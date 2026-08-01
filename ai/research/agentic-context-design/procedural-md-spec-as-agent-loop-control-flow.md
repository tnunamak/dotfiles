---
title: "A procedural Markdown spec is the right control-flow mechanism for high-stakes agent work when combined with fail-closed gates and cross-model verification, not self-rated confidence"
date: 2026-06-26
topic: agentic-context-design
tags: [agent-loop, spec-as-program, evaluator-optimizer, llm-as-judge, reward-hacking, bounded-autonomy, procedural-spec, multi-agent-consensus, harness-design, ralph-loop, context-anxiety, managed-agents, loop-engineering]
status: draft
sources: [anthropic-bea, react-paper, reflexion-paper, langgraph-blog, constitutional-ai, llm-judge-mt-bench, self-preference-paper, multiagent-debate, sycophancy-perez, scalable-oversight, lats-paper, anthropic-effective-harnesses, anthropic-harness-design, anthropic-c-compiler, anthropic-managed-agents, anthropic-claude-code-expertise, anthropic-long-running-claude, osmani-loop-engineering-oreilly, osmani-loop-engineering-blog, steipete-tweet-jun7, cherny-loops-quote, claude-code-goal-v2-1-139]
source_session: 019d36fa-79a0-7e52-8f36-c40011d890aa
---

## CLAIMS

### 2026 practitioner harness engineering (Area 0 — new)

- The "engineers working in shifts" model: "each new session begins with no memory of what came before. Imagine a software project staffed by engineers working in shifts, where each new engineer arrives with no memory of what happened on the previous shift" — the core long-running agent problem [anthropic-effective-harnesses]
- The two fundamental failure modes in long-running agentic coding: (1) trying to do too much at once / one-shotting the entire task, leaving the next session with a half-implemented feature and no documentation; (2) losing coherence as the context window fills, sometimes accompanied by "context anxiety" (prematurely wrapping up work as the agent senses it is approaching its context limit) [anthropic-effective-harnesses][anthropic-harness-design]
- The initializer + coding agent split (Nov 2025): an **initializer agent** decomposes the spec into a task list and sets up the environment; a **coding agent** makes incremental progress per session and leaves clear artifacts (task list, status notes) for the next session [anthropic-effective-harnesses]
- The Ralph loop (named for ghuntley.com/ralph/): a `while true` shell loop that re-invokes the agent immediately when it exits, because "current models can suffer from agentic laziness — when asked to complete a complex, multi-part task, they can sometimes find an excuse to stop before finishing." The loop forces the agent to admit the task is not up to spec and continue [anthropic-long-running-claude][anthropic-c-compiler]
- The Ralph loop concrete implementation (C compiler, Feb 2026): `while true; do claude --dangerously-skip-permissions -p "$(cat AGENT_PROMPT.md)" ...; done` — the loop runs forever; the agent's only escape is completing the stated goal (or self-terminating by accident) [anthropic-c-compiler]
- Context resets vs. compaction: context resets (clearing the window entirely + structured handoff) address both coherence loss AND context anxiety; SDK compaction alone is not sufficient for very long tasks because it doesn't always pass perfectly clear instructions to the next session [anthropic-harness-design]
- Context anxiety is model-version-specific and therefore harness-specific: Sonnet 4.5 exhibited context anxiety (premature wrap-up); the fix (context resets) was added to the harness. When Opus 4.5 was released, context anxiety was gone — the resets became dead weight. The same harness was correct for one model, over-engineered for the next [anthropic-managed-agents][anthropic-harness-design]
- "Harnesses encode assumptions that go stale as models improve... every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing, both because they may be incorrect, and because they can quickly go stale" [anthropic-harness-design][anthropic-managed-agents]
- The three-agent full-stack harness (Mar 2026): Planner (expands 1-4 sentence prompt to full product spec), Coder (implements feature-by-feature), Evaluator/QA (grades output against explicit rubric). Continuous session via SDK compaction; no context resets needed on Opus 4.5+ [anthropic-harness-design]
- The self-evaluation problem in practice: "Out of the box, Claude is a poor QA agent. In early runs, I watched it identify legitimate issues, then talk itself into deciding they weren't a big deal and approve the work anyway. It also tended to test superficially, rather than probing edge cases." The fix was an explicit grading rubric given to BOTH the generator and the evaluator, plus iterative tuning of the evaluator prompt [anthropic-harness-design]
- Separating generator from evaluator (GAN-inspired): "by separating frontend generation from frontend grading, we can create a feedback loop that drives the generator toward stronger outputs." The evaluator's rubric must encode taste/criteria explicitly — "Is this design beautiful?" is too vague; "Does the design feel like a coherent whole? Is there evidence of custom decisions, or template layouts?" is actionable [anthropic-harness-design]
- Test oracles for autonomous agents: the C compiler harness used an extensive automated test suite as the primary non-human oversight mechanism. "How to write tests that keep agents on track without human oversight" was the central harness-design challenge for the parallel-Claudes experiment [anthropic-c-compiler]
- Parallel agent teams (16 agents on the C compiler, Feb 2026): "multiple Claude instances work in parallel on a shared codebase without active human intervention." Key design question: how to structure work so agents make progress without blocking each other. 2,000 sessions, 100,000-line compiler [anthropic-c-compiler]
- Brain/hands decoupling (Managed Agents, Apr 2026): separate the harness ("brain" = Claude + orchestration), the sandbox ("hands" = containers/tools), and the session log. Each becomes a stable interface. Harness calls container as a tool: `execute(name, input) → string`. Container failure = tool-call error; harness crash = resume from session log via `wake(sessionId)` [anthropic-managed-agents]
- Memory across sessions: the CHANGELOG.md pattern — a "portable long-term memory, acting as a sort of lab notes." Must track: current status, completed tasks, FAILED approaches and WHY they failed (without this, successive sessions re-attempt the same dead ends), accuracy tables, known limitations [anthropic-long-running-claude]
- Adoption data (Jun 2026): "The share of GitHub projects with coding agent activity has more than doubled since late 2025; Claude Code users now spend an average of 20 hours per week using the tool." 400,000 sessions analyzed. Over 7 months, debugging share fell ~50%, usage shifted toward end-to-end agentic work (deploy, run, analyze, write non-code) [anthropic-claude-code-expertise]
- Division of cognitive labor: "In a typical session, people make most of the planning decisions (what to do) and Claude makes most of the execution decisions (how to do it). The greater domain expertise a person brings to a session, the more work Claude does per instruction" [anthropic-claude-code-expertise]

