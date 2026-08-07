# PDPP Repo Cleanup Audit — 2026-07-03

**Branch:** `waspflow/sp2-cleanup` · **Baseline commit:** `152fc8c59`
**Method:** repo-wide `git grep -w` for every suspected-dead symbol (dead ⟺ only its own
definition + optionally its own test file appear), package.json↔import cross-check, content-hash
duplicate scan, and manual read of every flagged site. Three specialist sub-agents fanned out over
(1) `reference-implementation/`, (2) `packages/`+`apps/`, (3) TODO/commented-code/debug debt; every
sub-agent finding was independently re-verified before landing or reporting.

## Executive summary

**This is a clean codebase.** The headline debt story is *low*: 4 real TODOs (all documented
migration steps), **zero** FIXME/HACK/XXX, **zero** commented-out code blocks, **zero** debug
leftovers (`debugger;`, `.only(`, stray `console.log` in runtime paths), a clean working tree (no
untracked files), and no stray temp artifacts committed by mistake. The `.gitignore` is unusually
thoughtful.

The cleanup value is concentrated in three places: **(a)** a handful of provably-dead exported
symbols, **(b)** two committed `dist/` trees + several unused `package.json` deps, and **(c)**
duplicated app code and a couple of abandoned/orphaned files that need a judgment call rather than a
mechanical delete.

### Applied in this pass (16 dead symbols, 14 files, 82 deletions / 0 additions)

All are **provably-dead exported symbols in `reference-implementation/`** (a non-published reference
impl — these exports are effectively private). Each was verified to have **exactly one** word-boundary
occurrence repo-wide (its own definition), so removal is purely subtractive and cannot change any
observable behavior. One follow-on unused import was also dropped. Each is its own commit
(`ea9567a73`..`9ba0e5ecf`). Full tsc could not run (dependencies are not installed in this worktree,
and installing was out of scope for a light-CPU pass) — but the LSP *did* surface the one
`noUnusedLocals` regression I introduced (an orphaned import), which I then fixed; the remaining LSP
errors are all `@types/node`-missing baseline noise identical on the untouched files.

| # | File:line (pre-edit) | Symbol | Kind |
|---|---|---|---|
| 1 | `runtime/pipe-errors.ts:37` | `CLOSED_PIPE_ERROR_CODES` | const |
| 2 | `runtime/controller.ts:1610` | `isNeedsHumanAttention` | function |
| 3 | `server/connection-setup-plan.ts:231` | `BrowserBoundConnector` | type |
| 4 | `server/connection-setup-plan.ts:247` | `ProviderAuthLifecycleProvenConnector` | type |
| 5 | `server/connection-setup-plan.ts:266` | `StaticSecretLiveProvenConnector` | type |
| 6 | `server/search-semantic.js:1031` | `resetVectorIndexForTests` | test helper (uncalled) |
| 7 | `server/streaming/neko-adapter.js:1195` | `createDefaultNekoStreamingCompanionFactory` | alias const |
| 8 | `server/auth.js:5808` | `_resetConsentExchangeCodes` | test helper (uncalled) |
| 9 | `server/provider-auth/google-data-portability.ts:341` | `googleDataPortabilityScopesForConfiguredEnv` | function (+ orphaned import) |
| 10 | `server/retained-size-read-model.js:2233` | `RETAINED_SIZE_LIMITS` | const |
| 11 | `server/collector-protocol.ts:34` | `CollectorProtocolVersion` | type alias |
| 12 | `server/search.js:109` | `isLexicalIndexBackfillActive` | function |
| 13 | `server/owner-session.ts:8` | `OWNER_AUTH_DEFAULT_SESSION_TTL_SECONDS` | alias const |
| 14 | `server/ref-control.ts:685` | `TimelineResponse` | interface |
| 15 | `cli/lib/args.js:49` | `requireFlag` | function |
| 16 | `cli/lib/cache.js:63` | `readClient` | function |

For each, I confirmed the symbols the removed code *depended on* (module state, sibling helpers,
underlying constants) remain referenced by other live code, so nothing was orphaned — with the single
exception of `GOOGLE_MAPS_DATA_PORTABILITY_OAUTH_SCOPES` in #9, whose only in-file consumer was the
removed function; that import was dropped in the same commit.

---

## Findings by category (ranked by safety × value)

Legend: **✅ APPLIED** · **🔍 INVESTIGATE** (needs a decision / build to verify) · **📌 KEEP**
(looked suspicious, verified intentional).

### 1. Dead exports — reference-implementation ✅ APPLIED
See table above. Highest safety (subtractive, zero refs), moderate value (16 symbols, ~82 lines).

