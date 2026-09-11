#!/usr/bin/env bash
# Restore the agent sessions that vanished when the 2026-09-10 crash restored
# tmux from a 10-day-old snapshot. Source of truth: the last save before the
# save blackout, transactions/bundle-bad13e0f8d10761a (2026-08-31T03:06:14Z).
#
# Every transcript below was verified present on disk. Nothing is lost; these
# conversations just lost the tmux window they were displayed in.
#
# NOT automatic on purpose. Each line re-attaches ONE conversation into the
# window it came from. Run the ones you still care about; skip the rest.
# Each respawns the pane, so run it only against a window you accept replacing.
set -euo pipefail

# main:3  ✳ Investigate Coolify and Vivid Fish hosting setup
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak-sandbox/e893c807-9b64-41c9-918f-c4b03cdad783.jsonl
tmux respawn-pane -k -t main:3.0 -c '/home/tnunamak/sandbox' 'claude --resume e893c807-9b64-41c9-918f-c4b03cdad783 --dangerously-skip-permissions'   # claude

# main:4  ✳ Investigate Claude Code hook errors
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak-code-dotfiles/bdac59f6-cce0-4bbb-8c9f-e58ff30c232b.jsonl
tmux respawn-pane -k -t main:4.0 -c '/home/tnunamak/code/dotfiles' 'claude --resume bdac59f6-cce0-4bbb-8c9f-e58ff30c232b --dangerously-skip-permissions'   # claude

# main:6  context-gateway
#   transcript: /home/tnunamak/.codex/sessions/2026/07/29/rollout-2026-07-29T11-27-57-019faeb4-43df-75e1-9607-294f65e61bdf.jsonl
tmux respawn-pane -k -t main:6.0 -c '/home/tnunamak/code/context-gateway' 'codex resume 019faeb4-43df-75e1-9607-294f65e61bdf'   # codex

# main:7  ✳ Test Devspecs CLI v1.0.0 release
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak-code-dotfiles/c0dad57d-f029-4f28-bf9e-46c646d26c11.jsonl
tmux respawn-pane -k -t main:7.0 -c '/home/tnunamak/code/dotfiles' 'claude --resume c0dad57d-f029-4f28-bf9e-46c646d26c11 --dangerously-skip-permissions'   # claude

# main:10  ✳ Claude Code
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak-sandbox/42569d54-d339-4dac-a5d0-9fe01269743e.jsonl
tmux respawn-pane -k -t main:10.0 -c '/home/tnunamak/sandbox' 'claude --resume 42569d54-d339-4dac-a5d0-9fe01269743e --dangerously-skip-permissions'   # claude

# main:13  pdpp
#   transcript: /home/tnunamak/.codex/sessions/2026/07/27/rollout-2026-07-27T14-27-47-019fa50c-32ac-7673-b25a-fc8078cec7d5.jsonl
tmux respawn-pane -k -t main:13.0 -c '/home/tnunamak/code/pdpp' 'codex resume 019fa50c-32ac-7673-b25a-fc8078cec7d5'   # codex

# main:14  ✳ Check memo and review Grafana data
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak-sandbox/47fd3267-7d5e-45af-89dd-a8d2a493d248.jsonl
tmux respawn-pane -k -t main:14.0 -c '/home/tnunamak/sandbox' 'claude --resume 47fd3267-7d5e-45af-89dd-a8d2a493d248 --dangerously-skip-permissions'   # claude

# main:15  zsh
#   transcript: /home/tnunamak/.claude-odl/projects/-home-tnunamak-code-pdpp/8b2c8ac0-a286-48e1-b140-253d6b93668c.jsonl
tmux respawn-pane -k -t main:15.0 -c '/home/tnunamak/.claude/projects/-home-tnunamak-code-pdpp' 'claude --resume 8b2c8ac0-a286-48e1-b140-253d6b93668c --dangerously-skip-permissions'   # claude

