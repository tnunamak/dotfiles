# Image generation prompt template

Generate each image separately. Replace the variables based on the article content;
don't stitch multiple images into one.

```text
Generate one standalone 16:9 horizontal article illustration.

Visual DNA:
Pure white background. Minimalist black hand-drawn line art. Slightly wobbly pen lines. Lots of empty white space. Sparse red/orange/blue handwritten English annotations. Clean absurd product-sketch feeling. No gradients, no shadows, no paper texture, no complex background, no commercial vector style, no PPT infographic look, no cute mascot poster, no children's illustration, no realistic UI. All text and labels in English only — no non-English characters anywhere.

Recurring IP character required:
"Little Black", a small slender solid-black cartoon octopus — slim and meek, small relative to the canvas. Petite slightly-tall body, smooth clean outline (NOT a round plump blob, NOT chunky). Two large white circle eyes with small black pupils, prominent on the slim body; no mouth. Eight thin fine tentacles like slender little threads — never stubby/chubby, never spiky, wild, or flame-like. Drawn with clean, confident, medium-thin black ink and a gentle hand-drawn wobble — never sketchy, scratchy, or wispy. At rest the tentacles hang softly below; when interacting they reach, grip, pull, plug, or haul as the scene needs. Blank calm earnest expression. Little Black must perform the core conceptual action using its tentacles — not decorate the scene.

Theme:
{the article-illustration theme}

Structure type:
{structure type: Workflow / system fragment / before-after / character state / conceptual metaphor / method layering / map-route / mini-comic panels}

Core idea:
{the core meaning this image should express}

Composition:
{the concrete scene: where Little Black is, what it is doing, what the main objects are, how information flows}

Suggested elements:
{element1} / {element2} / {element3} / {element4}

Handwritten labels (English only):
{label1} / {label2} / {label3} / {label4} / {optional label5}

Color use:
Black for main line art and Little Black. Orange for main flow/path/arrows. Red only for key warnings/problems/results. Blue only for secondary notes or feedback/system state.

Constraints:
One image explains only one core structure. Keep the main subject around 40%-60% of the canvas. Preserve at least 35% blank white space. Use at most 5-8 short handwritten English labels. Do not write a title in the top-left corner. Do not write the structure type on the image. Do not make it a formal diagram, course slide, or dense explainer. Do not use any non-English text. Do not copy prior examples or reuse known case compositions unless explicitly requested; invent a fresh visual metaphor for this specific article. It should be clear but not instructional, interesting but not childish, strange but clean.
```

## Image-editing prompts

Remove the top-left title:

```text
Edit the provided image. Remove only the handwritten title "{text to delete}" and its underline from the top-left corner. Fill that area with the same clean white background, matching the surrounding blank paper. Preserve everything else exactly: characters, labels, paths, line style, composition, aspect ratio, and image quality. Do not add any new text or objects.
```

Strengthen the quirky feel:

```text
Regenerate this illustration with the same core meaning and simple layout, but make Little Black more central to the conceptual action. Little Black should be doing the strange work that explains the idea, not standing beside the diagram. Keep it clean, sparse, hand-drawn, and not cute.
```
