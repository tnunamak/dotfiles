---
title: "For a mobile-to-tmux workflow, connection-drop continuity belongs server-side in the tmux session, not in a mobile transport (mosh/et), because iOS kills the client anyway and mosh cannot attach a second client"
date: 2026-07-16
topic: session-ux
tags: [mosh, eternal-terminal, tmux, ios-background, reconnect, roaming]
status: draft
sources: [mosh-org, mosh-github, mosh-usenix, et-dev, et-compare, blink-persist, termius-ios-bg, vscode-remote, codespaces]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- Mosh's roaming works by making the source IP of any authenticated higher-sequence packet the server's new target, so a client that changes IP (wifi→cellular) or sleeps and wakes keeps the same session without re-establishing it. [mosh-org][mosh-usenix]
- Mosh runs its State Synchronization Protocol (SSP) over UDP and synchronizes only the *visible* terminal state, not full byte streams; scrollback is therefore incomplete and the documented workaround is to run screen or tmux. [mosh-org]
- Mosh explicitly does not support port forwarding or X forwarding, requires UDP datagrams between client and server, requires a UTF-8 environment, and must be installed on both client and server. [mosh-github][mosh-org]
- Mosh does not support tmux control mode (`tmux -CC`) or native terminal scrollback; scrolling is through mosh's own history. [et-compare]
- Eternal Terminal (et) initializes over ssh, then switches to its own TCP protocol to persist across IP changes and outages; unlike mosh it supports tmux control mode, native scrollback, and ssh tunneling. et must also be installed on both client and server. [et-dev][et-compare]
- Because a mosh-server accepts only its original client and cannot have a second/new client attach, Blink Shell's persistence across a full app kill would require storing the client credentials on disk to reconnect — a mosh-server does not natively let a fresh client attach to an existing session. [blink-persist]
- Termius (2026) reports that on iOS/iPadOS, recent app versions stop background activity "almost immediately, usually within 20 to 30 seconds" because the app "cannot keep running in the background because of iOS and iPadOS restrictions." Its recommended durable workaround is screen or tmux to preserve the terminal session if the connection drops. [termius-ios-bg]
- VS Code Remote-SSH has no native infinite session persistence; the recommended workaround is tmux/screen on the server plus SSH keepalives (`ServerAliveInterval`/`ClientAliveInterval`) and `ControlPersist`. [vscode-remote]
- GitHub Codespaces keeps the environment running server-side when the browser tab closes and lets a user reconnect from github.com/codespaces on any device, but a full *stop* discards the terminal's visible contents (history is preserved, live pane state is not) — so even the most server-side-managed product still relies on tmux/screen for live-pane continuity across a stop. [codespaces]

## SOURCES

**mosh-org**
URL: https://mosh.org/
Accessed: 2026-07-16
Quote: "Every time the server receives an authentic packet from the client with a sequence number higher than any it has previously received, the IP source address of that packet becomes the server's new target." / "Mosh synchronizes only the visible state of the terminal" / "put your laptop to sleep and wake it up later, keeping your connection intact."

**mosh-github**
URL: https://github.com/mobile-shell/mosh
Accessed: 2026-07-16
Quote: "Mosh does not support X forwarding or the non-interactive uses of SSH, including port forwarding." / "To function, Mosh requires UDP datagrams to be passed between client and server." / "requires a UTF-8 environment to run."

**mosh-usenix**
URL: https://www.usenix.org/system/files/login/articles/winstein.pdf
Accessed: 2026-07-16
Quote: Mosh paper — SSP synchronizes the state of a terminal object over UDP; the server retargets to the latest authenticated client source address, enabling roaming.

**et-dev**
URL: https://eternalterminal.dev/
Accessed: 2026-07-16
Quote: Eternal Terminal automatically reconnects without interrupting the session and supports tmux control mode.

