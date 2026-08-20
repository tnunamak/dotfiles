#!/usr/bin/env bash
# gap-scan.sh <target-dir> [rules.json path]
# Deterministic gap-scan for the callumify skill: runs the profile's CRITICAL
# rule greps, taxonomy checks, and conformance pattern-pairs against a target
# repo, and prints one JSON report to stdout. Always exits 0 (reports, does
# not gate).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET="${1:?usage: gap-scan.sh <target-dir> [rules.json path]}"
RULES="${2:-"$SCRIPT_DIR/../profiles/callum/rules.json"}"

[ -d "$TARGET" ] || { echo "{\"error\": \"target dir not found: $TARGET\"}"; exit 0; }
[ -f "$RULES" ] || { echo "{\"error\": \"rules file not found: $RULES\"}"; exit 0; }
TARGET="$(cd "$TARGET" && pwd)"
HAVE_RG=0
command -v rg >/dev/null 2>&1 && HAVE_RG=1

# grep_glob PATTERN GLOB -> "path:line:text" lines, absolute paths under TARGET.
# GLOB supports "*.ext" or "*.{a,b}". Falls back to find+grep -E when rg is absent.
grep_glob() {
  if [ "$HAVE_RG" -eq 1 ]; then
    rg -n --no-heading -g "$2" -e "$1" "$TARGET" 2>/dev/null
    return
  fi
  local pattern="$1" glob="$2" exts name_expr=()
  exts="${glob#\*.}"; exts="${exts#\{}"; exts="${exts%\}}"
  IFS=',' read -ra EXTARR <<<"$exts"
  for e in "${EXTARR[@]}"; do name_expr+=(-o -iname "*.${e}"); done
  find "$TARGET" -type f \( "${name_expr[@]:1}" \) -print0 2>/dev/null \
    | xargs -0 grep -nE "$pattern" 2>/dev/null
}

count_lines() { [ -n "$1" ] && printf '%s\n' "$1" | grep -c '' || echo 0; }
jesc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

# --- critical_rules ---
critical_json="[]"
n_rules=$(jq '.critical_rules | length' "$RULES")
for ((i = 0; i < n_rules; i++)); do
  id=$(jq -r ".critical_rules[$i].id" "$RULES")
  pattern=$(jq -r ".critical_rules[$i].grep.pattern" "$RULES")
  glob=$(jq -r ".critical_rules[$i].grep.glob" "$RULES")
  matches="$(grep_glob "$pattern" "$glob")"
  count=$(count_lines "$matches")
  samples="[]"
  if [ "$count" -gt 0 ]; then
    samples=$(printf '%s\n' "$matches" | head -n 10 | awk -F: -v t="$TARGET/" \
      '{sub("^"t,"",$1); printf "%s:%s\n", $1, $2}' \
      | jq -R -s 'split("\n") | map(select(length>0))')
  fi
  critical_json=$(echo "$critical_json" | jq --arg id "$id" --argjson v "$count" --argjson s "$samples" \
    '. + [{id:$id, violations:$v, samples:$s}]')
done

# --- taxonomy ---
comp_dirs=$(find "$TARGET" -type d -iname "components" 2>/dev/null | grep -v node_modules || true)
expected_dirs_json=$(jq -c '.taxonomy.expected_dirs' "$RULES")
exempt_dirs=(ui mdx docs theme ai)
existing_json="[]"
wrappers_json="[]"
while IFS= read -r croot; do
  [ -z "$croot" ] && continue
  relroot="${croot#"$TARGET"/}"
  for d in $(echo "$expected_dirs_json" | jq -r '.[]'); do
    if [ -d "$croot/$d" ]; then
      existing_json=$(echo "$existing_json" | jq --arg r "$relroot" --arg d "$d" \
        '. + [{components_root:$r, dir:$d}]')
    fi
  done
  while IFS= read -r sub; do
    [ -z "$sub" ] && continue
    name="$(basename "$sub")"
    skip=0
    for known in $(echo "$expected_dirs_json" | jq -r '.[]') "${exempt_dirs[@]}"; do
      [ "$name" = "$known" ] && skip=1
    done
    [ "$skip" -eq 1 ] && continue
    fcount=$(find "$sub" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$fcount" -ge 5 ]; then
      relsub="${sub#"$TARGET"/}"
      wrappers_json=$(echo "$wrappers_json" | jq --arg d "$relsub" --argjson f "$fcount" \
        '. + [{dir:$d, file_count:$f}]')
    fi
  done < <(find "$croot" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
done <<<"$comp_dirs"

# --- conformance ---
conformance_json="[]"
n_pairs=$(jq '.conformance.pairs | length' "$RULES")
for ((i = 0; i < n_pairs; i++)); do
  name=$(jq -r ".conformance.pairs[$i].name" "$RULES")
  blessed=$(jq -r ".conformance.pairs[$i].blessed" "$RULES")
  legacy=$(jq -r ".conformance.pairs[$i].legacy" "$RULES")
  blessed_count=$(count_lines "$(grep_glob "$blessed" '*.tsx')")
  legacy_matches="$(grep_glob "$legacy" '*.tsx')"
  legacy_count=$(count_lines "$legacy_matches")
  by_path="{}"
  if [ "$legacy_count" -gt 0 ]; then
    # Bucket by up to 3 path segments after TARGET (e.g. src/app/dashboard,
    # src/components/pdpp-concept) so internal/tooling surfaces are separable.
    by_path=$(printf '%s\n' "$legacy_matches" | awk -F: -v t="$TARGET/" \
      '{f=$1; sub("^"t,"",f); n=split(f,p,"/");
        print (n>2 ? p[1]"/"p[2]"/"p[3] : (n>1 ? p[1]"/"p[2] : p[1]))}' \
      | sort | uniq -c | awk '{c=$1; $1=""; sub(/^ /,""); print $0"\t"c}' \
      | jq -R -s 'split("\n") | map(select(length>0) | split("\t")) | map({(.[0]): (.[1]|tonumber)}) | add // {}')
  fi
  conformance_json=$(echo "$conformance_json" | jq \
    --arg n "$name" --argjson b "$blessed_count" --argjson l "$legacy_count" --argjson p "$by_path" \
    '. + [{name:$n, blessed_count:$b, legacy_count:$l, legacy_by_path:$p}]')
done

jq -n \
  --arg target "$TARGET" \
  --argjson critical "$critical_json" \
  --argjson existing "$existing_json" \
  --argjson wrappers "$wrappers_json" \
  --argjson conformance "$conformance_json" \
  '{target:$target, critical_rules:$critical,
    taxonomy:{existing_expected_dirs:$existing, wrapper_dir_candidates:$wrappers},
    conformance:$conformance}'

exit 0
