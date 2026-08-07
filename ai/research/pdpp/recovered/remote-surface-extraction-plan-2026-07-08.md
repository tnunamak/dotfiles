# remote-surface repo extraction — plan (2026-07-08)

Owner: this agent. Status: **APPROVED — A+B authorized; C completes before transfer.**

## Owner decisions (2026-07-08, locked)
1. **LFDT timing: FULL extraction.** The transfer tree MUST NOT ship an
   OpenDataLabs-owned package — that ownership boundary is the point. No
   transition-mirror period (LFDT approval gives days of runway). Phase C
   completes BEFORE transfer, landing on `curation/lfdt-prep`, with the
   graceful-degradation shim (streaming disables with a clear status when the
   dep is absent).
2. **Go: A + B approved now.** B creates `github.com/vana-com/remote-surface`
   WITHOUT touching the monorepo. `npm publish` stays owner-gated (copyright
   line + `private:false`). After B, report the seam diff, then proceed to C
   unless flagged. Gates green throughout; commits authored
   Tim Nunamaker <tnunamak@gmail.com>.

Coordination branch: `curation/lfdt-prep` (the LFDT-transfer tree; HEAD is here and
already carries all the remote-surface "excellence" work incl. viewport-match,
form-overlay, CDP backend, container-fit, punctuation fix).

## 0. Reconciliation with existing plan-of-record

This is NOT greenfield. An owner-ratified openspec change already fixes the identity
and license decisions: `openspec/changes/republish-remote-surface-as-opendatalabs`.
Key ratified facts I will honor (not re-litigate):
- Target repo: **`github.com/vana-com/remote-surface`** (owner-confirmed). Matches the
  assignment's "new vana-com repo."
- Published name: **`@opendatalabs/remote-surface`** (already the package name).
- License: **Apache-2.0** (code), **CC-BY-4.0** (docs); copyright line deferred while
  `private: true`, MUST be set before `private:false`/publish.
- Host-neutral default exports; PDPP shapes under `./reference` + `src/compat/pdpp-reference/`
  (already done on this branch).
- `engines.node: ">=24"`, `security@vana.org`, publish-readiness metadata gates.
- That openspec explicitly scoped itself to the **rename/subpath split only** and
  deferred the **repo split** — which is exactly this assignment.

## 1. The dependency seam (verified)

Consumers of `@opendatalabs/remote-surface`, resolved via `workspace:*`:
- `reference-implementation/` — ~18 import sites (runtime, server, streaming, tests):
  browser-surface leases, neko allocator, streaming routes/sessions, run-coordinator.
- `apps/console/` — ~14 sites, all under `syncs/[runId]/stream/`: stream-viewer,
  neko-client, geometry/visual-quality/clipboard/viewport-classifier.
- `apps/site/` — declared dep in package.json.
- Workspace `package.json` deps in all three consumers use `"workspace:*"`.

The seam is clean: `workspace:*` is the single swap-point. No consumer reaches into
`packages/remote-surface/src/**` by relative path (all go through the package name /
its subpath exports) — confirmed by grep. This is what makes "consume as a published
dependency" a config change, not a code rewrite.

## 2. Files that move WITH the package (RELOCATE, verified against manifest)

From `tmp/workstreams/gemini-survey/manifest/disposition.jsonl`, class=RELOCATE,
note="remote-surface repo" — **12 files** (the 3 `docs/explorer/uat/harness/*.mjs`
RELOCATE entries are flagged for `tests/e2e/`, a DIFFERENT destination — NOT ours):

- `reference-implementation/scripts/stealth/` — README, `fingerprint-probe.ts`,
  `patchright-canary.ts`, `turnstile-check.ts` (4)
- `scripts/phone/` — README, `find-and-tap.sh`, `open-url.sh`, `screenshot.sh`,
  `tap.sh`, `wait-for-telemetry.sh` (6)
- `scripts/inspect-browser-run.mjs` (1)
- `scripts/perf/browser-bench.mjs` (1)

