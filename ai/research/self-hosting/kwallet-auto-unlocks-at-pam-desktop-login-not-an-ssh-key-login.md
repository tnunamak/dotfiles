---
title: "KWallet auto-unlocks at PAM desktop login, not an SSH key login"
date: 2026-07-23
topic: self-hosting
tags: [kwallet, ssh, pam, kubuntu, secrets]
status: settled
sources: [kwallet-handbook, kwallet-pam-source, kwallet-runtime-source, archwiki-kwallet-terminal, reddit-kwallet-ssh, reddit-nonpassword-login]
---

## CLAIMS

- KDE documents that the default KWallet is secured by the login password and automatically opens at login only when `kwallet_pam` is installed and properly configured. [kwallet-handbook]
- Upstream `kwallet-pam` source confirms that the auth hook stores `PAM_AUTHTOK`, while the session hook refuses non-graphical sessions unless passed `force_run`; with it, the module forks `kwalletd` and hands over the derived wallet key. [kwallet-pam-source]
- Current upstream KWallet runs the real wallet backend in `ksecretd`; a PAM-launched `ksecretd --pam-login` replaces a prematurely D-Bus-activated instance and calls `pamOpen()` with the handed-off password hash. `kwalletd6` is a compatibility frontend, so its `isOpen` result is not authoritative for the modern backend. [kwallet-runtime-source]
- ArchWiki documents querying KWallet outside a graphical session with `QT_QPA_PLATFORM=offscreen`, including for unattended scripts. [archwiki-kwallet-terminal]
- A community-tested SSH pattern uses `AuthenticationMethods publickey,password`, passes that password to `pam_kwallet5`, starts the non-graphical wallet session with `force_run`, and runs `pam_kwallet_init` from the login profile before querying the wallet. [reddit-kwallet-ssh]
- KDE users report that passwordless, automatic, fingerprint, and other alternative login methods cannot auto-unlock KWallet because PAM has no matching wallet password; normal password login with PAM is the working case. [reddit-nonpassword-login]

## SOURCES

**kwallet-handbook**
URL: https://docs.kde.org/stable_kf6/en/kwalletmanager/kwalletmanager/introduction.html
Accessed: 2026-07-23
Quote: "This wallet is secured by your login password and will automatically be opened at login, if kwallet_pam is installed and properly configured."

**kwallet-pam-source**
URL: https://invent.kde.org/plasma/kwallet-pam/-/blob/b8d072b06d7f181ff57f26f447459515c6ca299b/pam_kwallet.c
Accessed: 2026-07-23
Evidence: `pam_sm_authenticate()` reads and stores `PAM_AUTHTOK`;
`pam_sm_open_session()` checks `is_graphical_session()` and otherwise returns
unless `force_run` was parsed. `start_kwallet()` then forks the configured
`kwalletd` with the PAM login pipe and socket.

**kwallet-runtime-source**
URL: https://invent.kde.org/frameworks/kwallet/-/blob/00e578db1e10b3a4d3cc008edc7b7912d4a3c8ca/src/runtime/ksecretd/main.cpp
Accessed: 2026-07-23
Evidence: the `--pam-login` path reads the hash and environment from PAM,
registers `KDBusService::Replace` to replace an already D-Bus-activated
instance (the source cites BUG 509680), and passes the hash to
`KSecretD::pamOpen()`. The same source tree implements `kwalletd6` as a
compatibility frontend over the secret-service backend.

**archwiki-kwallet-terminal**
URL: https://wiki.archlinux.org/title/KDE_Wallet
Accessed: 2026-07-23
Quote: "In order to run `kwallet-query` outside of a graphical session ... set the `QT_QPA_PLATFORM=offscreen` environment variable."

**reddit-kwallet-ssh**
URL: https://www.reddit.com/r/kde/comments/qhw08j/how_do_i_unlock_kwallet_when_logging_in_via/
Accessed: 2026-07-23
Quote: "The below solution is used to unlock kwallet when logging into a machine via ssh."
Evidence: the working configuration uses
`AuthenticationMethods publickey,password`, `PasswordAuthentication yes`,
`UsePAM yes`, the guarded auth/session hooks, `force_run`, and a login-profile
call to the PAM-to-wallet environment handoff helper.

**reddit-nonpassword-login**
URL: https://www.reddit.com/r/kde/comments/1ux3ocy/kde_wallet_pisses_me_off/
Accessed: 2026-07-23
Quote: "It breaks easily via alternative methods of login, such as passwordless, automatic or via another identification method."

## SYNTHESIS

On peregrine, the active SDDM configuration auto-logs in `tnunamak`; its `sddm-autologin` PAM stack has no
`pam_kwallet5` entries, unlike the ordinary SDDM stack. Thus a reboot opens Plasma without unlocking KWallet.
`pam_kwallet5` is also absent from SSH and TTY `login` PAM stacks. SSH-public-key-only access has no
desktop-login password to pass into KWallet and therefore cannot automatically unlock it. A practical
personal-workstation policy is to configure `pam_kwallet5` in `/etc/pam.d/sshd` and `/etc/pam.d/login`:
password SSH and TTY login can unlock the wallet when their session lines include `force_run`, while
key-only SSH has no password for the auth hook to capture. This is remote unlock, not
physical-presence-only unlock. Requiring a public key plus password is also possible, but is a separate
friction/security policy—not a KWallet requirement.

For SSH, the proven community path is specifically `publickey,password`.
`publickey,keyboard-interactive:pam` authenticated correctly on peregrine but
failed the wallet handoff: OpenSSH ran the auth and session hooks in different
processes, and the session hook logged `open_session called without
kwallet5_key`. The password method must therefore be used here. The login shell
must also run `pam_kwallet_init` before attaching to the pre-existing tmux
server; otherwise the PAM socket environment is lost before the helper can
release the waiting `kwalletd`.

On peregrine, a successful `publickey,password` SSH login produced one PAM
process for authentication and session setup, created
`/run/user/1000/kwallet5.socket`, and launched
`/usr/bin/ksecretd --pam-login`. The authoritative
`org.kde.ksecretd /ksecretd org.kde.KWallet.isOpen kdewallet` call returned
`true`, and `QT_QPA_PLATFORM=offscreen kwallet-query -l kdewallet` listed entry
names without reading values. The compatibility `org.kde.kwalletd6` service
simultaneously returned `false`; do not use that interface as the health check.

The causal test also passed: close `kdewallet` through `org.kde.ksecretd` and
confirm `isOpen=false`; fully disconnect the existing SSH transport; reconnect
without answering any KDE prompt. The new login used a different TCP port,
logged password acceptance and the PAM socket in one SSH session process,
started a new `ksecretd --pam-login`, and left `isOpen=true`. A value-blind
`kwallet-query -l` then succeeded. This proves the SSH password/PAM path—not a
manual desktop unlock—opened the wallet.
