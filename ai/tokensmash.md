# Tokensmashing

Tokensmashing is the local practice of maximizing useful agent context per
quota, token, and minute. Do not trust reducer self-metrics as proof.

## What Counts As Evidence

Primary metric:

- Total logged tokens per successful normal agent task.

Best available offline proxy:

- Total logged tokens per local session, paired with tool-output bytes,
  tool-call count, user turns, and assistant messages.

Secondary metrics:

- Actual stdout+stderr bytes emitted into the agent transcript after a reducer
  runs.
- Approximate local token count for the emitted payload.
- Exit-code preservation.
- Wall time added by the reducer.
- Whether the agent can still answer task-specific oracle questions from the
  reduced payload.
- Provider/quota movement from independent usage tools, when available.

Do not use `rtk gain`, Headroom stats, or context-mode stats as the source of
truth. They are diagnostic hints only. RTK has open upstream issues showing
inflated or misleading gain/discover numbers when truncation, hook rewrites, or
raw skipped file sizes are counted as savings.

Relevant RTK issues:

- https://github.com/rtk-ai/rtk/issues/1045
- https://github.com/rtk-ai/rtk/issues/1973
- https://github.com/rtk-ai/rtk/issues/1935
- https://github.com/rtk-ai/rtk/issues/2241
- https://github.com/rtk-ai/rtk/issues/538

## Current Stack

- `context-mode`: context hygiene, searchable memory, tool-output sandboxing.
- `rtk`: incumbent shell-output reducer for agent hooks.
- `headroom`: MCP-only compressor/retriever available to all agents.

`headroom wrap` is not enabled by default. It should be benchmarked against
rtk/context-mode before it becomes an automatic interception layer.

Current adoption decision:

- Keep `context-mode`, measured `rtk`, Headroom MCP, and the local
  `tokensmash` harness.
- Do not add SEMMAP, pakr, devspecs-cli, mcp-doctor, Serena, Repomix,
  Gitingest, Aider, ToolHive, or mcp-compressor to default setup yet.
- Revisit only when a benchmark proves lower emitted context before first edit
  or a cleaner install path removes operational risk.

## Local Harness

Use `tokensmash`:

```bash
tokensmash doctor
tokensmash audit-sessions --days 3 --top 12
tokensmash audit-sessions --days 3 --started-days 3 --top 12
tokensmash compare -- git status --short
tokensmash compare -- find . -maxdepth 3 -type f
tokensmash compare --headroom -- find . -maxdepth 3 -type f
tokensmash suite --headroom
tokensmash sessions --days 3 --limit-samples 40
tokensmash sessions --agent codex --days 3 --limit-samples 5 --headroom --no-store
tokensmash history
```

Runs are stored under `~/.local/state/tokensmash/runs/`. Stored JSON includes
command, hashes, byte counts, line counts, exit codes, and timings, but not raw
command output.

`audit-sessions` is the decision-grade offline command. It reads local
Codex/Claude JSONL logs and stores aggregate token/tool metrics only, not raw
transcript text.

## Causal A/B Harness

Use `tokensmash-ab` when the question is:

- baseline token spend,
- token spend with the tool,
- percent improvement.

It runs the same normal agent task in disposable Git clones, then reads the
final Codex `token_count.total_token_usage.total_tokens` from
`~/.codex/sessions`. It does not use reducer self-reports.

Default smoke suite:

```bash
tokensmash-ab plan --suite ~/code/dotfiles/ai/tokensmash-bench/smoke.json
tokensmash-ab run --suite ~/code/dotfiles/ai/tokensmash-bench/smoke.json
tokensmash-ab run --live --suite ~/code/dotfiles/ai/tokensmash-bench/smoke.json
tokensmash-ab table ~/.local/state/tokensmash/ab-runs/<run-id>/results.json
```

`run` is dry-run by default. Add `--live` only when intentionally spending
quota. The suite defaults to `gpt-5.5` with low reasoning and `workspace-write`
sandboxing in a scratch clone.

Add a new tool by adding a `variants[]` entry to the suite JSON:

- `id`: stable row key in the result table.
- `codex_args`: Codex exec args for this variant, if any.
- `setup_commands`: optional shell commands to prepare context files in
  `{run_dir}`.
- `env`: optional suite, task, or variant environment variables; values may use
  `{repo_dir}` and `{run_dir}`.
