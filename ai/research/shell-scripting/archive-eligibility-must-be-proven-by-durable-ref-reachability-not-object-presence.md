---
title: "Archive-eligibility must be proven by durable-ref reachability, not object presence — and a fully-merged branch is the case a naive fork-point guard archives most expensively"
date: 2026-08-29
topic: shell-scripting
tags: [git, bundles, retention, disk-usage, archival, eligibility-gates, waspflow]
status: verified
sources: [waspflow-fanin, git-bundle-docs, git-rev-list-docs, measured-host]
source_session: b9e12532-351b-43c0-a858-171dee902cb9
---

## CLAIMS

- `git bundle create <file> <base>..<tip>` writes only commits in the range; `git bundle create <file> <branch>` writes the branch's entire reachable history, so bundle size is set by the revision expression, not by how much work is unique to the branch [git-bundle-docs]
- A thin bundle can only be restored where its base object already exists; `git bundle verify` checks exactly these prerequisites against the target repo [git-bundle-docs]
- `git merge-base HEAD <branch>` returns the branch tip itself when the branch is fully merged into HEAD, because the tip is then an ancestor of HEAD [git-rev-list-docs]
- Waspflow's archive path guarded thin bundling on `base != tip` and routed every other case to a full-history fallback whose comment scopes it to "an orphan/unrelated branch (no fork point)" [waspflow-fanin]
- That guard conflates two opposite conditions: no fork point (nothing shared) and fully merged (nothing unique). Both take the full-history branch, so the branch with the LEAST unique work produced the LARGEST bundle [waspflow-fanin]
- Measured on one host: 1,525 bundles totalling 14.39 GB; 1,474 bundles (14.21 GB, 98.8% of bytes) had a tip commit already present in a live local repo [measured-host]
- The three largest bundles were 354.5 MB each; one carried 10,104 upstream commits to preserve two lane commits that were a change and its own immediate revert — net-zero content [measured-host]
- Re-bundling one such branch as `base..tip` produced 4 KB against 354.5 MB, a ~90,000x reduction, and the 4 KB bundle restored both commits intact [measured-host]
- Classifying by reachability rather than mere object presence: 266 bundles (4.71 GB) ancestor-of-HEAD, 1,149 (9.24 GB) reachable only from some ref, 59 (0.27 GB) present but unreachable from any ref, 51 (0.18 GB) with no local repo holding the object [measured-host]
- "Present in a repo" is NOT sufficient for deletion: 59 bundles' tips were present as objects but unreachable from any ref, so a `git gc` would drop them and leave the bundle as the only copy [measured-host]
- "Reachable from a ref" is also NOT sufficient: of the 12 largest ref-reachable bundles, 5 were held exclusively by local `waspflow/*` branches with no remote, tag, or main containing them — deleting the branch would make the bundle the only copy [measured-host]
- Durability therefore requires reachability from a ref that outlives local cleanup — `refs/remotes/*`, `refs/tags/*`, or `refs/heads/{main,master}` — not from any ref whatsoever [measured-host]
- Testing durability of the bundle's TIP is still insufficient: of the 6 largest bundles whose tip was durable, 3 had `git rev-list <tip> --not <durable-refs>` return 4 commits each, i.e. commits the bundle carries that live on no durable ref [measured-host]
- A bundle is only fully redundant when `git rev-list <tip> --not <durable-refs>` is EMPTY; a durable tip can sit atop commits that are themselves only on a deletable local branch [measured-host]
- Applying the strict per-commit gate to the full population: 324 bundles (5.31 GB) fully durable and deletable; 295 (5.33 GB) durable-tipped but carrying non-durable commits; 796 (3.31 GB) only-copy risk; 110 (0.44 GB) no local repo [measured-host]
- The tip-level gate would have authorized deleting 10.64 GB; the per-commit gate authorizes 5.31 GB — the weaker gate was wrong about 5.33 GB, exactly half of what it approved [measured-host]

## FALSIFIED ALONG THE WAY

Each of these looked sufficient and was disproven by the next test, in order:

