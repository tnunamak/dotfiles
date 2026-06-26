# Research corpus index

One line per entry, **newest first**. Agents read this first to decide what to open
(see `README.md` for the convention; the standing "check here before web-researching"
rule is in `ai/AGENTS.md`). Add a line here whenever you create an entry.

## agentic-context-design
- [Agents retrieve knowledge via always-on instruction, not model judgment](agentic-context-design/agents-retrieve-knowledge-via-always-on-instruction-not-model-judgment.md) — 2026-06-25 — why a "check the corpus first" standing instruction is the only reliable defense against write-only rot; reliability ranking across 8 tools.
- [Grep beats embeddings for small structured corpora](agentic-context-design/grep-beats-embeddings-for-small-structured-corpora.md) — 2026-06-25 — empirical (SWE-Bench, Aider, Cody) basis for no-embeddings/no-vector-DB; when embeddings start to pay off.
- [Claude Code conditional context-injection + hook mechanics](agentic-context-design/claude-code-conditional-context-injection-hook-mechanics.md) — 2026-06-25 — hook events that can inject context, exact UserPromptSubmit schema, skills-vs-hooks, prompt-caching cost reality.
- [Claude PostToolUse wire schema for Bash (empirical)](agentic-context-design/claude-posttooluse-hook-wire-schema-bash.md) — 2026-06-25 — real fields (tool_response.stdout/stderr, NO exit_code); failure must be inferred from stderr; global hooks fire across all agents; .d.ts schema was wrong.

## feedback-systems
- [Event-gated feedback beats cadence for tool dogfooding](feedback-systems/event-gated-feedback-beats-cadence-for-tool-dogfooding.md) — 2026-06-25 — ESM + telemetry + UX consensus: trigger on friction/notable-success, rate-cap, thin staleness floor; generalizes across the tool roster.
- [Build simpler v1 feedback detector, not the generalized system](feedback-systems/dogfooding-feedback-build-simpler-v1-not-generalized-system.md) — 2026-06-25 — independent gpt-5.5 review + rebuttal: narrow the mechanism (roster.yaml, Claude-only candidate-detector, no Stop nudge, redaction/flock/kill-switch); 2-week trial decides sufficiency. The build spec.
- [feedback-block presence > owner/intent labels](feedback-systems/feedback-block-presence-encodes-report-vs-keep-drop-no-owner-intent-labels.md) — 2026-06-25 — Hickey review: report-vs-keep/drop collapses to "is there a feedback block"; cut owner/intent/stubs; nudge is destination-aware not intent-aware; fixed block-unbounded ledger lookup.

## knowledge-management
- [Separate facts from interpretation via sections, not files](knowledge-management/separate-facts-from-interpretation-via-sections-not-files.md) — 2026-06-25 — claim/evidence separation (Toulmin, nanopublications, zettelkasten); the design basis for this corpus's own format.