- `prompt_prefix`: optional instruction that tells the agent how to use the
  prepared tool output.
- `requires`: optional `env` and `commands` gates so unavailable tools skip
  cleanly.

Only paired successful samples count in the improvement table. A failed tool
run is not treated as a zero-token win.

## Decision Rule

A reducer wins only when it improves actual emitted payload or task outcome on
representative local workloads without unacceptable latency or lost signal.

For automatic hooks, prefer:

1. high byte reduction on large outputs,
2. unchanged exit semantics,
3. readable output for the agent,
4. low latency,
5. no double-compression of content that another layer already made retrievable.

For codebase-navigation tools, use a different gate. They do not reduce an
already-emitted payload; they should prevent the wrong payloads from being
emitted in the first place.

Promote a codebase-navigation tool into `setup.sh` only if a benchmark on real
repos shows:

1. lower bytes emitted before the first edit,
2. fewer file-read/search round trips before confidence,
3. high relevant-file hit rate for the task's eventual touched files,
4. low missed-file rate for files needed to understand the change,
5. reproducible install/update story across Linux and macOS.

Reject or defer tools that only make nice-looking maps but do not change agent
behavior or have brittle install paths.

## Tool Landscape

Use tools by layer, not brand.

### Output Avoidance / Deferred Retrieval

Best for MB-scale tool output, logs, MCP results, browser snapshots, and session
continuity.

- `context-mode`: strongest fit in the current setup. It runs data-heavy work in
  sandboxed commands/files and returns only derived answers, while retaining
  searchable raw chunks out of transcript. This is the right default for
  anything where the agent does not need to see every byte immediately.
- Headroom MCP `headroom_compress` / `headroom_retrieve`: useful as an explicit
  lossy compressor with retrieval handles, but current tests show it is
  bimodal on real session payloads: some large outputs collapse, others pass
  through unchanged.

### Shell Output Reducers

Best for commands the agent already intends to run in a shell.

- `rtk`: useful for `find`, `grep`, build/test/lint/log outputs when it actually
  rewrites or filters the emitted payload. Do not trust its savings dashboard.
  Measure actual stdout/stderr bytes with `tokensmash compare`.

### Codebase Retrieval / Navigation

Best for avoiding whole-file reads and reducing repeated repo discovery.

- SEMMAP (`junovhs/semmap`): generates a plain-text architectural map intended
  to help agents converge on the right 3-8 files before reading source deeply.
  This is directly aligned with tokensmashing because it reduces wandering and
  repeated discovery before large outputs are produced. Benchmark before
  installing globally: as of 2026-06-10, the repo is young, not published on
  crates.io, and its `Cargo.toml` depends on `omni-ast` via a sibling path, so
  source installation needs paired checkouts.
- pakr (`junovhs/pakr`): terminal file packer for AI context with SEMMAP-aware
  selection and token counting. Conceptually overlaps with Repomix/Gitingest,
  but it is interactive and selection-oriented rather than whole-repo packing.
  Benchmark only after SEMMAP proves useful.
- Serena MCP: LSP/symbol-level code retrieval and editing tools. Candidate for
  reducing repeated `rg`/`sed`/file-read loops on mature codebases.
- Aider repo-map style: tree-sitter/ctags symbol map under a token budget.
  Strong pattern to copy even if not adopting Aider as an agent.
- Sourcegraph/Cody/Claude Context style: semantic/hybrid code search over large
  repos. Powerful but heavier, often needs indexing/embedding/vector services.

### Repo Snapshot / One-Shot Packing

Best for audits, handoff packets, third-party repo review, and reproducible
offline prompts. Not a default agent loop.

- Repomix: packs repos with token counting, include/exclude controls, git-aware
  ignores, diffs/logs, and MCP mode.
- Gitingest: turns Git repositories into prompt-friendly text digests. Useful
  for external/public repos or portable one-shot context.
- devspecs-cli (`devspecs-com/devspecs-cli`): local-first indexing/export for
  specs, ADRs, plans, and agent-ready task context. Benchmark as a bounded
  task-slice tool, not as a live tool-output reducer.
- mcp-doctor (`destilabs/mcp-doctor`): diagnostic/eval tool for MCP response
  size, pagination, caching, and token efficiency. Use when auditing MCP
  servers; it is not a runtime reducer.

## Current Local Findings

Normal-session audit:

