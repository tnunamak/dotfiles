# PDPP Documentation Audit — 2026-07-03

**Scope:** All load-bearing Markdown documentation in the PDPP repo — `README.md`,
`AGENTS.md`, root normative specs (`spec-*.md`), `apps/site/content/docs/**`,
`docs/**` (core guides, operator runbooks, agent-skills), `openspec/README.md`
and `openspec/specs/**` (durable capability specs), package/deploy READMEs, and
`reference-implementation/README.md`.

**Out of scope (historical / vendored):** `openspec/changes/archive/**` (~348
archived changes), `openspec/changes/<active>/**` (transient in-flight proposals),
`docs/archive/**`, `demo_archived/**`, `design-notes/**` (frozen intake notes),
`.claude/commands/**`, `node_modules`.

**Method:** every concrete, checkable claim (a path, script, package name, port,
endpoint, env var, CLI flag, architecture assertion, cross-doc link) was verified
against the actual code and filesystem — `rg`/`grep`/`Read` against
`reference-implementation/`, `packages/`, `apps/`, root `package.json`, and the
openspec tree. A parallel multi-agent pass (8 audit lanes + adversarial verify
stage, 13 agents) cross-checked the manual findings; every auto-applied fix was
re-verified independently before commit.

**Branch:** `waspflow/sp2-docs`. Commits authored `Tim Nunamaker
<tnunamak@gmail.com>`. Not pushed.

---

## 1. Headline

The core entry-point docs are in **good shape**. `README.md` and `AGENTS.md` are
strikingly accurate — the site/console split, ports (`AS :7662` / `RS :7663`),
storage posture (SQLite default, Postgres opt-in on `:55432`), the connector
support matrix, script names, and even a cited code symbol
(`browser-launch.ts:decideContainerHeadedBrowserGate`) all check out against
current code.

Of **102 unique load-bearing doc files assessed**:

| Verdict | Count | Meaning |
| --- | --- | --- |
| ACCURATE | 73 (72%) | Matches current code |
| MIXED | 14 | Mostly accurate, isolated stale/wrong claims |
| STALE | 9 | Was true, now outdated (mostly dated session artifacts in `docs/operator/`) |
| WRONG | 5 | Never true / contradicts code |
| INCOMPLETE | 1 | Missing critical info |

The dominant defect class is **dead links to OpenSpec changes that were archived**
(moved from `openspec/changes/<name>` to
`openspec/changes/archive/<date>-<name>`). This is systemic: docs pin
non-archive paths that rot the moment a change is archived. **17 such dead links
across 8 files were found and fixed** this session.

The second class is **post-split (`apps/web` → `apps/site` + `apps/console`) and
post-TS-migration (`.js` → `.ts`) path rot** in a handful of operator/testing
guides.

The most **operator-dangerous** single defect was a transposed RS port
(`7763` instead of `7663`) in a copy-pasteable runbook block — fixed.

---

## 2. Fixes applied this session (12 commits)

Each is its own commit; all were independently re-verified (oldString present
verbatim, target/claim confirmed against code) before applying.

| # | File(s) | Fix | Evidence |
| --- | --- | --- | --- |
| 1 | `README.md` | `split-public-site-and-operator-console` → `archive/2026-06-01-…` | dir moved to archive |
| 2 | `README.md` | `introduce-local-collector-runner/design.md` → `archive/2026-05-29-…` | dir moved to archive |
| 3 | `AGENTS.md` | `reference-implementation-program/proposal.md` → `archive/2026-04-24-…` | dir moved to archive |
| 4 | `reference-implementation/README.md` | 2 dead links to `reference-implementation-program` design-notes → archive path | files exist in archive |
| 5 | `docs/agent-skills/…/query-cookbook.md` | `hydrate-first-party-blob-streams` → `archive/2026-05-28-…` | change archived |
| 6 | `deploy/railway/README.md` | 3 dead links to `add-railway-core-deploy-target` → `archive/2026-06-09-…` | change archived |
| 7 | `apps/site/content/docs/reference-implementation-examples.md` | RS port `7762`→`7663` (×3), `--owner-token`→`--token`, "Two things"→"One thing" | `cli/lib/common.js` `resolveRsUrl` default `:7663`; `cli/index.js:53` flag; only 1 bullet follows |
| 8 | `docs/operator/blob-fetch-runbook.md` | RS port `7763`→`7663` | `server/index.js` `RS_PORT` default `7663`; adjacent AS is `7662` |
| 9 | `docs/operator/{local-collector-runbook,add-connection,static-secret-connection-runbook,event-subscriptions}.md` | 7 dead openspec links → archive paths; 1 stale `apps/web`→`apps/site` | targets exist in archive; `apps/web` deleted |
| 10 | `docs/agent-skills/pdpp-data-access/{SKILL.md,references/troubleshooting.md}` | MCP tool list 5→6 (add `read_record_field`) | `packages/mcp-server/src/tools.js` `PDPP_MCP_TOOL_NAMES` (6 names); `tool-footprint.test.js:182` |
| 11 | `reference-implementation/README.md` | `split-public-site-and-operator-console` → `archive/2026-06-01-…` | change archived |
| 12 | `spec-core.md` + `apps/site/content/docs/spec-core.md` | add missing `{#record-model}` anchor to Section 4 so the TOC link resolves | TOC (`:32`) links `#record-model`; heading had no anchor while §5–10 do; `spec:check` passes |

