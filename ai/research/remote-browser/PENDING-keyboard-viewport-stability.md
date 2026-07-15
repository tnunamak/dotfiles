# Status report: mobile-keyboard viewport-stability research task

**Status: COMPLETE.** The corpus entry was researched, written, and committed
earlier in this session. This report exists only because the harness's
automated report-writing step didn't fire at the time; it is being
reconstructed now from the actual repo state, not from the evidence files
named in the prompt.

## Evidence-file mismatch (flagging honestly)

The prompt pointed to:
- `/home/tnunamak/.local/state/waspflow/lanes/rs-kbd-research/git-diff.txt`
- `/home/tnunamak/.local/state/waspflow/lanes/rs-kbd-research/git-status-after.txt`

Both describe a **different, unrelated change** — edits to
`bin/.local/bin/cleanup` (Elixir/Unity/pycache cache-threshold additions,
`NESTED_ARTIFACT_MAXDEPTH` refactor), `shell-status-refresh`, `RECOVERY.md`,
`host.sh`, etc. Neither file, nor the working-tree status they capture,
contains any trace of the keyboard/viewport research work. That lane's
changes are still uncommitted in the working tree (visible in
`git status --short` below as modified/untracked files unrelated to this
task) and are **not part of this report** — they belong to some other
in-flight session and were not touched or claimed here.

Rather than write a report against the wrong evidence, I re-verified the
actual outcome directly against git history and the filesystem, which is
authoritative.

## What was actually done

1. Read `ai/research/README.md` and `ai/research/_template.md` for corpus
   format (three-section entry: CLAIMS tagged `[source-slug]`, SOURCES with
   URL+accessed-date+quote, SYNTHESIS; frontmatter with title/date/topic/
   tags/status/sources; filename = claim in kebab-case).
2. Checked `ai/research/INDEX.md` to confirm no duplicate coverage — grepped
   for "keyboard" and "viewport" across the corpus; the two existing
   `remote-browser/` entries (viewport fix-at-session-start, Android IME
   forwarding) were confirmed distinct from mobile on-screen-keyboard
   layout-shift and left alone.
3. Dispatched a research agent to sweep primary sources (W3C CSS Viewport
   Module spec, W3C CSS Values & Units L4 spec, MDN incl. raw
   browser-compat-data JSON, Chrome for Developers blog, WebKit Bugzilla,
   WebKit standards-positions repo, WICG visual-viewport issues, Chromium
   issue tracker, web.dev) across six sub-topics: the `interactive-widget`
   viewport meta value, the VirtualKeyboard API, the `visualViewport` API,
   `dvh`/`svh`/`lvh` behavior under the keyboard, iOS Safari-specific
   quirks, and a ranked recommended stack.
4. Wrote the corpus entry:
   `ai/research/remote-browser/mobile-keyboard-overlay-requires-interactive-widget-plus-visualviewport-not-dvh-alone.md`
   (170 lines; CLAIMS tagged to 23 sources, each with URL + accessed date +
   verbatim quote; separate SYNTHESIS section with a ranked fix stack and an
   explicit confidence caveat on the one inferred-not-directly-stated claim).
5. Removed the `PENDING-latency-masking.md` placeholder that previously sat
   in `ai/research/remote-browser/` (it was untracked in git, so removal
   required no git action beyond the working-tree delete).
6. Added the corresponding one-line entry to `ai/research/INDEX.md`, ordered
   alphabetically within the `remote-browser/` group.
7. Committed both files as author `Tim Nunamaker <tnunamak@gmail.com>`,
   commit `5a97a01` — **not pushed**, per instructions.

## Verification (just re-run, current repo state)

```
$ git show 5a97a01 --stat
commit 5a97a015f447edd225fc425a728385910ca44bc6
Author: Tim Nunamaker <tnunamak@gmail.com>
Date:   Fri Jul 10 07:13:07 2026 -0500

    Add research: mobile keyboard overlay vs 100dvh layout shift

 ai/research/INDEX.md                                                          |   1 +
 .../mobile-keyboard-overlay-requires-interactive-widget-plus-visualviewport-not-dvh-alone.md | 170 ++++++++++
 2 files changed, 171 insertions(+)

$ grep -n "mobile-keyboard-overlay" ai/research/INDEX.md
99:- [Preventing mobile keyboard layout shift on a full-viewport (100dvh)
   video/stream viewer requires layering interactive-widget=overlays-content,
   the VirtualKeyboard API, and window.visualViewport as an iOS Safari
   fallback — dvh alone does not solve it](remote-browser/mobile-keyboard-...)
   — 2026-07-10 — ...

$ ls ai/research/remote-browser/PENDING*
(no matches — placeholder already removed)
```

