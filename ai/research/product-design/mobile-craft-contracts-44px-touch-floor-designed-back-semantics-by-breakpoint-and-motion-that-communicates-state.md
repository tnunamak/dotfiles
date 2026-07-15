---
title: "Felt mobile craft rests on a ~44px touch-target floor above WCAG's 24px legal floor, one-pane-at-a-time list-detail with designed back semantics per breakpoint, visible touch/focus state layers, wait indicators matched to duration, and motion reserved for feedback/state/navigation"
date: 2026-06-18
topic: product-design
tags: [mobile, responsive, touch-targets, motion, reduced-motion, list-detail, accessibility, prior-art]
status: draft
sources: [wcag-target-size, nng-touch-targets, android-list-detail, android-m3, wcag-animation, webdev-reduced-motion, mdn-reduced-motion, nng-animation, nng-skeleton, github-mobile, github-filtering, stripe-express, linear-method, apple-hig]
---

## CLAIMS

- WCAG 2.2 SC 2.5.8 requires pointer targets ≥ 24×24 CSS px, with exceptions: the Spacing exception allows an undersized target if a 24px-diameter circle centered on its bounding box does not intersect an adjacent target's circle; the Inline exception exempts links inside flowing text (governed by line-height); the Equivalent exception exempts a small control if an equivalent larger control does the same job on the page. [wcag-target-size]
- NN/g recommends a minimum touch target of ~1cm × 1cm (≈ 38–44 CSS px) — larger than the WCAG AA floor — and notes "crowding causes errors": stacked thin controls too close cause mis-taps, and even a near-miss "adds to the perception that the interface is difficult to use"; primary CTAs and in-motion contexts warrant larger (Target app uses ~2cm scan/search buttons). [nng-touch-targets]
- Android's `NavigableListDetailPaneScaffold` (the fetchable restatement of Material 3 list-detail) adapts by window size: large windows show list+detail side-by-side; small windows show one pane at a time, switching as the user navigates. Back is a named contract: `PopUntilScaffoldValueChange` means in single-pane (phone) back skips content changes within the detail and returns to the list ("a clear layout change"), while in multi-pane (desktop) back may exit the flow because no layout change occurred — back semantics differ by breakpoint by design. [android-list-detail]
- Material 3 (Compose) expresses interaction state (hover/focus/pressed/dragged) through state layers — a translucent overlay of the content/primary color at a defined opacity — rather than ad-hoc color swaps, so every interactive element reacts consistently to touch and focus. [android-m3]
- WCAG 2.1 SC 2.3.3 requires motion triggered by interaction (scroll, transition) to be disable-able, the canonical mechanism being `prefers-reduced-motion`; essential animation where motion is the information is exempt. [wcag-animation]
- web.dev notes "some users outright experience motion sickness when faced with parallax scrolling, zooming effects"; the guidance is to default to no large-movement animation and add it only inside `@media (prefers-reduced-motion: no-preference)`; the media query has been widely available since Jan 2020. [webdev-reduced-motion]
- MDN documents `prefers-reduced-motion` values `no-preference` and `reduce`; the standard idiom keeps essential opacity/color transitions and drops transforms/translates under `reduce`. [mdn-reduced-motion]
- NN/g: "Animation in UX must be unobtrusive, brief, and subtle. Use it for feedback, state-change and navigation metaphors, and to enhance signifiers" — not to induce delight or entertain; it names attention-grabbing (good — makes a subtle signifier obvious) vs attention-hijacking (a distraction and, when manufacturing urgency/loss, a dark pattern). [nng-animation]
- NN/g skeleton-screens: choose the loading indicator by expected duration — spinners/skeletons for <10s, progress bars for >10s ("Anything above 10 seconds requires an explicit estimation of duration"); spinners suit a single module, skeletons suit full-screen loads (previewing layout, lowering cognitive load); animated shimmer keeps users engaged but "can potentially be distracting … or create accessibility problems." [nng-skeleton]
- GitHub Mobile treats small screens as a purpose-built triage view (notifications, issues, PR review) rather than a shrunk-down desktop. [github-mobile]
- GitHub expresses filters as a stable, shareable query so a narrowed view survives a breakpoint change; the same filter grammar drives desktop and mobile. [github-filtering]
- Stripe requires Express Dashboard access "in a web browser, not in embedded web views inside mobile or desktop applications" — the responsive web view is the product surface, leaning on real browser back/scroll-restoration/`prefers-reduced-motion` rather than reinventing them. [stripe-express]
- Linear's stated principles include "speed as a feature"; its UI commits state changes optimistically (the row updates the instant you act; the network reconciles behind it) and is keyboard-first (optimistic-UI behavior is observed product behavior; the Method page renders client-side). [linear-method]
- Apple HIG's well-known rules — 44×44 pt minimum hit target, split-views collapsing to a navigation push stack on compact iPhone width with a back chevron + title bar, and "Reduce Motion" replacing slide/zoom transitions with cross-fades — are observed product behavior (the HIG pages are JS-rendered SPAs that returned empty bodies to a plain HTTP fetch), cross-anchored to the fetchable Android/WCAG sources. [apple-hig]

