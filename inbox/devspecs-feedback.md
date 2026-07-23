# devspecs (`ds`) trial — agent feedback ledger

**Purpose:** Tim is trialing the `devspecs` CLI (`ds`, by Brennan Nunamaker) for ~1–2 weeks
to decide whether it earns a place in the workflow, and to send the maintainer real
usage feedback. Agents do the trialing and the logging so Tim doesn't have to think
about it. After ~2 weeks Tim reviews this file and shares the digest with Brennan.

**Trial started:** 2026-06-13
**Version under test:** run `ds version` and note it in your entry if it changed.
**Instructions for agents:** see the "Trialing devspecs" section in `ai/AGENTS.md`.

---

## How to log

When you actually used `ds` on a real task, append one entry below. Keep it short and
honest — failures and friction are the most valuable signal for the maintainer. Don't
log if you didn't really use it (no filler entries).

Template:

```
### YYYY-MM-DD — <one-line what you were doing>
- **Command(s):** the ds commands you ran
- **Worked / didn't:** what happened, verbatim errors if any
- **vs. doing it by hand:** did it save effort, cost effort, or wash out?
- **Would use again here?:** yes / no / only-if
- **Maintainer-facing note:** the one thing Brennan should know (bug, rough edge, missing feature, or a genuine win)
```

---

## Entries

<!-- newest first; append above this comment is fine, or just add to the bottom -->

### 2026-06-15 — orient in pdpp (ds v1.0.1): map / find / context as a grep alternative
- **Command(s):** `ds version`, `ds map`, `ds find "grant-scoped bearer token limits every result"`, `ds context e5439fbb1` — run in `~/code/pdpp` (already `ds init`'d). Compared against `rg -l` for the same question.
- **Worked / didn't:**
  - `ds map` — **genuine win.** Indexed 3798 chunks in a few seconds, then synthesized labeled "areas" (e.g. "Run Generation Fencing Token", "Controller Self Heal Satisfaction") from source/test/doc co-location + *git signal*, each with key files, a recent-commit line, and a suggested `ds find` follow-up. Nothing grep gives you — this is the orient artifact's real value.
  - `ds find` — **mixed.** For "where is the grant-scoped bearer limit enforced," it returned a ranked working set (7 artifacts across impl/test roles) + 3 relevant commits with rationale, which is richer than a file list. BUT it pointed at `reference-implementation/server/{index,auth}.js` and `runtime/index.js` — the *authorization-server / legacy* surface — and **missed `packages/mcp-server/src/{tools,server,credentials}.js`**, which is where the MCP read-surface bearer limit actually lives. Plain `rg -l -i "bearer|grant.*scope"` found the mcp-server files instantly (0.015s) and `ds find` did not surface them at all. So for *this* lookup, grep was both faster and more correct on the specific subsystem; `ds find` gave better *narrative/commit context* but worse *recall* on the true target.
  - `ds context <id>` — clean: packs the file with an "Instructions for Agent / preserve acceptance criteria / record deviations" header. Good framing for handing one file to a worker; for a known file it's just `cat` + boilerplate.
- **vs. doing it by hand:** `ds map` saved real effort and surfaced structure I wouldn't have assembled from grep. `ds find` cost a little (slower than rg, and its ranking steered me toward the wrong subsystem — I'd have over-trusted it without a grep cross-check). `ds context` was a wash for a file I already knew.
- **Would use again here?:** only-if — `ds map` yes (great first-orient on an unfamiliar repo); `ds find` only as a *complement* to grep, not a replacement, until recall improves; `ds context` only when packaging a handoff.
- **Maintainer-facing note (Brennan):** Three things, and note #1 corrects my own first read.
  1. **`ds find` is query-phrasing-brittle (ranking, NOT scope/recall).** First I thought it couldn't *reach* `packages/mcp-server/src/*` — wrong. When I queried `"rs-client read surface mcp tools"` it returned `tools.js` + `rs-client.js` + the right commit immediately. The code IS indexed (the global DB has it; `config.yaml`'s narrow `sources` does not restrict `find`'s reach). The real problem: my *behavioral* query `"grant-scoped bearer token limits"` ranked the auth-server JS high and surfaced `mcp-server` **not at all**, yet a query naming the unique symbol `rs-client` found it instantly. So `find` only nailed the subsystem once I already knew a symbol from it — which is the worst failure mode for a discovery tool: most wrong exactly when the user is most dependent (they don't yet know where the code is). Suggest testing find with *intent-phrased* queries (how someone asks before they know the answer), not just symbol-ish ones, and looking at why a behaviorally-relevant file drops out of the top-N when a near-synonym query includes it.
  2. **The `ds map` "Evidence" line reads as misleadingly tiny.** On pdpp (4792 tracked files: 1827 md / 1278 src / 783 tests) `ds map` printed `Evidence: 2 markdown, 34 source, 13 tests` — i.e. ~0.1% / 2.6% / 1.7%. Tim flagged it: "<1% of the files?" That count reflects the narrow registered `sources` paths in `.devspecs/config.yaml` (openspec/adr/docs only), NOT the indexed corpus — but it's printed right under `Index updated (3798 new)` (which is *global* cross-repo churn in the 520MB `~/.devspecs/devspecs.db`), so the two adjacent numbers imply "looked at a lot" when the repo-specific evidence is a sliver. Two confusions to fix: (a) the evidence count should either reflect what map actually reasoned over or be labeled "registered spec sources, not full repo"; (b) `3798 new` is global, not this-repo — labeling it per-repo would mislead.
  3. **`ds map` is still the standout** — the git-signal-derived area labels + suggested `ds find` follow-ups are clearly better than DIY orientation. The value is real; it's the *evidence transparency* and *find ranking* that need work, not the core idea.
  (No errors, no stale-DB issue; v1.0.1 = latest, ran cleanly. ~8 min testing. Global DB is 520MB / 497M across all init'd repos — worth a retention note someday.)

### 2026-06-15 — Tim's own first-use reactions (verbatim signal, human consumer)
This is Tim reading `ds map` + `ds find` output cold, as a human. The friction is about *consumability by a person*, which is the most valuable signal — keep it unfiltered.
- **`ds map` — ranks by recency, presents as architecture.** Tim on the #1 area ("Connector Runtime Cascade Guard"): *"why is this the #1 code area, is it too narrow? tbh I don't even remember what it is. is it because it was implemented recently? would someone onboarding to this really care to learn about this as the first area? then I stopped reading."* → Two real issues: (a) "Detected areas" is ordered by **git recency**, not architectural importance, but the framing ("Repo map", "Detected areas") promises an onboarding/architecture view — mismatch. A newcomer wants the load-bearing subsystems, not the latest churn. (b) The area **label is a commit-message paraphrase, not a description** — it names the thing without explaining it, so it can't orient someone who doesn't already know it ("I don't even remember what it is" is the tell). He stopped reading at #1 — so whatever's most important to convey has to win the first 3 lines.
- **`ds find "where is version churn measured?"` — correct content, unnavigable format for a human.** Tim: *"this is super dense. okay there are a couple of commits that are clearly related. a few implementation surfaces nice. i am wondering if there are additional commits or surfaces I might be missing in the list? tests... I don't care about but okay maybe some ppl would. artifacts, okay yeah nice. oh now i see more commits at the bottom and realize the first ones were 'decisions'. tbh this all seems fine but i dont know what to do with it? I can't exactly navigate these things. an agent could, I guess. what is the maintainer's intention for how I am supposed to consume this information?"* → The decisive question is his last one: **who is the consumer?** The output (short IDs, role groups, "Related families kept for verbose/JSON", evidence counts) is an **agent-fetch payload**, not a human reading view — and `ds find` is a human-typed command, so it invites a category error. Specific fixable friction: (1) **reading-order vs numbering disagree** — "Implementation surface" is numbered 1–3 but printed *after* "Background / decisions" (numbered 4–5), so Tim parsed it backwards ("oh now I realize the first ones were decisions"). (2) **No coverage signal** — his "am I missing commits/surfaces?" has no answer in the output; a discovery tool should say what it excluded / how confident the recall is, because "what am I NOT seeing" is the scariest gap. (3) **Everything is equal visual weight** — decisions, impl, tests, related families, commits all compete; the one actionable thing (the 2 impl files) should be hoisted with a one-line "the answer is X, open Y." (4) Tests ranked prominently but he didn't want them ("tests... I don't care about") — role ordering may need to default to impl-first for human reads.
- **Synthesis for Brennan:** the tool's content is *right* (find returned the correct version-churn files; map's areas are real). The gap is **consumption design + intended-audience clarity**. Either (a) lean fully into "this is for agents" and add a thin human-facing `--summary`/TL;DR mode that says "answer: these 2 files; here's the one-line why," or (b) reorder for humans: most-actionable first, label the sections by who-cares, and add a coverage/confidence footer. And decide explicitly whether `ds map` is an *onboarding/architecture* view (then rank by importance + describe areas) or a *recent-activity* view (then say so in the header). Tim literally asked "what is the maintainer's intention for how I consume this?" — that's the thing to make obvious in the output itself.
2026-06-16 — PDPP add-source dead-end fix (ds v1.0.1)
- **Command(s):** `ds map`, `ds task quick "fix add-source catalog dead-end actions"`, `ds task checkpoint 20260616-163121-fix-add-source-catalog-dead-end-actions --target A01 ...`
- **Worked / didn't:** `ds map` returned a useful orientation summary. `ds task quick` and `checkpoint` both took >30s in this worktree and left an unexpected untracked `devspecs/` directory, not `.devspecs/`.
- **vs. doing it by hand:** orientation helped a bit; task/checkpoint cost more time than it saved for this medium scoped fix.
- **Would use again here?:** only-if the task is larger or needs handoff/resume receipts.
- **Maintainer-facing note:** clarify where task receipts are written and make `task quick`/`checkpoint` return faster or stream progress; the current silence makes agents wonder if the command hung.

