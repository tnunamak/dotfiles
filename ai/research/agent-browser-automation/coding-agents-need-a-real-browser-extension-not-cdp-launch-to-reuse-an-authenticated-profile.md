---
title: "Coding agents need a real browser extension (not a CDP-launched profile) to reuse an already-authenticated Chrome/Brave session, because Chrome 136+ blocks remote debugging on the default profile"
date: 2026-08-18
topic: agent-browser-automation
tags: [playwright, chrome-devtools-mcp, claude-in-chrome, cdp, remote-debugging, browser-profile]
status: draft
sources: [chrome-136-lockdown, playwright-mcp-cdp, claude-in-chrome-docs, codex-chrome-extension]
source_session: 708c0e01-a1d3-4cd3-b940-9c749f013f1e
---

## CLAIMS

- Since Chrome 136, browsers in the Chromium family (including Brave) refuse `--remote-debugging-port` against the user's real default profile directory; this is a deliberate anti-cookie-theft hardening measure, not a bug. [chrome-136-lockdown]
- Generic MCP browser tools that spawn their own Chromium process (`@playwright/mcp`, `chrome-devtools-mcp` in its default mode) get a **clean, logged-out profile** by default — none of the user's cookies, extensions, or wallet state carry over. [playwright-mcp-cdp]
- The two workarounds for giving such a tool an authenticated profile are: (a) copy the real profile directory once into a dedicated debug-profile directory and launch the browser against that copy with `--remote-debugging-port` + `--user-data-dir`, or (b) the newer Chrome M144+ (beta) `--autoConnect` flow, where the agent requests a debugging connection to the browser the user is already running and the user clicks an in-browser "Allow" dialog per session. [playwright-mcp-cdp]
- Chromium/Brave enforces single-instance access to a `--user-data-dir` via a `SingletonLock` symlink (hostname-PID); launching a second process against a profile that's already open does not corrupt data — it either hands the request off to the existing window via a `SingletonSocket`, or the new process exits. It does not, however, give the new process CDP control of that already-running instance. [chrome-136-lockdown]
- Anthropic's official "Claude in Chrome" extension sidesteps all of this: it runs as a real installed browser extension inside the user's actual, already-logged-in browser, so cookies/sessions/extensions (e.g. a wallet extension) are available immediately with no separate profile or CDP port. It works in Chrome and Edge natively, and is auto-detected/set up in Brave, Arc, Vivaldi, and Opera as well (not in WSL). Setup: install the extension, then run `/chrome` in Claude Code and select "Enabled by default." [claude-in-chrome-docs]
- OpenAI's equivalent, "Codex for Chrome," is an extension-based approach with the same profile-reuse property, but it is exclusive to the **Codex desktop app** — the Codex **CLI** has no native equivalent and is limited to MCP-based browser tools (Playwright/chrome-devtools-mcp), which fall back to the clean-profile behavior above. [codex-chrome-extension]

## SOURCES

**chrome-136-lockdown**
URL: https://raf.dev/blog/chrome-debugging-profile-mcp/
Accessed: 2026-08-18
Quote: "Starting with Chrome 136, remote debugging is blocked on your default profile for security reasons, preventing attackers from exploiting remote debugging to steal cookies."

**playwright-mcp-cdp**
URL: https://github.com/microsoft/playwright-mcp/issues/1319
Accessed: 2026-08-18
Quote: "Connect to any Chromium-based browser with a Chrome DevTools Protocol endpoint" using args like `["@playwright/mcp@latest", "--cdp-endpoint=http://localhost:9222"]`

**claude-in-chrome-docs**
URL: https://code.claude.com/docs/en/chrome
Accessed: 2026-08-18
Quote: "Because it runs as a real browser extension, it uses your actual browser profile, so cookies and login sessions carry over automatically — no separate setup needed."

**codex-chrome-extension**
URL: https://knightli.com/en/2026/06/17/codex-computer-use-chrome-browser-guide/
Accessed: 2026-08-18
Quote: "The Chrome Extension is a feature of the Codex desktop app (the GUI application), not the Codex CLI (the terminal tool). The CLI's browser capabilities remain limited to the $playwright-interactive skill and MCP-based DevTools servers."

## SYNTHESIS

The mental model to keep: MCP-launched browser tools (our host `playwright-mcp.service`, or `chrome-devtools-mcp` in its default mode) are "a lab with a clean beaker" — reproducible but logged out. Getting them to reuse a real, authenticated session always costs either a one-time profile copy (stale extensions/cookies snapshot, needs periodic re-copy) or a per-session click-through (`--autoConnect`, if the local Chrome/Brave build supports the M144+ beta feature — unconfirmed for our installed Brave version as of this session).

The actually-frictionless path for Claude Code specifically is the official "Claude in Chrome" extension, which we have not installed. For any future task that needs to drive a site the user is already logged into (wallet-gated pages, SSO'd internal tools), default to recommending `/chrome` setup over hand-rolling a Playwright CDP profile-copy — it's less fragile and doesn't require touching the shared `playwright-mcp.service` used by other sessions/devcontainers.

Also worth remembering operationally: our current `~/.local/bin/playwright-mcp-server` launches a bundled Chromium with no `--browser`/`--executable-path` override and no CDP passthrough — reconfiguring it to use Brave's binary would still only get a *fresh* Brave profile, not the user's real one, unless combined with the profile-copy step above.
