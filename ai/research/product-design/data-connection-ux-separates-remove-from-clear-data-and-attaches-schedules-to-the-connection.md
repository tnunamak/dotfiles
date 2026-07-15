---
title: "Data-connection/device UX gives each connection a stable renamable object, separates remove-connection from clear-data, attaches schedules to the connection, and uses a six-state setup machine"
date: 2026-05-27
topic: product-design
tags: [connection-ux, device-inventory, oauth-reconnect, scheduling, data-retention, plaid, fivetran, airbyte, tailscale]
status: draft
sources: [plaid-duplicate-items, plaid-items, fivetran-rename, fivetran-sync, slack-workspaces, github-multi-account, onepassword-vaults, tailscale-key-expiry, tailscale-remove, syncthing-faq, dropbox-device-list, google-devices, airbyte-schedules, airbyte-connections, airbyte-clear, stripe-connect-requirements, linear-slack, slack-auth-revoke]
---

<!-- Reusable per-product prior-art extracted from a pdpp connection/device-UX note.
     pdpp-specific [SLVP]/[OPEN]/[DEFER] recommendations were dropped. -->

## CLAIMS

- Across Plaid, 1Password, Slack, GitHub, Tailscale, and Dropbox a connection/account is a stable owner-facing object with a separate user-editable label (and often color/icon) plus a disclosed system identifier — the override never replaces the system identifier; both are surfaced. [plaid-duplicate-items][onepassword-vaults][slack-workspaces][github-multi-account][tailscale-remove]
- Plaid labels items as `institution.name` + `account.mask` + `subtype` and exposes `persistent_account_id` for dedupe (recommending a user-defined nickname layer on top); Fivetran connectors are named by user-set schema and are NOT renameable post-create (must clone/recreate); 1Password vaults get name + color + icon; Tailscale hostnames are auto-derived and admin-renameable while preserving the device key. [plaid-duplicate-items][fivetran-rename][onepassword-vaults][tailscale-remove]
- "Remove connection" defaults to retaining previously collected records at Plaid (`/item/remove` invalidates the token only), Fivetran (pause and delete both retain), Airbyte (delete connection retains), Dropbox (unlink keeps synced files), Tailscale (removing a device leaves peers unaffected), and Linear/Slack (`auth.revoke` retains both sides); only Airbyte's explicitly-renamed "Clear" (was "Reset") wipes destination rows behind a heavy confirmation modal. [plaid-items][fivetran-sync][airbyte-connections][dropbox-device-list][tailscale-remove][linear-slack][slack-auth-revoke][airbyte-clear]
- Removing a device revokes its credential and ends future capture while records remain owned by the connection; Tailscale node keys auto-expire (180d default, tagged devices exempt), Google keeps a device's historical entry visible up to 28d for audit, and Dropbox treats remote-wipe as a separate paid opt-in. [tailscale-key-expiry][tailscale-remove][google-devices][dropbox-device-list]
- Schedules belong to the connection, not the connector type: Fivetran (per-connection fixed-interval default 6h or cron, auto-pause after 14d failure, manual = REST-only trigger), Airbyte (per-connection Scheduled/Cron-Quartz/Manual, manual = effective pause, hourly minimum, ±30min jitter), and Hevo/Stitch (per-pipeline interval + pause) all share this shape. [fivetran-sync][airbyte-schedules]
- Auto-pause after N consecutive failures is the gold-standard failure ladder (Fivetran's 14d), surfaced as a distinct state. [fivetran-sync]
- A useful connection setup state machine is `draft → ready → paused ↔ error → needs_reconnect → retired`, synthesized from Airbyte `sync_on_create:false` (draft), Fivetran retry tiers (error), Plaid `ITEM_LOGIN_REQUIRED` / Stripe `past_due` / Tailscale key-expired (needs_reconnect), and owner-removed-but-records-retained (retired). [airbyte-schedules][fivetran-sync][plaid-items][stripe-connect-requirements][tailscale-key-expiry]
- Stripe Connect's `currently_due` vs `eventually_due` split is a reusable deferred-action pattern: surface "this connection will need attention by X" (deadline + remediation link) without blocking current capture — but the full `requirements` field set is too domain-specific to copy wholesale. [stripe-connect-requirements]
- Plaid's `persistent_account_id` solves "same account re-linked = different Item" duplicates; the reusable equivalent is a stable hash of `(provider, account_sub, exporter_kind)`. [plaid-duplicate-items]
- Slack and GitHub both use a left-rail icon stack + ⌘+number shortcut for multi-workspace/multi-org switching. [slack-workspaces][github-multi-account]
- Plaid emits a `USER_ACCOUNT_REVOKED` webhook on upstream revocation, precedent for emitting a `connection.retired`-style event on retirement so downstream consumers can react. [plaid-items]

## SOURCES

**plaid-duplicate-items**
URL: https://plaid.com/docs/link/duplicate-items/
Accessed: 2026-05-27

**plaid-items**
URL: https://plaid.com/docs/api/items/
Accessed: 2026-05-27

**fivetran-rename**
URL: https://fivetran.com/docs/connectors/troubleshooting/rename-a-connector
Accessed: 2026-05-27

**fivetran-sync**
URL: https://fivetran.com/docs/core-concepts/syncoverview
Accessed: 2026-05-27

**slack-workspaces**
URL: https://slack.com/help/articles/1500002200741-Switch-between-workspaces
Accessed: 2026-05-27

**github-multi-account**
URL: https://github.blog/changelog/2023-11-03-multi-account-support-on-github-com/
Accessed: 2026-05-27

**onepassword-vaults**
URL: https://support.1password.com/create-share-vaults/
Accessed: 2026-05-27

**tailscale-key-expiry**
URL: https://tailscale.com/docs/features/access-control/key-expiry
Accessed: 2026-05-27

**tailscale-remove**
URL: https://tailscale.com/kb/1260/device-remove/
Accessed: 2026-05-27

**syncthing-faq**
URL: https://docs.syncthing.net/users/faq.html
Accessed: 2026-05-27

**dropbox-device-list**
URL: https://help.dropbox.com/security/device-list-remote-sign-out
Accessed: 2026-05-27

**google-devices**
URL: https://myaccount.google.com/intro/device-activity
Accessed: 2026-05-27

**airbyte-schedules**
URL: https://docs.airbyte.com/platform/using-airbyte/core-concepts/sync-schedules
Accessed: 2026-05-27

**airbyte-connections**
URL: https://docs.airbyte.com/platform/cloud/managing-airbyte-cloud/configuring-connections
Accessed: 2026-05-27

**airbyte-clear**
URL: https://docs.airbyte.com/platform/operator-guides/clear
Accessed: 2026-05-27

**stripe-connect-requirements**
URL: https://docs.stripe.com/connect/upcoming-requirements-updates
Accessed: 2026-05-27

**linear-slack**
URL: https://linear.app/docs/slack
Accessed: 2026-05-27

**slack-auth-revoke**
URL: https://docs.slack.dev/reference/methods/auth.revoke/
Accessed: 2026-05-27

## SYNTHESIS

For any product that owns "configured data source" objects, the cross-product consensus is: a stable connection object with a free-text alias over a smaller always-shown system identifier (avoid Fivetran's no-rename-after-create); three distinct verbs instead of one conflated "Delete" — Pause (stop scheduled runs, keep everything), Retire/Disconnect (revoke credentials, mark terminal, records retained and queryable), and a separate typed-confirmation "Delete records…" flow (every product that conflates these generates support tickets, as Airbyte's Reset→Clear rename shows); schedules attached to the connection with auto-pause after N failures as a distinct state; a six-state setup machine with an explicit `needs_reconnect` state and a clear reconnect CTA; and a persistent dedupe identifier so a re-linked account isn't a duplicate. Multi-binding under one connection (aggregate OAuth + browser profile + device path) has no clean prior art — the closest analogues (Tailscale device-with-tags, 1Password vault-across-devices) are flat, suggesting bindings should live as a child collection in a disclosure panel rather than a primary axis.
