---
title: "SSH commit signing is the passwordless agent-native path while OpenPGP uses a bounded passphrase cache"
date: 2026-08-14
topic: developer-environments
tags: [git, signing, ssh-agent, openpgp, github]
status: settled
sources: [github-verification, git-config, gnupg-agent]
source_session: unknown
---

## CLAIMS

- GitHub verifies commits signed with GPG, SSH, or S/MIME and describes SSH
  signatures as the simplest option for most individual users. An existing SSH
  authentication key may also be registered as a signing key. [github-verification]
- With `gpg.format=ssh`, Git accepts a public-key path in `user.signingKey` when
  the matching private key is available through `ssh-agent`. Local trust is
  established through `gpg.ssh.allowedSignersFile`. [git-config]
- GnuPG's supported unattended mechanism is an in-memory `gpg-agent` passphrase
  cache governed by default and maximum TTLs. External caches are pinentry- and
  desktop-dependent rather than a portable permanent-keychain contract.
  [gnupg-agent]

## SOURCES

**github-verification**
URL: https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification
Accessed: 2026-08-14

**git-config**
URL: https://git-scm.com/docs/git-config
Accessed: 2026-08-14

**gnupg-agent**
URL: https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html
Accessed: 2026-08-14

## SYNTHESIS

For a workstation that already has a durable, unlocked SSH agent, SSH commit
signing is the smallest passwordless design: it reuses the agent boundary instead
of introducing passphrase-at-rest automation. Register the exact public key with
the forge as a signing key and keep a local allowed-signers file so local and
remote verification agree.

OpenPGP remains appropriate where policy or its richer expiry/revocation model is
required. Its honest low-friction mode is a bounded in-memory agent cache with an
interactive unlock, not a machine-identity analogue or a plaintext passphrase
bootstrap.

