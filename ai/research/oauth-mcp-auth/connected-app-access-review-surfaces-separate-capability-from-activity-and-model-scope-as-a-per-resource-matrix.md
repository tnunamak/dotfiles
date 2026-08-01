---
title: "Connected-app access-review surfaces separate capability (can read) from activity (has read), group by app not grant, and model scope as a per-resource graded matrix"
date: 2026-06-18
topic: oauth-mcp-auth
tags: [access-review, oauth, connected-apps, scopes, revocation, consent, prior-art]
status: draft
sources: [google-connections, google-devices, github-revoke-apps, github-installed-apps, github-fine-grained-pat, stripe-keys, stripe-keys-best-practices, plaid-dtm, plaid-portal, apple-siwa]
source_session: 019d189c-d050-7a92-af4a-aab2be41b5f1
---

## CLAIMS

- Google's "Manage links between your Google Account & apps" surface is a single linked-apps list at `myaccount.google.com/connections` grouped by app; it documents two link directions with fixed phrasing templates — an app reading the user's data appears as "{App name} has some access to your Google Account", and Google reading the linked app appears as "Google has some access to your {app name} account." Multiple link types of the same app collapse into one app row, expanded inside the app's detail. [google-connections]
- Google's per-app detail uses the fixed phrasing template, then a "See details" affordance listing concrete access, then "Delete link" → "Confirm" as the terminal action, carrying an explicit consequence statement: "If you delete this link, Google loses access to your account on the app. You won't have access to features that require this link on any device where you're signed in." [google-connections]
- Google keeps a separate activity/recent-use surface (`google.com/devices`) framed around "where you are or were signed in … recently" and "make sure no one else has signed in" — audit of actual use, distinct from and cross-linked to the capability (permissions) surface. [google-devices]
- GitHub's "Reviewing and revoking authorization of GitHub Apps" states its purpose as "You can review the GitHub Apps that you have authorized, and you can revoke your authorization" — review-then-revoke, with revocation the primary verb. [github-revoke-apps]
- GitHub installed-app capability is two-axis (permission kind × which specific repositories): "When you install a GitHub App, you grant the app the organization and repository permissions that it requested. If the app requested repository permissions, you also specify which repositories the GitHub App can access." The resource set is editable after the fact ("change the repositories the GitHub App can access"), and a non-destructive "suspend" sits beside delete. [github-installed-apps]
- GitHub fine-grained personal access tokens model scope as a per-resource graded matrix: a token has a resource target plus per-permission access levels, and "Permissions can be set to `read`, `write`, or `admin`, but not every permission supports each of those levels." The Account-permissions table enumerates dozens of resources each with allowed levels (e.g. `emails` → read/write; `user_events` → read; `profile` → write; `plan` → read); one row per resource, cell = chosen level, available levels constrained by resource type, an unnamed resource = no access. Tokens carry an expiration (default 30 days). [github-fine-grained-pat]
- Stripe distinguishes standard API keys (full read/write) from restricted keys, which exist to let a credential be least-privilege scoped per resource. [stripe-keys]
- Stripe's key best-practices page states least-privilege in prose: create restricted keys granting only the permissions the integration needs, scoped per resource, preferring read-only. The literal None/Read/Write three-state grid (one cell per Stripe resource — Charges, Customers, Invoices, …) is the Stripe Dashboard restricted-key creation UI (observed dashboard behavior, not text on the doc page); default for an unselected resource is None (deny-by-default). Keys are independently revocable/rollable to contain blast radius. [stripe-keys-best-practices]
- Plaid Data Transparency Messaging presents capability as (data type × purpose) in the user's own terms: "a user is informed of the specific data types that you are requesting and the reason that you are requesting them (use cases)." Each new data type or new purpose is its own consent event: "If you want access to additional data … or to use the data for additional use cases, they must consent to sharing that data through a separate consent flow." Disclosures render at the Account Select pane, so consent is per-account and per-data-type. [plaid-dtm]
- Plaid Portal (`my.plaid.com`) is marketed as "the convenient way to manage your financial data" — a consumer-facing, per-connection management surface where the end user (not the app developer) sees and manages which apps connect to which financial accounts. [plaid-portal]
- Apple's "Manage your apps with Sign in with Apple" is a single in-Settings list (Settings → [your name] → Sign in with Apple) of apps/developers used with the Apple ID; selecting one shows detail and a Delete action with on-screen confirmation. Consequence is stated plainly: "When you stop using your Apple Account with an app, you're signed out … you have to share your name and email address with the app again." Apple frames the minimal data shared (name + email) as the capability. [apple-siwa]