The entry file exists on disk, is committed, and `ai/research/INDEX.md`
line 99 links to it. `git log -1` on the file confirms it was introduced in
`5a97a01` and hasn't been touched since.

## Top findings (for reference)

1. `interactive-widget=overlays-content` (viewport meta) and
   `navigator.virtualKeyboard.overlaysContent = true` are two entry points
   into the *same* underlying spec behavior (W3C CSS Viewport Module
   explicitly ties them together) — both Chromium-only (Chrome 108+/Firefox
   132+ for the meta value; Chrome 94+ only for the JS API), confirmed
   unsupported on Safari/iOS via MDN's raw browser-compat-data and two open
   WebKit bugs.
2. `window.visualViewport` is the only API that works on iOS Safari at all
   for this problem — Baseline "Widely available" since Aug 2021 — because
   iOS Safari shrinks only the visual viewport and offsets the layout
   viewport underneath the focused input, rather than resizing the layout
   viewport the way Android Chrome's `resizes-content` mode does.
3. Per the W3C CSS Values & Units L4 spec, the on-screen keyboard is
   explicitly excluded from what `dvh`/`svh`/`lvh` are defined to track by
   default (those units track browser-chrome retraction, a different
   problem) — `100dvh` reflow on keyboard-open is a side effect of the
   *initial viewport* being resized (`resizes-content` mode or an older
   default), not `dvh`-specific keyboard awareness. Corroborated by a
   Chromium issue-tracker thread.