### 2. Dead exports — packages/apps 🔍 INVESTIGATE
High confidence they're dead, but **not auto-applied** because they live in the Next.js apps, whose
type/build check needs the app toolchain (couldn't run here), and a few are whole files/features where
deletion is a product decision. Each verified: only its own def (+ own test) appears repo-wide.

- `apps/console/src/app/dashboard/lib/duration.ts:1` — `formatDurationCompact` — def-only. **Delete.**
- `apps/console/src/app/dashboard/lib/owner-token.ts:315` — `clearOwnerToken` — def-only (file heavily imported, this export isn't). **Delete.**
- `apps/console/src/app/dashboard/lib/owner-token.ts:92` — `toReferencePublicUrl` — def-only; **and** `getReferencePublicPath` (`:76`) is used *only* by it → the pair is jointly dead. **Delete both.**
- `apps/console/src/app/dashboard/lib/rs-client.ts:838` — `deriveColumns` — def-only (siblings `deriveAllColumns`/`computeDefaultColumns`/`resolveSelectedColumns` are live). **Delete.**
- `apps/console/src/lib/pdpp-cli-command.ts:227–231` — five `pdppCliCollector*Command` aliases (`Enroll`/`Run`/`Doctor`/`Status`/`RetryDeadLetters`) — each def-only; the `pdppLocal*` originals are the live ones. **Delete all 5.** (Note: the sibling `pdppBrowserCollector*Command` aliases ARE live — string-referenced in `scripts/owner-journey-acceptance/surface-manifest.mjs`. Do not touch those.)
- `apps/console/src/app/dashboard/lib/source-actionability.ts:180` — `verdictRequiresOwnerNow` — dead product code kept alive only by its own test. **Delete symbol + its test case.** (The other exports flagged in this file are used internally — over-exported, not dead.)

### 3. Abandoned web-push feature 🔍 INVESTIGATE (medium confidence)
Looks like a fully-abandoned feature. Removing it is a product call, but the evidence is consistent:
- `apps/console/src/app/dashboard/components/web-push-settings.tsx` — imported only by its own `.test.ts`.
- `apps/console/src/app/dashboard/lib/ref-client.ts` — `getWebPushConfig` (`:1178`), `listWebPushSubscriptions` (`:1182`) — def-only, the ref-client methods that component would call.
- Plus 5 more def-only `ref-client.ts` methods that smell like other unwired half-features: `getStaticSecretSetupStatus` (`:1854`), `validateManualUploadArtifact` (`:1983`), `createManualUploadDraftConnection` (`:1996`), `listDeviceExporters` (`:2009`), `createBrowserEnrollmentShell` (`:2472`).
- **Action:** confirm the web-push feature is truly shelved, then delete `web-push-settings.tsx` + its test + the two web-push ref-client methods together. Audit the other 5 ref-client methods individually — some may be awaiting a caller.

### 4. Orphaned files (no product-code importer) 🔍 INVESTIGATE
Zero real `import`/`from` in `apps/`/`packages/` code; mentions only in markdown / archived demo. Safe
to delete, but they're whole files → confirm no dynamic/route usage first.
- `apps/site/src/lib/seed-gmail.ts` (`SEED_GMAIL_THREADS`, `GMAIL_SUMMARY`) — **zero refs anywhere.** Strongest.
- `apps/site/src/lib/openspec/format.ts` (`formatOpenSpecDate`) — **zero refs anywhere.** Strongest.
- `apps/site/src/lib/seed-data.ts` (`SEED_*`) — referenced only in docs/design-notes.
- `apps/site/src/lib/spec-refs.ts` (`SPEC`, `SpecRef`) — imported only by `demo_archived/` + docs.
- `apps/site/src/lib/purpose-docs.ts` (`PDPP_PURPOSE_DOCS`, `PurposeDoc`) — imported only by `demo_archived/`.
- `apps/console/src/app/dashboard/records/connector-row.tsx` (`ConnectorRow`) — **ambiguous:** many `ConnectorRow`/`connector-row` grep hits exist but appear to be a *different* symbol in the `records/[connector]/` tree. **Verify identity before any action.** Likely KEEP.

> `spec-refs.ts` and `purpose-docs.ts` are only alive through `demo_archived/` — if `demo_archived/`
> is removed (finding 8), re-check these; they may become fully dead.

### 5. Committed build artifacts (`dist/`) 🔍 INVESTIGATE
Two workspace packages commit their compiled output; no other package does, and `reference-contract`
even `.gitignore`s `dist/`. There is **no root `prepare`/`postinstall`** and neither package has a
`prepare` hook, so the committed `dist/` is what dev/build actually consumes → **cannot be blindly
removed** without adding a build step. This is real inconsistency, but load-bearing.
- `packages/remote-surface/dist/` — **160 tracked files.** `private:true`, `main:./dist/index.js`, consumed by `apps/console` via `exports`→`dist`. `.d.ts`/`.js`/`.js.map` triples of the src.
- `packages/local-collector/dist/` — **53 tracked files.** `private:false` (**published to npm**) — npm publish rebuilds via `prepack`, so the committed copy is redundant *for publishing* but may be relied on by workspace consumers at dev time.
- **Action:** decide the policy per package: either (a) add a `prepare` build hook + `.gitignore dist/` (removes ~213 tracked files, matches the rest of the repo), or (b) keep committing dist and document why. `local-collector` (published, rebuilt on publish) is the safer of the two to un-commit.

### 6. Unused `package.json` dependencies 🔍 INVESTIGATE
Cross-checked every dep against all tracked files in its package (code + CSS + config), not just JS
imports. The list below is **truly absent from the package's own sources** (appears only in
`demo_archived/`'s separate workspace or in a biome lint-ignore comment that is itself evidence the dep
was already removed from code). Not auto-applied: dep removal ripples into the lockfile and can hit
implicit/peer/dynamic-import usage.

**`apps/console`** — `@base-ui/react`, `@xterm/xterm`, `@xterm/addon-fit`, `@xterm/addon-web-links`,
`react-xtermjs`, `react-markdown`, `remark-gfm`, `fumadocs-mdx`, `imapflow`, `zod`.
**`apps/site`** — `@base-ui/react`, `@opendatalabs/remote-surface`, `@xterm/xterm`,
`@xterm/addon-fit`, `@xterm/addon-web-links`, `react-xtermjs`, `zod`, `lucide-react`(⚠️ used
transitively via `fumadocs-core/source/lucide-icons` — verify before removing).

> **Do NOT remove** (verified live via CSS/config/runtime, despite no JS import): `react-dom` (Next.js
> runtime requirement), `postcss`, `tw-animate-css`, `class-variance-authority`, `shadcn`,
> `@demodesk/neko` (site `globals.css`), `@fontsource-variable/*` (`pdpp-brand/base.css`).

- **Action:** run `pnpm dlx knip` (or `depcheck`) per app to confirm, then prune. The `xterm` cluster +
  `react-xtermjs` are only used in `demo_archived/` — high confidence once that's resolved.

### 7. Duplicated app code (console ↔ site) 🔍 INVESTIGATE (DRY / decomplect)
Content-hash scan found ~16 files byte-identical between `apps/console` and `apps/site`:
- `scripts/dev-origins.mjs` (+ `.test.mjs`), `src/components/pdpp/{connector-card,grant-inspector,spec-citation,stream-inventory}.tsx`, `src/components/theme/{theme-provider.tsx,theme-runtime.test.ts,theme-state.ts}`, `src/components/ui/{card,dialog,popover,tooltip,timestamp}.tsx` (+ `timestamp.test.ts`), `tailwind.config.ts`.
- **Action:** extract into a shared workspace package (e.g. `@pdpp/ui` or extend `pdpp-brand-react`).
  Behavior-preserving but structural (rewrites imports in two apps) → a scoped refactor, not a mechanical
  delete. Medium value, medium effort.

Other duplicate pairs verified **intentional / low-priority**: `packages/cli/src/ref/errors.js` vs
`reference-implementation/cli/lib/errors.js` (published CLI vendors a copy),
`server/queries/search-semantic/.../count-indexable-text-values.sql` vs `search/.../…` (per-feature
query copies), the 3 identical `docs/research/**/harness/base.css` prototype harnesses.

### 8. `demo_archived/` (72 files) 🔍 INVESTIGATE
A legacy demo app (`app/`, `browser-server/`, `mock-platform/`, 6 strategy `.md`s) explicitly named
"archived". Still referenced by ~7 docs and is the *sole* remaining consumer of `apps/site/src/lib/
{spec-refs,purpose-docs}.ts`. It's also the only place several "unused" deps and the `xterm` cluster
appear. **High-value removal if it's truly retired** (would clear ~72 files + unblock findings 4 & 6),
but it's a deliberate archive → **owner decision.** If removed, do it as one commit and re-run the
dead-dep/dead-file checks afterward.

### 9. Root-level & misc file hygiene 🔍 INVESTIGATE (low value)
- `research-traefik-nextjs-hmr.md` (root) — one-off research note, **zero refs.** Relocate to `docs/research/` or delete.
- `docs/research/oauth-spike-throwaway/` (README + `package.json` + `spike.mjs`) — explicitly "throwaway", marked private, **zero refs.** Delete candidate (owner may want to keep as research).
- `repro-crash.sh` (root) — frozen repro for the fixed `2026-04-24-fix-rs-query-memory-pressure` crash; depends on an external `~/pdpp-repro-db/*.snapshot`. Referenced by `AGENTS_NOTE.md` + archived openspec. Fixed bug → likely retire, but harmless. Low priority.
- `ds-trial-report.md` (root) — a dogfooding trial report; belongs in `inbox/` but harmless.
- `design-evidence/CLOSEOUT.md` — the only file left in `design-evidence/` (screenshots are `.gitignore`d); a closeout note for a design pass on an unmerged branch. Orphaned but documents shipped work — KEEP or relocate.

### 10. `.gitignore` gaps & quirks 🔍 INVESTIGATE (low risk)
- **Broad `*.png` / `*.yml` / `*.log` ignores (lines 16–18)** with `!`-exceptions. Consequence: any *new*
  legitimate PNG outside `docs/explorer/uat/**`, or a new top-level `.yml`, is silently ignored and easy
  to forget with `git add`. The fixture `debug.log`/`codex-tui.log` and `mystery.dat` files were
  force-added despite `*.log` — intentional, but fragile (a future `git add -A` won't re-add them if
  removed). Consider scoping these ignores to the dirs that actually generate the artifacts.
- **`.impeccable.md` is both tracked and listed in `.gitignore` (line 49)** — contradictory. `git
  check-ignore` returns nothing (tracked wins), so the rule is dead/misleading. Either untrack the file
  or drop the ignore line.
- `.waspflow/config.json` and `.devspecs/config.yaml` are tracked local-tooling configs — verify they're
  meant to be shared, not machine-local (the `.claude/` runtime artifacts are correctly ignored).

### 11. TODO / debt catalog 📌 (track, don't "clean")
Only **4 TODOs**, all in `packages/remote-surface/src/adapters/`, all tied to a numbered migration.
Two are real functional gaps worth a tracked issue:
- `neko-surface-adapter.ts:188` `TODO(step-3)` — **n.eko instance leak on remount** (no `stop` helper; "repeated mount/unmount cycles will leak the underlying neko instance"). *Highest severity.*
- `neko-surface-adapter.ts:398` `TODO(step-3)` — `sendText` is a **no-op** (returns instead of proxying `nekoInstance.control.paste`).
- `neko-surface-adapter.ts:216` `TODO(step-4)` — IME mode-switching ignored (cosmetic).
- `cdp-surface-adapter.ts:3` `TODO(remote-surface)` — whole adapter is a provisional fallback stub (both adapters ARE consumed by `apps/console` stream-viewer — not dead, just incomplete).

17 `@deprecated` JSDoc markers exist — all intentional back-compat re-export shims, **not** debt.

### 12. Verified-clean (no action) 📌
- **Root `spec-*.md` (10 files)** — load-bearing vitepress docs (`spec-core` alone has 89 refs; `index.md` links to them). KEEP.
- **Fixture `debug.log` / `codex-tui.log` / `mystery.dat`** under `packages/polyfill-connectors/fixtures/` — deliberate connector-source-home simulations (`unknown-future-store/mystery.dat` is a purpose-built "unknown store" test case). KEEP.
- **Large files** (openapi JSONs, spec.md, UAT PNGs, test fixtures, `_ds_bundle.js`) — all legitimate. KEEP.
- **`server/dev-env-defaults.js`, `server/hosted-ui.d.ts`** — flagged as possible orphans, both cleared (dynamic `node --import` load; ambient `.d.ts` for a live `.js`). KEEP.
- **`packages/reference-contract/src/common/*`** schemas — public API re-exported via `export *` barrel (grep-invisible). KEEP.
- No commented-out code, no `debugger;`, no `.only(`/`.skip(` test-isolation hazards, no stray runtime `console.log`, clean working tree.

---

## Recommended next actions (in order)
1. **Landed already:** the 16 reference-implementation dead-symbol removals (this pass).
2. **Low-risk, high-clarity:** delete the def-only apps/site orphans with **zero** refs anywhere —
   `seed-gmail.ts`, `openspec/format.ts` (verify app build stays green).
3. **Product decision:** confirm the web-push feature (finding 3) and `demo_archived/` (finding 8) are
   retired; both unblock further dead-code/dep pruning.
4. **Tooling-verified:** run `knip`/`depcheck` per app, prune finding 6's deps + lockfile.
5. **`dist/` policy** (finding 5): add `prepare` hooks + `.gitignore dist/`, starting with the published
   `local-collector` (~213 files off the tree).
6. **Refactor:** extract the console↔site duplicated UI (finding 7) into a shared package.
7. **Hygiene:** the `.gitignore` `.impeccable.md` contradiction and scoped `*.png`/`*.log` ignores.