# main:16  ✳ Improve data connector developer experience and reliability
#   transcript: /home/tnunamak/.claude-odl/projects/-home-tnunamak/1f934c1f-19c7-4d9d-9b1d-52f5e457e91e.jsonl
tmux respawn-pane -k -t main:16.0 -c '/home/tnunamak' 'claude --resume 1f934c1f-19c7-4d9d-9b1d-52f5e457e91e --dangerously-skip-permissions'   # claude

# main:17  ✳ Claude Code
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak-applications-SillyTavern/58979a73-f78b-437a-a591-9a8bd06076f9.jsonl
tmux respawn-pane -k -t main:17.0 -c '/home/tnunamak/applications/SillyTavern' 'claude --resume 58979a73-f78b-437a-a591-9a8bd06076f9 --dangerously-skip-permissions'   # claude

# main:19  ✳ Fix excessive Plasma notifications in Kitty tmux setup
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak-code-dotfiles/66850dc0-bec5-47ac-9554-487d12bfb62b.jsonl
tmux respawn-pane -k -t main:19.0 -c '/home/tnunamak/code/dotfiles' 'claude --resume 66850dc0-bec5-47ac-9554-487d12bfb62b --dangerously-skip-permissions'   # claude

# main:21  ✳ Transfer pdpp.dev domain and add copyright footer
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak/3f537a60-273f-4377-a7e1-05cdfa933cef.jsonl
tmux respawn-pane -k -t main:21.0 -c '/home/tnunamak' 'claude --resume 3f537a60-273f-4377-a7e1-05cdfa933cef --dangerously-skip-permissions'   # claude

# main:22  ✳ Vana Privy facilitator security implementation plan
#   transcript: /home/tnunamak/.claude-odl/projects/-home-tnunamak-code-vana-node-ops/4c9ad3f0-cb00-40cc-8bb9-baad3a7f16e5.jsonl
tmux respawn-pane -k -t main:22.0 -c '/home/tnunamak/code/vana-node-ops' 'claude --resume 4c9ad3f0-cb00-40cc-8bb9-baad3a7f16e5 --dangerously-skip-permissions'   # claude

# main:24  sandbox
#   transcript: /home/tnunamak/.codex/sessions/2026/02/27/rollout-2026-02-27T21-46-01-019ca25a-6e4c-7d03-b80f-8a6da17a91c3.jsonl
tmux respawn-pane -k -t main:24.0 -c '/home/tnunamak' 'codex resume 019ca25a-6e4c-7d03-b80f-8a6da17a91c3'   # codex

# main:26  ✳ Initialize new session
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak/028cfed9-8046-4929-b0c4-fe4e7b068369.jsonl
tmux respawn-pane -k -t main:26.0 -c '/home/tnunamak' 'claude --resume 028cfed9-8046-4929-b0c4-fe4e7b068369 --dangerously-skip-permissions'   # claude

# main:28  archive-2
#   transcript: /home/tnunamak/.codex/sessions/2026/08/11/rollout-2026-08-11T09-41-16-019ff145-437b-7360-8693-8adb853b5410.jsonl
tmux respawn-pane -k -t main:28.0 -c '/home/tnunamak' 'codex resume 019ff145-437b-7360-8693-8adb853b5410'   # codex

# main:31  ✳ Audio book generation from EPUBs
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak-Downloads/929c055b-4f26-404e-95c0-84bb92aba475.jsonl
tmux respawn-pane -k -t main:31.0 -c '/home/tnunamak/Downloads' 'claude --resume 929c055b-4f26-404e-95c0-84bb92aba475 --dangerously-skip-permissions'   # claude

# main:33  ✳ Debug signal launch issue
#   transcript: /home/tnunamak/.claude/projects/-home-tnunamak/ff819ac4-f054-4918-9c2d-edddd4da0b14.jsonl
tmux respawn-pane -k -t main:33.0 -c '/home/tnunamak/code/pdpp' 'claude --resume ff819ac4-f054-4918-9c2d-edddd4da0b14 --dangerously-skip-permissions'   # claude

# 18 recoverable sessions.