- "98.8% of tips are present in a live repo, so the archive is redundant" — presence ignores reachability; 59 bundles' tips were unreachable from any ref [measured-host]
- "Reachable from a ref is safe" — 5 of the 12 largest ref-reachable bundles were held only by local `waspflow/*` branches [measured-host]
- "A durable tip means a redundant bundle" — 3 of the 6 largest durable-tip bundles still carried 4 non-durable commits each; across the full population this gate over-approved by 5.33 GB, half of its own verdict [measured-host]

## SOURCES

**git-bundle-docs**
URL: https://git-scm.com/docs/git-bundle
Accessed: 2026-08-29
Quote: "git bundle create ... is used to create a bundle file... the bundle will contain all objects needed to reconstruct the given revisions... When a bundle is created with a revision range, the bundle is 'thin' and requires the prerequisite objects to be present in the receiving repository."

**git-rev-list-docs**
URL: https://git-scm.com/docs/git-merge-base
Accessed: 2026-08-29
Quote: "git merge-base finds best common ancestor(s) between two commits... if one commit is an ancestor of the other, the ancestor itself is the merge base."

**waspflow-fanin**
URL: /home/tnunamak/code/waspflow/lib/fanin.sh:219-248
Accessed: 2026-08-29
Quote: "Fall back to a full bundle if we can't resolve a fork point (e.g. an orphan/unrelated branch), so archival is never silently lost." — the guard was `if [[ -n "$base" && "$base" != "$(git rev-parse "$branch")" ]]`, whose else-branch also catches the fully-merged case.

**measured-host**
URL: /home/tnunamak/.local/state/waspflow/archive (1,525 bundles, classified 2026-08-29)
Accessed: 2026-08-29
Quote: "total: 1525 bundles, 14.39 GB — ANCESTOR-OF-HEAD 266 / 4.71 GB; ON-A-REF 1149 / 9.24 GB; PRESENT-UNREACHABLE 59 / 0.27 GB; no-repo 51 / 0.18 GB." Largest ON-A-REF sample showed `durable=0/2`, `durable=0/1`, `durable=0/2` — refs held only by local `waspflow/*` branches.

## SYNTHESIS

The reusable lesson is about eligibility gates, not about git.

A cleanup gate has to answer "is there another copy that will still exist after the cleanup I am about to do?" It is tempting to answer with the cheapest available test — does the object exist somewhere? — because that test is fast and almost always true. On this host it was true for 98.8% of bytes. But it is the wrong question twice over. An object can be present yet unreachable, so the next `git gc` collects it. A ref can hold it yet be deleted, so branch cleanup collects it. Each weaker test looks like the strong one right up until the moment the other cleanup runs, which is precisely when you need the archive.

Ordering the tests by strength — object present, reachable from any ref, tip reachable from a durable ref, *every carried commit* reachable from a durable ref — the population shrinks at each step, and only the last supports deletion. Skipping to the easy test would have classified 9.24 GB as redundant when a measurable fraction of it was the only copy. Each strengthening cost one more pass over data already gathered.

The instructive part is that four successive gates each looked sufficient. Presence is nearly always true; ref-reachability sounds like the definition of safe; a durable tip feels conclusive. Each was disproven only by running the next test, and none of the failures would have announced themselves — a wrongly deleted archive is discovered when someone needs it, long after the evidence of the mistake is gone. Where the cost of a false positive is silent and permanent, the gate should be strengthened until it stops finding new counterexamples, not until it stops being convenient. The stopping rule is empirical, not aesthetic: keep tightening while each new test still reclassifies something.

The archival bug underneath has the same shape. The guard tested `base != tip` as a proxy for "is there a fork point", and that proxy is correct for the case the author had in mind (an orphan branch) and silently inverted for the case they did not (a fully merged branch). Both fail the same predicate for opposite reasons, and the fallback — chosen to be safe — was maximally expensive exactly where it was least necessary. When a guard's else-branch is described in a comment by a single scenario, it is worth asking what else satisfies it; a proxy that stands in for the real condition will eventually meet an input where the two diverge.

Finally: a bloated store is a symptom with two independent remedies, and they are not interchangeable. Fixing the write path stops the growth but reclaims nothing; pruning reclaims but does not stop regrowth. Both are needed, and the pruning half must not begin until its eligibility gate is proven, because the failure mode is silent and permanent.