2026-06-16 — browser-session connect crash hotfix in pdpp (ds version not checked)
- **Command(s):** `ds task quick "fix browser-session connect page crash"` in `~/code/pdpp-waspflow-connect-crash`
- **Worked / didn't:** It eventually created task `20260616-164857-fix-browser-session-connect-page-crash` / target `A01`, but it took ~100s with no progress output after indexing 12,258 items. The packed source missed the actual crash area (`stream-viewer.tsx`) and focused on connector/browser-launch files, so I treated it as a receipt rather than task context.
- **vs. doing it by hand:** Cost effort for this P0 hotfix; direct `rg`/file reads were faster and more accurate.
- **Would use again here?:** only-if, for larger multi-slice work after the initial source targeting improves.
- **Maintainer-facing note:** `task quick` needs progress output during indexing and a way to include/override likely target paths; silent long indexing plus a wrong packed-source set makes agents second-guess whether to wait or abandon it.

2026-06-17 — store-parity spine_events index in pdpp-waspflow-perf-spine-index (ds v1.0.1)
- **Command(s):** `ds version`, `ds tldr`, `ds task quick "add store-parity spine_events composite index for aggregation and list hot paths"` in `~/code/pdpp-waspflow-perf-spine-index`.
- **Worked / didn't:** `ds tldr` returned useful workflow guidance. `ds task quick` produced no output for about 40s and was interrupted with Ctrl-C; no task receipt was created.
- **vs. doing it by hand:** cost time for this bounded DDL/test change; direct repo inspection was faster.
- **Would use again here?:** only-if there is a visible progress stream or a larger multi-slice handoff need.
- **Maintainer-facing note:** `task quick` should print early progress or an indexing phase marker; silent hangs make it hard for agents to decide whether to wait, retry, or abandon.
2026-06-17 — perf fan-in mapWithConcurrency lane (ds v1.0.1)

- **Command(s):** `ds version`, `ds task status` (mistakenly without required task id), `ds tldr`, `ds task quick "replace serial fan-in reads with bounded mapWithConcurrency"` in `~/code/pdpp-waspflow-perf-fanin`.
- **Worked / didn't:** `ds version` worked. `ds task status` returned `Error: accepts 1 arg(s), received 0` with usage, which was clear enough. `ds task quick` produced no output for about 90 seconds and had to be interrupted with Ctrl-C.
- **vs. doing it by hand:** Cost effort here; grep plus focused source reads were faster than waiting for task creation/indexing.
- **Would use again here?:** only-if there is visible progress or the task is large enough to justify waiting.
- **Maintainer-facing note:** `ds task quick` needs an immediate progress line for indexing/task creation, especially for agents; silent long-running commands look indistinguishable from a hang.
2026-06-17 — PDPP collector bounded-memory fix (ds v1.0.1)
- **Command(s):** `ds version`, `ds status`, `ds tldr`, `ds find "collector O(file) memory bounded runtime packages/polyfill-connectors local-collector"` in `~/code/pdpp-waspflow-perf-collector-oom`.
- **Worked / didn't:** `ds status` did not match the documented no-arg resume workflow: `Error: accepts 2 arg(s), received 0`. `ds tldr` was useful for recovering the current CLI shape. `ds find` did not return within a few seconds on this repo/worktree, so I interrupted it and used grep/source inspection instead.
- **vs. doing it by hand:** Cost effort on this bounded bugfix; grep got to the relevant connector files faster.
- **Would use again here?:** only-if, for larger handoff/context packaging rather than a narrow runtime fix.
- **Maintainer-facing note:** The docs/TLDR still suggest no-arg status/resume flows that the current CLI rejects, and `ds find` needs visible progress or a fast first result on large repos so agents know whether to wait.

---

**Task:** `waspflow/unity-consume-payments` — bump @opendatalabs/vana-sdk to PR #155 prerelease and consume `createEscrowGatewayClient`/`syncEscrowBalance` in Account /developers (2026-06-19)
- **ds commands used:** opened task earlier in the session (20260619-181209-port-builder-escrow-funding-to-waspflow-unity-co) but after context compaction the task ID was lost; the devspecs task wasn't visible in the resumed session since the DB lives in the old worktree, not the reset one.
- **Worked / didn't:** The task tracking friction was real: resetting the branch (git checkout -B from origin/dev) detached the context from the devspecs task. `ds task status` would have pointed to the old worktree. The slice+checkpoint model is best when the branch stays stable; it gets confused during rebase/reset cycles.
- **vs. doing it by hand:** No advantage here — the task was too short (one package bump + import update) and the worktree reset meant the checkpoint history was stale.
- **Would use again here?:** No — too short, plus the worktree was reset mid-task which breaks checkpoint continuity.
- **Maintainer-facing note:** When a branch is force-reset (git checkout -B), devspecs has no way to know and its task/checkpoint state goes stale silently. A `ds task orphan-check` or a warning when the tracked branch diverges from the checkpoint would help.

