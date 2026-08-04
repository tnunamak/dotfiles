# Agent Completion Gates: Forcing Required Actions Before Finishing

**Research question:** What established patterns exist for forcing an LLM agent to complete a required action before finishing (a completion gate / required-tool-call)?

**Scope:** Survey of Anthropic Claude, OpenAI, LangGraph, Guardrails AI, NeMo Guardrails, DSPy, and constrained decoding approaches.

**Date:** August 2026  
**Source session:** eea5172b-f553-47dc-a33b-66544e9e8683

---

## Key Findings

Three orthogonal approaches discovered:

1. **Model-Level Forcing (Declarative)** — `tool_choice="any"` (Claude/OpenAI), `strict: true` (OpenAI Structured Outputs), constrained decoding (NVIDIA/Google, not Anthropic). Best for guaranteeing at least one tool call; transparent in generation.

2. **Agentic State-Machine Gating (Structural)** — LangGraph `interrupt_before` and `interrupt_after`, multi-stage validation gates (Guardrails AI). Best for complex workflows with approval gates; adds latency but enables audit trails.

3. **Session-Level Blocking (Runtime)** — Claude Code Stop hook with `{"decision": "block"}` and exit code 2; loop cap of 8 blocks per turn (configurable). Only in interactive agent frameworks; visible to user.

### Claude Code Stop Hook Contract (Most Relevant)

- **Input**: JSON on stdin (includes `stop_hook_active`, `session_id`, `transcript_path`, etc.)
- **Block output**: Exit 0 with `{"decision": "block", "reason": "..."}`, or exit code 2
- **Allow output**: Exit 0 without decision JSON
- **Loop safety**: 8 consecutive blocks per turn trigger short-circuit; disable via `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP=0`
- **State tracking**: `stop_hook_active` flag is true when Claude is already in forced-continuation state; check to avoid immediate re-block

### Claude API tool_choice Options

- `{"type": "auto"}` — Claude decides whether to call a tool (default)
- `{"type": "any"}` — Claude must call one tool but picks which one
- `{"type": "tool", "name": "tool_name"}` — Claude must call the specific named tool
- `{"type": "none"}` — Claude cannot use tools
- **Note**: Only `auto` and `none` compatible with extended thinking

### OpenAI tool_choice and Structured Outputs

- `tool_choice="required"` — Guarantees tool invocation (available in Microsoft Agent Framework, Google ADK, native OpenAI agents)
- `strict: true` on tool definitions — JSON Schema conformance enforced; available on Chat Completions, Assistants, Batch APIs
- Namespace collision: "required" (OpenAI) vs "any" (Claude) are semantically different

### LangGraph State Gates

- `interrupt_before` — Blocks before a node executes (approval gate)
- `interrupt_after` — Pauses after a node executes (review gate)
- Structured transitions: `(state_before, node, state_after, edge_taken)` are explicitly defined and evaluable

### Guardrails AI Three-Stage Model

1. Input validation (before model call)
2. Output validation (before response to user)
3. Action authorization (before tool/action execution)

---

## Comparison Table

| Aspect | Model-Level (tool_choice) | State Machine (LangGraph) | Session Blocking (Stop hook) |
|--------|---------------------------|--------------------------|------------------------------|
| Prevents refusal | ❌ No | ⚠️ Partial | ❌ No |
| Guarantees by construction | ✅ Yes (constrained decoding) / ⚠️ Partial (tool_choice) | ✅ Yes | ✅ Yes |
| User visibility | Low | Medium | High |
| Applies at | Generation | Pre/post execution | Session close |
| Framework | All APIs | Custom/LangGraph | Claude Code only |
| Latency | None | Per gate | Per block |

---

## Design Recommendation

For **waspflow agent completion gate** (as research context):

1. **Primary**: Claude API `tool_choice={"type": "any"}` if requirement is "must call one of N analysis tools before finishing."
2. **Secondary**: Claude Code Stop hook if requirement is "interactive session cannot end until test passes."
3. **Avoid**: DSPy Assertions (deprecated) and NeMo Guardrails (research-grade, complex).

**Note on constraints**: Extended thinking incompatible with forced tool use (only `auto` and `none` supported). No cross-provider standard contract exists.

---

## References

- Claude Code Hooks: https://code.claude.com/docs/en/hooks
- Claude API Tool Use: https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview
- OpenAI Structured Outputs: https://developers.openai.com/api/docs/guides/structured-outputs
- LangGraph State Machines: https://blog.stackademic.com/built-with-langgraph-19-state-machines-24e9c5de8869
- Constrained Decoding: https://arxiv.org/html/2310.07075v3 (Don't Fine-Tune, Decode)
- Guardrails AI: https://last9.io/blog/what-are-ai-guardrails/
- NeMo Guardrails: https://github.com/NVIDIA-NeMo/Guardrails
