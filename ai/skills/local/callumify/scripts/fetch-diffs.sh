#!/usr/bin/env bash
# Durable: the DIFF TEXT of each Callum cleanup commit. Re-runnable, skips existing.
set -uo pipefail
ROOT="$HOME/.tmp/callumify-0818"; mkdir -p "$ROOT/raw/diffs"
python3 - <<'PY' > /tmp/todo.txt
import json
for l in open("pairs/cleanup-pairs.jsonl"):
    u=json.loads(l); print(f"{u['repo']}\t{u['callum_sha']}")
PY
n=0; ok=0
while IFS=$'\t' read -r repo sha; do
  n=$((n+1)); out="$ROOT/raw/diffs/${repo}__${sha:0:9}.diff"
  [ -s "$out" ] && { ok=$((ok+1)); continue; }
  CL="$ROOT/clones/$repo.git"; [ -d "$CL" ] || continue
  # blob:none clone needs blobs on demand; -m flattens merges
  git -C "$CL" diff-tree -p -m --no-color --stat=200 "$sha" > "$out" 2>/dev/null
  [ -s "$out" ] && ok=$((ok+1)) || rm -f "$out"
done < /tmp/todo.txt
echo "attempted=$n captured=$ok"
du -sh "$ROOT/raw/diffs" 2>/dev/null