## SOURCES

**google-connections**
URL: https://support.google.com/accounts/answer/13533235 ; https://myaccount.google.com/connections
Accessed: 2026-06-18
Quote: "{App name} has some access to your Google Account." / "If you delete this link, Google loses access to your account on the app."

**google-devices**
URL: https://support.google.com/accounts/answer/3067630
Accessed: 2026-06-18

**github-revoke-apps**
URL: https://docs.github.com/en/apps/using-github-apps/reviewing-and-revoking-authorization-of-github-apps
Accessed: 2026-06-18
Quote: "You can review the GitHub Apps that you have authorized, and you can revoke your authorization."

**github-installed-apps**
URL: https://docs.github.com/en/apps/using-github-apps/reviewing-and-modifying-installed-github-apps
Accessed: 2026-06-18
Quote: "When you install a GitHub App, you grant the app the organization and repository permissions that it requested."

**github-fine-grained-pat**
URL: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
Accessed: 2026-06-18
Quote: "Permissions can be set to `read`, `write`, or `admin`, but not every permission supports each of those levels."

**stripe-keys**
URL: https://docs.stripe.com/keys
Accessed: 2026-06-18

**stripe-keys-best-practices**
URL: https://docs.stripe.com/keys-best-practices
Accessed: 2026-06-18

**plaid-dtm**
URL: https://plaid.com/docs/link/data-transparency-messaging-migration-guide/
Accessed: 2026-06-18
Quote: "a user is informed of the specific data types that you are requesting and the reason that you are requesting them (use cases)."

**plaid-portal**
URL: https://my.plaid.com/
Accessed: 2026-06-18

**apple-siwa**
URL: https://support.apple.com/en-us/102571
Accessed: 2026-06-18
Quote: "When you stop using your Apple Account with an app, you're signed out … you have to share your name and email address with the app again."

## SYNTHESIS

A consistent access-review pattern emerges across consumer-facing "which apps can touch my data" surfaces. (1) The grouping object is the client/app, not an individual grant — Google, Apple, and GitHub all show one row per app and expand its multiple grants only in detail. (2) Capability is a per-resource graded matrix, deny-by-default — Stripe (None/Read/Write per resource), GitHub fine-grained tokens (read/write/admin per resource, levels constrained by type, unnamed = no access), and GitHub Apps (permission × which repos); free-text scope strings appear nowhere in the owner-facing layer. (3) Capability ("can read") and activity ("did read / last used") are separate, cross-linked surfaces — Google's apps-with-access vs devices/recent-activity is the canonical split. (4) Capability re-presents consent in the same concrete terms the user agreed to (Plaid DTM's data-type × purpose), and each new data type/purpose is its own consent event, so a multi-grant "package" is an honest accretion of discrete grants. (5) Revocation is the primary verb, with a softer "suspend" where useful (GitHub), guarded by a plain-language consequence statement + confirm (Google's "Delete link → Confirm", Apple's Delete). (6) Capability is time-bounded and independently revocable (GitHub token expiration; Stripe rollable keys) to contain blast radius. The transferable shape for any "review the apps that can read my data" screen: one row per app → a per-resource capability matrix (rows = resources, cells = graded access, absence = no access) → a separate activity/last-read view → a revoke-first action with consequence copy.