**et-compare**
URL: https://moguzozcan.github.io/shell/bash/zsh/ssh/mosh/eternal%20terminal/tmux/sandboxing/container/virtual%20machine/vm/SSH-TLS-Mosh-Tmux-EternalTerminal/
Accessed: 2026-07-16
Quote: "The most important feature et has over mosh is that it supports the tmux control center flag, which you probably know as tmux -CC." / mosh "does not support tmux -CC, it also does not support ssh-tunneling."

**blink-persist**
URL: https://github.com/blinksh/blink/issues/59
Accessed: 2026-07-16
Quote: "Since mosh does not allow 'new' clients to attach to an existing mosh-server, Blink might store the client information on disk whenever a connection is first established, so that restarting the app could seamlessly reconnect, opening all the tabs from when the app was last running."

**termius-ios-bg**
URL: https://docs.termius.com/help-center/faq/how-can-i-keep-termius-sessions-alive-in-the-background-on-ios-ipados
Accessed: 2026-07-16
Quote: "Recent versions stop background activity almost immediately, usually within 20 to 30 seconds." / "Termius, like most other apps, cannot keep running in the background because of iOS and iPadOS restrictions." / "screen or tmux can preserve your terminal session if the connection drops."

**vscode-remote**
URL: https://code.visualstudio.com/docs/remote/troubleshooting
Accessed: 2026-07-16
Quote: Remote-SSH has no native persistent server session; use tmux/screen plus `ServerAliveInterval`/`ClientAliveInterval` and `ControlPersist` to survive drops.

**codespaces**
URL: https://docs.github.com/en/codespaces/developing-in-a-codespace/stopping-and-starting-a-codespace
Accessed: 2026-07-16
Quote: "if you're using a codespace in the VS Code web client and you close the browser tab, the codespace remains running on the remote machine." / "the visible contents of the terminal window are not preserved between codespace sessions."

## SYNTHESIS

For Tim's exact setup — mobile Termius → SSH → tmux on peregrine — the state that matters (windows, panes, running agents) already lives in tmux on the server. Mosh and et solve *transport* survival: keeping one client↔server pipe alive across a wifi→5G handoff or a sleep. That is a real problem, but it is the wrong layer to invest in here for three converging reasons:

1. **iOS defeats the transport anyway.** Termius itself says iOS kills its background activity in 20–30s. Mosh's "survive sleep" magic assumes the client process keeps running; when iOS suspends/kills Termius, there is no mosh client left to roam. Blink (a mosh-native app) hits the same wall — a killed app cannot re-attach to a mosh-server, which by design accepts only its original client. So on iOS, "the transport survived the drop" is frequently untrue regardless of mosh/et.

2. **tmux is already the state-holder.** Every product surveyed — VS Code Remote-SSH, Codespaces, Blink's own docs — falls back to "run tmux/screen server-side" for durable live state. When the real state is in tmux, the transport only needs to *reconnect fast to a still-alive session*, which plain SSH + a fast auto-attach on login achieves. The reconnect experience is "SSH in, re-attach," not "resume a roaming pipe."

3. **Termius doesn't support mosh** (verified separately; the mosh-support forum thread is a long-standing, unfulfilled request), and adopting mosh would mean giving up Termius's snippets/startup-command ergonomics that are themselves part of the reconnect solution (see the Termius-specific entry). et is a closer fit technically (TCP, tunneling, tmux -CC) but still requires a client that supports it — Termius doesn't — so it's a client-switch decision, not a bolt-on.

**Recommendation:** solve continuity purely server-side. Keep tmux as the authoritative state-holder; make reconnect cheap with a login auto-attach (ideally to a picker — see the front-door entry); layer SSH keepalives (`ServerAliveInterval`/`ClientAliveInterval`) so a half-dead pipe drops fast instead of hanging. Reserve mosh/et for a *desktop/laptop* client where the client process actually survives backgrounding and roaming pays off; it does not pay off under iOS Termius. The one thing a mobile transport genuinely buys — instant local echo on a laggy link — is a comfort feature, not a continuity feature, and does not justify leaving Termius.
