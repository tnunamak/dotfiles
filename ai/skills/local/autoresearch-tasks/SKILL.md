---
name: autoresearch-tasks
description: Discover and generate autonomous-agent-friendly tasks for any repository. Use when users want to find what an agent can work on autonomously, bootstrap test oracles, assess repo "auto-researchability", generate verifiable tasks with anti-Goodhart constraints, or plan long-horizon autonomous coding work. Also triggers on "what can an agent work on", "find autoresearch tasks", "generate oracle", "bootstrap tests", "make this repo auto-researchable", or any request about finding safe autonomous agent work.
---

# Autoresearch Task Generator

Discover or generate tasks that an autonomous coding agent can pursue for a long time without being able to fake success by deleting, narrowing, or disabling the system.

## Core principle

Do not ask "What can the agent optimize?"

Ask: **"What can the agent optimize without being able to win by making the system smaller, dumber, or less useful?"**

A bare metric like "reduce errors" or "improve code quality" is Goodhartable. The agent can satisfy it by shrinking functionality. The property you actually care about is a **robust, behavior-preserving test oracle**.

## Terminology

Use these terms consistently:

| Term | Meaning |
|------|---------|
| **Verifiable task** | A task with an objective evaluator |
| **Test oracle** | The mechanism that says whether a change is correct |
| **Robust test oracle** | An oracle that is hard to game |
| **Behavior-preserving robust test oracle** | An oracle that makes deletion-based cheating hard |
| **Reward hacking / specification gaming / Goodharting** | Satisfying the metric while violating the real intent |
| **Oracle bootstrapping** | Creating the evaluator the repo does not already have |

## Workflow

### Phase 1: Repo signals inspection

Inspect these artifacts to understand the repo:

- README and docs
- Package manifests / language build files
- Makefile / justfile / task runner config
- docker-compose / Docker / devcontainer
- CI configs (.github/workflows, .gitlab-ci, etc.)
- Framework conventions
- Routes / controllers / CLI entrypoints
- Migration / schema files
- Test directories (even if sparse)
- Existing linters, formatters, type checkers

### Phase 2: Infer repo characteristics

From the signals, determine:

1. What kind of app/library this is
2. What parts are easiest to build and run
3. What public/observable surface exists
4. Whether the repo already has usable checks
5. What subsystem is narrowest and highest-value

**Observable surface** may include: web routes/pages, HTTP endpoints and response shapes, CLI commands and flags, exported package APIs, database schema and migrations, config keys, background jobs, files produced by normal workflows.

### Phase 3: Classify oracle tier

**Tier 1 — Strong existing oracle**: The repo already has tests/checks that constrain behavior well enough. These repos are ready for auto-research work against existing oracles.

**Tier 2 — Synthesizable oracle**: The repo lacks checks, but the agent can likely discover enough of the runtime surface to build a smoke oracle. The highest-value task is usually oracle bootstrapping.

**Tier 3 — No reliable oracle**: The repo is too ambiguous, too infrastructure-heavy, too stateful, or too broad for the agent to create a meaningful behavior-preserving oracle. Only read-only inventory work is justified. Human narrowing/specification is required.

### Phase 4: Generate task candidates

#### For Tier 1 repos (strong existing oracle)

Look for tasks that run against existing checks:

- Fixes for reproducible existing failures
- Dependency upgrades constrained by preserved behavior
- Lint/type cleanup constrained by preserved behavior
- Mechanical refactors inside a protected surface
- Expanding existing tests around already-known behavior

Even here, ask: can the agent pass by narrowing the surface area? If yes, add constraints.

#### For Tier 2 repos (synthesizable oracle)

The highest-value task is almost always:

> Bootstrap a behavior-preserving smoke oracle for the narrowest high-value runnable subsystem.

Concretely:
1. Discover how to build and run the repo
2. Infer its public or externally observable surface
3. Synthesize a behavior-preserving smoke oracle
4. Propose follow-on tasks that use that oracle

