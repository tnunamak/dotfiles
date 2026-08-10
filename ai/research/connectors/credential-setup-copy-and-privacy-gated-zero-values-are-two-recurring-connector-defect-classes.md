---
title: "Two recurring connector defect classes found during a live UAT audit: setup help_text/help_url pointing at the wrong flow (OAuth app-registration vs. personal-token pages), and numeric fields silently returning 0 for privacy-hidden data instead of null"
date: 2026-08-07
topic: connectors
tags: [connector-setup-ux, credential-capture, help-text, privacy-gated-fields, steam, groupme, jellyfin, github, data-fabrication]
status: draft
sources: [pdpp-groupme-manifest, pdpp-steam-manifest, pdpp-github-manifest, pdpp-steam-connector-code, pdpp-connector-authoring-guide]
source_session: unknown
---

## CLAIMS

- In a live PDPP UAT session (2026-08-07, `pdpp-uat-integrated-0807`), 3 of ~16
  audited `static_secret` connector manifests had setup-copy defects that
  stranded or misdirected the owner, found only by an owner actually
  attempting setup — a code-only audit (does help_text match the connector's
  auth mechanism?) caught 1 of the 3. [pdpp-groupme-manifest] [pdpp-steam-manifest]
  [pdpp-github-manifest]
- Defect class 1 — **destination mismatch between a field's `help_text` and
  its `help_url`.** GroupMe's `help_text` named the correct personal-token
  page (`steamcommunity.com`-style dev console) but its `help_url` pointed at
  GroupMe's OAuth application-registration form, which requires a Callback
  URL field that exists only for OAuth and is never used by a personal-token
  connector — the owner got stuck on a form field with no relevance to their
  task. Steam had the identical shape: `help_text` correctly named
  `steamcommunity.com/dev/apikey`, but the separate `help_url` field (the one
  actually rendered as a clickable link in the console UI) pointed at
  Steamworks *partner/publisher* developer-onboarding docs — a funnel with
  options like "I run a cyber cafe or VR arcade" and no path for "I want a
  personal API key." A code audit that only checks "does this connector use
  OAuth or a static token, and does help_text match" will not catch this,
  because `help_text` was correct in both cases — only the separate,
  independently-editable `help_url` field was wrong. Both fields must be
  checked, and checked by actually visiting the URL, not just reading it.
  [pdpp-groupme-manifest] [pdpp-steam-manifest]
- Defect class 2 — **instructions assume a UI path that doesn't exist for
  all accounts.** Steam's `steamid` help_text said "copy the number after
  `profiles/`" — true only for accounts without a custom vanity URL. An
  account with a vanity URL shows `/id/<name>` with no number anywhere on
  the page, so the instruction sends a subset of users on a dead-end search.
  Fix pattern: give a URL that resolves identically for both cases
  (`steamcommunity.com/my/profile`, which redirects to whichever form the
  logged-in user actually has) plus instructions covering both outcomes,
  rather than assuming one canonical account shape. [pdpp-steam-manifest]
- Defect class 3 — **required-scope omission for token-based auth.**
  GitHub's `help_text` said "create a token... paste it here" with no scope
  guidance, while the connector's own source comment documented required
  scopes (`read:user`, `public_repo`/`repo`, `gist`). GitHub's token-creation
  UI defaults to zero scopes selected — an owner following literal help_text
  gets a token that authenticates successfully but silently under-collects
  (no private repos, no gists), which surfaces as a data-completeness bug far
  downstream of setup, not as a setup failure. General pattern: any static
  PAT/API-key connector's help_text should state required scopes explicitly
  whenever the provider's token-creation UI does not select them by default.
  [pdpp-github-manifest]
