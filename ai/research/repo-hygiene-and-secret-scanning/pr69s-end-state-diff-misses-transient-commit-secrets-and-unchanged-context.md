---
title: "Vana smart-contracts PR 69's end-state diff misses secrets present only in intermediate pushed commits and misses unchanged neighboring secret context"
date: 2026-08-11
topic: repo-hygiene-and-secret-scanning
tags: [private-keys, pre-push, gitleaks, git-history, ethereum]
status: draft
sources: [pr69, local-reproduction]
source_session: unknown
---

## CLAIMS

- PR 69's pre-push hook invokes the scanner with `--diff base..local`, and the scanner implements that mode with `git diff --unified=0`; this compares endpoint trees rather than scanning every commit object that the push will upload. [pr69]
- In a local reproduction, commit A added an inline key-shaped value and commit B removed it. The endpoint trees were identical. PR 69 reported `0 64-hex candidate(s)`, while the proposed gitleaks commit-range command reported one leak. [local-reproduction]
- Diff-mode context is built only from lines returned by the zero-context diff. In a local reproduction where `export const privateKey =` was unchanged and only the next line's value was added, PR 69 reported one candidate but zero findings in offline pre-push mode. [pr69][local-reproduction]
- PR 69's pre-push mode deliberately disables RPC checks, so the on-chain verification that distinguishes it from a pattern scanner runs only after the push, in CI. [pr69]
- PR 69's CI job is advisory: the job uses `continue-on-error: true`, and its scan command omits `--fail-on-verified`. [pr69]

## SOURCES

**pr69**
URL: https://github.com/vana-com/vana-smart-contracts/pull/69
Accessed: 2026-08-11

**local-reproduction**
Path: `/home/tnunamak/.tmp/pr69-codex-review`
Accessed: 2026-08-11
Evidence: On an isolated detached worktree of PR head `edbd95b66e94f82a734b21322ca26f972c904a60`, commits `a406c61` and `9570f81` added and removed an inline test key. `scan.ts --diff a3538d4..9570f81 --offline` returned zero candidates; `gitleaks git --log-opts=a3538d4..9570f81` returned one finding. Commits `36eeaac` and `2963624` reproduced the unchanged-neighbor case; keyscan returned one candidate and zero findings.

## SYNTHESIS

PR 69 contains a valuable timing correction: an OSS private-key check must run before the push, because CI observes the leak after it reaches a public remote. But its primary preventive path does not use the on-chain verifier, does not scan all uploaded commit objects, and has a context-construction defect. It should not replace a central commit-history scanner. The credible design is layered: a shared, required commit-range CI check across repos; the same commit-range logic in an installed pre-push hook for public repos; and the chain-derived verifier as an optional advisory or scheduled semantic check after its scanner defects are fixed.
