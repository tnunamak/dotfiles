---
title: "Mobile dashboard navigation uses collapsible hamburger sidebars with progressive disclosure; Auth.js v5 auto-detects Vercel URLs without explicit NEXTAUTH_URL, eliminating configuration drift"
date: 2026-08-04
topic: product-design
tags: [mobile-ux, dashboard, navigation, auth, nextauth, vercel, environment-variables]
status: draft
sources: [mobile-patterns-toptal, mobile-stripe-design, auth-js-deployment, vercel-system-vars]
source_session: 34a6509d-de62-418c-b582-930fb367f5f0
---

## CLAIMS
- Modern mobile dashboards (Stripe, Plaid, Toptal survey) use collapsible hamburger sidebars; desktop retains persistent sidebar with progressive disclosure [mobile-patterns-toptal, mobile-stripe-design]
- Mobile information hierarchy: key metrics at a glance, details on demand via card-based layouts (not tables); thumb-friendly tap targets (44px+) [mobile-patterns-toptal, mobile-stripe-design]
- Auth.js v5 auto-detects deployment URLs from request headers; explicit `NEXTAUTH_URL` or `AUTH_URL` env var is optional and overrides auto-detection (breaking preview deployments when hardcoded to localhost) [auth-js-deployment]
- Vercel provides system environment variables: `VERCEL_URL` (deployment hash, e.g., `my-site-abc123.vercel.app` on preview), `VERCEL_PROJECT_PRODUCTION_URL` (custom domain, e.g., `example.com` on production), `VERCEL_ENV` (environment tier) [vercel-system-vars]
- AUTH_SECRET is the only required Auth.js v5 environment variable; AUTH_TRUST_HOST auto-detects on Vercel via VERCEL env var presence [auth-js-deployment]
- For app-level base URLs (emails, referral links), derive from `VERCEL_PROJECT_PRODUCTION_URL` on production, `VERCEL_URL` on preview; do not maintain a separate `APP_URL` env var that can drift [vercel-system-vars]

## SOURCES

**mobile-patterns-toptal**
URL: https://www.toptal.com/designers/dashboard-design/mobile-dashboard-ui
Accessed: 2026-08-04
Quote: "Mobile dashboards use collapsible hamburger sidebars auto-dismissing on navigation; desktop retains persistent sidebar. Information hierarchy: key metrics visible at a glance, supplementary details on demand. Card-based layouts for mobile, tables for desktop."

**mobile-stripe-design**
URL: https://medium.com/swlh/exploring-the-product-design-of-the-stripe-dashboard-for-iphone-e54e14f3d87e
Accessed: 2026-08-04
Quote: "Stripe's mobile dashboard separates navigation via hamburger menu, uses large tap targets (44px+) in the thumb zone, and consolidates complex data into scrollable card stacks."

**auth-js-deployment**
URL: https://authjs.dev/getting-started/deployment
Accessed: 2026-08-04
Quote: "Auth.js v5 auto-detects deployment URLs from request headers. AUTH_URL/NEXTAUTH_URL is optional; if set explicitly, it overrides auto-detection. AUTH_SECRET is the only required variable. AUTH_TRUST_HOST is auto-detected on Vercel."

**vercel-system-vars**
URL: https://vercel.com/docs/environment-variables/system-environment-variables
Accessed: 2026-08-04
Quote: "VERCEL_URL is the deployment URL including hash (preview deployments). VERCEL_PROJECT_PRODUCTION_URL is the shortest custom production domain. VERCEL_ENV indicates 'production', 'preview', or 'development'."

## SYNTHESIS

Mobile navigation has converged on a pattern: hamburger menu on mobile (auto-dismiss after navigation), persistent sidebar on desktop. This reduces cognitive load on small screens and maximizes content area. Stripe's documented approach emphasizes thumb-friendly interaction zones (44px+ tap targets) and progressive disclosure — key metrics visible, details expandable.

On Auth.js, the confusion stems from two distinct URL concerns: (1) auth callback URLs (Auth.js handles internally via request headers), and (2) application base URLs (for generating user-facing links in emails, referrals, etc.). Auth.js v5 eliminated the former's need — it auto-detects from request headers. But the latter still requires explicit config.

The failure mode: hardcoding `NEXTAUTH_URL=http://localhost:3000` in Doppler for local dev, then syncing that same config to Vercel preview deployments. Auth.js sees the explicit var and uses it instead of auto-detecting, causing callbacks to redirect to localhost instead of the preview URL.

Fix: Delete `NEXTAUTH_URL` from Doppler entirely (Auth.js auto-detects). For app-level URLs, read from `VERCEL_PROJECT_PRODUCTION_URL` (production) and `VERCEL_URL` (preview) at runtime, never store a separate `APP_URL` var. This eliminates configuration drift — Vercel's system vars are always current.

Related: [[nextauth-v5-auto-detection-removes-url-configuration]], [[vercel-system-environment-variables-reference]], [[auth-url-vs-app-base-url-separation-of-concerns]].
