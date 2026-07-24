#!/usr/bin/env bash
# The restore must fail loudly, rather than silently, if no display env arrives.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESTORE="$ROOT/bin/.local/bin/desktop-layout-restore"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/desktop-layout-env.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/home"
printf '#!/usr/bin/env bash\nexit 0\n' >"$WORK/bin/systemctl"
printf '#!/usr/bin/env bash\n[[ "$1" == getactivewindow ]] && exit 1\nexit 1\n' >"$WORK/bin/kdotool"
chmod +x "$WORK/bin/systemctl" "$WORK/bin/kdotool"
printf '%s\n' '{"screen":{"width":1,"height":1},"windows":[]}' >"$WORK/manifest.json"

if env -i HOME="$WORK/home" PATH="$WORK/bin:$PATH" DESKTOP_LAYOUT_WAIT_SECONDS=1 \
  "$RESTORE" --dry-run --manifest "$WORK/manifest.json" >"$WORK/out" 2>&1; then
  echo "expected env -i graphical-session wait to fail" >&2
  exit 1
fi
grep -q 'ERROR graphical session not ready after 1s' "$WORK/out"
grep -q 'ERROR rc=1 command=return 1 env:' "$WORK/out"
echo "PASS: env -i waits and logs graphical-session failure"
