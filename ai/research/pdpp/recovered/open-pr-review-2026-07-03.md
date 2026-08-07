# Open PR Critical Review — PDPP (2026-07-03)

Reviewer: autonomous principal-engineer review pass (Tim Nunamaker delegate).
Scope: every open PR on `github.com` PDPP repo at review time.
Method: full-diff read of implementation code (not just design docs), CI status,
merge/rebase state against current `origin/main`, and targeted correctness
tracing of the load-bearing logic in each PR. No PR branch was modified or
pushed; recommended revisions are described precisely for the PR authors.

## Summary table

| PR  | Title                                                       | Verdict     | Headline issue |
|-----|-------------------------------------------------------------|-------------|----------------|
| #11 | OSS connector adapter kit + HPI connector                   | **ready\*** | Clean, well-tested; merges without conflict. Only nits. |
| #10 | Promote connector config/credentials schema                 | **needs-work** | Sound design + code, but **3 merge conflicts** vs current main (benign, additive drift). Rebase required before merge. |
| #7  | Agent-authored connectors (`@pdpp/connector-synthesis`)     | **needs-work** | Impressive, well-guarded package. One **real runtime bug**: the generated *export* collector emits `key: String(data.id)` with no missing-id guard (asymmetric with the HPI connector and with its own record-validator). Plus packaging/`bin` nits. |

`ready*` = code is merge-quality; final call is gated on the explicit owner
review these PRs request (all three are self-labeled "owner-review-gated").

Shared context worth stating up front:

- **CI is thin.** The only required check on all three PRs is a Vercel deploy
  (passing). None of these PRs' unit tests run as a merge gate today. PR #7 adds
  its own path-scoped `connector-synthesis.yml` workflow (good), but PR #10 and
  #11's tests still depend on a human running them. Validation claims in the PR
  bodies were therefore **not independently re-run** in this pass (task asked to
  keep CPU light); I reviewed the tests as source instead and they look
  substantive. Recommend a human run the documented test commands before merge.
- **Branch age.** All three branch off a base that is now ~950–1100 main commits
  behind. #11 and #7 are isolated enough to still apply cleanly; #10 touches
  three hot files that main has since edited (see its section).
- All three are the "replacement for the accidentally-merged-then-reverted #6/#8"
  lineage and #7 depends on #10's direction. There is a real ordering
  dependency: **#10 should land before #7** (the synthesized export collector and
  the RI validate path both consume `START.connector_options`, which #10
  formalizes).

---

## PR #11 — OSS connector adapter kit + HPI connector

