# Generation recipe (validated 2026-06-10)

The settings that actually produce clean, on-style Little Black illustrations on
the local Vivid Fish gateway + ComfyUI (RTX 3090). Hard-won; don't drift from these
without re-testing.

## Model + workflow

- **Model/quant: Ideogram 4, GGUF Q8_0** (`ideogram4-Q8_0.gguf` +
  `ideogram4_unconditional-Q8_0.gguf`). GGUF Q8 is r/SD's #1-ranked quant for
  quality. nvfp4 (no FP4 accel on a 3090) and fp8 (no fp8 tensor cores on Ampere)
  both render *worse* text; INT8 is fast but crashes intermittently on our stack.
- **Workflow: `ideogram4-gguf-kijai`** (gateway model name). Mirrors the
  community-validated Kijai config:
  - `DualModelGuider` **cfg = 7** (NOT 1.0 — 1.0 is "too soft" and garbles text)
  - `CFGOverride` **cfg = 3, start_percent = 0.9, end_percent = 1.0** (override only the last 10%)
  - `ConditioningZeroOut` feeding the guider's negative
  - `ModelSamplingAuraFlow` **shift = 5**
  - `BasicScheduler` **simple, 28 steps**, euler sampler
  - **No split-sigmas, no ExtendIntermediateSigmas** (our earlier hacks hurt text)
- Requires city96 ComfyUI-GGUF + **PR #459** (adds ideogram arch detection + BF16
  dequant; not yet merged upstream as of 2026-06-10) and **torch >= 2.7+cu128**.
- Cost: ~195s cold / faster warm at 1536x1024. Heavy but correct. Quality over speed.

## Why this matters (the dead ends, so nobody repeats them)

The garbled-small-text problem was a **config** problem, not an Ideogram limit.
Independent r/SD users render 4+ clean labels with this config; our earlier
cfg=1.0 + split-sigmas + nvfp4 setup was the cause. Ideogram 4 IS the best local
text model (beats Flux per r/SD) — it just needs the right guidance settings.

## Prompt: send PLAIN ENGLISH — let the gateway build the JSON

**Send a plain-text description. Do NOT hand-author Ideogram-4 JSON.** The gateway's
Qwen3.6 converter turns your plain English into a properly *grounded* Ideogram-4 caption
(typed obj/text elements + bboxes following the depth-band rules below) automatically.
Hand-writing the JSON yourself is the #1 way to get worse results: it's easy to omit
`elements`/bboxes and hand the model an ungrounded caption, which renders garbled text and
trips the safety filter more. The gateway also auto-grounds JSON that lacks real `elements`,
but the simplest correct path is just: **describe the scene in a sentence or two.**

Two things to put in your plain-text brief:

1. **Loose-hand-drawn style steer** (otherwise the config renders clean but
   digital/vector-looking). Say, in words:
   > "loose hand-drawn marker and ballpoint-pen doodle on white paper, organic
   > wobbly imperfect lines, sketchy whiteboard-explainer feel, NOT digital, NOT
   > vector, NOT geometric, NOT flat-color-fill, casual rough linework, lots of
   > white space"
2. **English-only** — the gateway enforces this, but reinforce in the brief; Ideogram
   injects non-English glyphs unprompted otherwise.

The rules below describe what the gateway's grounding does and what to keep in mind when
WORDING your brief (e.g. ask for "3-4 large, well-separated labels", not a crowded grid).
Only hand-author JSON as a last resort, and if you do, it MUST include a non-empty
`elements` array with typed `obj`/`text` entries and bboxes — otherwise the gateway will
re-ground it anyway.

## Known limits / open issues

- **bbox collisions (SOLVED — apply this)**: if the octopus bbox overlaps a text
  bbox, the character breaks the word (e.g. "new task" -> "now|task"). Fix: place
  the octopus in a clear region (a corner / empty side) whose bbox does NOT overlap
  any text bbox, and have it point/reach toward the action rather than sit on it.
  Verified to eliminate the word-breaking.
- **Label density + SPACING (validated boundary)**: ~3-4 large, well-SEPARATED
  labels render cleanly. Text degrades to gibberish when labels are crowded or
  lined up close together in a row (e.g. 4 ladder rungs, tight grids, captions
  packed near each other). Keep labels few, large, and spread far apart across the
  canvas. Also: an object's `desc` text can leak as a rendered word (e.g. "GROUND"
  meant as a description appeared as a label) — keep descriptions free of words you
  don't want drawn, or they may show up.
- **Sparse scenes also fail**: a lone tiny character in mostly-empty space gives the
  model too little to anchor on and text degrades. Add light framing content
  (floor line, curtains, a prop) so the scene isn't near-empty.
- Safety filter is stochastic: an occasional grey "blocked" frame = bad seed;
  retry, don't change the prompt.
