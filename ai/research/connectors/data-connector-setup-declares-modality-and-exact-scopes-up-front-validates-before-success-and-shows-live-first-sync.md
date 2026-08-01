---
title: "Mature data-connector/integration setup declares the modality and exact scopes up front, validates the credential before claiming success, designs the handoff out-and-back, and replaces terminal 'submitted' with live first-sync progress"
date: 2026-06-18
topic: connectors
tags: [connector-setup, onboarding, oauth-scopes, credential-validation, first-sync, self-host, prior-art]
status: draft
sources: [github-oauth-scopes, github-pat, plaid-link, plaid-oauth, stripe-onboarding, stripe-hosted, railway-quickstart, railway-deployments, vercel-deployments, supabase-quickstart, supabase-deployment, tailscale-install, google-oauth-scopes, google-consent-screen]
source_session: 019d3602-f708-7e13-861c-0c4199f18a3f
---

## CLAIMS

- GitHub classic OAuth/PAT scopes are named exactly and warn about over-grant: `(no scope)` = "read-only access to public information"; `repo` = "full access to public and private repositories including read and write"; narrower variants `repo:status`, `repo_deployment`, `public_repo`; plus `read:user`, `user:email`, `gist`, `notifications`, `read:org`. There is no read-only `repo` scope — `repo` is all-or-nothing read+write across all repos. The page advises "Consider building a GitHub App instead of an OAuth app." [github-oauth-scopes]
- GitHub PAT creation is an explicit numbered flow (Settings → Developer settings → Personal access tokens → Generate new token → Note → Expiration → scope checkboxes). Classic PATs "can access every repository that you can access"; GitHub recommends fine-grained tokens which "restrict to specific repositories" and "specify fine-grained permissions instead of broad scopes" (adding Resource owner, Repository access All/selected, per-resource read-only/read-write Permissions). Hard limit: "There is a limit of 50 fine-grained personal access tokens you can create. If you require more tokens or are building automations, consider using a GitHub App." [github-pat]
- Plaid Link setup is a hosted token-mediated flow, not a credential form: the server mints a short-lived `link_token`, the SDK runs institution-select → login → account-select, then returns a `public_token` exchanged server-side for an `access_token`; the host app never sees the bank password. The account-select step lets the user pick which accounts at an institution to share; one Item can carry multiple accounts, and re-running Link adds a second institution. [plaid-link]
- Plaid's OAuth guide documents an app-to-app handoff (e.g. Chase's own app launches with Face ID/Touch ID, then redirects back). On iOS this requires an Apple App Association file mapping the redirect URI; with webviews app-to-app is "not automatic" and Plaid "strongly recommends" a mobile SDK or Hosted Link with a Universal Link `redirect_uri`; the handoff is testable in Sandbox (`ins_132241` "First Platypus Bank - OAuth App2App"). The handoff out and back is an explicit, designed, testable seam. [plaid-oauth]
- Stripe Connect forces an explicit onboarding configuration choice up front (Stripe-hosted vs embedded components vs API) rather than one-size-fits-all. [stripe-onboarding]
- Stripe-hosted onboarding requires two URLs on handoff: `return_url` (where the user lands when done) and `refresh_url` (where they land if the link expired or was already visited — a first-class designed resume state). HTTP is allowed only in test; "live mode only accepts HTTPS." Completion is a state, not a button: the platform listens for account `requirements` changes and re-sends an account through onboarding when it has any `currently_due` or `eventually_due` requirements; "the onboarding interface knows what information it needs to collect." [stripe-hosted]
- Railway's project "canvas" is "mission control" for infrastructure/environments/deployments; "Once the initial deployment is complete, your app is ready to go." On failure: "you can explore your build or deploy logs for clues… scroll through the entire log; important details are often missed, and the actual error is rarely at the bottom." Deploy is a live observable process with a build-vs-deploy split. [railway-quickstart]
- Railway deployments are first-class objects with explicit lifecycle states and per-deploy logs; a deploy that builds successfully but crashes at runtime is distinguished from a build failure. [railway-deployments]
- Vercel: "Every time your project builds successfully, Vercel creates a deployment with its own URL." Multiple entry modalities are equals ("Push code, run a CLI command, call the API, or drag a folder into your browser"). Deployments are immutable, URL-addressable artifacts with build → ready → error states, and production has an explicit "Rolling back a production deployment" path. [vercel-deployments]
- Supabase's Next.js quickstart names exactly which env vars to populate — `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` — copied from a labeled "Project URL" / "Publishable key" panel into `.env.local`; the config surface is concrete and copy-pasteable. [supabase-quickstart]
- Supabase frames that "most apps have at least two environments" (production + staging/preview) and provides self-hosting as a documented first-class path with a docker-compose stack and operator-generated secrets. [supabase-deployment]
- Tailscale first-run: sign in with SSO → "Let's add your first device" → pick OS → authenticate the client → "Once you are authenticated, the device will appear in the browser window." Adding a second device: "Copy the link and send it to the second device." Enrollment is one authenticated command giving immediate positive feedback (the device materializes). [tailscale-install]
- Google OAuth scopes are exact, copy-pasteable URLs with two-tier sensitivity: `https://www.googleapis.com/auth/gmail.readonly` = "View your email messages and settings"; `https://www.googleapis.com/auth/gmail.metadata` = "metadata such as labels and headers, but not the email body"; `https://mail.google.com/` = "Read, compose, send, and permanently delete all your email." "Sensitive scopes require review by Google … it's best to use a scope that isn't sensitive." Public apps "must complete a verification process"; during testing an "unverified app" screen appears until verification is submitted. [google-oauth-scopes]
- Google's OAuth consent screen config is operator-facing (App name, Logo, Support email, links); publishing status (Testing → In production) and a "test users" allowlist gate who can authorize before verification. [google-consent-screen]

