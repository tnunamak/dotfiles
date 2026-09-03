---
name: deck-building
description: Build presentation decks for Tim the way his orchestrator sessions do — author-then-translate into native editable Google Slides, with his anti-slop register, verbatim-diff and visual verification gates, and the slidetext.py editing loop. Use when Tim asks for a slide deck, session slides, a talk deck, or edits to an existing Google Slides deck. Triggers: "make me slides", "session N deck", "build a deck", "update the deck", "speaker notes".
---

# Deck building (Tim's pipeline)

Battle-tested across PDPP working sessions 1-3 (Aug 2026). Follow the pipeline;
every deviation listed here was learned by breaking something.

## The non-negotiable pipeline

1. **Brainstorm the frame with Tim first.** The deck's key points come from the
   MATERIAL, never from Tim's stream-of-consciousness questions (he flagged
   this explicitly: his dictated questions are him organizing thoughts, not
   focal points). Propose a frame; let him poke; iterate in conversation.
2. **Propose a concise slide outline** — one line + a few details per slide,
   a short list he can rapidly iterate on. Wait for his pass.
3. **The lead agent authors EVERY WORD** in a text source-of-record file
   (`<project>/local/<deck>-authored.md`): per slide, layout hint, HEADLINE /
   SUBTITLE / ROWS / CARDS / CHIPS / JSON / LINE fields, plus a NOTES block.
   Cheaper agents may only TRANSLATE, never write or reword copy. Tim
   instituted this rule on a top-tier model for a reason.
4. **Audit battery before he sees a word** (all three, in order):
   - slopgate CLI: `node ~/code/dotfiles/ai/skills/local/slopgate/detector/cli.mjs check --file <f> --json`
   - corpus-vocabulary check: grep every technical term against the project's
     canonical source (for PDPP: spec-core.md). Terms not in the corpus are
     the "slice vs fields" failure class.
   - manual register pass against the taxonomy below (slopgate can NOT see it).
5. **Dispatch a cheap agent (sonnet) to translate** into Google Slides. Rules
   for the translator prompt: copy is VERBATIM; anything that won't fit gets
   REPORTED, never reworded; verbatim diff (dump deck text, diff against the
   authored file, fix until clean) is mandatory before reporting done; visual
   thumbnail pass of every slide is mandatory (text diffs cannot see layout
   bugs); notes go in verbatim.
6. **Tim reworks directly in Slides.** Re-dump afterward to learn his edits —
   they are register training data (see taxonomy).
7. **Tim dictates a run-through.** Flag factual slips against the corpus,
   then REBUILD the speaker notes from his own spoken phrasing: glanceable,
   near-verbatim speakable, facts only. This is the notes version that works.

## Register taxonomy (what Tim edits out even when slopgate is silent)

