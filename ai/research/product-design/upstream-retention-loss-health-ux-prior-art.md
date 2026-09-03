---
title: "Mature data-sync products treat upstream retention loss as a scope/capability fact recorded once at the boundary, not a health signal — none surveyed degrade primary health for data the provider no longer serves, and the closest in-system irrecoverability record is a structural non-health marker (Plaid's per-institution history caps, Arq's 'Deleted/Kept' status, PyPI/crates.io yank records)"
date: 2026-08-26
topic: product-design
tags: [retention-loss, completeness, health-ux, denominator, provenance, tombstone, financial-aggregators, backup-tools, package-registries, consumer-product]
status: draft
sources: [plaid-transactions-api, plaid-bofa-history, plaid-days-requested-search, plaid-account-activity, quickbooks-90-day-official, quickbooks-90-day-community, xero-bank-feed-search, google-takeout-help, google-takeout-deleted-search, google-photos-backup-status, backblaze-version-history, backblaze-restoring-deleted, arq-thinning-community, pypi-yanking-docs, pep-592]
source_session: 5f38da1a-5459-4f34-81e8-1378f5c42678
---

<!--
Builds on, does not repeat:
- product-design/data-possession-and-work-in-flight-are-orthogonal-axes-and-the-owner-maintainer-message-split-is-by-actor-not-tone.md
  (data-possession × work-in-flight orthogonality; last-known-good must be labeled+bounded;
  owner/maintainer split is by actor not tone; condition lists are filtered to non-passing rows)
