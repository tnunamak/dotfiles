This confirms it design-wise: `consumer_pin_required` is `true` (fail-closed, activated by `4c51c5722`), and by design this check fails whenever a PR touches guarded paths that haven't yet been repinned in data-connectors — that's the whole point of the "signal." Any open PR touching `auth.ts`, connector-runtime, etc. will legitimately fail this check until data-connectors repins after merge. This is working as intended, not a bug to patch in this repo.

## Root cause

The "Check data-connectors' recorded pin" job in `.github/workflows/consumer-drift-signal.yml` fails with:

```
FAIL: one or more guarded paths changed since PDP-Connect/data-connectors last pinned this repo
at 1577a34e5c9f5934c83ed41e0b5aa735744eb119:
Changed paths:
packages/connector-protocol/artifact.json
packages/connector-protocol/src/auth.test.ts
packages/connector-protocol/src/auth.ts
```
(PR #94, run 34536363351/34536359750). PR #64 fails the same way with `packages/collector-runtime/artifact.json` and `packages/connector-protocol/artifact.json` as the changed guarded paths (merge-base `1577a34e5c9f5934c83ed41e0b5aa735744eb119`).

I verified `git merge-base origin/<PR-branch> origin/main` equals the pinned SHA exactly for both PRs, and that `origin/main` itself has **zero diff** against the pin on guarded paths. So this isn't a stale/wrong pin on `main` — it's each PR's own unmerged commits (`e408d2fbf` "fix(auth): resolve a sign-in pair both-or-nothing..." for #94; collector-runtime/connector-protocol artifact changes for #64) that legitimately touch guarded paths ahead of the recorded pin.

## Fix

**None applied.** This is neither a stale pin nor a broken check — it's the signal working as designed. The workflow's own header comment and `.github/consumer-drift-signal-config.json` (`consumer_pin_required: true`, activated in commit `4c51c5722`) describe exactly this: fail-closed reporting that guarded paths have moved beyond data-connectors' last recorded pin. Any open PR touching those paths will fail this check until data-connectors repins post-merge (the documented "coordinated repin procedure": data-connectors rebuilds vendored copies and updates `.github/cross-repo-pins.json` after this repo's PR lands). Silencing or "fixing" it in data-connect would defeat its purpose — it would let genuinely drifted guarded-path changes merge without the required downstream repin coordination.

I did not create the `fix/connector-pin-check` branch or commit anything, since no code change is warranted here.

## Verification

- `gh run view <id> --log-failed` on both failing runs, quoted above.
- `git merge-base origin/fix/salvaged-connector-and-enrollment-fixes origin/main` → `1577a34e5c9f5934c83ed41e0b5aa735744eb119` (matches recorded pin exactly).
- `git merge-base origin/fix/webpush-urgency-high origin/main` → same SHA.
- `git diff <pin>..origin/main -- <guarded paths>` → empty (main is clean against the pin).
- `git diff <pin>..<PR-branch> -- <guarded paths>` → real, substantive changes on both branches (shown above).

## Not verified

No CI run confirms anything, because I made no change to verify — there is nothing to submit for CI. If you disagree with this diagnosis (e.g., you expected this check to be scoped to `main` only, or not to run on PR branches at all), that would be a deliberate design change to `consumer-drift-signal.yml`'s trigger scope, and I'd want explicit confirmation before touching a fail-closed gate that was intentionally activated.

**Branch/commit created:** none.
