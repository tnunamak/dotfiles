---
title: "A creature whose body is made of legible text needs a spine-plus-width-profile model with glyph rotation fixed at zero; text-along-a-path and the widely-cited 'pretext dragon' both fail"
date: 2026-08-04
topic: frontend-libraries
tags: [canvas, procedural-animation, typography, legibility, creative-coding, prior-art]
status: draft
sources: [argonaut-proc-anim, khj68-pretext-example, chenglou-pretext, iq-fish-shadertoy, plex-mono-metrics, hugo-elias-water, huxtable-waterfilter]
source_session: f7bcfaac-5c8c-4f6f-bb24-597ca11e892d
---

## CLAIMS

- The "Chinese dragon demo in the pretext ecosystem whose body is made of text and which parts text like water" is substantially a myth. The official `chenglou/pretext` (MIT, ~49.6k stars) is a text-measurement and line-wrapping library containing no physics, no creature code, and no dragon in its demos directory. [chenglou-pretext]
- A real dragon demo does exist, but only in `github.com/khj68/pretext-example`, a third-party ~8-star fan repo, and its body is drawn with `ctx.fillRect` pixel blocks over a separate paragraph field — the creature is not made of text. The same repo contains an undocumented `koi` effect that is the same spine engine reskinned with fish anatomy. [khj68-pretext-example]
- That repo has no LICENSE file and GitHub's license field returns null, despite the README asserting MIT. An unbacked README claim is not a license grant, so it is technique-reference only. [khj68-pretext-example]
- Its text-disturbance mechanic is a per-character spring (`spring_k=0.06`, `damping=0.88`, `DISTURB_RADIUS` 50–65px, `DISTURB_STRENGTH` 48–50) applied as a draw-time offset that never touches layout. There is no neighbour-to-neighbour coupling, so reducing the constants yields smaller independent per-glyph jitter, not a propagating ripple. [khj68-pretext-example]
- argonaut's `animal-proc-anim` (MIT) models a creature as a joint chain plus a per-joint width table, deriving the outline as `joint ± perpendicular(heading) × width`. Position comes from walking the spine while rotation is a separate value never applied to the fill — which is what makes it able to carry upright glyphs. [argonaut-proc-anim]
- Its fish constants are `Chain(origin, 12, 64, PI/8)` and `bodyWidth[] = {68,81,84,83,77,64,51,38,32,19}`. The width array is a HALF-width, applied at `±PI/2`; reading it as a full width understates the body by 2× and wrongly rules out crosswise text. [argonaut-proc-anim]
- Derived proportions: max full width / body length = 0.292 (1:3.43), max width at 22% back from the snout, snout 0.81× max width, caudal peduncle 0.23× max width. [argonaut-proc-anim]
- The chain solves as follow-the-leader with an angle clamp rather than physics, so body-bend turning is emergent from steering the head alone — no separate turn model is required. [argonaut-proc-anim]
- IBM Plex Mono's advance width is exactly 0.6em, verified by reading the font's `hmtx` table with fontTools rather than from documentation. Character run length in px is therefore `chars × 0.6 × fontSize`. [plex-mono-metrics]
- Consequently a 14-character record is 109px at 13px, and a fish 360px long is 105px across at its widest — so whole records fit ACROSS the body, making a text-bodied fish a stack of 3–5 upright record lines. Filling a silhouette with a fine glyph grid instead requires 8–10px type, below the ~12px practical legibility floor, and degrades to texture. [plex-mono-metrics]
- Inigo Quilez's Shadertoy fish (`ldj3Dm`, CC BY-NC-SA 3.0) perturbs its swim clock as `fishTime = t + 3.5*noise1(0.2*t)` and uses an analytic width profile `0.04 + h*(1-h)^2*2.7`; the noise-perturbed clock is a cheap defeat for mechanical periodicity independent of the rendering technique. [iq-fish-shadertoy]
- What distinguishes a watery disturbance from a cartoon wobble is a true propagation delay — `sin(k·d − ω·t)` gated so the wavefront reaches near elements before far ones. Index-based stagger (e.g. GSAP `stagger: i*0.03`) substitutes element order for distance/speed and reads as choreography. [hugo-elias-water]
- The classic two-buffer height-field water step is `new = (Σ4 neighbours / 2 − old) × damping` with damping 0.985. [hugo-elias-water]
- Image-filter ripple defaults do not transfer to text: Jerry Huxtable's `WaterFilter` (Apache 2.0) defaults to amplitude 10px / wavelength 16px, where the amplitude alone is ~75% of a glyph width at body-text sizes. [huxtable-waterfilter]

