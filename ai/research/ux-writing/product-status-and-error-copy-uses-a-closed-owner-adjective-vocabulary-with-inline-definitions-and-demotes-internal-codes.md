---
title: "Product status/error/empty-state copy uses a small closed set of owner-facing state adjectives (each shipping its own one-line definition), embeds the reason in the state, and demotes the internal code to diagnostics"
date: 2026-06-18
topic: ux-writing
tags: [ux-writing, microcopy, error-messages, empty-states, status-labels, prior-art]
status: draft
sources: [stripe-errors, stripe-low-level, stripe-disputes, github-scopes, github-danger-zone, sentry-triage, sentry-issue-details, vercel-deployments, railway-deployments, trigger-runs, polaris-actionable, polaris-help, nng-errors, nng-empty, nng-microcontent, nng-ui-copy]
source_session: 019d96dc-b062-7be1-80e0-b2a931dcd464
---

## CLAIMS

- Stripe splits every error into a machine `type` + `code` (e.g. `card_error`, `invalid_request_error`, `api_connection_error`, `api_error`, `authentication_error`, `idempotency_error`, `rate_limit_error`) versus a user-facing string; the typed code is for the integrator's branching, and `error.message` "can be shown to your users" only for `card_error`/payment errors — for others the developer is told not to surface the raw message. The docs editorialize severity in plain words inline (API errors "(These are rare.)"; permission errors described as "the API key used for this request doesn't have the necessary permissions"). [stripe-errors]
- Stripe's advanced error docs reinforce the two-layer diagnostic-identifier-vs-human-sentence split. [stripe-low-level]
- Stripe's operator-facing dispute docs lead with the consequence and deadline in plain language ("respond before the deadline or the dispute is automatically lost") rather than an internal state name. [stripe-disputes]
- GitHub pairs every OAuth scope token with a plain-language capability sentence written from the data owner's point of view, front-loading read vs write, naming the concrete resource, and stating the negative boundary: `(no scope)` → "read-only access to public information"; `repo` → "full access … including read and write access to code"; `repo:status` → "read/write access to commit statuses … without granting access to the code." The scope token is the protocol identifier; the sentence is the owner copy; they are never collapsed. [github-scopes]
- GitHub's destructive-action ("danger zone") copy states the consequence in bold absolute terms before the action — "Deleting a repository will permanently delete team permissions. This action cannot be undone." — immediately followed by the reversibility window ("Some deleted repositories can be restored within 90 days"); the UI requires typing the exact repository name to enable the button. Pattern: consequence → reversibility → confirmation proportional to blast radius. [github-danger-zone]
- Sentry uses a small closed vocabulary of owner-legible issue statuses, each with a one-line condition definition: `New` ("created in the last 7 days"), `Ongoing` ("created more than 7 days ago or manually marked as reviewed"), `Escalating` ("exceeded its forecasted event volume"), `Regressed` ("a resolved issue that's come up again"), `Archived`, `Resolved` ("marked as fixed"). Two rules: "an issue can only have one status at a time," and statuses group into a default "Unresolved" tab so the front door shows only states needing a human. Every status ships its definition inline rather than relying on color. [sentry-triage]
- Sentry's issue page composes header + tags (clickable key/value facets) + stack trace + breadcrumb timeline; raw JSON is a secondary affordance, not the default. [sentry-issue-details]
- Vercel deployment states are short adjectives read at a glance (Ready, Error, Building, Queued, Canceled); destructive-action copy foregrounds reversibility/consequence in plain language ("deleting a deployment prevents you from using instant rollback on it and might break the links used in integrations"). [vercel-deployments]
- Railway exposes a deployment lifecycle with gerund/adjective state names that read as status (`Building` = "Railway will attempt to create a deployable Docker image…", `Active`, `Completed`, `Crashed`), plus a `Removing` → `Removed` transition pair for superseded deploys clearly marked as the previous deploy retiring, so a removed old deploy never reads as a failure. Each state has a one-sentence definition of what the system is doing. [railway-deployments]
- Trigger.dev (a background-job run model) gives each waiting/blocked run state an owner-readable reason embedded in its definition: "Pending version" = "waiting for a version update because it cannot execute without additional information"; "Delayed" = a run scheduled for later. The "waiting for X because Y" shape is the antidote to a bare internal token. [trigger-runs]
- Shopify Polaris content fundamentals: "Write like merchants talk… just focus on sounding human," use plain language and contractions, "some jargon is okay, as long as it's what actual merchants say," aim for a 7th-grade reading level, and the ship test "Read it out loud. Does it sound like something a human would say? Ship it." Help content is progressive-disclosure-first: add help text only when it clarifies; keep the essential message in the primary copy. [polaris-actionable, polaris-help]
- NN/g error-message guidelines: "Use human-readable language… Avoid technical jargon"; "Hide or minimize the use of obscure error codes or abbreviations; show them for technical diagnostic purposes only"; "Concisely and precisely describe the issue" but "beware of excessive technical precision… that can undermine understandability"; and "Offer constructive advice" — stating the problem is not enough, offer a remedy. It warns against hiding the situation behind cleverness (a Disney example obscuring "no results" with puns). [nng-errors]
- NN/g empty-state guidance: empty states are a learning surface with in-context "pull revelations," and must distinguish "nothing here yet (expected)" from "something is broken," because when a panel is empty "users may wonder whether an error has occurred"; a brief system-status line removes that ambiguity. [nng-empty]
- NN/g microcontent guidance: headlines/titles must work out of context and "tell readers something useful" — "avoid broad and generic headings," "remove nonessential words," "move the keywords to the front"; UI copy (command labels) is distinct and must be concise and specific because commands "change the state of the system." [nng-microcontent, nng-ui-copy]

