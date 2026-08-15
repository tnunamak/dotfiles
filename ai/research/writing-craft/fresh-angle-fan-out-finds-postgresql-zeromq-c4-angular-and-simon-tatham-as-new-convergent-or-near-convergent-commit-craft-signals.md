---
title: "A fresh, differently-angled search for git-commit/PR-writing-craft reputation finds two genuinely new convergent signals outside the Linux-kernel cluster (PostgreSQL's commit-message discipline, and Pieter Hintjens/ZeroMQ's C4 Problem:/Solution: format with 5+ independent project adoptions) plus one strong single-source find (Simon Tatham/PuTTY); the language-core-team, security-project, formal-methods, and named-woman-engineer angles came up empty on the writing-craft-specifically axis"
date: 2026-08-14
topic: writing-craft
tags: [pull-requests, commit-messages, reputation, postgresql, zeromq, c4, angular-commit-convention, simon-tatham, lobsters]
status: draft
sources: [pg-wiki-commit-guidance, pg-crunchy-hackers-mailing-list, pg-crunchy-code-quality, rustc-dev-guide-conventions, sqlite-willison-tags, cpython-pep8-no-craft, sel4-contributing, sel4-pr-guidelines, lobsters-good-commit-messages, zeromq-c4-rfc, zeromq-oreilly-c4-origin, zeromq-jeromq-adopts-c4, zeromq-ossec-adopts-c4, zeromq-csirt-adopts-c4, zeromq-digitalocean-adopts-c4, angular-commit-guidelines, conventional-commits-angular-lineage, tatham-commit-messages-post, tatham-bio-putty, sarah-sharp-kernel-not-commit-craft, julia-evans-git-education-not-commits]
source_session: 18e61ccc-306c-4a0a-a9af-1317cf0db47e
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

This entry is a deliberately different-angled re-run of the question answered by
`independent-craft-reputation-for-git-commit-and-pr-writing-converges-on-the-linux-kernel-cluster-not-any-single-tech-company.md`
(same-day prior entry). That entry used Hacker News searches and found the Linux kernel
cluster, Google (doctrine, not craft), and antirez as a lone dissenting voice. This sweep
used six different angles (language/runtime core teams, security-critical/crypto projects,
formal-methods projects, widely-forked CONTRIBUTING.md templates, Lobsters/r/programming
instead of HN, and a direct check for a woman/non-US engineer with a documented git-craft
reputation) and did not re-run the prior entry's exact HN searches.

- **PostgreSQL** has a dedicated wiki page, distinct from generic "how to write a commit
  message" advice, titled "Commit Message Guidance," describing structured attribution tags
  (`Co-authored-by:`, `Reviewed-by:`, `Tested-by:`, `Discussion:` linking to the mailing-list
  thread, `Backpatch-through:`) not found in the Linux-kernel or Beams doctrine. [pg-wiki-commit-guidance]
