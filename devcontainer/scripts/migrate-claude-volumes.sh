#!/bin/bash
# Migrate Claude session logs from docker volumes (claude-code-config-*) into
# host ~/.claude/projects/ with cwd rewritten from container path to host path.
#
# Strategy:
# - For each project dir inside a volume, peek at the actual "cwd" value recorded
#   inside a jsonl file (authoritative — not guessed from the dir name which has
#   lossy / -> - encoding).
# - Compute host cwd = swap container_root prefix for host_workspace prefix.
# - Target project dir on host = encode(host_cwd).
# - rsync files, then rewrite cwd fields in each jsonl for that project dir only.
set -euo pipefail

DRYRUN="${DRYRUN:-0}"
MAPPING="${MAPPING:-/tmp/volume-mapping.txt}"
DEST_ROOT=~/.claude/projects

encode() { echo "$1" | sed 's|/|-|g'; }

total_files=0
total_projects=0

while IFS='|' read -r vol host_ws container_root; do
  [[ -z "$vol" || "$vol" == "#"* ]] && continue

  # For each project dir, extract actual cwd from first jsonl + count files.
  # Format: proj_dir<TAB>container_cwd<TAB>count
  meta=$(docker run --rm -v "$vol":/data alpine sh -c '
    for p in /data/projects/*/; do
      [[ -d "$p" ]] || continue
      base=$(basename "$p")
      n=$(find "$p" -maxdepth 1 -name "*.jsonl" 2>/dev/null | wc -l)
      [[ "$n" -eq 0 ]] && continue
      # Pull first cwd from any jsonl in this project dir
      cwd=""
      for f in "$p"*.jsonl; do
        [[ -f "$f" ]] || continue
        # Read up to 100 lines to find cwd; files may start with snapshots, attachments, etc.
        cwd=$(head -100 "$f" 2>/dev/null | grep -oE "\"cwd\":\"[^\"]+\"" | head -1 | sed "s|\"cwd\":\"||; s|\"$||")
        [[ -n "$cwd" ]] && break
      done
      printf "%s|%s|%s\n" "$base" "$cwd" "$n"
    done
  ' 2>/dev/null)

  [[ -z "$meta" ]] && { echo "SKIP $vol (no data)"; continue; }

  echo
  echo "=== $vol  ->  host_ws=$host_ws  (root=$container_root) ==="

  while IFS='|' read -r proj_dir container_cwd srcn; do
    [[ -z "$proj_dir" ]] && continue

    # Compute host cwd
    if [[ -z "$container_cwd" ]]; then
      # Fallback: use project dir name as if container_root
      host_cwd="$host_ws/_orphan_${proj_dir#-}"
    elif [[ "$container_cwd" == "$container_root" ]]; then
      host_cwd="$host_ws"
    elif [[ "$container_cwd" == "$container_root"/* ]]; then
      suffix="${container_cwd#$container_root/}"
      host_cwd="$host_ws/$suffix"
    else
      # cwd doesn't start with expected root (e.g. /home/node/branch, /tmp/...)
      # Quarantine it under host_ws/_orphan_<sanitized-path>
      sanitized=$(echo "${container_cwd#/}" | tr '/' '_')
      host_cwd="$host_ws/_orphan_$sanitized"
    fi

    dst_name=$(encode "$host_cwd")
    dst="$DEST_ROOT/$dst_name"

    echo "  $proj_dir ($srcn jsonl)  container_cwd=$container_cwd"
    echo "    -> $dst_name  (host_cwd=$host_cwd)"

    if [[ "$DRYRUN" == "1" ]]; then
      continue
    fi

    mkdir -p "$dst"

    # Copy via an ephemeral container that mounts the volume + the host dest.
    # Use alpine+rsync. Also copy sibling attachment dirs (matching session-id pattern)
    # but exclude memory/.
    docker run --rm \
      -v "$vol":/src:ro \
      -v "$dst":/dst \
      alpine sh -c "
        apk add --no-cache rsync >/dev/null 2>&1
        cd '/src/projects/$proj_dir' && rsync -a --exclude='memory/' --exclude='memory' ./ /dst/
      "

    # Rewrite cwd fields in just-copied files (any jsonl that mentions container_cwd prefix)
    python3 - "$dst" "$container_cwd" "$host_cwd" "$container_root" "$host_ws" <<'PY'
import os, sys
dst, ccwd, hcwd, croot, hws = sys.argv[1:6]
changed = 0
for root, _, files in os.walk(dst):
    for fn in files:
        if not fn.endswith('.jsonl'):
            continue
        p = os.path.join(root, fn)
        try:
            with open(p, 'r', encoding='utf-8', errors='replace') as f:
                data = f.read()
        except Exception:
            continue
        new = data
        # Exact cwd match
        new = new.replace(f'"cwd":"{ccwd}"', f'"cwd":"{hcwd}"')
        # Also rewrite any cwd starting with container_root/... -> host_ws/...
        new = new.replace(f'"cwd":"{croot}/', f'"cwd":"{hws}/')
        new = new.replace(f'"cwd":"{croot}"', f'"cwd":"{hws}"')
        if new != data:
            with open(p, 'w', encoding='utf-8') as f:
                f.write(new)
            changed += 1
print(f"    rewrote cwd in {changed} files")
PY

    total_projects=$((total_projects + 1))
    total_files=$((total_files + srcn))
  done <<< "$meta"

done < "$MAPPING"

echo
echo "Done. Migrated $total_files files across $total_projects project dirs."
[[ "$DRYRUN" == "1" ]] && echo "(dry run)"
