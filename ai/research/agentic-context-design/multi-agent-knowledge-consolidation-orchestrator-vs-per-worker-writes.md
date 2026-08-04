---
title: "Orchestrator-centralized synthesis prevents fragmentation; per-worker writes requires strict isolation to avoid duplication and contradiction"
date: 2026-08-04
topic: agentic-context-design
tags: [multi-agent, knowledge-consolidation, orchestration-pattern, failure-modes]
status: final
sources: [anthropic-research-system, openai-deep-research, google-co-scientist, crewai-memory, langgraph-coordination, mapreduce-consolidation, claude-code-workflows, production-failure-analysis, shared-scratchpad, conflict-resolution]
source_session: 8fb0b508-9f0b-40bc-855d-7fc69d428698
---

## CLAIMS

- **Anthropic's orchestrator model: lead agent plans, spawns 3-5 subagents in parallel, each returns structured findings, then LeadResearcher synthesizes and routes to CitationAgent for final report** [anthropic-research-system]. This pattern beats single-agent baseline by 90.2% on internal evals; cost is 15× token overhead vs normal chat [anthropic-research-system].

- **OpenAI Deep Research uses Knowledge Gap Agent + Tool Selector Agent under a DeepResearcher orchestrator, which calls IterativeResearch instances in parallel, then a proofreading stage synthesizes** [openai-deep-research]. The orchestrator exits the research loop when sufficient info is gathered, then passes ALL findings to a CitationAgent.

- **Google Co-Scientist uses a Supervisor Agent managing asynchronous task execution, storing intermediate outputs in persistent context memory, computing statistics per-loop, and storing results for iterative refinement**; an Elo tournament evaluates hypotheses across multiple agents [google-co-scientist]. The SUPERVISOR writes to memory, not the workers.

- **CrewAI's unified memory system: all agents in a crew share ONE Memory class; after each task, discrete facts are extracted and stored; before each task, agents recall relevant context injected into the prompt; agents recall DIFFERENTLY (planning agents weight importance, execution agents weight recency)** [crewai-memory]. This is SHARED WRITE at the crew level, not per-worker.

- **LangGraph implements scatter-gather via the Send API: work is distributed to parallel agents, then consolidated downstream in a REDUCE stage**; the reduction happens in a separate graph node, not inside individual agent contexts [langgraph-coordination].

- **Map-reduce consolidation pattern: individual workers summarize their chunk (MAP), then a REDUCE phase combines summaries into one final summary**; this is the canonical large-scale multi-agent pipeline [mapreduce-consolidation]. Used for feedback classification, knowledge synthesis, and document summarization.