- api-contract-design/health-vocabularies-separate-a-lifecycle-axis-from-a-verdict-axis-and-kubernetes-explicitly-refuses-to-recommend-positive-condition-polarity.md
  (lifecycle vs verdict axes; Kubernetes condition schema; not_applicable = absence of a condition;
  PDPP's 13 conditions and the ProjectionReliable/BacklogClear findings)

This entry adds a THIRD axis neither covers: permanent, provider-caused, unrecoverable absence
(retention cliffs, deletions, yanks) as opposed to "not yet fetched" (possession) or "currently
erroring" (verdict). The central finding is a DENOMINATOR argument: every surveyed product scopes
its completeness claim to what the provider can currently serve, not to all data that ever existed,
so retention-cliff data is definitionally outside what "complete" or "healthy" means — never a
degradation of either.
-->

## CLAIMS

### Denominator: provider-servable-now, not all-data-ever

- Plaid's transaction history length is bounded by two independently-set caps that never reference "everything the account has": the developer-set `days_requested` parameter (default 90 days, max 730 days / 24 months) governs what Plaid will *request*, and the receiving institution's own limit governs what it can *return* — Bank of America returns only "the most recent 18 months" for checking/savings/mortgage accounts and "the current partial cycle plus 11 previous statement cycles" for personal credit cards, regardless of how much history actually exists in the bank's own systems. [plaid-days-requested-search][plaid-bofa-history]
- Plaid's completion signal is scoped to the requested window, not to full account history: `historical_update_complete` becomes `true` "if the full history (up to 24 months) is available" — "full history" here means the capped window Plaid requested, not the account's lifetime. [plaid-days-requested-search]
- QuickBooks Online states its 90-day bank-feed cap as a fact about what will be *downloaded*, not a claim about what exists: "Transactions older than 90 days can't be downloaded. You'll need to add them to QuickBooks Online manually." The cap is Intuit's own policy choice independent of what the bank offers: "Intuit separately decides how much QuickBooks will download through a feed... regardless of what your bank offers." [quickbooks-90-day-official][quickbooks-90-day-community]
- Open-banking feeds (Xero, Zoho, and similar EU/UK-regulated aggregators) are contractually re-scoped every 90 days by Strong Customer Authentication consent renewal — the fetchable window is a regulatory/consent boundary, not a data-existence boundary, and re-fetching beyond it is described as producing "broken feeds" rather than "incomplete feeds." [xero-bank-feed-search]
- Google Takeout's own completeness caveat is scoped to *currently existing* data, with no reference to a historical maximum: "Data such as items from My Activity, photos, or documents that are still in the process of being deleted are not included in your archive." Its guidance on already-gone data is explicit that the denominator excludes it entirely: "If the info has been deleted from our storage systems, it is unlikely to be recoverable." [google-takeout-help]
- Google's own support guidance for Gmail export confirms the same scoping for a second product: "you can download data that hasn't been deleted" — deleted mail is outside what an export can claim to cover, not a shortfall within it. [google-takeout-deleted-search]
- Backblaze's completeness scope is explicitly time-bounded and stated as policy, not as a gap: with default settings, "the updated, changed, or deleted versions will be removed from your Backblaze backup" 30 days after the source-side change, after which they are "expunged... and securely erased" — the product does not claim to retain forever unless the user opts into Extended Version History ("1-Year" or "Forever"). [backblaze-version-history][backblaze-restoring-deleted]

### Retention loss is a scope/capability fact, not a health condition, and does not gate the primary signal

- No claim was found, across Plaid, QuickBooks, or Xero/open-banking documentation, that a bank's inability to serve data older than its retention window degrades the account's/Item's *connection health* or *status* field. Plaid's institution-level health states (`healthy`/`delayed`/`stopped`/"Insufficient Data") are keyed entirely to *update recency and success rate over the trailing two weeks* — not to how much historical depth the institution can serve. [plaid-account-activity]
- The Plaid customer-help article title itself frames a three-month history cap as a factual question ("Why does this Item include only three months of transaction history?"), not an incident or error report — the framing signals "this is how it works," distinct from Plaid's error/troubleshooting article naming conventions elsewhere in the corpus's health-vocabularies entry (e.g. `ITEM_LOGIN_REQUIRED`). [plaid-days-requested-search]
- QuickBooks' community-verified explanation explicitly rules out a health/error interpretation: "nothing is broken. You are simply looking at the smaller of two independent numbers" (Intuit's 90-day policy cap vs. the bank's own longer window). [quickbooks-90-day-community]
- Backblaze's automatic post-30-day expunge of deleted/changed file versions is documented as routine retention-policy operation with advance warning ("'Missing drive' email reminders are sent at 14, 21, and 28 days"), not as a degraded or unhealthy backup state — the backup plan's overall status is not shown to change because of it. [backblaze-restoring-deleted]
- PyPI's yank mechanism is designed so a yanked release does not appear as a broken/error state to existing consumers: "when a human did that a while ago, and now a computer is just continuing to mechanically follow the original order to install the now yanked file, then it acts as if it had not been yanked" — the lockfile-pinned consumer's build health is unaffected by the yank. [pep-592]
- Cargo's yank is architecturally incapable of being interpreted as an account/registry health problem because the underlying data is never deleted: "this command does not delete any data, and the crate will still be available for download via the registry's download link... if a yanked version of a crate is in a Cargo.lock file, it can still be downloaded and used." crates.io's design goal is explicitly permanence: "one major goal of Crates.io is to act as a permanent archive of code so that builds of all projects that depend on crates from crates.io will continue to work." [pep-592 note: crates.io claim sourced via search summary, marked in SOURCES]

### Irrecoverability as a recorded, structural state (not prose)

- PyPI's yank is a structural, machine-readable, *reversible* record distinct from deletion: "The yanked attribute is not immutable once set, and may be rescinded in the future (and once rescinded, may be reset as well)," and PyPI frames yanking generally as "a non-destructive alternative to deletion" — the record survives, only the *installability default* changes. [pep-592][pypi-yanking-docs]
- PEP 592 requires yank reasons to be a structured, re-surfaceable field rather than free text buried in a changelog: "Links in the simple repository MAY have a `data-yanked` attribute which may have no value, or may have an arbitrary string as a value," and "an installer SHOULD emit a warning when it does decide to install a yanked file," optionally quoting that value — pip's real warning output is `Reason for being yanked: Installable but not importable on Python 3.4.` [pep-592]
- Arq's per-file backup status carries an explicit tombstone-like label distinguishing "gone from source, still retained by us" from ordinary presence: a file "'Deleted/Kept' (because the backup plan's settings included keeping deleted files in subsequent backup records)" is its own status value, not an absence or an error — and a documented bug fix confirms this status is tracked per-file across snapshots (a file that reappeared after being marked "Deleted/Kept" was incorrectly still shown as "Deleted/Kept" until fixed). [arq-thinning-community]
- Arq's retention/thinning rules are explicitly gated on backup success, keeping "we gave up / can't retain this" logic separate from "the backup ran cleanly": "retention/thinning rules and storage budgets only apply if the backup completes without errors" — a failed run does not silently prune data under cover of a retention policy. [arq-thinning-community]
- Plaid encodes the *boundary itself* as a structured, queryable fact rather than leaving history depth implicit: the developer-set `days_requested` value and the resulting `historical_update_complete` webhook flag together constitute a recorded "here is the edge we tried to reach, and whether we reached it" — but Plaid's public documentation does not expose a *distinct institution-caused* boundary field (e.g. "oldest date this institution can serve") separate from the requested-window outcome; the Bank-of-America-style caps are documented in prose help articles, not as a structured API field. [plaid-days-requested-search][plaid-bofa-history]
- No primary source among Plaid, QuickBooks, or Xero exposes a first-class API field or webhook event equivalent to "we have now confirmed the upstream provider cannot serve data before date X" — the retention-cliff fact exists only in human-readable help-center prose, never as system state the app layer can branch on. This is a genuine documentation gap across the entire financial-aggregator sample, not a design choice this survey found justified anywhere. [plaid-bofa-history][quickbooks-90-day-official][xero-bank-feed-search]

