#!/usr/bin/env bash
# Reject a sidecar that cannot be tied to the assistant process now running in
# each tmux pane.  tmux-assistant-resurrect may resolve a session from local
# history; history is useful for discovery but is not proof that it belongs to
# this live process.  A transaction must not advance on that weaker evidence.
set -euo pipefail

sidecar="${1:?usage: validate-assistant-session-identities.sh SIDECAR_JSON}"
[[ -f "$sidecar" ]] || { echo "identity validation: sidecar missing: $sidecar" >&2; exit 1; }

python3 - "$sidecar" <<'PY'
import json
import os
import re
import shlex
import subprocess
import sys
from collections import defaultdict, deque

sidecar_path = sys.argv[1]

try:
    with open(sidecar_path, encoding="utf-8") as f:
        sessions = json.load(f).get("sessions")
    if not isinstance(sessions, list):
        raise ValueError(".sessions is not an array")
except Exception as exc:
    print(f"identity validation: invalid sidecar: {exc}", file=sys.stderr)
    sys.exit(1)

def canonical_pane(session, group, window, pane):
    return f"{group or session}:{window}.{pane}"

def tool_for(args):
    try:
        argv = shlex.split(args)
    except ValueError:
        argv = args.split()
    if not argv:
        return None
    argv0 = os.path.basename(argv[0])
    for tool in ("claude", "opencode", "codex", "pi", "omp", "grok"):
        direct_tool = argv0 == tool
        node_launcher = (
            tool == "codex"
            and argv0 in ("node", "nodejs")
            and len(argv) > 1
            and os.path.basename(argv[1]) == "codex"
        )
        if direct_tool or node_launcher:
            if tool == "opencode" and "opencode run " in args:
                continue
            if tool == "omp" and "__omp_worker_" in args:
                continue
            return tool
    return None

def process_start_ticks(pid):
    # Linux /proc/<pid>/stat field 22.  The command field may include spaces
    # or parentheses, so split only after its final closing parenthesis.
    proc_root = os.environ.get("TMUX_ASSISTANT_IDENTITY_PROC_ROOT", "/proc")
    try:
        with open(os.path.join(proc_root, str(pid), "stat"), encoding="utf-8") as f:
            stat = f.read().strip()
        closing = stat.rfind(")")
        fields = stat[closing + 1:].split()
        ticks = fields[19]  # state is field 3; starttime is field 22.
        return ticks if ticks.isdigit() else None
    except (OSError, IndexError):
        return None

def proc_boot_time():
    proc_root = os.environ.get("TMUX_ASSISTANT_IDENTITY_PROC_ROOT", "/proc")
    try:
        with open(os.path.join(proc_root, "stat"), encoding="utf-8") as f:
            for line in f:
                if line.startswith("btime "):
                    return int(line.split()[1])
    except (OSError, ValueError, IndexError):
        pass
    return None

def process_start_epoch(pid):
    ticks = process_start_ticks(pid)
    boot_time = proc_boot_time()
    if ticks is None or boot_time is None:
        return None
    try:
        hz = int(os.environ.get("TMUX_ASSISTANT_IDENTITY_CLK_TCK") or os.sysconf("SC_CLK_TCK"))
    except (OSError, ValueError):
        return None
    if hz <= 0:
        return None
    return boot_time + (int(ticks) / hz)

def receipt_fresh_for_pid(state_file, pid):
    process_started = process_start_epoch(pid)
    if process_started is None:
        return False
    try:
        receipt_mtime = os.stat(state_file).st_mtime
    except OSError:
        return False
    # Fail closed on clock anomalies too. A SessionStart receipt is written
    # after the process starts, so it must never predate this PID generation.
    return receipt_mtime >= process_started

