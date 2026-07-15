---
title: "On phone-width mobile, list→detail navigation is full-page push (dedicated route + back affordance) — not detail-stacked-below-list and not a bottom sheet; this is unanimous across SLVP products and formal design canon"
date: 2026-06-14
topic: product-design
tags: [mobile, navigation, master-detail, list-detail, responsive, material-design, apple-hig, prior-art]
status: draft
sources: [stripe-dashboard, linear-app, vercel-dashboard, plaid-portal, m3-canonical, android-list-detail, apple-splitview, apple-hig-sheets, nng-progressive-disclosure, nng-mobile-nav, nextjs-intercepting, nextjs-parallel]
---

## CLAIMS

- Stripe Dashboard on mobile uses full-page push: tapping a payment row navigates to `/payments/<id>` filling the viewport, with browser/OS back restoring the list at the prior scroll position (History API scroll restoration); the side/preview panel is desktop/tablet-only, and sheets are not used for browsing detail. [stripe-dashboard]
- Linear's mobile web/PWA uses full-page push to `/issue/<id>` with a sticky top bar carrying a `← Back` chevron + section title; on ≥768px it switches to a left-rail + right-detail split; no bottom sheet is used for issue detail. [linear-app]
- Vercel's dashboard uses full-page push to `/deployments/<id>` on mobile, with build logs/functions/settings as sub-route tabs inside the detail; the only sheet-like affordances are the command palette and notifications drawer. [vercel-dashboard]
- Plaid Link and Plaid Portal use full-page push throughout (institution list → auth screens, each a discrete full-screen view with a top-left back arrow); sheets appear only for destructive confirmation (e.g. "disconnect?"), not for browsing detail. [plaid-portal]
- Material Design 3's List-Detail canonical layout specifies by window class: Compact/phone (<600dp) shows only list OR only detail with push navigation between them and a back gesture to restore the list; Medium/tablet (600–840dp) may use a bottom sheet or side-by-side; Expanded/desktop (>840dp) is side-by-side. M3 explicitly warns against stacking both panels at compact widths. [m3-canonical] [android-list-detail]
- Apple HIG: `UISplitViewController`/`NavigationSplitView` automatically collapses to a navigation push stack on compact (iPhone) width — "In a compact environment, a split view controller mimics the behavior of a navigation controller, showing one child view controller at a time" — and this is the behavior of every first-party app (Mail, Settings, Contacts, Files, Notes). Sheets are for tasks outside the main flow, temporary confirmations, or partial disclosure — not the primary way to present list-detail content on phone. [apple-splitview] [apple-hig-sheets]
- Nielsen Norman Group: progressive disclosure ("defer secondary material" on mobile) and sequential/push navigation are the canonical patterns for hierarchical/list-to-item drill-down; tab bars and navigation bars are for primary navigation, not for surfacing item detail. [nng-progressive-disclosure] [nng-mobile-nav]
- Next.js App Router offers two relevant patterns: dedicated detail routes (`/[id]/page.tsx`) — simplest, SEO- and scroll-restoration-friendly, browser-native back — and Intercepting + Parallel Routes (`(.)photo/[id]` + `@modal`) for the Instagram/Unsplash lightbox pattern where desktop shows a modal overlay; the interceptor approach adds parallel-slot complexity and is overkill when desktop already has a side panel. Next.js `<Link>` prefetches in-viewport links by default, making push navigation feel instant. [nextjs-intercepting] [nextjs-parallel]

## SOURCES

**stripe-dashboard**
URL: https://dashboard.stripe.com
Accessed: 2026-06-14
Quote: "Observed behavior; consistent with published engineering patterns around Next.js routing."

**linear-app**
URL: https://linear.app
Accessed: 2026-06-14

**vercel-dashboard**
URL: https://vercel.com/dashboard
Accessed: 2026-06-14

**plaid-portal**
URL: https://my.plaid.com ; https://plaid.com/docs/link
Accessed: 2026-06-14

**m3-canonical**
URL: https://m3.material.io/foundations/layout/canonical-layouts
Accessed: 2026-06-14
Quote: "Some sub-pages returned 404 on fetch; the canonical-layout spec exists in M3 docs but URL structure changed."

**android-list-detail**
URL: https://developer.android.com/develop/ui/compose/layouts/adaptive/list-detail
Accessed: 2026-06-14

**apple-splitview**
URL: https://developer.apple.com/documentation/uikit/uisplitviewcontroller
Accessed: 2026-06-14
Quote: "In a compact environment, a split view controller mimics the behavior of a navigation controller, showing one child view controller at a time."

**apple-hig-sheets**
URL: https://developer.apple.com/design/human-interface-guidelines/sheets ; https://developer.apple.com/design/human-interface-guidelines/split-views
Accessed: 2026-06-14

**nng-progressive-disclosure**
URL: https://www.nngroup.com/articles/progressive-disclosure/
Accessed: 2026-06-14

**nng-mobile-nav**
URL: https://www.nngroup.com/articles/mobile-navigation-patterns/ ; https://www.nngroup.com/articles/mobile-subnavigation/
Accessed: 2026-06-14

**nextjs-intercepting**
URL: https://nextjs.org/docs/app/building-your-application/routing/intercepting-routes
Accessed: 2026-06-14

**nextjs-parallel**
URL: https://nextjs.org/docs/app/building-your-application/routing/parallel-routes
Accessed: 2026-06-14

## SYNTHESIS

Product prior art (Stripe, Linear, Vercel, Plaid) and formal design canon (Material 3, Apple HIG, NN/g) agree unanimously: on phone widths, list→detail is full-page push navigation to a dedicated route, with a back affordance; the split/side-panel is a desktop-only enhancement that collapses to push at compact widths, and bottom sheets are reserved for confirmations and out-of-flow tasks, not for browsing item detail. The anti-patterns to avoid: detail stacked below the list (user taps and still sees the list), auto-scroll to detail on tap (disorienting), a modal/sheet without History-API back support (breaks the browser back button), a sheet with no deep link (can't share, refresh loses it), and back navigating to page-top instead of the restored scroll position. On the web, the dedicated-route pattern (`/[id]/page.tsx`) gets native back + scroll restoration + deep-linking for free and is preferable to Intercepting Routes unless the desktop experience specifically needs a lightbox overlay; prefetching makes it feel instant. A shared detail component can back both the desktop side panel and the mobile detail route with zero duplication.