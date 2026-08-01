---
title: "The remaining credible Qwen3.6 engine gains are MTP depth tuning or a DFlash challenger, not non-P2P dual-GPU serving"
date: 2026-07-16
topic: llm-serving
tags: [qwen3.6, llama.cpp, mtp, dflash, multi-gpu, rtx-3090]
status: draft
sources: [llama-mtp-regression, llama-draft-cache-types, bee-dflash-benchmarks, llama-multi-gpu, llama-non-p2p-corruption, local-topology, llama-cuda-ubatch, local-controlled-sweep]
source_session: 104fc3d9-a1d2-4777-affb-c5654d861214
---

## CLAIMS

- An upstream llama.cpp Qwen3.6 report measured the post-cleanup MTP path at 85–90% of the older path with draft depth 3, versus about 95% with draft depth 2; the issue remains unconfirmed and is not a controlled result on this host. [llama-mtp-regression]
- Official llama.cpp exposes the full quantized K/V type set independently for the speculative draft context; it publishes no Qwen3.6 benchmark establishing the throughput-versus-memory optimum for those draft-cache types. [llama-draft-cache-types]
- Bee's published RTX 3090 Qwen3.6-27B benchmarks report MTP at 56.5 tok/s and DFlash at 64.6 tok/s on a multi-turn coding trace, while short repetitive coding prompts show much larger DFlash gains; the benchmark is produced by the fork author and measures generation speed, not task accuracy. [bee-dflash-benchmarks]
- Bee's documented precision profile combines Q5_K_S target weights, a Q4-class DFlash drafter, q5_0/q4_1 KV, CPU-side vision projection, and 100k safe context; the author reports 160k fitting at 99.5% VRAM on one RTX 3090. [bee-dflash-benchmarks]
- Upstream llama.cpp documents layer split as the compatible multi-GPU path and tensor split as experimental; tensor split does not support quantized KV. [llama-multi-gpu]
- An open upstream issue reports corrupted output at contexts above 2048 on a dual-RTX-3090 layer split without P2P, including failures with both FP16 and quantized KV at larger contexts. [llama-non-p2p-corruption]
- This host's two RTX 3090s communicate through a PCIe host bridge and report GPU peer reads/writes as unsupported; both links have negotiated a maximum of PCIe Gen4 x8. [local-topology]
- A llama.cpp CUDA performance thread reports that Qwen3.6-27B needs a conventional 1024-token physical microbatch to reach maximum prompt throughput on the tested CUDA system, but the result is not from an RTX 3090 and does not establish this host's extra VRAM requirement. [llama-cuda-ubatch]
- On this host, MTP depth 2 saved 192 MiB but reduced draft acceptance from 90.1% to 84.2% and was fractionally slower (46.69 versus 46.84 generation tok/s), so depth 3 remains the local optimum. [local-controlled-sweep]
- Quantizing only the target-verified draft KV from q8/q8 to q5/q4 produced the same five-run mean generation rate (45.74 tok/s), effectively the same wall rate (44.92 versus 44.99 tok/s), and allowed a five-run 205,824-context profile while using less VRAM than the 202,752-context q8-draft baseline. [local-controlled-sweep]
- A 1024-token ubatch could not allocate its additional 1,348 MiB compute buffer at 202,752 context. At 184,320 context with q5/q4 draft KV it improved a 37,062-token prefill by only 4.1% (1,155 versus 1,109 prompt tok/s), an unfavorable 9.1% context trade. [local-controlled-sweep]

## SOURCES

**llama-mtp-regression**
URL: https://github.com/ggml-org/llama.cpp/issues/23230
Accessed: 2026-07-16

**llama-draft-cache-types**
URL: https://github.com/ggml-org/llama.cpp/blob/master/docs/speculative.md
Accessed: 2026-07-16

**bee-dflash-benchmarks**
URL: https://github.com/Anbeeld/beellama.cpp
Accessed: 2026-07-16

**llama-multi-gpu**
URL: https://github.com/ggml-org/llama.cpp/blob/master/docs/multi-gpu.md
Accessed: 2026-07-16

**llama-non-p2p-corruption**
URL: https://github.com/ggml-org/llama.cpp/issues/20052
Accessed: 2026-07-16

**local-topology**
URL: (local) `nvidia-smi topo -m`, `nvidia-smi topo -p2p r`, and `nvidia-smi topo -p2p w` on 2026-07-16
Accessed: 2026-07-16

**llama-cuda-ubatch**
URL: https://github.com/ggml-org/llama.cpp/discussions/15013
Accessed: 2026-07-16

**local-controlled-sweep**
URL: (local) official llama.cpp server measurements using
`scripts/local/bench_llm_endpoint.py`, process argv inspection, `nvidia-smi`,
and systemd journal evidence on 2026-07-16
Accessed: 2026-07-16

## SYNTHESIS

Keep the validated single-GPU official llama.cpp profile as production, with
MTP depth 3, q5_0/q4_1 main KV, q5_0/q4_1 draft KV, ubatch 512, and 205,824
context. The controlled sweep rejected depth 2 and ubatch 1024; draft-cache
quantization was performance-neutral and bought a small context increase without
changing final-token quality because target verification remains authoritative.
DFlash remains credible prior art, but the operator explicitly excluded it from
this setup, so it is not a pending production challenger. Do not make dual-GPU
serving a production profile on the current non-P2P topology until upstream's
long-context corruption path is resolved or a local long-context equivalence
soak disproves exposure.
