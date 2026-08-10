---
title: "ONNX Runtime's default intra-op thread pool claims all physical cores per session, so raising JS-level concurrency for transformers.js/onnxruntime-node embed() calls causes N-squared core oversubscription unless intraOpNumThreads is capped"
date: 2026-08-09
topic: llm-serving
tags: [onnxruntime, onnxruntime-node, transformers.js, threading, concurrency, cpu-oversubscription, embeddings]
status: draft
sources: [onnxruntime-threading-docs, hf-transformers-js-pipeline-options, silero-vad-discussion, medium-onnx-tricks]
source_session: de33c5d0-df7c-4cde-978c-a5e0ea30311a
---

## CLAIMS

- ONNX Runtime's `intra_op_num_threads` (Node.js binding: `intraOpNumThreads`), when left at its default of 0/unset, sizes the intra-op thread pool to the number of physical CPU cores on the host — i.e. one inference session by default tries to use ~all physical cores for a single call. [onnxruntime-threading-docs]
- With the default setting, the main thread runs on the 1st core (unaffinitized) and one extra thread is affinitized to each additional physical core, so on a 6-physical-core/12-logical-processor machine the intra-op pool totals 6 threads. [onnxruntime-threading-docs]
- Since ONNX Runtime 1.14, on NUMA systems the default intra-op pool spans all NUMA nodes' physical cores, not just one node (e.g., 2 nodes × 24 cores → 47 threads with per-core affinity). [onnxruntime-threading-docs]
- Because each session claims all physical cores by default, running multiple ONNX Runtime sessions concurrently in one process is a well-documented source of CPU oversubscription/thread contention. [onnxruntime-threading-docs] [medium-onnx-tricks]
- Documented mitigations for concurrent-session oversubscription: explicitly set `intra_op_num_threads` per session (don't rely on env vars, which some ORT builds ignore), use ORT's global/shared intra-op thread pool across sessions, or set `session.intra_op_thread_affinities` so each session's threads pin to a disjoint core set. [medium-onnx-tricks] [onnxruntime-threading-docs]
- Community best-practice from concurrent-serving contexts: with N concurrent sessions in one process, cap `intraOpNumThreads` to roughly `total_cores / N` (not leave it at the all-cores default) to avoid multiplicative thread explosion; for small/lightweight models under many parallel sessions, setting `intra_op_num_threads = 1` per session is common. [medium-onnx-tricks] [silero-vad-discussion]
- transformers.js (`@huggingface/transformers`)'s `pipeline()` accepts a `session_options` field of type `InferenceSession.SessionOptions`, which is passed through to the underlying `createInferenceSession()` call — so `intraOpNumThreads`/`interOpNumThreads` ARE configurable via the public pipeline API, but only if the caller explicitly sets them; transformers.js does not appear to set a non-default `intraOpNumThreads` on the caller's behalf. [hf-transformers-js-pipeline-options]
- Given the above, a JS-level dispatch concurrency of 1 can already saturate all physical cores via one session's internal intra-op pool; raising JS-level concurrency to N (CPU count) without also reducing `intraOpNumThreads` produces N inference calls each independently trying to claim ~all cores, i.e. N² core contention rather than N-way genuine parallelism — a documented, not speculative, failure mode. [onnxruntime-threading-docs] [medium-onnx-tricks]

## SOURCES

**onnxruntime-threading-docs**
URL: https://onnxruntime.ai/docs/performance/tune-performance/threading.html
Accessed: 2026-08-09
Quote: "By default with intra_op_num_threads=0 or not set... INTRA Threads Total = Number of physical CPU Cores... the intra-op thread pool will create an extra thread on every physical core (except the 1st core)."

**hf-transformers-js-pipeline-options**
URL: https://github.com/huggingface/skills/blob/main/skills/transformers-js/references/PIPELINE_OPTIONS.md ; https://huggingface.co/docs/transformers.js/api/backends/onnx
Accessed: 2026-08-09
Quote: "session_options of type InferenceSession.SessionOptions for ONNX Runtime settings... passed through to createInferenceSession()."

**silero-vad-discussion**
URL: https://github.com/snakers4/silero-vad/discussions/570
Accessed: 2026-08-09
Quote: "using more threads may be slower... a small thread count is enough for a small, optimized model."

**medium-onnx-tricks**
URL: https://medium.com/@Modexa/8-onnx-runtime-tricks-for-low-latency-python-inference-baee6e535445
Accessed: 2026-08-09
Quote: "each session by default tries to claim all physical cores — a major source of oversubscription when running multiple sessions concurrently... sweep intra_op from 1 to cores and pick the best p50/p95 latency combo."

## SYNTHESIS

This directly validates a red-team concern raised against a proposed change (set JS-level embed() concurrency = CPU count) in a transformers.js/onnxruntime-node (v1.24.3) codebase. The mechanism is real and documented, not hypothetical: ORT's default intra-op pool is sized to physical cores, so a single inference call already uses ~all cores internally; scaling JS-level concurrency to N without capping `intraOpNumThreads` to `~cores/N` (or using ORT's shared/global thread pool, or per-session core affinity) produces N² contention. This is a plausible root cause for a non-monotonic concurrency-vs-latency benchmark curve (e.g., worse at concurrency 4 than at 2, better again at 8) — oversubscription effects are known to be noisy/non-linear because they depend on scheduler behavior, cache thrashing, and affinity, not a clean queueing curve. The fix pattern from prior art: either (a) keep JS-level concurrency low and let ORT's default per-session pool use the cores, or (b) if raising JS-level concurrency, explicitly pass `session_options: { intraOpNumThreads: cores/N }` (or 1 for small models) through transformers.js's pipeline() options — the API supports this, it's just unset in the reviewed code.