Verified: **none of these import `reference-implementation`/`apps`/`@pdpp/**`** — they
are self-contained browser-automation/bench/stealth tooling, safe to relocate without
dragging monorepo deps. (`browser-bench-*.json` in `perf-results/` are generated
artifacts — leave behind / gitignore, don't relocate.)

Also moving (already in `packages/remote-surface/`, just travels with the dir):
docs `docs/remote-surface-*.md`, design briefs, the two new openspec changes
(container-fit, viewport-match), the standalone-audit + ux-onboarding research docs,
and `.github/workflows/remote-surface.yml` (becomes the new repo's primary CI).

## 3. Extraction sequence (smallest-risk first; each step independently verifiable)

**Phase A — finish making it self-contained IN-PLACE (no repo yet, reversible):**
1. Land the ratified `republish-*` openspec deltas that aren't done yet: verify
   `validate-package.mjs` reference-token allowlist is `dist/reference/**` only; add
   `LICENSE` (Apache-2.0, placeholder copyright) + `LICENSE-docs` (CC-BY-4.0); fill
   publish metadata (`repository`→vana-com/remote-surface, `bugs`, `homepage`,
   `keywords`, `publishConfig.access:"public"`). Package still `private:true`.
2. Move the 12 RELOCATE scripts INTO `packages/remote-surface/` (e.g. `tools/phone/`,
   `tools/stealth/`, `tools/bench/`) so they physically live with the package before
   the repo cut. Fix any in-repo references to their old paths (grep first). Keep them
   runnable. This de-risks the cut: the package dir becomes the complete unit.
3. Full gate green: `pnpm --filter @opendatalabs/remote-surface verify`, all consumers
   still build/test, `playground:test` (5 specs) + unit (268) green.

**Phase B — cut the repo (the irreversible step; done in a worktree/mirror, not destructive to pdpp):**
4. Create the new repo content by `git subtree split --prefix=packages/remote-surface`
   (preserves the package's own history) into a fresh tree; graft the 12 relocated
   scripts (already inside the prefix after Phase A, so they come for free).
5. Stand it up as a standalone repo: root `package.json` (drop `workspace:*` internal
   refs, pin real dep versions), root README (promote the package README + testing
   guide + playground), root CI (the path-scoped workflow becomes the repo's main
   CI: typecheck+lint+test+build+pack-validate; add playground Playwright job).
6. Push to `github.com/vana-com/remote-surface`. Do NOT `npm publish` yet — that's an
   owner-gated step (copyright line + `private:false` flip per the openspec).

**Phase C — make pdpp consume it as a dependency (reversible, gated on B):**
7. In pdpp, replace the `packages/remote-surface/` workspace package with a normal
   dependency on the published (or, pre-publish, a git/tarball-pinned) version in the
   three consumers' `package.json`. Remove the workspace package dir.
8. **Graceful degradation** (assignment requirement): remote-surface is only used by
   the browser-streaming path. Gate its consumption so pdpp builds/runs when the dep
   is absent — a thin internal `browser-surface-optional` shim that lazy-imports and,
   if the module is missing, disables streaming with a clear "browser surface
   unavailable" status rather than a hard crash. Prove by building pdpp with the dep
   removed.
9. Full pdpp gate green with the external dep; `reference-stack.sh verify` for the
   streaming path.

## 4. Coordination against `curation/lfdt-prep`

`lfdt-prep` is the LFDT-transfer tree and is HEAD. Risks + handling:
- The repo cut (Phase B `subtree split`) is READ-ONLY on pdpp — it doesn't modify
  `lfdt-prep`. Only Phase C (removing the workspace pkg, swapping to external dep)
  mutates the tree, and that should land as its own reviewable commit series ON a
  branch off `lfdt-prep`, not directly, so LFDT curation can gate it.
- The manifest's RELOCATE dispositions are the curation source of truth — moving those
  12 files OUT of pdpp is consistent with LFDT intent (they're flagged to leave).
- Open question for owner: does LFDT want the workspace package GONE from the transfer
  tree (full extraction) or KEPT as workspace + ALSO mirrored to the new repo for one
  transition release? The openspec says "keep developing inside the monorepo" for the
  rename tranche — so Phase C's timing (when pdpp stops vendoring it) is an
  owner/LFDT call, not mine to assume.

## 5. What I will NOT do without explicit approval
- Cut the repo / push to vana-com (Phase B).
- `npm publish` (owner-gated: copyright line + private:false).
- Remove the workspace package from `lfdt-prep` (Phase C step 7) — needs LFDT sign-off.
- Anything destructive to the transfer tree.

## 6. Immediately safe next actions (if approved to proceed on low-risk prep)
Phase A only — self-contained-in-place: metadata/license fill, relocate the 12 scripts
into the package dir, keep `private:true`. Fully reversible, no repo cut, gates stay
green. Recommend doing A, reporting, then pausing for the B/C go-decision.