- Rhetorical-question headlines -> declarative claims.
- Metaphor/drama framing -> functional description ("on trial", "reaches
  into", "the bet" all died).
- The deck never talks about itself: no "in this section", no segue lines
  ("the next slide shows..."), no arc language. Segues are spoken.
- No dunks on third parties; hedge contestable claims ("arguably").
- No categorical binaries; no emphatic repetition ("...and it stays the only
  one"); sweeping openers ("Everything is...") -> precise subjects.
- Real numbers only if verified; never invent statistics; if Tim says a
  number can't be confidently claimed, use no number at all.
- One idea per slide. Concrete beats abstract; a real artifact (verbatim JSON
  from the canonical spec) beats a description of one.
- Speaker notes: short first-person facts he might forget (numbers, names,
  back-pocket answers). NO stage directions, NO coaching ("pause here", "say
  this plainly"), NO restating the slide.
- Open questions are presented as plain statements + one alternative line
  ("Alternatively, everything could be mutable in v0.1.0"), never as
  confessional framing ("Two things we are not sure about" died).
- His closing pattern: a "Recapping some key decisions" numbered-card slide,
  discussion prompts live in speaker notes, CTAs consolidate on the close.

## Toolchain

- **Chrome/layout reuse:** COPY the most recent delivered deck via
  workspace-mcp `copy_drive_file` (a fresh copy does NOT inherit sharing —
  tell Tim it's private until he shares). NEVER write to the source deck;
  verify the target ID before every mutating call.
- **Text edits:** `assets/slidetext.py` (same file also at
  pdpp/local/deck-assets/slidetext.py) — dump / set / setfile / apply /
  notes; deck ID via PDPP_NATIVE_DECK_ID env or --deck. Auth reuses
  workspace-mcp credentials on disk (~/.config/workspace-mcp/credentials).
  Needs google-api-python-client + google-auth in a venv (uv).
- **Structural edits:** workspace-mcp `batch_update_presentation`
  (duplicateObject, deleteObject, updateSlidesPosition, updateTextStyle).
- **Visual verification:** `get_page_thumbnail` (LARGE) -> download -> LOOK
  at it. **PDF export** of the whole deck so the lead agent can inspect
  pages itself; deliver the PDF to Drive if Tim needs it portable
  (`gog drive upload` raw — NEVER `--convert`, it 500s).

## Known traps (each one bit us)

- `batch_update_presentation` is ATOMIC per call: a bad request rolls back
  the whole batch silently. Re-dump and verify after every batch; never
  trust individual success replies.
- `updatePageElementTransform` with applyMode ABSOLUTE collapses shapes to a
  wrong base size unless you restate the compensating scale (size lives
  outside the transform). Use RELATIVE deltas for moves.
- `updateSlidesPosition` with multiple slides requires presentation order and
  computes indexes against pre-move state; do ONE move per call and re-dump
  between moves.
- Duplicated slides inherit the source's CURRENT text (including Tim's later
  edits) — overwrite all text fields on copies.
- python-pptx decimal coordinates (x="123.0") break Google Slides import —
  irrelevant if you stay native, which you should (never image slides, never
  pptx round-trips; Tim banned image slides permanently).
- Six chips duplicated at full card size = giant overlapping boxes; chip
  shapes need explicit small geometry. Check thumbnails.
- Text dumps truncate ~90 chars per element; for full text use the Slides API
  directly (pattern in slidetext.py's text_of/walk).
- An agent's "visually checked" claim misses real collisions (footer overlap,
  doubled rules, wrong fonts). The LEAD agent reads the exported PDF pages
  itself before Tim sees the deck.
- Live-edit safety: if Tim is about to present, STOP structural agents
  (in-flight mutations during a talk are the worst failure); text-only
  `slidetext.py apply` edits are safe and surgical. Google Slides version
  history makes everything recoverable — say so if he fears lost edits.

## Facts-before-authoring rule

Before writing any slide containing protocol/technical claims, grep the
canonical source for the exact shapes (field names, JSON examples, error
codes, numbers). Session-3 lesson: a slide claimed grant narrowing was
supported; the spec said the opposite. Verify every claim you did not
personally confirm this session, especially "obvious" ones.

## Session-deck specifics (PDPP working sessions)

- Delivered decks to clone for chrome: session 2
  `1jV4QQxs1i_oA_l_V_dhD7zAzmVAPkAqTm91j6eLmqik`, session 3
  `1VUqCs1gMMy4GYOAJopvBUWyCYh9mt2o6_VpBDGD2ixU` (session 1:
  `1w_oMmzvIsqUlrcsoFMZ_59yi_6uKTHcIWA_nBNHtVcg`, shared with Anna).
- Authored sources of record: pdpp repo `local/session{1,2,3}-deck-authored.md`.
- Envelope: ~12-15 sparse slides for a 30-min session (~15 content + Q&A);
  schedule slide rows with a TODAY tag; title/close chrome reused.
- Anna's register (adopted where the audience already saw it): "primitives"
  not "nouns", gerund schedule headline, platform-value argument
  (Oura API / Granola MCP), legal-rights framing for connectors.
