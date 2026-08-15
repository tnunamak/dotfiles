---
title: "Torvalds's actual commit history splits sharply by repo: on torvalds/linux his own recent commits are almost entirely terse merges and version bumps (the craft reputation does not hold there today), but on his subsurface side project his non-merge commits are genuinely excellent outsider-readable exemplars — full causal chains, named regressions, explicit uncertainty, self-correction"
date: 2026-08-14
topic: writing-craft
tags: [pull-requests, commit-messages, linux-kernel, torvalds, subsurface, reputation, outsider-test, github-api]
status: draft
sources: [linux-search-1000cap, linux-ptrace-dumpable, linux-gitignore-raid6, linux-undefsyms, linux-mismerge-arm64, linux-security-keys-rcu, linux-proc-mem-force-ptrace, subsurface-dive-merge-location, subsurface-sample-times, subsurface-git-parser-quoted-strings, subsurface-xml-parse-huge, subsurface-fit-duration, subsurface-deco-init, subsurface-event-merging, subsurface-cylinder-merging]
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

- Across the 1,000 most recent GitHub-search-indexed commits authored by `torvalds` on `torvalds/linux` (the full result set the GitHub Search API allows; it caps at 1,000 and refuses to page further), only 6 commits were neither a `Merge ...` commit nor a bare `Linux X.Y-rcN` version-bump tag commit. The other ~994 were merges or version bumps. [linux-search-1000cap]
- Of those 6 non-merge, non-version-bump kernel commits, all 6 have a `Signed-off-by: Linus Torvalds` trailer and real prose bodies (not one-liners): `ef0c9f75a195` (raid6 .gitignore), `43a1e3744548` (security/keys RCU fix), `31e62c2ebbfd` (ptrace get_dumpable), `b4e07588e743` (tracing .gitignore), `1f5ffc672165` (arm64/timer-core mismerge fix), `599bbba5a36f` (proc PROC_MEM_FORCE_PTRACE default). [linux-gitignore-raid6] [linux-ptrace-dumpable] [linux-undefsyms] [linux-mismerge-arm64] [linux-security-keys-rcu] [linux-proc-mem-force-ptrace]
- The `31e62c2ebbfd` ptrace commit is a genuine outsider-readable example: it defines the concept in question ("The 'dumpability' of a task is fundamentally about the memory image of the task... makes no sense when you don't have an associated mm"), names the actual reporter and threat context ("Reported-by: Qualys Security Advisory"), and states both the old broken behavior and the exact new rule the fix implements, in full sentences, with no unexplained kernel-internal acronym left undefined except two capability-flag names (`CAP_SYS_PTRACE`, `PTRACE_MODE_READ_FSCREDS`) that are named but not spelled out. [linux-ptrace-dumpable]
- The `1f5ffc672165` "Fix mismerge" commit is a first-person narrative of Torvalds's own reasoning error during a merge: he explains that he initially resolved a merge conflict correctly, then re-did it after looking at how `linux-next` had resolved the same conflict "because it looked cleverer," and states plainly that this was a mistake ("it turns out nobody apparently tests linux-next, and the merge in linux-next was just wrong") before describing the causal chain of what broke (`hrtimer_rearm_deferred()` no longer being called) and undoing his own change. [linux-mismerge-arm64]
- On `subsurface/subsurface`, the GitHub Search API returned 1,011 total commits authored by `torvalds`; of the first 100 (most recent, reverse-chronological), the large majority are single-purpose non-merge fix/feature commits with multi-paragraph explanatory bodies, in contrast to the kernel sample. [subsurface-dive-merge-location]
- `da6c75350215` ("Fix sample times in dive merging") names the exact commit that caused the regression (`c27314d60`, "core: replace add_sample() by append_sample()"), states the observable symptom in plain language ("The end result was a completely broken profile"), explains not just what the fix does but why a naive version of the fix would be wrong ("It also takes the offset not from the difference in time of the two dives, but the difference in time of the dive computers... we're not mixing up different times from different sources that aren't necessarily in sync"), and explicitly discloses a known remaining bug out of scope: "The dive merging still messes up the dive location. That's some other bug." [subsurface-sample-times]
- `05e1294be9f4` ("git parser: handle left-over multi-line quoted strings better") is a ~500-word commit body that first explains the design philosophy of the file format being parsed ("The git save format is designed to be entirely line-based... That is very much by design, so that you can merge these files automatically"), then walks through a concrete worked example with literal sample input/output text showing exactly how a merge conflict corrupts a multi-line quoted field, then states the fix, then proposes and explicitly defers an alternative, more thorough fix ("We could try to improve on this by instead noticing... But that would be an independent thing anyway... So do this more important fix first."). [subsurface-git-parser-quoted-strings]
- `a0a631122ab3` ("xml parsing: add XML_PARSE_HUGE flag to xmlReadMemory()") includes an explicit statement of the limits of Torvalds's own understanding of the fix: "I don't know libxml2 internals, so I have no idea what exactly goes wrong, but the docs say... XML_PARSE_HUGE = 524288 : relax any hardcoded limit from the parser, and that makes us successfully parse the Greek file from Kostas." It also quotes the literal reproducing error text and names the reporter. [subsurface-xml-parse-huge]
- `aa3a93a46698` ("Fix location in result of dive merging") quotes a fellow maintainer's code-review assessment verbatim inside the commit body ("Berthold says that the whole site handling may be broken: 'From a quick glance, the code in dive_table::merge_dives looks fundamentally broken...'") and explicitly scopes the fix as narrower than the full known problem: "this at least fixes the resulting location in the dive itsels [sic]." [subsurface-dive-merge-location]
- `914cdb102ba5` ("Fix Suunto FIT file import dive duration mis-calculation") explains a quantified, causal failure mode in plain language ("the dive duration ends up being completely nonsensical (generally roughly by a factor of five...)") and states the root cause, the fix, and a scoped-out follow-up cleanup ("The FIT file parser should probably be taught to not even bother sending empty samples... but that's a separate cleanup. This fixes the actual bad behavior."). [subsurface-fit-duration]
- `a2028cd6ef4a` ("deco: _really_ make sure the deco state is fully initialized") is a self-correction commit: "I incorrectly thought that 'ci_pointing_to_guiding_tissue' was the only missing initialization, because that is the only one valgrind pointed at. ... that is, until I started looking at a few more dives, which showed that there were other parts tht [sic] weren't initialized either." [subsurface-deco-init]
- `77a11400a1ae` ("Fix event merging when merging dives") identifies two distinct bugs in the same function, attributes the first bug to a specific prior commit by SHA and message, explains the mechanism of the regression (a pointer-movement optimization in the old code that the new code's author didn't realize was doing double duty), and closes with an honest assessment of the pre-existing code quality: "In all fairness, the new code did get the time offset right, which the old code didn't. So this was always buggy." [subsurface-event-merging]
- `628c7c8f13d6` ("Fix dive merging with multiple cylinders") opens with blunt self/predecessor-critical language rather than neutral engineering prose: "We did something really horribly wrong when merging cylinders," names the commit that introduced the bug, and states the fix's goal in plain terms: "This rewrites the logic to be (I think) a bit more easy to understand." [subsurface-cylinder-merging]
- Several subsurface commits in the same 100-commit sample are short and low-context by comparison — e.g. `47b0a9ce65e1` ("Don't share dive computer data allocations") gives only one sentence of justification ("it just causes problems later when we free them, since we don't do any reference counting") with no description of the observed symptom, and `3446dd512597` gives a single dependency-ordering sentence with no symptom or root-cause narrative at all. Not every Torvalds subsurface commit clears the outsider bar; the excellent ones are a genuine subset, not the median. [subsurface-fit-duration]

