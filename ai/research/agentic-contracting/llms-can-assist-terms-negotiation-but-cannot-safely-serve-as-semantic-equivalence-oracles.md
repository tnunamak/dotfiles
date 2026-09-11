---
title: "LLMs can assist terms negotiation but cannot safely serve as semantic-equivalence oracles"
date: 2026-09-03
topic: agentic-contracting
tags: [llm, contracts, agents, mcp, a2a, electronic-agents]
status: draft
sources: [contract-nli, blt, contract-eval, clause, legalbench, esign, ueta, visa]
source_session: unknown
---

## CLAIMS

- ContractNLI reports that contract entailment remains difficult where exceptions and negation control the result. BLT found poor performance by public LLMs on basic legal-text tasks; Better Call CLAUSE found leading models often missed subtle contract errors and struggled to justify answers. [contract-nli] [blt] [clause]
- ContractEval found that reasoning mode could improve answer effectiveness while reducing correctness. [contract-eval]
- LegalBench excludes long documents and tasks where reasonable legal minds may differ, and is weighted toward English-language United States law. Its results therefore cannot validate arbitrary, jurisdiction-sensitive terms interpretation. [legalbench]
- E-SIGN recognizes electronic-agent formation only when the agent's action is legally attributable to the person to be bound. UETA allows agent-to-agent formation but leaves the contract terms to applicable substantive law. [esign] [ueta]
- MCP and A2A standardize authentication and agent interchange, not legal-policy semantics. Visa and Mastercard instead bind agent identity, operation, time, payment authority, and limits in signed, bounded mandates. [visa]

## SOURCES

**contract-nli**
URL: https://aclanthology.org/2021.findings-emnlp.164/
Accessed: 2026-09-03

**blt**
URL: https://aclanthology.org/2024.nllp-1.18/
Accessed: 2026-09-03
Quote: "casts into doubt their reliability as-is for legal practice"

**contract-eval**
URL: https://aclanthology.org/2025.nllp-1.19/
Accessed: 2026-09-03

**clause**
URL: https://aclanthology.org/2026.findings-eacl.305/
Accessed: 2026-09-03

**legalbench**
URL: https://proceedings.neurips.cc/paper_files/paper/2023/file/89e44582fd28ddfea1ea4dcb0ebbf4b0-Supplemental-Datasets_and_Benchmarks.pdf
Accessed: 2026-09-03

**esign**
URL: https://uscode.house.gov/view.xhtml?req=granuleid:USC-prelim-title15-section7001&num=0&edition=prelim
Accessed: 2026-09-03
Quote: "legally attributable to the person to be bound"

**ueta**
URL: https://legislature.mi.gov/Laws/MCL?objectName=MCL-450-844
Accessed: 2026-09-03
Quote: "determined by the substantive law applicable to the contract"

**visa**
URL: https://developer.visa.com/capabilities/trusted-agent-protocol/trusted-agent-protocol-specifications
Accessed: 2026-09-03

## SYNTHESIS

An LLM can translate legal text, explain differences, collect preferences, and propose a mapping to known clauses. It should not decide that two arbitrary texts are legally equivalent or silently compile prose into an executable policy. The safe boundary is a deterministic validator over exact versioned identifiers and typed constraints, with the model outside the trust boundary. Novel language, conflicts, and jurisdiction questions require explicit human or legal escalation. Agentic-commerce practice supports bounded signed mandates, not open-ended prose autonomy.
