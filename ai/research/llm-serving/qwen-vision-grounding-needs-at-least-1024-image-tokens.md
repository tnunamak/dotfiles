---
title: "Qwen dynamic-resolution vision needs at least 1024 image tokens for reliable OCR and grounding"
date: 2026-07-16
topic: llm-serving
tags: [qwen, vision, llama.cpp, ocr, grounding]
status: draft
sources: [llamacpp-qwen-image-size, local-image-token-validation]
source_session: 019f5a4a-52e6-7a60-8091-f5fab423bd3b
---

## CLAIMS

- A Qwen contributor recommends roughly 1024–2048 image tokens for grounding, especially OCR; llama.cpp exposes `--image-min-tokens` for dynamic-resolution vision models and warns when Qwen is configured below 1024. [llamacpp-qwen-image-size]
- On Daisy's Qwen3.6-27B llama.cpp deployment, setting `--image-min-tokens 1024` increased the same 512x512 icon request from about 284 prompt tokens to 1051, a measured cost of roughly 767 additional context tokens. [local-image-token-validation]
- With the new minimum, Daisy exactly read a UI headline and base URL from a 1440x1000 screenshot and correctly answered three relative-position questions from a 1280x900 UI screenshot. [local-image-token-validation]

## SOURCES

**llamacpp-qwen-image-size**
URL: https://github.com/ggml-org/llama.cpp/issues/16842
Accessed: 2026-07-16

**local-image-token-validation**
URL: (local) live authenticated gateway tests on 2026-07-16 against `/home/tnunamak/Pictures/screenshots-swept-20260616/ai-gateway-me-desktop.png`, `/home/tnunamak/Pictures/screenshots-swept-20260616/pdpp-neko-desktop-1280x900.png`, and `/usr/share/pixmaps/kubuntu-logo.png`
Accessed: 2026-07-16

## SYNTHESIS

For Daisy's occasional screenshot and image use, set the dynamic-resolution floor to 1024 image tokens. The measured per-image context cost is under 800 tokens for the small-icon probe and the production tests passed at 1051–1434 prompt tokens. This is a better trade than leaving the model below its recommended OCR/grounding range. Keep the projector CPU-side and retain the existing fixed total context; image tokens consume part of that context only on multimodal requests.