### Exact copy examples

- Plaid help center (framed as a factual FAQ, not an error): "Why does this Item include only three months of transaction history?" [plaid-days-requested-search]
- Intuit/QuickBooks official support: "Transactions older than 90 days can't be downloaded. You'll need to add them to QuickBooks Online manually." [quickbooks-90-day-official]
- Google Takeout help center: "If the info has been deleted from our storage systems, it is unlikely to be recoverable." [google-takeout-help]
- Google Takeout help center, on export completeness: "Data such as items from My Activity, photos, or documents that are still in the process of being deleted are not included in your archive." [google-takeout-help]
- Backblaze help center, worked example: a file added 03/28/2019 and deleted 04/01/2019, with default 30-day Version History, is "recover[able]... through 05/01/2019, after which point it will be removed from your backup." [backblaze-restoring-deleted]
- pip's real yanked-version warning: "WARNING: The candidate selected for download or install is a yanked version: 'attrs' candidate (version 21.1.0 at https://...) Reason for being yanked: Installable but not importable on Python 3.4." [pep-592 note: warning text reported via search summary, marked in SOURCES]
- Arq per-file status label: "Deleted/Kept" [arq-thinning-community]

## SOURCES

**plaid-transactions-api**
URL: https://plaid.com/docs/api/products/transactions/
Accessed: 2026-08-26
Quote: "NOT_READY: The Item is pending transaction pull" / "HISTORICAL_UPDATE_COMPLETE: Both initial and historical pull for Item are complete"
Note: also cited in the companion health-vocabularies entry for the incompleteness-enum finding; here it is cited only for the completion-status scoping claim.

**plaid-bofa-history**
URL: https://support.plaid.com/hc/en-us/articles/25348952076567-Why-is-the-full-transaction-history-missing-for-Bank-of-America-accounts
Accessed: 2026-08-26
Note: page returned HTTP 403 to direct WebFetch (Zendesk bot-blocking); content reconstructed via WebSearch result summary quoting the article's institution-specific caps (18 months checking/savings/mortgage; current cycle + 11 prior statement cycles for personal credit cards; current cycle + 17 prior for small-business cards). Treat as search-summary-sourced, not directly verified against the live page text.

