---
title: "Qwen3.6 large-prefill checkpoint churn is disabled by zero context checkpoints while preserving flat q8 flash-attention throughput"
date: 2026-07-15
topic: llm-serving
tags: [llama.cpp, qwen3.6, checkpoints, prefill, prompt-cache, cuda]
status: draft
sources: [local-daisy-measurement, llama-22746, llama-23181, llama-23371]
source_session: 104fc3d9-a1d2-4777-affb-c5654d861214
---

## CLAIMS

- On official llama.cpp b10034 (`505b1ed1`), Qwen3.6-27B with q8_0 K/V, 102,400 context, one slot, and 16 context checkpoints emitted repeated erase/create churn for approximately 198-209 MiB checkpoints during a failed large prompt. [local-daisy-measurement]
- With only `--ctx-checkpoints 0` changed, fresh 2k, 10k, 20k, and 60k deterministic prompts completed at 0.840, 0.793, 0.822, and 0.996 ms per prompt token respectively; a separate fresh 60,015-token OpenAI chat request completed prefill at 0.997 ms per token. [local-daisy-measurement]
- The passing 60k runs retained `--cache-ram 4096`, mmproj, `--no-mmap --mlock`, MTP, and `--reasoning-budget -1`. [local-daisy-measurement]
- llama.cpp issue #22746 reports Qwen3.6 hybrid/recurrent checkpoint-chain invalidation and forced prompt reprocessing. [llama-22746]
- llama.cpp issue #23181 reports that `--cache-ram 0` does not disable context checkpoint creation. [llama-23181]
- llama.cpp issue #23371 reports long-context checkpoint retention and mmproj-restore VRAM pressure on Qwen3.6-27B with MTP and vision. [llama-23371]

## SOURCES

**local-daisy-measurement**
URL: /home/tnunamak/.tmp/daisy-engine-sol-0715.md
Accessed: 2026-07-15

**llama-22746**
URL: https://github.com/ggml-org/llama.cpp/issues/22746
Accessed: 2026-07-15

**llama-23181**
URL: https://github.com/ggml-org/llama.cpp/issues/23181
Accessed: 2026-07-15

**llama-23371**
URL: https://github.com/ggml-org/llama.cpp/issues/23371
Accessed: 2026-07-15

## SYNTHESIS

For this single-slot deployment, context checkpoints were the causal second
bottleneck after the q8 flash-attention correction. Disabling checkpoints is
more precise than disabling the independent RAM prompt cache and preserves
vision plus the existing memory-loading policy. The tradeoff is weaker
checkpoint-based rollback/reuse for multi-turn hybrid contexts; upstream's
Qwen3.6 checkpoint behavior remains an open concern for that separate workload.
