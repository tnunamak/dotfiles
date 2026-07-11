# Bet-the-Company Hardening Playbook

Read this before assessment, then read the relevant phase section immediately before entering it. Use it with `engineering-loop` and this profile’s `SKILL.md`; do not replace the loop’s preflight, maker/checker, done-check, or closeout gates. This playbook is authoritative for phase details; `SKILL.md` is the compact control plane.

## Contents

- [Assess](#1-assess)
- [Bettable hardening](#2-bettable-hardening)
- [Delegation and provider routing](#delegation-and-provider-routing)
- [Red-team the invariant](#red-team-the-bettable-invariant)
- [Excellence audit](#3-excellence-audit)
- [Release verification](#4-release-and-exact-artifact-verification)
- [Concrete traps](#concrete-traps-to-actively-test)
- [Final report](#compact-final-report)

## Operating posture

Hardening is not a feature sweep, a green test run, or a promise of flawlessness. Reduce a proven company-critical risk without silently weakening the project’s useful behavior. Begin with the product’s actual value path and the truth it owes its users.

Write the invariant as a falsifiable sentence. Examples:

- A submission system never reports accepted when the downstream job was not submitted.
- A recovery system never converts an unknown or corrupted state into success.
- A deployment tool never reports released until the exact published artifact is verified.
- A data workflow never loses, duplicates, or exposes a record without an explicit error.

Use the project’s existing issue tracker, records directory, and release mechanism if they exist. Otherwise return the compact artifacts in the task result. Do not create a permanent framework merely to run one engagement.

## Engineering-loop profile contract

| Slot | Hardening-specific value |
| --- | --- |
| Stop condition / acceptance | The gate for the requested bar passes: bettable, excellence, and authorized release are separate claims. |
| Oracle | Project checks plus a before/after failure-path oracle and a live valuable-journey assertion. |
| Checker | Different model, at least as capable as the maker, reading the diff and raw evidence; prefer a different lineage. |
| Discovery / memory | Ranked risk register plus rejected hypotheses, disproof evidence, and when to reconsider them. |
| Owner gate | Public behavior, policy, destructive/live-data probes, deployment, and irreversible external actions. |
| Cleanup | Preserve evidence reports; close/reap workers; record branch/worktree fate, rollback, and discarded diagnostics. |
| Fail output | One missing proof or owner decision, or a verified non-finding—never a substituted easy win. |

## 1. Assess

### Establish ground truth

Record these before interpreting a report:

1. Current revision, branch, worktree state, remotes, and divergence.
2. Runtime, dependency/tool versions, relevant environment assumptions, and whether tests are hermetic.
3. The high-value user journeys, external providers, durable state, recovery paths, and release/install path.
4. Existing test, build, lint, type, migration, packaging, security, and policy gates—plus exact baseline results.
5. Public surface: routes, commands, exports, schemas, config keys, artifacts, and support/operational paths.

Read implementation and state transitions before accepting an issue’s description or a command’s apparent surface. Check a status claim against raw `git status`, `git log`, remote refs, tags/releases, and the generated artifact as applicable.

### Build a risk register

Probe these lanes as relevant, recording the exact evidence and uncertainty:

| Lane | Look for |
| --- | --- |
| Truth and integrity | fabricated success, result laundering, missing/duplicated writes, incompatible/corrupt state |
| Reliability | races, retries, startup failure, stalled interactive boundary, interrupted work, recovery correctness |
| Security and trust | auth/authorization boundaries, injection, secrets, unsafe shell/filesystem input, supply chain |
| Operability | misleading status, raw internal errors, logs/diagnostics, bounded resources, fleet behavior |
| Release | wrong revision, unpublished change, stale package/image, install breakage, rollback uncertainty |

Rank by user/company impact × credible likelihood × evidence quality × detectability × ability to bound the fix. Classify each as `target`, `owner-gated`, `no-go`, `needs-evidence`, or `non-finding`. Do not exclude hard areas and then report “nothing serious found.” Inspect enough to classify them.

### Confidence register

Start with a number only if it helps the owner decide. Pair it with named gaps, scope, and evidence:

```text
Confidence: 90% that <specific invariant> holds for <named scope>.
Evidence: deterministic gate X; live journey Y; baseline Z.
Residual gaps: R1 mixed-provider soak; R2 killed-worker recovery; R3 exact release artifact.
Not claimed: full command-surface excellence.
```

Treat the number as a scoped judgment, not a frequency calculated from passing checks. Explain why the estimate is calibrated at that level. Change it only when evidence changes a named gap. A live failure lowers it immediately; a reproduced live matrix or independent audit can raise it. “The agent feels better,” a green unit suite, and an unreproduced report are not evidence that changes it.

### Assessment exit

Exit with an assessment packet containing raw state, baselines, ranked map, protected invariant candidates, no-go/owner gates, initial confidence, and named residuals. Stop with a verified non-finding if no bounded target clears the bar. Ask one sharp question if the high-value target needs owner authority.

## 2. Bettable hardening

### Choose a bettable wager

Create a bet record before changing code. A target is bettable only when all fields are concrete:

```text
Observed failure/abuse path:
Source evidence (command, trace, fixture, or live reproduction):
Protected invariant:
Root-cause hypothesis and disproof plan:
Smallest causal control:
Deterministic oracle (exact command and expected result):
Real live journey and observable assertion:
Public behavior intentionally preserved/changed:
Blast radius and rollback:
Owner gate required?:
Residuals this wager will not close:
```

Reject a vague cleanup, an untestable safety claim, a broad redesign, an imagined fixture, or a proposal that requires a policy decision. Prefer one tight wager over a portfolio of cosmetic fixes.

### Prove the defect before fixing it

Reproduce the semantic failure using the real system path whenever safely possible. Capture the actual state transition, logs, wire response, or provider output. If an environmental explanation is offered—quota, load, a flaky dependency, a bad test runner—treat it as a hypothesis:

1. Instrument the state transition that would distinguish it from a product defect.
2. Repeat or isolate the observation.
3. Record the raw result and update the hypothesis.

Never excuse a failure as environmental because it is convenient or because a dashboard banner looks plausible. Conversely, validate the harness: malformed invocations, login shells, shared tmux sockets, ambient configuration, and test artifacts can create false failures.

### Make the causal fix

Fix the demonstrated cause, not the visible symptom. Recovery is useful only after the primary path is reliable and the remaining failure warrants recovery. Do not ship a recovery feature that masks a repeatable root cause.

Preserve behavior unless the owner explicitly authorizes change. Add a characterization test before changing disputed behavior. Test contracts at boundaries: exit status, durable output, submitted state, returned API field, generated artifact, or user-visible message.

Run applicable project gates before and after. Compare the protected public surface and explain every intentional difference. Keep checks baseline-relative: existing unrelated failures do not make the target impossible, but no new relevant failure is acceptable.

### Verify the real journey

Tests can miss turn barriers, races, startup noise, provider/TUI prompts, scheduling, and cross-process state. Exercise the valuable journey against its real boundary. For example:

```text
create → submit → wait → revise/retry → complete/reap
install → configure → execute → observe output → recover from interruption
build → publish candidate → clean install → execute user path
```

Assert a durable effect, not only a process exit: file content, remote job ID, state transition, output record, transaction, or installed command behavior. Before blaming the product, validate the harness: argument quoting, shell/login mode, isolated tmux or process state, ambient configuration, and realistic provider startup time. Include failure injection when it is part of the promised guarantee. Add modest concurrency and a short soak when coordination is material; scale only after the single journey is reliable. For fleets, record every lane’s submit, effect, completion, and result status; never hide failures in an aggregate pass rate.

### Bettable gate

Clear this gate only when:

- The original failure is reproduced or the evidence establishes why it cannot be reproduced.
- The deterministic oracle shows the hardened failure path is blocked or honest.
- A targeted positive path proves intended behavior remains.
- The real live journey shows the actual valued outcome.
- Relevant load, concurrency, provider, recovery, and failure-injection evidence is recorded.
- A capable independent checker reads the diff and oracle output and verifies the claim.
- Known residuals are named, bounded, and reflected in confidence.

This supports an explicitly justified, scope-limited confidence estimate for the named invariant. The number is not a probability inferred from test counts and does not imply a comprehensive quality claim.

## Delegation and provider routing

### Allocate work deliberately

Consult `clawmeter` or another trustworthy utilization/cost/headroom source when it is available. Do not claim it exists or trust stale quota data. Use GPT-5.6 only; unavailable GPT-5.6 capacity is a blocker, not permission to fall back to 5.5/5.4/5.3. Route within 5.6:

- Luna: mechanical/light checks that do not decide acceptance;
- Terra: bounded implementation, repeated live smoke matrices, short soaks, narrow probes, fixture capture, drafting;
- Sol: system mapping, target selection, causal reasoning, synthesis, and final independent judgment;
- humans: approvals, security choices, irreversible external actions, policy, and decisions with unbounded downside.

Throttle or stop when headroom is hot. Cheap models are not automatically valid checkers: the checker must be capable enough and at least as strong as the maker for the judgment it makes.

### Report contract for each worker

Use an isolated worktree/directory and a bounded task. Waspflow lanes and worktrees are one implementation when available; any equivalent isolation and contract is acceptable. Give every worker:

```text
Role and distinct failure class:
Revision and isolated worktree path:
In-scope surfaces; explicit exclusions:
Time/cost and command limits:
Allowed mutations (prefer none for red teams):
Exact repro/probe commands:
Evidence to preserve (raw output, trace, fixture, diff):
Report: finding ID; severity; exact reproduction; expected vs actual;
        raw evidence path; affected revision; proposed next step; confidence;
        false-positive risks and untested edges.
```

Require workers to report `no finding` with what they tested. Do not let a lane’s “success” mean merely that a pane opened or a prompt was pasted; define submission and completion by durable provider-neutral evidence.

## Red-team the bettable invariant

Run independent adversarial lanes after the core change. Give each a distinct failure class to avoid parallel happy-path testing:

| Failure class | Example attacks |
| --- | --- |
| Input/trust boundary | shell/path/prompt injection, malformed flags, auth/permission edge, secret exposure |
| State and lifecycle | corrupt/incompatible state, race/lost update, kill mid-operation, retry/recovery, result laundering |
| Journey and provider boundary | startup noise, submission failure, stale turn/idle signal, blocked human prompt, mixed provider/load behavior |
| Release and reporting | stale branch, absent publication, wrong tag/digest, installer path, rollback, false success summary |

Independently reproduce every reported finding in a fresh environment without trusting the worker’s pipeline, test data, or severity label. Fix confirmed issues; record disproven reports as test/harness lessons. The maker cannot validate its own red-team conclusion.

## 3. Excellence audit

Run this only after bettable hardening has a credible evidence packet. It is intentionally broader and has its own independent gate.

Give a different-model auditor at least as capable as the maker a clean worktree at the exact candidate revision; prefer a different lineage. Ask it to read the diff—not the maker’s summary—and audit all affected command/API/config/documentation/recovery surfaces. Require a `PASS`/`REVISE`/`REJECT` report with command evidence. If no capable independent auditor is available, stop blocked rather than self-grade.

Audit at least:

1. Valid and malformed inputs, unknown flags/options, boundary values, and exit statuses.
2. Corrupt, absent, incompatible, and concurrent state; never turn unknown into success.
3. Interrupted, timed-out, stalled, and recovery paths; errors must remain honest and useful.
4. User-visible error quality, observability, docs/help/config discoverability, and no raw internal tool leakage where the project promises a product boundary.
5. Public-surface preservation, changed-file scope, secrets/dependencies/policy scans, and behavior regressions.

Require independent reproduction of every finding before changing code. Then rerun the deterministic and live evidence affected by the correction. A green reactive test set is not a systematic audit.

### Excellence gate

Pass only when the independent verdict is `PASS`, all confirmed affected-surface seams are resolved or owner-classified, no silent lie/corruption/result laundering remains in scope, and the packet states which whole-project surfaces were not audited. If a residual is small but real, say “bettable, not excellence” rather than blending the two claims.

## 4. Release and exact-artifact verification

First decide whether the owner authorized a release. Without authorization, stop at `release-ready` and report the candidate, gate outputs, rollback, and remaining action.

For an authorized release:

1. Run the project’s actual release path and capture raw output.
2. Determine the exact public artifact: immutable tag/commit, package version and checksum, image digest, release URL, binary, or installer revision.
3. Verify remote Git state, release metadata, and artifact contents independently; a green CI/release job is not enough.
4. Use a clean checkout, environment, or install location to obtain that exact artifact—not the working tree—and run the release gate.
5. Run a realistic install/use journey and record the result.
6. Record rollback/forward-fix instructions and monitoring/health evidence.
7. Compare post-release commits with the artifact. Explain every difference by the release policy; do not claim the artifact contains untagged work.

Report `released` only after these checks. Otherwise report `release-ready`, `publication failed`, or `artifact verification failed` with the smallest next action.

## Concrete traps to actively test

| Trap | Required response |
| --- | --- |
| `producer | head` or similar pipeline appears green | Capture the producer’s exit status without a masking pipeline; use `pipefail`, temporary output, or explicit status handling. |
| Green unit suite | Run the live journey; test races, timing, provider boundaries, and durable effects. |
| Curated compatibility/model lists | Prefer authoritative live discovery. Reject a list that will rot unless it has a proven refresh and honesty contract. |
| Recovery command looks attractive | Reproduce and fix the causal primary-path failure first; recovery must not hide it. |
| Handwritten prompt/regex fixture | Capture verbatim provider output, preserve it as ground truth, and wait long enough for the real interaction. Demote wording to a hint when a structural signal exists. |
| “It is environmental” | Prove the environmental mechanism by instrumenting the causal transition; test harness defects too. |
| Status says branch/release/fleet healthy | Check raw Git status/log/remotes, per-lane outcomes, publication metadata, and the exact artifact. Never use fleet averages to conceal failed lanes. |
| Exit code accidentally follows logging or a conditional | Test every success and failure path at the caller boundary; successful commands must explicitly succeed. |
| Interactive human prompt | Detect and surface it; never auto-answer approvals, security choices, or model/cost decisions without authority. |

## Compact final report

Use this shape even when the artifacts remain in chat:

```text
Verdict: <blocked | non-finding | bettable | bettable-not-excellent | release-ready | publication-failed | artifact-verification-failed | released>
Scope/invariant:
Revision and exact artifact (if released):
Evidence: <commands → results; live journey; independent verdict>
Confidence: <number and scope, or omitted because it would mislead>
Residual gaps: <ID, impact, owner/action, why not closed>
Behavior/public-surface changes: <none or authorized list>
Rollback and next action:
```

Do not write “done,” “excellent,” or “released” unless the corresponding gate has passed. A truthful stop with one missing proof is stronger than an unearned company-level claim.
