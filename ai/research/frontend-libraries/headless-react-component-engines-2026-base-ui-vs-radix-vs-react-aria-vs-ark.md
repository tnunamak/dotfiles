---
title: "In 2026 the headless React component-engine landscape bifurcated into two healthy peers with shadcn as a neutral abstraction on top: Base UI (shipped stable by the original Radix + MUI + Floating UI team, the more purely headless and forward-moving) and Radix (transferred to WorkOS, maintained but incumbent), with React Aria (Adobe, most-tested a11y but heaviest/i18n-laden) and Ark UI/Zag (Chakra, framework-agnostic state-machine core) as the other credible options"
date: 2026-06-13
topic: frontend-libraries
tags: [headless-ui, react, base-ui, radix, react-aria, ark-ui, design-system, library-eval]
status: draft
sources: [baseui-about, baseui-releases, baseui-v1, baseui-quickstart, baseui-dialog, baseui-field, radix-repo, radix-npm, radix-releases, reactaria-why, reactaria-components, ark-npm, shadcn-baseui, shadcn-changelog, shadcn-base-dialog]
---

## CLAIMS

- Base UI is shipped by the original Radix team together with MUI's component team and Floating UI ("From the creators of Radix, Material UI, and Floating UI"); it ships zero CSS (only DOM, behavior, ARIA, and `data-*` state attributes) and composes via `className` (string or state-fn), a `render` prop, and `data-*` state. [baseui-about][baseui-quickstart][baseui-dialog]
- Base UI v1.0.0 landed 2025-12-11 (the release that renamed the package from `@base-ui-components/react` to `@base-ui/react`) and reached v1.5.0 on 2026-05-19 with perf-focused releases (e.g. "up to 50% faster closed-popup mount, 85% faster unmount") and added breadth (Combobox, NumberField i18n). [baseui-releases][baseui-v1]
- Base UI provides a `Field`/`Fieldset` that natively wires label/description/error association and validation announcements, plus Dialog, Popover, Menu, Tooltip, Tabs, Combobox, Select, OTP, NumberField, ScrollArea. [baseui-field][baseui-dialog]
- Radix was not abandoned — it was transferred to WorkOS and is maintained (GitHub header "Maintained by @workos", ~19k stars, `@radix-ui/react-dialog` at 1.1.16), with full React 19 + RSC compatibility shipped (PRs #2952, #2923) and a unified tree-shakable `radix-ui` package — but new component work and API evolution is happening in Base UI, not Radix. [radix-repo][radix-npm][radix-releases]
- shadcn supports both Base UI and Radix with an identical component API: `npx shadcn create` lets you pick Radix or Base UI, the docs ship full `/docs/components/radix/*` and `/docs/components/base/*` trees, and the Jan 2026 "Base UI Documentation" post frames it as "Same Abstraction, Different Primitives" — the wrapper import is identical regardless of engine, only the underlying implementation changes. [shadcn-baseui][shadcn-changelog][shadcn-base-dialog]
- React Aria (Adobe) is the most exhaustively-tested a11y engine (WAI-ARIA APG, 30+ locales, 13 calendars, RTL) but ships default `react-aria-*` class names and render-props/slots (slightly more framework-y to skin) and carries i18n/number/date/calendar machinery weight even when unused. [reactaria-why][reactaria-components]
- Ark UI wraps a Zag.js state-machine core per component (framework-agnostic, well-tested but smaller battle-history, heavier client runtime); latest publish observed 5.37.2. [ark-npm]

## SOURCES

**baseui-about**
URL: https://base-ui.com/react/overview/about
Accessed: 2026-06-13
Quote: "From the creators of Radix, Material UI, and Floating UI"

**baseui-releases**
URL: https://base-ui.com/react/overview/releases
Accessed: 2026-06-13

**baseui-v1**
URL: https://base-ui.com/react/overview/releases/v1-0-0
Accessed: 2026-06-13

**baseui-quickstart**
URL: https://base-ui.com/react/overview/quick-start
Accessed: 2026-06-13

**baseui-dialog**
URL: https://base-ui.com/react/components/dialog
Accessed: 2026-06-13

**baseui-field**
URL: https://base-ui.com/react/components/field
Accessed: 2026-06-13

**radix-repo**
URL: https://github.com/radix-ui/primitives
Accessed: 2026-06-13

**radix-npm**
URL: https://www.npmjs.com/package/@radix-ui/react-dialog
Accessed: 2026-06-13

**radix-releases**
URL: https://www.radix-ui.com/primitives/docs/overview/releases
Accessed: 2026-06-13

**reactaria-why**
URL: https://react-spectrum.adobe.com/react-aria/why.html
Accessed: 2026-06-13

**reactaria-components**
URL: https://react-spectrum.adobe.com/react-aria/components.html
Accessed: 2026-06-13

**ark-npm**
URL: https://www.npmjs.com/package/@ark-ui/react
Accessed: 2026-06-13

**shadcn-baseui**
URL: https://ui.shadcn.com/docs/changelog/2026-01-base-ui
Accessed: 2026-06-13

**shadcn-changelog**
URL: https://ui.shadcn.com/docs/changelog
Accessed: 2026-06-13

**shadcn-base-dialog**
URL: https://ui.shadcn.com/docs/components/base/dialog
Accessed: 2026-06-13

## SYNTHESIS

For a token-driven, headless-only React 19 / Next 16 design system in 2026, the naive "Radix is dead, everyone moved to Base UI" narrative is wrong. The real picture is a clean bifurcation into two healthy peers with shadcn as the neutral abstraction on top, differentiation pushed up into the skin layer.

A weighted scorecard (dimensions weighted for a shared content-site-and-app headless layer; 1–5) came out: **Base UI 93 · Radix 84 · React Aria 80 · Ark UI 77** (max 95). Base UI and Radix are close because they are siblings; Base UI wins on forward-looking axes — maintenance trajectory (same authors putting new work here), headless purity (ships no CSS), skinning ergonomics (`className` as string-or-state-fn + `render` + `data-*` states, ideal for applying your own token classes), and bundle/perf trend (single tree-shakable package, active perf-shrinking releases). React Aria is the a11y maximalist but its i18n weight and more ceremonious composition are overkill for an English-first app; Ark/Zag is a fine framework-agnostic option with no advantage for a React-only shop and a state-machine runtime cost.

The recommended house pattern when skinning Base UI: pass through Root/Trigger/Portal/Close unstyled; on each visible part forward `className` joined with your token class plus a `data-slot` hook; style off Base UI's `data-*` state attributes (`data-open`, `data-closed`, `data-starting-style`) in CSS rather than JS-toggled classes (keeps the skin declarative and SSR-stable); use the `render` prop (Base UI's successor to Radix's `asChild`) where a part needs a different DOM tag. Because a thin skin over a part-based API that Radix mirrors is only ~30–90 lines per primitive, a future fall-back from Base UI to Radix is a contained per-primitive rewrite, not a design-system rewrite — which is itself an argument for the thin-skin architecture. The residual risk is Base UI's youth (~12 months at 1.x vs Radix's multi-year track record). Also note: zero-interaction visual atoms (Table, Tag, Button-on-native-`<button>`, etc.) should not touch any headless engine — the dividing test is "does it have interactive state a screen reader must be told about, or focus/keyboard behavior?"; yes → engine skin, no → hand-rolled semantic HTML.
