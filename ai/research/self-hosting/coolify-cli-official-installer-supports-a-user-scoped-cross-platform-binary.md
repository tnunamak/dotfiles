---
title: "Coolify CLI's official installer supports a user-scoped cross-platform binary"
date: 2026-07-16
topic: self-hosting
tags: [coolify, cli, installation, macos, linux]
status: draft
sources: [coolify-cli-readme, coolify-cli-installer, coolify-cli-release]
source_session: 019f53bd-60e5-71b1-9b84-e6f065591556
---

## CLAIMS

- Coolify's official CLI supports Linux and macOS on amd64 and arm64, and its documented install script is the recommended installation method. [coolify-cli-readme]
- The official installer accepts `--user`, which installs the binary in `~/.local/bin` instead of `/usr/local/bin` and does not require sudo. [coolify-cli-installer]
- The CLI stores its configuration under `~/.config/coolify/config.json`; configuration and authentication are separate from installation. [coolify-cli-readme]
- Coolify's latest CLI release ships platform tarballs and Windows zip files, not Debian packages; its official installation options list an install script, Homebrew, and `go install`, with no apt repository or PPA. [coolify-cli-readme] [coolify-cli-release]

## SOURCES

**coolify-cli-readme**
URL: https://github.com/coollabsio/coolify-cli#installation
Accessed: 2026-07-16

**coolify-cli-installer**
URL: https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.sh
Accessed: 2026-07-16

**coolify-cli-release**
URL: https://github.com/coollabsio/coolify-cli/releases/latest
Accessed: 2026-07-16

## SYNTHESIS

Use the official installer with `--user` in the dotfiles bootstrap. That keeps the binary in the existing user-managed CLI location and leaves Coolify contexts and tokens as per-machine runtime state rather than repository configuration.
