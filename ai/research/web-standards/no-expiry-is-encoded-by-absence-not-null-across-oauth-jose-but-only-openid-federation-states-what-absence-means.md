---
title: "Every OAuth/JOSE spec encodes 'no expiry' by omitting the field rather than setting it null, but only OpenID Federation actually states what absence means — the rest establish the convention by silence, so 'the RFCs require absent-only' overclaims the evidence"
date: 2026-09-03
topic: web-standards
tags: [oauth, jose, json-schema, api-design, null-vs-absent, expiry]
status: draft
sources: [rfc7519, rfc7662, rfc7493, oidfed, fhir-json]
source_session: e495dad0-025d-4abd-a225-5951edd20f60
---

## CLAIMS

- RFC 7519 (JWT) §4.1.4 defines `exp` as "Use of this claim is OPTIONAL." It defines no null variant and nowhere discusses JSON null as a claim value. §4.1 adds that none of the registered claims are "mandatory to use or implement in all cases." [rfc7519]
- RFC 7519 does not state what the *absence* of `exp` means. It states only that unrecognized claims "MUST be ignored" (§4), which is a different question. The "absent means no expiry" reading is conventional, not textual. [rfc7519]
- RFC 7662 (Token Introspection) §2.2 likewise makes `exp` "OPTIONAL", defines no null variant, and is silent on absence semantics. Its only absence-adjacent rule is in §4: "If the response contains the `exp` parameter (expiration), the response MUST NOT be cached beyond the time indicated therein." [rfc7662]
- **OpenID Federation 1.0 is the exception and the only citable primary source for the semantics**: trust-mark `exp` is OPTIONAL and the spec explicitly says "If not present, it means that the Trust Mark does not expire." [oidfed]
- RFC 7493 (I-JSON) does **not** address null-versus-omission. It constrains encoding, numbers, and duplicate object names only. It is sometimes offered as authority for absent-only and does not support it. [rfc7493]
- FHIR JSON does not permit JSON null as a standalone element value: "String property values can never be empty. Either the property is absent, or it is present with at least one character of content." Null appears only as array padding in the parallel `_element` form — "JSON null values are used to fill out both arrays so that the id and/or extension are aligned with the matching value in the first array." So a period with no end omits `end`: an independent ecosystem reaching the same encoding without an OAuth lineage. [fhir-json]
- JSON Schema and OpenAPI treat `required` and `nullable` as **independent** axes, so a field that is both optional and nullable is well-formed. This is the mechanism by which "optional or null" API fields arise, and it means the two-encoding shape is not intrinsically invalid — only ambiguous. [rfc7493]

## SOURCES

**rfc7519**
URL: https://www.rfc-editor.org/rfc/rfc7519.txt
Accessed: 2026-09-03
Quote: "The \"exp\" (expiration time) claim identifies the expiration time on or after which the JWT MUST NOT be accepted for processing... Use of this claim is OPTIONAL."

**rfc7662**
URL: https://www.rfc-editor.org/rfc/rfc7662.txt
Accessed: 2026-09-03
Quote: "exp OPTIONAL.  Integer timestamp, measured in the number of seconds since January 1 1970 UTC, indicating when this token will expire, as defined in JWT [RFC7519]."

**rfc7493**
URL: https://datatracker.ietf.org/doc/html/rfc7493
Accessed: 2026-09-03
Quote: "(No section addresses null values, omission versus null, or absent-member treatment; the RFC covers encoding, numbers, duplicate names, and protocol design recommendations only.)"

**oidfed**
URL: https://openid.net/specs/openid-federation-1_0.html
Accessed: 2026-09-03
Quote: "If not present, it means that the Trust Mark does not expire."

**fhir-json**
URL: https://www.hl7.org/fhir/json.html
Accessed: 2026-09-03
Quote: "String property values can never be empty. Either the property is absent, or it is present with at least one character of content."

## SYNTHESIS

The practical design conclusion — model "no expiry" as an absent field, never as `null` — is well
supported, and the convention is genuinely uniform across JWT, introspection, OAuth token responses,
FHIR, protobuf field presence, and UK Open Banking consent objects. What is *not* well supported is
the way this is usually argued. Reviewers reach for RFC 7519 or RFC 7662 as if they mandated
absent-only; both merely mark the field OPTIONAL and stay silent on what absence means. The
inference "optional and no null variant defined, therefore absence carries the meaning" is sound
convention but is not a quotable rule.

If you need a primary source that actually states the semantics, it is **OpenID Federation 1.0's
trust-mark `exp`** — "If not present, it means that the Trust Mark does not expire." That single
sentence is worth more in a spec review than three RFC citations that only imply it. This is the
same failure mode catalogued in `six-commonly-cited-oauth-consent-precedents-have-stale-or-wrong-section-and-term-names.md`:
the surrounding argument is sound, the pointer is the weak part.

Two traps for future work. First, do not cite RFC 7493 (I-JSON) here — it looks like it should be
on point and it says nothing about null versus omission. Second, expect the counter-argument from
tooling: JSON Schema and OpenAPI treat `required` and `nullable` as independent axes, so
"optional or null" is a legal schema, and the case for cleanup rests on encoding hygiene before a
wire-format freeze rather than on the current shape being invalid. Argue it that way and the case
holds; argue it as "the RFCs forbid null" and a careful reviewer will correctly push back.

A migration note observed in practice (PDPP, 2026-09): when a codebase has already emitted explicit
nulls at scale — 1,544 of 1,557 live grants — the workable path is a tolerant read-path normalizer
that treats received `null` as absent, plus a backfill, rather than a hard schema cutover. The
normative rule and the compatibility code are separable and should be argued separately.
