---
title: "Separate verifiable facts from interpretation via clearly-delineated sections in one file, not separate files"
date: 2026-06-25
topic: knowledge-management
tags: [zettelkasten, claim-evidence, provenance, frontmatter, corpus-design]
status: settled
sources: [zettelkasten-lit-notes, nanopublications, toulmin, matuschak-evergreen, force11, hugo-frontmatter]
source_session: 019f005e-b205-77b3-9faa-01fe0eac7ed7
---

## CLAIMS

- The zettelkasten tradition separates literature notes (what a source says, with reference attached) from permanent notes (your own synthesis); Luhmann kept them in physically separate boxes, but the zettelkasten.de maintainers themselves do not enforce the separation, treating it as a maturity distinction rather than a location one. [zettelkasten-lit-notes]
- Nanopublications model a claim as three separate named graphs — assertion, provenance, publication-info — so the pure assertion is independently addressable from its provenance; this is the machine version of separating "what the source says" from "what I conclude." [nanopublications]
- The Toulmin argument model structurally separates grounds (verifiable evidence/data) from claim (the conclusion inferred from them). [toulmin]
- Matuschak's evergreen-note principle: titles should be full declarative sentences (falsifiable claims), not topic labels, which makes each note independently retrievable. [matuschak-evergreen]
- A verifiable stored fact needs minimal provenance — URL + access date + optional verbatim quote — to remain re-checkable after the source changes; FORCE11 Principle 7 requires "provenance and fixity sufficient to verify." [force11]
- Static-site frontmatter consensus: the fields that actually drive retrieval are title, date, and tags; everything else is optional. [hugo-frontmatter]
- For an agent-written corpus, sections within one file (CLAIMS / SOURCES / SYNTHESIS) achieve the same fact-extractability as separate files without the per-entry coordination cost, and the separation benefit of separate files only materializes at hundreds of densely-linked notes. [zettelkasten-lit-notes]

## SOURCES

**zettelkasten-lit-notes**
URL: https://zettelkasten.de/posts/literature-notes-vs-permanent-notes/
Accessed: 2026-06-25
Quote: The maintainers do not themselves separate literature notes from permanent notes; the distinction is maturity, not location. "Permanent just means permanently useful, not unchanging/fully formed."

**nanopublications**
URL: https://en.wikipedia.org/wiki/Nanopublication
Accessed: 2026-06-25
Quote: A nanopublication is three named graphs — assertion, provenance, and publication-info — designed so provenance/publication-info are consumed independently of the assertion.

**toulmin**
URL: https://en.wikipedia.org/wiki/Stephen_Toulmin#Toulmin_model_of_argument
Accessed: 2026-06-25
Quote: The model separates claim (conclusion) from grounds (the verifiable data supporting it).

**matuschak-evergreen**
URL: https://notes.andymatuschak.org/Evergreen_notes
Accessed: 2026-06-25
Quote: Notes should be atomic and concept-oriented with titles as declarative assertions, not topic labels.

**force11**
URL: https://www.force11.org/group/joint-declaration-data-citation-principles-final
Accessed: 2026-06-25
Quote: Principle 7 (Specificity and Verifiability): citations should include "provenance and fixity sufficient to verify that the specific version retrieved subsequently is the same as was originally cited."

**hugo-frontmatter**
URL: https://gohugo.io/content-management/front-matter/
Accessed: 2026-06-25
Quote: date + tags drive taxonomy/list pages; other fields are optional custom params.

## SYNTHESIS

This entry is the design basis for this corpus's own format (see README.md). Chosen: three
sections in one file (CLAIMS = fact layer with [slug] tags; SOURCES = URL+date+quote provenance;
SYNTHESIS = skippable interpretation), filename = claim-as-kebab-case, 6-field frontmatter.
Rejected as over-engineering for this scale: separate literature/permanent files, generated
index, confidence scores beyond a 3-value status, per-source files, wikilink graph. The
literature/permanent split is honored within the file via headers rather than across files,
which keeps agent write-friction at one document per finding while preserving the ability to
read only CLAIMS+SOURCES.