def explicit_session(tool, pid, args):
    # Only accept identity evidence directly bound to this PID.  In particular,
    # do not turn Codex's cwd-scoped SQLite fallback into a recovery receipt.
    if tool == "codex":
        tags = os.path.join(os.path.expanduser("~"), ".codex", "session-tags.jsonl")
        ticks = process_start_ticks(pid)
        try:
            with open(tags, encoding="utf-8") as f:
                for raw in reversed(f.readlines()):
                    row = json.loads(raw)
                    if str(row.get("pid")) != str(pid):
                        continue
                    # Tag schema is {pid, session, start_ticks}. Use only the
                    # newest row for this PID, matching upstream's tail -1.
                    session = row.get("session") or row.get("session_id")
                    if row.get("tool") not in (None, "codex"):
                        return None
                    if ticks is not None and str(row.get("start_ticks")) == ticks \
                        and isinstance(session, str) and session:
                        return session
                    return None
        except (OSError, ValueError, json.JSONDecodeError):
            pass
        match = re.search(r"(?:^|\s)resume\s+([A-Za-z0-9_-]+)(?:\s|$)", args)
        return match.group(1) if match else None
    if tool == "claude":
        # This is the same PID-keyed SessionStart receipt that the upstream
        # saver reads.  Require its recorded ppid too: the filename alone is
        # not sufficient evidence if a stale runtime receipt remains.
        # Match upstream exactly: TMUX_ASSISTANT_RESURRECT_DIR is the complete
        # state directory, while XDG_RUNTIME_DIR/TMPDIR need the suffix.
        state_dir = os.environ.get("TMUX_ASSISTANT_RESURRECT_DIR") or os.path.join(
            os.environ.get("XDG_RUNTIME_DIR") or os.environ.get("TMPDIR") or "/tmp",
            "tmux-assistant-resurrect",
        )
        state_file = os.path.join(state_dir, f"claude-{pid}.json")
        try:
            with open(state_file, encoding="utf-8") as f:
                state = json.load(f)
            sid = state.get("session_id")
            if str(state.get("ppid")) == str(pid) and isinstance(sid, str) and sid \
                and receipt_fresh_for_pid(state_file, pid):
                return sid
        except (OSError, ValueError, json.JSONDecodeError):
            pass
        match = re.search(r"--resume(?:=|\s+)([A-Za-z0-9_-]+)", args)
        return match.group(1) if match else None
    patterns = {
        "opencode": r"(?:-s|--session)(?:=|\s+)([A-Za-z0-9_-]+)",
        "pi": r"--session(?:=|\s+)([A-Za-z0-9_-]+)",
        "omp": r"--session(?:=|\s+)([A-Za-z0-9_-]+)",
        "grok": r"(?:-r|--resume)(?:=|\s+)([A-Za-z0-9_-]+)",
    }
    match = re.search(patterns.get(tool, r"$^"), args)
    return match.group(1) if match else None

fixture = os.environ.get("TMUX_ASSISTANT_IDENTITY_SNAPSHOT")
if fixture:
    try:
        with open(fixture, encoding="utf-8") as f:
            snapshot = json.load(f)
        live = snapshot["panes"]
    except Exception as exc:
        print(f"identity validation: invalid test snapshot: {exc}", file=sys.stderr)
        sys.exit(1)
