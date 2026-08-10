---
title: "Steam has no per-user OAuth token, so an owner-supplied API key beats the industry app-owned-key precedent for self-hosted personal-data tools"
date: 2026-08-07
topic: connectors
tags: [steam, openid, api-keys, self-hosted, privacy-gates, auth-model]
status: draft
sources: [valve-web-api, steamworks-webapi-auth, steamworks-features-auth, steam-dev, passport-steam, steam-forum-privacy]
source_session: 073acd59-50b7-4bf4-81a9-bfb5e652202b
---

## CLAIMS

- Steam has no per-user OAuth token of any kind. Steam OpenID 2.0 returns only a
  claimed id of the form `https://steamcommunity.com/openid/id/<steamid64>` — no
  access token, no refresh token, no scoped grant. [valve-web-api]
  [steamworks-features-auth]
- Because OpenID yields no API authority, every profile/library/achievement read
  still requires a `key=` Web API key. Login and data access are two independent
  mechanisms, not one flow. [steamworks-webapi-auth] [passport-steam]
- A standard Web API key identifies the calling *application*, not the subject.
  Any valid key can read any *public* profile; the key need not belong to the
  account being queried. [valve-web-api] [steamworks-webapi-auth]
- The "key must be linked to the steamid" rule is a narrow exception that applies
  only to reading your OWN non-public data — it is not the general rule.
  [steamworks-webapi-auth]
- Publisher keys do not bypass privacy: standard and publisher keys honor user
  privacy settings identically. [steamworks-webapi-auth]
- Third-party sites (IsThereAnyDeal, Backloggd, Astats) therefore use OpenID for
  identity plus ONE app-owned key, tied to a registered domain, for all
  subsequent reads — which is why they all require a Public profile.
  [steamworks-features-auth] [steam-dev]
- `passport-steam` exposes `profile: false`, which disables user-data fetching and
  confirms Steam login works with no API key at all. [passport-steam]
- "Profile public" and "game details public" are SEPARATE toggles. A public
  library with private playtimes returns `playtime_forever: 0` rather than an
  error or null. [valve-web-api]
- `GetPlayerSummaries` returns `communityvisibilitystate` (1=private, 2=friends,
  3=public) for up to 100 ids per call, making visibility a cheap pre-check.
  [valve-web-api]
- `rtime_last_played`, `playtime_2weeks`, and achievement timestamps are readable
  only with a key linked to that steamid. [valve-web-api]
- The self-exception is REAL and load-bearing: when `key` belongs to the same account
  as `steamid`, privacy settings are bypassed and a PRIVATE profile still returns full
  data from `GetOwnedGames` / `GetRecentlyPlayedGames`. A private profile blocks
  third-party apps, not the owner. [valve-web-api] [steam-forum-privacy]
- The exception is NOT uniform across endpoints. `GetPlayerSummaries` does not
  authenticate, so it returns only public fields even when querying yourself with your
  own key, and its `communityvisibilitystate` collapses to 1 (not visible to you) or 3
  (public). It is therefore unreliable as a self-visibility pre-check.
  [steam-forum-privacy]
- Some owned titles are omitted unless `skip_unvetted_apps=false` is passed — a silent
  undercount that looks like missing data rather than an error. [steam-forum-privacy]
- A common false positive when testing: querying Steam FRIENDS appears to prove a key
  bypasses privacy, when it is really friends-only visibility. Non-friends with private
  profiles return an empty response. [steam-forum-privacy]
- Personal keys are issued at `https://steamcommunity.com/dev/apikey`, which 302s
  to a normal Steam login. `partner.steamgames.com` is game-publisher onboarding
  and is the wrong destination for a personal key (verified live 2026-08-07).
  [steam-dev] [steamworks-webapi-auth]

## SOURCES

**valve-web-api**
URL: https://developer.valvesoftware.com/wiki/Steam_Web_API
Accessed: 2026-08-07
Quote: "Private, friends-only, and other privacy settings are not supported unless
you are asking for your own personal details (ie the WebAPI key you are using is
linked to the steamid you are requesting)."

**steamworks-webapi-auth**
URL: https://partner.steamgames.com/doc/webapi_overview/auth
Accessed: 2026-08-07
Quote: "Some Web API methods return publicly accessible data and do not require
authorization when called. Other methods may require a unique API key."

**steamworks-features-auth**
URL: https://partner.steamgames.com/doc/features/auth
Accessed: 2026-08-07
Quote: "Inside a web browser, a third-party website can use OpenID to obtain a
user's SteamID which can be used as the login credentials for the 3rd party
website, or linked to an existing account on that website."

**steam-dev**
URL: https://steamcommunity.com/dev
Accessed: 2026-08-07
Quote: "all that's required is a Steam account and a domain name associated with
the key, plus agreeing to the Steam Web API Terms of Use"

**steam-forum-privacy**
URL: https://steamcommunity.com/discussions/forum/7/1729827777339922602/
Accessed: 2026-08-07
Quote: "when game details are private you get an empty response; when the library is
public but total playtimes are private, playtime values come back as 0"

**passport-steam**
URL: https://github.com/sezeryldz/passport-steam
Accessed: 2026-08-07
Quote: "if you don't want to use an API key, you can set `profile: false`, which
disables fetching of user data"

## SYNTHESIS

The industry precedent is a poor fit for self-hosted, user-owned tools, and copying
it would be a downgrade.

IsThereAnyDeal-class sites solve a different problem: reading MANY OTHER PEOPLE'S
PUBLIC profiles at scale. One app-owned key plus OpenID is optimal for that, and the
Public-profile requirement is the cost they accept.

A personal-data tool solves the inverse: ONE OWNER reading THEIR OWN data, including
the non-public parts. That lands squarely inside the exception — an owner-supplied key
is the *only* way to reach `rtime_last_played`, `playtime_2weeks`, and achievement
timestamps. So asking the owner for their own key is not a shortcut; it is more correct
than the precedent.

Shipping a tool-owned key is additionally hostile to self-hosting: keys are registered
to a domain and a Steam account under Valve's ToU (no single "app" exists across many
deployments), and one shared key becomes a ~100k req/day choke point for every user.

The defensible design is: keep the owner-supplied key, and add OpenID purely as an
identity convenience to eliminate the SteamID paste. That also fixes a real usability
trap — the common "copy the number after `profiles/`" instruction fails for any account
with a vanity URL, where `/id/<name>` exposes no number anywhere.

A private profile is therefore NOT a blocker for the owner-key design — that is the
main practical payoff of choosing it. "Most users have private profiles" is a fatal
objection to the app-owned-key pattern and a non-issue for the owner-key one.

Correctness trap worth generalizing to other connectors: a provider that returns `0`
for privacy-restricted data (rather than an error or null) will silently produce
fabricated zeros in any pipeline that treats absence and zero alike. Steam's
`playtime_forever: 0` on a public-library/private-playtime account is exactly this.

Do NOT reach for `communityvisibilitystate` as the guard, despite it being the
commonly-recommended pre-check: that endpoint is unauthenticated, so it reports what is
visible to the CALLER rather than the true setting, and collapses to 1-or-3. Under the
owner-key design it is also answering the wrong question — the owner's own privacy
setting does not gate the owner's own reads. The correct guard is to treat a `0`
playtime on an otherwise-populated record as UNKNOWN unless corroborated, and to
surface the distinction rather than render it as a measured zero.

Two silent-undercount traps to check in any Steam implementation: omit
`skip_unvetted_apps=false` and some owned titles simply vanish; and when testing key
behavior, querying your own FRIENDS looks like proof that a key bypasses privacy when
it is only friends-only visibility.