## SOURCES

**linux-search-1000cap**
URL: https://api.github.com/search/commits?q=repo:torvalds/linux+author:torvalds&sort=author-date&order=desc
Accessed: 2026-08-14
Quote: GitHub API response at page 11: `{"message":"Only the first 1000 search results are available","documentation_url":"https://docs.github.com/v3/search/","status":"422"}`. `total_count` reported as 29,650 but only 1,000 are retrievable; of the retrievable 1,000, non-merge/non-version-bump commits found: 6.

**linux-ptrace-dumpable**
URL: https://github.com/torvalds/linux/commit/31e62c2ebbfd
Accessed: 2026-08-14
Quote: "The 'dumpability' of a task is fundamentally about the memory image of the task - the concept comes from whether it can core dump or not - and makes no sense when you don't have an associated mm... Reported-by: Qualys Security Advisory <qsa@qualys.com>"

**linux-gitignore-raid6**
URL: https://github.com/torvalds/linux/commit/ef0c9f75a195
Accessed: 2026-08-14
Quote: "I keep having to do this, because people think they can just move directories around and move the gitignore files around with them. You really can't do that - the old generated files stay around for others, and still need to be ignored in the old location."

**linux-undefsyms**
URL: https://github.com/torvalds/linux/commit/b4e07588e743
Accessed: 2026-08-14
Quote: "Honestly, it *should* have been just a real honest-to-goodness regular file in git, instead of having strange code to generate it in the Makefile, but that is not how that silly thing works. So now we need to ignore it explicitly."

