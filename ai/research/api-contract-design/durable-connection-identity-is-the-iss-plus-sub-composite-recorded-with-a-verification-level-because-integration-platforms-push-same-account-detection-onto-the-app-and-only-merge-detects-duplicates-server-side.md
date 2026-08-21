---
title: "Durable connection identity is an (issuer/tenant + stable account id + verification method) tuple, not a bare id: OIDC guarantees only iss+sub, integration platforms push 'is this the same account?' onto the app, and Merge — the one platform that detects duplicates server-side — fingerprints credentials and exposes the mismatch response as a three-way policy"
date: 2026-08-16
topic: api-contract-design
tags: [connection-identity, oauth, oidc, dedupe, entity-resolution, plaid, merge, nango, mdm, reconnect, prior-art]
status: draft
sources: [oidc-core, entra-claims, plaid-accounts, plaid-duplicates, plaid-update-mode, slack-migration, github-users, discord-users, amazon-lwa, nango-providers, merge-duplicates, merge-linked, stripe-oauth, segment-identity, amplitude-userid, reltio-merge, informatica-xref, scim-rfc7643, timelinize-repo, twitter-archive, immich-owner, stripe-idempotency]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

## CLAIMS

### The spec-guaranteed identity key

- OpenID Connect Core 1.0 §5.7 states that `sub` and `iss` used **together** are "the only Claims that an RP can rely upon as a stable identifier for the End-User," and that "the only guaranteed unique identifier for a given End-User is the combination of the `iss` Claim and the `sub` Claim." [oidc-core]
- The same section is normative that `email`, `phone_number`, `preferred_username`, and `name` **"MUST NOT be used as unique identifiers"**, because an issuer MAY reuse an email address across different users over time. [oidc-core]
- The issuer/tenant component is load-bearing, not padding: Microsoft Entra's `sub` is **pairwise per-application**, so the durable key is `oid` + `tid`, and "if a single user exists in multiple tenants, the user contains a different object ID in each tenant." [entra-claims]
- SCIM (RFC 7643 §3.1) splits `id` (server-assigned, authoritative, globally unique) from `externalId` (client-asserted, explicitly not globally unique) — the right shape for a verification-level vocabulary. [scim-rfc7643]

### Per-provider stable ids and what actually mutates

- Google: `sub` is durable; email changes and is reusable across users. [oidc-core]
- Slack: `team_id` + `user_id` (+ `enterprise_id`), but **Enterprise Grid migration mints new global IDs**, and Slack ships `migration.exchange` for the sole purpose of remapping old IDs to new. A scheme assuming "a durable ID never changes" breaks precisely here. [slack-migration]
- GitHub: the numeric `id` is durable; `login` changes freely. [github-users]
- Discord: the snowflake `id` is durable; `username` / `global_name` are not. [discord-users]
- Amazon Login with Amazon: `user_id` is **pairwise per relying party**, not a global ID — and no order-history scope exists at all, so order data has no OAuth identity path. [amazon-lwa]

### What platforms do when there is no stable id

- Plaid's own docs admit `account_id` is not durable: "This value will not change unless Plaid can't reconcile the account... The `account_id` can also change if the access_token is deleted and the same credentials that were used to generate that access_token are used to generate a new access_token on a later date." [plaid-accounts]
- Plaid's `persistent_account_id` exists to fix this but covers **only Chase, PNC, and US Bank** (tokenized-account-number institutions). [plaid-accounts]
- For all other institutions, Plaid's official duplicate-detection guidance is fuzzy matching on `institution_id` + account `name` + `mask`, with an explicit warning: "Never detect duplicate Items by attempting to match a `mask` with an account number." Plaid states plainly that linking the same account at the same institution twice produces two Items with different `item_id` values. [plaid-duplicates]
- Nango lifts the provider's own account id declaratively out of the OAuth token response via `token_response_metadata` in `providers.yaml` (Slack's config captures `team.id` this way), with `post_connection_script` as the fallback when an extra API call is required. [nango-providers]

### Reconnect / mismatch handling

- **Merge is the only surveyed platform with server-side duplicate detection**, and it works by fingerprinting **credentials**, not account IDs: "if the same API key used on two separate Merge linked account, we will flag them as duplicates." A `?include_duplicates` parameter exists on `/linked-accounts`. [merge-duplicates]
- Merge exposes the mismatch response as an operator-configurable **three-way policy**: (1) create the duplicate anyway and flag it on the dashboard (default), (2) show success but do not create, returning a `public_token` resolving to the *existing* account, (3) show an error and refuse to create. [merge-duplicates]
- Merge's relink otherwise keys purely on the app-supplied `end_user_origin_id`. [merge-linked]
- Stripe Connect returns whatever `stripe_user_id` the account picker produced, with **no documented mismatch handling**. [stripe-oauth]
- Nango fires an `operation = override` webhook identically whether or not the reconnect is the same provider account. [nango-providers]
- Segment's one good instinct is blocking rather than guessing: its algorithm "detects when a merge would break user_id uniqueness and prevents the merge." [segment-identity]

