---
title: "The distro arbitrates SSH_AUTH_SOCK through an ordered chain of systemd socket units, so a shell-spawned ssh-agent is a fourth competing agent rather than a fallback"
date: 2026-09-10
topic: developer-environments
tags: [ssh, ssh-agent, gcr, gnome-keyring, systemd, shell-config, git-signing]
status: verified
sources: [arch-psa, arch-gcr-cli, nixos-hijack, fedora-reboot, arch-multiple-sshadd, unit-gcr-socket, unit-ssh-agent-socket, local-machine]
source_session: e746f9e7-2e8a-4f03-8c46-bc761f4ad161
---

## CLAIMS

- On a systemd distro with gcr installed, three user socket units may each set `SSH_AUTH_SOCK`
  in the systemd user environment, in a deliberate documented order: `ssh-agent.socket` →
  `gcr-ssh-agent.socket` → `gpg-agent-ssh.socket`. Last writer wins. [unit-gcr-socket]
- `gcr-ssh-agent.socket` declares this arbitration in its own unit comments: "If gcr is
  installed, take priority in setting SSH_AUTH_SOCK over ssh-agent" (`After=ssh-agent.socket`)
  and "Conversly, allow gpg-agent-ssh to overwrite if explicitely enabled"
  (`Before=gpg-agent-ssh.socket`). [unit-gcr-socket]
- Both units export the variable via `ExecStartPost=... systemctl --user set-environment
  SSH_AUTH_SOCK=%t/...`. `ssh-agent.socket` uses `%t/openssh_agent`; `gcr-ssh-agent.socket`
  uses `%t/gcr/ssh`. [unit-gcr-socket] [unit-ssh-agent-socket]
- GNOME Keyring 1:46.1 moved the SSH component out of `gnome-keyring-daemon` into
  `/usr/lib/gcr-ssh-agent` (the gcr-4 package) specifically "so that systemd can manage it".
  The stated plan is to remove the gnome-keyring-daemon implementation entirely. [arch-psa]
- The widely-reproduced community fix for the resulting unset/wrong variable is to set
  `SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh` declaratively in
  `~/.config/environment.d/*.conf` — not in a shell rc file. [arch-psa]
- `gcr-ssh-agent.service` is `WantedBy=graphical-session-pre.target`, so it is not started by
  a non-graphical login; `ssh-agent.socket` is `WantedBy=sockets.target` and is not
  graphical-session-gated. [unit-gcr-socket] [unit-ssh-agent-socket] [local-machine]
- gcr routes passphrase prompts through a GUI askpass. Over a plain SSH login with
  `SSH_AUTH_SOCK` pointing at gcr, key auth can hang while a GUI prompt waits on the remote
  desktop; unsetting `SSH_AUTH_SOCK` for the session restores CLI key auth. [arch-gcr-cli]
- gcr does not auto-unlock a passphrased key at login the way users expect: on Fedora 43 the
  key reappears in `ssh-add -l` after reboot yet signing fails with "agent refused operation"
  until `ssh-add` is re-run. The reporter resolved it by removing the passphrase. [fedora-reboot]
- A misconfigured or unsupported-key gcr agent can spawn accumulating background `ssh-add`
  processes at high CPU; one reporter traced it to gcr logging that ed25519 keys were
  unsupported and fixed it by switching back to plain `ssh-agent`. [arch-multiple-sshadd]
- Disabling the gcr SSH component while keeping gnome-keyring for other secrets is not
  reliably supported: `services.gnome.gcr-ssh-agent.enable = false`, a
  `gnome-keyring-3/daemon.ini` `[components] ssh=false`, and limiting
  `services.gnome-keyring.components` all failed to stop the `SSH_AUTH_SOCK` override; the
  reporter fell back to symlinking their preferred agent socket onto the gcr path. [nixos-hijack]
- Measured on this host (Ubuntu 26.04.1, OpenSSH 10.2p1): three agents ran concurrently with
  three different key sets — `%t/openssh_agent` (0 keys, unit enabled+active), `%t/gcr/ssh`
  (7 keys, the path systemd actually exported), and a shell-spawned agent reached via a
  `~/.ssh/ssh_auth_sock` symlink (4 keys, what interactive shells used). Eight orphaned
  `ssh-agent -s` processes had accumulated. [local-machine]

## SOURCES

**unit-gcr-socket**
URL: file:///usr/lib/systemd/user/gcr-ssh-agent.socket (+ gcr-ssh-agent.service)
Accessed: 2026-09-10
Quote: "# If gcr is installed, take priority in setting SSH_AUTH_SOCK over ssh-agent
After=ssh-agent.socket
# Conversly, allow gpg-agent-ssh to overwrite if explicitely enabled
Before=gpg-agent-ssh.socket
[Socket]
ListenStream=%t/gcr/ssh
ExecStartPost=-/usr/bin/systemctl --user set-environment SSH_AUTH_SOCK=%t/gcr/ssh"