- Active local sessions in the last 3 days: 160 sessions, 27.98B logged tokens,
  901 MB tool-output bytes, 175K tool calls.
- Sessions both active and started in the last 3 days: 148 sessions, 8.36B
  logged tokens, 86.9 MB tool-output bytes, 15.5K tool calls.
- Fresh-started 3-day workload by agent:
  - Codex: 37 sessions, 6.73B logged tokens, 86.3 MB tool-output bytes.
  - Claude: 111 sessions, 1.62B logged tokens, 592 KB tool-output bytes.
- Token-confidence labels:
  - Codex: high confidence for local logs, because the audit uses each session
    file's final `token_count.total_token_usage`.
  - Claude: medium-high confidence for local logs, because the audit sums
    per-message `usage`; this should be close but is not a single final
    provider session total.
  - Neither is a billing statement, and neither proves causal savings from a
    candidate tool.
- Top fresh-started tool-output sources:
  - `function_call:exec_command`: 51.2 MB
  - `mcp:context-mode/ctx_batch_execute`: 14.8 MB
  - `custom_tool_call:apply_patch`: 10.0 MB
  - `mcp:pdpp/schema`: 2.7 MB
  - `function_call:write_stdin`: 1.6 MB
  - `mcp:context-mode/ctx_execute`: 1.5 MB
  - `mcp:context-mode/ctx_search`: 1.4 MB
  - `mcp:context-mode/ctx_execute_file`: 0.7 MB
- Interpretation: total-token risk is dominated by long or very large agent
  sessions. For fresh recent Codex work, direct shell output is the largest
  measured tool-output pressure. Context-mode is not free: its returned
  summaries/results were the second-largest measured tool-output source. It may
  still be net-positive, but logs alone do not prove the counterfactual savings.
  Claude's recent token load is mostly not visible as tool-output bytes.

This supersedes the earlier headline table. Reducer/packer numbers below are
diagnostics, not proof of lower tokens per successful task.

What this can and cannot prove:

- Proven from logs: which tools add output bytes in normal sessions, and which
  sessions dominate total logged tokens.
- Proven from reducer replay: how much a reducer shrinks a specific captured
  payload or command suite.
- Not proven offline: whether SEMMAP, Repomix/Gitingest, Serena, ToolHive, or
  mcp-compressor reduce total tokens per successful normal task. They require
  controlled A/B replays because they change agent behavior, not just bytes.
- Context-mode needs a controlled A/B too. The right question is not "how many
  bytes did it index?" but "does the same task complete successfully with fewer
  total logged tokens when context-mode is available and used correctly?"

Toy command suite in `~/code/dotfiles`:

- Raw: 9,007 bytes
- RTK: 5,168 bytes, 42.6% actual emitted-byte reduction
- Headroom MCP: 7,220 bytes, 19.8% actual emitted-byte reduction

Recent real session samples:

- Codex, last 3 days, top 40 local tool-output samples: 37.5 MB raw. Top kinds:
  `function_call_output` and `mcp_tool_call_end`. Median sample was ~938 KB.
  This is exactly the class where context-mode-style deferred processing should
  beat shell-output filtering.
- Codex, last 3 days, top 5 with Headroom MCP: 8.7 MB raw -> 5.9 MB compressed,
  32.2% reduction. Three large samples passed through unchanged; two collapsed
  to tiny summaries.
- Claude, last 7 days, top 20 local tool-output samples: 725 KB raw. Median
  sample was ~29 KB.
- Claude, last 7 days, top 8 with Headroom MCP: 440 KB raw -> 228 KB compressed,
  48.1% reduction. One 207 KB list-like sample passed through unchanged.

Interpretation:

- Keep context-mode as the default for large outputs and MCP/tool results.
- Keep RTK as a measured shell-output reducer, not a source of truth.
- Keep Headroom MCP available, but route it selectively until it proves
  reliable on the payload classes that matter.
- Next experiments should test Serena or repo-map-style retrieval against
  repeated codebase-discovery loops, because those may reduce work before large
  outputs are produced at all.

## External Candidate Findings

GitHub pass on `junovhs` / `bnunamak`:

- `junovhs/semmap`: strongest hit. Benchmark first against 2-3 real repo tasks:
  compare relevant-file hit rate, missed-file rate, emitted bytes before first
  edit, and round trips to confidence. Practical test result: promising for
  `clawmeter`, weak for `dotfiles`, and not ready for global install.