**Total dead links / broken anchors fixed: 18. Wrong facts fixed: 5 (3× port, 1×
CLI flag, 1× 5-vs-6 tool footprint). Stale count fixed: 1.** All 9 mirrored
root/site spec pairs still pass `pnpm spec:check`.

---

## 3. Prioritized recommendations (NOT auto-applied)

These are either judgment-call rewrites, decisions the owner should make, or
fixes whose exact form I could not fully pin without repo-convention input.

### P0 — correctness, affects contributors/operators literally

1. **`docs/local-testing-e2e.md` — dead `.js` entrypoints after the TS
   migration.** Two runnable commands invoke files that no longer exist:
   - L63: `node packages/polyfill-connectors/bin/orchestrate.js run chatgpt`
     → file is now `orchestrate.ts`.
   - L258: `node packages/polyfill-connectors/connectors/chatgpt/index.js …`
     → file is now `index.ts`.
   Note the fix is **not** a plain `.js`→`.ts` rename: `node foo.ts` won't
   execute TypeScript. The connector's own entry-point comment
   (`connectors/chatgpt/index.ts:3966`) prescribes `tsx connectors/chatgpt/index.ts`.
   **Recommended:** replace `node …/orchestrate.js …` with
   `tsx …/orchestrate.ts …` (or the repo's canonical `pnpm exec`/package-script
   invocation) — confirm the exact runner convention before editing so one
   broken command isn't swapped for another.

2. **`docs/local-testing-e2e.md` L233 — pre-split "view in dashboard" step is
   now wrong.** It tells the operator to run `pnpm dev` in a 4th terminal
   expecting a standalone dashboard on `:3002` that reads the AS/RS started in
   terminal 2. But `pnpm dev` (`scripts/dev.mjs`) now boots its **own** reference
   AS/RS on `7662/7663` (colliding with terminal 2) plus `apps/console`, and the
   default web port scans up from `:3000`, not `:3002`. **Recommended:** rewrite
   the walkthrough for the current `pnpm dev` / `pnpm dev:full` topology.

3. **`docs/operator/local-collector-runbook.md` L29 — wrong compose location.**
   Refers to "the Docker compose under `reference-implementation/docker/`"; no
   such directory exists. The compose stack is at the repo root
   (`docker-compose.yml`). **Recommended:** correct the path.

### P1 — stale architecture / accuracy claims

4. **`reference-implementation/README.md` "What it proves / does not yet prove"
   is stale on the authorization-code flow.** L30–32 say the reference "does not
   yet prove a full generic third-party authorization-code redirect flow," but
   the code now implements and metadata-advertises exactly that: `GET/POST
   /oauth/authorize` with PKCE (`server/routes/as-authorize.ts`),
   `grant_type=authorization_code` exchange (`server/routes/as-oauth.ts:336`),
   and `authorization_endpoint` advertised in discovery
   (`server/routes/root-and-discovery.ts:440`). The "Primary surfaces" section
   (L91–97) also omits `GET /oauth/authorize`. **Recommended:** move the
   authorization-code flow from "does not yet prove" to "proves," and add
   `/oauth/authorize` to Primary surfaces. (Judgment-call prose rewrite — leaving
   to owner to phrase the honesty framing.)

