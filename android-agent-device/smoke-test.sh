#!/usr/bin/env bash
# End-to-end host smoke: real AVD + browser + IME + VisualViewport + rotation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI="${ANDROID_AGENT_DEVICE_CLI:-$ROOT/../bin/.local/bin/android-agent-device}"
EVIDENCE_DIR="${ANDROID_AGENT_DEVICE_SMOKE_EVIDENCE_DIR:-$HOME/.local/share/android-agent-device/evidence/smoke-$(date -u +%Y%m%dT%H%M%SZ)}"
PORT="${ANDROID_AGENT_DEVICE_SMOKE_PORT:-18080}"
mkdir -p "$EVIDENCE_DIR"
SMOKE_OWNER_TOKEN="${ANDROID_AGENT_DEVICE_OWNER_TOKEN:-smoke-$$-$(date -u +%s)}"

if [[ "${ANDROID_AGENT_DEVICE_SMOKE_LOCK_HELD:-}" != 1 ]]; then
  # All lifecycle and browser interactions below execute beneath one flock, including cleanup.
  exec "$CLI" lock -- env ANDROID_AGENT_DEVICE_SMOKE_LOCK_HELD=1 \
    ANDROID_AGENT_DEVICE_OWNER_TOKEN="$SMOKE_OWNER_TOKEN" "$0" "$@"
fi

server_pid=""
smoke_owns_recorded_process() {
  local status owner
  status="$("$CLI" status --json 2>/dev/null || true)"
  owner="$(sed -n 's/.*"owner_token":"\([^"]*\)".*/\1/p' <<<"$status")"
  [[ "$owner" == "$SMOKE_OWNER_TOKEN" ]]
}

cleanup() {
  local code=$?
  [[ -n "$server_pid" ]] && kill "$server_pid" 2>/dev/null || true
  if smoke_owns_recorded_process; then
    "$CLI" stop >>"$EVIDENCE_DIR/stop.log" 2>&1 || true
  else
    printf 'Smoke did not own the recorded emulator process; it did not stop it.\n' >>"$EVIDENCE_DIR/stop.log"
  fi
  exit "$code"
}
trap cleanup EXIT

dump_ui() {
  local name="$1"
  "$CLI" run -- shell uiautomator dump /sdcard/window.xml >/dev/null
  "$CLI" run -- pull /sdcard/window.xml "$EVIDENCE_DIR/$name.xml" >/dev/null
}

cdp_metrics() {
  local name="$1"
  "$CLI" run -- forward tcp:9222 localabstract:chrome_devtools_remote >/dev/null
  python3 - <<'PY' > "$EVIDENCE_DIR/$name-cdp.json" 2> "$EVIDENCE_DIR/$name-cdp.stderr"
import base64
import json
import os
import socket
import struct
import time
import urllib.parse
import urllib.request

sock = None
last_response = b""
for attempt in range(5):
    targets = json.load(urllib.request.urlopen("http://127.0.0.1:9222/json", timeout=5))
    target = next((item for item in targets if item.get("type") == "page" and "keyboard-viewport.html" in item.get("url", "")), None)
    if target is None:
        raise RuntimeError("fixture page is not a CDP target")
    parsed = urllib.parse.urlsplit(target["webSocketDebuggerUrl"])
    sock = socket.create_connection((parsed.hostname, parsed.port or 80), timeout=5)
    key = base64.b64encode(os.urandom(16)).decode()
    request_path = parsed.path + (f"?{parsed.query}" if parsed.query else "")
    request = (
        f"GET {request_path} HTTP/1.1\r\n"
        f"Host: {parsed.netloc}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
        f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
    )
    sock.sendall(request.encode())
    response = b""
    while b"\r\n\r\n" not in response:
        response += sock.recv(4096)
    if response.startswith(b"HTTP/1.1 101"):
        break
    last_response = response
    sock.close()
    sock = None
    time.sleep(0.5)
else:
    raise RuntimeError(f"CDP WebSocket handshake failed after retries: {last_response!r}")

def send_frame(payload):
    mask = os.urandom(4)
    size = len(payload)
    header = bytes([0x81])
    if size < 126:
        header += bytes([0x80 | size])
    elif size < 65536:
        header += bytes([0x80 | 126]) + struct.pack("!H", size)
    else:
        header += bytes([0x80 | 127]) + struct.pack("!Q", size)
    masked = bytes(value ^ mask[index % 4] for index, value in enumerate(payload))
    sock.sendall(header + mask + masked)

def receive_exact(size):
    data = b""
    while len(data) < size:
        chunk = sock.recv(size - len(data))
        if not chunk:
            raise RuntimeError("CDP socket closed")
        data += chunk
    return data

def receive_frame():
    first, second = receive_exact(2)
    size = second & 0x7f
    if size == 126:
        size = struct.unpack("!H", receive_exact(2))[0]
    elif size == 127:
        size = struct.unpack("!Q", receive_exact(8))[0]
    masked = second & 0x80
    mask = receive_exact(4) if masked else b""
    payload = receive_exact(size)
    if masked:
        payload = bytes(value ^ mask[index % 4] for index, value in enumerate(payload))
    return first & 0x0f, payload

expression = "JSON.stringify({layoutWidth:innerWidth,layoutHeight:innerHeight,visualWidth:visualViewport.width,visualHeight:visualViewport.height,orientation:screen.orientation.type,focused:document.activeElement.id})"
send_frame(json.dumps({"id": 1, "method": "Runtime.evaluate", "params": {"expression": expression, "returnByValue": True}}).encode())
while True:
    opcode, payload = receive_frame()
    if opcode == 0x9:
        sock.sendall(bytes([0x8A, len(payload)]) + payload)
        continue
    message = json.loads(payload)
    if message.get("id") != 1:
        continue
    if message.get("error") or message.get("result", {}).get("exceptionDetails"):
        raise RuntimeError(json.dumps(message))
    print(message["result"]["result"]["value"])
    break
sock.close()
PY
  cat "$EVIDENCE_DIR/$name-cdp.json"
}

tap_fixture_input() {
  local bounds x1 y1 x2 y2
  dump_ui input-target
  bounds="$(python3 - "$EVIDENCE_DIR/input-target.xml" <<'PY'
import re
import sys
from xml.etree import ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
for node in root.iter('node'):
    text = node.attrib.get('text', '')
    desc = node.attrib.get('content-desc', '')
    if text == 'Type here' or 'Tap for the Android soft keyboard' in text or 'Tap for the Android soft keyboard' in desc:
        print(node.attrib.get('bounds', ''))
        break
PY
)"
  [[ "$bounds" =~ ^\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]$ ]] \
    || { echo "Could not locate the browser fixture input in UI XML: $bounds" >&2; return 1; }
  x1="${BASH_REMATCH[1]}"; y1="${BASH_REMATCH[2]}"; x2="${BASH_REMATCH[3]}"; y2="${BASH_REMATCH[4]}"
  "$CLI" run -- shell input tap "$(((x1 + x2) / 2))" "$(((y1 + y2) / 2))"
}

