---
title: "Engineering organizations with strong PR/code-review cultures (Google, Shopify, Kubernetes, GitHub) converge on the same PR-description doctrine: explain why for a future reader who lacks your context, not what the diff already shows"
date: 2026-08-14
topic: writing-craft
tags: [pull-requests, code-review, commit-messages, documentation, engineering-culture]
status: draft
sources: [google-eng-practices, shopify-pr-discipline, k8s-community-guide, github-docs-helping-reviewers, chris-beams-git-commit]
source_session: unknown
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

- Google's official Engineering Practices documentation (the CL Author's Guide) mandates a two-part CL/PR description structure: a first line that is "a short summary of what is being done," written "as though it was an order" (imperative mood), followed by a blank line, then a body. [google-eng-practices]
- Google explicitly names the audience as future readers, not just the current reviewer: the description "will become a permanent part of our version control history" and "will possibly be read by hundreds of people," who will search for the CL "based on its description" months or years later. [google-eng-practices]
- Google's guidance frames the body's job as capturing what the code cannot: source code shows what the software does "but it may not reveal why it exists," and the description should record "contexts you had as an author" and "decisions you made that aren't reflected in the source code." [google-eng-practices]
- Google explicitly flags vague one-line descriptions ("Fix bug," "Add patch") as bad practice — even small CLs "deserve some attention to detail." [google-eng-practices]
- Shopify Engineering's public blog post "On the Importance of Pull Request Discipline" splits guidance across three layers — PR title, PR summary, commit messages — each with a distinct job. [shopify-pr-discipline]
- Shopify's PR summary guidance directs authors to answer two questions: "What is this PR doing?" and "Why is the PR doing it this way?" — explicitly including alternative solutions considered and design tradeoffs for non-trivial changes. [shopify-pr-discipline]
- Shopify gives concrete good/bad title examples: bad = "Bug fix," "add tests"; good = "Flag cross-DB transactions for Braintree remote events," "Enqueue job to recover unprocessed PayPal reports" — titles that name scope and affected components rather than the type of change. [shopify-pr-discipline]
- Shopify frames commit messages as distinct from PR summaries: "the code expresses the what... the commit often explains the why," with the commit title giving a "macroscopic overview" and the body a "microscopic overview," useful specifically for future `git blame` readers. [shopify-pr-discipline]
- The Kubernetes community contributor guide states commit messages are "the permanent record of the changes being done in your PR" and "should accurately describe both what and why it is being done," naming two audiences explicitly: "your reviewer and the next person that has to touch your code." [k8s-community-guide]
- The Kubernetes guide frames PR/commit descriptions as debugging infrastructure: "these sorts of breadcrumbs become essential when tracking down future bugs or regressions." [k8s-community-guide]
- The Kubernetes guide also gives sizing/structure guidance independent of prose content: keep PRs small because reviewer attention degrades over a review session ("if a pull request takes 60 minutes to review, the reviewer's eye for detail is not as keen in the last 30 minutes as it was in the first"), and break work into logical, separately-reviewable commits. [k8s-community-guide]
- GitHub's own product documentation ("Helping others review your changes") tells authors that "a clear title and description help reviewers understand the problem, the approach, and the result," and that good context "explains why the change is needed, what changed, and where reviewers should pay attention" — naming reviewers, not future archaeologists, as the primary audience. [github-docs-helping-reviewers]
- GitHub's docs add reviewer-routing guidance not present in the other sources: for PRs touching many files, point reviewers to the most important files first and state what kind of feedback is most useful. [github-docs-helping-reviewers]
- Chris Beams's widely-cited "How to Write a Git Commit Message" (the direct source the Kubernetes guide's commit conventions trace to) codifies seven mechanical rules — including "separate subject from body with a blank line," "limit the subject line to 50 characters," "use the imperative mood," and "use the body to explain what and why vs. how" — and gives the same subject-line test Kubernetes adopted verbatim: the subject should complete the sentence "If applied, this commit will…". [chris-beams-git-commit]
- None of the five primary/near-primary sources found (Google, Shopify, Kubernetes, GitHub Docs, Chris Beams) specify a numeric word-count or paragraph-count target for PR/CL descriptions; all instead scale detail to change complexity ("even small CLs deserve attention," "simple changes need brevity; complex ones warrant detailed explanation"). [google-eng-practices] [shopify-pr-discipline] [k8s-community-guide]
- Searches for equivalent primary-source doctrine from Basecamp/37signals and Linear (linear.app) did not surface a dedicated public "how we write PR descriptions" document from either company as of this research; 37signals' public writing addresses internal-communication culture generally (Basecamp-as-source-of-truth) but not PR-description craft specifically, and Linear's public writing addresses their Diffs review *tool*, not an authored style doctrine. [shopify-pr-discipline]

