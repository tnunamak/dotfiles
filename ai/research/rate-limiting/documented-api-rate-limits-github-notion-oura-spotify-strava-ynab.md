---
title: "Documented API rate limits and 429/Retry-After behavior for GitHub, Notion, Oura, Spotify, Strava, and YNAB"
date: 2026-06-13
topic: rate-limiting
tags: [rate-limits, api, github, notion, oura, spotify, strava, ynab, retry-after]
status: draft
sources: [github-rate-limits, notion-request-limits, oura-error-handling, spotify-rate-limits, strava-rate-limits, ynab-rate-limits]
---

## CLAIMS

- GitHub REST API: authenticated users (personal access token) get 5,000 requests/hour; secondary limits include max 100 concurrent requests, max 80 content-generating requests/minute and 500/hour, and no more than 900 points/minute to a single endpoint; on exhaustion GitHub returns 403/429 with `x-ratelimit-remaining: 0` and a `retry-after` header. 5,000/hour ≈ 1.389 req/s ≈ a 720ms minimum interval (~83 req/min). [github-rate-limits]
- Notion: rate limits are "an average of three requests per second" per integration, with bursts beyond the average allowed; `429` (`rate_limited`) and `529` (`service_overload`) responses carry a `Retry-After` header in integer seconds. 3 req/s ≈ a 333ms minimum interval (180 req/min). [notion-request-limits]
- Oura: the V1 and V2 API are rate limited to 5,000 requests in a 5-minute period (≈16.67 req/s, ≈60ms minimum interval, ≈1000 req/min), returning `429` on exceed; there is no separate documented per-day cap. [oura-error-handling]
- Spotify: the limit is computed over a rolling 30-second window and the exact request count is not published (it differs between development mode and extended-quota mode); on exceed it returns `429` with a `Retry-After` header in seconds; a commonly-observed development-mode figure is ~180 req/min. [spotify-rate-limits]
- Strava: per-application 15-minute and daily limits; the overall default is 200 requests/15 min + 2,000/day, while non-upload endpoints default to 100 requests/15 min + 1,000/day; 15-minute windows reset at natural :00/:15/:30/:45 boundaries; responses carry `X-RateLimit-Limit` / `X-RateLimit-Usage` headers, and the docs warn that continuing to make requests while rate limited may result in banning. 100/15 min ≈ 0.111 req/s ≈ a 9000ms minimum interval (~6.67 req/min). [strava-rate-limits]
- YNAB: an access token may be used for up to 200 requests per hour, enforced over a rolling one-hour window; `429` (`too_many_requests`) on exceed. 200/hour ≈ 0.0556 req/s ≈ an 18000ms minimum interval (~3.33 req/min). [ynab-rate-limits]

## SOURCES

**github-rate-limits**
URL: https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
Accessed: 2026-06-13

**notion-request-limits**
URL: https://developers.notion.com/reference/request-limits
Accessed: 2026-06-13

**oura-error-handling**
URL: https://cloud.ouraring.com/docs/error-handling
Accessed: 2026-06-13

**spotify-rate-limits**
URL: https://developer.spotify.com/documentation/web-api/concepts/rate-limits
Accessed: 2026-06-13

**strava-rate-limits**
URL: https://developers.strava.com/docs/rate-limits/
Accessed: 2026-06-13

**ynab-rate-limits**
URL: https://api.ynab.com/
Accessed: 2026-06-13
Quote: "An access token may be used for up to 200 requests per hour" (Usage → Rate Limiting)

## SYNTHESIS

These six providers span the full range of rate-limit shapes: short-window high-quota (Oura 5,000/5min, Notion 3 req/s, GitHub 5,000/hr, Spotify rolling-30s undisclosed) versus long-window low-quota (Strava 100/15min non-upload, YNAB 200/hr). A safe pacing prior sets the fastest sustained request interval at or below the provider's documented sustained rate, never at it, so that even a fully-accelerated client cannot exceed the budget — the documented limit is the wall, the chosen ceiling is the speed limit driven under it. For long-window providers the binding constraint is the window's sustained average (e.g. Strava's 6.67 req/min over 15 minutes, YNAB's 3.33 req/min over an hour): set the interval below that average so a sustained run can never drain the window faster than it refills. For read-only single-threaded clients, the read/primary limit is the binding axis — content-generation and upload secondary limits (GitHub's 80/min content, Strava's upload endpoints) don't apply. Every one of these providers signals overload with `429` plus a `Retry-After` (or `X-RateLimit-*`) header, so honoring `Retry-After` on backoff is a universal contract; Strava additionally warns that ignoring the limit risks a ban, making it the one to pace most conservatively.
