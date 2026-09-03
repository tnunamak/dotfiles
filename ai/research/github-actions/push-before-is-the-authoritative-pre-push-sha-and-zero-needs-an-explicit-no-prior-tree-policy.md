---
title: "GitHub push payloads expose before as the authoritative pre-push SHA, while no-prior-tree values need an explicit workflow policy"
date: 2026-08-30
topic: github-actions
tags: [github-actions, push, webhook, sha, ci]
status: draft
sources: [github-webhook-push]
source_session: unknown
---

## CLAIMS

- GitHub documents a push event's required `before` field as the SHA of the most recent commit on the updated ref before the push. [github-webhook-push]
- GitHub documents `after` separately as the most recent commit on that ref after the push. [github-webhook-push]

## SOURCES

**github-webhook-push**
URL: https://docs.github.com/en/webhooks/webhook-events-and-payloads#push
Accessed: 2026-08-30
Quote: "The SHA of the most recent commit on `ref` before the push."

## SYNTHESIS

For a push-triggered content gate, compare the checked-out final tree against `before`,
not against every commit reachable from the new tip. The former evaluates the delivered
transition; the latter can count an intermediate edit whose final file content was
restored. A value that cannot name a prior tree must be handled explicitly: fail the
base-scoped command, or deliberately run the full check for a documented no-prior-tree
case. Do not silently skip either case.
