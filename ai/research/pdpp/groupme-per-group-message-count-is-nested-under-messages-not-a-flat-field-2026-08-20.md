---
title: "GroupMe's per-group message count is nested as messages.count on GET /groups, not the flat messages_count the PDPP connector read — which is why 156/156 live groups persisted a null count"
date: 2026-08-20
topic: pdpp
tags: [groupme, connectors, completeness-evidence, api-shape, provider-anchors]
status: verified
sources: [groupme-docs-groups, groupme-docs-chats, pdpp-live-postgres]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

## CLAIMS

- GroupMe's `GET /groups` returns per-group message metadata as a NESTED object
  `messages: { count, last_message_id, last_message_created_at, preview }`, not as a
  flat `messages_count` scalar. [groupme-docs-groups]
- GroupMe's `GET /chats` (direct chats) DOES return a flat `messages_count` scalar
  per chat — so the two endpoints genuinely differ in shape, and a connector cannot
  assume one shape covers both. [groupme-docs-chats]
- The PDPP GroupMe connector's `GroupMeGroup` interface modelled only the flat
  `messages_count`, and `toGroupRecord` read `g.messages_count ?? null`. Against live
  data this yielded `messages_count: null` for 156 of 156 groups, across every record
  version ever collected (0 non-null out of 156 versions). [pdpp-live-postgres]
- The sibling `members_count` field DID populate on the same live records (observed
  values 2–6), which rules out "the whole group payload is sparse" and isolates the
  failure to the message-count field specifically. [pdpp-live-postgres]
- The connector's committed test fixture `__fixtures__/group.json` asserts a flat
  `"messages_count": 142`. That value is synthetic and does not match the live API
  shape, so the fixture masked the defect rather than catching it. [pdpp-live-postgres]
- GroupMe's documentation does NOT state whether the `count` field in the
  `GET /groups/:id/messages` response envelope is the group's total message count or
  the current page's size. The published example (`"count": 123`) is ambiguous, and
  the connector's fixtures set it equal to the page length, so neither source settles
  it. [groupme-docs-groups]

## SOURCES

**groupme-docs-groups**
URL: https://dev.groupme.com/docs/v3
Accessed: 2026-08-20
Quote: "`\"messages\": { \"count\": 100, \"last_message_id\": \"1234567890\", \"last_message_created_at\": 1302623328, \"preview\": { ... } }`" — the GET /groups index response example. Separately, for GET /groups/:id/messages the example shows `"count": 123` with no accompanying definition of whether it is a group total or a page count.

**groupme-docs-chats**
URL: https://dev.groupme.com/docs/v3
Accessed: 2026-08-20
Quote: "`\"messages_count\": 10`" — appears as a flat field per chat object in the GET /chats response example.

**pdpp-live-postgres**
URL: local — docker exec pdpp-postgres-1 psql -U pdpp -d pdpp
Accessed: 2026-08-20
Quote: Scoped to `connector_instance_id='cin_5804a2ff36cd303e22762745'` (groupme): `SELECT count(*) FILTER (WHERE record_json->>'messages_count' IS NOT NULL) AS ever_nonnull, count(*) AS total_versions FROM records WHERE ... AND stream='groups'` returned `0|156`. A sampled record: `{"id": "1618492", ..., "member_count": 2, "messages_count": null}`.

## SYNTHESIS

This is a worked example of why a provider "anchor" must be validated against live
data before it is bound as completeness evidence, not merely against a committed
fixture. The fixture and the type definition agreed with each other and disagreed with
the provider; because nothing compared either to reality, a field that never once
populated in production looked like a usable denominator.

The near-miss is the interesting part. Binding the flat `messages_count` as a
completeness anchor would have produced a denominator of `null`-coerced-to-zero for
every group, which reads as "provider says this group is empty" — a fabricated
denominator asserting completeness for groups that were never fully walked. That is
the same defect class as an `item_count: 0` asserted for orders never fetched.

Two transferable rules:

1. **Check the anchor's live fill rate before binding it.** A one-line query
   (`count(*) FILTER (WHERE field IS NOT NULL)`) against production records would have
   caught this in seconds. A sibling field that DOES populate (here `members_count`) is
   the control that distinguishes "wrong path" from "sparse data".
2. **Distinguish absent from zero, always.** The fix returns `null` when neither shape
   yields a usable integer, and the caller reports those groups as explicitly
   *unanchored* rather than folding them into a proven-complete count. "The provider
   did not tell us" and "the provider says zero" must not share a representation.

The endpoint-shape inconsistency (`/groups` nests, `/chats` flattens) is worth
remembering for any future GroupMe work: it is a real asymmetry in the API, not a
documentation error.

The `GET /groups/:id/messages` envelope `count` remains unresolved and should NOT be
bound as an anchor until its semantics are confirmed against a real authenticated
response with a group known to have more messages than one page.
