---
title: "A short context label carries scent only when its distinguishing keyword is front-loaded into the first ~2 words / ~11 characters; shared prefixes waste the highest-scent real estate"
date: 2026-07-16
topic: session-ux
tags: [information-scent, information-foraging, labels, truncation, nng, f-pattern]
status: draft
sources: [pirolli-card-1999, nng-first-2-words, nng-writing-links, nng-f-pattern, dubroy-chi2010]
source_session: 66850dc0-bec5-47ac-9554-487d12bfb62b
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = interpretation. Skippable. No citations here.
-->

## CLAIMS

- Information scent is the perception of the value, cost, or access path of an information source obtained from proximal cues such as links or icons; foragers follow scent to decide which source to pursue. [pirolli-card-1999]
- If scent is sufficiently strong the forager makes the correct choice at each decision point; scent-following behaves like heuristic search. [pirolli-card-1999]
- Users typically see only about the first 2 words of a list item — a little more if the lead words are short, only the first word if they are long. [nng-first-2-words]
- In an NN/g study, a link whose first 11 characters were "Gift Cards " let 85% of users correctly predict its destination and 100% pick it correctly, while a link whose first 11 characters were "Introducing" gave 0% of users a reasonable prediction. [nng-first-2-words]
- The best links start with the most important words; front-loading the link name helps users scan because people mostly look at the first 2 words of a link. [nng-writing-links]
- Links must clearly explain where they lead (good information scent); starting every link on a page with the same introductory text (e.g. "Read more about…") is an anti-pattern. [nng-writing-links]
- In the F-shaped reading pattern, the first few words on the left of each line receive more fixations than later words; headings should start with the words carrying the most information so that seeing only the first 2 words still conveys the gist. [nng-f-pattern]
- The F-pattern is the default scanning behavior when there are no strong cues attracting the eye toward meaningful information. [nng-f-pattern]
- In a logging study of Firefox users, the typical working set of tabs was small (only one participant had a median above 6) but the same users spiked situationally to 20–42 tabs; users kept tabs open as reminders and "just in case," making labels function as memory aids, not only navigation. [dubroy-chi2010]

## SOURCES

**pirolli-card-1999**
URL: https://act-r.psy.cmu.edu/wordpress/wp-content/uploads/2012/12/280uir-1999-05-pirolli.pdf
Accessed: 2026-07-16
Quote: "Information scent is the (imperfect) perception of the value, cost, or access path of information sources obtained from proximal cues, such as bibliographic citations, WWW links, or icons representing the sources." / "If scent is sufficiently strong, the forager will be able to make the correct choice at each decision point."

**nng-first-2-words**
URL: https://www.nngroup.com/articles/first-2-words-a-signal-for-scanning/
Accessed: 2026-07-16
Quote: "Users typically see about 2 words for most list items; they'll see a little more if the lead words are short, and only the first word if they're long." / "85% of users were able to predict where this link led after seeing only the first 11 characters, and 100% of users successfully picked this link." / "on its tested link, the initial 11 characters, 'Introducing,' had no meaning... none of the users had a reasonable prediction."

**nng-writing-links**
URL: https://www.nngroup.com/articles/writing-links/
Accessed: 2026-07-16
Quote: "Finally, the best links start with the most important words." / "Frontloading the link name helps users scan the page more easily" / "Links should have good information scent: that is, they must clearly explain where they will take users."

**nng-f-pattern**
URL: https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content/
Accessed: 2026-07-16
Quote: "First few words on the left of each line of text receive more fixations than subsequent words on the same line." / "Start headings and subheadings with the words carrying most information: if users see only the first 2 words, they should still get the gist of the following section." / "The F-pattern is the default pattern when there are no strong cues to attract the eyes towards meaningful information."

**dubroy-chi2010**
URL: https://www.dgp.toronto.edu/~ravin/papers/chi2010_tabbedbrowsing.pdf
Accessed: 2026-07-16
Quote: "Participant 14 had by far the highest median number of tabs open with 17, while no other participant had a median higher than 6." / "Having the tab open is a reminder to me." / "I will often lose interest in something, and I think I might go back to it, so I will leave the tab open".

## SYNTHESIS

The scent budget of a switcher label lives in its first ~11 characters / first ~2 words. Everything after that is read only after the user has already decided the item is a candidate. This yields a concrete label grammar for Tim's 12–40 char windows:

- **Front-load the differentiator.** The leftmost token must be the thing that distinguishes this window from its siblings — the project name or the specific task noun — because that is the only part reliably read. Tim's current agent labels ("✳ Fix streaming browser surface package UX") bury the project behind a generic verb; "Fix" is a low-scent lead shared across many agent windows, the exact Chase-"Introducing" failure. Prefer `dotfiles: fix tmux restore` over `Fix tmux restore in dotfiles`.

- **Kill shared prefixes.** If every label reads `main:12 · claude · ~/code/...`, the high-scent real estate is spent on boilerplate that differentiates nothing. Socket names, the literal word "claude"/"zsh"/"node", and repeated home-dir paths belong pushed right, encoded as a glyph, or dropped. Generic process-name labels ("zsh", "node") carry near-zero scent and should be replaced with the project/cwd basename.

- **State is a cue, not a lead word.** An attention state (needs-input, running, error) is high-value scent, but if spelled as a leading word it pushes the differentiator right. Encode state as a single leading GLYPH or a color/badge that costs ~1 char, so the first readable word stays the differentiator.

- **Proposed grammar (left to right, high→low scent):** `<state-glyph> <project-or-differentiator> <task-verb-phrase> <age?>`. The state glyph is ~1 char; project/differentiator occupies the first-2-words slot; the task phrase fills the middle where a scanning user reads only if interested; age/host go last or are dropped. Age matters as a foraging cost cue (stale vs live) but is the lowest-scent field, so it belongs at the right edge or as a dim suffix.

- **Labels double as reminders.** The tab studies show users keep contexts open as memory aids and forage back to them later; a good label is not just "which window is this" but "what was I doing and is it worth returning to" — another argument for the task-phrase middle over a bare process name.
