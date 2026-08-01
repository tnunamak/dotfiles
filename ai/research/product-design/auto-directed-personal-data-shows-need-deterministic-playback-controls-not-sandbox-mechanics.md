---
title: "An auto-directed personal-data show should preserve its default flow while exposing deterministic pause, reading-time, history, and cue-navigation controls"
date: 2026-07-11
topic: product-design
tags: [game-interaction, playback, visual-novel, accessibility, timed-text, mobile, personal-data]
status: draft
sources: [ea-sims-time-controls, renpy-preferences, renpy-config, renpy-history, renpy-rollback, renpy-keymap, wcag-timing, wcag-pause]
source_session: 019f51de-df3c-7ef1-951d-65adee1e8b0a
---

## CLAIMS

- EA's official *The Sims 4* tips page lists `P` / `0` / backtick as pause controls and `1` / `2` / `3` as regular, fast, and ultra simulation speeds. [ea-sims-time-controls]
- Ren'Py exposes a text-speed preference (`preferences.text_cps`), an auto-forward enablement preference and time (`preferences.afm_enable`, `preferences.afm_time`), and documents that a larger auto-forward time is slower because timing accounts for line length. [renpy-preferences]
- Ren'Py's auto-forward configuration adds a character-count component and can suppress auto-forward while voice is playing. [renpy-config]
- Ren'Py's dialogue history stores shown dialogue so it can be retrieved and shown again; a history entry can carry a rollback identifier. [renpy-history]
- Ren'Py documents rollback as returning to an earlier checkpoint, including game state and reversible variables, rather than merely changing which line is displayed. [renpy-rollback]
- Ren'Py's default keymap distinguishes rollback (Page Up), roll-forward (Page Down), and dismiss/advance (Enter, Space, keypad Enter, select, or primary mouse release). [renpy-keymap]
- WCAG 2.2 SC 2.2.1 treats content that advances beyond a person's ability to read or understand as a time limit; the page's own timing can be turned off, adjusted, or extended, and an alternative that does not rely on a timer also satisfies the concern. [wcag-timing]
- WCAG 2.2 SC 2.2.2 requires a mechanism to pause, stop, hide, or control the frequency of automatically moving or updating information presented in parallel with other content; it identifies a single control covering multiple moving elements as a UX best practice. [wcag-pause]
- WCAG's explanatory guidance says that, outside a real-time status context, resuming from the point at which a user paused is the better behavior for someone pausing to read. [wcag-pause]

## SOURCES

**ea-sims-time-controls**
URL: https://www.ea.com/en-au/games/the-sims/tips-and-tricks
Accessed: 2026-07-11
Quote: "Pause game P / 0 / `" and "Regular/fast/ultra speed 1 / 2 / 3."

**renpy-preferences**
URL: https://www.renpy.org/doc/html/preferences.html
Accessed: 2026-07-11
Quote: "preferences.text_cps = 0 ... The speed of text display" and "preferences.afm_time = 15 ... Bigger numbers are slower."

**renpy-config**
URL: https://www.renpy.org/doc/html/config.html
Accessed: 2026-07-11
Quote: "config.afm_characters" determines the characters used in auto-forward timing; the default callback disables auto-forward while voice is playing unless configured otherwise.

**renpy-history**
URL: https://www.renpy.org/doc/html/history.html
Accessed: 2026-07-11
Quote: "Ren'Py includes a dialogue history system that stores each line of dialogue after it has been shown to the player."

**renpy-rollback**
URL: https://www.renpy.org/doc/html/save_load_rollback.html
Accessed: 2026-07-11
Quote: "Rollback allows the user to revert the game to an earlier state" and `renpy.rollback()` "Rolls the state of the game back to the last checkpoint."

**renpy-keymap**
URL: https://www.renpy.org/doc/html/keymap.html
Accessed: 2026-07-11
Quote: Default mappings include Page Up for rollback, Page Down for roll-forward, and Enter/Space/primary mouse for dismiss.

**wcag-timing**
URL: https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html
Accessed: 2026-07-11
Quote: "animated, moving or scrolling content introduces a time limit on a users ability to read and/or understand it."

**wcag-pause**
URL: https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html
Accessed: 2026-07-11
Quote: "Pausing and resuming where the user left off is best for users who want to pause to read content."

## SYNTHESIS

The usable synthesis is deliberately narrower than copying either precedent. The Sims contributes an immediately legible, persistent transport idea: a simulation can continue by default while the viewer has an obvious pause and speed override. Ren'Py contributes three separable ideas: reading rate is a preference, shown material remains inspectable, and backward/forward navigation has a precise state contract. Its *rollback* is not suitable as-is for an AI-directed personal-data episode, because it rewinds game state and choices; changing which already-authored episode cue is presented must not re-run curation, consume evidence, or change the episode.

For an auto-directed personal-data show, compile an immutable directed tape into deterministic **cues** (readable units such as narration, a chat turn group, a receipt reveal, or a scene transition). Keep auto-play as the default. Pause/resume must retain the exact cue and elapsed presentation position. Previous/next moves between cue snapshots and leaves the player paused. A reading-time setting changes only future automatic holds; a fully manual setting advances only through the same next-cue control. This offers control without turning the show into a sandbox, a branching game, or an episode editor.

Timed, meaningful text should be treated as an accessibility contract, not decorative animation. The practical floor is one pause control that freezes the whole presentation, an adjustable/disabled automatic advance path, complete text available in a semantic reading surface, and an inspectable source view that is reachable without a timer. For a mobile browser, the transport, readable text, and source view need separate layout regions; relying on z-index negotiations among canvas overlays and independently positioned DOM buttons makes that contract untestable.