## SOURCES

**stripe-errors**
URL: https://stripe.com/docs/error-handling
Accessed: 2026-06-18

**stripe-low-level**
URL: https://docs.stripe.com/error-low-level
Accessed: 2026-06-18

**stripe-disputes**
URL: https://stripe.com/docs/disputes/responding
Accessed: 2026-06-18

**github-scopes**
URL: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps
Accessed: 2026-06-18

**github-danger-zone**
URL: https://docs.github.com/en/repositories/creating-and-managing-repositories/deleting-a-repository
Accessed: 2026-06-18
Quote: "Deleting a repository will permanently delete team permissions. This action cannot be undone."

**sentry-triage**
URL: https://docs.sentry.io/product/issues/states-triage/
Accessed: 2026-06-18
Quote: "an issue can only have one status at a time"

**sentry-issue-details**
URL: https://docs.sentry.io/product/issues/issue-details/
Accessed: 2026-06-18

**vercel-deployments**
URL: https://vercel.com/docs/deployments/managing-deployments
Accessed: 2026-06-18

**railway-deployments**
URL: https://docs.railway.com/reference/deployments
Accessed: 2026-06-18

**trigger-runs**
URL: https://trigger.dev/docs/runs
Accessed: 2026-06-18

**polaris-actionable**
URL: https://polaris-react.shopify.com/content/actionable-language
Accessed: 2026-06-18
Quote: "Read it out loud. Does it sound like something a human would say? Ship it."

**polaris-help**
URL: https://polaris-react.shopify.com/content/help-content
Accessed: 2026-06-18

**nng-errors**
URL: https://www.nngroup.com/articles/error-message-guidelines/
Accessed: 2026-06-18
Quote: "Hide or minimize the use of obscure error codes or abbreviations; show them for technical diagnostic purposes only."

**nng-empty**
URL: https://www.nngroup.com/articles/empty-state-interface-design/
Accessed: 2026-06-18

**nng-microcontent**
URL: https://www.nngroup.com/articles/microcontent-how-to-write-headlines-page-titles-and-subject-lines/
Accessed: 2026-06-18

**nng-ui-copy**
URL: https://www.nngroup.com/articles/ui-copy/
Accessed: 2026-06-18

## SYNTHESIS

A convergent two-layer model appears across Stripe, Sentry, Railway, Vercel, Trigger.dev, GitHub, and NN/g: a small fixed vocabulary of owner-facing state adjectives, each shipping a one-line plain definition, kept strictly separate from a rich internal event/code stream — the owner word is never the internal token. Reusable rules: (1) single status at a time + a "needs human" front tab (Sentry's one-status rule and default Unresolved tab), so a headline is a deterministic projection of one count. (2) Reason-embedded waiting states (Trigger.dev "waiting for X because Y") — never a bare token like "draining." (3) Error copy = what happened / why / what to do, with the diagnostic code present-but-secondary and copyable (NN/g + Stripe). (4) Scope/access copy is owner-POV, verb-first, naming the concrete resource and the negative boundary (GitHub). (5) Destructive copy: consequence → reversibility → confirmation proportional to blast radius (GitHub/Vercel; type-the-name for true deletes). (6) Empty ≠ broken — disambiguate "nothing yet (expected)" from an error, and double the empty state as in-context teaching. (7) The voice test is "read it out loud": plain language, contractions, ~7th-grade reading level, jargon only if it's the reader's own word. A practical enforcement move is a banned-internal-vocabulary string-scan over owner-facing surfaces so scheduler/protocol nouns never leak into a user-facing headline.