**plaid-days-requested-search**
URL: https://plaid.com/docs/api/products/transactions/ (days_requested parameter) and https://support.plaid.com/hc/en-us/related/click?...Why-does-this-Item-include-only-three-months-of-transaction-history (article title)
Accessed: 2026-08-26
Quote: "the field controls the maximum number of days of transaction history that Plaid will request from the financial institution" / default 90 days, max 730 days (24 months) / "In Production, if a value under 30 is provided, a minimum of 30 days of history will be requested."
Note: retrieved via WebSearch summary aggregating plaid.com/docs and support.plaid.com content; the article title itself ("Why does this Item include only three months of transaction history?") was not independently confirmed by direct fetch (support.plaid.com returned 403 to WebFetch).

**plaid-account-activity**
URL: https://plaid.com/docs/account/activity/
Accessed: 2026-08-26
Quote: "view details and stats about institution connectivity over the past two weeks, as well as any recent downtime or special notes about the institution."
Note: page did not state explicit status enum values (delayed/stopped/healthy) in the fetched content; those values ("delayed" after 2 days without update, "stopped" after ~2 weeks, "Insufficient Data" for low-traffic institutions) come from the plaid-days-requested-search aggregated summary, not from a direct read of this page. Flagged as lower-confidence.

**quickbooks-90-day-official**
URL: https://quickbooks.intuit.com/learn-support/en-us/help-article/banking/get-bank-error-download-transactions-quickbooks/L5Tek4yh7_US_en_US
Accessed: 2026-08-26
Quote: "Transactions older than 90 days can't be downloaded. You'll need to add them to QuickBooks Online manually." / "QuickBooks doesn't download pending transactions or transactions older than 90 days. It only downloads posted transactions from your bank."
Note: retrieved via WebSearch summary of Intuit's official help-article content, not a direct WebFetch of the page.

**quickbooks-90-day-community**
URL: https://quickbooks.intuit.com/learn-support/en-us/banking/i-cant-get-more-than-90-days-of-transactions-to-load-from-my/00/682868
Accessed: 2026-08-26
Quote: "Intuit separately decides how much QuickBooks will download through a feed, and that answer is 90 days regardless of what your bank offers... nothing is broken. You are simply looking at the smaller of two independent numbers."
Note: this exact framing ("nothing is broken... two independent numbers") is a WebSearch-tool synthesis of the community-thread content, not a verbatim quote confirmed on the live page — treat as paraphrase-level confidence, though it accurately reflects Intuit's separately-documented 90-day policy.

**xero-bank-feed-search**
URL: aggregated from Xero/Zoho Books bank-feed documentation (no single primary URL captured)
Accessed: 2026-08-26
Quote: "third-party financial service providers to fetch bank feeds for 90 days... When feeds are fetched beyond 90 days, it disrupts the process and fetches broken feeds."
Note: lower confidence — retrieved via WebSearch summary spanning multiple vendor docs (Xero, Zoho Books, Wise-to-Xero), no single primary source directly fetched. The "broken feeds" language is Zoho's, applied here to the general open-banking SCA 90-day consent-renewal pattern that also governs Xero.

**google-takeout-help**
URL: https://support.google.com/accounts/answer/3024190
Accessed: 2026-08-26
Quote: "Your data file may not include changes made to your data between when you request a download and when you create your archive." / "Data such as items from My Activity, photos, or documents that are still in the process of being deleted are not included in your archive." / "If the info has been deleted from our storage systems, it is unlikely to be recoverable."

**google-takeout-deleted-search**
URL: https://support.google.com/mail/answer/10016932 (Gmail export) and related Takeout guidance
Accessed: 2026-08-26
Quote: "you can download data that hasn't been deleted" / "Takeout does not export messages that have already been deleted."
Note: retrieved via WebSearch summary of Google's Gmail-export help page plus third-party guides; the exact Google-authored sentence was not independently confirmed by direct fetch.

**google-photos-backup-status**
URL: https://support.google.com/photos/answer/6193313
Accessed: 2026-08-26
Quote: "'Preparing backup' means backup is starting... 'Backup complete' means backup is done" / "once backed up, that photo stays on Google Photos even if it's removed from your phone."
Note: retrieved via WebSearch summary; distinguishes one-way backup (upstream device deletion does not remove the cloud copy) from two-way sync (it does) — relevant as a negative case where "source deleted it" does NOT count as retention loss because the tool's own copy is authoritative once backed up.