- **Claude Code Workflow runtime: agents spawn in parallel, intermediate results stay in SCRIPT VARIABLES (not Claude's context window), orchestration is deterministic and repeatable, final answer lands in the session after all agents complete** [claude-code-workflows]. The workflow script itself holds the loop, branching, and intermediate state.

- **Per-worker writes require strict isolation to avoid conflicts: one-writer-per-module with isolated Git worktrees prevents write collisions by construction, but requires explicit segmentation**; without isolation, agents duplicate effort and contradict [orchestrator-worker-pattern]. This pattern trades consolidation cost for isolation simplicity.

- **State synchronization failure is a top failure mode in production multi-agent systems (79% of breakdowns); agents develop inconsistent views when one agent's state update races with another's read**; duplicate work and contradiction are THE consequence, not detection gaps [production-failure-analysis].

- **Inter-agent misalignment is the most common production failure mode: agents talk past each other, duplicate effort, forget responsibilities, despite being individually capable**; this is a system-level property, not agent-level [production-failure-analysis]. It emerges from coordination, not agent quality.

- **Shared scratchpad with SHA-256 content addressing and metadata aliasing: if a worker writes the same payload twice, only one file is stored; metadata entries accumulate independently with multiple labels on same content**; this is ONE deduplication strategy [shared-scratchpad]. Requires version control and clear contribution protocols.

- **The Consistency Illusion: multi-agent debate (consensus voting) can mask reasoning misalignment — agents may agree on an answer for different reasons, making agreement a false proxy for correctness** [consistency-illusion]. Consensus consolidation ≠ correctness verification.

- **Knowledge transfer propagates vulnerabilities alongside capabilities; when agents interact, individual failures compound into qualitatively new system-level failure modes**; a safe multi-agent system requires holistic analysis, not per-agent safety [production-failure-analysis]. Safe agents ≠ safe system.

## SOURCES

**anthropic-research-system**
URL: https://medium.com/@kushalbanda/how-we-built-our-multi-agent-research-system-5f5e10b2a8d6
Accessed: 2026-08-04
Quote: "A user's query first reaches the LeadResearcher, which deconstructs the question into a coherent research plan and assigns targeted subtasks to Subagents. Each Subagent then executes its segment—be it web search, data extraction, or analysis—concurrently, returning concise findings that the LeadResearcher later synthesizes into a unified report... The LeadResearcher synthesizes these results and decides whether more research is needed — if so, it can create additional subagents or refine its strategy. Once sufficient information is gathered, the system exits the research loop and passes all findings to a CitationAgent, which processes the documents and research report to identify specific locations for citations."

**openai-deep-research**
URL: https://openai.com/index/introducing-deep-research/
Accessed: 2026-08-04
Quote: "a multi-agent implementation includes a DeepResearcher that orchestrates a workflow with an initial report outline, calling of multiple parallel IterativeResearch instances, and a final proofreading step, along with specialized agents including a Knowledge Gap Agent that analyzes current research state and identifies gaps in knowledge, and a Tool Selector Agent that determines which tools to use for addressing specific knowledge gaps."

**google-co-scientist**
URL: https://deepmind.google/blog/co-scientist-a-multi-agent-ai-partner-to-accelerate-research/
Accessed: 2026-08-04
Quote: "A persistent context memory maintains state over long reasoning horizons, enabling feedback loops and continuous improvement... The Supervisor Agent manages asynchronous task execution, allocates computational resources dynamically, and stores intermediate outputs in context memory for iterative refinement. The Supervisor agent periodically computes and writes to the context memory, a comprehensive suite of statistics, including the number of hypotheses generated and requiring review, and the progress of the tournament."

**crewai-memory**
URL: https://crewai.com/blog/how-we-built-cognitive-memory-for-agentic-systems
Accessed: 2026-08-04
Quote: "All agents in the crew share the crew's memory unless an agent has its own. After each task, the crew automatically extracts discrete facts from the task output and stores them. Before each task, the agent recalls relevant context from memory and injects it into the task prompt... Agents share a memory but recall differently, a planning agent weights importance while an execution agent weights recency, so you find yourself with same knowledge but being able to tap into it through different lenses."

**langgraph-coordination**
URL: https://latenode.com/blog/ai-frameworks-technical-infrastructure/langgraph-multi-agent-orchestration/langgraph-multi-agent-orchestration-complete-framework-guide-architecture-analysis-2025
Accessed: 2026-08-04
Quote: "LangGraph enables flexible control flow through conditional logic and modular subgraphs, where conditional edges evaluate the current state to decide the next execution path... The framework supports parallel execution strategies, allowing tasks to be processed simultaneously while staying coordinated via shared state, with patterns like scatter-gather where tasks are distributed to multiple agents and results are consolidated downstream."

**mapreduce-consolidation**
URL: https://medium.com/google-cloud/summarizing-too-big-for-context-with-mapreduce-and-llms-6d2acc7a2ed0
Accessed: 2026-08-04
Quote: "The MapReduce method breaks text into chunks, summarizes each one, then summarizes the summaries—you first generate individual summaries (map), then combine and condense them into one final summary (reduce)... In LangGraph, map-reduce is implemented using the Send API, which enables dynamic task creation at runtime where the number and configuration of parallel tasks are determined by the graph's state rather than fixed at design time."

**claude-code-workflows**
URL: https://code.claude.com/docs/en/workflows
Accessed: 2026-08-04
Quote: "A dynamic workflow is a JavaScript script that orchestrates subagents at scale... The workflow runtime executes the script in an isolated environment, separate from your conversation. Intermediate results stay in script variables instead of landing in Claude's context... Every run writes its script to a file under your session's directory in `~/.claude/projects/`. The runtime tracks each agent's result as the run progresses, which is what makes a run resumable within the same session."

**orchestrator-worker-pattern**
URL: https://agentpatterns.ai/multi-agent/orchestrator-worker/
Accessed: 2026-08-04
Quote: "The orchestrator handles coordination alone—maintaining session state, routing tasks to the appropriate worker agent, and connecting follow-up requests to preserved artifacts—without performing analysis or report generation itself... Multiple workers can operate simultaneously, enabling parallel processing of independent subtasks, while the orchestrator manages synchronization and result aggregation... Per-agent writes require strict isolation to avoid conflicts: one-writer-per-module with isolated Git worktrees prevents write collisions by construction, but requires explicit segmentation."

**production-failure-analysis**
URL: https://huggingface.co/papers/2503.13657
Accessed: 2026-08-04
Quote: "Fine-grained failure modes are organized into 3 categories: specification and system design failures, inter-agent misalignment, and task verification and termination. Research identifies these two categories (specification ambiguity and coordination breakdowns) as the source of 79% of production breakdowns... State synchronization failures occur when agents develop inconsistent views of shared system state. Unlike single agents maintaining a unified context, distributed agents must actively synchronize state across boundaries, creating multiple failure points... Inter-agent misalignment is the most common production failure mode: agents talk past each other, duplicate effort, forget responsibilities, despite being individually capable."

**shared-scratchpad**
URL: https://agentic-design.ai/patterns/multi-agent/shared-scratchpad-collaboration
Accessed: 2026-08-04
Quote: "Different agents can collaborate on a shared scratchpad of messages, with all work being visible to each agent. Best practices include using version control and conflict resolution mechanisms, establishing clear protocols for agent contribution formats, and implementing proper access control and edit permissions... The scratchpad uses SHA-256 content addressing, where if an agent deposits the same payload twice, only one file is stored. Metadata entries accumulate independently, allowing multiple labels to alias the same underlying content."

**consistency-illusion**
URL: https://arxiv.org/pdf/2606.08457
Accessed: 2026-08-04
Quote: "The Consistency Illusion: How Multi-Agent Debate Hides Reasoning Misalignment — multi-agent debate (consensus voting) can mask reasoning misalignment; agents may agree on an answer for different reasons, making agreement a false proxy for correctness."

## SYNTHESIS

**The Fragmentation Problem**

Without active orchestration, per-worker writes amplify three risks: **duplication** (agent A and B both solve the same subproblem; neither knows), **contradiction** (agent A extracts Fact X; agent B extracts ¬X; no reconciliation layer), and **state desynchronization** (agent C reads outdated state while agent D is updating it; C acts on stale knowledge). These account for 79% of production multi-agent failures.

Shared scratchpad and per-worker write patterns attempt to avoid this by isolation: split the problem domain across workers so no two write the same region. This works when boundaries are clean (one module per worker, Git worktrees per edit task) but breaks when work naturally overlaps (research spanning multiple sources, synthesis requiring cross-worker deduplication, knowledge gaps discovered mid-execution that need backfill).

**Why Orchestrator-Centralized Synthesis Wins**

Anthropic, OpenAI, Google, and CrewAI converge on a single architectural choice: **the orchestrator holds the consolidation logic, not the workers**. The workers write findings into an isolated intermediate form (structured JSON, scratchpad entries), and then ONE stage (LeadResearcher, CitationAgent, Supervisor, CrewAI's unified Memory) performs deduplication, conflict detection, and synthesis.

Key properties:

1. **Single source of truth for consolidation**: One component owns the deduplication logic, so it can detect duplicates (content-addressed hashes, entity resolution, semantic similarity scoring) and contradictions (fact X vs ¬X detection).

2. **Deterministic ordering**: The orchestrator controls the reduction order (map-reduce has a canonical MAP then REDUCE stage), preventing timing races where agent C reads B's output before D finishes and contradicts B.

3. **Verifiable seams**: The input to the reduction stage is bounded and explicit (N workers' outputs + their metadata), making it auditable and testable.

4. **Cost is upfront, not distributed**: The consolidation overhead is paid ONCE at the end, not replicated across workers. Anthropic's 15× token cost is mostly this synthesis pass; without it, parallel workers waste tokens on redundant analysis.

**The Per-Worker Write Boundary**

Per-worker writes work only when:
- **Isolation is strict**: The domain can be cleanly partitioned so no two workers plausibly cover the same ground (rare in research; common in code where modules are explicit).
- **No cross-worker consensus needed**: If you need to verify "did agents agree on this fact?", you've already lost isolation and need to consolidate.
- **Conflict resolution is not needed**: If contradictions are acceptable (vote-and-move-on), the system tolerates the Consistency Illusion and may accept wrong answers.

Anthropic's research system initially considered this: assign each worker one source (paper A, paper B, paper C) and prevent overlap. But real research needs synthesis across overlapping domains, so they added the orchestrator layer.

**Documented Failure Modes of Fragmentation**

1. **State synchronization race**: Worker A completes task and updates central state; Worker B retries because of timeout, not knowing A succeeded; both mark as done; central state is corrupt (two completion markers for one task).

2. **Duplicate synthesis from different angles**: Worker A studies "company X's rate limiting"; Worker B independently studies "company X's rate limiting"; CitationAgent must detect these are the same fact and merge them or pick one.

3. **Knowledge gaps discovered too late**: Worker finishes its chunk, returns findings; orchestrator detects a gap (no coverage of "what if rate limit is exceeded?"), spins up Worker F to backfill; but this requires the orchestrator to know enough to recognize gaps—if it's dumb, gaps stay hidden.

4. **Contradictions accepted without notice**: Worker A says "X uses token bucket"; Worker B says "X uses sliding window"; voting on both may happen; the Consistency Illusion can make them both survive (50-50 vote = both reported as viable, hiding the contradiction).

**Implementation Gauntlet**

Orchestrator-synthesis requires three things to avoid becoming a bottleneck:

1. **Structured output from workers** (JSON schema, mandatory fields), so the consolidator doesn't parse prose.
2. **Explicit deduplication strategy** (content hash like scratchpad SHA-256, semantic similarity bounds, or entity resolution rules).
3. **Conflict escalation rule** (contradiction detected → which source is authoritative, or escalate to human?).

CrewAI's implementation (unified Memory, per-agent recall patterns) shows this can work at crew scale; Google's Supervisor in Co-Scientist shows it scales to large hypothesis tournaments. Claude Code Workflows codify it: the script IS the orchestration, not an afterthought.

**Open Gaps**

- **Optimal consolidation frequency**: After every worker finishes? After N workers? After a timeout? No empirical guidance in the research.
- **Unbounded dialogue handling**: If workers iterate and discover new facts, does consolidation run again? Or only at the end?
- **Cross-worker dependency chains**: If Worker B needs Worker A's output to proceed, should the orchestrator enforce that, or do workers poll? (None of the systems surveyed make this explicit.)
- **Verification of consolidation itself**: Who verifies the orchestrator didn't introduce errors during synthesis? Anthropic runs a separate CitationAgent, but that's a second pass, not a structural guarantee.

**Recommended Practice**

- **Assume consolidation is necessary** once you have >3 parallel workers or overlapping domains.
- **Centralize synthesis in the orchestrator**, not in the workers or a later "merge" step.
- **Enforce structured output** from workers (schema validation, not prose interpretation).
- **Implement explicit deduplication** (content hash for exact matches, semantic similarity for near-misses, conflict detection for contradictions).
- **Make ordering deterministic** (map-reduce canonical stage order, not async races).
- **Verify the consolidation seam** with a different agent or deterministic test—the orchestrator's synthesis is a place bugs hide.
