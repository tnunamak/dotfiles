---
title: "Salvatore Sanfilippo's real Redis commits demonstrate his stated 'commit messages are not titles' philosophy in practice — they pass the outsider test better than a terse Beams-style title because they restate the causal chain in the commit's own words rather than deferring to a linked issue, but this costs scannability (git log --oneline becomes useless) and a minority of his commits drift into implementation-internals prose that assumes reader familiarity with the codebase"
date: 2026-08-14
topic: writing-craft
tags: [git-commit-messages, antirez, redis, outsider-test, dense-synopsis, chris-beams, code-clarity]
status: draft
sources: [antirez-news-90-verbatim, redis-commit-27db38d069, redis-commit-48cde3fe47, redis-commit-94e8c9e77e, redis-commit-b09ea1bd90, redis-commit-41d3147344, redis-commit-db862e8ef0, redis-commit-624742d9b4, redis-commit-adc5df1bc3, redis-commit-57fa355e56, redis-commit-b407590cee, redis-commit-00a3bc4359, github-issue-1449]
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

- Salvatore Sanfilippo's (antirez) full stated position, verbatim from his own blog: "Nor subjects, for what matters. Everybody will tell you to don't add a dot at the end of the first line of a commit message. I followed the advice for some time, but I'll stop today, because I don't believe commit messages are titles or subjects. They are synopsis of the meaning of the change operated by the commit, so they are small sentences... This is a smart synopsis, as information dense as possible... If the first line of a commit message is a title, it changes *the way* you write it. It becomes just some text to introduce some more text, without any stress on the information density... Moreover, programming is the art of writing synopsis, otherwise you end with programs much more complex they should be." [antirez-news-90-verbatim]
- `redis/redis` (not `antirez/redis`) is the canonical, actively-maintained repository; GitHub's commit-author API (`gh api repos/redis/redis/commits?author=antirez`) returns his commits across the repo's full history including his personal-maintainer era (through ~June 2020, when he stepped down) and his later return to contribute Vector Sets (2024-2026). [redis-commit-27db38d069]
- antirez commit `27db38d069` ("Slaves heartbeat while loading RDB files.", Dec 2013) restates the entire causal chain of a replication bug as five self-contained numbered steps ("1) Master and slave setup with big dataset. 2) Slave performs the first synchronization... 5) Master detects the slave as timed out...") and explicitly names the tradeoff being made ("this is a shame since for the 0.1% of operation time we are forced to use a timeout that is not what is suited for 99.9% of operation time") and the reason the fix is deliberately a workaround ("a solution that is a bit of an hack... in order to be back ported to 2.8 safely"). [redis-commit-27db38d069]
- The GitHub issue that commit `27db38d069` references (`redis/redis#1449`, "Redis 2.8 replication issue") is a raw, unstructured user bug report consisting mostly of pasted log output with no root-cause analysis — the commit message's 5-step causal explanation does not appear anywhere in the issue; antirez synthesized and wrote it fresh rather than restating linked-issue content. [github-issue-1449] [redis-commit-27db38d069]
- Commit `48cde3fe47` ("dict.c iterator API misuse protection.", Aug 2013) explains a general mechanism before the specific fix ("dict.c allows the user to create unsafe iterators... The limitation is that when iterating with an unsafe iterator, no call to other dictionary functions must be done inside the iteration loop, otherwise the dictionary may be incrementally rehashed") and states the debugging motivation directly ("a number of bugs were found due to misuses of the API... The bugs are not trivial to track because the effect is just missing elements during the iteration") before describing the fingerprint-based detection mechanism and closing with the literal assertion-failure text the fix will now print. [redis-commit-48cde3fe47]
- Commit `94e8c9e77e` ("Make new masters inherit replication offsets.", Dec 2013) walks a concrete three-node scenario (A, B, C) step by step to explain why the bug is a comparability problem, then explicitly scopes the fix's limits in its own final paragraph: "Note that this does not mean offsets are always comparable to understand what is [the best replica]... in more complex examples the replica with the higher replication offset could be partitioned away." [redis-commit-94e8c9e77e]
- Commit `b09ea1bd90` ("Draft #1 of a new expired keys collection algorithm.", Aug 2013) states the design goal before the mechanism ("when we are no longer [able] to expire keys at the rate [they] are created, we can't block more in the normal expire cycle as this would result in too big latency spikes"), gives literal reproduction commands (`redis-benchmark -r 100000000 -n 100000000 -P 32 set ele:rand:000000000000 foo ex 2`) and monitoring commands, and self-flags the commit's own risk level ("this commit will make Redis printing a lot of debug messages, it is not a good idea to use it in production") — commit-as-lab-notebook, not commit-as-final-record. [redis-commit-b09ea1bd90]
- Commit `41d3147344` ("Fixed critical memory leak from EVAL.", Aug 2013) is a shorter, tighter example of the same form: names the exact defect ("multiple missing calls to lua_pop prevented the error handler function pushed on the stack for lua_pcall() to be popped"), names the user-visible symptom that would let an operator recognize the same bug independently ("very visible from INFO memory output, as the 'used_memory_lua' field reported an always increasing amount of memory used"), and closes with a personal credit line to the reporter ("Thanks to Tanguy Le Barzic for noticing... and for creating a testing EC2 environment where I was able to investigate the issue"). [redis-commit-41d3147344]
- Commit `db862e8ef0` ("redis-benchmark: changes to random arguments substitution.", Aug 2013) is a weaker counter-example within the same sample: its final two paragraphs shift from problem/rationale into pure implementation narration ("it was needed to change a few things in the internals of redis-benchmark, as new clients are created cloning old clients... a client structure is passed as a reference for cloning, so that we can directly clone the offsets inside the command line") that assumes the reader already understands redis-benchmark's internal client-cloning design — an outsider gets the "what changed for the user" (syntax `:rand:000000000000` → `__rand_int__`) but not full closure on the "why did the internals need restructuring" without separately reading the diff. [redis-commit-db862e8ef0]
- Four later (2020-era) commits sampled from the same author-filtered pull show the same structural pattern persisting near the end of his original Redis tenure: `624742d9b4` reproduces a full crash backtrace and walks a 6-step causal chain to the exact freed-memory access; `adc5df1bc3` pastes a real stack trace before explaining the synchronous-vs-asynchronous invariant being restored; `57fa355e56` explains a 3-step operational failure mode (PINGs sent after network partition inflate replication offset, blocking future PSYNC) before naming the fix; `b407590cee` quotes a GitHub issue discussion inline ("Citing from the issue: btw I suggest we change this fix to something else...") rather than just linking it. [redis-commit-624742d9b4] [redis-commit-adc5df1bc3] [redis-commit-57fa355e56] [redis-commit-b407590cee]
- None of the sampled commits follow Chris Beams's 50-character title-line convention; every title is a full descriptive clause (e.g. "Make new masters inherit replication offsets.", "Draft #1 of a new expired keys collection algorithm.") ending in a period, which is the specific convention (no title, no banned trailing dot) antirez's blog post argues for directly. [antirez-news-90-verbatim] [redis-commit-94e8c9e77e]

