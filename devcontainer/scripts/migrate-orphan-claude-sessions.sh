#!/bin/bash
# Migrate Claude session logs from pre-.claude-mount devcontainer homes
# into host ~/.claude/projects/ with cwd rewritten from container path to host path.
#
# Originals in ~/.devcontainer-homes/*/.claude/projects/ are left untouched.
set -euo pipefail

DRYRUN="${DRYRUN:-0}"
HOMES=~/.devcontainer-homes
DEST_ROOT=~/.claude/projects

# Format: container_name | orphan_project_dirname | container_cwd | host_cwd
MAPPINGS=(
  "anka-redactor|-workspace|/workspace|/home/tnunamak/code/anka-redactor"
  "anka-redactor|-workspace-replicate|/workspace/replicate|/home/tnunamak/code/anka-redactor/replicate"
  "anka-redactor|-home-node-extraction-improvements|/home/node/extraction-improvements|/home/tnunamak/code/anka-redactor"
  "ankadata-org|-workspace|/workspace|/home/tnunamak/code/ankadata-org"
  "ankadata-org|-home-node-review-ux-optimizations|/home/node/review-ux-optimizations|/home/tnunamak/code/ankadata-org"
  "claude-code|-workspace|/workspace|/home/tnunamak/code/claude-code"
  "clearcut|-workspace|/workspace|/home/tnunamak/applications/clearcut"
  "mind-dao|-workspace|/workspace|/home/tnunamak/code/mind-dao"
  "sandbox|-workspace|/workspace|/home/tnunamak/sandbox"
  "SillyTavern|-workspace|/workspace|/home/tnunamak/applications/SillyTavern"
  "vana-smart-contracts|-workspace|/workspace|/home/tnunamak/code/vana-smart-contracts"
  "vana-stats-server|-workspace|/workspace|/home/tnunamak/code/vana-stats-server"
)

# Turn a host path into the Claude project dir encoding: /home/tnunamak/code/foo -> -home-tnunamak-code-foo
encode_project_dir() {
  echo "$1" | sed 's|/|-|g'
}

run() {
  if [[ "$DRYRUN" == "1" ]]; then
    echo "DRYRUN: $*"
  else
    "$@"
  fi
}

total_copied=0
total_rewritten=0

for entry in "${MAPPINGS[@]}"; do
  IFS='|' read -r container orphan_dir container_cwd host_cwd <<< "$entry"

  src="$HOMES/$container/.claude/projects/$orphan_dir"
  dst_name=$(encode_project_dir "$host_cwd")
  dst="$DEST_ROOT/$dst_name"

  jsonl_count=$(find "$src" -maxdepth 1 -name '*.jsonl' 2>/dev/null | wc -l)
  if [[ "$jsonl_count" -eq 0 ]]; then
    echo "SKIP  $container/$orphan_dir (no jsonl files)"
    continue
  fi

  echo
  echo "==> $container/$orphan_dir  ->  $dst_name"
  echo "    cwd rewrite: $container_cwd -> $host_cwd  ($jsonl_count jsonl files)"

  # Copy everything except memory/
  if [[ "$DRYRUN" == "1" ]]; then
    rsync -an --exclude='memory/' --exclude='memory' "$src/" "$dst/" | tail -5
  else
    mkdir -p "$dst"
    rsync -a --exclude='memory/' --exclude='memory' "$src/" "$dst/"
  fi

  # Rewrite cwd in all .jsonl files under $dst that originated from this source.
  # We use the source file list to know which dest files to touch, so we don't
  # accidentally modify pre-existing host files in a merge target.
  while IFS= read -r -d '' srcfile; do
    relpath="${srcfile#$src/}"
    destfile="$dst/$relpath"
    [[ -f "$destfile" ]] || continue

    if [[ "$DRYRUN" == "1" ]]; then
      matches=$(grep -c "\"cwd\":\"$container_cwd\"" "$destfile" 2>/dev/null || echo 0)
      echo "    would rewrite $matches lines in $relpath"
    else
      # Rewrite only exact cwd field matches. Use | as sed delimiter since paths have /.
      sed -i "s|\"cwd\":\"$container_cwd\"|\"cwd\":\"$host_cwd\"|g" "$destfile"
      total_rewritten=$((total_rewritten + 1))
    fi
    total_copied=$((total_copied + 1))
  done < <(find "$src" -name '*.jsonl' -print0)
done

echo
echo "Done. Copied $total_copied files, rewrote cwd in $total_rewritten."
[[ "$DRYRUN" == "1" ]] && echo "(dry run — no changes made)"
