---
title: "W3C Technical Reports and IETF RFCs both pin document identity to a fixed publication date embedded in the doc, and W3C separates 'this version' (immutable) from 'latest version' (a redirect) rather than showing a single mutable date"
date: 2026-08-05
topic: spec-versioning
tags: [standards-process, w3c, rfc, versioning, changelog]
status: draft
sources: [w3c-pubrules, w3c-tr-uris]
source_session: 6813bbc1-0821-4f0e-bbb8-a0c731f9fac6
---

## CLAIMS

- Every W3C Technical Report exposes two distinct URIs on its title page: a "this version" URI (immutable, the exact document as published on its title-page date) and a "latest published version" URI (a stable redirect to whatever is newest in that document series). [w3c-tr-uris]
- W3C's publication checklist enforces date integrity mechanically at publish time: the title-page date must not be in the future, and a request to publish with a too-far-past date is aborted — i.e., the date is a build-time assertion, not free text an editor types. [w3c-pubrules]
- W3C's rule is explicit that the editor must not change the document after its title-page date — the date freezes the document; any further edit requires a new date and (per the versioned-URI scheme) a new "this version" URI. [w3c-pubrules]
- The URI format itself encodes the date: `https://www.w3.org/TR/YYYY/status-shortname-YYYYMMDD` — the date is structurally part of the document's identity, not a separately-editable field that can drift from reality. [w3c-tr-uris]
- Older W3C templates (circa 1999-2001) used simpler labels — "This version" / "Latest version" / "Previous version" — before the terminology shifted to "This version" / "Latest published version" / "Previous version"; the This/Latest split itself predates and outlives the label wording. [w3c-tr-uris]

## SOURCES

**w3c-pubrules**
URL: https://www.w3.org/Guide/pubrules-20030630.html
Accessed: 2026-08-05
Quote: "the date for the title page must not be in the future; if it is, the document isn't published yet, and if it's too far in the past, the request is aborted... The editor must not change the document after the title page date."

**w3c-tr-uris**
URL: https://www.w3.org/Consortium/Process/Process-19991111/tr.html
Accessed: 2026-08-05
Quote: "a 'this version' URI, which identifies the specific document, and a 'latest published version' URI, which identifies the most recently published draft in a document series"

## SYNTHESIS

The relevant transferable idea for any spec/protocol site (not just W3C's own
tooling) is structural, not cosmetic: **a document's date should be an
assertion the publishing mechanism enforces, not a field a human types once
and never revisits.** W3C gets this by making the date part of the URI itself
(so a stale date would literally be a broken/nonexistent link) and by
freezing the document at that date (no further silent edits). RFCs follow a
parallel discipline: an RFC is immutable once published; any change is a new
RFC number entirely, superseding rather than editing in place.

Applied to a repo-hosted spec (e.g. PDPP's `spec-core.md`, a single hand-typed
`Date:` header line with no such enforcement): the header date is exactly the
failure mode both standards bodies engineer against — a field that can be
edited independently of a fresh publish action, and one that has no
mechanical check against the thing it claims to describe (when the content
actually last changed). The cheapest available real-world proxy for "when
was this content last actually changed" in a git-hosted spec is the file's
git history — not a perfect substitute for a real publish-freeze workflow,
but a fully mechanical, zero-new-dependency check: does the header's claimed
date fall on or after the file's actual last-modified commit? If the header
date is *older* than the git history says the content is, the document is
making a promise ("current context established as of April 2026") the repo's
own history disproves.

The "This version" vs "Latest published version" split also answers a
distinct question worth carrying over: should a site show one date, or two?
W3C's answer is effectively "show both, but keep them semantically distinct" —
one is "when was the section of text you're reading pinned" (This version),
the other is "where do I go for the current one" (Latest). A minimal site
that only has one live document per spec doesn't need two URIs, but it can
still adopt the same distinction in miniature: "vX.Y.Z, published <header
date>" (this version — an immutable historical fact about a milestone) plus,
where the underlying source has moved since, "content updated <git date>"
(an honest signal that the document's *content* — not its version number —
continued changing after that milestone was declared). Collapsing those two
into a single date field is exactly the trap that produced the observed bug:
a value gets reused across meanings it wasn't scoped for.
