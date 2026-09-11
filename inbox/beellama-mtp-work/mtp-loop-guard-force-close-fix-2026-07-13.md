# MTP loop-guard force-close rollback fix (2026-07-13)

## Scope

Fix the MTP checkpoint rollback path where the loop-guard callback has already
accepted the triggering token and transitioned either to force-close or stop.
The fix is limited to the MTP replay boundary in
`tools/server/server-context.cpp` and MTP hidden-state handling in
`common/speculative.cpp`, with the server-owned replay transaction in
`tools/server/server-mtp-replay.cpp` and one offline regression executable.

## Transaction invariant

The accepted prefix, sampler state, loop-guard state, output counters, and
target/draft context must advance together. An ordinary partial MTP acceptance
still restores every snapshot and retries. A callback-induced loop-guard
transition instead restores only the contexts, marks the accepted prefix for a
single replay, and retains the committed sampler/control state.

The next scheduler pass re-evaluates that prefix into the restored contexts
without accepting it a second time, then emits every committed prefix token
once. It samples the next token from the final replay row only if no replayed
token has already made the slot terminal; otherwise it releases after the last
committed token. MTP explicitly advances `pending_h` to that final replay row
before the next forced token reaches `ctx_dft`; ordinary acceptance continues
to select the pre-final accepted row. While force-close is active, the existing
non-DFlash `common_sampler_blocks_speculative()` gate keeps subsequent tokens
on ordinary decode until the reasoning budget reaches `DONE`.

## Preserved behavior

- Ordinary MTP mismatch/partial-accept checkpoint rollback still restores the
  sampler, loop guard, stop state, counters, and retries.
- DFlash does not schedule or enter the MTP committed-prefix replay path.
- The replay avoids double-counting the draft attempt and does not re-accept
  the callback-triggering token.
- A committed stop drains all already-accepted replay output before release;
  it cannot sample or generate a new token afterward.
- MTP's first forced-token draft input is copied from the final replay hidden
  row, not the ordinary pre-final acceptance row.

## Follow-up audit correction

The independent review of the first fix identified that replay's normal
`common_speculative_accept(..., ids.size() - 1)` correctly maintained
acceptance accounting but also reset MTP `pending_h` to the pre-final row.
The replay transaction now performs that ordinary accept unchanged, then makes
one MTP-only committed-replay handoff to the final verification row. The next
draft decode therefore consumes the hidden state for the triggering replay
token exactly once. This applies after either a FULL checkpoint restore or an
RS restore whose rollback exceeds the RS window; DFlash never calls this MTP
handoff.

The prior regression executable inspected production source text. It has been
replaced with a behavioral oracle over the narrow production MTP hidden-state
transfer seam used by normal acceptance, committed replay, and draft input
assembly.

## Evidence hardening follow-up

The server now owns a `server_mtp_replay` transaction that is armed only for a
FULL checkpoint, or an RS checkpoint whose rollback exceeds the RS window,
when non-DFlash MTP has already committed a loop-guard control transition. The
same transaction is called by the server to:

- schedule that one context replay when forcing makes `n_draft_max` zero;
- verify that `update_batch()` advanced the restored prompt by the sampled
  token plus the replay prefix;
- account for accepted draft tokens and exactly-once replay output; and
- choose either the next ordinary/forced sample or slot release after a stop.

This replaces local FULL/RS fixture booleans with a model-free execution of
the actual production transaction. The concrete MTP implementation used by
`common_speculative_commit_mtp_replay()` also delegates its final-row handoff
to the tested production hidden-state commit seam.

## Review3 scheduler-to-batch correction

Review3 found that a pending replay was admitted with `n_draft_max == 0`, then
the generic draft-limit code immediately resized its retained prefix to zero
before `update_batch()`. The draft-limit decision now belongs to
`server_mtp_replay::apply_draft_limit()`: a pending context-repair replay
retains its token and log-prob payload exactly once, while every idle path
continues to use the former truncation behavior. The server calls this method
immediately before its existing `update_batch()` path.

The regression drives retained FULL and long-RS prefix payloads through that
production scheduler-to-batch limit seam at zero draft limit, then verifies the
post-batch position transition and the release outcome. It also proves that
ordinary rollback and DFlash still truncate at the same zero limit.

## Review4 committed-stop output correction

