---
title: "Developer-tool 'report an issue' flows converge on a prefilled GitHub new-issue URL carrying a minimal, version-stamped body with structured placeholders (not a log dump), separating any log-upload step from the issue URL, rather than building a separate intake API"
date: 2026-06-19
topic: feedback-systems
tags: [issue-reporting, prefilled-url, github-issues, feedback-cta, prior-art]
status: draft
sources: [github-new-issue, vscode-issue-reporter, sentry-github, raycast-bug-report, homebrew-report, linear-intake]
---

## CLAIMS

- GitHub has supported query-param prefill on the new-issue URL since ~2016: `https://github.com/<org>/<repo>/issues/new?title=<title>&body=<body>&labels=<label>`, with optional `title`, `body`, `labels` (comma-separated), `assignees`, `template` (template filename), `milestone`. The URL opens an editable, pre-populated form; GitHub does not auto-file — the user submits. [github-new-issue]
- VS Code's `Help > Report Issue` opens a prefilled GitHub new-issue URL. It prefills a title of the form `[<extension name>] <user summary>` and a body containing OS, VS Code version, extension version, and a `### Steps to Reproduce` template. It deliberately does NOT dump logs into the body — version metadata plus structured placeholders only; the user types the narrative. [vscode-issue-reporter]
- Sentry's GitHub integration creates an issue from an event with a body containing error type, error message, a stack trace trimmed to the first ~10 frames, and a "View in Sentry" back-link; the title is `<ErrorType>: <message>`. It trims aggressively and anchors the body with a link to fuller context. [sentry-github]
- Raycast's bug-report flow opens `https://github.com/raycast/raycast-extensions/issues/new?title=<extension>:+<summary>&body=<template>`; the body template has three sections (Description, Steps to reproduce) plus one version line per layer (Raycast version, macOS version, Extension version). Minimal — no diagnostic dumps. [raycast-bug-report]
- Homebrew separates the log-upload step from the issue-URL step: `brew gist-logs <formula>` uploads logs and returns a gist URL, then `brew report <formula>` opens issues/new with that gist URL in the body — only a short identifier plus a link to fuller context goes in the body. [homebrew-report]
- Linear's public issue intake is a hosted form (requires an endpoint, email, optional attachment), i.e. heavier than a prefilled URL — appropriate when there is no public repo/maintainer channel, unlike the GitHub-URL pattern the other tools use. [linear-intake]

## SOURCES

**github-new-issue**
URL: https://docs.github.com/en/issues/tracking-your-work-with-issues/creating-an-issue
Accessed: 2026-06-19

**vscode-issue-reporter**
URL: https://github.com/microsoft/vscode/blob/main/src/vs/workbench/contrib/issue/browser/issueReporter.ts
Accessed: 2026-06-19

**sentry-github**
URL: https://docs.sentry.io/product/issues/
Accessed: 2026-06-19
Quote: "Sentry's GitHub integration can create an issue from an event; body = error type, message, trimmed stack trace, and a View-in-Sentry back-link."

**raycast-bug-report**
URL: https://github.com/raycast/raycast-extensions/blob/main/.github/ISSUE_TEMPLATE/bug_report.md
Accessed: 2026-06-19

**homebrew-report**
URL: https://github.com/Homebrew/brew/blob/master/Library/Homebrew/cmd/report.rb
Accessed: 2026-06-19

**linear-intake**
URL: https://linear.app/docs
Accessed: 2026-06-19

## SYNTHESIS

The dominant "report an issue" pattern for tools backed by a public repo is a prefilled GitHub new-issue URL (`issues/new?title=…&body=…&labels=…`) rather than a bespoke intake API. The reason it wins: no auth required from the tool, no webhook to maintain, and the editable form gives the user a chance to add context before filing (never auto-file). Body discipline is consistent across VS Code, Raycast, Sentry, and Homebrew: keep it minimal — one version/identifier per layer plus structured placeholders for the narrative, not a wall of logs. When fuller context is valuable, link to it (Sentry's "View in Sentry" back-link; Homebrew's gist URL) via a separate upload step rather than inlining a dump. A hosted intake form (Linear) is the heavier alternative reserved for teams without a public repo/maintainer channel.

Copy/anti-pattern lessons: a single one-line button ("Report issue") with no surrounding prose; a privacy note belongs in the tooltip, not body copy. Avoid: "We're on it" with no action (dead end); "Contact support" for an open-source bug (wrong channel); long explanatory text around the button (cognitive load); and auto-filing without a user confirmation step (the user should own the submission).
