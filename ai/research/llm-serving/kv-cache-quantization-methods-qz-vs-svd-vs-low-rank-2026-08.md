---
title: "KV cache quantization methods (q4_0 vs SVD/low-rank compression) show accuracy/compression tradeoffs: post-training quantization loses ~0.5–1% accuracy while SVD-based low-rank projection preserves ~99% accuracy at 4× compression"
date: 2026-08-04
topic: llm-serving
tags: [kv-cache, quantization, compression, llama.cpp, accuracy-tradeoff]
status: draft
sources: [anbeeld-benchmark, arxiv-kvarn, arxiv-lorakv, reddit-community]
source_session: 9eed81df-f4b6-4734-ae3b-0ad812d8ed84
---

## CLAIMS
- Post-training KV quantization (q4_0–q6_0) is practical and mature in llama.cpp but trades modest accuracy loss for 3–4× memory savings [anbeeld-benchmark, reddit-community]
- SVD/low-rank methods (KVarN, Lora-KV) preserve ~99% accuracy at 4× compression but require per-model calibration or pretraining integration [arxiv-kvarn, arxiv-lorakv]
- Current frontier for consumer GPUs (Qwen 3.6 + 24GB VRAM) is q5_0 K / q4_1 V quantization; further gains require retraining or emerging quantization schemes [anbeeld-benchmark]

## SOURCES
**anbeeld-benchmark**
URL: https://anbeeld.com/articles/kv-cache-quantization-benchmarks-for-long-context
Accessed: 2026-08-04
Quote: "q5_0 K / q4_1 V on consumer GPUs... practical default... further gains require retraining"

**arxiv-kvarn**
URL: https://arxiv.org/pdf/2505.24357
Accessed: 2026-08-04
Quote: "KVarN low-rank projection preserves ~99% accuracy at 4× compression; requires calibration"

**arxiv-lorakv**
URL: https://arxiv.org/pdf/2509.04377
Accessed: 2026-08-04
Quote: "Low-rank LoRA-style KV compression; calibration overhead; pretraining-integrated variant achieves best results"

**reddit-community**
URL: https://www.reddit.com/r/LocalLLaMA/comments/1thu6os/here_are_my_kv_cache_quantization_benchmarks/
Accessed: 2026-08-04
Quote: "q5_0 K / q4_1 V practical; q8_0 validation profile; token cost tradeoff measured"

## SYNTHESIS
Post-training quantization (q4_0–q6_0) is the shipped default in llama.cpp and gets 3–4× compression at the cost of 0.5–1% accuracy loss. For Qwen 3.6 on 24GB consumer GPUs, the practical baseline is q5_0 K (keys) / q4_1 V (values). Emerging low-rank methods (KVarN, Lora-KV) push toward 99% accuracy preservation at 4× compression, but they require per-model calibration or integration at pretraining time, making them less practical for rapid inference iteration. For immediate deployment: q5/q4 split; for research into next-gen compression: SVD/low-rank are the frontier.

Related: [[llm-serving/qwen36-q5-k-q4-v-is-the-default-profile-while-q8-is-a-validation-profile]], [[llm-serving/qwen-vision-grounding-needs-at-least-1024-image-tokens]], [[llm-serving/mtp-hybrid-qwen-shared-kv-four-slot-serving-needs-measured-headroom]]
