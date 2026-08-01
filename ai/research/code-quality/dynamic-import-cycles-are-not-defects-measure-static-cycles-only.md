---
title: "A dependency cycle broken by a dynamic import() is not a defect; cycle gates must count static (load-time) cycles only"
date: 2026-06-27
topic: code-quality
tags: [cycles, dependency-cruiser, esm, refactoring-loop, false-positive, verify-before-fixing]
status: draft
sources: [dependency-cruiser-docs, pdpp-auth-search]
source_session: 019f1569-f5c4-70c3-904c-dc2c49e80ec9
---

## CLAIMS

- An ES-module import cycle causes a load-time hazard only when every edge in the cycle is a STATIC (top-level) import; if any edge is a dynamic `import()` evaluated inside a function body, the modules finish initializing before the lazy edge is followed, so there is no initialization-order defect. [dependency-cruiser-docs]
- The idiomatic ESM fix for a necessary cyclic dependency is to make ONE direction lazy (dynamic `import()` inside the function that needs it) while the other stays static — this is a deliberate pattern, not a smell. [pdpp-auth-search]
- dependency-cruiser with `tsPreCompilationDeps:false` still reports dynamic-import edges as runtime cycles, so a naive `to:{circular:true}` rule FLAGS already-mitigated lazy cycles as violations. The correct rule excludes dynamic edges: `to:{ circular:true, viaOnly:{ dependencyTypesNot:["dynamic-import"] } }`. [dependency-cruiser-docs]
- In PDPP reference-implementation (sweep HEAD 90b040195), the two reported runtime cycles (`auth.js <-> search.js`, `auth.js <-> search-semantic.js`) are both broken by a documented lazy import on auth's side (`// Lazy import keeps the records <-> search <-> auth cycle clean`); search imports `getConnectorManifest` statically, auth `await import('./search.js')`s back. With the dynamic-aware rule the count of TRUE static cycles is 0 of 220 modules. [pdpp-auth-search]

## SOURCES

**dependency-cruiser-docs**
URL: https://github.com/sverweij/dependency-cruiser/blob/main/doc/rules-reference.md
Accessed: 2026-06-27
Quote: "dependencyTypes / viaOnly let a circular rule ignore cycles that are only closed through a dynamic import"

**pdpp-auth-search**
URL: (local) reference-implementation/server/auth.js:2972-2980, search.js:36, search-semantic.js:47
Accessed: 2026-06-27
Quote: "// Lazy import keeps the records ↔ search ↔ auth cycle clean.  const { lexicalIndexBackfillForManifest } = await import('./search.js');"

## SYNTHESIS

This corrects a premise embedded across the SLVP-Q planning docs: the scorecard's "6 import cycles"
(and the cycle term in the SLVP-Q index) was measured type-INCLUSIVE and dynamic-BLIND. The honest
runtime count is 2, and both are already-mitigated lazy cycles — TRUE static cycles = 0. So
"break the server cycles" was NOT a real swing; pursuing it (extracting `getConnectorManifest` out
of the 6630-line auth.js) would have been risky churn — `invalidConnectorManifest` is referenced 94×
in auth.js — to fix a non-defect.

Process lesson (reinforces [[ai-generated-code-smells-and-when-agents-act-contrary-to-refactoring-goals]]):
a mechanical metric (cycle count) is only as good as its measurement semantics. The two-model design
gate's value here was upstream of the gate — VERIFYING the premise (is this cycle a real load-time
hazard?) before designing the extraction. The fix is to the RULE, not the code: adopt the
dynamic-aware no-circular rule as the ratchet so the architecture gate measures real defects, and so
a future agent doesn't "rediscover" these phantom cycles and churn the god-file. See the gated-loop
design in [[refactoring-loop-as-skill-plus-workflow-composition]].