## SOURCES

**github-oauth-scopes**
URL: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps
Accessed: 2026-06-18

**github-pat**
URL: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
Accessed: 2026-06-18
Quote: "There is a limit of 50 fine-grained personal access tokens you can create. If you require more tokens or are building automations, consider using a GitHub App for better scalability and management."

**plaid-link**
URL: https://plaid.com/docs/link/
Accessed: 2026-06-18

**plaid-oauth**
URL: https://plaid.com/docs/link/oauth/
Accessed: 2026-06-18

**stripe-onboarding**
URL: https://docs.stripe.com/connect/onboarding
Accessed: 2026-06-18

**stripe-hosted**
URL: https://docs.stripe.com/connect/hosted-onboarding
Accessed: 2026-06-18
Quote: "the onboarding interface knows what information it needs to collect."

**railway-quickstart**
URL: https://docs.railway.com/quick-start
Accessed: 2026-06-18
Quote: "scroll through the entire log; important details are often missed, and the actual error is rarely at the bottom."

**railway-deployments**
URL: https://docs.railway.com/guides/deployments
Accessed: 2026-06-18

**vercel-deployments**
URL: https://vercel.com/docs/deployments/overview
Accessed: 2026-06-18
Quote: "Every time your project builds successfully, Vercel creates a deployment with its own URL."

**supabase-quickstart**
URL: https://supabase.com/docs/guides/getting-started/quickstarts/nextjs
Accessed: 2026-06-18

**supabase-deployment**
URL: https://supabase.com/docs/guides/deployment
Accessed: 2026-06-18

**tailscale-install**
URL: https://tailscale.com/kb/1017/install
Accessed: 2026-06-18
Quote: "Once you are authenticated, the device will appear in the browser window."

**google-oauth-scopes**
URL: https://developers.google.com/identity/protocols/oauth2/scopes
Accessed: 2026-06-18

**google-consent-screen**
URL: https://support.google.com/cloud/answer/10311615
Accessed: 2026-06-18

## SYNTHESIS

Across connector-setup, OAuth-onboarding, and operator-deploy flows a shared discipline appears. (1) Declare the modality before the user starts — Stripe forces a hosted/embedded/API choice; Plaid declares OAuth/app-to-app vs credential; GitHub distinguishes classic vs fine-grained — so the user is never dropped into a form that might be the wrong kind. (2) Disclose prerequisites and exact scopes up front, in provider vocabulary — GitHub names the literal checkbox, Google the literal scope URL, Supabase the literal env var; none say "configure access." (3) Validate the credential/identity before claiming success — Plaid returns a `public_token` only after the bank authenticates; Stripe gates completion on `requirements` clearing; success echoes the provider identity. (4) The handoff out and back is a designed, named seam — Plaid redirect_uri/Universal Link; Stripe `return_url` + `refresh_url` with an explicit expired/already-visited resume path. (5) Post-submit is a live, observable process, not a terminal "submitted" — Railway streams build-then-deploy logs and distinguishes build-fail from runtime-crash; Vercel makes every deploy a durable object; Tailscale makes the device appear the instant it authenticates. (6) Multi-account/multi-device is first-class — Plaid account-select + re-run Link; Tailscale add-second-device with a copy-link. (7) Unavailable is honest and named with a forward path — Google's "unverified app" + verification path; Stripe's `refresh_url` expired-link state; Plaid degrading webview app-to-app to Hosted Link. (8) Remove/repair is symmetric with add — Plaid update-mode, Stripe re-onboarding on new requirements, Google's Delete-link confirm ceremony. The transferable rules for any "add a data source" flow: gate the CTA on a real capability check (never an enabled action that opens a page that immediately fails), name the exact narrowest scope, validate before success, define both a return and an expired-link resume landing, and show live first-sync progress with a new-records-this-run count rather than a bare "collected."