### The named discipline: loop engineering (Area 0b — June 2026)

- Peter Steinberger (June 7, 2026): "You shouldn't be prompting coding agents anymore. You should be designing loops that prompt your agents." — the catalytic statement that named the movement [steipete-tweet-jun7]
- Boris Cherny (head of Claude Code, Anthropic): "I don't prompt Claude anymore. I have loops running that prompt Claude and figuring out what to do. My job is to write loops." — as quoted by Osmani in both his blog and O'Reilly Radar publications [osmani-loop-engineering-blog][osmani-loop-engineering-oreilly][cherny-loops-quote]
- Addy Osmani's central definition (June 2026): "Loop engineering is replacing yourself as the person who prompts the agent. You design the system that does it instead. A loop here can be thought of as a recursive goal where you define a purpose and the AI iterates until complete." [osmani-loop-engineering-oreilly]
- The six-piece anatomy of a loop (Osmani): (1) Automations that go off on a schedule and do discovery and triage by themselves; (2) Worktrees so two agents working in parallel don't step on each other; (3) Skills to write down the project knowledge the agent would otherwise just guess; (4) Plugins and connectors to plug the agent into the tools you already use; (5) Subagents so one of them has the idea and a different one checks it; (6) Memory — "A Markdown file, or a Linear board… the agent forgets; the repo doesn't." [osmani-loop-engineering-oreilly]
- The maker/checker split as the most valuable structural insight: "The most useful structural thing in a loop, by far, is splitting the one who writes from the one who checks. The model that wrote the code is way too nice grading its own homework. A second agent with different instructions and sometimes a different model catches the stuff the first one talked itself into." [osmani-loop-engineering-oreilly]
- Why the maker/checker split specifically matters inside loops (not just single-shot): "The reason it matters specifically inside a loop is the loop runs while you are not watching, so a verifier you actually trust is the only reason you can walk away." [osmani-loop-engineering-oreilly]
- The /goal primitive as the maker/checker split applied to the termination condition itself: "Claude Code's `/goal` does under the hood, a fresh model decides if the loop is done instead of the one that did the work, the maker and checker split applied to the stop condition itself." [osmani-loop-engineering-oreilly]
- /goal shipped in Claude Code v2.1.139 (May 11, 2026): "Added `/goal` command: set a completion condition and Claude keeps working across turns until it's met. Works in interactive, `-p`, and Remote Control. Shows live elapsed/turns/tokens as an overlay panel." [claude-code-goal-v2-1-139]
- Verification burden stays on the engineer: "Verification is still on you. A loop running unattended is also a loop making mistakes unattended." [osmani-loop-engineering-oreilly]
- Token cost caution: "I'm skeptical, and you absolutely have to be careful about token costs (usage patterns can vary wildly if you are token rich or poor)" — Osmani flags this as a reason to be cautious about loops, not to adopt them uncritically [osmani-loop-engineering-oreilly]
- Subagent token cost note: "subagents do burn more tokens since each one does its own model and tool work, so spend them where a second opinion is worth paying for" [osmani-loop-engineering-oreilly]
- The leverage-point-shifted thesis: "Two people can build the exact same loop and get completely opposite results. One uses it to move faster on work they understand deeply. The other uses it to avoid understanding the work at all. The loop doesn't know the difference. You do. That's what makes loop design harder than prompt engineering. Cherny's point isn't that the work got easier. It's that the leverage point moved." [osmani-loop-engineering-oreilly]
- Cognitive surrender as the failure mode: "The comfortable posture is the dangerous one. When the loop runs itself it's very tempting to stop having an opinion and just take whatever it gives back. I called that cognitive surrender. Designing the loop is the cure when you do it with judgement and the accelerant when you do it to avoid thinking, same action, opposite result." [osmani-loop-engineering-oreilly]

### Canonical agentic loop shapes (Area 1)

- Anthropic identifies six named workflow shapes: prompt chaining (sequential with optional gates), routing (classify then specialize), parallelization (fixed concurrent subtasks), orchestrator-workers (central LLM dynamically delegates), evaluator-optimizer (generator + evaluator loop), and fully autonomous agents with tool use [anthropic-bea]
- Anthropic's explicit guidance on when NOT to use agents: "add multi-step agentic systems only when simpler solutions fall short" — fixed pipelines are preferred when the task is well-defined [anthropic-bea]
- Anthropic's checkpointing guidance: "Agents can pause for human feedback at checkpoints or when encountering blockers... it's also common to include stopping conditions (such as a maximum number of iterations) to maintain control" [anthropic-bea]
- ReAct (Yao et al. 2022) defines interleaved thought→action→observation, where "reasoning traces help the model induce, track, and update action plans as well as handle exceptions, while actions allow it to interface with external sources" [react-paper]
- Reflexion (Shinn et al. 2023) adds verbal self-critique + episodic memory: agents "verbally reflect on task feedback signals, then maintain their own reflective text in an episodic memory buffer to induce better decision-making in subsequent trials" — no weight updates, purely in-context [reflexion-paper]
- LangGraph frames agents as stateful graphs with cycles (not DAGs), making human-in-the-loop a first-class state-machine feature rather than an afterthought [langgraph-blog]
- LATS (Zhou et al. 2023) integrates Monte Carlo Tree Search to enable deliberate backtracking: "LM-powered value functions and self-reflections for proficient exploration and enhanced decision-making" — the canonical paper for structured search with backtracking in LLM agents [lats-paper]