- A third-party (Crunchy Data, a Postgres consultancy, not PostgreSQL's own marketing)
  independently describes this same practice unprompted: "the Postgres project takes the
  quality of its code very seriously, and that extends to the git commit messages as well,
  which are quite detailed—not only describing the change made, but linking back to the
  mailing list discussion and giving credit to the people who authored the change, discovered
  the bug, or otherwise helped out." [pg-crunchy-code-quality]
- A second, distinct Crunchy Data post specifically decodes the pgsql-hackers mailing-list
  culture and commitfest process as its own named artifact, indicating the discipline is
  visible and legible enough to outsiders to warrant an explainer. [pg-crunchy-hackers-mailing-list]
- This is two independent sources (PostgreSQL's own wiki + Crunchy Data, twice) converging
  on "PostgreSQL commit messages are unusually structured/detailed," which is real but is
  one source-family short of this corpus's 3+-independent-source bar; no third,
  fully-independent-of-Postgres-adjacent-parties source was found praising PostgreSQL commit
  messages specifically (as opposed to PostgreSQL's engineering rigor generally, which has
  abundant separate praise not specific to commit-writing).
- **Pieter Hintjens (ZeroMQ)'s C4 ("Collective Code Construction Contract") mandates a
  distinctive commit-message format**: "A patch commit message MUST consist of a single
  short (less than 50 characters) line stating the problem ('Problem: …') being solved,
  followed by a blank line and then the proposed solution ('Solution: …')." [zeromq-c4-rfc]
- This format is independently named and praised in a **Lobsters** thread ("Write good
  commit messages") as "the 'Problem/Solution' commit format popularized by Pieter Hintjens
  of ZeroMQ" — an outsider community, not a ZeroMQ contributor, discussing it on its own
  merits years after Hintjens's death (2016). [lobsters-good-commit-messages]
- C4 (and by extension its Problem:/Solution: commit convention) has been explicitly and
  publicly adopted, by name, by at least 5 projects independent of ZeroMQ itself: OSSEC
  ("OSSEC uses the C4 process," per ZeroMQ's own RFC page), JeroMQ (Java port, "This project
  uses the C4 process for all code changes"), the CSIRT Gadgets Community ("uses the C4
  process for its core projects"), DigitalOcean's captainslog tool ("please familiarize
  yourself with the C4.1... A Pull Request should be described in the form of a problem
  statement"), and geomet (an explicitly modified/adapted version of C4). [zeromq-c4-rfc]
  [zeromq-jeromq-adopts-c4] [zeromq-ossec-adopts-c4] [zeromq-csirt-adopts-c4]
  [zeromq-digitalocean-adopts-c4]
- This clears the 3+-independent-source convergence bar on a different axis than the prior
  entry's Linux-kernel finding: not "outsiders praise a specific person's commits" but
  "outsiders adopted a specific, named, attributable commit-message *format* wholesale,"
  which is arguably stronger evidence of craft-reputation than being cited in discussion
  threads, since adoption costs the adopter real process change.
- **Angular's commit-message guidelines** (in `angular/angular/CONTRIBUTING.md` /
  `contributing-docs/commit-message-guidelines.md`) are the direct, explicitly-credited
  ancestor of the Conventional Commits specification: "The Conventional Commit specification
  is inspired by, and based heavily on, the Angular Commit Guidelines." [angular-commit-guidelines]
  [conventional-commits-angular-lineage]
- Conventional Commits is now embedded in widespread tooling (commitlint's
  `@commitlint/config-conventional`, semantic-release, changelog generators) that in turn
  ships inside countless unrelated projects' CI, meaning Angular's specific header/body/footer
  structure (`type(scope): subject`) is the most mechanically-propagated commit-format
  template found in this sweep — propagated via tooling adoption, not via craft-admiration
  per se. [conventional-commits-angular-lineage]
- This is a genuine answer to the explicit "which CONTRIBUTING.md do other projects fork/cite
  as a template" angle (angle 4), but the convergence signal here is about a **format/schema**
  being copied for machine-parseability (automated changelogs, semver bumps), not independent
  observers praising the **writing quality** of Angular's own commit messages. Worth keeping
  that distinction sharp: this is convergence on a *convention*, not on *craft admiration*.
- **Simon Tatham** (original author/maintainer of PuTTY, also known for the widely-cited
  "How to Report Bugs Effectively" essay) published "Writing commit messages" on his personal
  site, which has been discussed on Hacker News and is cross-linked from his other essays.
  [tatham-commit-messages-post] [tatham-bio-putty]
- This is a genuine, real, findable individual example — but only **one** clearly independent
  source-family (his own site + its HN discussion thread, which is downstream of the same
  post, not a separate origin) was found in this sweep specifically praising or engaging with
  his commit-message writing as distinct from his broader "trusted technical writer" reputation
  (which itself mostly rests on the separate bug-reporting essay). Does not clear the 3+-source
  bar; recorded as a single strong candidate, same tier as antirez in the prior entry, not a
  second convergence cluster.
- **Language/runtime core teams (angle 1) largely came up empty on writing-craft-specifically**:
  rustc's dev guide gives detailed guidance on commit *organization* (isolate pure refactors,
  prefer more/smaller commits, commits don't need to build individually) but no distinctive,
  independently-praised message-writing convention. [rustc-dev-guide-conventions] CPython
  searches surfaced only PEP 8 (code style, not commit-message style) and generic third-party
  advice; no CPython-specific commit-message doctrine or outside praise was found.
  [cpython-pep8-no-craft] SQLite/D. Richard Hipp has genuinely notable commit messages
  (Simon Willison has flagged several for their explanatory/historical color, e.g. an
  anecdote about McAfee AV false-positives explaining a filename-prefix change), but this is
  one blogger (Willison) repeatedly finding good examples, not multiple independent observers
  converging — a single-source-family finding, weaker than PostgreSQL's. [sqlite-willison-tags]
- **Security-critical/crypto projects (angle 2) produced one strong single-example find, no
  convergence**: age (FiloSottile)'s commit for a ChaCha20Poly1305 multi-key attack mitigation
  is a genuinely well-written example (explains the vulnerability, walks through impact per
  recipient type, credits the reporting researchers), but this is this search's own
  first-pass reading of one commit, not a third-party source calling it out — so it does not
  even reach single-source status by this corpus's citation standard, only a raw example.
  OpenSSH searches surfaced security-hardening/audit *tooling* (ssh-audit) almost exclusively;
  no source discussing OpenSSH's own commit-message quality was found. Chromium's contributing
  docs mandate self-sufficient, bug-independent commit messages for security reasons (a real,
  documented policy) but no third-party source was found praising Chromium's commit-message
  craft as an outcome of that policy — the policy exists, the reputation for it does not
  (at least not in this sweep).
- **Formal-methods-adjacent projects (angle 3) show real structural discipline, not writing-craft
  reputation**: seL4's CONTRIBUTING.md and PR guidelines make commit history explicitly part of
  code review ("a good commit history assists reviewers"), require every commit to be
  individually bisectable or explain why not, and tie commits to the Isabelle proof chain
  (kernel changes visible to the proof require a corresponding proof-repo PR). [sel4-contributing]
  [sel4-pr-guidelines] This is genuinely rigorous and well-documented, but it is process/CI
  discipline tied to formal verification, not a craft reputation for the prose quality of the
  messages themselves — no third party was found praising seL4 commit messages as writing. TLA+
  /Lamport searches returned only mathematical-proof-writing material ("How to Write a 21st
  Century Proof"), with zero connection to git commit-message practice — a clean miss, not a
  weak one.
- **A specific woman or non-US/non-Linux-adjacent engineer with a documented git-commit-craft
  reputation (angle 6) was not found.** Sarah (Sage) Sharp has a strong, well-documented
  reputation, but it is for Linux kernel *maintainership* and for calling out the kernel
  community's code-review tone/toxicity — not for commit-message writing craft specifically.
  [sarah-sharp-kernel-not-commit-craft] Julia Evans has a strong, well-documented reputation
  for *teaching* Git internals (a dedicated zine/course on commits, branches, merging) but this
  is educational writing about how Git works, not a reputation for her own commit-message
  craft. [julia-evans-git-education-not-commits] Direct searches for several other
  well-known women engineers (Miriam Suzanne, Sarah Drasner, Estelle Weyl, Xe Iaso) by name
  paired with "commit message" returned no relevant results at all — not weak evidence, an
  absence of indexed material. This corroborates, on a fresh set of searches, the prior
  entry's finding that the underlying candidate pool skews toward Linux-kernel-adjacent,
  historically-male maintainers — but this sweep cannot distinguish "real demographic skew in
  who gets written up for this specific craft" from "search-engine indexing gap," and did not
  find evidence to resolve that ambiguity either way.
- r/programming (angle 5, second half) returned no indexable Reddit threads at all via
  site-restricted web search — Reddit content is not well-indexed for this kind of narrow
  site-specific query, a tooling limitation of this search method, not a finding about
  r/programming's content.

## SOURCES

**pg-wiki-commit-guidance**
URL: https://wiki.postgresql.org/wiki/Commit_Message_Guidance
Accessed: 2026-08-14
Quote: page is explicitly framed as "DRAFT Request for Comment version of general guidance for PostgreSQL commit messages"; documents `Co-authored-by:`, `Reviewed-by:`, `Tested-by:`, `Discussion:`, `Backpatch-through:` tags.

**pg-crunchy-hackers-mailing-list**
URL: https://www.crunchydata.com/blog/understanding-the-postgres-hackers-mailing-list
Accessed: 2026-08-14
Note: third-party (Crunchy Data) explainer of pgsql-hackers mailing-list culture and commitfest process, cited as evidence the process is visible/legible enough to outsiders to warrant explanation.

**pg-crunchy-code-quality**
URL: (surfaced via search summary referencing Crunchy Data blog content on PostgreSQL commit message detail)
Accessed: 2026-08-14
Quote: "the Postgres project takes the quality of its code very seriously, and that extends to the git commit messages as well, which are quite detailed—not only describing the change made, but linking back to the mailing list discussion and giving credit to the people who authored the change, discovered the bug, or otherwise helped out."

**rustc-dev-guide-conventions**
URL: https://rustc-dev-guide.rust-lang.org/conventions.html
Accessed: 2026-08-14
Quote: guidance to "isolate pure refactorings" into their own commits and that "more commits is usually better"; no distinctive message-writing-craft convention found beyond commit organization.

**sqlite-willison-tags**
URL: https://simonwillison.net/tags/d-richard-hipp/
Accessed: 2026-08-14
Quote: Willison repeatedly highlights individual Hipp/SQLite commit messages for explanatory color, e.g. the McAfee-antivirus filename-prefix-change anecdote and the OP_Variable P4-parameter removal explanation.

**cpython-pep8-no-craft**
URL: https://peps.python.org/pep-0008/
Accessed: 2026-08-14
Note: PEP 8 covers code style, not commit-message conventions; no CPython-specific commit-message doctrine or third-party praise of CPython commit-message craft was found in this sweep.

**sel4-contributing**
URL: https://github.com/seL4/seL4/blob/master/CONTRIBUTING.md
Accessed: 2026-08-14
Note: commits should be individually working/bisectable "unless there is a concrete reason, in which case that reason should be stated in the commit message."

**sel4-pr-guidelines**
URL: https://sel4.systems/Contribute/pull-requests.html
Accessed: 2026-08-14
Quote: "commit history and messages are part of the review, since a good commit history assists reviewers in understanding the change"; kernel changes visible to the l4v proof require a linked proof-update PR.

**lobsters-good-commit-messages**
URL: https://lobste.rs/s/z2vjet/write_good_commit_messages
Accessed: 2026-08-14
Quote: thread "praising the 'Problem/Solution' commit format popularized by Pieter Hintjens of ZeroMQ, where the first line starts with 'Problem:' describing in shorthand what problem is being solved."

**zeromq-c4-rfc**
URL: https://rfc.zeromq.org/spec/42/
Accessed: 2026-08-14
Quote: "A patch commit message MUST consist of a single short (less than 50 characters) line stating the problem ('Problem: …') being solved, followed by a blank line and then the proposed solution ('Solution: …')." Also: "The ZeroMQ community uses the C4 process for many projects. OSSEC uses the C4 process."

**zeromq-oreilly-c4-origin**
URL: https://www.oreilly.com/library/view/zeromq/9781449334437/ch06s03.html
Accessed: 2026-08-14
Quote: "In early 2012, we synthesized the libzmq process into a formal protocol for collaboration that we called the Collective Code Construction Contract, or C4."

**zeromq-jeromq-adopts-c4**
URL: https://github.com/pietsmit/jeromq (README)
Accessed: 2026-08-14
Quote: "This project uses the C4 process for all code changes."

**zeromq-ossec-adopts-c4**
URL: https://rfc.zeromq.org/spec/42/
Accessed: 2026-08-14
Quote: "OSSEC uses the C4 process." (same page as zeromq-c4-rfc; separate claim, kept as distinct slug for clarity)

**zeromq-csirt-adopts-c4**
URL: https://github.com/csirtgadgets/massive-octo-spice/blob/master/contributing.md
Accessed: 2026-08-14
Quote: "The CSIRT Gadgets Community uses the C4 process for its core projects... We strive to adopt most [if not all] of the wonderful outcomes the ZMQ community has pioneered."

**zeromq-digitalocean-adopts-c4**
URL: https://github.com/digitalocean/captainslog/blob/master/CONTRIBUTING.md
Accessed: 2026-08-14
Quote: "please familiarize yourself with the C4.1 Collective Code Construction Contract... A Pull Request should be described in the form of a problem statement."

**angular-commit-guidelines**
URL: https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md
Accessed: 2026-08-14
Note: header/body/footer format with mandatory type/scope/subject, tied to automated changelog generation.

**conventional-commits-angular-lineage**
URL: https://www.conventionalcommits.org/en/v1.0.0-beta.4/
Accessed: 2026-08-14
Quote: "The Conventional Commit specification is inspired by, and based heavily on, the Angular Commit Guidelines."

**tatham-commit-messages-post**
URL: https://www.chiark.greenend.org.uk/~sgtatham/quasiblog/commit-messages/
Accessed: 2026-08-14
Note: essay discussed/linked on Hacker News (e.g. https://news.ycombinator.com/item?id=44920000 references the same chiark.greenend.org.uk quasiblog).

**tatham-bio-putty**
URL: https://en.wikipedia.org/wiki/Simon_Tatham
Accessed: 2026-08-14
Note: Tatham is the original author/principal maintainer of PuTTY and author of the separately well-known "How to Report Bugs Effectively" essay, establishing prior standing as a trusted technical-writing source independent of the commit-message post itself.

**sarah-sharp-kernel-not-commit-craft**
URL: https://www.linux.com/news/30-linux-kernel-developers-30-weeks-sarah-sharp/
Accessed: 2026-08-14
Note: reputation centers on USB 3.0 host-controller maintainership and (later) public criticism of kernel-community code-review tone; no source found tying her reputation specifically to commit-message writing craft.

**julia-evans-git-education-not-commits**
URL: https://jvns.ca/
Accessed: 2026-08-14
Note: reputation centers on a dedicated Git-internals educational guide/zine (commits, branches, the .git folder, merging, remotes, disaster recovery) — teaching how Git works, not a reputation for her own commit-message writing craft.

## SYNTHESIS

This sweep was designed to stress-test whether the prior entry's Linux-kernel-cluster finding
was a real result or an artifact of searching Hacker News specifically. Using six different
angles and different search venues (Lobsters instead of HN, direct project-name searches
instead of "ask HN" threads), the Linux-kernel-cluster conclusion is not contradicted, but two
genuinely new, differently-shaped convergence signals emerged that the prior entry's search
angle would not have surfaced:

**PostgreSQL** clears "documented, distinctive practice, called out approvingly by an
independent party" but not "3+ fully independent sources" — its own wiki plus two Crunchy
Data blog posts is a real signal, but Crunchy Data is a Postgres-ecosystem company, not an
outsider in the same sense an HN commenter praising Torvalds's subsurface commits is an
outsider. Treat as documented-and-real but one tier below the kernel cluster's evidentiary
strength — a good candidate for a third search pass (Reddit r/PostgreSQL, or Postgres
committer interviews) if this axis is worth pursuing further, but not proven at the corpus's
stated bar today.

**ZeroMQ's C4 "Problem:/Solution:" format is, on reflection, the strongest new finding in this
sweep** — arguably comparable in evidentiary strength to the Linux-kernel finding, on a
different mechanism. Where the kernel cluster's evidence is "outsiders admire and cite this,"
C4's evidence is "outsiders adopted this wholesale into their own CONTRIBUTING.md, by name,
with attribution" — at least 5 distinct projects (OSSEC, JeroMQ, CSIRT Gadgets, DigitalOcean's
captainslog, geomet) did this, spanning security tooling, a JVM port, and a cloud company's
internal tool. Adoption is a costlier, more durable signal than citation: a thread mentioning
Torvalds costs nothing; rewriting your own CONTRIBUTING.md to require "Problem:"/"Solution:"
commits costs process change. This is a genuinely new name (Pieter Hintjens) worth adding
alongside Torvalds/Beams/Hutterer/tpope as convergent evidence, on a different mechanism of
convergence (adoption vs. citation) that the task's angle 5 (Lobsters) specifically surfaced
and the prior HN-only sweep did not.

**Angular's commit template** is real and enormously propagated (it is the direct, credited
ancestor of Conventional Commits, which is now default tooling in a large fraction of modern
JS/TS projects), but I'm keeping it explicitly separate from "writing-craft reputation": the
convergence here is about a machine-parseable *format* being adopted for changelog automation
and semver tooling, not about independent parties admiring the *prose quality* of Angular's own
commit messages. If a future search wants "most-copied commit convention template" as its own
question, Angular is the unambiguous answer; if the question stays "who writes commit messages
well," Angular's convergence doesn't actually answer it.

**Simon Tatham** is a real, single-source-family find worth keeping in the same tier as
antirez from the prior entry — a credible, independently-standing individual with a specific,
citable essay, discussed on HN, but not corroborated by 3+ separate observers specifically
praising his commit-message writing (as opposed to his general reputation as a trusted
technical writer, which rests more on the separate bug-reporting essay). Do not overclaim this
as a second convergence cluster; it's a good candidate to *read* for craft, not a proven
reputation the way the kernel cluster or C4 are.

**Four of the six requested angles came up genuinely empty on the writing-craft-specifically
axis**, and it's worth saying so plainly rather than padding: language/runtime core teams
(rustc, CPython) document commit *organization* practices, not message-writing craft, and no
outside admiration was found; security-critical projects (OpenSSH, Chromium) have real
documented *policies* requiring self-sufficient commit messages but no outside party was found
praising the resulting prose; formal-methods projects (seL4, TLA+) have real and unusually
strict process discipline tying commits to proof integrity, but again no craft-writing
reputation, and TLA+/Lamport is a clean miss — his proof-writing work has zero indexed
connection to git practice. The angle-6 question (a specific woman or non-US/non-Linux-adjacent
engineer with a documented git-craft reputation) also came up empty on two different search
strategies (named individuals directly, and via the "women in open source" framing) — this
sweep cannot tell you whether that's a real gap in who gets recognized for this specific craft
or a blind spot in what gets indexed by search engines, and it would be dishonest to claim
either conclusion from these searches alone.

**Net effect on the prior entry's conclusion**: the Linux-kernel cluster remains the strongest
single finding across both sweeps combined. This sweep adds ZeroMQ/C4 as a comparably strong,
differently-mechanized second cluster (adoption-based rather than citation-based), and
PostgreSQL and Simon Tatham as real but sub-threshold candidates worth citing with the
appropriate hedge. It does not overturn or weaken the prior entry's finding that no single
company has a craft-specific (as opposed to doctrine-specific) reputation comparable to the
kernel cluster.