## SOURCES

**argonaut-proc-anim**
URL: https://github.com/argonautcode/animal-proc-anim
Accessed: 2026-08-04
Quote: "float[] bodyWidth = {68, 81, 84, 83, 77, 64, 51, 38, 32, 19};" and "spine = new Chain(origin, 12, 64, PI/8);" and "return spine.joints.get(i).x + cos(spine.angles.get(i) + angleOffset) * (bodyWidth[i] + lengthOffset);"

**khj68-pretext-example**
URL: https://github.com/khj68/pretext-example
Accessed: 2026-08-04
Quote: Repo cloned and run locally; body rendered via `ctx.fillRect` 3px blocks; disturbance constants `spring_k=0.06`, `damping=0.88`. GitHub API license field returns null.

**chenglou-pretext**
URL: https://github.com/chenglou/pretext
Accessed: 2026-08-04
Quote: MIT-licensed text measurement / line-wrapping library; `pages/demos/` contains accordion, bubbles, editorial-engine, masonry — no dragon, no physics code.

**iq-fish-shadertoy**
URL: https://www.shadertoy.com/view/ldj3Dm
Accessed: 2026-08-04
Quote: "an = or + (0.2+0.8*ih)*sin(3.0*ih - 2.0*fishTime)" with "fishTime = t + 3.5*noise1(0.2*t)" and width profile "ra = 0.04 + h*(1-h)*(1-h)*2.7"

**plex-mono-metrics**
URL: https://github.com/IBM/plex
Accessed: 2026-08-04
Quote: fontTools read of the `hmtx` table gives an advance width of 600/1000 em = 0.6em for all glyphs.

**hugo-elias-water**
URL: https://web.archive.org/web/20160418004149/http://freespace.virgin.net/hugo.elias/graphics/x_water.htm
Accessed: 2026-08-04
Quote: "new = (Σ4 neighbours / 2 − old) × damping", damping constant 0.985 in the widely-mirrored JS reimplementation.

**huxtable-waterfilter**
URL: http://www.jhlabs.com/ip/filters/WaterFilter.html
Accessed: 2026-08-04
Quote: Apache 2.0 image filter; default amplitude 10, default wavelength 16.

## SYNTHESIS

The reusable lesson is a structural one about what kind of body model can carry text at
all. Two obvious approaches both fail: bending a string along a path (glyphs end up
rotated, mirrored, and unreadable — it reads as a rendering glitch rather than a
creature) and filling a silhouette with small characters (falls below the legibility
floor and becomes texture). What works is a spine with a per-joint width profile, because
it yields a fillable region with a centreline while keeping glyph position and glyph
rotation as independent quantities. Fix rotation at zero and the text stays readable
while the body deforms.

Two traps worth remembering. First, the pretext dragon is heavily cited in
secondary/SEO content as the canonical "text behaves like a creature" demo, and it is
not that — verifying it required cloning and running the actual repo, and the licensing
turned out to be absent despite a README claim. Treat popular creative-coding
attributions as unverified until the source is fetched. Second, width tables in
procedural-animation code are commonly half-widths applied at ±90°; misreading one as a
full width silently halves the body and can lead to abandoning a viable design. Both
errors were made during this research by intermediate passes and only caught by reading
primary source.

Also durable: image-domain effect parameters (ripple amplitude/wavelength) do not
transfer to typography, where the natural unit is a fraction of glyph size — roughly
1–2px of offset at body-text sizes, with the rest of the disturbance carried through
luminance rather than position. And "text as a pond surface" turned out to be nearly
unprecedented on the open web, so anyone building it should expect to tune rather than
copy.
