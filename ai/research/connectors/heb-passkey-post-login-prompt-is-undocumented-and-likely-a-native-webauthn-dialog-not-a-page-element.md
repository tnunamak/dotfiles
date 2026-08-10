---
title: "H-E-B's own help documentation describes passkey setup as account-settings-initiated, not an automatic post-login prompt, and general WebAuthn research shows this prompt class is commonly a native OS/browser dialog rather than a page DOM element"
date: 2026-08-07
topic: connectors
tags: [heb, passkey, webauthn, browser-automation, dismiss-selector, playwright]
status: draft
sources: [heb-whats-a-passkey, heb-add-passkey, heb-passkey-password-fallback, ms-qa-skip-ignored, fusionauth-webauthn-docs, webdev-conditional-create]
source_session: e420353d-98a9-49b9-b014-1fcb0fc780b0
---

## CLAIMS

- H-E-B's own help pages (`whats-a-passkey`, `how-do-i-add-a-passkey`) describe passkey
  setup as something the account holder initiates manually from account settings
  ("click the arrow next to your name... select Account... Add passkey"), not something
  that interrupts a password/OTP login flow automatically. [heb-whats-a-passkey]
  [heb-add-passkey]
- No H-E-B help article documents a sign-in-time "Not now" / "Skip" dismiss prompt for
  passkeys. [heb-whats-a-passkey]
- A live PDPP UAT run against H-E-B nonetheless produced exactly this kind of
  post-OTP interstitial ("H-E-B is asking for a passkey. Complete the prompt in the
  secure browser...") which the owner dismissed manually before the run completed
  (`run_1786140172253`, 91 records) — a real discrepancy against H-E-B's own docs,
  suggesting either an undocumented rollout or a native (non-page) dialog.
- Post-login passkey enrollment nudges ("save a passkey?") are commonly implemented via
  `navigator.credentials.create()`, which triggers a browser-native dialog rather than a
  page-rendered DOM element. [webdev-conditional-create] [fusionauth-webauthn-docs]
- Native WebAuthn dialogs cannot be targeted by page-content text selectors (e.g.
  Playwright `page.locator(...)` against page HTML); a selector aimed at dismiss-control
  text can only ever match page DOM, which for a native dialog means it matches nothing,
  or worse, matches an unrelated page element underneath the dialog.
- User reports confirm "skip"/"not now" clicks on passkey prompts sometimes silently
  fail to dismiss and re-render the same prompt, indicating fragile, inconsistent
  dismiss-UI behavior across implementations generally, not just H-E-B.
  [ms-qa-skip-ignored]

## SOURCES

**heb-whats-a-passkey**
URL: https://www.heb.com/help/account/whats-a-passkey
Accessed: 2026-08-07

**heb-add-passkey**
URL: https://www.heb.com/help/account/how-do-i-add-a-passkey
Accessed: 2026-08-07

**heb-passkey-password-fallback**
URL: https://www.heb.com/help/account/if-i-add-a-passkey-can-i-still-use-a-password-or-code-to-log-in
Accessed: 2026-08-07 (referenced via prior research doc heb-auth-session-and-passive-collection-2026-07-14.md, not re-fetched this session)

**ms-qa-skip-ignored**
URL: https://learn.microsoft.com/en-us/answers/questions/4688449/when-i-press-skip-for-now-about-passkey-it-ignores
Accessed: 2026-08-07

**fusionauth-webauthn-docs**
URL: https://fusionauth.io/docs/lifecycle/authenticate-users/passwordless/webauthn-passkeys
Accessed: 2026-08-07

**webdev-conditional-create**
URL: https://web.dev/articles/passkey-form-autofill
Accessed: 2026-08-07

## SYNTHESIS

For PDPP's H-E-B connector (`packages/polyfill-connectors/src/auto-login/heb.ts`), this
means a text-based dismiss selector for the passkey surface cannot be written with
confidence today: no fixture or captured DOM exists showing the real interstitial, and
the general pattern this prompt belongs to is frequently not a page element at all. The
right next step, if this friction is worth removing later, is capturing a real DOM
snapshot the next time this handoff fires with `CaptureSession` fixture capture enabled
(already wired through `manualAction` in `browser-handoff.ts`), not guessing selector
text against undocumented UI. Full write-up: `docs/inbox/report-passkey-dismissal.md` in
the `pdpp-uat-integrated-0807` worktree (repo-local, not committed).
