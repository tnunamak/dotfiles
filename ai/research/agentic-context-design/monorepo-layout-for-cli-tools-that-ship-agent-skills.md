---
title: Monorepo layout for small CLI tools that each ship an agent skill — shared-lib at dev time, vendor-on-ship at the skill boundary
date: 2026-06-30
tags: [monorepo, packaging, agent-skills, pep723, uv, claude-code, repo-structure]
sources: primary (anthropics/skills file tree md5-verified, Agent Skills spec, PEP 723, uv docs, Simon Willison)
source_session: 019d33c8-24c6-7f51-bdb9-949980e73f71
---

# Monorepo layout for CLI-tools-that-ship-skills (2026 prior art)

**Context.** Building `tnunamak/minnows`: a standalone repo of small, authored Python CLI tools
where each tool ships both an executable AND an agent skill (SKILL.md). Some tools share code
(e.g. `convo` + `uncompact` both parse Claude Code session JSONL / compaction boundaries).
Question: shared `lib/` (DRY) vs self-contained tools (copy-paste) vs installable package?

## Verdict

**Two distribution targets with opposite constraints — use a different pattern for each:**

1. **Dev time → shared `lib/` (Pattern 1).** Tools import a single shared parser. One source of
   truth. This is correct for a personal monorepo where you control every consumer.
2. **Ship time (inside a skill folder) → self-contained / vendored (Pattern 2).** A skill dir is
   copied/symlinked OUT of the repo (into `~/.claude/skills/`, a marketplace, another machine);
   at that point `from lib import x` has no `lib/` on the path. So the shipped skill must carry
   its code. **Vendor `lib/` into each `skills/*/scripts/` at ship time** (a `make sync`/pre-commit
   copy step) — Pattern 1 in dev, Pattern 2 at the boundary.
3. **Installable package (Pattern 3) — DON'T, yet.** Reserve for an *external* consumer / PyPI.
   For code only you consume, a version bump + reinstall per shared-parser tweak is pure ceremony.

**PEP 723 vs shared-lib:** use BOTH, by layer. PEP 723 inline `# /// script` + `uv run` is the
2026 default for **third-party dependencies** per standalone tool. It does **NOT** solve local-code
reuse — PEP 723 Motivation, verbatim: a single-file script "does not expect the availability of any
other local code that may be used for imports." The instant two tools share a parser you need a
`lib/` (dev) or a vendored copy (ship). They compose: a tool can carry an inline deps block AND
`from lib import …` when run from repo root.

## The biggest gotcha (why this matters)

**The skill boundary breaks `lib/` imports silently, on another machine, where you can't see it.**
Works locally (repo root on `sys.path`) → `ModuleNotFoundError` the moment an agent runs the bundled
script from `~/.claude/skills/`. The Agent Skills spec's "scripts should be self-contained" rule
EXISTS because of this failure mode. Mitigation ranking: vendor-on-ship (best) > symlink (breaks on
copy-installs + Windows) > escalate `lib/` to an installed package (heavy).

## Primary-source evidence

- **anthropics/skills** (https://github.com/anthropics/skills): README "Each skill is self-contained
  in its own folder with a SKILL.md." Decisive: the `office/` helper package is **byte-identical
  across docx/pptx/xlsx** (md5-verified: `unpack.py` 345c1b6a0e, `pack.py` 20d61f93e8, etc.) —
  Anthropic's own production skills **duplicate** shared code across skills rather than share a lib.
  Package-style sharing (`__init__.py`+`utils.py`) appears only *within* a single skill
  (skill-creator/scripts/). No skill script uses PEP 723.
- **Agent Skills spec** (https://agentskills.io/specification): canonical dir = SKILL.md + scripts/
  + references/ + assets/; scripts should "Be self-contained or clearly document dependencies." No
  provision for importing code outside the skill folder.
- **PEP 723** (https://peps.python.org/pep-0723/): inline script metadata = third-party deps only;
  explicitly no local-code imports.
- **uv** (https://docs.astral.sh/uv/guides/scripts/, /guides/tools/): `#!/usr/bin/env -S uv run
  --script` executable shebang; `uvx --from git+https://…` runs a tool straight from a repo (the
  Pattern 3 bridge when you outgrow scripts).
- **Simon Willison** (one-shot-python-tools 2024-12-19; designing-agentic-loops 2025-09-30):
  standalone single-file uv tools + installed CLIs documented in AGENTS.md; Pattern-2-flavored.

## Recommended layout (for minnows)

```
minnows/
├── lib/<pkg>/__init__.py      # shared parsers (e.g. claude_sessions: locations, chains, boundaries)
├── tools/<tool>/              # the dev source: executable + SKILL.md + README + evals/
├── skills/<tool>/             # SHIPPED skill: SKILL.md + scripts/ (vendored, self-contained)
├── sync.(sh|py)               # copies tool exe + lib/ into skills/*/scripts/ — the vendor step
├── install.sh                 # symlinks skills/* into ~/.{claude,codex,gemini}/skills + bins onto PATH
└── README.md
```
Dev edits `lib/` once; `sync` vendors into each shipped skill; `install.sh` wires agents.
Keep SHIPPED skills few + well-described (skill-metadata index has a ~16k-char cliff — see
[[skill-metadata-budget-and-name-only-overrides]]; this machine is already ~2× over).