**Verdict: ready\*** (merges cleanly; owner-review-gated by author's own request).

### What it does
Generalizes the hand-rolled `slackdump` subprocess wrap into a reusable
`external-tool-adapter.ts` (binary resolution → arms-length spawn → typed
missing-binary / timeout / exit / overflow errors → JSON/JSONL readback), then
proves it with a real `hpi` connector (`connectors/hpi/*`) and wires `hpi` into
the orchestrator + the external-tool honesty gate.

### Merge state
`git merge-tree origin/main origin/feat/oss-adapter-kit-review` → **no
conflicts.** All new files plus two one-line additions (`orchestrator.ts`
KNOWN_CONNECTORS `hpi: c("hpi")`, and the honesty-test declaration). Low
integration risk despite the 956-commit gap.

### Strengths (this is genuinely good code)
- **Resource safety is first-class, not bolted on.** `runExternalTool`
  (`packages/polyfill-connectors/src/external-tool-adapter.ts`) spawns
  `detached: true` so `killTree` can signal the whole process group
  (`process.kill(-pid, …)`), escalates SIGTERM→SIGKILL after a grace window,
  `unref()`s the escalation timer, clears it on natural exit to avoid signalling
  a recycled PID, and hard-bounds combined stdout+stderr at 256 MiB to prevent
  OOM before a (possibly 1h) timeout fires. This is the level of care the Slack
  wrap should have had.
- **Honest error model in `parseToolRecords`.** The array branch throws a typed
  `ExternalToolOutputParseError` on a corrupt document rather than silently
  returning `[]` (which would masquerade as "ran fine, zero records"); the JSONL
  branch skips interleaved non-JSON log lines. The asymmetry is deliberate and
  documented.
- **Per-stream skip isolation** in `connectors/hpi/index.ts`: a missing/unconfigured
  HPI module `SKIP_RESULT`s that one stream, never aborts the whole run.
- **Missing-id is a skip, not a malformed RECORD** (`collectStream`), and a test
  (`validateRecord: rejects a record with no id`) pins it. Contrast PR #7 below.
- Lenient `z.looseObject` schemas correctly forward upstream-shaped fields.

### Findings (all minor)

1. **`advanceCursor` lexical string comparison** —
   `packages/polyfill-connectors/connectors/hpi/index.ts` (`advanceCursor`).
   Cursor advancement uses `candidate > current` on raw strings. This is correct
   **only** for ISO-8601 UTC (`…Z`) timestamps that sort lexically. HPI's
   `--order-type datetime` normalizes order upstream, so in practice the largest
   record is emitted last and this holds — but the function is generic and a
   future mapping with local-offset timestamps (`2026-05-01T00:00:00+02:00`) or
   numeric-but-string cursors ("10" < "9") would advance the cursor wrong.
   *Suggested revision:* add a one-line doc-comment stating the invariant
   ("assumes lexically-sortable cursor values; HPI `--order-type datetime`
   guarantees this for the default mappings"), or key the compare off
   `mapping.orderType`. Low priority — not a bug for the shipped mappings.

2. **`resolveMappings()` reads `readOptions(null, …)`** — same file. It passes
   `null` as the START message (the code's own `TODO(PR #10)` acknowledges this),
   so only the `HPI_STREAMS` env override works today; `START.connector_options.STREAMS`
   is inert until #10 lands. This is honest (commented) but means the
   connector's headline "overridable streams" affordance is env-only for now.
   Fine to merge; just don't advertise the START path as working yet.

3. **Malformed `HPI_STREAMS` override silently falls back to defaults.** The
   `try/JSON.parse … catch → DEFAULT_MAPPINGS` swallows a user typo. A stderr
   warning (mirroring #10's "unknown option" warning philosophy) would keep a
   misconfigured override from being silently inert. Optional.

### Recommendation
Approve on code merit; let the owner-review gate the actual merge. No code change
required to be correct. The two doc-comment nits above are worth a follow-up
commit but are not blockers.

---

## PR #10 — Promote connector config/credentials schema

**Verdict: needs-work** (design + code are sound; blocked on a rebase).

### What it does
Adds an optional `connector_options` field to the canonical `StartMessage`,
plus a dependency-free `validateConnectorOptions` shape-validator, and wires
pre-spawn validation into three runtime entry points: the collector runner
(`collector-runner.ts`), the RI controller (`runtime/controller.ts`), and the RI
`runConnector` (`runtime/index.js`). It also strips any `credentials_schema`
field name out of the options snapshot written to `spine_events`
(defense-in-depth against secret leakage into the audit spine).

### Merge state — **the blocking issue**
`git merge-tree origin/main origin/feat/connector-config-schema` → **3 content
conflicts:**
- `packages/polyfill-connectors/src/collector-runner.ts`
- `reference-implementation/runtime/controller.ts`
- `reference-implementation/runtime/index.js`

I inspected the hunks. They are **benign additive drift**: main independently
added a `resources` field to `CollectorConnectorSpec` and a `resources` argument
to `buildCollectorStartMessage` in the *same regions* PR #10 adds
`connector_options`. The conflict is adjacency, not semantics — the resolution is
"keep both fields." `runtime/index.js` still exists on main (it was **not**
migrated to `.ts`), so #10's `.js` edits still have a home. No feature overlap:
main has no `validateConnectorOptions` and no `options_schema` plumbing yet.

*Required revision:* rebase the branch onto current main and resolve the three
conflicts by taking both sides (order the new `readonly connector_options?` /
`resources?` fields together in the interface; pass both `priorState`/`resources`
and `connectorOptions` through `buildCollectorStartMessage`). Re-run the
documented typecheck + tests afterward.

### Strengths
- **The leakage boundary is enforced twice.** Build-time honesty test asserts
  no `options_schema`↔`credentials_schema` name overlap; `runtime/index.js` also
  filters credential-named keys out of `safeOptionsForSpine` at runtime as
  defense-in-depth. The comment correctly calls the runtime filter "normally a
  no-op." Good belt-and-suspenders on a real secret-exposure risk.
- **Fails fast, before resources.** `assertConnectorOptionsOrThrow` runs before
  the outbox/heartbeat are acquired.
- **Forward-compat handling is deliberate and consistent** across all three
  call sites: unknown keys PASS but are surfaced (stderr in the runner, `log.warn`
  in the controller, an `onProgress` `connector_options_warning` event in
  `runConnector`) so a typo'd knob isn't silently inert. This matches the
  documented "Airbyte `additionalProperties:true` + K8s `Warn`" majority choice.

### Findings

1. **`validateConnectorOptions` does not enforce `required`, `enum`, or numeric
   bounds — only presence-conditional type checks.** — `validate-connector-options.ts`.
   The loop `if (!Object.hasOwn(options, field)) continue;` means a **missing**
   declared option is never an error, and there's no `required` concept, no
   `enum` membership, no `minimum`/`maximum`. This is *explicitly* scoped as
   "shape only" in the design (`design.md`: "the runtime can't semantically
   validate them beyond shape"), and defaults live in the schema, so this is a
   **documented limitation, not a bug.** Flagging so reviewers don't assume a
   fuller JSON-Schema validator than exists. If a connector ever needs a
   *required* option, this validator won't catch its absence — worth a note in
   the spec's acceptance checks.

2. **`integer` values that are `NaN`/`Infinity`.** `scalarTypeMatches("number")`
   accepts any `typeof value === "number"`, including `NaN`/`Infinity`
   (the sibling `record-validator.ts` in PR #7 correctly uses `Number.isFinite`).
   `connector_options` come from operator input / JSON, so `NaN` is unreachable
   via `JSON.parse` (JSON has no NaN literal) — low practical risk, but for
   consistency with PR #7's validator, `number`/`integer` could use
   `Number.isFinite`. Optional.

3. **Two near-duplicate shape validators now exist** (`validate-connector-options.ts`
   in this PR and `record-validator.ts` in PR #7). They validate different things
   (options vs records) and are intentionally dependency-free, so this is
   acceptable duplication, but a future consolidation into one tiny shared
   JSON-Schema-subset checker would remove drift risk (e.g. the `Number.isFinite`
   inconsistency in #2). Not a blocker.

### Recommendation
Rebase (mandatory) → resolve the 3 additive conflicts by keeping both sides →
re-run tests → then owner review. The code itself is merge-quality; only the
staleness blocks it.

---

## PR #7 — Agent-authored connectors (`@pdpp/connector-synthesis`)

**Verdict: needs-work** (excellent architecture and guardrails; one real runtime
bug + packaging nits; depends on #10).

### What it does
A standalone `@pdpp/connector-synthesis` package: NL intent + source signals →
`classifyCooperativeness` (api/export/cooperative_web/hostile_web) →
`synthesizeManifest` (owner-scoped `agent:<owner>/<slug>` id, `listed:false`,
provenance) → `generateCollector` (deterministic `.mjs` + optional self-heal
skill) → `validateSynthesizedManifest` (honesty guards) →
`validateSynthesizedConnector` (runs the generated collector as a subprocess vs a
fixture, validates emitted records). Plus a per-owner `persist` layer, an
owner-scoped path resolver, an RI lifecycle bridge test, and its own CI workflow.

### Merge state
No conflicts (isolated new package under `packages/*`, which the workspace glob
auto-includes; `pnpm-lock.yaml` touched). Applies cleanly despite 1109 commits of
drift.

### Strengths (this is a lot of careful work)
- **Path-traversal defense is rigorous and battle-tested in-diff.**
  `identity.ts::assertSafePathSegment` rejects `""`, `.`, `..`, leading-dot,
  `/`, `\`, and NUL, and is applied on **both** construction and parse. The
  comment on `parseAgentConnectorId` documents a *previously-fixed* traversal
  bug (`agent:o/..` — `..` carries no slash, so a slug-only `/`-check let it
  escape `join()`), and `persist.ts::ownerConnectorDir` re-asserts at the
  `join()` site as the single trust boundary. This is exactly the
  defense-in-depth you want around "untrusted string → filesystem path."
- **The honesty gate is the load-bearing design and it's enforced, not
  aspirational.** `validate-manifest.ts` rejects `listed:true`, non-`agent:` ids,
  a binding not justified by cooperativeness (e.g. an `api` connector asking for
  a browser), and an incomplete provenance block. `classifyCooperativeness`
  defaults an **unknown** source to `hostile_web` (under-promise) and an explicit
  hostile signal wins over everything.
- **Comment-injection safety on generated code.** `sanitizeForBlockComment`
  breaks `*/`, flattens newlines, strips control chars before interpolating
  agent free-text (display_name, access notes) into a generated block comment —
  a real code-generation escape vector, handled.
- **No fabricated data.** The non-export stub collector emits
  `SKIP_RESULT reason:"extraction_not_implemented"` rather than inventing
  records; hostile_web gets an experimental status + self-heal skill that
  explicitly says "do not gradient-descend on an opaque block."
- **Determinism discipline.** `synthesizedAt` is caller-supplied ("the toolkit
  never calls Date.now"), `codeHash` is a sha256 of the generated source.

### Findings

1. **REAL BUG — generated export collector emits `key: String(data.id)` with no
   missing-id guard.** — `generate-collector.ts`, `generateExportCollector`
   (the emitted `main()` loop):
   ```js
   await emit({ type: "RECORD", stream: streamName, key: String(data.id), data });
   ```
   If a source-export item lacks `id` (or has `id: null/undefined`), `key`
   becomes the string `"undefined"` / `"null"`. Two such items **collide on the
   same key**, and a RECORD is emitted for an id-less record instead of skipping
   it. This is asymmetric with:
   - PR #11's HPI collector, which explicitly `SKIP_RESULT`s a missing-id record
     (`reason:"missing_id"`), and
   - this PR's *own* `record-validator.ts`, which lists `id` as required and
     would flag it — but only at **fixture-validation time**. On a **real run**
     (`persist` → RI spawns the `.mjs`) there is no such guard, so a real export
     with any id-less item silently emits colliding/garbage-keyed records.

   The committed Spotify fixture happens to give every item an `id`, so the
   end-to-end test never exercises the gap.

   *Recommended revision (precise):* in `generateExportCollector`'s emitted loop,
   guard before emit, mirroring the HPI connector:
   ```js
   for (const rawItem of arr) {
     const data = applyFieldMap(rawItem, plan.fieldMap);
     if (data.id === undefined || data.id === null) {
       await emit({ type: "SKIP_RESULT", stream: streamName, reason: "missing_id",
                    message: "source item has no id" });
       continue;
     }
     if (data.fetched_at === undefined) data.fetched_at = nowIso();
     await emit({ type: "RECORD", stream: streamName, key: String(data.id), data });
     recordsEmitted += 1;
   }
   ```
   And add a `generate-collector.test.ts` case with an id-less source item
   asserting a `SKIP_RESULT` (not a `RECORD` with `key:"undefined"`).

2. **`applyFieldMap` returns the original object by reference when
   `fieldMap` is absent, then the caller mutates it.** — same emitted collector.
   `applyFieldMap(item, undefined)` returns `item` unchanged (same reference);
   the loop then does `data.fetched_at = nowIso()`, mutating the caller's
   `rawItem` (which is an element of the parsed `source`). Harmless in the
   current single-pass collector (the source array isn't reused), but it's a
   latent foot-gun if the generated code is ever extended to iterate a stream
   twice. *Suggested revision:* have the no-fieldMap branch return `{ ...item }`,
   or clone at the `fetched_at` assignment. Low priority.

3. **`bin` points at a `.ts` file.** — `packages/connector-synthesis/package.json`:
   `"bin": { "pdpp-synthesize-connector": "./src/cli.ts" }`. A `bin` is invoked
   by plain `node` on install; `cli.ts` needs the `--import tsx/esm` loader (as
   the file's own usage comment shows). So the declared `bin` won't run as a
   bare executable — only via the documented `node --import tsx/esm src/cli.ts`.
   Package is `"private": true` so this never publishes, but the `bin` entry is
   misleading. *Suggested revision:* either drop the `bin` field, or ship a tiny
   `.mjs`/`.js` shim entry that bootstraps tsx, matching how `persist.ts`
   deliberately emits generated collectors as `.mjs` "so a synthesized connector
   needs no TS toolchain at run time." (Nice that the *generated* artifact avoids
   this; the package's own CLI doesn't.)

4. **`validate-connector.ts` subprocess spawn does not use the process-group
   kill discipline PR #11 established.** — `validate-connector.ts::runCollector`
   spawns without `detached:true` and on timeout calls `proc.kill("SIGKILL")` on
   the immediate child only. For the export collector (a short, self-contained
   `.mjs`) this is fine. But this is the validation harness that will eventually
   run *stub/hostile* collectors that spawn browsers/subprocesses, at which point
   a wedged descendant could leak. Since PR #11 already wrote the reusable
   `killTree`/group-kill logic, a future consolidation should have this validator
   reuse it. Not a blocker for the export-only proof shipped here.

5. **Package pins its own `@biomejs/biome` / `ultracite` devDeps and a
   `zod ^4.3.6` dep.** Consistent with other packages? Worth a quick check that
   the `zod` major matches the rest of the monorepo (PR #11's schemas also use
   zod 4 `looseObject`, so likely fine) to avoid two zod copies in the lockfile.
   Verification-only note.

6. **Dependency ordering.** The synthesized export collector reads
   `start.connector_options.source_path`, and the CLI/validate path passes
   `connector_options`. That wire field is *formalized by PR #10*. #7's generated
   code reads it defensively (falls back to `PDPP_SYNTH_SOURCE_PATH` env), so it
   works standalone, but the two PRs are coupled and **#10 should merge first** so
   the `StartMessage.connector_options` type exists repo-wide.

### Recommendation
Fix finding #1 (real bug, small + well-scoped) and add its regression test before
merge. Address #2–#3 in the same pass (trivial). #4–#5 are follow-ups. Land after
#10. Then owner review — the code-generation + per-owner-identity surface is
exactly what the author's own "OWNER REVIEW" banner is for, and the guardrails
(honesty gate, path-traversal defense, no-fabrication) are strong enough to make
that review a yes on engineering grounds.

---

## Cross-cutting recommendations

1. **Merge order:** #11 (independent, clean) any time → **#10 (rebase first)** →
   **#7 (fix bug #1, land after #10).**
2. **Make the tests a gate.** Only #7 ships CI. #10 and #11 add substantial test
   suites that no required check runs. Consider a path-scoped
   `polyfill-connectors` workflow mirroring #7's `connector-synthesis.yml` so the
   documented `node --test …` commands become a merge signal instead of a
   manual step.
3. **One shared shape-validator.** #10's `validateConnectorOptions` and #7's
   `record-validator` are near-duplicate JSON-Schema-subset checkers that already
   disagree on `Number.isFinite` for numbers. A single tiny shared util would
   remove that drift.
4. **Reuse #11's `killTree` in #7's validator** once both land — don't grow a
   second, weaker subprocess-lifecycle implementation.

## Confidence

- Merge-conflict findings (#10's 3 files; #11 and #7 clean): **high** — computed
  via `git merge-tree` against fetched `origin/main`.
- PR #7 finding #1 (missing-id → `key:"undefined"`): **high** — traced from the
  generated source through `record-validator` and confirmed the committed
  fixture never exercises it.
- Test *quality* claims: **medium** — read as source, not re-executed this pass
  (deliberate, to keep CPU light; PR bodies document the exact commands).
- Design/honesty-gate correctness: **high** — read in full.
