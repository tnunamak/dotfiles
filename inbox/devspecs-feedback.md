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
