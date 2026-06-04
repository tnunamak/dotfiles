# Repeatability Rubric

Use this rubric to decide what to script, what to template, and what must remain
human or model judgment.

## Mechanical

These are worth scripting:

- locating candidate session files;
- extracting user-message corpora;
- filtering injected runtime/user-role duplicates;
- adding bounded agent context snippets;
- counting primitive regex hits;
- bucketing windows by time;
- dumping a window into a compact review file;
- selecting contrastive windows deterministically;
- checking whether referenced commits exist.

Mechanical outputs are locators, not conclusions.

## Semi-Mechanical

These are worth templating and sometimes delegating:

- writing audit cards with fixed fields;
- classifying a window by contrast class;
- checking agent final-message claims against repo evidence;
- adding phase labels;
- finding later repair or acceptance within a bounded lookahead;
- making a static UI or artifact index.

Semi-mechanical outputs need review because the same words can mean different
things in different phases.

## Judgment-Heavy

These should not be automated away:

- identifying the live object that should have stayed bound;
- deciding whether "proceed" means acceptance, impatience, or baton-pass;
- deciding whether a steering act caused later behavior;
- distinguishing useful live correction from agent failure;
- deciding whether a primitive is generally useful or session-specific;
- promoting a primitive into durable prompting advice.

Judgment-heavy work is where the audit creates value. Scripts should make this
work cheaper, not replace it.

## Prematurity Check

Do not script a new evaluator if:

- precision of primitives has not been hand-labeled;
- clean controls are missing;
- outcomes are not checked outside final messages;
- the output would imply authority the evidence does not support;
- the user is still trying to understand the phenomenon.

Do script a helper if:

- it reduces repeated file/log spelunking;
- it produces a candidate list for human review;
- it makes future audits cheaper without hiding uncertainty.