- `junovhs/pakr`: promising companion if SEMMAP works; defer until SEMMAP is
  installed and producing useful maps.
- `junovhs/omni-ast`: likely a dependency/enabler for SEMMAP rather than a
  direct user-facing tokensmashing tool.
- `bnunamak`: no public repo matched token/context/MCP/semantic-map criteria in
  the repo keyword pass.
- Adjacent worker finds: `devspecs-cli` and `mcp-doctor` are worth benchmarking
  later, but neither displaces context-mode/rtk/headroom today.

Decision queue:

1. Benchmark SEMMAP on `clawmeter` and `dotfiles`.
2. If SEMMAP improves file-selection behavior, benchmark `pakr` as its
   interactive packing companion.
3. Benchmark `devspecs-cli` only for task/spec handoff workflows.
4. Use `mcp-doctor` only when auditing MCP servers; do not add it to default
   agent startup.

Final outcome from the 2026-06-10 pass:

- SEMMAP: defer. A scratch build works only with sibling `semmap` and
  `omni-ast` clones. `cargo install semmap` and `cargo install --git` do not
  work cleanly. It generated a useful-looking 36 KB map for a `clawmeter`
  scratch copy in about 6 seconds, but was low-signal for `dotfiles` and misses
  extensionless executables such as `bin/.local/bin/tokensmash`.
- SEMMAP safe inclusion path: documentation-only plus an optional pinned scratch
  benchmark. Do not add a `tokensmash semmap` subcommand unless it is explicitly
  experimental and requires a caller-provided `semmap` binary path.
- pakr: defer behind SEMMAP. It is an interactive packing companion, not a
  standalone default.
- devspecs-cli: defer. It has release binaries and a Homebrew tap, but solves
  task/spec handoff rather than the currently measured biggest problem:
  multi-megabyte tool/MCP outputs.
- mcp-doctor: defer to ad hoc MCP audits. It evaluates MCP response quality but
  does not reduce transcript payloads.
- Repomix/Gitingest: keep as ephemeral benchmark comparators, not setup
  packages. Local scratch results: Repomix packed `dotfiles` in 1.30s to 1.5 MB
  and `clawmeter` in 1.50s to 596 KB; Gitingest packed `dotfiles` in 3.20s to
  1.3 MB and `clawmeter` in 1.10s to 566 KB with a more readable prompt-pack
  shape and token estimates.
- Aider repo-map: reject for setup but keep the concept. Scratch repo-map output
  was compact (`dotfiles` 25 KB, `clawmeter` 35 KB), but the CLI is heavier and
  writes `.aider.chat.history.md` / `.aider.tags.cache.v4`.
- Serena MCP: still a plausible future benchmark for symbol-level retrieval,
  but no current local measurement beats the adopted stack.
- Atlassian mcp-compressor: benchmark later from its Rust binary only. The npm
  package exists (`@atlassian/mcp-compressor@0.30.0`, ~78.7 MB unpacked), but a
  transient npm help probe spawned recursive `mcp-compressor --help` processes.
  It may reduce MCP tool-schema/input bloat, not large tool outputs.
- ToolHive MCP Optimizer: reject for default install. It is a gateway/vMCP
  layer that would replace this repo's single `sync-mcps.sh` MCP mechanism with
  another orchestration system. Revisit only for a deliberate MCP gateway
  experiment.
- Default setup remains intentionally small: `context-mode` for avoiding large
  context injections, `rtk` where measured shell output shrinks, Headroom MCP
  for explicit experiments, and `tokensmash` for proof.

Optional SEMMAP scratch benchmark:

```bash
mkdir -p ~/.tmp/semmap-bench
cd ~/.tmp/semmap-bench

git clone https://github.com/junovhs/omni-ast.git
git clone https://github.com/junovhs/semmap.git

git -C omni-ast checkout 9e75edd5aa9911b6668e4df5447da697634e02cd
git -C semmap checkout 1d7c09d697c75047aa82cac41a95bf620eb06f9e

cargo install --path semmap --root "$PWD/install" --locked

~/.tmp/semmap-bench/install/bin/semmap generate \
  --root ~/code/clawmeter \
  --output ~/.tmp/semmap-bench/clawmeter-SEMMAP.md

~/.tmp/semmap-bench/install/bin/semmap context \
  --root ~/code/clawmeter \
  "task description here"
```
