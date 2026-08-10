---
title: "Gmail's documented IMAP limits are an account-wide daily bandwidth cap (2500 MB/day download) and a 15-simultaneous-connection ceiling, not a per-connection throughput allowance — so opening multiple IMAP connections has no documented basis for restoring per-attachment speed, and may itself violate a hard cap"
date: 2026-08-09
topic: connectors
tags: [gmail, imap, throttling, concurrency, rate-limiting]
status: draft
sources: [google-workspace-bandwidth-limits, google-gmail-client-limit, chatwoot-issue-6082, mozilla-bugzilla-805830, imapflow-repo]
source_session: 1c7c83c3-64b7-4075-81a8-78d89280dfa5
---

## CLAIMS

- Google Workspace's official admin knowledge base publishes IMAP bandwidth limits as **2500 MB/day download, 500 MB/day upload**, described in account-level (not per-connection) terms [google-workspace-bandwidth-limits].
- Google's own guidance frames the limit as **cumulative across all IMAP clients on the account**: "Using multiple IMAP clients with the same account means every message is downloaded multiple times, which increases Gmail bandwidth use exponentially" — this is a warning against multi-client access precisely because usage aggregates account-wide, not per-connection [google-workspace-bandwidth-limits].
- Google's consumer Gmail help documents a **15-simultaneous-connection** ceiling ("You can add Gmail to up to 15 email clients at a time per account"), exceeding it produces a "Too many simultaneous connections" error [google-gmail-client-limit].
- A 2012 Mozilla/Thunderbird bug report documents a **harsher, older behavior**: exceeding 10 simultaneous IMAP connections triggered "account exceeded command or bandwidth limits," resulting in a full **24-hour lockout** from Gmail's IMAP servers, not mere throttling [mozilla-bugzilla-805830].
- A production incident (Chatwoot, a support-ticketing platform) documents the failure mode "Account has exceeded the Gmail bandwidth limit for downloads via IMAP," which disconnected the mailbox integration entirely rather than gracefully slowing it [chatwoot-issue-6082].
- No authoritative Google source found states a **per-connection** throughput allowance (e.g. "each IMAP connection gets N KB/s"). All found bandwidth language is at the account level.
- The imapflow client library's changelog references automatic retry of throttled FETCH commands, implying imapflow's authors have encountered server-side FETCH throttling as a known condition to handle, but no public imapflow issue was found that isolates or measures per-connection vs. per-account scope for that throttling.
- No definitive authoritative source (Google docs, imapflow issues, or other open-source Gmail sync tooling) was found that confirms opening N separate IMAP connections yields N× throughput for large attachment FETCH BODY downloads. This is an **open, unconfirmed question** — the account-wide framing of Google's own bandwidth-limit language is circumstantial evidence AGAINST the per-connection-allowance hypothesis, not proof either way.

## SOURCES

**google-workspace-bandwidth-limits**
URL: https://knowledge.workspace.google.com/admin/gmail/gmail-bandwidth-limits
Accessed: 2026-08-09
Quote: "Download with IMAP: 2500 MB" / "Upload with IMAP: 500 MB" per day; "Using multiple IMAP clients with the same account means every message is downloaded multiple times, which increases Gmail bandwidth use exponentially."

**google-gmail-client-limit**
URL: https://support.google.com/mail/answer/7126229
Accessed: 2026-08-09
Quote: "You can add Gmail to up to 15 email clients at a time per account."

**chatwoot-issue-6082**
URL: https://github.com/chatwoot/chatwoot/issues/6082
Accessed: 2026-08-09
Quote: "Account has exceeded the Gmail bandwidth limit for downloads via IMAP"

**mozilla-bugzilla-805830**
URL: https://bugzilla.mozilla.org/show_bug.cgi?id=805830
Accessed: 2026-08-09
Quote: "Gmail imap server returns 'account exceeded command or bandwidth limits' due to exceeding 10 simultaneus imap connections, user gets blocked from gmail imap servers for 24 hours"

**imapflow-repo**
URL: https://github.com/postalsys/imapflow
Accessed: 2026-08-09
Quote: changelog references automatic retry of throttled FETCH commands (no per-connection/per-account scope stated)

## SYNTHESIS

The evidence base does not answer "does connection N get its own throughput allowance" — nobody publishes that number, and the closest primary source (Google's own bandwidth-limits doc) talks exclusively in account-aggregate terms, which if anything argues against a naive N-connections=N× win. Two additional facts sharpen the risk: (1) the connection-count ceiling (15, or historically 10 before a lockout) is a hard cliff, not a graceful slowdown — real-world reports (Mozilla, Chatwoot) describe full mailbox disconnection or 24h IMAP lockout, not "a bit slower," when accounts trip these gates; (2) the SAME account may already have a live production connector run holding open connections, so any new pool must be counted against the *existing* usage, not treated as if starting from zero. A conservative multi-connection design — if attempted at all — should treat 2-3 additional connections as the experiment ceiling (well under 10), monitor first for any pressure signal (slow response, explicit throttle/backoff error) before assuming success, and be trivially reversible. Given the account-wide-not-per-connection evidence, the safer default recommendation is to NOT assume multi-connection fan-out will help, and to validate empirically (in a way that can be aborted instantly) before investing in the pattern.