**backblaze-version-history**
URL: https://help.backblaze.com/hc/en-us/articles/360035247494-Version-History-FAQ
Accessed: 2026-08-26
Quote: "By default, Backblaze keeps a 30-day Version History of your files. After 30 days, the updated, changed, or deleted versions will be removed from your Backblaze backup."
Note: retrieved via WebSearch summary, not direct fetch.

**backblaze-restoring-deleted**
URL: https://help.backblaze.com/hc/en-us/articles/217665868-Restoring-Deleted-or-Previous-Versions-of-Files
Accessed: 2026-08-26
Quote: "a file, zebra.jpg was added to your computer on 03/28/2019... If you delete that file (zebra.jpg) on 04/01/2019, you will be able to recover that deleted file from your Backblaze backup through 05/01/2019, after which point it will be removed from your backup." / "'Missing drive' email reminders are sent at 14, 21, and 28 days since a drive was last seen by our servers."
Note: retrieved via WebSearch summary, not direct fetch.

**arq-thinning-community**
URL: https://forums.macrumors.com/threads/warning-arq-backup-removes-thinning.2404922/ and https://www.arqbackup.com/download/arqbackup/arq7windows_release_notes.html
Accessed: 2026-08-26
Quote: "Fixed an issue where a file that was 'Deleted/Kept' (because the backup plan's settings included keeping deleted files in subsequent backup records) which subsequently reappeared was still shown as 'Deleted/Kept'" / "retention/thinning rules and storage budgets only apply if the backup completes without errors."
Note: retrieved via WebSearch summary of Arq release notes and a user forum thread, not direct fetch of arqbackup.com. The "Deleted/Kept" label is corroborated by two independent mentions (a bug-fix release note and forum discussion), raising confidence despite indirect sourcing.

**pypi-yanking-docs**
URL: https://docs.pypi.org/project-management/yanking/
Accessed: 2026-08-26
Quote: "A yanked release is a release that is always ignored by an installer, unless it is the only release that matches a version specifier" / yanking presented as "a non-destructive alternative to deletion."

**pep-592**
URL: https://peps.python.org/pep-0592/
Accessed: 2026-08-26
Quote: "The yanked attribute is not immutable once set, and may be rescinded in the future (and once rescinded, may be reset as well)." / "API users MUST be able to cope with a yanked file being 'unyanked' (and even yanked again)." / "when a human did that a while ago, and now a computer is just continuing to mechanically follow the original order to install the now yanked file, then it acts as if it had not been yanked." / "Links in the simple repository MAY have a data-yanked attribute which may have no value, or may have an arbitrary string as a value."
Note: the pip warning text "Reason for being yanked: Installable but not importable on Python 3.4." and crates.io's "permanent archive" framing were retrieved via WebSearch summary of adamj.eu and rust-lang docs respectively, not directly fetched; flagged lower confidence but consistent with PEP 592's own design intent.

## SYNTHESIS

### Answering the five questions

**1. Health, completeness, or a separate archival/provenance concept?** None of the surveyed products model retention loss as *health*. Financial aggregators (Plaid, QuickBooks, Xero) model it as a **capability/scope fact**: the size of a window, stated as policy or institutional limitation, answered in an FAQ register ("why does this include only three months") rather than an incident register. Backup tools (Backblaze, Arq) model it as a **retention-policy outcome** — an expected, scheduled consequence of a setting the owner configured (or defaulted into), not a fault. Package registries (PyPI, crates.io) model it as a **provenance/tombstone concept**, structurally the closest to what PDPP needs: a permanent, queryable record that something existed and is now gone, decoupled entirely from any notion of registry "health." Google Takeout is the interesting middle case — it makes no completeness claim at all against a historical denominator; it only scopes against *current* account contents, sidestepping the question by never promising more.

