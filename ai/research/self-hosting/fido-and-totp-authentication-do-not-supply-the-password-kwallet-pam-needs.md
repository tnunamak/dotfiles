---
title: "FIDO and TOTP authentication do not supply the password KWallet PAM needs"
date: 2026-07-23
topic: self-hosting
tags: [kwallet, pam, ssh, fido, totp, authentication]
status: settled
sources: [archwiki-kwallet-pam, ubuntu-fido-ssh, ubuntu-totp-ssh, archwiki-gnome-keyring]
source_session: 019f8f55-9f2f-7ba1-92c2-2169a031a10f
---

## CLAIMS

- `kwallet-pam` auto-unlocks only when the KWallet password equals the current user password; it does not support GnuPG-backed wallets. [archwiki-kwallet-pam]
- OpenSSH FIDO keys use a hardware token to perform a cryptographic operation; the per-device key stays on the token, and use requires the device to be present. [ubuntu-fido-ssh]
- Ubuntu's documented SSH TOTP/HOTP configuration makes a public key the first factor, the one-time code the second, and disables password authentication. [ubuntu-totp-ssh]
- GNOME Keyring's PAM integration also unlocks its login keyring through `pam_gnome_keyring.so`; a fingerprint login does not unlock it. [archwiki-gnome-keyring]

## SOURCES

**archwiki-kwallet-pam**
URL: https://wiki.archlinux.org/title/KDE_Wallet
Accessed: 2026-07-23
Quote: "The chosen KWallet password must be the same as the current user password."

**ubuntu-fido-ssh**
URL: https://documentation.ubuntu.com/server/how-to/security/two-factor-authentication-with-u2f-or-fido/
Accessed: 2026-07-23
Quote: "the per-device key ... cannot be exported from the token hardware."

**ubuntu-totp-ssh**
URL: https://documentation.ubuntu.com/server/how-to/security/two-factor-authentication-with-totp-or-hotp/
Accessed: 2026-07-23
Quote: "The configuration presented here makes public key authentication the first factor, the TOTP/HOTP code the second factor, and makes password authentication unavailable."

**archwiki-gnome-keyring**
URL: https://wiki.archlinux.org/wiki/GNOME/Keyring
Accessed: 2026-07-23
Quote: "The PAM module pam_gnome_keyring.so initialises GNOME Keyring partially, unlocking the login keyring in the process."

## SYNTHESIS

No standard FIDO/U2F, smart-card, or TOTP setup can automatically unlock an existing
password-encrypted KWallet **without also obtaining the KWallet/account password**. These
mechanisms prove possession (and sometimes a local PIN or biometric) or verify a changing
one-time code; they do not release the Unix password to PAM. In OpenSSH FIDO-key login,
authentication happens through a signed challenge before PAM has any account password. In a
TOTP PAM flow, the supplied value is a one-time code, not the stable wallet password.

PAM can only pass a password to `pam_kwallet5` when some earlier authentication step actually
collected that password. Requiring password as an additional factor therefore works, but brings
back the friction Tim rejected. Making a FIDO key decrypt a separately stored copy of the
account password would require a custom, host-readable credential-unwrapping design; that is
not a supported KWallet/PAM feature and weakens the clean boundary that a hardware key normally
provides. A GnuPG-backed KWallet is a distinct design too, and `kwallet-pam` explicitly cannot
auto-unlock it. Switching to GNOME Keyring does not solve this class of problem: it is likewise
password/PAM-unlocked. KeePassXC is a good user-operated password manager, but replacing the
desktop Secret Service with it would require migration and integration work while still leaving a
master-password/key-file unlock decision.

For peregrine, the clean policy remains: a real password login (TTY or password SSH) can unlock
KWallet once `pam_kwallet5` is configured; public-key/FIDO-key SSH can authenticate without
unlocking it; desktop autologin leaves it locked until manually unlocked.