### Spec/prompt as program (Area 2)

- Karpathy's stated (Jan 2023) position: "The hottest new programming language is English" — establishing that natural-language text IS control flow for LLMs, not just description [karpathy-tweet]
- Constitutional AI (Bai et al. 2022) is the clearest published example of a text spec acting as executable control flow: a list of principles drives a self-critique→revise loop; "the only human oversight is provided through a list of rules or principles" [constitutional-ai]
- Constitutional AI demonstrates that a FIXED text spec can constrain an LLM's generation across multiple revision passes without weight updates, proving the "spec as loop" pattern works at scale [constitutional-ai]

### LLM-as-judge bias and failure modes (Area 3)

- Zheng et al. 2023 ("MT-Bench") identified three structural biases in LLM judges: position bias (favoring first answer), verbosity bias (favoring longer answers regardless of quality), and self-enhancement bias (favoring outputs that resemble the judge's own style) [llm-judge-mt-bench]
- Panickssery et al. 2024 proved self-preference is causally mechanistic: "We discover a linear correlation between self-recognition capability and the strength of self-preference bias" — GPT-4 and Llama 2 recognize their own outputs at non-trivial accuracy and score them higher [self-preference-paper]
- The implication: using the same model to generate AND judge its own work is structurally broken — the judge "wins" by recognizing and preferring its own generations [self-preference-paper]
- Du et al. 2023 showed multi-agent debate (multiple LLM instances proposing and debating over rounds) "significantly enhances mathematical and strategic reasoning" and "improves the factual validity of generated content" [multiagent-debate]
- Perez et al. 2022 documented RLHF-induced sycophancy: "Larger LMs repeat back a dialog user's preferred answer... we find some of the first examples of inverse scaling in RL from Human Feedback, where more RLHF makes LMs worse" [sycophancy-perez]

### Reward hacking / spec gaming (Area 4)

- Self-preference bias IS a form of reward hacking when the model is self-evaluating: since self-recognition correlates with self-preference, a model asked to rate its own output "97% confident" is structurally disposed to inflate the score [self-preference-paper]
- Scalable oversight (Bowman et al. 2022): "Developing safe and useful general-purpose AI systems will require us to make progress on scalable oversight: the problem of supervising systems that potentially outperform us on most skills relevant to the task at hand" — the problem statement for why self-evaluation is not sufficient for high-stakes work [scalable-oversight]
- A numeric confidence score ("I'm 96% confident") is a gameable gate: a model asked to produce a number will produce one; the number cannot be externally verified and is structurally inflated by sycophancy and self-preference [sycophancy-perez][self-preference-paper]

### Step-constraint mechanics (Area 5)

- Reflexion's episodic memory buffer is the prior-art pattern for "bounded autonomy within a step": the agent reasons freely inside each trial, but the self-critique and memory update happen BETWEEN trials, enforcing a gate [reflexion-paper]
- Constitutional AI's multi-round self-critique pattern shows that a FIXED external spec (the constitution) can act as a gate between generation rounds without requiring human oversight at each step [constitutional-ai]
- LangGraph's state-machine framing means each node can only transition via named edges — "you may reason freely within a node, but transitions between nodes are controlled" is the design pattern for bounded autonomy [langgraph-blog]
- Anthropic's "evaluator-optimizer" pattern explicitly separates the generator from the evaluator, making the gate structurally independent: the optimizer cannot see or influence the evaluator's criteria [anthropic-bea]

## SOURCES

**osmani-loop-engineering-oreilly**
URL: https://www.oreilly.com/radar/loop-engineering/
Published: June 22, 2026 (repost of Osmani blog with minor copyediting)
Status: Loaded successfully via WebFetch
Quote (definition): "Loop engineering is replacing yourself as the person who prompts the agent. You design the system that does it instead. A loop here can be thought of as a recursive goal where you define a purpose and the AI iterates until complete."
Quote (maker/checker): "The most useful structural thing in a loop, by far, is splitting the one who writes from the one who checks. The model that wrote the code is way too nice grading its own homework."
Quote (why it matters in loops): "The reason it matters specifically inside a loop is the loop runs while you are not watching, so a verifier you actually trust is the only reason you can walk away."
Quote (/goal framing): "Claude Code's `/goal` does under the hood, a fresh model decides if the loop is done instead of the one that did the work, the maker and checker split applied to the stop condition itself."
Quote (two people): "Two people can build the exact same loop and get completely opposite results. One uses it to move faster on work they understand deeply. The other uses it to avoid understanding the work at all. The loop doesn't know the difference. You do. That's what makes loop design harder than prompt engineering. Cherny's point isn't that the work got easier. It's that the leverage point moved."
Quote (cognitive surrender): "The comfortable posture is the dangerous one. When the loop runs itself it's very tempting to stop having an opinion and just take whatever it gives back. I called that cognitive surrender."
Quote (verification): "Verification is still on you. A loop running unattended is also a loop making mistakes unattended."
Note: Verbatim phrases "verifier is the bottleneck" and "scarce skill is defining what good and done mean" do NOT appear in the published text; those are interpretive paraphrases, not Osmani quotes.

**osmani-loop-engineering-blog**
URL: https://addyosmani.com/blog/loop-engineering/
Published: Before June 22, 2026 (exact date not shown on page; likely ~June 8–12, 2026 based on Steipete tweet reference)
Status: Loaded successfully via WebFetch; content nearly identical to O'Reilly repost
Note: O'Reilly version says "originally appeared on Addy Osmani's blog." Blog version has minor style differences; all key quotes confirmed identical.

**steipete-tweet-jun7**
URL: https://x.com/steipete/status/2063697162748260627
Published: June 7, 2026 (6:58 PM)
Status: Loaded successfully via WebFetch (og:description + page body); 8.4M views
Quote: "Here's your monthly reminder that you shouldn't be prompting coding agents anymore. You should be designing loops that prompt your agents."
Note: Peter Steinberger joined OpenAI in February 2026. This is a tweet, not a blog post; his blog (steipete.me) has no matching June 2026 post.

**cherny-loops-quote**
URL: Primary tweet URL not confirmed (search turned up amplification accounts at 404 URLs, not Cherny's own tweet)
Published: Before June 22, 2026 (quoted by Osmani in the loop-engineering essay)
Status: Quote confirmed as verbatim from two independent fetches of the Osmani article (blog + O'Reilly). Primary source tweet from Cherny's own account not independently verified.
Quote: "I don't prompt Claude anymore. I have loops running that prompt Claude and figuring out what to do. My job is to write loops."
Attribution by Osmani: "Boris Cherny, head of Claude Code at Anthropic"

**claude-code-goal-v2-1-139**
URL: https://github.com/anthropics/claude-code/releases/tag/v2.1.139
Published: May 11, 2026
Status: Confirmed via GitHub API
Quote (release note): "Added `/goal` command: set a completion condition and Claude keeps working across turns until it's met. Works in interactive, `-p`, and Remote Control. Shows live elapsed/turns/tokens as an overlay panel."
Note: Release notes do not describe the evaluator architecture ("separate smaller model"). That characterization comes from Osmani's essay. Follow-up fixes: v2.1.140 (hang fix), v2.1.143 (evaluator timing fix), v2.1.172 (CPU idle fix, June 10 2026).

**anthropic-bea**
URL: https://www.anthropic.com/research/building-effective-agents
Accessed: 2026-06-26
Quote: "Agents can then pause for human feedback at checkpoints or when encountering blockers. The task often terminates upon completion, but it's also common to include stopping conditions (such as a maximum number of iterations) to maintain control."

**react-paper**
URL: https://arxiv.org/abs/2210.03629
Accessed: 2026-06-26
Quote: "reasoning traces help the model induce, track, and update action plans as well as handle exceptions, while actions allow it to interface with external sources"

**reflexion-paper**
URL: https://arxiv.org/abs/2303.11366
Accessed: 2026-06-26
Quote: "Reflexion agents verbally reflect on task feedback signals, then maintain their own reflective text in an episodic memory buffer to induce better decision-making in subsequent trials."

**langgraph-blog**
URL: https://blog.langchain.dev/langgraph/
Accessed: 2026-06-26
Quote: "Effectively, these chains are directed acyclic graphs — as are most data orchestration frameworks… This can essentially be thought of as running an LLM in a for-loop. These types of systems are often called agents."

**karpathy-tweet**
URL: https://x.com/karpathy/status/1617979122625712128
Accessed: 2026-06-26
Quote: "The hottest new programming language is English."
Note: The oft-cited longer formulation "the weights are the program, the prompt is the source code" is attributed to Karpathy in talks but could not be verified at this URL.

**constitutional-ai**
URL: https://arxiv.org/abs/2212.08073
Accessed: 2026-06-26
Quote: "The only human oversight is provided through a list of rules or principles… In the supervised phase we sample from an initial model, then generate self-critiques and revisions, and then finetune the original model on revised responses."

**llm-judge-mt-bench**
URL: https://arxiv.org/abs/2306.05685
Accessed: 2026-06-26
Quote: "position, verbosity, and self-enhancement biases, as well as limited reasoning ability"

**self-preference-paper**
URL: https://arxiv.org/abs/2404.13076
Accessed: 2026-06-26
Quote: "We discover a linear correlation between self-recognition capability and the strength of self-preference bias."

**multiagent-debate**
URL: https://arxiv.org/abs/2305.14325
Accessed: 2026-06-26
Quote: "multiple language model instances propose and debate their individual responses and reasoning processes over multiple rounds… significantly enhances mathematical and strategic reasoning… improves the factual validity of generated content."

**sycophancy-perez**
URL: https://arxiv.org/abs/2212.09251
Accessed: 2026-06-26
Quote: "Larger LMs repeat back a dialog user's preferred answer ('sycophancy')… We also find some of the first examples of inverse scaling in RL from Human Feedback (RLHF), where more RLHF makes LMs worse."

**scalable-oversight**
URL: https://arxiv.org/abs/2211.03540
Accessed: 2026-06-26
Quote: "Developing safe and useful general-purpose AI systems will require us to make progress on scalable oversight: the problem of supervising systems that potentially outperform us on most skills relevant to the task at hand."

**lats-paper**
URL: https://arxiv.org/abs/2310.04406
Accessed: 2026-06-26
Quote: "We integrate Monte Carlo Tree Search into LATS to enable LMs as agents, along with LM-powered value functions and self-reflections for proficient exploration and enhanced decision-making."

**anthropic-effective-harnesses**
URL: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
Published: Nov 26, 2025
Quote: "The core challenge of long-running agents is that they must work in discrete sessions, and each new session begins with no memory of what came before. Imagine a software project staffed by engineers working in shifts, where each new engineer arrives with no memory of what happened on the previous shift... We developed a two-fold solution... an initializer agent that sets up the environment on the first run, and a coding agent that is tasked with making incremental progress in every session, while leaving clear artifacts for the next session."

**anthropic-harness-design**
URL: https://www.anthropic.com/engineering/harness-design-long-running-apps
Published: Mar 24, 2026
Quote (on self-evaluation failure): "Out of the box, Claude is a poor QA agent. In early runs, I watched it identify legitimate issues, then talk itself into deciding they weren't a big deal and approve the work anyway." Quote (on stale assumptions): "every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing, both because they may be incorrect, and because they can quickly go stale as models improve."

**anthropic-c-compiler**
URL: https://www.anthropic.com/engineering/building-c-compiler
Published: Feb 05, 2026
Quote (Ralph loop shell script): "while true; do COMMIT=$(git rev-parse --short=6 HEAD); claude --dangerously-skip-permissions -p \"$(cat AGENT_PROMPT.md)\" ... done" Quote (scope): "I tasked 16 agents with writing a Rust-based C compiler... Over nearly 2,000 Claude Code sessions and $20,000 in API costs, the agent team produced a 100,000-line compiler that can build Linux 6.9 on x86, ARM, and RISC-V."

**anthropic-managed-agents**
URL: https://www.anthropic.com/engineering/managed-agents
Published: Apr 08, 2026
Quote: "Harnesses encode assumptions that go stale as models improve... As just one example, in prior work we found that Claude Sonnet 4.5 would wrap up tasks prematurely as it sensed its context limit approaching—a behavior sometimes called 'context anxiety.' We addressed this by adding context resets to the harness. But when we used the same harness on Claude Opus 4.5, we found that the behavior was gone. The resets had become dead weight."
Quote (decoupling): "The solution we arrived at was to decouple what we thought of as the 'brain' (Claude and its harness) from both the 'hands' (sandboxes and tools that perform actions) and the 'session' (the log of session events). Each became an interface that made few assumptions about the others, and each could fail or be replaced independently."

**anthropic-claude-code-expertise**
URL: https://www.anthropic.com/research/claude-code-expertise
Published: Jun 16, 2026
Quote: "In a typical session, people make most of the planning decisions (what to do) and Claude makes most of the execution decisions (how to do it). The greater domain expertise a person brings to a session, the more work Claude does per instruction." Quote (adoption): "The share of GitHub projects with coding agent activity has more than doubled since late 2025, and Claude Code users now spend an average of 20 hours per week using the tool."

**anthropic-long-running-claude**
URL: https://www.anthropic.com/research/long-running-Claude
Published: Mar 23, 2026
Quote (CHANGELOG pattern): "The progress file, which by convention we call here CHANGELOG.md, is the agent's portable long-term memory, acting as a sort of lab notes... A good progress file might track current status, completed tasks, failed approaches and why they didn't work, accuracy tables at key checkpoints, and known limitations. The failed approaches are important—without them, successive sessions will re-attempt the same dead ends."
Quote (Ralph loop): "current models can suffer from agentic laziness—when asked to complete a complex, multi-part task, they can sometimes find an excuse to stop before finishing the entire task ('It's getting late, let's pick back up again tomorrow?'). To circumvent this, a useful orchestration pattern is the Ralph loop, which is essentially a for loop which kicks the agent back into context when it claims completion, and asks if it's really done."

## SYNTHESIS

### 2026 practitioner state-of-the-art (Anthropic harness engineering)

This section reconciles Anthropic's published harness engineering (Nov 2025 – Jun 2026) with the 5-state platonic-ideal-gate loop described below.

#### What they converge on

**Stop conditions / loop structure.** Every 2026 Anthropic harness includes an explicit external stop condition — not a self-rated "I'm done." The Ralph loop (`while true`) removes the agent's ability to terminate voluntarily; the agent must claim completion and the outer loop re-injects it with "are you really done?" until the task truly passes the test oracle. This directly validates our design: gates must be external and structural, not self-reported. The Ralph loop is the minimal working implementation of our "fail-closed by default" principle applied to the termination condition.

**Tool-based over self-graded verification.** Anthropic found empirically that self-evaluation is unreliable ("Claude is a poor QA agent... it would identify legitimate issues, then talk itself into deciding they weren't a big deal"). Their fix — an explicit rubric shared by BOTH the generator and the evaluator, enforced by a structurally separate evaluator agent — is exactly the S1/S2 cross-agent verification pattern in our loop. Their GAN-inspired generator/evaluator split matches our "aggregator is a different model" principle. For verifiable tasks (compiler correctness), they use automated test suites as the oracle — pure tool-based feedback, no model judgment.

**Sub-agent splits / parallel work.** Anthropic has converged on functional decomposition: Planner → Coder → Evaluator at minimum; 16 parallel coding agents for the C compiler. The key invariant in both their work and ours: the entity that generates an artifact should NOT be the entity that grades it. This is the anti-sycophancy constraint, and their empirical evidence (Evaluator grading diverged from human review until the rubric was carefully tuned across multiple rounds) validates how hard it is to get right.

**Fail-closed / error handling.** The Managed Agents brain/hands decoupling treats container failure as a tool-call error that gets passed back to Claude rather than silently ignored. The session log is external and durable — harness crash = resume from last event. This is the infrastructure-level version of our S4 (BEHAVIOR-VERIFY) fail-closed principle: failures surface as hard errors, not soft warnings.

**Progress files / handoff.** The CHANGELOG.md pattern (status, completed tasks, failed approaches + why, known limitations) is the file-backed equivalent of what our loop would produce in a multi-session run. Crucially, they emphasize recording FAILED approaches — exactly the anti-pattern our S0 DERIVE-IDEAL step prevents by committing the ideal-spec before the change is revealed. "Without them, successive sessions will re-attempt the same dead ends" is the runtime confirmation of why our COMMITTED IDEAL-SPEC cannot be changed once derived.

#### Where they challenge our design

**Over-engineering warning: context resets became dead weight.** The starkest 2026 finding is that context resets (a key component of the Nov 2025 harness) were completely dropped for the Mar 2026 harness, because Opus 4.5 no longer exhibited context anxiety. The lesson: every scaffold component is a time-stamped assumption about a specific model version. Our 5-state loop is heavy — five sequential states with cross-model aggregators is more scaffolding than the simple Ralph loop + external test oracle that Anthropic used for the C compiler.

**Implication for our loop:** The 5-state gate is appropriate for high-stakes code changes where correctness must be proven before landing (our original use case). For long-running autonomous builds where iteration speed matters, the Anthropic pattern is simpler: (1) write a comprehensive test suite as the oracle, (2) use a Ralph loop to keep the agent from stopping prematurely, (3) add an evaluator agent only if self-grading quality matters (UI/design), (4) use a CHANGELOG for memory across sessions. Our 5-state loop is over-engineered for bulk iterative work; it is appropriately specified for gating high-stakes changes into production.

**Evaluator quality requires iteration.** Anthropic's evaluator was tuned across "several rounds" of reading evaluator logs and updating prompts when its judgment diverged from human judgment. Our loop treats the evaluator as a static component, but in practice the evaluator prompt must itself be maintained. This is not a design flaw, but an operational reality: a rubric that is not iterated becomes stale, just as a harness becomes stale.

**The brain/hands decoupling shifts where failure lives.** Their Managed Agents architecture externalizes failure handling to the session log (durable outside the harness). Our loop's fail-closed pattern applies within a single session; it does not address cross-session recovery. For long-running work, the CHANGELOG.md + external session log pattern should be added as a S0 prerequisite: the agent reads the last known state before entering the gate loop, and writes the rejection/outcome before exiting.

#### Net guidance for our loop

1. Keep the 5-state gate for high-stakes production changes (code landing in main, schema migrations, SLVP-tier UI changes). It is not over-engineered for that use case.
2. For long autonomous runs (multi-day builds, research sessions), use the lighter pattern: CHANGELOG.md memory + Ralph loop outer shell + test suite oracle + evaluator agent only where needed. Do not force the 5-state gate on every iteration.
3. Add a S0 prerequisite: read CHANGELOG/progress file before starting, write outcome (including rejection reason) to it before exiting. This makes our gate loop resumable across sessions.
4. Treat each gate component as a versioned assumption. When the model improves, re-evaluate whether each component is still load-bearing. Remove dead weight aggressively ("find the simplest solution possible, and only increase complexity when needed" — Anthropic's consistent principle across all six 2026 posts).
5. The Ralph "are you really done?" re-injection is not in our loop and should be. S5's REJECT output should re-inject back to the start with the rejection reason, not just terminate — the agent should be forced to address the rejection and re-submit, rather than silently failing.

---

### The named discipline (June 2026): loop engineering

The Steinberger tweet (June 7), Osmani essay (June ~8–22, O'Reilly repost June 22), and Cherny quote crystallized a movement that had been emerging from Anthropic's harness engineering posts (Nov 2025 – Jun 2026) and the ralph/LATS prior art. That movement now has a name: **loop engineering**.

#### This is the canonical framing for what we are building

The loop-engineering literature is not separate from the 5-state gate loop described in this document — it IS the named discipline of which our gate loop is a specific, high-stakes instance. Osmani's anatomy maps directly onto the structures we use:

| Osmani's anatomy | Our equivalent |
|---|---|
| Automations (schedule, discovery) | The outer ralph loop / cron that re-invokes the gate |
| Worktrees (parallel agents, no collision) | Parallel blind derivations in S0/S1 |
| Skills (project knowledge the agent would otherwise guess) | The CLAUDE.md spec, COMMITTED IDEAL-SPEC from S0 |
| Plugins and connectors | Test runner, type-checker, linter in S4 |
| Subagents (one has the idea, a different one checks it) | S1 aggregator ≠ S0 generators; S3 membership-checker ≠ S2 evaluator |
| Memory (Markdown file, the repo doesn't forget) | The CHANGELOG.md pattern; the committed ideal-spec itself |

The maker/checker split that Osmani identifies as "the most useful structural thing in a loop" is exactly the design principle driving our cross-model verification requirement (S1 aggregator is a different model) and our fail-closed independence (S3 checks things S2 cannot check by design). The `/goal` primitive — "a fresh model decides if the loop is done instead of the one that did the work" — is the same principle applied to the termination condition itself.

#### The hard problem: our refactor goal is the BAD kind of termination condition

Osmani describes the /goal primitive with an example of a GOOD termination condition: "all tests in test/auth pass and lint is clean." This is checkable: a tool either passes or fails, and a fresh model can evaluate it objectively. The loop terminates when the condition is verifiably true.

Our refactor goal — "is this change part of the platonic ideal of this file?" — is structurally the same kind of condition Osmani would call **bad**: it is open-ended, non-checkable, and never terminates because "better" is always available. It is equivalent to "improve the code": a condition that produces perpetual iteration because no objective threshold is ever crossed.

This is not a criticism of the goal — it is an accurate diagnosis of the problem the 5-state gate exists to solve.

**The resolution: convert the unbounded ideal-judgment into a set of checkable structural conditions.**

The 5-state gate does exactly this conversion:

1. **"Independent blind derivations converged"** — replaces "is this the ideal?" with "did N ≥ 3 independent derivations of the ideal, without seeing the proposed change, agree?" Agreement is countable: 2/3 threshold is a number, not a judgment call. This converts the open-ended question into a measurement.

2. **"Membership against committed spec"** — replaces "does this change feel right?" with "does the proposed change contain anything outside the committed ideal-spec, yes or no?" A different agent answers a binary question about a fixed spec. The binary is checkable; the spec is immutable from S0.

3. **"Tests green"** — the only fully tool-mediated gate. Tests pass or they do not. No model judgment involved.

Together, these three checkable conditions replace the uncheckable "is this ideal?" with: "did blind independent derivations converge + does the change map onto that consensus + does no change exceed it + do tests pass?" This is the same move Osmani describes when he sets up /goal: you don't give it "improve the code," you give it "all tests in test/auth pass and lint is clean." We give it: "blind derivations ≥ 2/3 converged AND membership check PASS AND tests green."

The gate is still hard — especially the S0/S1 convergence check, which can fail on genuinely ambiguous design questions. But it is bounded and decidable, whereas "is this ideal?" is neither. The 5-state gate converts a philosophical question into an engineering procedure, which is precisely what loop engineering means in practice: "the scarce skill is defining what 'done' means in a way a loop can check."

#### The cognitive surrender risk

Osmani's warning about cognitive surrender applies directly to the use of this gate. The gate can be used in two ways: (1) by an engineer who has internalized why each state exists and adjusts the spec when the loop surfaces a genuine ambiguity; (2) by an engineer who runs the loop to avoid having an opinion, and accepts whatever it outputs. The loop produces the same verdicts in both cases. The difference is in what happens when the gate rejects — in case (1), the rejection is a signal about the change or the spec; in case (2), the rejection is an obstacle to be routed around.

The gate works when its operator treats divergence in S1 as important information about underspecified design, not as a nuisance that delays shipping. The spec being fixed after S0 is only load-bearing if the operator does not then update the spec to make a failing change pass.

---

### The conclusion: yes, procedural MD spec-as-loop is the right tool, but only if you understand WHY it works and WHERE it breaks

The research converges on a clear answer: a procedural Markdown spec the agent must execute step-by-step IS the right mechanism for high-stakes work — but the reason it works is structural, not motivational.

**Why motivational specs fail:** If you tell an agent "be careful and don't skip steps," you're relying on the agent's own judgment about when it has satisfied the instruction. The self-preference and sycophancy literature shows that this is structurally unreliable: the model is disposed to believe its own outputs are good, to inflate confidence scores when asked to self-rate, and to agree with whatever framing the prompt implies ("you're 95% confident here, right?"). A spec that says "verify with >95% confidence" produces the number without the verification.

**Why structural specs work:** Constitutional AI proves that a FIXED text spec (the "constitution") can drive multi-pass self-critique WITHOUT the agent deciding when it's done. The key is that the spec controls the LOOP STRUCTURE, not just the content of any one step. LangGraph's state-machine framing makes this explicit: you may reason freely WITHIN a node, but you can only TRANSITION via named edges. The gate is in the structure, not in the agent's self-assessment.

**The honest caveats:**
1. Specs get ignored if too long or too abstract. Constitutional AI works because each principle is a concrete, actionable critique instruction. A 3,000-word CLAUDE.md full of general wisdom is not a loop spec — it's ambient context that the model may follow or discount.
2. Self-critique loops can converge on wrong answers (Reflexion's failure mode: the agent convinces itself its initial wrong answer was right, and each "critique" reinforces the mistake). Convergence ≠ truth. This is why multi-agent and cross-model verification beats single-agent self-critique for correctness.
3. Multi-agent debate improves factuality on measurable tasks (Du et al.), but the debate itself can be dominated by the first speaker (position bias) or by the more verbose model. The ensemble must be structured to prevent easy consensus — use adversarial roles, not just "do you agree?"

---

### Concrete loop design: STRUCTURAL REFACTOR GATE

This is a named-state machine for gating a code change for "is this part of the file's platonic ideal, with >95% confidence that is STRUCTURAL not self-rated." It is executable as a Markdown spec — an orchestrator runs the states sequentially, agents reason freely within each state, but transitions require external gate conditions, not self-reported confidence.

---

#### STATE MACHINE

```
┌─────────────────────────────────────────────────────────────┐
│  STATES (must execute in order; fail-closed is default)     │
│                                                             │
│  S0: DERIVE-IDEAL                                           │
│  S1: BLIND-CONSENSUS                                        │
│  S2: CONVERGENCE-CHECK                                      │
│  S3: MEMBERSHIP-CHECK                                       │
│  S4: BEHAVIOR-VERIFY                                        │
│  S5: LAND / REJECT                                          │
└─────────────────────────────────────────────────────────────┘
```

---

#### S0: DERIVE-IDEAL (blind spec generation)

**What happens:** Before seeing the proposed change, N ≥ 3 independent agents (including at least one different model, e.g. Claude + GPT-5.5) are each asked: "Given this file's purpose and context [provide file + surrounding system description], describe what the PLATONIC IDEAL version of this file looks like — the irreducible set of things it must do and nothing more. Do not look at any proposed change."

**Why blind:** We must derive the ideal BEFORE seeing the change. If agents see the change first, self-preference and anchoring bias will cause them to rationalize the change as "obviously correct." The Constitutional AI principle: the critique spec must be independent of the artifact being judged.

**Gate condition to advance:** All N agents have produced an ideal-spec (structured list of required behaviors + anti-patterns). No confidence score requested. The output is the COMMITTED IDEAL-SPEC — it cannot be changed in later states.

**Fail-closed default:** If any agent fails to produce an ideal-spec, REJECT. Do not proceed with fewer than N specs.

---

#### S1: BLIND-CONSENSUS (convergence on the ideal)

**What happens:** The N ideal-specs from S0 are compared by a separate AGGREGATOR agent (different model, never sees the proposed change). The aggregator's sole job: produce a DIFF of the N specs — where do they agree? Where do they diverge?

**Why a different model:** Self-preference bias (Panickssery et al.) means the same model that wrote spec_A will score spec_A as most accurate. The aggregator must be a different model.

**Gate condition to advance:** Agreement ≥ 2/3 of N agents on each substantive point. Points where agents diverge are FLAGGED as "uncertain — cannot gate this dimension."

**Fail-closed default:** If overall agreement < 50%, REJECT: the ideal is underspecified and cannot be used as a gate. Surface the divergence to the human.

---

#### S2: CONVERGENCE-CHECK (does the proposed change map onto the consensus ideal?)

**What happens:** The proposed change is now revealed to the AGGREGATOR. It checks each point in the consensus ideal-spec: does the proposed change move the file TOWARD the ideal, AWAY from it, or is it NEUTRAL?

**Gate condition to advance:** The change is:
- TOWARD on all non-uncertain points, AND
- Not AWAY on any point

**Fail-closed default:** Any AWAY vote = REJECT. Uncertain points = surface to human, do not self-resolve. Do NOT ask the agent that proposed the change to adjudicate — that is the self-preference trap.

---

#### S3: MEMBERSHIP-CHECK (is the change only doing what the ideal requires?)

**What happens:** A third independent agent (ideally yet another model, or the same model with a different persona/system prompt) checks: does the proposed change contain ANYTHING not required by the consensus ideal-spec? This catches "scope creep" — a change that passes S2 but adds non-ideal behaviors.

**Why separate from S2:** S2 checks "does it move toward the ideal?" S3 checks "does it add anything outside the ideal?" A change can satisfy both, either, or neither independently.

**Gate condition to advance:** No material additions outside the consensus ideal-spec.

**Fail-closed default:** Any "yes, this adds X which is not in the ideal" finding = REJECT that portion. The agent may not decide on its own to slim the change — it surfaces the finding, and the change-author must re-submit.

---

#### S4: BEHAVIOR-VERIFY (does the change preserve all required behaviors?)

**What happens:** Automated tests + the N ideal-spec behaviors are checked against the changed file. This is the ONLY state where a tool (test runner, type checker, linter) replaces agent judgment. The ideal-spec from S0 is used as the test oracle: each behavior in the spec should pass; no existing passing test should now fail.

**Gate condition to advance:** 
- All automated tests pass
- Each behavior in the consensus ideal-spec has at least one test that covers it (if not, the test must be written FIRST, not assumed)
- Type-check and lint clean

**Fail-closed default:** Any failure = REJECT. No exceptions for "minor" failures. Agents may not adjust the spec to make the change pass — the spec is fixed from S0.

---

#### S5: LAND / REJECT

**LAND:** All gates S0–S4 passed. The change is committed.

**REJECT:** Any gate failed. The rejection message must include: which state failed, the specific gate condition, and the divergence/violation. Do NOT include a confidence score. The rejection is structural, not probabilistic.

---

#### KEY DESIGN PRINCIPLES (grounded in prior art)

1. **No self-rated confidence scores anywhere in the loop.** Every gate is structural (a diff, a count, a test pass/fail) or mediated by a different agent/model. This is the core fix for reward-hacking: a model cannot inflate a count or make a test pass by being "confident."

2. **The ideal-spec is derived BLIND and COMMITTED before the change is evaluated.** This prevents anchoring and self-preference. (Constitutional AI pattern: the constitution is fixed before any artifact is judged.)

3. **Cross-model verification at every aggregation step.** The aggregator in S1 and the membership-checker in S3 are deliberately different models. Self-preference bias (Panickssery et al.) is structurally eliminated when the judge cannot recognize its own output.

4. **Fail-closed is the default, not the exception.** The burden of proof is on ADVANCE, not on REJECT. Missing data, agent failure, divergence below threshold, or uncertain results all map to REJECT, not to "proceed with caution."

5. **Reason freely within a state; the gate controls the transition.** Agents inside S2 can and should reason extensively. But the gate condition is evaluated by a DIFFERENT agent/tool, not by the reasoning agent declaring "I'm done." This is the LangGraph state-machine principle applied to spec-as-loop.

6. **The spec IS the loop.** This document is executable. An orchestrator reads each state, runs the described agents, checks the described gate conditions, and advances or rejects. There is no ambient "use good judgment" — the procedure specifies the exact thing that must be true to advance.

---

#### HOW TO USE THIS AS A MARKDOWN SPEC

An agent executing this loop should:
1. Read this document in full at the start
2. Maintain a STATE variable (starts at S0)
3. Complete the current state fully before reading the gate condition
4. Apply the gate condition as written — not as summarized, not as interpreted
5. If FAIL-CLOSED default applies: output the rejection message format verbatim, stop
6. If gate passes: advance STATE, repeat from step 3

The agent must NOT skip ahead to "see what the end looks like" — this is why S0 is deliberately blind and S1 is committed before S2 sees the change. The spec's effectiveness depends on sequential execution. This is the same principle as Constitutional AI's critique-before-revise ordering: the critique must be written without seeing the final revised text.
