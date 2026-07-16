---
title: "This llama-bee.service config uses none of Bee's DFlash/TurboQuant differentiators, so it can switch to official llama.cpp with no feature loss, only a lost loop-guard safety net"
date: 2026-07-15
topic: llm-serving
tags: [llama.cpp, bee, beellama, mtp, qwen, speculative-decoding, gguf]
status: draft
sources: [bee-arg-audit, upstream-arg-audit, mtp-pr-22673, mtp-pr-23269, issue-23577, reddit-may-2026-shootout]
---

## CLAIMS

- Every flag in `/home/tnunamak/.local/bin/llama-bee-start`'s `server_args` (`--ctx-checkpoints`,
  `--checkpoint-min-step`, `--cache-ram`, `--kv-unified`, `--spec-draft-p-min`,
  `--cache-type-k/v-draft`, `--reasoning`/`-budget`/`-format deepseek`, `--no-host`,
  `--chat-template-kwargs`, `--slots`, `--spec-type mtp`, `--spec-draft-n-max`, etc.) exists in
  official `ggml-org/llama.cpp` master `common/arg.cpp` (fetched live 2026-07-15). [bee-arg-audit] [upstream-arg-audit]
- `--spec-type mtp` (native MTP/speculative decoding for Qwen3.6-class models) merged upstream via
  PR #22673 on 2026-05-16, with a cleanup pass in PR #23269 by ggerganov after a regression report
  (#23230). [mtp-pr-22673] [mtp-pr-23269]
- The flag's accepted value spelling churned during that window — community command lines in
  issue #23577 show both `--spec-type mtp` and `--spec-type draft-mtp` in use across nearby
  builds, and one report shows a build rejecting `draft-mtp`. Verify the exact accepted string
  against whichever official build/tag is actually deployed. [issue-23577]
- This deployment's KV cache types (`q5_0`, `q4_1`, `q8_0` for draft) are standard ggml quant
  types (IDs 3/6, present upstream); Bee's actual differentiator cache types
  (`turbo2`/`turbo3`/`turbo4`/`turbo2_tcq`/`turbo3_tcq`, ggml type IDs 42-46, TurboQuant/TCQ) are
  not used anywhere in the wrapper. [bee-arg-audit]
- The local Bee clone (`~/applications/beellama`) is Bee `main` + 16 commits: 7 cherry-picked
  upstream checkpoint fixes + 9 agent-authored MTP commits. Of those 9, one pair
  (`f6040736c`/`dd93447ef`, a decode-batch cancellation-latency fix) is a commit immediately
  followed by its own revert — `git diff main~16 main` on the affected files is empty, so it is
  net-zero and not a live differentiator. [bee-arg-audit]
- The remaining 7 commits patch `tools/server/server-loop-guard.{cpp,h}` and
  `tools/server/server-mtp-replay.{cpp,h}` — both return HTTP 404 fetched from
  `raw.githubusercontent.com/ggml-org/llama.cpp/master`, i.e. Bee-only abstractions with no
  upstream equivalent. Upstream `server-context.cpp` (5,337 lines) has zero matches for
  `loop_guard`. [bee-arg-audit] [upstream-arg-audit]
- The commits' own doc (`docs/ops/mtp-loop-guard-force-close-fix-2026-07-13.md`) states twice
  that the fixed path is explicitly non-DFlash-only ("DFlash does not schedule or enter the MTP
  committed-prefix replay path"), confirming the bugs are in Bee's own loop-guard/MTP-replay
  interaction layered on top of upstream's MTP mechanism, not in the MTP mechanism itself.
  [bee-arg-audit]
- Upstream issue #23577 ("MTP with Qwen3.6 27B outputs repeated //// after long session") is the
  closest upstream analogue by symptom, open since 2026-05-23, still open 2026-07-15, 13 distinct
  reporters across CUDA/ROCm/Vulkan. [issue-23577]
- The most recent root-cause analysis in that thread (2026-07-15, same day) attributes at least
  one variant to a numerical overflow in the CUDA flash-attention tile kernel
  (`ggml/src/ggml-cuda/fattn-tile.cuh`, half2 VKQ accumulator on GFX11 D=DV=256 tiles), not a
  scheduler/loop-guard bug. Diffing Bee's copy of that file against upstream shows only
  formatting/ordering differences — Bee inherits the same kernel and the same exposure to this
  bug. [issue-23577] [bee-arg-audit]
- No indexed June-July 2026 r/LocalLLaMA sentiment recommends Bee specifically for MTP serving;
  every source (including Bee's own README/marketing) frames Bee's value as DFlash + TurboQuant,
  a separate axis from MTP, which mainline llama.cpp now provides natively and which multiple
  independent sources (Simon Willison, Unsloth docs, NVIDIA dev forum, jarvislabs.ai) document as
  the standard way to run Qwen3.6-27B-MTP GGUFs. [reddit-may-2026-shootout]

## SOURCES

**bee-arg-audit**
URL: (local) `~/applications/beellama` git history + `/home/tnunamak/.local/bin/llama-bee-start`
Accessed: 2026-07-15
Quote: "DFlash does not schedule or enter the MTP committed-prefix replay path." (docs/ops/mtp-loop-guard-force-close-fix-2026-07-13.md, commit bf85489b8)

**upstream-arg-audit**
URL: https://raw.githubusercontent.com/ggml-org/llama.cpp/master/common/arg.cpp
Accessed: 2026-07-15
Quote: "{\"-ctxcp\", \"--ctx-checkpoints\", \"--swa-checkpoints\"}, \"N\", ... [(more info)](https://github.com/ggml-org/llama.cpp/pull/15293)"

**mtp-pr-22673**
URL: https://github.com/ggml-org/llama.cpp/pull/22673
Accessed: 2026-07-15
Quote: "llama + spec: MTP Support" — merged 2026-05-16.

**mtp-pr-23269**
URL: https://github.com/ggml-org/llama.cpp/pull/23269
Accessed: 2026-07-15
Quote: "llama : MTP clean-up"

**issue-23577**
URL: https://github.com/ggml-org/llama.cpp/issues/23577
Accessed: 2026-07-15
Quote: "The GFX11 D=DV=256 fast-FP16 tile in ggml/src/ggml-cuda/fattn-tile.cuh keeps the softmax maximum and denominator in F32, but accumulates the V-weighted numerator (VKQ) in half2. ... the half2 numerator overflows on the ninth contribution and the FA output becomes Inf." (redthing1, 2026-07-15)

**reddit-may-2026-shootout**
URL: https://hackobar.com/item/reddit-beellamacpp-advanced-dflash-amp-turboquant-with-support-of-r-7ef7 ; https://github.com/Anbeeld/beellama.cpp
Accessed: 2026-07-15
Quote: "a llama.cpp fork ... that keeps the familiar llama.cpp tools and server flow, then adds DFlash speculative decoding, adaptive draft control, TurboQuant/TCQ KV-cache compression, and reasoning-loop protection"

## SYNTHESIS

For *this specific deployment* the fork-vs-upstream question resolves cleanly: the config was
already living entirely inside upstream-equivalent territory (standard MTP, standard cache
types), so Bee's only real leverage here was the loop-guard safety net it added on top — not any
Bee-exclusive acceleration. Switching removes that safety net but not any throughput or context
capability. The honest risk is symmetric across forks: a real, open, partially-diagnosed upstream
MTP repetition bug (#23577) that neither fork currently fixes, since (at least one variant of) its
root cause lives in a shared, unmodified CUDA kernel. Decision: migrate, add an
operational/client-side degenerate-loop guard to compensate for the removed Bee-specific
safety net, and track #23577 independently of the fork choice. Full evidence trail:
`/home/tnunamak/.tmp/bee-vs-upstream-llamacpp-0715.md`.
