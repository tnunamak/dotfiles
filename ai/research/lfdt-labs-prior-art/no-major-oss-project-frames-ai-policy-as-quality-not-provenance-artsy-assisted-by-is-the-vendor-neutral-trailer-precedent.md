---
title: "No major OSS project frames its AI policy as quality-of-output rather than provenance; Artsy's Assisted-by RFC is the strongest (still non-standard) precedent for a vendor-neutral disclosure trailer"
date: 2026-07-21
topic: lfdt-labs-prior-art
tags: [ai-policy, ai-disclosure, contributing, quality-vs-provenance, git-trailer, assisted-by, co-authored-by, dco, curl, linux-kernel, linux-foundation, django, rust, biome, deno, pdp-connect]
status: draft
sources: [curl-golden-rule, curl-stenberg-tools-review, django-ai-policy-docs, django-security-ai-note, rust-forge-llm-policy, rust-rfc-3950, linux-kernel-coding-assistants-doc, linux-kernel-tomshardware, linux-foundation-genai-policy, biome-contributing-ai, deno-pr-template-ai, artsy-rfc-assisted-by, claude-code-assisted-by-issue, fabio-rehm-assisted-by, git-submittingpatches-trailers, github-copilot-coauthor-vscode, melissawm-policy-list]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
Filename = the claim in kebab-case (greppable), under the matching topic/ dir.
Add one line to INDEX.md when you create this.
-->

## CLAIMS

### Q1 — Is any credible project's AI policy framed as quality-of-output rather than provenance?

