# Spec register calibration: PDPP core vs peer specifications

Date: 2026-08-04. Purpose: calibrate any editorial pass on spec-core.md against the
register of the specifications PDPP names as peers, so corrections move the document
toward legitimate spec conventions and never toward generic prose-style heuristics.
Sources: peer-convention extraction with verbatim quotes in
local/register-extraction-peers-2026-08-04.md (MCP 2025-06-18, x402, RFC 9396);
direct measurement of spec-core.md (14,747 words) this date.

## Scorecard: where spec-core already conforms

1. BCP 14 boilerplate verbatim in the Requirements Language section, matching RFC
   9396 and MCP. x402 is the outlier that lacks it.
2. Normative keyword density ~10 per 1,000 words (147 total), in the RFC/MCP band,
   carried in prose.
3. Zero first-person voice and zero contractions in the entire document. RFC 9396
   fences "we" out of normative text entirely; spec-core meets the strictest bar.
4. Structural header nouns throughout (Introduction, Terminology and Actors,
   Conformance, Security and Privacy Considerations, Scope and Boundaries). None of
   x402's branded or glossed headers ("Payment Schemes (The Logic)").
5. Explicit in-scope/out-of-scope lists in Section 11, the cleanest peer pattern
   (x402's paired lists).
6. Scope delegation to companions via "defined in [X]" pointers, the mechanism all
   three peers use. Boundary pointers are conforming register.
7. A TypeScript types section, mirroring MCP's own schema-in-TS practice.
8. Note blocks contain no RFC 2119 keywords (checked), avoiding MCP's own defect of
   normative language inside skippable Warning asides.

## Findings: deviations from peer register

F1. Inverse normative marking. Two headers carry "(normative)" tags while six
    scattered markers say "illustrative"/"informative". Peers default the whole
    document to normative and mark only the exceptions. Fix: one sentence in
    Requirements Language ("This document is normative except where marked
    otherwise"); drop the two "(normative)" header tags; keep and standardize the
    non-normative markers.

F2. Question-form prose in normative territory. The resource server enforcement
    checklist ("Checks: is the grant active?") and the three-concerns framing in
    System Architecture use interrogatives. Peer register is declarative ("The RS
    verifies that the grant is active"). Fix the checklist; the architecture
    questions are a judgment call (MCP tolerates rhetorical framing in overview
    prose) and need the owner's read.

F3. Phrasing normalization: "out of scope here" (4 occurrences) becomes "out of
    scope for this document", the RFC 6749/9396 form.

F4. Combined Security and Privacy Considerations. RFC 9396 alone among peers splits
    Privacy Considerations into its own top-level section. For a personal-data
    protocol this split is cheap, signals seriousness, and the subsections already
    exist (data minimization, purpose limitation, retention). Candidate for the
    pre-freeze editorial commit; owner decision because it renumbers Section 10.

F5. Discursive subsection headers ("How the protocol layers relate", "Split rule",
    "Three time-related concepts"). Peer register favors noun phrases. Low priority;
    acceptable under MCP's register, would be tightened under RFC register.

F6. Example segregation. Inline "Example:" labels are acceptable (MCP, x402) if
    consistent; RFC 9396's numbered appendix is the gold standard. Rule: keep inline
    but label consistently; no fix needed beyond consistency.

## Rule set for any editorial pass on spec files

R1. A sentence containing an RFC 2119 keyword is frozen: it may be relocated intact,
    and it may be edited only when a defect in the requirement itself is being fixed,
    reviewed as a normative change. Style passes never touch these sentences.
R2. Repetition of defined terms and parallel sentence frames is precision. Do not
    vary phrasing for variety. Anti-slop heuristics that reward varied wording are
    inverted for spec files.
R3. First person, contractions, em-dashes, marketing adjectives, and glossed or
    branded headers are defects everywhere in spec files.
R4. Non-normative asides use one convention consistently and never contain RFC 2119
    keywords.
R5. Scope delegation pointers ("out of scope for this document; see [X]") are
    conforming register, not clutter. Do not remove them; normalize their phrasing.
R6. Declarative mood in all normative and procedural text; interrogatives only in
    overview prose, sparingly.
R7. Calibration target is the peer set (MCP, x402 spec doc, RFC 9396, SMART), never
    general prose guidance. When peers disagree, RFC register wins for normative
    sections and MCP register wins for overview sections.

## Disposition

Mechanical now (agent-executable, fold into the pre-freeze editorial commit): F1,
F2-checklist, F3, F6. Owner decisions: F2-architecture framing, F4 privacy split,
F5 header tightening. Slop-gate spec profile = R1 through R6, advisory mode first.

Thursday relevance: the scorecard section doubles as the answer to "does this read
like a legitimate spec": eight conformance points against the named peer class, with
the deviations known, triaged, and scheduled.