### Merge semantics — link, don't destroy

- Reltio crosswalks: on merge the losing entity ID "is not discarded but held invisibly within the metadata of the merged entity." [reltio-merge]
- Informatica XREF tables retain every source system's own primary key, with **unmerge as a first-class operation**. [informatica-xref]
- CDPs are the counterexample and the warning: Segment and Amplitude merge destructively with no unmerge primitive, and Amplitude documents flatly that "after you set a user ID in Amplitude, you can't change it." [amplitude-userid] [segment-identity]

### Non-OAuth source identity

- Timelinize's `Attribute` struct carries an explicit `Identity bool` flag documented as: "If true, this attribute defines a person's identity on the data source... There should only be 1 identity attribute per data source." It degrades gracefully — for Google Voice, where only a name is available, it manufactures a weak `gvoice_name` identifying attribute that can later merge with a phone number. [timelinize-repo]
- The X/Twitter archive's `data/account.js` holds `accountId`, `username`, and `email` as three **separate** fields — durable ID, mutable handle, and verifiable contact, not conflated. [twitter-archive]
- Negative findings: Immich records only a local `ownerId` with **no source-account identity**, causing real triplicate-ingestion bugs; Apple Health's export contains **no account identity at all**, only `sourceName` device strings. [immich-owner]

### Idempotency

- Stripe idempotency keys are mechanical and involve no probabilistic judgment; reusing a key with a changed request body is a **hard error**, not a silent overwrite. [stripe-idempotency]

## SOURCES

**oidc-core**
URL: https://openid.net/specs/openid-connect-core-1_0.html
Accessed: 2026-08-16
Quote: "The sub (subject) and iss (issuer) Claims, used together, are the only Claims that an RP can rely upon as a stable identifier for the End-User... Therefore, the only guaranteed unique identifier for a given End-User is the combination of the iss Claim and the sub Claim."

**entra-claims**
URL: https://learn.microsoft.com/en-us/entra/identity-platform/id-token-claims-reference
Accessed: 2026-08-16
Quote: "If a single user exists in multiple tenants, the user contains a different object ID in each tenant."

**plaid-accounts**
URL: https://plaid.com/docs/api/accounts/
Accessed: 2026-08-16
Quote: "This value will not change unless Plaid can't reconcile the account with the data returned by the financial institution."

**plaid-duplicates**
URL: https://plaid.com/docs/link/duplicate-items/
Accessed: 2026-08-16
Quote: "Never detect duplicate Items by attempting to match a mask with an account number."

**plaid-update-mode**
URL: https://plaid.com/docs/link/update-mode/
Accessed: 2026-08-16

**slack-migration**
URL: https://api.slack.com/methods/migration.exchange
Accessed: 2026-08-16

**github-users**
URL: https://docs.github.com/en/rest/users/users
Accessed: 2026-08-16

**discord-users**
URL: https://discord.com/developers/docs/resources/user
Accessed: 2026-08-16

**amazon-lwa**
URL: https://developer.amazon.com/docs/login-with-amazon/obtain-customer-profile.html
Accessed: 2026-08-16

**nango-providers**
URL: https://docs.nango.dev/guides/api-authorization/overview
Accessed: 2026-08-16

**merge-duplicates**
URL: https://help.merge.dev/en/articles/6463873-duplicate-production-linked-accounts
Accessed: 2026-08-16
Quote: "if the same API key used on two separate Merge linked account, we will flag them as duplicates"

**merge-linked**
URL: https://docs.merge.dev/merge-unified/merge-link/overview/
Accessed: 2026-08-16

**stripe-oauth**
URL: https://stripe.com/docs/connect/oauth-reference
Accessed: 2026-08-16

**segment-identity**
URL: https://segment.com/docs/unify/identity-resolution/identity-resolution-overview/
Accessed: 2026-08-16

**amplitude-userid**
URL: https://amplitude.com/docs/data/sources/instrument-track-user-id
Accessed: 2026-08-16
Quote: "after you set a user ID in Amplitude, you can't change it"

**reltio-merge**
URL: https://docs.reltio.com/matchmerge/merginginreltio.html
Accessed: 2026-08-16
Quote: "is not discarded but held invisibly within the metadata of the merged entity"

**informatica-xref**
URL: https://docs.informatica.com/master-data-management/multidomain-mdm/10-3/overview-guide/key-concepts/content-metadata/cross-reference--xref--tables.html
Accessed: 2026-08-16