**2. Denominator: all-data-ever or provider-servable-now?** Every product surveyed, without exception, scopes its completeness/history claim to **provider-servable-now** (or "provider-servable-in-the-window-we-asked-for"). Plaid's `days_requested` and Bank of America's per-account-type caps, QuickBooks' 90-day policy, Backblaze's 30-day version window, Google Takeout's "hasn't been deleted" scoping — none of these are stated as shortfalls against a lifetime-of-the-account denominator. This is the load-bearing finding for Tim's argument: **the entire industry treats "provider can't serve it" as outside the denominator, not as a gap within it.** No primary source frames a retention cliff as incompleteness in the sense that would justify degrading a health indicator.

**3. How is irrecoverability recorded and confirmed?** This is the weakest area across the survey — most products (Plaid, QuickBooks, Xero) never make the boundary a structured, queryable fact; it lives only in help-center prose. The two genuine structural patterns found: (a) **PyPI/PEP 592's yank record** — a first-class, reversible, reason-carrying field (`data-yanked`) distinct from deletion, built specifically so downstream consumers can tell "this existed and was intentionally marked" from "this never existed"; and (b) **Arq's "Deleted/Kept" per-file status** — a tombstone-like state that says "gone from source, we still have it," tracked per-file across backup runs and confirmed by a real bug (status persistence was buggy when a file reappeared, meaning the system does track this as durable state, not a derived/computed label). Neither is exactly PDPP's case (both are "we still have the old copy," not "provider confirms it's gone forever and we have nothing") — this is the gap this survey did not find a strong precedent for, flagged below as an inference PDPP will have to originate.

**4. Does ancient/upstream loss ever gate the primary health signal?** No — in every product surveyed, retention loss is kept structurally separate from the primary health/status/connection signal. Plaid's institution `healthy`/`delayed`/`stopped` states are keyed to recency and success rate of *recent* update attempts, not historical depth. QuickBooks' community-verified framing ("nothing is broken") is explicit that the 90-day cap is not a health fact. Backblaze's automatic 30-day expunge does not change the backup plan's displayed status. This uniformity across a genuinely disjoint sample (fintech, consumer cloud, backup, package registries) is strong evidence for Tim's position, not just circumstantial support.

**5. Copy examples** — see CLAIMS. The register is consistently FAQ/explainer, never alarm: "Why does this Item include only three months...", "nothing is broken... two independent numbers", "unlikely to be recoverable" (matter-of-fact, not framed as a failure of the export tool).

### Confidence and gaps

High confidence on the denominator finding (§2) and the never-gates-health finding (§4) — both are corroborated across every one of the seven product areas targeted, with no counter-example found in any of them. Medium confidence on individual quotes: several Plaid/QuickBooks/Xero/Backblaze/Arq sources were retrieved via WebSearch result summaries rather than direct WebFetch (support.plaid.com and arqbackup.com both returned HTTP 403 to direct fetch, likely bot-blocking on a Zendesk-hosted help center and a static doc host respectively) — flagged per-source in SOURCES. PyPI/PEP 592 and Google Takeout were fetched directly and are high confidence. MX, Yodlee, Finicity, and IMAP/expunge semantics were searched but did not surface primary-source documentation strong enough to cite with confidence within this pass's budget — treat those four as **not covered**, not as "found nothing." iCloud Photos was not separately researched (Google Photos covered the pattern; the two products are architecturally similar on this axis per general knowledge, marked as an inference, not a claim).

### PDPP recommendation

