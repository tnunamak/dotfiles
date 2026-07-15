---
title: "Current Pi uses the Earendil package, and extension-only updates do not update the Pi CLI"
date: 2026-07-13
topic: llm-integration
tags: [pi, updates, npm, provenance, extensions]
status: draft
sources: [pi-npm, pi-repository, pi-package-docs]
---

## CLAIMS

- The current published coding-agent package is `@earendil-works/pi-coding-agent`; npm lists version 0.80.6 and the `earendil-works/pi` repository. [pi-npm]
- The Earendil repository is the active Pi toolkit repository and its package documentation names `@earendil-works/pi-*` as the extension peer packages. [pi-repository] [pi-package-docs]
- Pi's current package documentation says `pi update --extensions` updates package extensions only, while `pi update` or `pi update --self` updates the CLI; `pi update --all` updates both CLI and packages. [pi-package-docs]

## SOURCES

**pi-npm**
URL: https://www.npmjs.com/package/@earendil-works/pi-coding-agent
Accessed: 2026-07-13

**pi-repository**
URL: https://github.com/earendil-works/pi
Accessed: 2026-07-13

**pi-package-docs**
URL: https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/packages.md
Accessed: 2026-07-13

## SYNTHESIS

Treat the Earendil package as current Pi, not as a stale third-party fork. Do not use `pi update --extensions` as evidence that the CLI itself is current: update the CLI explicitly (or use the documented all-update operation), then verify `pi --version` and the installed package name. Keep automation version-aware because Pi's update-command semantics have changed during active development.