**scim-rfc7643**
URL: https://www.rfc-editor.org/rfc/rfc7643.html
Accessed: 2026-08-16

**timelinize-repo**
URL: https://github.com/timelinize/timelinize
Accessed: 2026-08-16
Quote: "If true, this attribute defines a person's identity on the data source... There should only be 1 identity attribute per data source."

**twitter-archive**
URL: https://help.x.com/en/managing-your-account/how-to-download-your-x-archive
Accessed: 2026-08-16

**immich-owner**
URL: https://github.com/immich-app/immich/discussions/15009
Accessed: 2026-08-16

**stripe-idempotency**
URL: https://docs.stripe.com/api/idempotent_requests
Accessed: 2026-08-16

## SYNTHESIS

The spec answer and the practice answer diverge sharply, and the divergence is the finding. OIDC hands you a clean composite key (`iss` + `sub`) and forbids using email as an identifier — yet **almost no integration platform stores one**. Plaid, Airbyte, Fivetran, Nango, and Merge all push "is this the same account?" onto the integrating application. Merge is the sole exception with server-side detection, and it does not compare account IDs at all: it fingerprints *credentials*. So the honest posture for a small app is that nobody is going to hand you this; you must capture it yourself at the one moment it is knowable.

That moment is the only real constraint. Account identity is cheaply observable exactly once — at connect/auth time, when the token response or the first authenticated `whoami` call is in hand — and it is **permanently unrecoverable afterwards** if not written down. This asymmetry is what makes the gap urgent out of proportion to its size: it is not "we lack a feature," it is "every day we do not capture it, more rows become permanently un-deduplicable." One nullable column plus a write at the auth callback closes it going forward; nothing closes it retroactively.

The minimal durable tuple is `(provider, issuer_or_tenant, stable_account_id, verification_method, observed_at)`, and the fourth field is what keeps the design honest. Identity quality genuinely differs by acquisition path — a provider-attested OIDC `sub` (verified), a scraped logged-in username (observed), an owner-typed label on a manual upload (self-declared), a local device binding (device-attested) — and collapsing these into one nullable string invites treating a guess as authoritative. SCIM's `id`/`externalId` split and W3C VC's issuer-equals-subject test both give the same shape for free, with no new schema vocabulary to invent. Plaid is the cautionary tale for skipping this: it minted an `account_id` that reads authoritative and then had to document that it silently changes, forcing every integrator onto fuzzy `institution_id`+`name`+`mask` matching anyway. Better to record a weak fingerprint labelled weak than a strong-looking ID that lies.

Timelinize's single `Identity bool` attribute per data source is the best small-scale prior art, precisely because it degrades: when Google Voice offers only a name, it manufactures a deliberately weak identifying attribute that can merge later when a phone number appears. That is the right model for manual imports and scraped sources — record *something* with an explicit confidence, rather than recording nothing because nothing perfect is available. Archives often carry identity if you look: the X archive's `account.js` separates `accountId`, `username`, and `email` exactly as a careful schema would.

On merge semantics, enterprise MDM is unanimous and the CDPs are the warning. Reltio retains the losing ID in metadata; Informatica keeps every source key in XREF with unmerge as a first-class operation; Segment and Amplitude merge destructively and cannot undo it. Link-plus-survivorship-view costs one join table and is arguably *more* valuable for a single owner than at enterprise scale, because there is no data-steward team to catch a bad automatic merge. Never destructively merge two connection rows; record a reversible `same_account_as` link and let the read model present them as one.

For mismatch on reconnect, steal Merge's structure rather than any particular default: **detection and enforcement are separate decisions**, and the response should be a policy, defaulting to non-destructive (create/keep, flag it, let the owner decide). Blocking a reconnect because the observed identity disagrees is the wrong default for a personal-data app whose value is accumulated history — a false positive locks the owner out of their own data.

What to refuse at this scale: blocking keys exist to tame O(n²) at millions of records and are pure ceremony across a few dozen connections (compare every pair). Fellegi-Sunter / Splink probabilistic weights need labeled training pairs to estimate m/u probabilities that a single owner will never produce, so hand-tuned deterministic rules will beat an unfittable model. Informatica-style per-field 0–100 trust scores reconcile many opaque third-party sources of differing reliability — but you wrote your own connectors, so a static per-field priority list suffices. Segment/RudderStack identifier limits and "blob user" defenses target anonymous multi-tenant crosstalk, which is the wrong threat model entirely. What does scale down: Stripe-style idempotency keys (mechanical, no probabilistic judgment, and note that key reuse with a changed body is a hard error rather than a silent overwrite) and the MDM link-don't-destroy principle.
