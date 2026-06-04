#!/usr/bin/env bash
#
# Weekly nudge: next time Tim boots Windows, run `powercfg /h off` from an
# Admin command prompt to permanently disable hibernation and stop Windows
# from recreating hiberfil.sys (~51 GB) on the shared NTFS partition.
#
# Kill switch: once disabled, `touch ~/.local/state/windows-hibernate-disabled.flag`.
# This script becomes a no-op while that flag exists.
#
# Always exits 0 so systemd doesn't backoff on transient curl failures.

set -u

FLAG="${XDG_STATE_HOME:-$HOME/.local/state}/windows-hibernate-disabled.flag"
ENV_FILE="$HOME/.config/ntfy/env"

if [[ -f "$FLAG" ]]; then
    echo "flag present at $FLAG — hibernation already disabled, exiting"
    exit 0
fi

if [[ ! -r "$ENV_FILE" ]]; then
    echo "ntfy env file missing at $ENV_FILE — skipping notification" >&2
    exit 0
fi

# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

if [[ -z "${NTFY_SERVER_URL:-}" || -z "${NTFY_TOPIC:-}" ]]; then
    echo "NTFY_SERVER_URL or NTFY_TOPIC not set" >&2
    exit 0
fi

AUTH_ARGS=()
if [[ -n "${NTFY_USERNAME:-}" && -n "${NTFY_PASSWORD:-}" ]]; then
    AUTH_ARGS=(-u "$NTFY_USERNAME:$NTFY_PASSWORD")
fi

BODY="Next time you boot Windows: run \`powercfg /h off\` from an Admin cmd
prompt to permanently disable hibernation and reclaim ~51 GB on the shared
NTFS partition (hiberfil.sys will otherwise be recreated on every Windows
boot).

After running it, silence this reminder:
  touch $FLAG"

HTTP=$(curl -sS -o /dev/null -w '%{http_code}' \
    "${AUTH_ARGS[@]}" \
    -X POST \
    -H "Title: Disable Windows hibernation" \
    -H "Priority: default" \
    -H "Tags: windows,reminder" \
    -d "$BODY" \
    "$NTFY_SERVER_URL/$NTFY_TOPIC" || echo "000")

if [[ "$HTTP" == "200" ]]; then
    echo "notified (HTTP $HTTP)"
else
    echo "ntfy POST failed with HTTP $HTTP" >&2
fi

exit 0