tap_visible_text() {
  local capture="$1"; shift
  local bounds x1 y1 x2 y2
  dump_ui "$capture"
  bounds="$(python3 - "$EVIDENCE_DIR/$capture.xml" "$@" <<'PY'
import sys
from xml.etree import ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
choices = set(sys.argv[2:])
for node in root.iter('node'):
    if node.attrib.get('text') in choices or node.attrib.get('content-desc') in choices:
        print(node.attrib.get('bounds', ''))
        break
PY
)"
  [[ "$bounds" =~ ^\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]$ ]] || return 1
  x1="${BASH_REMATCH[1]}"; y1="${BASH_REMATCH[2]}"; x2="${BASH_REMATCH[3]}"; y2="${BASH_REMATCH[4]}"
  "$CLI" run -- shell input tap "$(((x1 + x2) / 2))" "$(((y1 + y2) / 2))"
}

complete_chrome_first_run_if_present() {
  local activity attempt
  for attempt in 1 2 3; do
    activity="$("$CLI" run -- shell dumpsys activity activities)"
    [[ "$activity" == *'FirstRunActivity'* ]] || return 0
    tap_visible_text "chrome-first-run-$attempt" \
      'Accept & continue' 'Accept and continue' 'ACCEPT & CONTINUE' \
      'Use without an account' 'No thanks' 'Continue' \
      || { echo 'Chrome first-run screen appeared but its acceptance control was not discoverable.' >&2; return 1; }
    sleep 3
  done
  activity="$("$CLI" run -- shell dumpsys activity activities)"
  [[ "$activity" != *'FirstRunActivity'* ]] \
    || { echo 'Chrome first-run did not complete after three automated acceptance actions.' >&2; return 1; }
}

dismiss_chrome_notification_onboarding_if_present() {
  local attempt
  # Fresh Google Play images can chain Chrome-owned notification and ad-privacy prompts.
  # Decline the notification and acknowledge the informational privacy panel without enabling either.
  for attempt in 1 2 3; do
    if tap_visible_text "chrome-onboarding-$attempt" 'No thanks' 'Got it'; then
      sleep 3
    else
      return 0
    fi
  done
}

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$ROOT/fixtures" >"$EVIDENCE_DIR/http.log" 2>&1 &
server_pid=$!

