---
name: little-black-illustrations
description: Generate hand-drawn, whimsical body illustrations for articles. Use when the user asks to illustrate an article, post, blog, Notion doc, workflow doc, methodology, process, structure, state, metaphor, or argument — triggers on "whimsical/quirky illustration", "hand-drawn diagram", "article illustration", "body illustration", "illustration suggestions", "shot list", or "remove the title / edit the image". Uses the "Little Black" mascot, pure-white hand-drawn line art, sparse red/orange/blue English annotations, and a clean but imaginative visual style.
---

# Little Black — Whimsical Article Illustrations

> Adapted from the `ian-xiaohei-illustrations` skill by helloianneo.

## Core positioning

Design and generate 16:9 landscape body illustrations for articles. The goal is NOT
commercial illustration, PPT infographics, or cute cartoons — it is to turn an
article's key judgments, processes, structures, states, or metaphors into a clean,
quirky, creative, readable-but-not-manual-like hand-drawn explanatory sketch.

The default visual IP is "Little Black": a small slender solid-black cartoon octopus
with big white dot eyes, eight thin tentacles, and a blank expression, earnestly doing
one absurd-but-coherent thing. Little Black must take part in the core action of the
scene — never just stand beside it as decoration.

## Read these references first

Load as the task needs; don't stuff them all into context at once:

- `references/generation-recipe.md`: **READ FIRST when actually generating** — the
  validated model/workflow/settings + style steer + bbox rules that make output
  clean and on-style. On the Vivid Fish gateway, request model
  **`ideogram4-gguf-kijai`** (not the gateway's default Klein). Don't drift from
  these settings without re-testing.
- `references/style-dna.md`: style DNA, color, text, taboos.
- `references/xiaohei-ip.md`: Little Black's appearance, personality, action library, taboos.
- `references/composition-patterns.md`: structure types, original-metaphor method, anti-repetition rules.
- `references/prompt-template.md`: the single-image generation prompt template.
- `references/qa-checklist.md`: post-generation checks and iteration rules.
- `assets/examples/`: low-frequency visual calibration only — does NOT enter the default
  generation path. Do not copy these examples' compositions, objects, or annotations.

## Workflow

### 1. Digest the article

First read the article, link, Notion page, Markdown file, or screenshot the user gives.
Distill:

- What is the core argument
- Which paragraphs carry a cognitive turn
- What is well-suited to explaining with an image
- What only suits text and needs no image

Don't illustrate uniformly. Prefer "cognitive anchors", e.g.: the core judgment, two
break points, an input→output loop, a fork, before/after contrast, one-input-many-uses,
a hand-off path, common pitfalls, a character's change of state.

### 2. Propose an illustration strategy first

If the user only says "analyze how to illustrate this / think about where illustrations
are needed", give a shot list first. For each image write out:

- Which paragraph it follows
- The image's theme
- The core meaning
- The structure type
- What Little Black is doing in it
- Suggested elements
- Suggested English annotation words

Default to 4–8 images. For very short articles, 1–3; even for long pieces don't lightly
exceed 9. Enough is enough — don't turn the article into a picture book.

### 3. Generate one image at a time

If the user explicitly asks to "generate / output / make images / generate for me",
don't stop to wait for confirmation; use the built-in `image_gen` to generate each one
separately. Don't stitch multiple images into one.

Each image conveys only one core structure. The prompt must include:

- 16:9 landscape article illustration
- Pure white background
- Black hand-drawn line art
- Sparse red/orange/blue handwritten English annotations (English only — never any
  non-English text; the model will inject non-English glyphs unless told otherwise)
- Lots of white space
- Little Black as the core action subject
- No PPT, no commercial illustration, no childish cuteness, no complex architecture,
  no top-left-corner type title

Don't reproduce past examples. Examples only provide style density and a sense of how
Little Black participates; do not directly reuse existing compositions like
"conveyor-belt break points / Little Black pulling a lever / material-fish /
stamp toolbox / common-pitfalls path" unless the user explicitly asks to reproduce a
specific image. Every time, reinvent a strange-but-coherent metaphor from the current
article.

### 4. Check and iterate

After generating, check `references/qa-checklist.md`. If any of these appear, prefer
regenerating or doing a local edit:

- Little Black is mere decoration
- The frame is too full
- It looks too much like a flowchart / PPT
- Any non-English text, too much text, or serious typos
- A top-left title like "common pitfalls / flowchart / system architecture" appears
- The style is too cute, childish, or rigid
- The background is not clean white

### 5. Save and deliver

If the user is working inside a workspace, copy the final images to:

```text
assets/<article-slug>-illustrations/
```

Name them in order:

```text
01-topic-name.png
02-topic-name.png
```

Keep the original generated files; don't overwrite existing assets unless the user
explicitly asks to replace them.

## Output discipline

Keep the pre-generation strategy output short and precise. The post-generation delivery
should include:

- How many images were generated
- What each image is for
- The save path
- Which images are most solid, which are optional

Don't write long explanations of style theory; let the images speak.