else:
    panes_raw = subprocess.run(
        ["tmux", "list-panes", "-a", "-F", "#{session_name}|#{session_group}|#{window_index}|#{pane_index}|#{pane_pid}"],
        text=True, capture_output=True,
    )
    if panes_raw.returncode:
        print("identity validation: could not list tmux panes", file=sys.stderr)
        sys.exit(1)
    roots = {}
    for raw in panes_raw.stdout.splitlines():
        fields = raw.split("|")
        if len(fields) != 5 or not fields[4].isdigit():
            print("identity validation: malformed tmux pane row", file=sys.stderr)
            sys.exit(1)
        target = canonical_pane(*fields[:4])
        existing = roots.setdefault(target, fields[4])
        if existing != fields[4]:
            print(f"identity validation: canonical pane {target} has inconsistent roots", file=sys.stderr)
            sys.exit(1)
    ps_raw = subprocess.run(["ps", "-eo", "pid=,ppid=,args="], text=True, capture_output=True)
    if ps_raw.returncode:
        print("identity validation: could not snapshot processes", file=sys.stderr)
        sys.exit(1)
    processes = {}
    children = defaultdict(list)
    for raw in ps_raw.stdout.splitlines():
        fields = raw.strip().split(None, 2)
        if len(fields) < 3 or not fields[0].isdigit() or not fields[1].isdigit():
            continue
        pid, ppid, args = fields
        processes[pid] = args
        children[ppid].append(pid)
    live = []
    for pane, root in roots.items():
        if root not in processes:
            print(f"identity validation: pane root disappeared: {pane}", file=sys.stderr)
            sys.exit(1)
        queue = deque([root])
        assistants = []
        while queue:
            pid = queue.popleft()
            args = processes.get(pid, "")
            tool = tool_for(args)
            if tool:
                assistants.append({"tool": tool, "pid": pid, "session_id": explicit_session(tool, pid, args)})
            queue.extend(children.get(pid, ()))
        live.append({"pane": pane, "assistants": assistants})

live_by_pane = {}
for row in live:
    pane = row.get("pane")
    assistants = row.get("assistants")
    if not isinstance(pane, str) or not isinstance(assistants, list):
        print("identity validation: malformed live identity snapshot", file=sys.stderr)
        sys.exit(1)
    if pane in live_by_pane:
        print(f"identity validation: duplicate live pane {pane}", file=sys.stderr)
        sys.exit(1)
    live_by_pane[pane] = assistants

saved_by_pane = defaultdict(list)
for row in sessions:
    if not isinstance(row, dict):
        print("identity validation: sidecar session is not an object", file=sys.stderr)
        sys.exit(1)
    pane, tool, pid, sid = row.get("pane"), row.get("tool"), row.get("pid"), row.get("session_id")
    if not all(isinstance(value, str) and value for value in (pane, tool, pid, sid)):
        print("identity validation: sidecar entry lacks pane/tool/pid/session_id", file=sys.stderr)
        sys.exit(1)
    saved_by_pane[pane].append(row)

kept = []
omitted = []
for pane, rows in saved_by_pane.items():
    if len(rows) != 1:
        print(f"identity validation: sidecar has {len(rows)} entries for {pane}", file=sys.stderr)
        sys.exit(1)
    row = rows[0]
    assistants = live_by_pane.get(pane)
    if assistants is None:
        print(f"identity validation: sidecar assistant pane is not live in tmux: {pane}", file=sys.stderr)
        sys.exit(1)
    same_process = [
        assistant for assistant in assistants
        if assistant.get("tool") == row["tool"] and str(assistant.get("pid")) == row["pid"]
    ]
    if len(same_process) != 1:
        print(
            f"identity validation: {pane} sidecar {row['tool']}:{row['session_id']} pid={row['pid']} "
            "does not match a live provider/PID",
            file=sys.stderr,
        )
        sys.exit(1)
    live_sid = same_process[0].get("session_id")
    if live_sid is None:
        print(f"identity validation: {pane} {row['tool']} pid={row['pid']} has no PID-bound session identity", file=sys.stderr)
        sys.exit(1)
    if live_sid != row["session_id"]:
        print(
            f"identity validation: {pane} sidecar {row['tool']}:{row['session_id']} pid={row['pid']} "
            "does not match a live PID-bound identity",
            file=sys.stderr,
        )
        sys.exit(1)
    kept.append(row)

kept_panes = {row["pane"] for row in kept}
for pane, assistants in live_by_pane.items():
    if assistants and pane not in kept_panes and not any(item["pane"] == pane for item in omitted):
        omitted.append({"pane": pane, "reason": "live-assistant-has-no-sidecar-entry"})

print(json.dumps({"identity_validation": "accepted", "saved": len(kept), "omitted": omitted}, separators=(",", ":")))
PY