**unit-ssh-agent-socket**
URL: file:///usr/lib/systemd/user/ssh-agent.socket
Accessed: 2026-09-10
Quote: "ListenStream=%t/openssh_agent
ExecStartPost=/usr/bin/systemctl --user set-environment SSH_AUTH_SOCK=%t/openssh_agent
ExecStopPre=/usr/bin/systemctl --user unset-environment SSH_AUTH_SOCK"

**arch-psa**
URL: https://www.reddit.com/r/archlinux/comments/1avuxcw/psa_gnome_keyring_1461_may_break_your_sshagent/
Accessed: 2026-09-10
Quote: "GNOME made some breaking changes that basically breaks the 'old' ssh-agent since they're
migrating it away from gnome-keyring-daemon to gcr so that systemd can manage it." … comment:
"To fix it, I set this environment variable: SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh — I put it
in ~/.config/environment.d/gcr-ssh-agent.conf"

**arch-gcr-cli**
URL: https://www.reddit.com/r/archlinux/comments/1bsxiyz/ssh_agent_gcr_doesnt_work_on_cli/
Accessed: 2026-09-10
Quote: "Yesterday, I wanted to do the same, but it just stuck on ssh user@…. Turns out, a GUI
opened up on the work laptop, and asked for my private key's password. … I'm using
$SSH_AUTH_SOCK=/run/user/1000/gcr/ssh". Cross-posted as r/hyprland/1bsyoo8; reporter confirms
the same behavior under xfce, ruling out the compositor.

**fedora-reboot**
URL: https://www.reddit.com/r/Fedora/comments/1rok743/fedora_43_sshagent_refusing_key_after_reboot/
Accessed: 2026-09-10
Quote: "sign_and_send_pubkey: signing failed for ED25519 … from agent: agent refused operation
… echo $SSH_AUTH_SOCK → /run/user/1000/gcr/ssh … after every reboot the same error comes back,
and I have to add the key again even though it appears with ssh-add -l. … UPDATE: I ended up
just removing the passphrase from the key."

**arch-multiple-sshadd**
URL: https://www.reddit.com/r/archlinux/comments/156lm8v/multiple_sshadd_processes_running_in_the/
Accessed: 2026-09-10
Quote: "I checked the logs for gnome-keyring and it seems to complain that ed25519 keys are not
supported. I've switched to the standard ssh-agent and the duplicate processes are no longer
being created." … "more than 10 ssh-add commands and gcr-ssh-agent maxing out multiple cpu
threads since having to start using it with gnome-keyring-daemon's removal of the ssh component"

**nixos-hijack**
URL: https://www.reddit.com/r/NixOS/comments/1ow3ha4/gnomekeyring_hijacks_ssh_auth_sock_variable/
Accessed: 2026-09-10
Quote: "Despite this, after logging in, my SSH_AUTH_SOCK is always [gcr] ssh. If I disable
services.gnome.gnome-keyring completely, my variable is set correctly, but then I lose the
keyring for other applications." … workaround: "Force the gnome-keyring ssh socket path to
point to the bitwarden agent socket."

**local-machine**
URL: n/a — direct measurement, host peregrine, Ubuntu 26.04.1 LTS, OpenSSH_10.2p1
Accessed: 2026-09-10
Quote: "systemctl --user show-environment → SSH_AUTH_SOCK=/run/user/1000/gcr/ssh;
SSH_AUTH_SOCK=/run/user/1000/openssh_agent ssh-add -l → 'The agent has no identities.';
SSH_AUTH_SOCK=/run/user/1000/gcr/ssh ssh-add -l → 7 keys;
SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock ssh-add -l → 4 keys"

## SYNTHESIS

There is an objectively correct design here, and it is written down in the shipped unit files
rather than settled by community vote: the distro elects one agent through an ordered chain of
socket units and exports its path into the systemd user environment. Everything downstream is
supposed to inherit that. A shell rc block that spawns its own `ssh-agent` is therefore not a
fallback layered under the system mechanism — it is a fourth competitor that shadows the
elected agent for interactive shells only, which is exactly how a host ends up with several
agents holding different key sets and a signing key that is present or absent depending on
which process is asking.

Reddit did not decide the arbitration question, but it was worth checking for three things the
unit files do not say. First, it independently confirms the mechanism and dates the migration
(gnome-keyring 46.1, SSH moved to gcr explicitly "so that systemd can manage it"). Second, it
establishes the idiomatic override point: `~/.config/environment.d/*.conf`, which is
declarative, applies to graphical and non-graphical logins alike, and reaches non-shell
consumers — a shell rc file reaches none of those. Third, and most useful, it surfaces the
failure modes of committing fully to gcr, which the units are silent about: GUI askpass
hanging CLI/SSH logins, passphrased keys not actually auto-unlocking across reboot, and
runaway `ssh-add` spawning on unsupported keys. Those are the real arguments for keeping plain
`ssh-agent` as the elected agent rather than gcr.

The load-bearing caveat for any consolidation: `gcr-ssh-agent.service` is
`WantedBy=graphical-session-pre.target`, so a headless/SSH login does not get it, while
`ssh-agent.socket` is not graphical-session-gated. Whichever agent is chosen, the non-graphical
path must be tested separately before deleting a shell-level fallback — the two login types do
not exercise the same units.
