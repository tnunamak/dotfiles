#!/usr/bin/env bash
# Reap stale agent/worktree SUBDIRECTORIES under ~/.tmp.
#
# Why this exists: systemd-tmpfiles `e` only deletes loose files by age; it
# never removes a stale subdirectory tree (verified 2026-06-15). The bulk of
# ~/.tmp is per-task subdirs (agent runs, git worktrees), so they accumulated
# unbounded (34G as of 2026-06-15) despite the daily tmpfiles clean.
#
# Policy: remove any immediate ~/.tmp/<subdir> whose NEWEST contained file is
# older than AGE_DAYS, and that no running process is cwd'd inside. Uses
# inner-file mtime (not the dir's own mtime, which churns) so a subdir is reaped
# only when its actual work has gone cold.
#
# Git worktrees living under ~/.tmp leave dangling refs in their parent repos
# after removal; this prunes those for repos under ~/code.
set -uo pipefail

TMPROOT="${HOME}/.tmp"
AGE_DAYS="${TMP_REAPER_AGE_DAYS:-7}"
DRY="${1:-}"   # pass --dry-run to preview

[[ -d "$TMPROOT" ]] || exit 0

now=$(date +%s)
cutoff=$(( now - AGE_DAYS * 86400 ))

# Set of dirs currently used as a process working directory (never reap these).
mapfile -t active_cwds < <(ls -l /proc/*/cwd 2>/dev/null | grep -oE '/[^ ]*$' | sort -u)
is_active() {
    local target="$1" c
    for c in "${active_cwds[@]}"; do
        [[ "$c" == "$target"* ]] && return 0
    done
    return 1
}

reaped=0 freed_kb=0
shopt -s nullglob
for d in "$TMPROOT"/*/; do
    d="${d%/}"
    # newest mtime among contained files (epoch); empty dir -> use dir mtime
    newest=$(find "$d" -type f -printf '%T@\n' 2>/dev/null | sort -rn 2>/dev/null | head -1)
    newest="${newest%.*}"
    [[ -z "$newest" ]] && newest=$(stat -c %Y "$d" 2>/dev/null || echo "$now")
    (( newest > cutoff )) && continue            # still warm
    if is_active "$(readlink -f "$d")"; then
        echo "skip (active cwd): $d"; continue
    fi
    sz=$(du -sk "$d" 2>/dev/null | cut -f1); sz=${sz:-0}
    if [[ "$DRY" == "--dry-run" ]]; then
        printf 'would reap %6sM  %s\n' "$((sz/1024))" "$d"
    else
        rm -rf -- "$d" && { reaped=$((reaped+1)); freed_kb=$((freed_kb+sz)); }
    fi
done

# Clear dangling worktree refs left behind in ~/code repos.
if [[ "$DRY" != "--dry-run" ]]; then
    for g in "$HOME"/code/*/.git; do
        r="${g%/.git}"
        git -C "$r" worktree prune 2>/dev/null || true
    done
fi

if [[ "$DRY" == "--dry-run" ]]; then
    echo "(dry-run; AGE_DAYS=$AGE_DAYS)"
else
    echo "tmp-reaper: removed $reaped subdir(s), freed $((freed_kb/1024))M (AGE_DAYS=$AGE_DAYS)"
fi
