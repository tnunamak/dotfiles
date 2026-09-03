---
title: "Fish Audio S2 Pro's voice-clone reference-audio encode step can OOM a 24GB GPU when combined with the loaded model, and the cause is reference-clip length, not torch.compile"
date: 2026-08-25
topic: audiobooks
tags: [fish-speech, tts, voice-cloning, cuda-oom, vram, tts-audiobook-tool]
status: draft
sources: [isolated-repro]
source_session: cd43dd9a-27d9-4d72-b627-922342f38a25
---

## CLAIMS
- On a single RTX 3090 (23.5GB usable), loading Fish Audio S2 Pro (`fishaudio/s2-pro`, via `zeropointnine/tts-audiobook-tool`'s `FishS2Model`) alone uses ~15.1GB (t2s DualARTransformer + DAC codec), leaving ~8.4GB headroom. [isolated-repro]
- Calling `_create_voice_clone()` (which runs `dac_model.encode()` on the reference audio) with a 13.9s, 24kHz mono reference clip pushed PyTorch's *reserved* memory to 23.10GB immediately after voice-clone creation — before any actual generation — leaving no room for `generate_long()`'s own allocations and causing a hard `CUDA out of memory` on the very next generate() call, reproducibly, across three separate attempts. [isolated-repro]
- This reproduced identically in both `compile_enabled=True` and `compile_enabled=False` (eager) modes — ruling out `torch.compile` as the cause, contrary to the first hypothesis (the codebase's `DECISIONS.md` had already documented compile-mode Xid 109 instability on a different GPU in this same project, which was a red herring here). [isolated-repro]
- Trimming the same reference clip to 7.0s (same speaker, same source) fixed it completely: model load ~15.1GB, voice-clone creation only pushed reserved memory into the low-20s GB range, and a full compiled-mode generate() call completed with a measured peak of 22.1GB — safely under the 23.5GB ceiling, with room to spare for a full multi-hour production render (2,697 segments completed with 0 OOMs afterward). [isolated-repro]
- The DAC encoder resamples the reference to 44.1kHz internally regardless of input sample rate (`dac_model.sample_rate`), so a 13.9s @ 24kHz clip becomes ~612k samples for encoding — the encoder's convolutional stack appears to need buffer sizes that scale disproportionately (roughly non-linearly, based on the ~1GB isolated-DAC-only test vs ~8GB+ jump when combined with the already-loaded t2s model) with input length once combined with the full model's existing allocations, likely a fragmentation effect rather than a true peak-compute requirement (an isolated DAC-only test with no t2s model loaded encoded the same 13.9s clip using only ~1GB peak). [isolated-repro]

## SOURCES
**isolated-repro**
URL: n/a (local reproduction, not a published source)
Accessed: 2026-08-25
Quote: "[after voice clone created] allocated=15.13GB reserved=23.10GB" (13.9s clip, immediately preceded a CUDA OOM on the next generate() call); with a 7.0s clip instead: "peak during generate: 22.115052032 GB" (successful completion)

## SYNTHESIS
For anyone using `tts-audiobook-tool`'s Fish S2 Pro backend for voice-cloned narration on a single 24GB consumer GPU (3090/4090-class): keep the reference/prompt audio clip short — 7-10s tested safe, 13.9s tested to reliably OOM combined with a loaded model. This is a practical VRAM-budgeting constraint specific to this codec+transformer combination on ~24GB cards, not a general Fish-Speech limitation and not a torch.compile bug. Worth checking again if `fish_speech`/`tts-audiobook-tool` upstream changes the DAC encode path (e.g. chunked encoding) to remove this scaling behavior. Don't waste time debugging compile-mode instability first, as documented compile-mode Xid faults elsewhere in a project can be a red herring for what is actually a reference-length VRAM issue.