## SOURCES

**wcag-target-size**
URL: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
Accessed: 2026-06-18

**nng-touch-targets**
URL: https://www.nngroup.com/articles/touch-target-size/
Accessed: 2026-06-18

**android-list-detail**
URL: https://developer.android.com/develop/ui/compose/layouts/adaptive/list-detail
Accessed: 2026-06-18

**android-m3**
URL: https://developer.android.com/develop/ui/compose/designsystems/material3
Accessed: 2026-06-18

**wcag-animation**
URL: https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html
Accessed: 2026-06-18

**webdev-reduced-motion**
URL: https://web.dev/articles/prefers-reduced-motion
Accessed: 2026-06-18

**mdn-reduced-motion**
URL: https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
Accessed: 2026-06-18

**nng-animation**
URL: https://www.nngroup.com/articles/animation-purpose-ux/
Accessed: 2026-06-18
Quote: "Animation in UX must be unobtrusive, brief, and subtle."

**nng-skeleton**
URL: https://www.nngroup.com/articles/skeleton-screens/
Accessed: 2026-06-18
Quote: "Anything above 10 seconds requires an explicit estimation of duration."

**github-mobile**
URL: https://github.com/mobile
Accessed: 2026-06-18

**github-filtering**
URL: https://docs.github.com/en/issues/tracking-your-work-with-issues/filtering-and-searching-issues-and-pull-requests
Accessed: 2026-06-18

**stripe-express**
URL: https://docs.stripe.com/connect/express-dashboard
Accessed: 2026-06-18
Quote: "Express users must access the Dashboard in a web browser, not in embedded web views inside mobile or desktop applications."

**linear-method**
URL: https://linear.app/method/introduction
Accessed: 2026-06-18

**apple-hig**
URL: https://developer.apple.com/design/human-interface-guidelines/
Accessed: 2026-06-18

## SYNTHESIS

Felt craft on small screens reduces to a set of contracts underneath the layout. (P1) There are two touch-target floors — WCAG's 24px legal floor and NN/g/Apple's ~44px craft floor; crafted UIs sit at the higher one with deliberate spacing. (P2) Crowding, not just size, causes the "hard to use" feeling — a small target is tolerable only when isolated (WCAG Spacing exception). (P3) One pane at a time on phone with designed back semantics — drilling in on phone is a history entry and back returns to the list, while selecting a different row on desktop is not a back-stack entry (the Android `PopUntilScaffoldValueChange` contract). (P4) Every interactive element must visibly react to touch and focus via a consistent state-layer model — a row that doesn't change under a finger reads as dead. (P5) Motion is for feedback, state-change, and navigation metaphor, never delight-for-its-own-sake. (P6) Match the wait indicator to the wait length and graduate to a determinate progress bar past 10s. (P7) Always honor `prefers-reduced-motion` and author the reduced variant first (keep opacity/color, drop transforms). (P8) The responsive web view is a first-class surface delivered in a real browser (GitHub Mobile, Stripe), leaning on native back/scroll-restoration/OS motion prefs, with a shared filter grammar so a narrowed view survives a breakpoint flip. (P9) Optimistic apply + keyboard yields perceived speed (Linear) — but as a normative guardrail, optimistic/silent apply is for non-destructive, easily-reversible changes only; destructive, security-relevant actions (e.g. revoking an app's data access, deleting a connection) must route through an explicit confirm gate (type-to-confirm for true deletes) and must never show a "saving/reconciling" shimmer implying a committed change is still provisional. A useful motion catalog names, per pattern, the state it communicates, the motion, its duration, and the `reduce` fallback.
