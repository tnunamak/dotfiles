---
title: "SSH hardening norm is key-only, while key plus password is a separate two-factor choice"
date: 2026-07-23
topic: self-hosting
tags: [ssh, authentication, security, keys, passwords]
status: settled
sources: [ubuntu-openssh, ubuntu-ssh-hardening, openssh-authenticationmethods]
source_session: 019f904c-e840-76e2-a0ee-27213e56ef83
---

## CLAIMS

- Ubuntu documents SSH public-key authentication as passwordless host authentication using a private/public key pair. [ubuntu-openssh]
- Ubuntu's SSH hardening guidance recommends disabling password authentication when key-based access is reliably available, while noting that doing so removes unapproved-device access and recovery from a lost key. [ubuntu-ssh-hardening]
- OpenSSH documents `AuthenticationMethods` as a mechanism for requiring every method in a listed sequence; `publickey,password` is therefore a deliberate two-factor policy rather than the default single-method behavior. [openssh-authenticationmethods]

## SOURCES

**ubuntu-openssh**
URL: https://ubuntu.com/server/docs/openssh-server/
Accessed: 2026-07-23
Quote: "SSH allows authentication between two hosts without the need of a password, using cryptographic keys instead."

**ubuntu-ssh-hardening**
URL: https://help.ubuntu.com/community/SSH/OpenSSH/Configuring
Accessed: 2026-07-23
Quote: "It's recommended to disable password authentication unless you have a specific reason not to."

**openssh-authenticationmethods**
URL: https://manpages.ubuntu.com/manpages/noble/man5/sshd_config.5.html
Accessed: 2026-07-23
Quote: "successful authentication requires completion of every method in at least one of these lists."

## SYNTHESIS

For an internet-facing managed server, key-only is the normal hardened baseline; it removes online password
guessing. Key plus password is a valid deliberate second factor, but it is not required merely because keys
exist and often adds more friction than a purpose-built second factor (FIDO/TOTP). A personal workstation
with an intentional password-SSH use case may retain password authentication, but should make that exposure
decision explicitly (network reachability, strong unique password, and recovery needs) rather than inherit it
as an unnoticed default.
