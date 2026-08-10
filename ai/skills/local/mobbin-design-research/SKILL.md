---
name: mobbin-design-research
description: Pull real shipped-app UI precedent from Mobbin (search_screens, search_flows, search_sections MCP tools) before designing or building UI without a Figma/spec to follow. Use when building onboarding, empty/error/permission states, checkout, settings, or any screen from scratch; when the user has no formal design background and wants to avoid "programmer UI"; or when a design skill (impeccable, shape, critique, etc.) calls for precedent but doesn't specify a source. Triggers on "what does this usually look like", "how do other apps handle X", "check Mobbin", "find examples of this screen/flow".
---

# Mobbin design research

Mobbin's MCP tools (`search_screens`, `search_flows`, `search_sections`) return
real screens from shipped apps as images + metadata. Use them as precedent
BEFORE designing UI from scratch, not as decoration after the fact — cheapest
point to catch a bad pattern is before code exists.

## When to reach for it

- Building a screen/flow type you haven't built before: onboarding, paywall,
  empty state, permission request, checkout, settings, search-with-filters.
- The user has no formal design background and says something like "make this
  look good" or "how should this work" with no reference given.
- A design skill (`impeccable`, `shape`, `critique`, `distill`, etc.) is
  active and asks for precedent/reference but doesn't name a source — this is
  that source.
- Before reviewing/critiquing UI the user already built, to compare against
  shipped-app norms instead of just your own taste.

Skip it for: pure logic/backend work, micro-tweaks to existing screens
(spacing, color pass), or when the user already gave a specific reference
(Figma file, screenshot, named competitor) — go straight to that instead.

## Which tool

- **`search_screens`** — single-screen lookup. Default choice for "what does
  a login screen look like."
- **`search_flows`** — multi-screen sequences. Use for anything with steps
  (onboarding, checkout, signup) — shows what persists/changes screen-to-
  screen, which a single screenshot can't.
- **`search_sections`** — a component/section within a screen (a card, a nav
  bar, a paywall block) rather than the whole screen. Use when the ask is
  narrower than a full screen.

## Query phrasing (this is what most agents get wrong)

- Describe concrete UI elements and their relationship, not vibes.
  Good: `"login screen with biometric auth and forgot-password link"`.
  Bad: `"modern clean login screen"`.
- One screen/intent per query. Don't combine ("onboarding with paywall") —
  search separately and compose the findings yourself.
- No negations ("without ads") — the search can't reliably exclude.
- Name a real app to anchor style when the user has one in mind or you want
  a trust signal: `"Stripe checkout page"`, `"Linear settings screen"`.
- Pass `platform` (`ios`/`web`) as its own param — don't put it in the query
  text.
- Default `mode: "deep"` unless you need low latency and the query is
  simple/unambiguous — deep scores relevance instead of just keyword-matching.

## Discipline once you have results

- **Pull 3-5 examples, never just 1.** A single example can't distinguish
  "this app's quirk" from "the actual pattern." Look for what repeats across
  results before treating anything as a rule to follow.
- **Look at hierarchy/spacing/information density, not colors.** Colors are
  the most copyable and least transferable thing — they won't fit the user's
  brand. Structure will.
- **Steal microcopy when it fits.** Strings like "This can take up to a
  minute" or empty-state copy are high-value, low-risk to reuse verbatim or
  near-verbatim — text is often the hardest part for a non-designer to get
  right from scratch.
- **Always cite `mobbin_url` for anything you reference or based a decision
  on.** Every result includes one — surface it as a markdown link so the
  user (or a later reviewer) can verify precedent instead of taking your
  word for it. This matters more here than in most tool use: it's the
  difference between "I made this up" and "here's what N shipped apps do."
- **Examine the actual returned images before describing a screen.** Don't
  summarize from the metadata alone (app name, id) — the visual content is
  the point.

## Not a substitute for judgment

Precedent tells you what's common, not what's right for this product. If the
shipped-app pattern conflicts with something the user has explicitly asked
for, say so rather than silently deferring to Mobbin.