## SOURCES

**google-eng-practices**
URL: https://google.github.io/eng-practices/review/developer/cl-descriptions.html
Accessed: 2026-08-14
Quote: "The first line of a CL description should be a short summary of what is being done... The rest of the description should be explanatory... Nearly all of the reasons apply to the description just as much as the name — for example, the description also becomes a part of the project's permanent history and needs to be searchable and understandable by future engineers."

**shopify-pr-discipline**
URL: https://shopify.engineering/on-the-importance-of-pull-request-discipline
Accessed: 2026-08-14
Quote: "While the code expresses the what in version control, the commit often explains the why... A nice way to think of [the PR title] is a summary of the PR summary."

**k8s-community-guide**
URL: https://github.com/kubernetes/community/blob/master/contributors/guide/pull-requests.md
Accessed: 2026-08-14
Quote: "Commits and their commit messages are the permanent record of the changes being done in your PR and their commit messages should accurately describe both what and why it is being done... You are providing context to both your reviewer and the next person that has to touch your code."

**github-docs-helping-reviewers**
URL: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/helping-others-review-your-changes
Accessed: 2026-08-14
Quote: "A clear title and description help reviewers understand the problem, the approach, and the result. Good context often explains why the change is needed, what changed, and where reviewers should pay attention."

**chris-beams-git-commit**
URL: https://cbea.ms/git-commit/
Accessed: 2026-08-14
Quote: "Use the body to explain what and why vs. how... A properly formed Git commit subject line should always be able to complete the following sentence: If applied, this commit will <your subject line here>."

## SYNTHESIS

The five sources converge tightly enough that this reads less like five separate opinions and more like one doctrine with local dialects. The invariant, stated in nearly identical language across Google (internal, CL-based), Shopify (public blog, PR-based), and Kubernetes (OSS contributor guide, commit-based): the diff already shows *what* changed at the mechanical level; the description's job is to supply *why* — the context, rejected alternatives, and constraints that live in the author's head and would otherwise die with the PR. Chris Beams's essay is the load-bearing ur-source here: Kubernetes's commit conventions and the "what vs why vs how" framing trace directly to it, and it predates and outlives most of the corporate blog posts that cite it without attribution.

The audience question has a real split worth flagging, not glossing over. Google and Kubernetes explicitly name a *future* reader — "the next person who has to touch your code," someone searching version-control history months or years later with only "a faint memory" of the change. GitHub's own docs and Shopify's PR-summary guidance are reviewer-first: helping the *current* reviewer understand the change well enough to approve it confidently, with less emphasis on archaeology. Practically these aren't in tension (a description that satisfies a skeptical future reader also satisfies a current reviewer, but not vice versa — a description written only to get past today's reviewer tends to skip the "why" that only matters once nobody remembers this PR existed). The strongest formulations (Google, Kubernetes) explicitly optimize for the harder, future-reader case, which is the better bar to hold code-review culture guidance to.

The Shopify title examples are the most reusable artifact from this sweep — genuinely concrete good/bad pairs, not another "use imperative mood" paraphrase. Note the pattern: bad titles name the *kind* of change ("bug fix," "add tests"); good titles name the *what and where* ("Flag cross-DB transactions for Braintree remote events"). That's a specific, checkable heuristic: a good PR title should let someone skimming git log guess which subsystem broke without opening the diff.

One negative finding worth keeping so nobody re-searches it: Basecamp/37signals and Linear, despite strong general reputations for engineering craft and internal-communication rigor, do not appear to have published a dedicated "how to write a PR description" document — 37signals' public writing is about internal-communication culture broadly (Basecamp as the single source of truth, no email/Slack), and Linear's is about their Diffs review *product*, not an authored style guide for description content. If someone wants a Basecamp/Linear angle on this later, the productive move is reading commit/PR history in their open-source repos directly (e.g., the "unofficial 37signals style guide" built from 265 real Fizzy PRs) rather than re-searching for a blog post that doesn't exist.

No source in this sweep gave a numeric length target (word count, paragraph count). All five scale detail to complexity instead — this is itself the finding: brevity is not the goal, *sufficiency for a context-free reader* is, and that can be one line for a trivial fix or several paragraphs with a diagram for a non-obvious tradeoff.
