---
title: "For Qwen3.6 on a 24 GiB GPU, q5_0 K plus q4_1 V is the practical default while q8_0 is a validation profile with a large context cost"
date: 2026-07-16
topic: llm-serving
tags: [qwen3.6, llama.cpp, kv-cache, q8, q5]
status: draft
sources: [anbeeld-kv-benchmark, bee-qwen36-quickstart, local-capacity-sweep, local-llama-quant-benchmark, q5-agentic-report]
source_session: 019f62b0-1ccd-7a10-90d2-69df8fa07969
---

## CLAIMS

- Bee's Qwen3.6 guide labels `q5_0` K plus `q4_1` V as the precision configuration for coding and other precision-sensitive work. [bee-qwen36-quickstart]
- Anbeeld's published KV benchmark labels q8/q8 as a validation and blame-isolation mode, q5/q5 as the normal-quality preset, and q5/q4_1 as the best default under VRAM constraint. On Q5_K_S weights, its reported 99.9%-tail precision is 94.62% for q8/q8 and 92.65% for q5/q4_1; on IQ4_XS weights at 128k, the corresponding figures are 98.49% and 96.50%. The author explicitly cautions that these perplexity/KLD diagnostics are not real-task accuracy. [anbeeld-kv-benchmark]
- On this RTX 3090, the pinned official llama.cpp all-quants build passed the warm request at 202,752 tokens with q5/q4_1 and failed at 203,776; q8/q8 passed at 145,408 and failed at 146,432 under the same one-slot MTP wrapper. [local-capacity-sweep]
- The q5 profile therefore exposes 57,344 more context tokens than q8 on this deployment, about 39.4% more than the q8 limit. [local-capacity-sweep]
- Independent weight-quantization data shows UD-Q5_K_XL closer to the reference distribution than lower-bit weights, and a separate report demonstrates that UD-Q5_K_XL can complete agentic coding tasks. Neither source is a controlled Q5-versus-UD-Q4_K_XL task-success comparison, so they do not quantify how many real coding failures a weight upgrade would prevent. [local-llama-quant-benchmark] [q5-agentic-report]

## SOURCES

**anbeeld-kv-benchmark**
URL: https://anbeeld.com/articles/kv-cache-quantization-benchmarks-for-long-context
Accessed: 2026-07-16

**bee-qwen36-quickstart**
URL: https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-qwen36-dflash.md
Accessed: 2026-07-16

**local-capacity-sweep**
URL: (local) `/home/tnunamak/.tmp/q5-202752-response.json`, `/home/tnunamak/.tmp/q5-203776-response.json`, `/home/tnunamak/.tmp/q8-145408-long-response.json`, `/home/tnunamak/.tmp/q8-146432-response.json`, and matching `*-vram.csv` evidence
Accessed: 2026-07-16

**local-llama-quant-benchmark**
URL: https://www.reddit.com/r/LocalLLaMA/comments/1tr9vzn/qwen3627b_quantization_benchmark/
Accessed: 2026-07-16

**q5-agentic-report**
URL: https://jackrong-qwen36-eval.static.hf.space/report.html
Accessed: 2026-07-16

## SYNTHESIS

Use q5_0 K plus q4_1 V for Daisy's normal coding profile. Keep q8/q8 as an explicit sticky profile for a user-requested fidelity check or for isolating whether a suspected failure depends on KV quantization; do not let Daisy choose it automatically. The published quality difference is real enough that q8 remains useful diagnostically, but it does not justify giving up 57K tokens by default without task-level evidence that q5/q4 caused a defect. Treat a Q5 weight file as a separate future challenger, not as a justified production upgrade: community evidence supports better distribution fidelity, but does not yet establish a real-task gain large enough to price against the context lost on a 24 GiB GPU.