2026-06-22 — Clawmeter Windows packaging end-state implementation (ds v1.1.0)
- **Command(s):** `ds task quick "define and implement ideal Windows packaging for Clawmeter" --json`, `ds task checkpoint 20260622-233805-define-and-implement-ideal-windows-packaging-for --target A01 ...`, `ds task finish A01 --decision promote`.
- **Worked / didn't:** Task creation worked and produced a useful durable receipt. I first tried `ds task checkpoint A01 ...` and then the full task id with a custom target; both failed. The successful shape required the full task id plus target `A01`.
- **vs. doing it by hand:** Useful for preserving a validation receipt after a multi-file packaging change, but the id/target distinction cost a couple retries.
- **Would use again here?:** yes, for multi-file release/packaging work where checkpoints are valuable.
- **Maintainer-facing note:** The CLI should print the exact checkpoint command shape after `task quick`, including the full task id and valid target id; short id `A01` looks like a task handle but is only the slice target.
2026-06-24 — PDPP record-components PR lane (ds current)

- **Command(s):** `ds tldr`; `ds task "land RecordIdentity Explore cell" --slice "replay shared RecordIdentity patch onto fresh origin/main" --slice "validate THE LENS honesty invariants and gate tests" --slice "push branch and open PR"` in `/home/tnunamak/.tmp/pdpp-record-components`.
- **Worked / didn't:** `ds tldr` was useful. `ds task ...` printed `Task auto-index progress: discovered 4770 candidate file(s); skipped 11 ignored/heavy directories...` and then produced no additional output for roughly 90 seconds. I interrupted with Ctrl-C and proceeded by hand.
- **vs. doing it by hand:** cost effort on this lane; normal git/rg/pnpm workflow was faster once the task stalled.
- **Would use again:** only-if, for this repo, until task creation gives regular progress output or a bounded indexing timeout.
- **Maintainer-facing note:** task creation needs a heartbeat after the initial indexing line, or agents cannot distinguish "still indexing" from a hung command.

2026-06-24 — PDPP Explore sort frontend lane (ds v1.1.0)

- **Command(s):** `ds version`, mistaken `ds task status` with no task id, `ds task quick "land Explore declared-field sort frontend lane without reachability lie"`, `ds task checkpoint 20260624-150052-land-explore-declared-field-sort-frontend-lane-w --target A01 ...`.
- **Worked / didn't:** The no-arg `ds task status` failed with clear usage. `ds task quick` completed but first printed `scan failed while walking /home/tnunamak/code/pdpp` and still created a task/checkpoint. The generated task picked a plausible source file, but the actual sequencing decision came from the human brief and THE LENS, not from ds context.
- **vs. doing it by hand:** Mild cost; useful as a receipt after validation, not useful for deciding the foundation-PR sequencing.
- **Would use again here?:** yes for checkpoints on multi-step lanes, but not as the primary context source for highly sequenced handoffs.
- **Maintainer-facing note:** If scanning fails but task creation proceeds, the CLI should show the specific path/error and label the resulting context as degraded. Otherwise agents cannot tell how much to trust the packed source/risk cards.
2026-06-24 — BUI-587 cross-repo testnet switch (ds v1.1.x)

- **Command(s):** `ds task "BUI-587 testnet switch" --slice ...` in `unity-surfaces`, then `ds task checkpoint 20260624-154727-bui-587-testnet-switch --target A03 ...` after implementation landed in a separate `vana-sdk` worktree.
- **Worked / didn't:** Task creation worked and the checkpoint receipt was useful. The initial task auto-indexed for ~35s, which was acceptable but still long enough that I had to keep working in parallel. The awkward part was cross-repo reality: the task lived under the `unity-surfaces` worktree, but discovery proved the actual patch belonged in `vana-sdk`; checkpointing absolute paths worked but felt semantically odd.
- **vs. doing it by hand:** Useful as a durable receipt for a multi-step, cross-repo task; not useful for choosing the repo boundary, which came from source inspection and subagent scouting.
- **Would use again here?:** yes for receipt/checkpointing, but only after the owning repo is known when possible.
- **Maintainer-facing note:** Cross-repo tasks need a first-class way to record “implementation moved to repo/worktree X” so the task state does not imply the original repo owns the change.

2026-06-24 — PDPP density toggle rebuild (ds v1.1.x)

