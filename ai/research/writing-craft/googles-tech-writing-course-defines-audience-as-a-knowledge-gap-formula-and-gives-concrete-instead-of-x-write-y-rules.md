---
title: "Google's technical writing course defines audience as a knowledge-gap formula and gives concrete instead-of-X-write-Y rules for jargon, abbreviations, and pronouns"
date: 2026-08-14
topic: writing-craft
tags: [audience, google-tech-writing, style-guide, jargon, curse-of-knowledge, plain-language]
status: draft
sources: [tech-writing-audience, tech-writing-words, tech-writing-error-audience, style-guide-tone, style-guide-word-list]
source_session: unknown
---

## CLAIMS

- Google's "Technical Writing One" course defines good documentation with an explicit
  formula: "good documentation = knowledge and skills your audience needs to do a task
  − your audience's current knowledge and skills." [tech-writing-audience]
- The course instructs writers to identify audience by **role** first (e.g. software
  engineers, scientists, students, non-technical positions), then by the audience's
  **proximity** to the subject — their existing familiarity with related concepts and
  how time has eroded that familiarity. [tech-writing-audience]
- The course names "the curse of knowledge" as the core failure mode: "Experts often
  suffer from the curse of knowledge, which means that their expert understanding of a
  topic ruins their explanations to newcomers," and explicitly warns "As experts, it is
  easy to forget that novices don't know what you already know." [tech-writing-audience]
- The course gives a concrete widening-audience rule: "The people on your team probably
  understand your team's abbreviations, but people on other teams often don't — so as
  your target audience widens, assume that you must explain more." It extends this to
  implementation details: "Unless you are writing specifically for other experienced
  members of your team, you typically must explain more than you expect." [tech-writing-audience]
- The course names idioms explicitly as a form of the curse of knowledge and gives
  direct replacements: "a sticky wicket" → "challenging problem"; "Bob's your uncle" /
  "a piece of cake" → "this task is done"; "Be that as it may" → "However." [tech-writing-audience]
- The course's word-choice module gives an explicit rule for introducing terms: "If the
  term already exists, link to a good existing explanation. If your document is
  introducing the term, define the term." [tech-writing-words]
- The word-choice module gives an explicit abbreviation rule: "On the initial use of an
  unfamiliar acronym within a document or a section, spell out the full term, and then
  put the acronym in parentheses" — e.g. "Telekinetic Tactile Network (TTN)." [tech-writing-words]
- The word-choice module treats ambiguous pronouns (it, they/them/their, this, that) as
  a defect class of the same kind as undefined jargon: "Using pronouns improperly causes
  the cognitive equivalent of a null pointer error in your readers' heads," and gives a
  before/after: "Running the process configures permissions and generates a user ID.
  This lets users authenticate." → "This user ID lets users authenticate." [tech-writing-words]
- A dedicated course page ("Write for the target audience," under error-messages)
  extends curse-of-knowledge guidance specifically to messages read by someone who
  wasn't present for the engineering decision: "A term familiar to you might not be
  familiar to your target audience," with the instruction to "Use appropriate
  terminology for that target audience. Be mindful of what the target audience knows
  and doesn't know." [tech-writing-error-audience]
- That page's worked example rewrites an internals-facing error for a non-technical
  shopper: instead of "A server dropped your client's request because the server farm
  is running at 92% CPU capacity," write "So many people are shopping right now that
  our system can't complete your purchase. Don't worry — we won't lose your shopping
  cart. Please retry in five minutes." [tech-writing-error-audience]
- The Google Developer Documentation Style Guide's tone page instructs writers to "Try
  to sound like a knowledgeable friend who understands what the developer wants to do,"
  and to "aim for a conversational tone rather than a formal one." [style-guide-tone]
- The style guide's tone page ties audience calibration to translation/localization
  explicitly, not just native-English readers: "Consider that readers come from many
  different cultures and may have varying levels of ability reading English," and notes
  "Simple and consistent writing can also make it easier to translate documents into
  other languages." [style-guide-tone]
- The style guide's tone page gives an unusually concrete negative rule about politeness
  markers in instructions: "using please in a set of instructions is overdoing the
  politeness." [style-guide-tone]
