---
title: "First-run setup journeys are staged one subject at a time, with each stage's status observed by the product (not inferred from logs), identity echoed before completion, and access review as a product surface rather than a raw audit log"
date: 2026-06-18
topic: onboarding-ux
tags: [onboarding, first-run, staged-setup, identity-echo, self-host, prior-art]
status: draft
sources: [tailscale-quickstart, railway-variables, vercel-projects, stripe-connect, plaid-link-returning, github-fgpat, google-linked-apps, supabase-keys]
source_session: 019ce297-6779-78c0-a12e-667fda61949e
---

## CLAIMS

- Tailscale starts from the concrete object the user wants to add (a device); the browser guide and device app form one loop (choose OS → install client → authenticate → the device appears back in the browser), and the user is not expected to infer success from logs. [tailscale-quickstart]
- Railway treats variables as deployment configuration (not per-account user setup), visible in a deployment context and available to build, runtime, `railway run`, and shell contexts. [railway-variables]
- Vercel separates project, deployment, logs, domains, and environment variables while keeping them in one project context; a deployment has status, URL, commit/source, and actions, and operational evidence is kept distinct from the app's product content. [vercel-projects]
- Stripe Connect uses hosted onboarding or embedded components to collect required information in a dynamically scoped flow; requirements are concrete, tied to capabilities, and can be current or future requirements — the platform does not ask users to infer missing requirements from post-submit API errors. [stripe-connect]
- Plaid Link owns credential validation, MFA, institution errors, account selection, and success return; returning-user flows reuse what they can, then ask the user to select accounts when selection is the essential decision. [plaid-link-returning]
- GitHub exposes exact permissions and resource scope for fine-grained tokens (permission sets, repositories, organizations, expiration); the setup is still cognitively heavy, so the product reduces ambiguity by naming each of those explicitly rather than saying "paste a token." [github-fgpat]
- Google separates sign-in, linked apps, and third-party access review; the user chooses an account and can later review or remove app access, and consent display can distinguish verified origin from client-authored name/logo. [google-linked-apps]
- Supabase separates project keys, publishable keys, secret keys, and management API tokens with explicit privilege boundaries, and explains which keys are appropriate for client vs server contexts. [supabase-keys]

## SOURCES

**tailscale-quickstart**
URL: https://tailscale.com/docs/how-to/quickstart ; https://tailscale.com/docs/features/access-control/device-management/how-to/set-up
Accessed: 2026-06-18

**railway-variables**
URL: https://docs.railway.com/variables ; https://docs.railway.com/variables/reference
Accessed: 2026-06-18

**vercel-projects**
URL: https://vercel.com/docs/projects ; https://vercel.com/docs/deployments ; https://vercel.com/docs/deployments/managing-deployments
Accessed: 2026-06-18

**stripe-connect**
URL: https://docs.stripe.com/connect/hosted-onboarding ; https://docs.stripe.com/connect/custom/hosted-onboarding ; https://docs.stripe.com/connect/required-verification-information
Accessed: 2026-06-18

**plaid-link-returning**
URL: https://plaid.com/docs/link/ ; https://plaid.com/docs/link/returning-user/ ; https://plaid.com/plaid-exchange/docs/user-experience/
Accessed: 2026-06-18

**github-fgpat**
URL: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens ; https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2026-03-10
Accessed: 2026-06-18

**google-linked-apps**
URL: https://support.google.com/accounts/answer/13533235 ; https://www.google.com/account/about/sign-in-with-google/ ; https://support.google.com/accounts/answer/13864929
Accessed: 2026-06-18

**supabase-keys**
URL: https://supabase.com/docs/guides/getting-started/api-keys ; https://supabase.com/docs/reference/api/introduction
Accessed: 2026-06-18

## SYNTHESIS

Across Tailscale, Stripe, Plaid, GitHub, Google, Vercel, Railway, and Supabase, the first-run journey converges on eight moves. (1) The journey is staged, not a documentation dump. (2) Each stage has a distinct subject — project, deployment, device, account, source, client, grant — and the next action is specific to that subject. (3) Setup status is observed by the product, not inferred from logs (Tailscale's device-appears, Stripe's requirements state, Plaid's validation return). (4) Account selection and identity echo prevent accidental mixing — the flow echoes the provider identity and a user label before completion rather than silently merging two accounts. (5) Advanced/operator prerequisites (e.g. an instance-level encryption key or deployment secret) are disclosed before the user spends effort, and are kept distinct from adding an ordinary data source. (6) Access review is a product surface answering "who can read what / what was read," not a raw audit log. (7) Credential types don't collapse into one generic "token" — deployment secrets, owner tokens, client credentials, and connector credentials are distinguished with stated privilege boundaries (Supabase). (8) Low-level identifiers stay available but are never required for ordinary comprehension. The transferable contract for a self-host/first-run flow: readiness stated in the operator's own language (ready / one setting needed / unavailable, naming the exact missing setting), an add-flow that shows only what can be added now with unavailable options honest-and-secondary, exact scopes and links before submit, validation and live first-sync after submit, and an "add another account" path for a source already in use.