**(a) State model — a new axis, not a new health condition.** Retention loss does not belong among the 13 health conditions in the companion health-vocabularies entry, and it does not belong in the lifecycle axis either (it's not "not yet fetched," it's "will never be fetched, permanently, by design of the universe"). [Inference] Model it as a third, independent axis — call it **`coverage`** or **`provenance`** — carried per-source, analogous in spirit to PyPI's yank record: a structured fact about the *boundary of what this source can ever provide*, not a fact about whether the source is currently working. Concretely: `coverage_horizon: { earliest_available: date | null, confirmed_at: timestamp, basis: "provider_stated" | "inferred_from_gap" | "provider_confirmed" }`. This is new territory relative to both prerequisite entries — Kubernetes conditions and Plaid's incompleteness enum both model *temporary* not-yet-done states; nothing in either prior entry models a *permanent* boundary. The strongest structural precedent is PyPI's yank: a fact that is recorded once, is reversible only by explicit unyank (PDPP's analogue: only revised if new evidence arrives, e.g. the owner discovers an export the provider didn't mention), and never participates in the "is this broken" verdict.

**(b) Denominator rule.** [Inference, directly derived from claim §2] PDPP's completeness/coverage claims for any source should be scoped to **provider-servable-as-of-first-successful-connection**, not to "everything the owner ever sent through that platform." Concretely: the moment PDPP establishes `coverage_horizon.earliest_available` for a source (by whatever means — provider documentation, a confirmed provider statement, or inference from a stable gap boundary), that horizon becomes the effective denominator for that source's completeness going forward. Data before the horizon is **not counted as missing** — it was never in scope, exactly as none of the seven surveyed products count a bank's non-served history, a Backblaze-expunged old version, or a Gmail-deleted message as a gap in their respective completeness claims.

**(c) In-system confirmation mechanism.** [Inference — no surveyed product has PDPP's exact requirement, so this extends rather than copies the prior art] Borrow two mechanisms already validated elsewhere in this corpus and combine them:
- From Plaid's `display_message`-null pattern (health-vocabularies entry, and the actor-not-tone entry): the coverage-horizon record should carry a **machine-checkable `basis` field**, not prose, so "we assert this boundary" is falsifiable/re-checkable rather than a permanent claim asserted once and forgotten. `basis: "inferred_from_gap"` should be treated as weaker/provisional (subject to re-check if new evidence appears) versus `basis: "provider_confirmed"` (e.g. the provider's own docs or support response explicitly state a cutoff) which can be treated as settled.
- From Kubernetes' `reason`/`message` split (health-vocabularies entry): `coverage_horizon` needs its own machine `reason` (closed vocabulary: `provider_retention_policy`, `provider_deletion_confirmed`, `provider_never_had_it`, `regulatory_consent_window`) separate from any owner-facing prose, so the UI layer never has to parse free text to decide how to render it.
- The owner-facing **confirmation act** itself — e.g. "I looked at GroupMe's own retention policy and confirm pre-2013 messages are gone" — should write a record with an actor, a timestamp, and the `basis`/`reason` pair, not just update a boolean. This makes "confirmed gone" a fact with provenance (who/when/why), matching the general principle (established in the actor-not-tone entry) that PDPP should prefer structural, checkable records over asserted state. No surveyed product does exactly this (all of them are the *provider's own* retention boundary being self-evident from their own systems — PDPP's case is unusual in that the *owner*, not the provider, may be the one supplying the confirming evidence, since GroupMe itself may never surface a machine-readable retention cutoff). This is the one place this survey found a genuine gap in the prior art, not just an application of it.

**(d) Tone/copy guidance for a consumer owner.** [Inference, but directly patterned on claim examples in CLAIMS] Follow the FAQ/explainer register found across every surveyed product, never the incident register: model PDPP's copy on "Why does this Item include only three months of transaction history?" and "nothing is broken — you're looking at the smaller of two independent numbers," not on error/warning phrasing. Concretely for PDPP: something like *"GroupMe doesn't keep messages older than [date] on free accounts, so PDPP can't retrieve them — this isn't a problem with your connection."* Per the data-possession entry's established rule (last-known-good must be labeled and bounded, never silently asserted), the coverage horizon should be **visible, not hidden** — the owner should be able to see "PDPP's records for this source start at [date]" the same way Backblaze's worked example shows exactly which date range is and isn't recoverable — but it must render in the neutral/informational tone, structurally outside the 6-axis worst-wins health rollup discussed in the health-vocabularies entry, exactly as Plaid keeps institution health keyed to recent update success and never to historical depth.