- The style guide's word list gives multiple concrete instead-of-X-use-Y entries: for
  Latin abbreviations ("Don't use [e.g./i.e.]. Instead, use phrases like for example or
  such as"); for "aka" ("Don't use. Instead, present an alternative term using
  parentheses or the word or"); and for "authN"/"authZ" ("Don't use. Instead, use
  authentication or authorization"). [style-guide-word-list]
- The word list separately flags overused/vague jargon terms for replacement:
  "actionable" ("Avoid unless it's the clearest and simplest phrasing for your
  audience... replace it with a phrase like that you can act on") and "anti-pattern"
  ("Avoid... consider using a more specific and broadly understood term"). [style-guide-word-list]

## SOURCES

**tech-writing-audience**
URL: https://developers.google.com/tech-writing/one/audience
Accessed: 2026-08-14
Quote: "good documentation = knowledge and skills your audience needs to do a task − your audience's current knowledge and skills"; "Experts often suffer from the curse of knowledge, which means that their expert understanding of a topic ruins their explanations to newcomers."; "As experts, it is easy to forget that novices don't know what you already know."; "Idioms are another form of the curse of knowledge."

**tech-writing-words**
URL: https://developers.google.com/tech-writing/one/words
Accessed: 2026-08-14
Quote: "If the term already exists, link to a good existing explanation. If your document is introducing the term, define the term."; "On the initial use of an unfamiliar acronym within a document or a section, spell out the full term, and then put the acronym in parentheses."; "Using pronouns improperly causes the cognitive equivalent of a null pointer error in your readers' heads."

**tech-writing-error-audience**
URL: https://developers.google.com/tech-writing/error-messages/target-audience
Accessed: 2026-08-14
Quote: "A term familiar to you might not be familiar to your target audience."; "Use appropriate terminology for that target audience. Be mindful of what the target audience knows and doesn't know."

**style-guide-tone**
URL: https://developers.google.com/style/tone
Accessed: 2026-08-14
Quote: "Try to sound like a knowledgeable friend who understands what the developer wants to do."; "Consider that readers come from many different cultures and may have varying levels of ability reading English."; "using please in a set of instructions is overdoing the politeness."

**style-guide-word-list**
URL: https://developers.google.com/style/word-list
Accessed: 2026-08-14
Quote: "Don't use [e.g./i.e.]. Instead, use phrases like for example or such as."; "Don't use [authN/authZ]. Instead, use authentication or authorization."

## SYNTHESIS

Google's course does not use the phrase "wasn't in the room," but the concept is the
exact content of two independent teaching moments: (1) the curse-of-knowledge framing
in `tech-writing/one/audience`, which is specifically about experts forgetting that
listeners lack the shared context the expert built up while solving the problem, and
(2) the error-messages target-audience page, which applies the same idea to a reader
who is even further removed — someone hitting a failure with zero access to the
engineering conversation that produced the error. The shopping-cart rewrite example is
the clearest "in the room vs. not in the room" pair in the corpus: the original sentence
assumes the reader knows what a server farm and CPU capacity are (writer's context); the
rewrite assumes only that the reader wants to buy something and is worried about losing
their cart (reader's actual context).

The audience definition itself — a subtraction formula (needed knowledge minus current
knowledge) plus a two-axis identification method (role, then proximity) — is more
operational than typical "know your audience" advice. It gives a writer two concrete
questions to ask before drafting rather than a vague disposition to hold while writing.

The style guide and course are consistent with each other on mechanism (define once,
explain more as scope widens, prefer plain synonyms) but the style guide's word list
is the more directly reusable artifact for an automated check or lint: it's a maintained
list of specific banned/discouraged terms with prescribed replacements (e.g., i.e./e.g.
→ "for example"/"that is"; authN/authZ → "authentication"/"authorization"; aka →
parenthetical or "or"), which is closer to a rule table than to prose guidance. The
pronoun-antecedent rule ("cognitive equivalent of a null pointer error") is the single
most quotable line in the corpus for explaining *why* vague referents cost a reader
without context — it names the failure mechanically rather than just calling it "unclear."