- Separately, a numeric-data-fabrication trap: Steam's Web API returns
  `playtime_forever: 0` (not an error, not omitted) when a profile's library
  is public but its playtime/game-details visibility is set private — profile
  visibility and game-details visibility are two independent Steam privacy
  toggles. The connector (`connectors/steam/index.ts:272`, `:291`) emits
  `playtime_forever` from the raw API response unconditionally, with no `??
  null` fallback (unlike every sibling numeric field in the same object
  literal, which already does `?? null`), and the schema
  (`connectors/steam/schemas.ts:32`, `:49`) declares the field non-nullable.
  `communityvisibilitystate` (the profile-level visibility signal) is fetched
  and stored on the `profile` record (`index.ts:253`) but never consulted to
  gate or annotate any other stream — the signal needed to detect this case
  is already being collected and simply isn't used. General pattern worth
  checking on any connector wrapping a provider with granular privacy
  settings: does the provider ever substitute a valid-looking sentinel
  (0, empty string, empty array) for "hidden by privacy" rather than
  erroring or omitting the field, and if so, does the connector have any way
  to tell that case apart from the real value? [pdpp-steam-connector-code]
  [pdpp-connector-authoring-guide]

## SOURCES

**pdpp-groupme-manifest**
URL: local repo, `packages/polyfill-connectors/manifests/groupme.json` (PDPP monorepo, `pdpp-uat-integrated-0807` branch)
Accessed: 2026-08-07
Quote: pre-fix `help_url: "https://dev.groupme.com/applications"` (OAuth app-registration form) paired with correct `help_text` naming the personal-token page

**pdpp-steam-manifest**
URL: local repo, `packages/polyfill-connectors/manifests/steam.json`
Accessed: 2026-08-07
Quote: pre-fix `help_url: "https://partner.steamgames.com/doc/webapi_overview/auth"` vs. correct `help_text` naming `steamcommunity.com/dev/apikey`; owner-verified live: `steamcommunity.com/dev/apikey` 302s to normal Steam login, `partner.steamgames.com/...` returns 200 on developer/publisher docs

**pdpp-github-manifest**
URL: local repo, `packages/polyfill-connectors/manifests/github.json` and `connectors/github/index.ts` header comment
Accessed: 2026-08-07
Quote: connector source documents "Minimum scopes: read:user, public_repo (for public), repo (for private), gist (for gists)"; manifest help_text omitted all of it

**pdpp-steam-connector-code**
URL: local repo, `packages/polyfill-connectors/connectors/steam/index.ts` and `schemas.ts`
Accessed: 2026-08-07
Quote: `playtime_forever: game.playtime_forever` (index.ts:272, :291, no `?? null`) vs. sibling fields `playtime_windows: game.playtime_windows ?? null` in the same object literal; `playtime_forever: z.number()` (schemas.ts:32, :49, non-nullable)

**pdpp-connector-authoring-guide**
URL: local repo, `packages/polyfill-connectors/docs/connector-authoring-guide.md`
Accessed: 2026-08-07
Quote: "Nullable fields return `null`, not sentinel strings... If the platform says 'we can't show this,' your connector should say `null`." — documented for strings; the Steam case is the same defect class for a number, not covered by the rule's literal wording

## SYNTHESIS

Both defect classes were found only because a real owner attempted real setup
and reported exactly where it broke — a code-only audit (read help_text,
read the connector's auth mechanism, check they agree) caught the GitHub
scope gap but missed both help_url mismatches, because in both cases
help_text itself was correct and only the separately-editable help_url field
was wrong. The generalizable audit procedure: for any `static_secret`
manifest, don't just read `help_url` — visit it and confirm the destination
is the credential-creation page a personal user would use, not a
developer/publisher/partner-tier onboarding funnel that happens to live at a
similarly-named domain. This is a live-verification check, not a
static-review check.

The privacy-zero trap generalizes beyond Steam: any connector wrapping a
provider with independent, granular privacy settings should be audited for
whether "no data" and "data hidden by privacy" are distinguishable in the
API response, and if the provider collapses them into a valid-looking
default (0, empty, false) rather than an error, the connector must carry
that distinction forward as `null`/a flag rather than passing the sentinel
through as if it were real data. The tell that this bug exists without
reading provider docs: a numeric field with no `?? null` fallback sitting
next to sibling fields in the same record that do have one — an asymmetry
that suggests the non-nullable field was never audited against the
provider's privacy model, not that it's known to always be present.