- **The dominant pattern across every major project checked (curl, Django, Rust, Biome, Deno, kernel) is provenance-based, not quality-based**: the operative rule is "disclose that AI was involved" / "AI must not write the human-facing prose" / "a human must sign off," not "we will judge your PR on its clarity and correctness regardless of how it was produced." [melissawm-policy-list] [biome-contributing-ai] [deno-pr-template-ai] [django-ai-policy-docs] [linux-kernel-coding-assistants-doc]
- **curl comes closest to a quality/effort framing, but as a review-cost heuristic, not an authorship-neutral policy**: "The golden rule is that a contribution should be worth more to the project than the time it takes to review it, which is usually not the case if large parts of your PR were written by LLMs." [curl-golden-rule] This still names LLM-written volume as the presumptive problem — it is provenance-adjacent, not purely outcome-based.
- **curl maintainer Daniel Stenberg has publicly separated "AI as a tool a clever person uses" from "AI slop," and does not treat AI-authorship itself as disqualifying** for code review assistance: he stated he runs "three different AI review bots" on curl's own PRs that catch missing tests and flawed assumptions overnight, and that curl's trust model for provenance was never author-identity-based in the first place — "someone made that code, copied that code, generated that code with AI, or copied it from Stack Overflow five years ago" are treated the same way (review the artifact). [curl-stenberg-tools-review] Despite this, curl's *written* PR policy (the "golden rule" above) still singles out LLM-written volume as presumptively low-value — Stenberg's personal quality-not-provenance instinct is not what's codified in curl's contributor-facing policy text.
- **Django's official policy is explicitly provenance/disclosure-based, not outcome-based**: contributors "must disclose which AI tools were used and what they were used for," and the policy separately addresses AI tools directly, demanding they "disclose involvement" and avoid fabricating APIs — the rejection trigger named is fabrication/inaccuracy tied to AI use, and disclosure is a standing requirement independent of whether the output is good. [django-ai-policy-docs] Django's security-report guidance likewise targets AI-sourced fabrication specifically ("Never thought I'd be writing official docs for a major open source project begging LLMs to stop fabricating surreal vulnerabilities" — Django Fellow Natalia Bidart). [django-security-ai-note]
- **The Rust Project's draft policy (RFC #3950, and the narrower rust-lang/rust Forge LLM policy) is provenance-based**: it distinguishes "private use of LLMs" (unrestricted) from "AI in creating public project content" (restricted), bars PR descriptions/comments/issue bodies "originally created by an LLM" from personal accounts, and states the project does not accept "vibe-coded" pull requests — the gate is where/how AI was used, not solely whether the resulting text or code is good. [rust-rfc-3950] [rust-forge-llm-policy]
- **The Linux kernel's new project-wide AI policy (`Documentation/process/coding-assistants.rst`, merged for kernel 7.0) is provenance-based by design**: it mandates a disclosure tag naming the specific model/tooling used (`Assisted-by: Claude:claude-3-opus coccinelle sparse`), requires the human DCO signer to retain full responsibility, and treats "purely machine-generated submissions" as unwelcome regardless of quality. [linux-kernel-coding-assistants-doc] The one contemporaneous soundbite that is genuinely quality-not-provenance in spirit is journalistic commentary, not the policy text itself: Tom's Hardware summarized the practical effect as "if the code is good, then it's good. If it's hallucinatory AI slop that breaks the kernel, the human who clicked 'submit' is the one who will have to answer to Linus Torvalds." [linux-kernel-tomshardware] Torvalds' own stated position — Linux "will not be an anti-AI project," and objectors can "fork it" — is permissive toward AI as a tool, but the codified rule contributors must follow is still the disclosure tag, not an authorship-blind quality bar. [linux-kernel-tomshardware]
- **The Linux Foundation's org-wide Generative AI Policy is the single closest thing found to an explicit "treat it the same" framing, but it governs licensing/IP risk, not writing quality**: "Code or other content generated in whole or in part using AI tools can be contributed to Linux Foundation projects... development and review of code generated by AI tools should be treated no differently" than human-written contributions. [linux-foundation-genai-policy] This sentence is about *review process equality* (don't require a separate AI-specific gate) and is paired immediately with IP/licensing-compliance conditions (tool terms-of-service must not conflict with the project license; attribution obligations for third-party material in AI output) — it does not address writing clarity/quality at all, and explicitly leaves "AI-generated content" guidance to individual LF projects. [linux-foundation-genai-policy] Because PDP-Connect is itself an LFDT (Linux Foundation) lab, this is the most directly applicable umbrella precedent available, even though it doesn't answer the writing-quality question.
- **Biome and Deno — the two projects with the most current (2026), most prominent AI-disclosure requirements — both explicitly ban AI-written human communication regardless of code quality**, which is the inverse of a quality-not-provenance stance: Biome states "Please do not use AI to write pull request descriptions or contributor communication for this project" as a rule separate from and additional to code-quality review; Deno's PR template states "PRs will be rejected if there is suspicion of undisclosed AI usage" as a standing rejection ground independent of the PR's actual content quality. [biome-contributing-ai] [deno-pr-template-ai]
- **No project surfaced in this research states a policy of the form Tim proposes** — "contributors are responsible for the quality of their writing; if it's unclear or sloppy we may ask for revision or decline, regardless of whether AI was involved" — as a *replacement* for a provenance/disclosure rule. Every credible project's formal contributor-facing text either bans/restricts AI-authored prose outright (Rust draft policy, Biome's PR-description clause) or requires disclosure as a standing, quality-independent condition (Biome, Deno, Django, kernel). This is a genuine gap, not a search-coverage failure: the community-maintained tracker of ~dozens of OSS AI policies (`melissawm/open-source-ai-contribution-policies`) was checked directly and its closest matches (curl, FastAPI, Apache DataFusion) all frame the bar as "worth more than the review-time cost," which is quality-*adjacent* (a cost/benefit heuristic) but still names AI-authorship-at-volume as the presumptive failure mode, not the code/prose's actual clarity. [melissawm-policy-list]

### Q2 — Is there a vendor-neutral AI-assistance commit-trailer precedent?