## SOURCES

**antirez-news-90-verbatim**
URL: https://antirez.com/news/90
Accessed: 2026-08-14
Quote: "Nor subjects, for what matters... I don't believe commit messages are titles or subjects. They are synopsis of the meaning of the change operated by the commit, so they are small sentences... This is a smart synopsis, as information dense as possible... If the first line of a commit message is a title, it changes *the way* you write it... Moreover, programming is the art of writing synopsis, otherwise you end with programs much more complex they should be." (full page text fetched via curl + tag-stripping, not paraphrased through a summarizer, to guarantee verbatim accuracy.)

**redis-commit-27db38d069**
URL: https://github.com/redis/redis/commit/27db38d069
Accessed: 2026-08-14
Quote: "Slaves heartbeat while loading RDB files.\n\n... Here the problem is that the master has no way to know how much the slave will take to load the RDB file in memory. The obvious solution is to use a greater replication timeout setting, but this is a shame since for the 0.1% of operation time we are forced to use a timeout that is not what is suited for 99.9% of operation time. This commit tries to fix this problem with a solution that is a bit of an hack, but that modifies little of the replication internals, in order to be back ported to 2.8 safely."

**redis-commit-48cde3fe47**
URL: https://github.com/redis/redis/commit/48cde3fe47
Accessed: 2026-08-14
Quote: "dict.c iterator API misuse protection.\n\n... The limitation is that when itearting with an unsafe iterator, no call to other dictionary functions must be done inside the iteration loop, otherwise the dictionary may be incrementally rehashed resulting into missing elements in the set of the elements returned by the iterator... This code was checked against a real bug, issue #1240."