- **Command(s):** `ds task quick "rebuild S-scope density toggle on fresh origin/main"` in `/home/tnunamak/.tmp/pdpp-density-toggle-rebuild`.
- **Worked / didn't:** Printed `Task auto-index progress: discovered 4781 candidate file(s); skipped 11 ignored/heavy directories...`, then produced no further output for about 90 seconds. I interrupted with Ctrl-C and proceeded with direct repo inspection.
- **vs. doing it by hand:** Cost effort for this S-scope PR lane; the human brief plus targeted source reads were faster than waiting for task creation.
- **Would use again here?:** only-if the lane is large enough to amortize indexing, or if task creation gives incremental output/checkpoint value before the first minute.
- **Maintainer-facing note:** `ds task quick` now shows an initial indexing line, which is better than older silent waits, but it still needs periodic progress or an early usable task id so agents can checkpoint/continue instead of guessing whether to interrupt.
2026-06-24 — data-gateway escrow finalized accounting incident (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick "fix settled escrow payments counted as authorized balance"` in `~/code/data-gateway-escrow-accounting`.
- **Worked / didn't:** `ds task quick` completed in a few seconds after indexing and correctly pointed at `api/v1/escrow/pay.ts`, `api/v1/escrow/settle.ts`, and `tests/escrow-pay.test.ts`. It created an untracked `devspecs/` directory in the repo, even though the local guidance says devspecs state should be globally ignored.
- **vs. doing it by hand:** Mildly useful as a context sanity check, but the actual root cause was faster to verify with source inspection because the incident already named the suspect fields.
- **Would use again here?:** only for a longer incident where preserving a checkpoint receipt is worth the extra generated state.
- **Maintainer-facing note:** The CLI should either keep generated task state under the documented ignored path or clearly warn when it is writing an unignored `devspecs/` directory into the worktree.

2026-06-24 — BUI-587 unity-surfaces resume check (ds v1.1.x)

- **Command(s):** `ds task status` in `/home/tnunamak/code/.worktrees/unity-surfaces-bui587`.
- **Worked / didn't:** Failed with `Error: accepts 1 arg(s), received 0`. The usage is clear, but there is no obvious no-arg way for a resumed agent to discover the active/relevant task id from the current repo/worktree.
- **vs. doing it by hand:** No advantage for this resume point; `git status`, Linear context, and targeted greps were faster.
- **Would use again here?:** only if the task id is preserved in the handoff or a no-arg status/list command exists.
- **Maintainer-facing note:** A no-arg `ds task status` or `ds task list --current-worktree` would help agents recover after compaction or handoff without needing task ids from chat history.

2026-06-26 — retired the `ds-update-check` SessionStart hook

- The auto-update-nudge hook (`bin/.local/bin/ds-update-check`, wired into Claude
  + Gemini SessionStart) was a temporary trial scaffold; the trial is now past its
  ~1–2 week window (started 2026-06-13). Removed the script and both hook entries.
- Not folded into `setup.sh`: `setup.sh` doesn't install `ds` (it lives in
  `/usr/local/bin` via devspecs' own `install.sh`), so there was no dotfiles update
  flow to fold it into. To check for a newer `ds`, run its `install.sh` again.
- The dogfooding feedback path (`dogfood-feedback-nudge` + this ledger) stays.

2026-07-23 — PDPP shared release-matrix lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then a three-slice `ds task "implement shared release matrix authority for CLI and read-core candidates" --slice ...`; attempted `ds task status` and `ds task list`.
- **Worked / didn't:** the explicit multi-slice command produced an inspectable task tree, but creation emitted only index progress, so the task id had to be recovered from `devspecs/tasks`. Both no-argument status and list were non-obvious (status rejected missing id; list created an unrelated `list` task). The generated context had no ranked implementation/test files for an explicit package/runtime request and left an unignored `devspecs/` tree in the clean worktree; direct package reports, scripts, and tests were authoritative.
- **Maintainer-facing note:** print the task id/path after creation, make list read-only and status discover the sole active task, preserve exact package paths from the request, and keep generated task state outside or ignored by source worktrees.

2026-07-22 — Context Gateway x402 escrow-read lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task "Implement x402 escrow payments for Personal Server reads" --slice` and `ds task status`.
- **Worked / didn't:** `tldr` documented the slice workflow, but task creation rejected the initially supplied bare `--slice` flag and a follow-up status call rejected the no-argument form. Task creation also emitted only indexing progress, so no task id or usable receipt was available to checkpoint.
- **Maintainer-facing note:** show a compact example for required repeatable flags, print the created task id/path after indexing, and let `status` select a sole current task.

2026-07-22 — waspflow-fedgui-e2e Wave H lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds map`, then `ds task "Implement Federation Wave H ..." --slice ...`.
- **Worked / didn't:** `ds task` created a usable task directory and slices, but its scan simultaneously failed with `database is locked (5) (SQLITE_BUSY)`. The partial task context was useful; the success-like artifact plus failed scan is ambiguous and required direct source/test inspection.
- **Maintainer-facing note:** retry or clearly distinguish an incomplete index from a successfully packed task, with a concrete lock-recovery hint.

2026-07-22 — Pramana incomplete-result ingest gate (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "fix: prevent incomplete and needs-human Pramana reports from being ingested"`.
- **Worked / didn't:** `tldr` made the intended hotfix flow clear, but task creation reported `scan failed ... database is locked (5) (SQLITE_BUSY)` while still leaving an unignored `devspecs/` task tree in the clean worktree. The partial artifacts were not trustworthy for source discovery, so direct source/test inspection supplied the implementation boundary and evidence.
- **Maintainer-facing note:** on a scan lock, either retry or create no task artifacts; if partial artifacts are intentionally retained, label them incomplete and make them ignored by default.

2026-07-16 — remote-surface capabilities R4/R2 lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then two `ds task quick "Make remote-surface backend capabilities honest and backend-symmetric"` invocations and `ds task prompt`.
- **Worked / didn't:** the second task produced a usable id and plan, but each `task quick` initially printed only `Task index updated ...` while creating an unignored `devspecs/` tree. The generated plan proposed client/adapters outside the task’s explicit allowed surface and missed the named CDP/neko descriptors plus protocol capability type; direct `rg`, source reads, and tests found the real implementation boundary. A no-argument `ds task status` also failed because the previously undisclosed task id is mandatory.
- **vs. doing it by hand:** negative for discovery on this precise, named-file capability correction; direct inspection was authoritative. The plan receipt did make the retrieval miss easy to document.
- **Would use again here?:** only for a final checkpoint after the implementation, if generated state is outside the worktree or ignored.
- **Maintainer-facing note:** elevate exact file paths and symbols from a task brief over inferred client surfaces, always print the new task id/path, provide a current-task status default, and prevent task artifacts from dirtying or lint-breaking a clean worktree.

2026-07-16 — ephemeral browser runtime-health implementation lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task status`, and `ds task refresh`.
- **Worked / didn't:** `ds task refresh` produced useful slice receipts, but `ds task status` without an id failed instead of selecting the only current task. The tool also created an unignored `devspecs/` artifact directory in the implementation worktree.
- **vs. doing it by hand:** useful as a compact checkpoint receipt; direct source/test inspection remained the authority for cross-lane Luna contracts and owner steering.
- **Maintainer-facing note:** default status to the active/sole task and ensure generated task state is ignored or can be directed outside the source worktree.

2026-07-16 — mobile overlay clipping implementation lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick`, `ds task status`, and `ds task checkpoint`.
- **Worked / didn't:** task creation and the validated checkpoint were useful receipts, but `task quick` initially printed only the index update rather than the new task id, `task status` without that id failed, and every artifact was left in an unignored `devspecs/` directory in the source worktree.
- **vs. doing it by hand:** useful only for the final evidence receipt; direct source, geometry-hook, and test inspection found the actual renderer boundary.
- **Maintainer-facing note:** print the new task id immediately, make status default to the sole active task, and keep generated artifacts outside or ignored by the implementation worktree.

2026-07-16 — remote-surface mobile UAT lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick`, `ds task checkpoint`, and `ds task finish`.
- **Worked / didn't:** checkpoint and finish recorded the implementation evidence cleanly. `task quick` again printed only `Task index updated` even though it created a task, so the id was not available for `status`; a no-argument `status` then failed. Its unignored `devspecs/` directory also had to be removed before handoff.
- **vs. doing it by hand:** useful for the final receipt only; source inspection and the live WebSocket probe supplied the actual evidence.
- **Maintainer-facing note:** print the task id from `task quick`, let `status` select a sole active task, and default generated task state outside or ignored by source worktrees.

2026-07-16 — local-ingest throughput replacement gate (ds v1.1.x)

- **Command(s):** `ds task status` and `ds task checkpoint` across a five-slice implementation/verification task.
- **Worked / didn't:** status and the final A04 checkpoint are useful compact receipts. Checkpoint rejected an intuitive `--evidence` flag, then rejected descriptive text passed to `--next-decision`; discovering that evidence belongs in `--description` and that next-decision is an enum took two failed invocations. Generated state again remained as an unignored `devspecs/` directory.
- **vs. doing it by hand:** the slice ledger helped preserve the long-running gate sequence, but direct test output and immutable Git commits remained the correctness authority.
- **Maintainer-facing note:** add `--evidence` as an alias for `--description`, clarify in the error that `--next-decision` is an enum while prose belongs in `--note`, and keep generated state outside or ignored by source worktrees.

2026-07-18 — ChatGPT idle-session repair classification lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick`, `ds task show`, then a validated `ds task checkpoint`.
- **Worked / didn't:** the checkpoint captured the source files and test commands, but `task quick` initially printed only indexing progress while creating an unignored `devspecs/` tree. Its plan named no primary implementation or test files, so direct inspection found `connection-health.ts`, `ref-control.ts`, and their tests. The follow-up `ds task finish ... --decision promote` failed with `all task targets are terminal` immediately after a checkpoint with that same promote decision.
- **vs. doing it by hand:** the final receipt was useful; source/test discovery was not, and the generated task directory dirtied the worktree.
- **Would use again here?:** only for an end-of-task receipt if artifacts are ignored or stored outside the worktree.
- **Maintainer-facing note:** print the task id/path from `task quick`, rank exact source/test files for a named defect, make `finish` idempotent after a terminal checkpoint, and keep generated artifacts out of tracked worktrees.

2026-07-18 — my-little-psychosis ingest hotfix lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "fix approval-to-ingest double status read"`.
- **Worked / didn't:** the task indexed the relevant ingest route and controller, but again printed only `Task index updated` instead of the created task id/path, left an unignored `devspecs/` tree in the clean hotfix worktree, and ranked an unrelated pipeline tool as an expected implementation surface. The production incident evidence already named the authoritative boundary, so direct regression tests and source inspection were faster and safer.
- **Maintainer-facing note:** print the task id/path, keep generated state outside or ignored by source worktrees, and weight exact incident-named files above broad lexical matches.

2026-07-18 — pramana connector-matrix lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds map`.
- **Worked / didn't:** `tldr` was useful, but `ds map` reported a SQLite `database is locked` scan failure before producing a partial stale map. No task receipt was created, so direct source/workflow/identity reads and deterministic tests supplied the evidence.
- **Maintainer-facing note:** make the SQLite index transaction retry or report the lock owner/repair step before emitting a partial map; a failed refresh should not make the map look current.

2026-07-18 — my-little-psychosis OOM/status integration lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick "integrate production ingest hotfix with single Vana status snapshot while preserving OOM bounds"`, then a validated `ds task checkpoint`.
- **Worked / didn't:** the checkpoint captured the five status files and full unit/bench/typecheck/build/E2E evidence, but `task quick` again printed only `Task index updated` while creating an unignored `devspecs/` tree. The generated plan ranked `app/machine/MachineClient.tsx` and several unrelated Vana routes as expected change surfaces even though the incident brief explicitly prohibited MachineClient changes and named the authoritative five-file status surface.
- **vs. doing it by hand:** useful as a final receipt, negative for discovery on an exact production-hotfix integration; direct source-worktree diffing, installed-SDK inspection, and the deterministic route regression found the safe boundary.
- **Maintainer-facing note:** print the new task id/path, keep generated state outside or ignored by implementation worktrees, and treat explicit allowed/prohibited paths in the task brief as hard retrieval constraints rather than lexical hints.

2026-07-18 — Pramana full-docs reliability coverage lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds map`, and task/slice discovery during initial repository orientation.
- **Worked / didn't:** `tldr` was useful, but the index repeatedly failed with `database is locked` / scan-transaction errors. The tool also created an unignored `devspecs/` tree in Pramana; it broke the repository Biome gate and had to be moved recoverably to `~/.tmp/pramana-agent-artifacts/` before verification. Direct document/source reads and deterministic tests supplied the actual evidence.
- **Maintainer-facing note:** make locking retryable or name the lock owner/repair command, and never emit generated state into a tracked worktree unless it is ignored by default.

2026-07-20 — Pramana BUI-739 desktop + developer-journey implementation lane (ds v1.1.x)

- **Command(s):** `ds init --yes`, then `ds task "Land BUI-739 desktop CI and per-run build-app coverage" --slice ...`.
- **Worked / didn't:** initialization created the Codex helper files successfully, but the first multi-slice task failed before a receipt with `database is locked (5)` while beginning its scan transaction. It left an unignored `.agents/` directory in the otherwise clean Pramana worktree.
- **vs. doing it by hand:** negative for this implementation start; the existing design brief, research index, scenarios, workflow, and tests were immediately inspectable and authoritative.
- **Maintainer-facing note:** retry/serialize the scan transaction (or print lock owner and safe recovery action) and keep generated Codex helpers outside the project or ignored by default.

2026-07-19 — PDPP Remote Surface causal hotfix lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick`, and a validated `ds task checkpoint`.
- **Worked / didn't:** the checkpoint made a compact receipt, but task creation produced no task id in output, wrote an unignored `devspecs/` tree into the clean worktree, and its inferred primary file was an unrelated allocator server. Direct commit-range tracing plus an isolated n.eko reproduction found the actual adapter/settle seam.
- **Maintainer-facing note:** for an incident brief with explicit commits and source paths, rank those constraints above lexical expansion; keep generated state outside or ignored by the source worktree.

2026-07-19 — PDPP desktop stream session-identity lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick` for the bounded viewer regression.
- **Worked / didn't:** the tool created a task receipt, but `task quick` printed only an index update instead of the task id and left an unignored `devspecs/` directory in an otherwise clean isolated worktree. The supplied evidence already named the viewer/session seam, so direct source and focused tests were the reliable path.
- **Maintainer-facing note:** always print the created task id/path and keep generated task state outside the source worktree or ignored by default.

2026-07-21 — PDPP historical read-authority slice (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick`, then attempted `ds task status`.
- **Worked / didn't:** `task quick` created a useful bounded receipt but printed only indexing progress, so the task id had to be recovered by searching the new unignored `devspecs/` tree. `ds task status` then rejected the no-argument form despite there being one new task; the usage string showed that an id was required.
- **Maintainer-facing note:** print the created task id/path from `task quick`, allow `task status` to select the sole active task, and keep generated task state out of source worktrees by default.

2026-07-21 — PDPP historical-evidence integration lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task ... --slice`, then attempted `ds task status`.
- **Worked / didn't:** the slice task produced a bounded task tree, but creation printed indexing progress rather than the task id/path and left that tree unignored in the clean integration worktree. `ds task status` without an id rejected the command, so direct commit, diff, and test evidence remained the authoritative integration record.
- **Maintainer-facing note:** always print the new task id/path, let status choose a sole active task, and default generated task artifacts outside or ignored by the source worktree.

2026-07-21 — Pramana Attempt Envelope / fail-latch lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task "Implement TIER-2 immutable Attempt Envelope and ingest fail-latch for BUI-739" --slice ...` and `ds task status <recovered-id>`.
- **Worked / didn't:** task creation only printed indexing progress and left an empty, unignored task directory; the recovered id had no `task.json`, so status and the required validation checkpoint could not run. Direct spec/source review and deterministic tests supplied the implementation evidence.
- **Maintainer-facing note:** do not create a task directory until its manifest is durable; print the task id/path on creation and make the error explain an incomplete task receipt rather than leaving an unrecoverable empty directory.

2026-07-21 — Unity Pramana Tier-1 viewer lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick`, checkpoint, and finish.
- **Worked / didn't:** the checkpoint recorded the final files and gates, but task creation printed only indexing progress and left an unignored `devspecs/` tree. Broad lexical retrieval also ranked unrelated Desktop and data-request files despite the task naming the Pramana viewer path.
- **Maintainer-facing note:** print the task id/path, keep task artifacts outside source worktrees or ignored, and treat an explicit path boundary as a hard retrieval constraint.

2026-07-21 — Waspflow Federation sbx-preflight lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "Implement Federation sbx install preflight doctor and daemon setup_required state"`.
- **Worked / didn't:** `tldr` gave the expected bounded-task workflow, but task creation failed during its automatic scan with `database is locked (5)` before producing a usable receipt. It still left an unignored `devspecs/` directory in the clean Waspflow worktree.
- **vs. doing it by hand:** negative for this named, source-directed implementation; direct backend/CLI/daemon/test reads were immediately authoritative.
- **Maintainer-facing note:** retry or serialize the SQLite scan transaction, and do not create task artifacts in a source worktree until the task receipt is durable (or ignore them by default).

2026-07-21 — Waspflow Federation task-discovery lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds map`, `ds task "build federation task discovery and contributor-selected claims" --slice ...`, then three validation checkpoints.
- **Worked / didn't:** the task and checkpoints were usable after creation, but both `ds map` and task creation reported `database is locked (5)` during automatic scanning. Creation still wrote an unignored `devspecs/` directory into the clean worktree, and the output omitted the task id/path; it had to be recovered from the generated directory. Direct source/test inspection supplied the authoritative implementation boundary.
- **vs. doing it by hand:** checkpoints gave a compact receipt; discovery was negative for this explicitly path-directed change because the partial map was stale and the lock error gave no owner or safe retry guidance.
- **Maintainer-facing note:** serialize/retry SQLite scans or report the lock owner and a recovery command, print the created task id/path, and store generated task state outside source worktrees (or ignore it by default).

2026-07-21 — Waspflow Federation browser-auth correction lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick`, checkpoint, and finish.
- **Worked / didn't:** the checkpoint successfully recorded the exact task slice and validation evidence, but task creation emitted no task id/path and wrote an unignored `devspecs/` tree into the clean worktree. `ds task finish` also returned no visible confirmation and left task status as `packed`, so the receipt had to be inspected directly; the generated tree was removed before the requested code commit.
- **vs. doing it by hand:** compact checkpoint was useful after discovering the id; direct source/test tracing remained the reliable implementation record for the explicitly named auth files.
- **Maintainer-facing note:** print created/finished task state, transition the task status on finish, and keep generated receipts outside or ignored by source worktrees.

2026-07-21 — Waspflow Federation packaging lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds init --yes`, then `ds task "Build isolated federation packaging artifacts" --slice ...`.
- **Worked / didn't:** `tldr` gave the intended slice/checkpoint workflow, but initialization/task creation produced no usable task receipt or visible task id and wrote an unignored `devspecs/` directory into an otherwise clean package worktree. It had to be moved to trash before the packaging diff could be handed off.
- **vs. doing it by hand:** negative for this bounded, source-directed packaging task; direct design/source inspection and deterministic package smoke checks supplied the evidence.
- **Maintainer-facing note:** print the created task id/path or a clear failure, and do not create unignored worktree artifacts until a durable task receipt exists.

2026-07-21 — Waspflow Federation Windows portability lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "Audit and fix Windows portability for Federation Node daemon and Go tray; document and verify"`.
- **Worked / didn't:** `tldr` described the intended bounded workflow, but task creation reported `database is locked (5)` during automatic scanning while still writing an unignored `devspecs/` tree in the clean worktree. The generated receipt was not needed for this explicitly named, source-directed change; direct source/test reads and deterministic Node/Go checks supplied the evidence.
- **Maintainer-facing note:** serialize or retry the SQLite scan before creating worktree artifacts, and keep generated receipts outside the source worktree or ignore them by default.

2026-07-21 — Pramana desktop DCR-handoff diagnosis lane (ds v1.1.x)

- **Command(s):** `ds task quick "diagnose and fix F desktop-required DCR scope setup"`, then `ds task status`.
- **Worked / didn't:** task creation did produce a bounded receipt, but it printed only automatic-index progress and no task ID or path. It also wrote an unignored `devspecs/` tree into the clean worktree, which then broke the repository-wide Biome gate. The no-argument status command did not provide a usable task status. Direct source tracing, an evidence-timing check, and focused unit tests supplied the actionable diagnosis.
- **Maintainer-facing note:** print a durable task ID/path from `task quick`, make the single active task discoverable by `task status`, and keep generated receipts outside a source worktree or ignored by default.

2026-07-22 — Waspflow Federation Wave C evidence gate (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task "Fix Federation Wave C evidence gate..." --slice ...`, then `ds task list` and `ds task status <recovered-id>`.
- **Worked / didn't:** the multi-slice task did create usable C01–C04 receipts, but creation printed only automatic-index progress and no task id/path. Two diagnostic `list` commands also created separate unignored task directories, and one scan hit `database is locked (5)`. The durable receipt was useful after recovery; direct source, live daemon, browser, and full-suite evidence remained authoritative.
- **Maintainer-facing note:** print the created task id/path, make diagnostic commands read-only, and retry/report SQLite scan ownership before emitting unignored task directories.

2026-07-21 — Pramana F HITL classification lane (ds v1.1.x)

- **Command(s):** `ds tldr`.
- **Worked / didn't:** `tldr` gave the expected bounded-task guidance. I did not create a task because the prior Pramana use had left unignored generated state and this lane already had exact source paths, a confirmed production failure, and clear focused tests.
- **vs. doing it by hand:** useful only as a short workflow reminder; direct source, controller, fixture, and live-run evidence were authoritative.
- **Maintainer-facing note:** preserve the useful short guide, but make task creation safe for clean worktrees before it becomes the default for narrowly scoped incident fixes.

2026-07-22 — Waspflow Federation Wave E visual/copy lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task "Ship Federation Wave E..." --slice ...`, attempted `ds task status`, then `ds task checkpoint`.
- **Worked / didn't:** task creation generated useful D01–D03 plan/result receipts and the final checkpoint accepted source/test evidence. Creation printed only indexing progress instead of the task id, so `status` first failed without an id; recovering the generated directory showed a usable manifest. The unignored `devspecs/` task directory dirtied the requested implementation worktree and had to be removed after checkpointing.
- **vs. doing it by hand:** the final checkpoint is a useful compact receipt; direct source, headless screenshot, and test evidence remained authoritative for this exact UI defect.
- **Maintainer-facing note:** print the durable task id/path immediately after creation, let `status` select the sole recent task, and keep task artifacts outside or ignored by source worktrees.

2026-07-22 — Remote Surface retained-surface repair lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick`, attempted `ds task status`, then checkpoint and finish.
- **Worked / didn't:** task creation made a useful bounded receipt and the checkpoint captured the exact source/test evidence, but creation printed no task id/path, so recovery required searching the new unignored `devspecs/` tree. `status` without an id errored, and `finish --decision promote --stage done` returned no confirmation and left the task-level status as `packed` despite the slice checkpoint being promoted.
- **vs. doing it by hand:** the final checkpoint is a compact handoff record; direct code history, source/test tracing, and `pnpm verify` were the authoritative proof for this narrow port.
- **Maintainer-facing note:** print the task id/path and finish state, let `status` select a sole active task, update the top-level task status on finish, and keep generated task state outside or ignored by the source worktree.

2026-07-22 — Pramana connector-session transplant lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task "build connector-session transplant ..." --slice ...`, followed by `ds task status` and `ds task list`.
- **Worked / didn't:** `tldr` explained the multi-slice workflow, but task creation printed only automatic index progress instead of a task id/path. The no-argument status command failed, while the diagnostic list command unexpectedly created another unignored `devspecs/` task tree. That tree made the repository-wide Biome check fail and had to be moved to trash before validation. Direct runner/source/test inspection remained the implementation authority.
- **Maintainer-facing note:** make diagnostic listing read-only, print a durable task id/path after task creation, let `status` select a sole active task, and keep generated artifacts outside or ignored by a clean source worktree.

2026-07-22 — Waspflow Federation Wave G lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task ... --slice ...`, then a validated `ds task checkpoint`.
- **Worked / didn't:** the multi-slice task eventually created a useful receipt and the checkpoint captured the implementation evidence. Its automatic scan first failed with `database is locked (5)` while still creating an unignored `devspecs/` task tree in the implementation worktree; direct source/test inspection was required to continue safely.
- **vs. doing it by hand:** useful for the checkpoint, negative for initial discovery on this exact owner-directed Federation change.
- **Maintainer-facing note:** retry/serialize the SQLite scan before reporting task creation success, and keep task artifacts outside or ignored by the source worktree.

2026-07-22 — Context Gateway Stripe escrow wiring lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "wire successful Stripe subscription payment events to manual escrow funding requests"`.
- **Worked / didn't:** `tldr` gave the intended bounded-task workflow, but task creation failed before producing a usable receipt with `scan failed ... database is locked (5) (SQLITE_BUSY)`. It still created an unignored `devspecs/` directory in the requested worktree; direct source, migration, and focused-test inspection supplied the implementation boundary and evidence.
- **Maintainer-facing note:** on an index lock, retry or emit no worktree artifacts; if a partial receipt is retained, mark it incomplete and print a concrete lock-recovery command.

2026-07-22 — Waspflow Federation Git task-access lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds map`, `ds find`, then a three-slice `ds task`.
- **Worked / didn't:** `tldr` clarified the intended bounded-slice workflow, but both discovery/task indexing encountered `database is locked (5) (SQLITE_BUSY)`. The task directory was still created, leaving an ambiguous partial receipt; direct source/test/document inspection was required to establish the actual schema, daemon, kit, and runner seams.
- **Maintainer-facing note:** make a locked scan retryable or fail before creating task artifacts, and label any partial receipt/index as incomplete with a concrete recovery command.

2026-07-23 — PDPP Gmail re-quarantine accounting investigation (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds map`, then `ds task quick "triage connector-neutral recovery accounting regression..."`.
- **Worked / didn't:** `tldr` gave a useful incident workflow, but both map/task indexing hit `database is locked (5) (SQLITE_BUSY)`. The attempted task still left an unignored `devspecs/` directory in the clean worktree and yielded no usable task id or evidence receipt, so direct source/spec/test tracing was required.
- **Maintainer-facing note:** serialize or retry the index transaction before creating worktree artifacts; on failure, emit no task tree or clearly mark it incomplete and print a safe lock-recovery command.

2026-07-22 — PDPP systemic connector-test timeout lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick "close systemic polyfill-connectors node:test hosted aggregate timeout"`, then `ds task status`.
- **Worked / didn't:** `tldr` described the intended incident workflow, but `task quick` emitted only automatic-index progress and no durable task id/path; `status` without an id errored. Direct package-script, CI-history, Node-runner, and focused-file evidence was necessary to define the bounded runner change.
- **Maintainer-facing note:** print a task id/path after `task quick`, and let `task status` resolve a single active task rather than requiring a hidden id.

2026-07-22 — Waspflow Federation Wave I lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task ... --slice ...`, then `ds task checkpoint` and `ds task finish`.
- **Worked / didn't:** task creation first hit `database is locked (5) (SQLITE_BUSY)` while creating the unignored Wave I task directory. A later checkpoint succeeded and captured the exact suite and browser evidence, but `finish --decision promote` returned no confirmation and left the task status as `packed` with only G01/G04 explicitly advanced.
- **Maintainer-facing note:** retry or fail closed before writing task artifacts when SQLite is locked; make finish report its actual transition and advance all completed slices or explain why it did not.

2026-07-22 — Context Gateway escrow-funding lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds map`, then `ds task "implement escrow funding for per-app Moksha escrow deposits" --slice ...`.
- **Worked / didn't:** the task command first reported `database is locked (5) (SQLITE_BUSY)` and printed no task identifier, while later leaving an unignored `devspecs/` task tree in the implementation worktree. Direct source, migration, and focused Vitest evidence were required to continue; the generated receipts were not needed for the requested implementation.
- **Maintainer-facing note:** retry or fail before creating worktree artifacts on SQLite contention, print the durable task path when it succeeds, and keep generated task state outside or ignored by the source worktree.

2026-07-22 — PDPP Next 16.3 canary / TypeScript 7 upgrade lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task "upgrade Next.js 16.3 canary and TypeScript 7" --slice ...`; attempted `ds task status`.
- **Worked / didn't:** `tldr` clearly described the bounded multi-slice workflow. Task creation printed only automatic-index progress and no task id/path or completion receipt; `task status` without an id then errored with its usage message. Direct dependency/config inspection and the required build/type/test gates remained the usable evidence.
- **Maintainer-facing note:** print the durable task id/path when task creation completes, and let `task status` select a sole active task or point directly to the recoverable receipt.

2026-07-22 — PDPP Biome 2.5 / Ultracite 7.9 migration lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then a four-slice `ds task "full Biome 2.5.5 and Ultracite 7.9.4 migration"`.
- **Worked / didn't:** `tldr` made the staged workflow clear, but task creation stopped during automatic scanning with `database is locked (5) (SQLITE_BUSY)` and supplied neither a durable task identifier nor a safe lock-recovery action. Direct repository/config inspection is the usable evidence path for this migration.
- **Maintainer-facing note:** serialize or retry the SQLite scan before reporting task creation, and on contention print the lock-recovery command plus whether any task artifact was retained.

2026-07-22 — Pramana thin managed-run coordinator (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task "build thin managed-run coordinator" --slice ...`, attempted `ds task status`, then checkpoint.
- **Worked / didn't:** the generated slices and checkpoint made a useful compact receipt, but task creation printed only indexing progress rather than the task id/path. `status` without the hidden id errored, and the unignored generated `devspecs/` files made the repository-wide Biome check fail until removed. Direct runner, preflight, registry, and targeted-test evidence remained authoritative.
- **Maintainer-facing note:** print the new task id/path, let `status` select a sole current task, and put generated task state outside or inside an ignored worktree path.

2026-07-22 — Pramana honest redaction wire-contract fix (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "fix honest redaction wire value"`.
- **Worked / didn't:** `tldr` clearly described the focused-task workflow, but task creation first failed during automatic scanning with `database is locked (5) (SQLITE_BUSY)` and still left an unignored `devspecs/` directory in the clean implementation worktree. The task command also emitted no usable task id before its failure.
- **vs. doing it by hand:** direct producer/consumer source and contract tests were the reliable path for this urgent cross-repo correctness fix.
- **Maintainer-facing note:** on an index lock, fail before writing task artifacts (or mark/print the partial task path) and give a concrete safe retry/recovery command.

2026-07-22 — Pramana real F OS-handoff lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds map`, then `ds task "build real F web-to-desktop OS custom-scheme handoff" --slice ...`.
- **Worked / didn't:** map and the generated A01–A03 receipts were useful orientation, but task creation printed only scan progress rather than the durable task id/path. It created an unignored `devspecs/` directory in the clean implementation worktree, which made the repository-wide Biome gate fail even though product sources were formatted.
- **Maintainer-facing note:** print the task path on creation and place generated task state outside source worktrees or under an ignored directory; a clean requested worktree should remain lintable after normal task creation.

2026-07-22 — PDPP Biome judgment-rule lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task "Clear the five specified Biome judgment rules only" --slice ...`.
- **Worked / didn't:** `tldr` provided a clear bounded-slice workflow, but task creation failed its automatic scan with `database is locked (5) (SQLITE_BUSY)` while still writing an unignored `devspecs/` task directory into the clean implementation worktree. The directory had to be removed before the repository-wide Biome gate could be trusted; direct Biome diagnostics and focused tests supplied the actual evidence.
- **Maintainer-facing note:** when the index is locked, retry or fail before creating worktree artifacts; if a partial receipt is retained, print its durable path and mark it incomplete.

2026-07-22 — PDPP Biome shared-file cleanup lane (ds v1.1.x)

- **Command(s):** `ds tldr`, `ds task quick "repair Biome regressions merged from parallel lanes; achieve zero Biome errors and prescribed validation"`, status, checkpoint, and finish.
- **Worked / didn't:** the task receipt and lifecycle commands worked after discovering the generated task id from `task.json`, but creation printed only indexing progress rather than that durable id/path. It also created unignored `devspecs/` files inside the fresh worktree; Biome then linted the generated `task.json`, producing a false gate failure until the task artifact was removed.
- **Maintainer-facing note:** always print the completed task id/path, and write generated task state outside the repository scan or under an ignored path so `ds task quick` cannot make a clean worktree fail its own lint gate.

2026-07-22 — Pramana K desktop visual-capture hotfix (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "fix K desktop visual replay capture on attach and authenticated-oracle path"`.
- **Worked / didn't:** `tldr` described the focused hotfix flow, but task creation failed its automatic scan with `database is locked (5) (SQLITE_BUSY)` while still creating an unignored `devspecs/` task tree in a clean worktree. The generated receipt was not reliable for discovery; direct source and focused regression inspection supplied the implementation boundary.
- **Maintainer-facing note:** retry/serialize the scan or fail before writing worktree artifacts; on contention, identify the partial receipt and give a concrete safe recovery command.

2026-07-23 — PDPP Gmail recovery throughput discriminator (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "add aggregate-only Gmail attachment recovery throughput discriminator"` twice.
- **Worked / didn't:** `tldr` correctly described a bounded hotfix workflow. Both task-creation attempts stopped during automatic scanning with `database is locked (5) (SQLITE_BUSY)` and emitted no usable task id or completion receipt, while still leaving two unignored `devspecs/` task trees in the clean worktree. Direct OpenSpec/source/test tracing provided the reliable implementation boundary.
- **Maintainer-facing note:** serialize or retry the index transaction before creating any worktree artifact; on a lock, print a concrete recovery command and either no receipt or one explicitly marked partial.

2026-07-23 — PDPP Gmail adaptive recovery throughput lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task "implement bounded Gmail attachment recovery byte-batch throughput" --slice ...`, followed by `ds task status` and `ds task list`.
- **Worked / didn't:** `tldr` clarified the intended multi-slice flow, but task creation printed only automatic-index progress and no receipt id/path. The no-argument status command failed, and the diagnostic list command unexpectedly created a second unignored task tree. Both generated trees had to be removed before validation; direct OpenSpec, source, and deterministic Gmail tests supplied the authoritative boundary and evidence.
- **Maintainer-facing note:** make list/status read-only diagnostics, print the durable task id/path after creation, let status resolve a sole active task, and keep generated task state outside or ignored by a source worktree.

2026-07-23 — Context Gateway isolated ERC-20 funding lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "add manual asset-aware ERC-20 escrow funding with local mock-contract integration coverage"` from a clean detached worktree.
- **Worked / didn't:** `tldr` defined the bounded workflow, but task creation stopped while scanning the focused worktree with `database is locked (5) (SQLITE_BUSY)` and returned no task id/path or recovery command. Direct escrow source, SDK ABI, gateway decoder, and focused integration tests remained the usable evidence path.
- **Maintainer-facing note:** retry or serialize the index transaction for concurrent worktrees; on contention, say whether any task artifact was retained and print a safe focused-path retry command.

2026-07-23 — Context Gateway data_access signing counterpart (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "implement feature-gated standalone data_access x402 signing while preserving grant behavior"` from a clean detached worktree; followed the TLDR's suggested focused-path recovery with `--path`.
- **Worked / didn't:** task creation stopped during automatic scanning with `database is locked (5) (SQLITE_BUSY)` and returned no task id/path. The documented `--path` recovery is not accepted by `ds task quick` (`unknown flag: --path`), so direct protocol/source/test inspection supplied the implementation boundary.
- **Maintainer-facing note:** make the TLDR's focused-path recovery command valid for `task quick` (or document the supported equivalent), and retry/serialize the index before emitting task artifacts.

2026-07-23 — Pramana producer-causality lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task "implement Pramana producer causality and evidence-honesty" --slice ...`.
- **Worked / didn't:** the task created plan/result artifacts but automatic indexing failed with `database is locked (5) (SQLITE_BUSY)`. The resulting unignored `devspecs/` tree had to be removed before the repository's formatter and test gates could be trusted; direct artifact/source/test inspection provided the implementation boundary.
- **Maintainer-facing note:** on a locked scan, either retry before creating the task tree or clearly mark it incomplete and ignore it by default.

2026-07-23 — Pramana Sol Gate 2 terminal-schema lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then a four-slice `ds task ... --slice ...`, followed by `ds task status` and a validated `ds task checkpoint`.
- **Worked / didn't:** `tldr` was useful and the task produced a usable A02 receipt, but creation printed only automatic-index progress, so the task ID had to be recovered from the generated tree. `ds task status` without that ID failed. The unignored `devspecs/` directory was included by the repository-wide Biome check and had to be formatted during validation, then removed before the requested code commit. Direct gate-report/source/test inspection remained authoritative for the named P1/P4 boundaries.
- **Maintainer-facing note:** print the durable task ID/path on creation, let `status` resolve a sole active task, and keep generated task state outside or ignored by implementation worktrees so it cannot affect lint or commits.

2026-07-23 — Data Gateway PR58 settlement-proof outbox lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then a three-slice `ds task "implement PR58 F01 and F04 durable settlement proof fixes" --slice ...`.
- **Worked / didn't:** `tldr` clearly described the multi-slice workflow, but task creation reported `database is locked (5) (SQLITE_BUSY)`, printed no task ID/path, and then hung until interrupted after roughly 90 seconds. Despite the reported scan failure and interruption, it left a complete-looking unignored `devspecs/` task tree in the isolated worktree, so the caller cannot tell whether the receipt is authoritative or partial.
- **Maintainer-facing note:** fail promptly on SQLite contention, state whether a task was durably created, print its path if so, and keep generated task state outside or ignored by implementation worktrees.

2026-07-23 — Data Gateway PR58 grant-authorization hardening lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then a three-slice `ds task "harden PR58 grant-authorized standalone access settlement" --slice ...`.
- **Worked / didn't:** `tldr` supplied a useful gated workflow, but automatic indexing failed with `database is locked (5) (SQLITE_BUSY)` and returned no task ID. It nevertheless left a complete-looking unignored `devspecs/` task tree in the primary PR worktree, so the generated artifacts could not be treated as an authoritative receipt and had to be removed before validation.
- **Maintainer-facing note:** serialize or retry the shared index before writing task artifacts; if task creation cannot complete, identify any partial path explicitly and keep it outside or ignored by the implementation worktree.

2026-07-23 — Data Gateway PR58 F02 balance-lock lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then `ds task quick "implement Data Gateway red-team F02 balance-row authorization lock"` from the isolated PR-head worktree.
- **Worked / didn't:** `tldr` clearly bounded the focused workflow, but task creation reported `database is locked (5) (SQLITE_BUSY)`, printed no task ID/path, and then hung until interrupted. It left an unignored, complete-looking `devspecs/` task tree even though the scan failed, so direct source and real-PostgreSQL concurrency tests remain the authoritative evidence.
- **Maintainer-facing note:** fail promptly on index contention, state whether the generated receipt is partial or usable, print its path when retained, and keep task state outside or ignored by implementation worktrees.

2026-07-23 — Data Gateway PR58 F06 legacy-payee lane (ds v1.1.x)

- **Command(s):** `ds tldr`, then a three-slice `ds task "implement Data Gateway red-team F06 legacy payee migration gate" --slice ...` from the isolated PR-head worktree.
- **Worked / didn't:** `tldr` described a useful migration-oriented workflow, but task creation reported `database is locked (5) (SQLITE_BUSY)`, emitted no task ID/path or safe recovery command, and hung until interrupted. It still left an unignored, complete-looking `devspecs/` tree whose receipts could not be trusted after the failed scan.
- **Maintainer-facing note:** fail promptly and before writing task artifacts on index contention; if any receipt survives, print its exact path and whether it is partial, and keep it outside or ignored by implementation worktrees.
