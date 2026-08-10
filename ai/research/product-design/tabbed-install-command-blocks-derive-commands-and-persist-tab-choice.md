---
title: "Tabbed install-command blocks in developer docs should derive commands from one input and persist the tab choice across pages, and the strongest examples strip everything except tabs plus one command"
date: 2026-08-05
topic: product-design
tags: [developer-docs, install-command, tabs, code-block, onboarding, quickstart, opencode, turborepo]
status: draft
sources: [turborepo-install, retroui-pr63, ni-cli, opencode-screenshot]
source_session: 740f664e-caeb-419c-a8ad-fd03c81b61fb
---

<!--
Captured while building the PDPP /reference (Self-Host) page, which needed a
Docker/Compose/Railway tabbed command block. The owner supplied the opencode.ai
screenshot as the reference pattern.
-->

## CLAIMS

- Turborepo's installation docs render one tab per package manager (pnpm, yarn, npm, bun), each panel holding the equivalent command, and reuse the same component for dev-dependency installs where the commands diverge more sharply [turborepo-install]
- The component is justified by genuinely incompatible syntax rather than trivial aliases: adding a package is `npm i react` / `yarn add react` / `pnpm add react` / `bun add react`, and dev dependencies split four ways as `npm install --save-dev` / `yarn add -D` / `pnpm add -D` / `bun add -d` [turborepo-install]
- Package managers resolve dependencies differently and are not fully compatible, so installing with the wrong one can break a project, and mixed lockfiles are cited as the leading cause of "works locally, breaks in CI" [turborepo-install]
- A documented implementation (RetroUI PR #63) replaced hand-authored multiline code blocks across all component and setup guides with a single prop-based component that takes the package name and derives the four commands [retroui-pr63]
- The same implementation bundles one-click copy per panel [retroui-pr63]
- CI variants diverge more than install commands do: npm's clean install is a separate command (`npm ci`), pnpm uses `--frozen-lockfile`, and Yarn splits by generation — `--frozen-lockfile` for Yarn 1 versus `--immutable` for Yarn Berry [turborepo-install]
- `ni` auto-selects a package manager by scanning for `yarn.lock`, `pnpm-lock.yaml`, `package-lock.json`, `bun.lockb`, or `deno.json`; a docs site cannot read the reader's filesystem, so the equivalent fallback for default-tab selection is localStorage [ni-cli]
- Documenting a unified CLI (`ni vite` resolving to the right manager) is the alternative that removes tabs entirely, but it adds an install step for the reader, so most public-facing docs still prefer tabs [ni-cli]
- The opencode.ai install block is a single bordered panel containing only a row of plain-text tabs (curl, npm, bun, brew, paru) above a thin rule, and one command on one line — no heading, no explanatory sentence, no button styling on the tabs, no icons [opencode-screenshot]
- In that block the active tab is brighter with an underline inset to the label width while inactive tabs are dimmed, and within the command only the domain (`opencode.ai/install`) is brightened while the surrounding `curl -fsSL`, `|`, and `bash` recede [opencode-screenshot]

## SOURCES

**turborepo-install**
URL: https://turborepo.dev/docs/getting-started/installation
Accessed: 2026-08-05
Quote: "tabs for pnpm, yarn, npm, and bun, each showing a terminal snippet"

**retroui-pr63**
URL: https://github.com/Logging-Studio/RetroUI/pull/63
Accessed: 2026-08-05
Quote: "added a tabbed interface supporting npm, yarn, pnpm, and bun with one-click copy… replaced multiline code blocks across all component and setup guides with concise, prop-based components"

**ni-cli**
URL: https://wicksipedia.com/blog/ni-universal-package-manager/
Accessed: 2026-08-05
Quote: "`ni vite` resolves to `npm i vite`, `yarn add vite`, `pnpm add vite`, `bun add vite`, or `deno add vite` as appropriate"

**opencode-screenshot**
URL: local file /home/tnunamak/.tmp/Screenshot_20260804_232357.png (opencode.ai install block, supplied by the PDPP owner as the reference pattern)
Accessed: 2026-08-05

## SYNTHESIS

Two design rules worth carrying into any tabbed command block:

**Derive, don't duplicate.** Hand-authoring N snippets per page does not scale and
guarantees drift — the RetroUI refactor exists precisely because the literal
strings had spread across every guide. Take one input (package name, or in our
case an image reference) and generate the variants.

**Persist the tab choice.** A pnpm user re-clicking the pnpm tab on every docs
page is the default failure mode. localStorage is the docs-site equivalent of
`ni`'s lockfile detection.

The opencode block is the strongest visual reference because of what it omits.
Tabs carry the choice, the command carries the instruction, and nothing else is
present — no heading, no lead-in sentence. Most docs pages explain before they
instruct; this inverts that. The selective emphasis is the subtle part: brightening
only the meaningful token (the domain) and dimming the boilerplate flags gives the
eye a landing spot inside a monospace line that would otherwise read as uniform
texture. The equivalent for a `docker run` line is the image reference.

Caveat on emphasis: it only works when exactly one token matters. A command where
the flags are the point (port mappings, volume mounts) would be actively harmed by
dimming them, so this is a judgment call per command, not a blanket rule.