**redis-commit-94e8c9e77e**
URL: https://github.com/redis/redis/commit/94e8c9e77e
Accessed: 2026-08-14
Quote: "Make new masters inherit replication offsets.\n\n... Note that this does not mean offsets are always comparable to understand what is, in a set of instances, since in more complex examples the replica with the higher replication offset could be partitioned away when picking the instance to elect as new master."

**redis-commit-b09ea1bd90**
URL: https://github.com/redis/redis/commit/b09ea1bd90
Accessed: 2026-08-14
Quote: "Draft #1 of a new expired keys collection algorithm.\n\n... For this reason the commit introduces a \"fast\" expire cycle that does not run for more than 1 millisecond but is called in the beforeSleep() hook of the event loop... Note: this commit will make Redis printing a lot of debug messages, it is not a good idea to use it in production."

**redis-commit-41d3147344**
URL: https://github.com/redis/redis/commit/41d3147344
Accessed: 2026-08-14
Quote: "Fixed critical memory leak from EVAL.\n\nMultiple missing calls to lua_pop prevented the error handler function pushed on the stack for lua_pcall() to be popped before returning, causing a memory leak in almost all the code paths of EVAL... Thanks to Tanguy Le Barzic for noticing something was wrong with his 2.8 slave, and for creating a testing EC2 environment where I was able to investigate the issue."

**redis-commit-db862e8ef0**
URL: https://github.com/redis/redis/commit/db862e8ef0
Accessed: 2026-08-14
Quote: "redis-benchmark: changes to random arguments substitution.\n\n... In order to implement the new semantic, it was needed to change a few thigns in the internals of redis-benchmark, as new clients are created cloning old clients, so without a stable prefix such as \":rand:\" the old way of cloning the client was no longer able to understand, from the old command line, what was the position of the random strings to substitute."

**redis-commit-624742d9b4**
URL: https://github.com/redis/redis/commit/624742d9b4
Accessed: 2026-08-14
Quote: "Remove the client from CLOSE_ASAP list before caching the master.\n\nThis was broken in 1a7cd2c: we identified a crash in the CI, what was happening before the fix should be like that:\n\n1. The client gets in the async free list.\n2. However freeClient() gets called again against the same client which is a master...\n6. Redis accessed a freed cached master."

**redis-commit-adc5df1bc3**
URL: https://github.com/redis/redis/commit/adc5df1bc3
Accessed: 2026-08-14
Quote: "Make disconnectSlaves() synchronous in the base case.\n\nOtherwise we run into that:\n\nBacktrace:\nsrc/redis-server 127.0.0.1:21322(logStackTrace+0x45)[0x479035]...\n\nSince we disconnect all the replicas and free the replication backlog in certain replication paths, and the code that will free the replication backlog expects that no replica is connected."

**redis-commit-57fa355e56**
URL: https://github.com/redis/redis/commit/57fa355e56
Accessed: 2026-08-14
Quote: "PSYNC2: meaningful offset implemented.\n\nA very commonly signaled operational problem with Redis master-replicas sets is that, once the master becomes unavailable for some reason... 1. The master becomes isolated, however it keeps sending PINGs to the replicas... 2. On the other side, one of the replicas will turn into the new master... 3. When the master rejoins the partion... a full synchronization will be required."

**redis-commit-b407590cee**
URL: https://github.com/redis/redis/commit/b407590cee
Accessed: 2026-08-14
Quote: "Fix #7306 less aggressively.\n\nCiting from the issue:\n\nbtw I suggest we change this fix to something else:\n* We revert the fix.\n* We add a call that disconnects chained replicas in the place where we trim the replica (that is a master i this case) offset."

