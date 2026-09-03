---
title: "Abliteration (refusal-direction ablation) can silently drop a model's MTP speculative-decoding tensors, and reputable publishers now verify block count post-quantization rather than assuming preservation"
date: 2026-08-17
topic: llm-serving
tags: [abliteration, mtp, speculative-decoding, gguf, quantization, model-verification]
status: draft
sources: [jonathancoletti-qwen38-uncensored, aeon-qwen38-mindstudio, huihui-qwen38-abliterated]
source_session: 9ae2222f-0655-4f5e-9acb-516d26336b8f
---

## CLAIMS

- Abliteration workflows that re-save a model through `transformers` (the standard path for merging a refusal-ablation LoRA/edit into base weights) do not carry over MTP (multi-token-prediction) head tensors by default, even though the resulting `config.json` still advertises MTP support. [jonathancoletti-qwen38-uncensored]
- The failure is silent: nothing in the abliteration or quantization pipeline errors out when MTP tensors are dropped — the GGUF simply loads and runs without the draft head, and `--spec-type draft-mtp` either falls back silently or fails at inference time depending on the serving engine. [jonathancoletti-qwen38-uncensored] [aeon-qwen38-mindstudio]
- At least two independent, unrelated Qwen3.8-27B abliteration efforts (JonathanColetti and the AEON-7 team) hit this exact bug independently and both had to manually graft the original MTP tensors back from the base checkpoint after abliteration. [jonathancoletti-qwen38-uncensored] [aeon-qwen38-mindstudio]
- JonathanColetti's fix is verified per-file, not assumed: each quantized GGUF is inspected post-quantization for actual tensor block count against the declared block count in metadata (e.g. 65/65 blocks present = MTP retained vs 64/64 = MTP silently dropped), and the verification table is published per-quant in the model card. [jonathancoletti-qwen38-uncensored]
- AEON-7's abliteration pipeline (built on `abliterix`, itself built on the `Heretic` project by Philipp Emanuel Weidmann) also independently discovered the abliterix merge step drops the MTP head (15 tensors) and grafted the originals back with an explicit hash-match check before publishing. [aeon-qwen38-mindstudio]
- The official `huihui-ai` org's abliteration of the same base model explicitly calls out in its model card that "MTP and visual has not been modified," suggesting the risk is now recognized widely enough that reputable publishers state MTP preservation as a selling point rather than leaving it implicit. [huihui-qwen38-abliterated]
- Community skepticism (r/LocalLLaMA, 2026-08-16) of shallow abliteration evaluations specifically calls out the absence of KL-divergence reporting as a credibility gap, separate from the MTP issue — suggesting MTP-tensor verification and KLD reporting are becoming two independent bars a rigorous abliteration release is expected to clear.

## SOURCES

**jonathancoletti-qwen38-uncensored**
URL: https://huggingface.co/JonathanColetti/Qwen3.8-27B-Uncensored-GGUF
Accessed: 2026-08-17
Quote: "Abliteration drops the `mtp.*` tensors: the model is re-saved through transformers, which does not carry the MTP head, while `config.json` still advertises it. They are grafted back from the base checkpoint and every file is inspected after quantization — see Method and Verification." / "A fused file whose present-block count does not exceed its declared count did not retain the MTP block." (verification table shows e.g. Q4_K_M.gguf: MTP=True, 65/65 blocks vs noMTP-Q4_K_M.gguf: MTP=False, 64/64 blocks)

**aeon-qwen38-mindstudio**
URL: https://www.mindstudio.ai/blog/qwen3-8-27b-aeon-uncensored-abliteration
Accessed: 2026-08-17
Quote: "After the abliteration pass, the team discovered that the abliterix merge process had dropped the model's native multi-token prediction (MTP) head, 15 tensors, and manually grafted the original MTP weights back in with a hash-match check."

**huihui-qwen38-abliterated**
URL: https://huggingface.co/huihui-ai/Huihui-Qwen3.8-27B-abliterated-GGUF
Accessed: 2026-08-17
Quote: "The first 15 layers were retained without ablation. MTP and visual has not been modified."

## SYNTHESIS

For anyone selecting or producing an abliterated GGUF of an MTP-capable model (Qwen3.5/3.6/3.8 family and likely others adopting MTP), do not assume the draft head survived the abliteration + quantization pipeline just because `--spec-type draft-mtp` doesn't throw an error — verify it. The check is cheap: compare present tensor/block count against the metadata-declared count (JonathanColetti's `quantize.py inspect` approach), or diff the file's tensor list against a known-good MTP-enabled GGUF from the same base model. A model that silently lost its draft head will still serve requests correctly — it just quietly falls back to non-speculative decoding, which shows up as an unexplained throughput regression (in llama.cpp, `draft_n`/`draft_n_accepted` will be absent or 0 in the `timings` block of a chat completion response) rather than a hard failure, making it easy to miss without an explicit A/B on decode speed.

This also means "official" or "trusted-lineage" publishers are not automatically safer on this specific axis — the fix requires an active verification step that a publisher has to think to add; it isn't automatic from using a reputable base or a well-known abliteration tool. When evaluating abliterated builds going forward, look for explicit MTP-tensor-count verification in the model card (not just a mention of "MTP support") as a genuine quality signal alongside published KL-divergence and refusal-rate methodology.