Review4 identified that `process_token()` records a replayed token but reports
false when a loop-guard stop was already committed. The former server loop
treated that report as permission to break immediately, so a prefix with more
than one accepted token lost its suffix, including the triggering token.

`server_mtp_replay::record_output()` now owns the output-loop decision after
each emitted replay token. It returns `EMIT_NEXT` until the committed prefix is
fully drained, latches any terminal result, and returns `RELEASE` only after
the final prefix token. Only a non-terminal final token returns `SAMPLE_NEXT`.
The server consumes that action directly, so neither a committed stop nor an
emergent terminal replay result permits a new sample before release.

## Review5 Release-oracle correction

Review5 found that the regression used standard `assert(...)` for every
behavioral call. Release builds define `NDEBUG`, so that executable evaluated
none of the replay, hidden-row, forcing, or output-loop expressions and could
pass with no production symbols linked into the test path.

`test-mtp-loop-guard-rollback` now uses a test-local, always-on `TEST_CHECK`.
It evaluates the expression in every build and aborts with the file, line, and
expression on failure. This changes no other test target or production build
flags. The Release executable now retains MTP replay methods plus the MTP
hidden-row production calls; disassembly shows calls to the latter. As a
mutation check, changing the expected first forced token from `102` to `103`
made the Release executable abort at that check (exit status 134); the expected
value was then restored before the final runs.

## Offline evidence

CPU-only Debug build directory:

`/home/tnunamak/.tmp/beellama-mtp-loopguard-fix-build`

Commands run:

```sh
cmake -S . -B /home/tnunamak/.tmp/beellama-mtp-loopguard-fix-build \
  -DGGML_NATIVE=OFF -DGGML_OPENMP=OFF -DGGML_CURL=OFF \
  -DLLAMA_BUILD_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build /home/tnunamak/.tmp/beellama-mtp-loopguard-fix-build \
  --target test-mtp-loop-guard-rollback test-reasoning-budget \
  test-server-loop-guard test-dflash-plumbing -j 4
ctest --test-dir /home/tnunamak/.tmp/beellama-mtp-loopguard-fix-build \
  --output-on-failure \
  -R 'test-(mtp-loop-guard-rollback|reasoning-budget|server-loop-guard|dflash-plumbing)'

cmake -S . -B /home/tnunamak/.tmp/beellama-mtp-loopguard-release-build \
  -DGGML_NATIVE=OFF -DGGML_OPENMP=OFF -DGGML_CURL=OFF \
  -DLLAMA_BUILD_TESTS=ON -DCMAKE_BUILD_TYPE=Release
cmake --build /home/tnunamak/.tmp/beellama-mtp-loopguard-release-build \
  --target test-mtp-loop-guard-rollback test-reasoning-budget \
  test-server-loop-guard test-dflash-plumbing -j 4
ctest --test-dir /home/tnunamak/.tmp/beellama-mtp-loopguard-release-build \
  --output-on-failure \
  -R 'test-(mtp-loop-guard-rollback|reasoning-budget|server-loop-guard|dflash-plumbing)'
```

Result: all four tests passed in both Debug and Release builds.
`test-mtp-loop-guard-rollback` is a behavioral oracle over the production
server MTP replay transaction and hidden-state transfer seam. It executes
distinguishable FULL and long-RS restore paths, ordinary rollback, DFlash
exclusion, a zero-draft-limit forcing replay, position validation, exactly-once
replay accounting/output, stop release, and forced-sequence completion. It also
rejects negative/out-of-range rows, zero dimensions/rows, malformed pending and
verification vector sizes, and a null draft-input destination. The
scheduler-to-batch payload test retains FULL and long-RS replay tokens/log-probs
at zero draft limit and preserves ordinary and DFlash truncation. Its two-token
committed-stop case drives the production output-loop action: the first
terminal token requires `EMIT_NEXT`, the second is emitted and then yields
`RELEASE`, and any additional output is rejected. It does not read production
source text; its checks remain active under `NDEBUG`.

The shell also printed a stale `ctest` wrapper interpreter warning before CTest
ran; the command exited successfully and CTest itself reported all four tests
passing.

## Confidence and limits

High confidence in the transaction/lifecycle fix and its deterministic
coverage. No model, network, live server, tmux session, gateway, or installed
binary was used. Therefore this does not claim a hardware/model throughput or
end-to-end HTTP-server validation.