- **`Co-authored-by` is the established, vendor-agnostic-in-*syntax* GitHub convention, but every default tool implementation makes it vendor-specific in practice**: Claude Code defaults to inserting `Co-Authored-By: Claude <noreply@anthropic.com>`; GitHub Copilot in VS Code 1.118+ defaults to stamping a Copilot-specific co-author trailer (`git.addAICoAuthor` flipped to `all` by default in PR #310226, drawing user backlash: "a silent default... It's vandalism"); Aider appends `(aider)` to the author name and adds the specific model as co-author. None of these tools ship a shared, vendor-neutral identity string — each names its own product. [github-copilot-coauthor-vscode]
- **A real, deliberate rejection of `Co-authored-by` for AI in favor of a vendor-neutral-shaped trailer happened at Artsy**: an internal RFC ("disclose LLM usage in commits or PRs," opened 2026-05-27, merged 2026-06-08) initially drafted `Co-authored-by` (because it's the trailer everyone already knows) but the team talked itself out of it during review; the merged proposal's example trailer became `Assisted-by`. The stated rationale (Joey Aghion): `Assisted-by` "keeps responsibility visibly and exclusively with the human contributor, even though GitHub's UI doesn't count it as a contributor" — framed explicitly as a feature, not a bug, since "the whole point is that the tool does not get an avatar." [artsy-rfc-assisted-by] Artsy's RFC records the provider and *optionally* the model as trailer content, i.e., the trailer key itself (`Assisted-by:`) is vendor-neutral even though the value can name a vendor. [artsy-rfc-assisted-by]
- **Independent convergence on the same trailer name**: developer Fabio Rehm arrived at `Assisted-by: Claude Code` by generalizing from git's own documented `SubmittingPatches` convention, which already establishes a family of `<Verb>-by:` trailers with specific semantics (`Reported-by`, `Reviewed-by`, `Helped-by`, `Suggested-by`) and explicitly permits inventing new ones "if the situation warrants it." [fabio-rehm-assisted-by] [git-submittingpatches-trailers] This is the strongest argument that `Assisted-by` is not an ad hoc invention but a natural, low-friction extension of an existing, universally-understood git convention (`git interpret-trailers`, `git log --grep="Assisted-by:"` all work identically to any other trailer).
- **The Linux kernel adopted the same trailer *name* (`Assisted-by:`) as its official, mandatory tag — but populates it with vendor- and model-specific detail, not a vendor-neutral form**: the documented format is `Assisted-by: Claude:claude-3-opus coccinelle sparse`, i.e. tool name, specific model, and auxiliary tooling are all named inline. [linux-kernel-coding-assistants-doc] This means the one instance of `Assisted-by` becoming a formal, mandatory, project-wide rule in a flagship project uses it as a vendor-*specific* disclosure field, not a vendor-neutral generic-AI marker — a meaningful distinction from what Tim is asking for.
- **A three-tier layered model exists in tooling (not yet in any major project's formal policy) that treats `Assisted-by`, `Co-authored-by`, and `Generated-by` as a graduated scale by degree of AI contribution**, paired with a human `Signed-off-by` to preserve accountability: `Assisted-by` = minor help (code primarily human-written), `Co-authored-by` = substantial AI contribution, `Generated-by` = primarily AI-generated. The `rai-lint` tool formalizes exactly this tiering as a lint rule. [claude-code-assisted-by-issue] This is a community/tooling proposal, not an adopted project policy anywhere found.
- **`Signed-off-by` (DCO) and the AI-assistance trailer are understood as separate, non-competing mechanisms in every source found**: the kernel's policy explicitly keeps DCO sign-off as human-only ("Only humans may sign a patch's Developer Certificate of Origin") while adding `Assisted-by` as an orthogonal disclosure tag — DCO answers "who is legally certifying the right to contribute this," `Assisted-by`/`Co-authored-by` answers "who/what helped produce it." [linux-kernel-coding-assistants-doc] No source proposed folding AI disclosure into the DCO trailer itself.
- **There is an open, unresolved feature request asking Anthropic's own tool to switch its default from `Co-authored-by: Claude` to `Assisted-by`**, citing "several big projects" recommending it — confirming this is a live, contested default as of 2026, not a settled convention Claude Code already follows. [claude-code-assisted-by-issue]
- **Automation is explicitly anticipated but flagged as a risk, not solved**: Artsy's own RFC discussion raised "the risk of people automating the trailer via a hook or shell alias regardless of whether the help was 'significant'" as an open concern — i.e., the community that invented the vendor-neutral form has not yet settled whether blanket-automating it (every commit gets the trailer, no per-commit judgment) is desirable or degrades the signal. [artsy-rfc-assisted-by]

## SOURCES

**curl-golden-rule**
URL: https://github.com/melissawm/open-source-ai-contribution-policies (curl entry, cross-verified via search aggregation of curl's own CONTRIBUTING/AI docs)
Accessed: 2026-07-21
Quote: "The golden rule is that a contribution should be worth more to the project than the time it takes to review it, which is usually not the case if large parts of your PR were written by LLMs."

**curl-stenberg-tools-review**
URL: https://thenewstack.io/curls-daniel-stenberg-ai-is-ddosing-open-source-and-fixing-its-bugs/ ; https://opensourcesecurity.io/2025/2025-05-curl_vs_ai_with_daniel_stenberg/
Accessed: 2026-07-21
Quote: Stenberg uses "three different AI review bots" on curl's PRs that run overnight and catch "missing tests or flawed assumptions about external library behavior"; on provenance: "someone made that code, copied that code, generated that code with AI, or copied it from Stack Overflow five years ago" are treated the same for trust purposes.

**django-ai-policy-docs**
URL: https://docs.djangoproject.com/en/dev/internals/contributing/writing-code/submitting-patches/
Accessed: 2026-07-21
Quote: Contributors must "disclose which AI tools were used and what they were used for (e.g., generating code, drafting commit messages, writing documentation)"; a section addressed directly to AI tools requires "disclosing its involvement" and "not inventing APIs, features, functions, or citations that do not exist."

**django-security-ai-note**
URL: https://socket.dev/blog/django-joins-curl-in-pushing-back-on-ai-slop-security-reports
Accessed: 2026-07-21
Quote: Django Fellow Natalia Bidart on Mastodon: "Never thought I'd be writing official docs for a major open source project begging LLMs to stop fabricating surreal vulnerabilities."

**rust-forge-llm-policy**
URL: https://github.com/rust-lang/rust-forge/pull/1040 (Add an LLM policy for `rust-lang/rust`)
Accessed: 2026-07-21
Quote: Distinguishes "private use of LLMs" (permitted: answering questions, analyzing code, private review) from "use in creating public project content" (restricted); states the project does not accept "vibe-coded" pull requests that lower codebase quality; PR descriptions/comments/issue bodies "originally created by an LLM" barred from personal accounts.

**rust-rfc-3950**
URL: https://github.com/rust-lang/rfcs/pull/3950 (Add contribution policy for AI-generated work)
Accessed: 2026-07-21
Quote: "We adopt a Rust Project contribution policy for AI-generated work" that "applies to all Project spaces."

**linux-kernel-coding-assistants-doc**
URL: kernel Documentation/process/coding-assistants.rst, merged for Linux 7.0 (via secondary reporting: https://shiporskip.io/news/linux-kernel-ai-assisted-patches-official-guidance-maintainer-policy-2026 ; https://itsfoss.com/news/linux-ai-coding-assistants-policy/)
Accessed: 2026-07-21
Quote: Disclosure tag format "Assisted-by: Claude:claude-3-opus coccinelle sparse"; "Only humans may sign a patch's Developer Certificate of Origin"; purely machine-generated submissions "not welcome."

**linux-kernel-tomshardware**
URL: https://www.tomshardware.com/software/linux/linux-lays-down-the-law-on-ai-generated-code-yes-to-copilot-no-to-ai-slop-and-humans-take-the-fall-for-mistakes-after-months-of-fierce-debate-torvalds-and-maintainers-come-to-an-agreement
Accessed: 2026-07-21
Quote: "The bottom line is, if the code is good, then it's good. If it's hallucinatory AI slop that breaks the kernel, the human who clicked 'submit' is the one who will have to answer to Linus Torvalds." Torvalds: Linux "will not be an anti-AI project"; objectors can "fork the project or leave it."

**linux-foundation-genai-policy**
URL: https://www.linuxfoundation.org/legal/generative-ai
Accessed: 2026-07-21
Quote: "Code or other content generated in whole or in part using AI tools can be contributed to Linux Foundation projects." "[D]evelopment and review of code generated by AI tools should be treated no differently" than human-written contributions. Individual LF projects "may develop their own project-specific guidance."

**biome-contributing-ai**
URL: https://raw.githubusercontent.com/biomejs/biome/main/CONTRIBUTING.md
Accessed: 2026-07-21
Quote: "If you are using any kind of AI assistance to contribute to Biome, it must be disclosed in the pull request." / "Please do not use AI to write pull request descriptions or contributor communication for this project."

**deno-pr-template-ai**
URL: https://github.com/denoland/deno/blob/main/.github/PULL_REQUEST_TEMPLATE.md
Accessed: 2026-07-21
Quote: "IMPORTANT: If you used AI tools (e.g. Copilot, ChatGPT, Claude, Cursor, etc.) to help write this PR, you MUST disclose it in the PR description. PRs will be rejected if there is suspicion of undisclosed AI usage."

**artsy-rfc-assisted-by**
URL: https://www.baristalabs.io/blog/ai-assisted-commits-need-provenance-trailer (reporting on Artsy's internal RFC, "disclose LLM usage in commits or PRs," opened 2026-05-27, merged 2026-06-08); RFC process reference: https://github.com/artsy/README/blob/non-incidents/playbooks/rfcs.md
Accessed: 2026-07-21
Quote: Joey Aghion: "Assisted-by" "keeps responsibility visibly and exclusively with the human contributor, even though GitHub's UI doesn't count it as a contributor" — "the whole point is that the tool does not get an avatar." Open concern raised in discussion: "the risk of people automating the trailer via a hook or shell alias regardless of whether the help was 'significant.'"

**claude-code-assisted-by-issue**
URL: https://github.com/anthropics/claude-code/issues/36105 ([FEATURE] Use `Assisted-by` git commit trailer instead of `Co-authored-by`)
Accessed: 2026-07-21
Quote: Issue argues Claude Code should switch "as it's recommended by several big projects." Open/unresolved as of access date.

**fabio-rehm-assisted-by**
URL: https://fabiorehm.com/blog/2026/03/02/our-coding-agent-commits-deserve-better-than-co-authored-by/
Accessed: 2026-07-21
Quote: Notes git's `SubmittingPatches` docs already suggest `Reported-by`, `Reviewed-by`, `Helped-by`, `Suggested-by` and states contributors "can create your own if the situation warrants it"; settles on `Assisted-by: Claude Code`.

**git-submittingpatches-trailers**
URL: git.git Documentation/SubmittingPatches (referenced via fabio-rehm-assisted-by; canonical trailer semantics also documented at `git help interpret-trailers`)
Accessed: 2026-07-21
Quote: Documents the extensible `<Verb>-by:` trailer family (`Reported-by`, `Tested-by`, `Reviewed-by`, `Suggested-by`, etc.) as a general, open-ended convention.

**github-copilot-coauthor-vscode**
URL: https://winbuzzer.com/2026/05/03/vs-code-1-118-copilot-co-author-default-commits-xcxwbn/
Accessed: 2026-07-21
Quote: "VS Code 1.118 now stamps a Copilot co-author trailer on Git commits by default after PR #310226 flipped `git.addAICoAuthor` to `all`." User backlash quote: "a silent default... It's vandalism."

**melissawm-policy-list**
URL: https://github.com/melissawm/open-source-ai-contribution-policies
Accessed: 2026-07-21
Quote: Community-maintained aggregation of OSS AI contribution policies across many projects; closest quality-leaning entries found are curl, FastAPI ("If the human effort put in a PR... is less than the effort we would need to put to review it, please don't submit the PR"), and Apache DataFusion ("Better ways to contribute than an AI dump") — all cost/effort heuristics, not authorship-blind quality bars.

## SYNTHESIS

**Q1 answer: this is a real gap, not a search miss.** Across curl, Django, Rust, Biome, Deno, the Linux kernel, and the Linux Foundation's own umbrella policy — the group most likely to have already solved this, since it spans the exact governance layer PDP-Connect sits under as an LFDT lab — not one formal, contributor-facing policy is framed as "we judge the output; provenance is irrelevant." Every one names AI-authorship itself (undisclosed, prominent, or "primarily") as a distinct thing to police, on top of or instead of ordinary quality review. The closest analogues are: (a) curl/FastAPI's review-cost heuristic ("worth more than the time it takes to review"), which is an *economic* framing, not a *quality* one — a short, excellent, obviously-AI-assisted PR passes it trivially, but so does the framing's implicit suspicion of "large parts... written by LLMs"; (b) the Linux Foundation's "treated no differently" sentence, which is about *review process* parity (no extra AI-specific gate) and is bundled with licensing/IP conditions, not writing-quality standards; (c) Torvalds' personal stance and the Tom's Hardware "if the code is good, it's good" summary, which capture the *spirit* Tim wants but describe journalistic gloss on a kernel policy whose actual codified rule is a mandatory vendor-specific disclosure tag. PDP-Connect adopting an explicit quality-not-provenance framing would be ahead of the field, not catching up to an existing norm — this is worth stating plainly in whatever policy doc results, since it's a genuine differentiator Tim can point to rather than an obvious-in-hindsight best practice he's late to.

**Why this matters for PDP-Connect specifically**: the existing corpus entry in this directory (`high-craft-contribution-flow-...md`) already recommends borrowing Biome/Deno's disclosure-banner pattern — that recommendation is sound as a *baseline* (disclosure costs nothing and pre-empts "did they hide it" suspicion) but it inherits the provenance framing wholesale. Tim's stated preference is a *superset*: keep an AI-disclosure line if he wants the optics benefit of transparency, but make the actual accept/reject criterion the writing's clarity and quality, stated explicitly so contributors (and future maintainers) don't misread "disclose AI use" as "AI use is presumptively suspect." A clean way to reconcile the two corpus entries: disclosure trailer = mechanical, automatic, zero-cost metadata (answers "how was this made," useful for maintainers calibrating review depth, per Django/kernel precedent); the *policy prose* in CONTRIBUTING.md = quality-not-provenance (answers "what's the bar," and explicitly states AI-assisted work is welcome and judged the same as anything else). No project studied separates these two cleanly — most conflate "disclose AI" with "AI is the risk factor" in the same sentence. PDP-Connect keeping them structurally separate (a trailer that's just data, and a policy that's just a quality bar) would itself be the novel, defensible position.

**Q2 answer: `Assisted-by` is the strongest real precedent for a vendor-neutral-*shaped* trailer, but "vendor-neutral" needs a precise definition — no project has actually deployed a generic, contentless AI marker.** Every real-world instance found (Artsy's RFC, Fabio Rehm's personal convention, the Linux kernel's mandatory tag) uses the *trailer key* `Assisted-by:` generically, but populates the *value* with a specific tool/model name (`Assisted-by: Claude:claude-3-opus ...`, `Assisted-by: Claude Code`). That's "vendor-neutral syntax, vendor-specific payload" — a meaningfully different thing from what "generic AI identity" might imply (e.g., `Assisted-by: AI` with no product name at all). Artsy's RFC discussion explicitly flagged this ambiguity itself, noting Cursor's auto-mode picks a model and never discloses which, so "you can't record a model string you were never given" — i.e., even the people building this convention hit cases where a fully generic marker (no vendor, no model) is the only honest option.

**Recommended form for PDP-Connect, reasoned from the precedent above:**
- **Trailer key**: `Assisted-by:` — not `Co-authored-by:` (every source that considered both explicitly rejected `Co-authored-by` for AI, for the same reason: it implies GitHub-recognized co-authorship/contributor status, which the community consensus found actively undesirable — "the tool does not get an avatar" is the correct default for a maintainer who wants credit and accountability to stay human). This also sidesteps the entire Claude Code / Copilot default-behavior controversy (both currently default to `Co-authored-by`, both have open complaints about it) by simply not using that trailer for AI at all.
- **Trailer value**: generic by default (`Assisted-by: AI`), with an optional, non-mandatory tool/model suffix when known and worth recording (`Assisted-by: AI (Claude Code)`) — this is the one place PDP-Connect can go further than any precedent found: nobody has shipped a *default-generic, optionally-specific* form. Given Tim's stated goal (never think about it, automated by a hook), defaulting to the fully generic value and treating vendor detail as optional enrichment (not a requirement) is both the simplest hook to write and the most robust to auto-mode/unknown-model cases that stumped Artsy's own RFC.
- **Automation**: a `prepare-commit-msg` or `commit-msg` git hook that appends the trailer unconditionally whenever commits originate from an agent session (detectable via an env var the CLI harness sets, or simply: PDP-Connect's own tooling always runs through an agent wrapper that stamps it) — this directly answers Tim's "never thinks about it" requirement and sidesteps the human-judgment question Artsy flagged as unresolved ("was the help 'significant'") by making disclosure unconditional rather than judgment-gated. Unconditional-by-default also matches the honesty argument: if the norm is "AI-assisted is normal and welcome," there's no reason to make the trailer conditional on a magnitude judgment nobody can audit anyway.
- **Keep `Signed-off-by` (DCO) completely separate and human-only**, per the kernel's explicit design and per LFDT's own existing DCO requirement (already documented in this corpus's governance entries) — no source anywhere proposed merging AI disclosure into the DCO trailer, and doing so would blur a legal certification with a metadata note.

## REFINEMENT (Tim, 2026-07-21): provenance as CONTEXT, not DISCRIMINATOR

The right synthesis is not "quality not provenance" (which implies provenance is irrelevant) but a
THREE-LAYER norm:
1. FILTER (hard line) = QUALITY. Unclear / low-effort / sloppy writing -> revise-or-decline,
   AI-assisted or not. Quality is the only disqualifier.
2. CONTEXT (soft, transparent) = PROVENANCE IS DISCLOSED and openly discussed. Comment on it in the
   messaging ("we use AI heavily and openly; be transparent; it does not lower the bar") WITHOUT
   using it as a gate. A reviewer legitimately reads AI-heavy work more alertly (plausible-but-wrong,
   volume-over-substance); acknowledging that as context is honest, hiding it is naive.
3. RATIONALE (the why) = curl's economics: a contribution should be worth more than the time it
   takes to review it. This protects reviewers from AI-volume slop WITHOUT naming AI as the villain.

Tone target: PRO-AI, high-craft, transparent, quality-gated. Distinctly PDP-Connect. This is a more
thoughtful stance than any researched project (all of which use provenance as a discriminator) and
reads as leadership rather than defensiveness. Disclosure via automatable vendor-neutral trailer
(Assisted-by: AI, hook-added, separate from human-only DCO Signed-off-by).
