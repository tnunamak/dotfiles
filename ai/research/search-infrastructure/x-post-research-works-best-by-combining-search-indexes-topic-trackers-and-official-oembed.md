---
title: "Public X post research works best by combining search indexes and topic trackers with X's official oEmbed endpoint"
date: 2026-08-12
topic: search-infrastructure
tags: [x, twitter, search, oembed, social-media]
status: draft
sources: [x-oembed, bing-rss, codex-resets, nitter]
source_session: unknown
---

## CLAIMS

- X's unauthenticated oEmbed endpoint returned the full public text, author, date, and canonical URL for known post IDs during this investigation. [x-oembed]
- Bing's RSS search results exposed indexed X post URLs and snippets when ordinary web search returned no useful results. [bing-rss]
- A topic-specific tracker supplied a larger candidate set of canonical X post URLs, which the oEmbed endpoint could then verify independently. [codex-resets] [x-oembed]
- Nitter's current setup requires Twitter accounts, so public Nitter-style instances are not a dependable primary discovery path. [nitter]

## SOURCES

**x-oembed**
URL: https://publish.twitter.com/oembed?url=https%3A%2F%2Fx.com%2Fthsottiaux%2Fstatus%2F2087423996115681767&omit_script=true
Accessed: 2026-08-12

**bing-rss**
URL: https://www.bing.com/search?format=rss&q=%22thsottiaux%22+%22reset%22+Codex
Accessed: 2026-08-12

**codex-resets**
URL: https://codex-resets.com/
Accessed: 2026-08-12

**nitter**
URL: https://github.com/zedeus/nitter
Accessed: 2026-08-12

## SYNTHESIS

Treat X research as a two-stage process. Discover candidate post IDs through search-engine
indexes, syndication feeds, and credible topic-specific trackers. Then verify every known
ID through X's official oEmbed endpoint. This combination recovered public posts when
direct X pages, general web search, and Nitter-style mirrors were blocked or incomplete.
It does not guarantee complete reply discovery: search indexes and trackers can omit
unindexed replies, deleted posts, protected accounts, and unrelated posts outside their
topic.
