---
title: "MTP hybrid Qwen serving with four slots needs measured headroom because 131k unified KV is aggregate and speculative rollback expands recurrent state"
date: 2026-07-15
topic: llm-serving
tags: [llama.cpp, beellama, qwen3.6, mtp, kv-cache, vram, concurrency]
status: draft
sources: [llama-parallel, llama-mtp-pr, llama-mtp-maintainer, llama-cache-ram, bee-docs, qwen-model-card]
---

## CLAIMS

- In llama.cpp unified-KV mode, `--ctx-size` is a cache shared across sequences; parallel requests consume that aggregate budget rather than each receiving a separate full-size allocation. [llama-parallel]
- Upstream MTP creates a separate draft context/KV cache and states that parallel decoding is supported but not fully optimized; a maintainer specifically said batching recurrent Qwen3.x with MTP on one machine does not currently benefit from parallel processing. [llama-mtp-pr] [llama-mtp-maintainer]
- `--cache-ram` bounds the host-RAM prompt cache, not the live GPU KV cache; upstream describes it as an extra-slot prompt cache in regular RAM. [llama-cache-ram]
- Bee documents `q5_0` K plus `q4_1` V as its quality-sensitive Qwen cache pair, but calls for backend validation before relying on Turbo/TCQ cache types for a deployment. [bee-docs]
- Qwen3.6-27B is a 64-layer hybrid model with 16 full-attention layers and a native 262,144-token context. [qwen-model-card]

## SOURCES

**llama-parallel**
URL: https://github.com/ggml-org/llama.cpp/discussions/4130
Accessed: 2026-07-15

**llama-mtp-pr**
URL: https://github.com/ggml-org/llama.cpp/pull/22673
Accessed: 2026-07-15

**llama-mtp-maintainer**
URL: https://github.com/ggml-org/llama.cpp/pull/22673#issuecomment-2902208373
Accessed: 2026-07-15

**llama-cache-ram**
URL: https://github.com/ggml-org/llama.cpp/pull/16391
Accessed: 2026-07-15

**bee-docs**
URL: https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-qwen36-dflash.md
Accessed: 2026-07-15

**qwen-model-card**
URL: https://huggingface.co/Qwen/Qwen3.6-27B
Accessed: 2026-07-15

## SYNTHESIS

For a four-slot service, call `--ctx-size 131072` an aggregate shared context, not “131k per slot”; the deterministic worst case is roughly 32k per simultaneously full slot. MTP's extra context and hybrid-model rollback state mean static VRAM arithmetic is not sufficient. Preserve the known cache pair first, treat partial target-layer CPU offload as the conservative VRAM release valve, and measure a four-slot sustained workload before considering more aggressive Bee-only cache compression.