Good bootstrapping tasks:
- Bootstrap a smoke oracle for the primary server/web flow
- Generate a route/API/CLI surface manifest and lock it with snapshots
- Create minimal startup + healthcheck harness
- Synthesize fixtures/seed data for the happy path
- Build reproducible repro harnesses for known manual bugs
- Add contract tests around external interfaces
- Create migration/schema invariants if the DB layer is central

#### For Tier 3 repos

Be honest: recommend read-only inventory work or human escalation. A bad task recommendation is worse than no task recommendation.

Safe fallback tasks (lower value but safe):
- Secret scanning / dependency audit
- SBOM generation
- Architecture inventory documentation

### Phase 5: Score and rank candidates

Score each candidate task on 0-5 for:

| Dimension | Description |
|-----------|-------------|
| **Oracle strength** | Is there an executable, machine-checkable evaluator? |
| **Oracle robustness** | Is the oracle hard to game? |
| **Behavior preservation** | Does the oracle prevent deletion-based shortcuts? |
| **Scope tractability** | Can the scope be narrowed to a tractable subsystem? |
| **Expected autonomy duration** | Can the agent work for a while without human steering? |
| **Leverage created** | Does this task produce durable leverage for future work? |

**Reject** anything with behavior preservation < 3 or scope tractability < 3.

### Phase 6: Emit task packages

Do not just emit a task title. Emit a full **task package** for each recommended task:

```
## Task: [name]

**Why auto-research friendly**: [explanation]

**Oracle description**: [what checks success]

**Behavior-preserving safeguards**:
- [constraint 1]
- [constraint 2]
- ...

**Scope boundaries**: [what's in, what's explicitly out]

**Anti-Goodhart constraints**:
- Do not delete routes, commands, exported APIs, DB schema, or config keys unless explicitly allowed
- Do not reduce test count unless removed tests are provably obsolete
- Do not satisfy the task by disabling code paths, guards, checks, or features
- Flag large negative LOC diffs
- Flag deleted files outside generated/build/vendor paths
- Capture before/after surface manifest
- [task-specific constraints]

**Expected artifacts**: [what the agent should produce]

**Stop conditions**: [when to stop or escalate]

**Confidence**: [high/medium/low with reasoning]

**Scores**:
| Dimension | Score |
|-----------|-------|
| Oracle strength | X/5 |
| Oracle robustness | X/5 |
| Behavior preservation | X/5 |
| Scope tractability | X/5 |
| Autonomy duration | X/5 |
| Leverage created | X/5 |
```

## What NOT to recommend

These are tempting but usually poor auto-research tasks, especially without a strong existing oracle:

- Broad refactors
- "Fix code smells" / "reduce complexity" / "improve architecture"
- Dead-code deletion
- Reduce warnings / improve lint score (without behavior constraints)
- Vulnerability reduction without behavior constraints
- Broad dependency churn without an oracle
- Documentation-only busywork
- Increase test pass rate without protecting behavior

All of these can be gamed by making the system smaller.

## Anti-pattern: the key question

For every candidate task, ask:

> Can the agent achieve success without preserving the externally valuable behavior of the repo?

If **yes**, the task is unsafe or low-value for long autonomous runs. Either add constraints that make deletion expensive and visible, or reject the task.

## Report format

When analyzing a repo, produce a report with these sections:

1. **Repo summary** — what it is, what stack, what it does
2. **Oracle tier** — Tier 1/2/3 with justification
3. **Observable surface inventory** — what the agent can observe and test
4. **Existing checks assessment** — what tests/CI/linting exists and how robust it is
5. **Recommended tasks** — full task packages, ranked by composite score
6. **Tasks explicitly NOT recommended** — what might look tempting but fails the anti-Goodhart test
7. **Follow-on opportunities** — what becomes possible after the recommended tasks are done

For references on scoring rubrics and detailed schemas, see `references/scoring-guide.md`.
