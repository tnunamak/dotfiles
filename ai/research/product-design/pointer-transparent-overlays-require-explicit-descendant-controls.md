---
title: "Pointer-transparent overlays require explicit descendant controls to preserve their interaction"
date: 2026-08-11
topic: product-design
tags: [css, pointer-events, overlays, accessibility]
status: draft
sources: [mdn-pointer-events]
source_session: unknown
---

## CLAIMS

- `pointer-events: none` removes an element itself from pointer targeting, but a descendant can become targetable when it explicitly uses another pointer-events value. [mdn-pointer-events]
- `pointer-events: none` does not remove an element from sequential keyboard focus navigation. [mdn-pointer-events]

## SOURCES

**mdn-pointer-events**
URL: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/pointer-events
Accessed: 2026-08-11
Quote: "its subtree could be kept targetable by setting `pointer-events` to some other value."

## SYNTHESIS

Use a pointer-transparent content layer only when an intentional overlay owns the
otherwise-empty hit area. Scope that rule to the overlay state, then explicitly
restore native descendant controls so an action does not lose to the overlay.
Do not use it on a presentational card with no overlay: its cell content should
retain normal pointer behavior by default.