**linux-mismerge-arm64**
URL: https://github.com/torvalds/linux/commit/1f5ffc672165
Accessed: 2026-08-14
Quote: "But it turns out nobody apparently tests linux-next, and the merge in linux-next was just wrong... So this undoes the 'clever' merge, and does the straightforward one instead."

**linux-security-keys-rcu**
URL: https://github.com/torvalds/linux/commit/43a1e3744548
Accessed: 2026-08-14
Quote: "The regular key handling doesn't see this because holding the keyring semaphore hides any lifetime issues, but the persistent key handling uses a different model. Instead of extending the keyring locking, just do the simple RCU locking that the assoc_array was designed for."

**linux-proc-mem-force-ptrace**
URL: https://github.com/torvalds/linux/commit/599bbba5a36f
Accessed: 2026-08-14
Quote: "I'd love to get rid of FOLL_FORCE entirely... but sadly that is likely not a realistic option... at least let's make it more obvious that you have the choice to limit it."

**subsurface-dive-merge-location**
URL: https://github.com/subsurface/subsurface/commit/aa3a93a46698
Accessed: 2026-08-14
Quote: "Berthold says that the whole site handling may be broken: 'From a quick glance, the code in dive_table::merge_dives looks fundamentally broken, because it may overwrite site->location outside of the undo system. I.e. this will not be undone.'"

**subsurface-sample-times**
URL: https://github.com/subsurface/subsurface/commit/da6c75350215
Accessed: 2026-08-14
Quote: "Commit c27314d60 ('core: replace add_sample() by append_sample()') broke the dive computer interleaving when merging two dives... The end result was a completely broken profile... The dive merging still messes up the dive location. That's some other bug."

**subsurface-git-parser-quoted-strings**
URL: https://github.com/subsurface/subsurface/commit/05e1294be9f4
Accessed: 2026-08-14
Quote: "The git save format is designed to be entirely line-based, where all the dive data is on individual lines that are independent. That is very much by design, so that you can merge these files automatically..."

**subsurface-xml-parse-huge**
URL: https://github.com/subsurface/subsurface/commit/a0a631122ab3
Accessed: 2026-08-14
Quote: "I don't know libxml2 internals, so I have no idea what exactly goes wrong, but the docs say: XML_PARSE_HUGE = 524288 : relax any hardcoded limit from the parser, and that makes us successfully parse the Greek file from Kostas."

**subsurface-fit-duration**
URL: https://github.com/subsurface/subsurface/commit/914cdb102ba5
Accessed: 2026-08-14
Quote: "That doesn't end up being a problem for subsurface, _except_ that it really confuses our 'dc_fixup_duration()' logic, and the dive duration ends up being completely nonsensical (generally roughly by a factor of five...)"

**subsurface-deco-init**
URL: https://github.com/subsurface/subsurface/commit/a2028cd6ef4a
Accessed: 2026-08-14
Quote: "I incorrectly thought that 'ci_pointing_to_guiding_tissue' was the only missing initialization, because that is the only one valgrind pointed at. ... that is, until I started looking at a few more dives..."

**subsurface-event-merging**
URL: https://github.com/subsurface/subsurface/commit/77a11400a1ae
Accessed: 2026-08-14
Quote: "In all fairness, the new code did get the time offset right, which the old code didn't. So this was always buggy."