**redis-commit-00a3bc4359**
URL: https://github.com/redis/redis/commit/00a3bc4359
Accessed: 2026-08-14
Quote: "Cluster: introduce data_received field.\n\nWe want to send pings and pongs at specific intervals, since our packets also contain information about the configuration of the cluster and are used for gossip. However since our cluster bus is used in a mixed way for data... sometimes a very busy channel may delay the reception of pong packets."

**github-issue-1449**
URL: https://github.com/redis/redis/issues/1449
Accessed: 2026-08-14
Quote: Issue title "Redis 2.8 replication issue"; body is a user's raw problem report plus pasted server log lines (e.g. "MASTER timeout: no data nor PING received...", "Full resync from master:") with no causal analysis — the numbered causal explanation in commit 27db38d069 does not appear in this issue text.

## SYNTHESIS

Pulling real commits (not summaries of them) confirms antirez practiced what he preached, and the practice is genuinely more defensible on the outsider test than I expected going in skeptical. The strongest examples — `27db38d069`, `48cde3fe47`, `94e8c9e77e`, `b09ea1bd90`, `41d3147344` — all pass a strict version of the outsider test: a reader with zero Redis-internals context can follow the numbered causal chain, understand why the fix is shaped the way it is (including *deliberate imperfection*, e.g. "a solution that is a bit of an hack... in order to be back ported to 2.8 safely"), and in at least one case (`27db38d069`) get a *better* causal explanation from the commit than exists anywhere in the linked GitHub issue — I checked issue #1449 directly and it's just a raw log dump with zero root-cause narrative. That is the single most important finding here: a Beams-style terse title + "see #1449" would have sent the outsider to a dead end. Antirez's synopsis-first ethic forces the causal explanation to live in the one place guaranteed to survive — the commit itself — rather than in an issue thread that may be unstructured, off-topic-drifted, or (on GitHub specifically) subject to no permanence guarantee at all.

The honest caveat, and I looked for it deliberately rather than cherry-picking only the best five: not every commit clears the bar equally. `db862e8ef0` is a real counter-example in the same sample — it explains the user-visible change well (the `:rand:` prefix syntax replaced by `__rand_int__`) but its last two paragraphs lapse into narrating an internal refactor ("a client structure is passed as a reference for cloning") without re-grounding why that internal change was necessary for someone who doesn't already know redis-benchmark's client-cloning design. That's not rambling exactly, but it's not fully self-contained either — a true outside reader gets 80% clarity, not 100%. So "dense and long" is not automatically "clear"; length buys clarity only when the writer keeps re-anchoring to the causal "why," and antirez doesn't do that with perfect consistency. Given the sample (12 commits fully read, several dozen more scanned by body length across two multi-year windows), the hit rate for genuinely outsider-clear commits looked like roughly 4 out of 5, which is a real, credible number — not "all of them," but clearly better than a coin flip.

The tradeoff against Beams/kernel convention is real and shouldn't be softened. `git log --oneline` on antirez's commits is close to useless as a scanning tool — his titles are full clauses ("Draft #1 of a new expired keys collection algorithm.", "Make new masters inherit replication offsets."), not the compressed, parallel-structured verb-first fragments Beams's convention optimizes for, and there is no consistent 50/72-column discipline, so `git log` output wraps unpredictably in a terminal. The Beams/kernel convention optimizes for a different reader in a different moment: someone scanning hundreds of commits in `git log --oneline` or a `git blame` output, deciding in under a second whether this commit is relevant to what they're debugging, with full detail only one `git show` away. Antirez optimizes for the reader who has already decided this commit matters and needs the full causal story without leaving the terminal. Neither is strictly better — they're built for different query patterns (scan-many vs. read-one), and a repo that gets both (short, real title-as-summary *plus* explicit numbered causal body, which several of these commits actually achieve, e.g. `94e8c9e77e`'s title is itself a complete, scannable clause) is doing better than either pure convention alone. The strongest single recommendation this sweep supports: steal antirez's *habit* (numbered causal steps, explicit statement of what tradeoff is being made and why, self-contained enough to not require the linked issue) without abandoning a short, parseable, non-title-feeling first line — which is achievable, and which several of his own best commits (`94e8c9e77e`, `41d3147344`) already demonstrate is not actually a contradiction.
