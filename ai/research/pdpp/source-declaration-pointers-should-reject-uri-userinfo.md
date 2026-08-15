---
title: "Source Declaration pointers should reject URI user information"
date: 2026-08-11
topic: pdpp
tags: [pdpp, uri, discovery, credentials, rfc-3986]
status: draft
sources: [rfc-3986]
source_session: unknown
---

## CLAIMS

- RFC 3986 permits a `userinfo` subcomponent before the host in a URI authority. [rfc-3986]
- RFC 3986 deprecates `user:password` in `userinfo` and identifies clear-text authentication information as a security risk. [rfc-3986]
- RFC 3986 says a password in `userinfo` should normally be treated as an error and warns that `userinfo` can make the real host misleading to a person. [rfc-3986]

## SOURCES

**rfc-3986**
URL: https://www.rfc-editor.org/rfc/rfc3986.html
Accessed: 2026-08-11

## SYNTHESIS

A Source Declaration pointer is a security-sensitive retrieval input. An HTTPS-only check does not reject `https://user:password@host/...`. The pointer contract and parser should reject both username-only and username-plus-password `userinfo`. This keeps credentials out of stored, displayed, and logged declaration URLs and removes an authority-confusion surface without restricting ordinary HTTPS hosting.