**subsurface-cylinder-merging**
URL: https://github.com/subsurface/subsurface/commit/628c7c8f13d6
Accessed: 2026-08-14
Quote: "We did something really horribly wrong when merging cylinders. It's been broken since commit 7c9f46a ('Core: remove MAX_CYLINDERS restriction'), and used some really strange logic. This rewrites the logic to be (I think) a bit more easy to understand."

## SYNTHESIS

The honest verdict: **the reputation is real but repo-conditional, and the prior corpus entry's "read Torvalds's subsurface commits" recommendation was more precisely correct than "read Torvalds's kernel commits" would have been.**

On `torvalds/linux` today, Torvalds's own authored commits are almost entirely merge commits and version-bump tags — of the full 1,000-commit sample the GitHub Search API will return (the API caps there; true total is ~29,650, so this is a ~3% haircut, not a full census, but 1,000 recent commits is a large and representative window), only 6 were substantive non-merge, non-tag work. That's mechanically expected — he's been primarily an integrator, not a line-level contributor, for a long time — but it means "go read Torvalds's kernel commits for craft" mostly means reading his *merge* commit messages (which is its own genre, and which the 2024 HN thread ["Linus Torvalds Asks Kernel Developers to Write Better Git Merge Commit Messages"] suggests he cares about a lot, but which this task didn't scope me to evaluate). The 6 non-merge commits that do exist are genuinely good by the outsider test — especially `31e62c2ebbfd` (ptrace) and `1f5ffc672165` (the mismerge self-correction) — so the craft is still visibly present when he does write a real fix commit; it's just rare in the modern kernel corpus.

On `subsurface/subsurface`, the reputation holds up strongly and is not folklore. This is exactly the side project the original HN thread flagged as worth reading independent of kernel context, and the sample bears that out: these commits consistently name the regressing commit by SHA and message, state the observed symptom in plain non-jargon language a non-diving-software-engineer can follow, explain not just the fix but why a simpler/wrong fix would fail, and — most distinctively — show intellectual honesty that most engineering commit messages don't: explicit "I don't know why this works, but the docs say..." (`a0a631122ab3`), explicit self-correction of an earlier wrong diagnosis (`a2028cd6ef4a`), explicit "I got this wrong last time" narration of his own merge-conflict-resolution mistake (`1f5ffc672165`, on the kernel side, is the same pattern), and explicit scoping of what the commit does NOT fix (`da6c75350215`, `aa3a93a46698`, `914cdb102ba5` all do this). That combination — causal narrative + honest uncertainty + explicit scope boundary — is the actual transferable craft pattern, more specific and more teachable than "write descriptive commit messages."

Caveat against over-claiming, in the spirit of the antirez entry's honesty discipline: not every subsurface commit clears the bar. `47b0a9ce65e1` and `3446dd512597` are one-line justifications with no symptom description — closer to the median terse commit than to the exemplars. The excellent commits are a real, identifiable subset (roughly a third to half of the sample read in full), not "everything he writes." An agent should be pointed at the *pattern* these specific commits exhibit, not told "write like Torvalds" as if his median commit were the bar.

**Recommendation for teaching material — best commits to quote verbatim, ranked:**
1. `da6c75350215` (subsurface) — best all-around: names the regressing commit, states the symptom plainly, explains why the fix's specific approach (device-clock offset, not wall-clock) matters, discloses a known remaining bug. Short enough to quote in full.
2. `05e1294be9f4` (subsurface) — best for teaching *why explain the system, not just the bug*: opens by explaining the file format's design intent before getting to the parser bug. Longer, but the clearest "explain the mental model, then the defect" structure in the sample.
3. `31e62c2ebbfd` (kernel) — best kernel example, and useful precisely because it shows the same craft survives at institutional scale with a real CVE-adjacent security reporter in the loop.
4. `a0a631122ab3` (subsurface) — best example of honest-uncertainty commit writing ("I don't know libxml2 internals... but the docs say"), a pattern most style guides don't teach and most engineers are embarrassed to write.
5. `1f5ffc672165` (kernel) — best example of a commit that documents the author's own reasoning mistake mid-process, which is rare and valuable as a model for "the fix undoes something I did, and here's why I was wrong."
6. `aa3a93a46698` (subsurface) — good short example of scoping a fix narrowly and citing a colleague's review verbatim instead of paraphrasing it.