4. Multiple still-open WebKit Bugzilla entries (#153224, #202120, #176205,
   #265578) confirm `position: fixed`/`sticky` elements still misbehave
   under the iOS keyboard as of research date — not folklore.
5. Recommended stack (ranked in the entry's SYNTHESIS): `100svh`/`100lvh`
   base CSS → `interactive-widget=overlays-content` meta (unconditional,
   zero-cost) → `navigator.virtualKeyboard.overlaysContent` JS layer →
   `window.visualViewport`-driven fallback for iOS → avoid raw
   `position: fixed` for input bars.

## What's missing / not done

Nothing outstanding for the task as scoped. One confidence caveat is
carried explicitly in the entry's SYNTHESIS: the claim "under Chrome's
current `resizes-visual` default, `100dvh` should not reflow for the
keyboard" is a defensible inference from combining spec text with the
Chrome blog post, not a single source stating it outright — the entry
recommends verifying on a real Android/Chrome device before relying on it
in production. Not done (out of scope): no code changes were made to any
consuming application — this was research only.

---

## `git status --short` (verbatim, dotfiles repo, current)

```
 D ai/skills/local/skill-creator/scripts/__pycache__/__init__.cpython-312.pyc
 D ai/skills/local/skill-creator/scripts/__pycache__/aggregate_benchmark.cpython-312.pyc
 M bin/.local/bin/cleanup
 M bin/.local/bin/shell-status-refresh
 M claude/.claude/CLAUDE.md
 M claude/.claude/commands/auditcodex.md
 M gemini/.gemini/settings.json
 M hosts/peregrine/RECOVERY.md
 M hosts/peregrine/host.sh
 M hosts/peregrine/workstation-issues.json
 M inbox/devspecs-feedback.md
 M npm-global-packages.txt
 M shell/.shell_config
 M zsh/.zshrc
?? ai/research/.staging-index-a.md
?? ai/research/.staging-index-b.md
?? ai/research/.staging-index-siteart.md
?? ai/research/agentic-context-design/agent-model-choice-is-cost-performance-at-effort-not-quota-or-sticker-price-alone.md
?? ai/research/agentic-context-design/auditing-the-orchestrator-not-just-the-change.md
?? ai/research/agentic-context-design/gnhf-overnight-agent-orchestrator-excellent-infra-but-agent-self-grades.md
?? ai/research/agentic-context-design/live-multi-agent-tmux-orchestration-tools-drive-workers-via-mcp-tools-and-detect-idle-from-jsonl-not-screen-scraping.md
?? ai/research/agentic-context-design/llm-judge-and-checklist-rubric-evaluation-literature-for-loop-engineering.md
?? ai/research/agentic-context-design/loop-library-is-prompt-templates-with-self-grading-not-a-gated-loop.md
?? ai/research/agentic-context-design/personal-data-import-tools-scope-dedup-per-acquisition-method-and-treat-partial-coverage-as-first-class.md
?? ai/research/agentic-context-design/read-aggregation-apis-converge-on-measures-dimensions-time-filters.md
?? ai/research/agentic-context-design/retained-size-read-models-should-label-byte-categories-and-separate-dimensions-from-measures.md
?? ai/research/agentic-context-design/skill-metadata-budget-and-name-only-overrides.md
?? ai/research/api-contract-design/
?? ai/research/code-quality/BOOK-LIST-FOR-TIM.md
?? ai/research/code-quality/CANONICAL-CODE-QUALITY-THEORY.phase1.md
?? ai/research/code-quality/MEMO-8-does-the-refactor-machine-need-tests.md
?? ai/research/code-quality/RAW-adversarial-counter-research-2026-06-28.md
?? ai/research/code-quality/RAW-deep-research-findings-2026-06-28.md
?? ai/research/code-quality/SLVPQ-OPERATIONALIZATION.md
?? ai/research/code-quality/discovering-and-prioritizing-codebase-defects-at-scale.md
?? ai/research/code-quality/dynamic-import-cycles-are-not-defects-measure-static-cycles-only.md
?? ai/research/code-quality/mature-npm-ecosystems-name-a-shared-package-after-the-durable-concept-it-owns-core-runtime-util-to-output.md
?? ai/research/code-quality/own-rent-delete-the-attention-perimeter-objective-function.md
?? ai/research/code-quality/sources-collected/
?? ai/research/code-quality/ungameable-quality-budget-and-prioritization-for-agent-pipelines.md
?? ai/research/connectors/
?? ai/research/data-collection-systems/
?? ai/research/data-explorer-ux/
?? ai/research/data-portability/
?? ai/research/distributed-systems/
?? ai/research/feedback-systems/connector-fleet-health-state-ux-patterns-across-stripe-plaid-linear-vercel.md
?? ai/research/feedback-systems/integration-health-ui-converges-on-one-synthesized-verdict-plus-a-typed-required-action-plus-a-self-heal-satisfaction-contract.md
?? ai/research/feedback-systems/mature-integrations-only-interrupt-the-owner-when-no-held-credential-can-resolve-it-and-route-everything-else-to-a-dashboard.md
?? ai/research/feedback-systems/rate-limiter-recovery-should-be-clocked-by-wall-time-since-last-throttle-not-by-successful-requests.md
?? ai/research/feedback-systems/report-issue-ctas-converge-on-prefilled-github-new-issue-url-with-minimal-versioned-body.md
?? ai/research/feedback-systems/scheduled-collection-needing-a-human-should-be-a-durable-attention-task-not-a-log-line.md
?? ai/research/frontend-libraries/
?? ai/research/knowledge-management/presenting-a-complex-technical-system-to-mixed-audiences-martini-glass-c4-progressive-disclosure.md
?? ai/research/mcp-protocol/
?? ai/research/oauth-mcp-auth/
?? ai/research/onboarding-ux/
?? ai/research/oss-strategy/
?? ai/research/product-design/
?? ai/research/rate-limiting/
?? ai/research/remote-browser/android-ime-forwarding-requires-guacamole-style-text-input-mode-not-keysym-synthesis.md
?? ai/research/search-infrastructure/
?? ai/research/self-hosting/
?? ai/research/session-ux/
?? ai/research/standards-body-sites/
?? ai/research/ux-writing/
?? ai/research/web-performance/
?? ai/research/web-push/
?? ai/research/webhooks-events/
?? ai/skills/local/code-quality-canon/
?? ai/skills/local/efficient-fable/
?? ai/skills/local/engineering-loop/
?? ai/skills/local/explore-unknowns/
?? ai/skills/local/refactor-loop/
?? hosts/peregrine/MEMORY-OOM-2026-06-28.md
?? inbox/pdpp-agent-observations-2026-06-25.md
?? inbox/pdpp-devspecs-feedback-2026-07-09.md
?? inbox/pdpp-product-feedback-tim-2026-06-18.md
?? inbox/session-4eb0f6c7-conversation-log.md
?? inbox/waspflow-feedback.md
```

Note: this status list is dominated by pre-existing, unrelated uncommitted
work in the working tree (other research-corpus entries, `cleanup` script
edits, various dotfiles), none of which was created or modified by this
task. The files this task produced (the corpus entry and the `INDEX.md`
line) do **not** appear above because they are already committed
(`5a97a01`), not because they're missing. This report file itself
(`PENDING-keyboard-viewport-stability.md`) will appear as untracked in a
subsequent `git status` since it was written after this snapshot was taken
and is not part of the committed research work.