wait_for_fixture_server() {
  local deadline=$((SECONDS + 20))
  while (( SECONDS < deadline )); do
    # A bare TCP connect only proves something is listening: a pre-existing, unrelated local
    # service on the same port would pass that check too. Require our own backgrounded PID to
    # still be alive both immediately before and after a real HTTP GET for the known fixture file,
    # and require the response body to actually be that fixture's content.
    kill -0 "$server_pid" 2>/dev/null || { echo "Fixture HTTP server on 127.0.0.1:$PORT exited before it could be verified. See $EVIDENCE_DIR/http.log." >&2; return 1; }
    if python3 -c "
import sys
import urllib.request
try:
    with urllib.request.urlopen('http://127.0.0.1:' + sys.argv[1] + '/keyboard-viewport.html', timeout=1) as response:
        body = response.read()
except OSError:
    sys.exit(1)
sys.exit(0 if b'keyboard-test' in body else 1)
" "$PORT" 2>/dev/null && kill -0 "$server_pid" 2>/dev/null; then
      return 0
    fi
    sleep 0.2
  done
  echo "Fixture HTTP server did not start serving the expected fixture on 127.0.0.1:$PORT within 20s. See $EVIDENCE_DIR/http.log." >&2
  return 1
}
wait_for_fixture_server

"$CLI" diagnose --json | tee "$EVIDENCE_DIR/diagnose.json"
"$CLI" start | tee "$EVIDENCE_DIR/start.log"
status_json="$("$CLI" status --json)"
printf '%s\n' "$status_json" | tee "$EVIDENCE_DIR/status.json"
browser="$(printf '%s' "$status_json" | sed -n 's/.*"browser":"\([^"]*\)".*/\1/p')"
[[ "$browser" != missing ]] || { echo 'Chromium baseline is absent from the selected system image.' >&2; exit 1; }

url="http://10.0.2.2:$PORT/keyboard-viewport.html"
"$CLI" run -- shell am start -W -a android.intent.action.VIEW -d "$url" >"$EVIDENCE_DIR/browser-start.txt"
sleep 5
complete_chrome_first_run_if_present
dismiss_chrome_notification_onboarding_if_present
# First-run acceptance owns the original intent, so launch the controlled fixture once more.
"$CLI" run -- shell am start -W -a android.intent.action.VIEW -d "$url" >>"$EVIDENCE_DIR/browser-start.txt"
sleep 3
initial_metrics="$(cdp_metrics initial)"
[[ "$initial_metrics" == *'"visualHeight":'* ]] || { echo "Fixture CDP metrics unavailable: $initial_metrics" >&2; exit 1; }
"$CLI" screenshot "$EVIDENCE_DIR/01-initial.png" >/dev/null

tap_fixture_input
sleep 3
"$CLI" run -- shell dumpsys input_method >"$EVIDENCE_DIR/input-method.txt"
"$CLI" run -- shell dumpsys window >"$EVIDENCE_DIR/window.txt"
keyboard_metrics="$(cdp_metrics keyboard)"
"$CLI" screenshot "$EVIDENCE_DIR/02-keyboard.png" >/dev/null

# Android exposes IME visibility differently by release; require a positive platform signal,
# not only a viewport change or a screenshot.
rg -q 'mInputShown=true|mShowRequested=true|mImeWindowVis=(0x)?[1-9a-fA-F]' "$EVIDENCE_DIR/input-method.txt" "$EVIDENCE_DIR/window.txt" \
  || { echo 'No platform IME visibility evidence after tapping the input.' >&2; exit 1; }
[[ "$keyboard_metrics" == *'"focused":"keyboard-test"'* ]] || { echo "Input did not receive focus: $keyboard_metrics" >&2; exit 1; }
initial_visual_height="$(sed -n 's/.*"visualHeight":\([0-9.]*\).*/\1/p' <<<"$initial_metrics")"
keyboard_visual_height="$(sed -n 's/.*"visualHeight":\([0-9.]*\).*/\1/p' <<<"$keyboard_metrics")"
awk "BEGIN { exit !($keyboard_visual_height < $initial_visual_height) }" \
  || { echo "VisualViewport did not shrink for the shown Android IME: $initial_metrics -> $keyboard_metrics" >&2; exit 1; }

"$CLI" run -- shell settings put system accelerometer_rotation 0
"$CLI" run -- shell settings put system user_rotation 1
sleep 3
landscape_metrics="$(cdp_metrics landscape)"
"$CLI" screenshot "$EVIDENCE_DIR/03-landscape.png" >/dev/null
file "$EVIDENCE_DIR/03-landscape.png" | tee "$EVIDENCE_DIR/landscape-image.txt"
[[ "$landscape_metrics" == *'"orientation":"landscape'* ]] || { echo "Rotation did not reach landscape: $landscape_metrics" >&2; exit 1; }

"$CLI" logs "$EVIDENCE_DIR/logcat.txt" >/dev/null
cat > "$EVIDENCE_DIR/result.txt" <<EOF
PASS: real Android browser fixture
initial: $initial_metrics
keyboard: $keyboard_metrics
landscape: $landscape_metrics
IME evidence: input-method.txt + window.txt
EOF
cat "$EVIDENCE_DIR/result.txt"