5. **`MAINTAINERS.md` — garbled anonymization artifacts.** The maintainer table
   (L9–11) contains non-functional identity strings ("the owner Nunamaker", "a
   person Kaz") and a GitHub ID `@owner` that is not a resolvable handle. As the
   canonical governance/contributor list this reads as broken. **Needs owner
   input** (the intended real values are unknown to the auditor); cannot be
   safely auto-fixed.

6. **`openspec/specs/reference-implementation-architecture/spec.md` — package
   rename drift.** Names the extractable package `@pdpp/remote-surface` in ~14
   places; the shipped package is now scoped `@opendatalabs/remote-surface`
   (`packages/remote-surface/package.json:2`). This is **owner-tracked** by the
   active change `republish-remote-surface-as-opendatalabs` (has a specs delta)
   and should reconcile on archive — flagged, not fixed, because the rename is
   mid-flight. The sibling `packages/remote-surface` path reference is still
   correct.

7. **`packages/remote-surface/README.md` L213 — wrong validator path.** Says
   host-coupled matches "must be pattern-allowlisted in
   `scripts/validate-package.mjs`" (implying repo root); the validator actually
   lives at `packages/remote-surface/scripts/validate-package.mjs`. There is no
   root `scripts/validate-package.mjs`. **Recommended:** correct to the
   package-local path. (Also: this README still uses the old package name in
   places — reconcile with the `@opendatalabs` rename.)

8. **`packages/reference-contract/README.md` L27–30 — stale "Development
   status."** Frames the package as scaffolded in W0 with validators/artifacts
   still being filled in across W1–W2. In reality `src/{common,public,reference,
   openapi,builders}` are fully populated (11 `.ts` files) and the package ships
   at `v0.1.0`. **Recommended:** update or drop the status section.

9. **`docs/agent-skills/pdpp-owner-agent/references/control-surface.md` L193 —
   stale change reference.** Cites `add-owner-agent-control-surface` as if
   live/pending; it was archived 2026-06-10
   (`archive/2026-06-10-add-owner-agent-control-surface`). **Recommended:**
   update the reference (text mention, not a link) to reflect archived status.

### P2 — dead pointers to unpublished / never-created artifacts

10. **Root specs cite documents that do not exist:**
    - `spec-deferred.md:111` → `spec-v2-session-relay-profile.md` (dangling;
      `spec-core.md:81` also calls the "PDPP Session Relay Profile" "not yet
      published"). Either publish the stub or soften the pointer to a forward
      reference without a filename.
    - `spec-connector-ecosystem.md:21` and `:123` → `model-b-runtime-provided-
      browser.md` (twice; file never existed in-repo).
    **Recommended:** convert to prose forward-references or remove the filenames
    until the documents exist. (Spec-authoring judgment call.)

11. **`spec-connector-ecosystem.md:100` / `spec-deferred.md:181` — manifest
    browser-capability shape contradicts the normative Collection Profile.**
    They describe `browser: required|optional|none` /
    `runtime_requirements.browser`, but the normative shape
    (`spec-collection-profile.md:56–69`) is
    `runtime_requirements.bindings.browser_automation` (`{interface, ws_url, …}`).
    **Recommended:** reconcile the informational specs to the normative manifest
    shape. (Contradiction between docs.)

12. **`spec-core.md` — broken intra-doc anchor. [FIXED — commit 12]** The
    Section-4 self-link `#record-model` had no matching heading id (every other
    numbered section carries an explicit `{#…}` anchor). Anchor added to both the
    root spec and its site mirror; `spec:check` still passes.

13. **`reference-implementation/README.md` `docs/operator/live-proof-packet.md`
    etc. — references to session-scratch paths.** e.g.
    `tmp/workstreams/ri-live-gated-proof-map-v1-report.md` (does not exist).
    These are ephemeral by nature; **recommended** to relocate the packet docs
    (see P3-#16) rather than repair each scratch pointer.

### P3 — completeness, duplication, clarity, tidiness

14. **`apps/site/content/docs/meta.json` — `spec-data-query-api` orphaned from
    the docs sidebar.** The page is a mirrored, published spec (`spec:check`
    treats it as a canonical pair) but is missing from `meta.json`'s `pages`
    array, so it's reachable only by direct URL and absent from the index Cards.
    **Recommended:** add it to the sidebar. (Verified: 0 occurrences of
    `spec-data-query-api` in `meta.json`.)

15. **Agent-skill dist (`skills/pdpp-data-access/`) is drifted and currently
    fails `pnpm agent-skill:check`.** `skills/pdpp-data-access/` is a **generated
    dist** produced by `scripts/sync-agent-skill.mjs --write` from the canonical
    source `docs/agent-skills/pdpp-data-access/`. `pnpm agent-skill:check`
    already reports drift on **4 files** (SKILL.md, grant-design.md,
    query-cookbook.md, troubleshooting.md) — this predates and is independent of
    this audit's edits. The canonical source is authoritative and was corrected
    here (fixes #5, #10). **Recommended:** run `pnpm agent-skill:sync` to
    regenerate the dist and unblock the CI gate. (Left as a build step, not
    swept into a doc commit, to keep the audit commits clean.)

16. **Six dated one-off session artifacts pollute `docs/operator/`.** Operators
    treat `docs/operator/` as durable runbooks, but these are point-in-time proof
    logs tied to now-archived changes:
    `live-proof-packet.md`, `live-proof-batch-runbook.md`,
    `sitting-b-hosted-mcp-bench-packet.md`, `chatgpt-mcp-canonical-proof-packet.md`,
    `canonical-connector-keys-production-restore-packet.md`,
    `codex-append-cursor-recovery-packet.md`. **Recommended:** relocate to
    `docs/archive/` (keeps the durable runbooks — hosted-mcp-setup,
    selfhost-quickstart, local-collector-runbook, add-connection,
    static-secret-connection-runbook, event-subscriptions, blob-fetch — clean).

17. **`AGENTS_NOTE.md` is expired steward cruft at the repo root.** Dated
    2026-04-22/24, it announces a steward agent running "for the next ~8–12
    hours," references deleted `apps/web` (multiple lines), the removed
    `pdpp-ts-refactor/` worktree, `.claude/scheduled_tasks.json` (gone), and
    long-archived changes (swap-sqlite-driver, add-reference-impl-logging,
    fix-rs-query-memory-pressure). It is linked from nothing and can mislead a
    fresh agent into thinking a steward is live-committing. Its own "Don't delete
    this file" instruction was scoped to that (long-ended) live window.
    **Recommended: delete.** (Left as a recommendation rather than auto-deleting
    a whole outward-facing file; it's an unambiguous removal, but deleting a file
    is heavier than a link fix and the owner may want the steward convention
    preserved elsewhere.)

18. **Two point-in-time research notes sit unlinked at the repo root**
    (`ds-trial-report.md`, `research-traefik-nextjs-hmr.md`). Repo convention
    (`AGENTS.md`) directs web research/prior-art into `docs/research/`.
    **Recommended:** relocate to declutter the entry-point surface. (Content is
    intact; low priority.)

19. **`docs/full-vision.md` is a dated design-session handoff stored as a live
    core guide.** Reads as current-state ("what we said we'd build in this
    session," "what we promised but haven't fully delivered") but is a
    point-in-time capture. **Recommended:** archive under `docs/archive/` or
    add a dated "session snapshot" banner.

20. **15 of 23 durable OpenSpec specs still carry a placeholder Purpose.** Files
    (hybrid/semantic-retrieval, mcp-adapter, reference-surface-topology,
    reference-implementation-runtime, reference-connector-instances,
    polyfill-runtime, reference-connection-health,
    local-agent-collector-completeness, local-collector-durable-work,
    local-device-exporter-collection, reference-run-assistance,
    reference-demo-instance, reference-dashboard-notifications,
    reference-owner-agent-control-surface, and one sibling) still read `Purpose:
    TBD - created by archiving change <name>. Update Purpose after archive.`
    These are unfilled post-archive TODOs the OpenSpec workflow expects to be
    resolved (`openspec/README.md:34`: "Open questions do not belong in spec
    files"). **Recommended:** fill each Purpose. Judgment-call authored content,
    not a mechanical edit — best done by whoever owns each capability.

21. **Duplicate agent-skill trees `skills/` and `docs/agent-skills/`.** Resolved:
    `docs/agent-skills/` is canonical, `skills/` is the generated dist (see #15).
    No action beyond running the sync; noting here so future readers don't treat
    the two copies as independent sources of truth.

---

## 4. Notable NON-findings (things I verified are correct, to prevent re-work)

- **Root specs vs `apps/site/content/docs/spec-*.md` are in parity by design.**
  A raw `diff` shows ~11–12 differing lines per file, but this is purely the
  presentation wrapper (`# Title` → MDX frontmatter; `Status:`/`Date:` →
  `<Callout>`) that `scripts/spec-check.mjs` intentionally normalizes
  (`stripTitleAndRootStatus` / `stripLeadingSiteCallout`). **This is NOT drift.**
  The site copies are faithful mirrors plus an MDX wrapper.
  `spec-reference-implementation-examples.md` is an explicitly exempt
  `REFERENCE_ONLY_ROOT_SPEC` and legitimately differs (the site
  `reference-implementation-examples.md` is a different, more tutorial document).

- **`README.md` connector-support matrix and route claims verified.** All
  connectors in the table exist under `packages/polyfill-connectors/connectors/`;
  console routes (`/dashboard`, `/dashboard/records/add`, BFF proxy `/v1`,
  `/oauth`, `/well-known`) and site routes (`/docs`, `/reference`,
  `/reference/coverage`, `/sandbox`, `/planning`, `/design`, `/palette`) all
  exist; `browser-launch.ts:decideContainerHeadedBrowserGate` exists at
  `packages/polyfill-connectors/src/browser-launch.ts:179`.

- **`AGENTS.md` references all resolve** (`docs/{ci-mode,agent-workstream-
  playbook,voice-and-framing}.md`, `docs/positioning/README.md`,
  `openspec/specs/reference-implementation-architecture/spec.md`, `ci:mode:*`
  scripts) after the archive-link fix.

- **`spec-core.md` Section 8 (RS interface) is code-accurate.** Endpoints
  (`/v1/streams…`, `/v1/blobs/:id`, `/v1/ingest/:stream`, `/v1/state/:id`),
  error codes (`limit_clamped`, `field_not_granted`, `grant_stream_not_allowed`,
  `invalid_expand`, `invalid_cursor`, `blob_not_found`, …), and query features
  (`view`, `changes_since`, `range_filters`) all verified against
  `reference-implementation/server/routes/rs-read.ts` + `rs-mutation.ts` and
  `packages/read-core`.

- **`index.md` is the live VitePress home page** (consumed by
  `.vitepress/config.ts`), not an orphan or duplicate; its hero links resolve.

---

## 5. Systemic recommendation

The single highest-leverage improvement is to **stop dead-linking archived
OpenSpec changes.** 17 of the ~22 defects found were this exact pattern: a doc
pins `openspec/changes/<name>` and the link dies the instant the change is
archived to `openspec/changes/archive/<date>-<name>`. Options, in preference
order:

1. **Add a link-checker to `spec:check` or CI** that resolves relative Markdown
   links in load-bearing docs (this audit's scan found every one; it's cheap).
   A CI gate would have caught all 17.
2. **Reference archived changes by a stable ID, not a path**, or link to the
   capability spec under `openspec/specs/<cap>/` (which is durable) rather than
   the change that introduced it.
3. When archiving a change, **grep the docs for its non-archive path** and
   rewrite references as part of the archive step (mirror of the AGENTS.md
   rename-cleanup discipline).

A repo-wide relative-link scan (excluding archives/vendored) over 478 doc files
found 154 local links, of which the genuine breakages were exactly the archived-
change pattern plus the post-split/post-TS-migration path rot documented above.
Extensionless spec links (e.g. `[…](spec-collection-profile)`) and Next.js route
links (`/reference`, `/docs`) are intentional for the docs router and are not
defects on the site, though the root specs' extensionless links won't resolve in
a plain Markdown viewer (GitHub) — a minor portability note, left as-is because
changing them risks the site router / `spec:check`.

---

*Generated during the 2026-07-03 docs deep-audit. Fixes committed on
`waspflow/sp2-docs`; report + fixes not pushed.*
