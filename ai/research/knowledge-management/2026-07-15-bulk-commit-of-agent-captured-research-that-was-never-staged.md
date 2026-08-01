---
title: "The 2026-07-15 bulk commit (acdbd83) captured 138 agent-written research entries that had accumulated untracked in the working tree — capture succeeded, `git add` never ran"
date: 2026-07-15
topic: knowledge-management
tags: [research-corpus, provenance, git-hygiene, agent-workflow, corpus-log]
status: verified
sources: [git-acdbd83, corpus-readme, research-capture-hook-memo]
source_session: unknown
---

<!--
This is a CORPUS-LOG / provenance note, not a topic-research entry. It explains why a
single commit dropped 138 files into ai/research/ at once, so a future reader (or agent)
doesn't mistake acdbd83 for an unreviewed dump. Kept in the corpus itself so it's greppable
alongside the research it describes. If more bulk-capture events happen, add sibling
corpus-log notes rather than editing this one.
-->

## CLAIMS

- On 2026-07-15, commit `acdbd83` ("research: commit uncommitted corpus entries across 28 topic areas") added 138 untracked `.md` research files plus the modified `INDEX.md` in one commit — 139 files, 12,914 insertions. [git-acdbd83]
- Those 138 files were NOT newly authored in that commit; they had been written to `ai/research/` over the preceding weeks by many different agent sessions and simply never `git add`ed, so they sat untracked in the working tree. [git-acdbd83]
- No `.gitignore` rule excluded them — the omission was missing `git add`/commit, not an ignore pattern. [git-acdbd83]
- The bulk commit was created by a general-purpose subagent dispatched from an interactive Claude Code session (`66850dc0`) at the user's explicit request ("that research and all research needs to go into the research corpus"). [git-acdbd83]
- Before staging, the subagent ran a mandatory secret scan (credential-value patterns: `sk-`, `ghp_`, `xox…`, `AKIA…`, JWT `eyJ…`, private-key blocks, `user:pass@` URLs, `vivid.fish`/`shell_secrets`/owner-token references) and found zero real secrets; all matches were architectural prose. Nothing was excluded. [git-acdbd83]
- The commit was made locally only; it was NOT pushed. [git-acdbd83]
- 128 of the 138 files already had an `INDEX.md` pointer; 10 lacked one (mostly RAW/INPUT/PENDING/sources-collected supporting material, not standalone entries). [git-acdbd83]
- The corpus README documents the entry format (CLAIMS/SOURCES/SYNTHESIS + one INDEX.md line per entry) but defines no provenance/corpus-log convention; this note establishes the first one. [corpus-readme]
- This event is a concrete instance of the previously-captured finding that research-capture-as-instruction is unreliable: agents captured the research (the hard part) but the "commit it" step is the weak link, and a batch of work can silently accumulate untracked. [research-capture-hook-memo]

## SOURCES

**git-acdbd83**
URL: local commit acdbd83 in /home/tnunamak/code/dotfiles (branch main)
Accessed: 2026-07-15
Quote: "139 files changed, 12914 insertions(+)"

**corpus-readme**
URL: ai/research/README.md
Accessed: 2026-07-15
Quote: "Add one line to INDEX.md when you create this."

**research-capture-hook-memo**
URL: ai/research/agentic-context-design/research-capture-is-unreliable-as-instruction-needs-precompact-hook.md
Accessed: 2026-07-15
Quote: "editing AGENTS.md doesn't reach running sessions; capture-at-the-end is the weakest moment"

## SYNTHESIS

The origin of these entries is ordinary corpus growth, not a suspicious import: dozens of
agent sessions did prior-art research across ~28 topics over several weeks and wrote proper
CLAIMS/SOURCES entries, but the final `git add && git commit` was skipped often enough that
138 files piled up untracked. The 2026-07-15 sweep just regularized them — with a secret
scan as the gate, since this repo has leaked live tokens into staged files before.

The durable lesson matches [[research-capture-is-unreliable-as-instruction-needs-precompact-hook]]:
capturing the research is not the failure mode — *committing* it is. A staged-file backstop
(e.g. a periodic "untracked files under ai/research/? commit them" check, or folding the
commit step into the same hook that nudges capture) would prevent the next silent pile-up.
Until then, treat "large untracked set under ai/research/" as expected drift to sweep, not
as an anomaly.
