---
title: "An LLM cannot safely adjudicate a counterparty's free-text terms as an authorization gate, and the live agentic-commerce protocols (Google AP2, OpenAI/Stripe ACP, MCP, A2A) already avoid the problem structurally by making authorization terms typed, bounded, and cryptographically signed rather than natural-language"
date: 2026-09-03
topic: llm-integration
tags: [prompt-injection, agentic-commerce, ap2, acp, mcp, a2a, legal-hallucination, determinism, authorization, verifiable-credentials, pdpp]
status: draft
sources: [ap2-spec, acp-spec, mcp-authorization, a2a-governance-gap, legalbench, cuad-lexglue, dahl-legal-hallucinations, magesh-jels2025, owasp-llm01, willison-lethal-trifecta, prompt-injection-defense-failure, openai-lockdown-mode, thinking-machines-determinism, ueta-esign, berman-v-freedom-financial, gdpr-art22-schufa]
source_session: da53c1ca-0fcc-46b4-9b1a-3e44d3b7159c
---

## CLAIMS

- **Google AP2 (Agent Payments Protocol)** models user-side authorization as **Intent Mandates and Cart Mandates**, each a W3C Verifiable Credential (JSON-LD), signed with ECDSA over P-256+/SHA-256, containing typed and bounded fields — a price ceiling, item/SKU description, delivery address, and a time window for "human-not-present" scenarios (Intent Mandate), or the exact final cart signed by the user for "human-present" scenarios (Cart Mandate). No field in the Mandate schema is evaluated by natural-language interpretation; the schema is designed so no LLM judgment call about ambiguous prose is load-bearing at authorization time. [ap2-spec]
- AP2 was donated to the FIDO Alliance on April 28, 2026 (v0.2), moving to community governance; as of the research date its stated deployment caveat is "AP2 is open source but currently only deployed by Google," with the industry described as watching for Anthropic, OpenAI, and Microsoft to adopt it or ship a compatible competitor. [ap2-spec]
- **OpenAI/Stripe's Agentic Commerce Protocol (ACP)**, released Apache 2.0 September 29, 2025, defines agentic checkout, cart/feed browsing, and delegated payment/authentication mechanics — but defines **no terms/policy data model** at all; the protocol's flagship consumer feature, OpenAI's "Instant Checkout," was reportedly retired in March 2026 after only about a dozen Shopify merchants ever shipped against it. [acp-spec]
- **MCP's authorization spec (stable revision 2025-11-25)** contains no field, extension, or concept for a free-text or structured "terms of service," license, or usage agreement attached to a tool, resource, or grant; its only mention of "consent" is procedural OAuth scope-grant approval ("Server->>User: Display consent page with client_name / User->>Server: Approves access"). Authorization itself is OPTIONAL for MCP implementations. [mcp-authorization]
- A systematic governance-gap analysis of agent-interoperability protocols (MCP, A2A, ACP, ANP, ERC-8004), scored against a six-dimension taxonomy (membership, deliberation, voting, dissent preservation, human escalation, audit/replay), found **voting and dissent preservation universally ABSENT across all five protocols studied**, and deliberation absent-or-partial across the board; for MCP specifically, "no tamper-evident event log, no hash chain, and no replay guarantee" on the audit dimension. [a2a-governance-gap]
- On contract-clause reliability, **LegalBench reports GPT-4/GPT-3.5/Claude-1 achieving ≥88% balanced accuracy on 38 CUAD-derived contract-clause tasks**, and ≥90% on statutory-clause (PROA) tasks — but these are narrow, well-specified classification/extraction tasks (e.g., "does this clause contain a non-compete"), not open-ended interpretation of arbitrary free-text terms for an authorization decision. [legalbench]
- On the harder, more realistic task — locating and extracting the actual clause span rather than classifying a given clause — **CUAD's own native clause-extraction task tops out at roughly 46.8% AUPR (SOTA)**, and CUAD was excluded from the LexGLUE benchmark suite specifically because of "very low F1 scores of all models" and annotation noise judged too severe to include. The gap between LegalBench's 88%+ figures and CUAD's sub-50% AUPR is explained by task shape: simplified binary/classification framings score well; open-ended clause-location/interpretation does not. [cuad-lexglue]
- **Dahl, Magesh, Suzgun & Ho (Journal of Legal Analysis, 2024)** tested general-purpose 2023 models on 800,000+ verifiable legal questions and found hallucination rates of **58% (GPT-4), 69% (GPT-3.5), 88% (Llama 2)**; models "struggle to predict their own hallucinations" and "often uncritically accept users' incorrect legal assumptions." [dahl-legal-hallucinations]
- **Magesh, Surani, Dahl, Suzgun, Manning & Ho (Journal of Empirical Legal Studies, 2025)**, the first preregistered empirical evaluation of RAG-grounded commercial legal-AI tools, found **Lexis+ AI: 65% correct, 17% hallucination rate; Westlaw AI-Assisted Research: 42% correct, 33% hallucination rate**, with a GPT-4 baseline in the same study at 43% hallucination. RAG grounding reduces but does not eliminate hallucination — purpose-built, retrieval-augmented legal AI tools still hallucinate 17-33% of the time. [magesh-jels2025]
- Damien Charlotin's AI Hallucination Cases database (CC0, HEC Paris Smart Law Hub) tracked growth from 87 cases (May 2025) to **1,668 cases by July 2, 2026** (1,163 US, 59 UK; a practicing lawyer was responsible in 653 of them, not just pro se litigants), with pace accelerating to roughly 5-10 new cases per day by mid-2026. [dahl-legal-hallucinations]
- **OWASP's Top 10 for LLM Applications 2025 ranks Prompt Injection (LLM01) #1 for the second consecutive edition**, stating "it is unclear if there are fool-proof methods of prevention for prompt injection," because "LLMs process instructions and data in the same channel without clear separation... the model follows it because it can't tell the difference." Neither RAG nor fine-tuning fully mitigates LLM01. [owasp-llm01]
- Simon Willison's "lethal trifecta" (June 16, 2025) names three co-occurring capabilities that create severe risk: (1) access to private data, (2) exposure to untrusted content, (3) ability to communicate externally. A design where an LLM reads a counterparty's free-text terms (untrusted content) while holding authority to grant/deny access to personal data (private data plus an externally consequential authorization action) sits inside the trifecta by construction. [willison-lethal-trifecta]
- A meta-analysis synthesizing 78 studies (2021-2026) on prompt-injection defenses found **attack success rates against state-of-the-art defenses exceed 85% under adaptive attack strategies**; separately cited industry figures show 50-84% success rates depending on configuration. On Feb 13, 2026, at the launch of its Lockdown Mode, **OpenAI publicly acknowledged that prompt injection in AI browsers "may never be fully patched."** [prompt-injection-defense-failure] [openai-lockdown-mode]
- A production zero-click exploit, EchoLeak (CVE-2025-32711, CVSS 9.3), used a single crafted email to trigger data exfiltration from Microsoft 365 Copilot with no user interaction required, empirically confirming the indirect-prompt-injection threat model in a real deployed system. [prompt-injection-defense-failure]
- **Thinking Machines Lab (Sept 11, 2025)** demonstrated that the same prompt run 1,000 times at temperature 0 in normal production LLM serving produced **80 unique completions**, because reduction kernels (RMSNorm, matmul, attention) lack "batch invariance" — their output depends on the server's live batch size, which fluctuates with load. After replacing three kernels with batch-invariant implementations, all 1,000 runs became bitwise identical, but at a real throughput cost (~61.5% in their baseline implementation; ~34.35% in a follow-up using CUDA graphs). Determinism is achievable only via specific, costly engineering not deployed in standard commercial inference by default. [thinking-machines-determinism]
- **UETA §14 and E-SIGN §7001(h) already validate contracts formed by the interaction of electronic agents** without individual human review — this is not the legal obstacle to LLM-mediated authorization. UETA §14(1): "A contract may be formed by the interaction of electronic agents of the parties, even if no individual was aware of or reviewed the electronic agents' actions or the resulting terms and agreements." [ueta-esign]
- The actual legal obstacle is the doctrine of conspicuous notice plus unambiguous manifestation of assent, established by **Berman v. Freedom Financial Network** (9th Cir., April 5, 2022): a two-part test requiring (1) reasonably conspicuous notice of terms and (2) an unambiguous manifesting action (click/checkbox) directed at those specific, displayed terms. An LLM's probabilistic judgment on free text a human never conspicuously saw inverts both prongs of this test. [berman-v-freedom-financial]
- **GDPR Article 22** governs automated decisions "based solely on automated processing... which produces legal effects... or similarly significantly affects" a data subject, with only three narrow lawful bases (contract necessity, member-state legal authorization, or explicit Art. 9(2)(a) consent). The CJEU's **SCHUFA judgment** closed the "human rubber-stamp" escape hatch: a human formally signing off without real authority to overturn the AI's decision still counts as "solely automated," so genuine, empowered human review is required to exit Article 22 entirely. An LLM autonomously deciding to authorize or deny release of personal data based on free-text terms is a highly plausible Article 22 trigger. [gdpr-art22-schufa]

## SOURCES

**ap2-spec**
URL: https://ap2-protocol.org/specification/
Accessed: 2026-09-03 (via /home/tnunamak/code/pdpp/local/research/_deep-0903/area5-ai-era.md)
Quote: "Each Mandate is a W3C Verifiable Credential, JSON-LD, signed with ECDSA over P-256+/SHA-256 ... Intent Mandate: captures scope/constraints ... e.g., 'buy running shoes, size 10, under $150 ... deliver to my saved address.' ... AP2 is open source but currently only deployed by Google."

**acp-spec**
URL: https://docs.stripe.com/agentic-commerce/acp; https://github.com/agentic-commerce-protocol/agentic-commerce-protocol
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "ACP defines commerce mechanics (cart, payment token, checkout session) — no terms/policy data model. ... OpenAI's 'Instant Checkout' was reportedly retired in March 2026 after only about a dozen Shopify merchants ever shipped against it."

**mcp-authorization**
URL: https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
Accessed: 2026-09-03 (via area5-ai-era.md, fetched directly)
Quote: "Implementations using an HTTP-based transport SHOULD conform to this specification ... Server->>User: Display consent page with client_name / User->>Server: Approves access."

**a2a-governance-gap**
URL: https://arxiv.org/abs/2606.31498 (Kang & Diponegoro, "Governance Gaps in Agent Interoperability Protocols: What MCP, A2A, and ACP Cannot Express")
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "voting and dissent preservation are universally ABSENT across all five protocols studied ... For MCP specifically: 'no tamper-evident event log, no hash chain, and no replay guarantee' on the audit dimension."

**legalbench**
URL: https://proceedings.neurips.cc/paper_files/paper/2023/hash/89e44582fd28ddfea1ea4dcb0ebbf4b0-Abstract-Datasets_and_Benchmarks.html (Guha et al., NeurIPS 2023, arXiv:2308.11462)
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "On the 38 CUAD-derived contract-clause tasks, GPT-4/GPT-3.5/Claude-1 all achieved ≥88% balanced accuracy; on PROA (statutory clauses) GPT-4/GPT-3.5 achieved ≥90%."

**cuad-lexglue**
URL: https://arxiv.org/abs/2103.06268 (CUAD); https://arxiv.org/pdf/2110.00976 (LexGLUE)
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "SOTA AUPR is LOW: original RoBERTa-base ~42.6% AUPR; best improved variant found ~46.6-46.8% AUPR. CUAD was actually excluded from the LexGLUE benchmark suite because of 'very low F1 scores of all models' and annotation noise the LexGLUE authors judged too severe to include."

**dahl-legal-hallucinations**
URL: https://law.stanford.edu/2024/01/11/hallucinating-law-legal-mistakes-with-large-language-models-are-pervasive/ (Dahl, Magesh, Suzgun, Ho, Journal of Legal Analysis 2024, Vol 16 No 1, pp. 64-93); https://www.damiencharlotin.com/hallucinations/
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "Hallucination rates: GPT-4 58%, GPT-3.5 69%, Llama 2 88%. Models 'struggle to predict their own hallucinations' and 'often uncritically accept users' incorrect legal assumptions.' ... 1,668 cases by July 2, 2026 (US: 1,163; UK: 59; practicing lawyer responsible in 653 of them)."

**magesh-jels2025**
URL: https://onlinelibrary.wiley.com/doi/full/10.1111/jels.12413
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "Lexis+ AI: 65% correct, 17% hallucination rate. Westlaw AI-Assisted Research: 42% correct, 33% hallucination rate ... GPT-4 baseline in the same study: 43% hallucination rate."

**owasp-llm01**
URL: https://owasp.org/www-project-top-10-for-large-language-model-applications/assets/PDF/OWASP-Top-10-for-LLMs-v2025.pdf
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "LLM01 Prompt Injection holds the #1 spot for the second consecutive edition ... 'it is unclear if there are fool-proof methods of prevention for prompt injection.'"

**willison-lethal-trifecta**
URL: https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "three capabilities that combined create severe risk — (1) access to private data, (2) exposure to untrusted content, (3) ability to communicate externally ... the model follows it because it can't tell the difference."

**prompt-injection-defense-failure**
URL: (meta-analysis of 78 studies 2021-2026, cited in area5-ai-era.md; EchoLeak CVE-2025-32711)
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "attack success rates against SOTA defenses exceed 85% under adaptive attack strategies ... EchoLeak (CVE-2025-32711, CVSS 9.3) — a single crafted email triggered zero-click data exfiltration from Microsoft 365 Copilot, no user interaction required."

**openai-lockdown-mode**
URL: (OpenAI Lockdown Mode launch, Feb 13, 2026, cited in area5-ai-era.md)
Accessed: 2026-09-03
Quote: "OpenAI itself publicly acknowledged (Feb 13, 2026, Lockdown Mode launch) that prompt injection in AI browsers 'may never be fully patched.'"

**thinking-machines-determinism**
URL: https://thinkingmachines.ai/blog/defeating-nondeterminism-in-llm-inference/
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "the same prompt run 1,000 times at temperature 0 produced 80 unique completions ... After replacing three kernels with batch-invariant implementations, all 1,000 runs became bitwise identical — but at a real performance cost (~61.5% throughput cost in their baseline; SGLang's follow-up reduced this to ~34.35%)."

**ueta-esign**
URL: https://www.law.cornell.edu/uscode/text/15/7001 (E-SIGN §7001(h)); UETA §14 via multiple secondary sources
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "A contract may be formed by the interaction of electronic agents of the parties, even if no individual was aware of or reviewed the electronic agents' actions or the resulting terms and agreements."

**berman-v-freedom-financial**
URL: https://law.justia.com/cases/federal/appellate-courts/ca9/20-16900/20-16900-2022-04-05.html
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "established the modern two-part test: (1) reasonably conspicuous notice of terms, (2) an unambiguous manifesting action (click/checkbox) ... 'tiny gray font,' hyperlink in same color as surrounding text — 'the antithesis of conspicuous.' Held: no enforceable arbitration agreement formed."

**gdpr-art22-schufa**
URL: https://gdpr-info.eu/art-22-gdpr/
Accessed: 2026-09-03 (via area5-ai-era.md)
Quote: "GDPR Article 22 already governs any AI system making automated decisions 'based solely on automated processing... which produces legal effects... or similarly significantly affects' a data subject ... The SCHUFA judgment (CJEU) closed the 'human rubber-stamp' escape hatch — a human formally signing off without real authority to overturn the AI's decision still counts as 'solely automated.'"

## SYNTHESIS

Every dimension of the reliability question points the same direction, and the industry's own live protocol choices confirm it independently of the academic literature. Determinism fails by default (80 unique completions from 1,000 identical-temperature-0 runs, fixable only at real throughput cost). Accuracy fails on the task that actually resembles free-text interpretation — LegalBench's 88-90% figures are on simplified classification, but CUAD's native clause-extraction task (the closer analog to "read this stranger's terms and decide") tops out under 47% AUPR, and even purpose-built RAG-grounded legal tools hallucinate 17-33% of the time. Adversarial robustness fails outright: a free-text term IS attacker-controlled content feeding an authorization decision, which is the textbook prompt-injection surface, and OWASP explicitly declines to claim a fool-proof defense exists. Legal defensibility is weak in a specific, not general, way — UETA and E-SIGN already settled that machines can form contracts, so "no human at the company saw this" is not the barrier; the barrier is that courts have spent twenty years (Specht, Nguyen, Berman) narrowing what counts as valid assent to specific, conspicuously-displayed terms, and an LLM's probabilistic read of unseen free text is the opposite of that pattern, while GDPR Article 22 adds an independent, near-certain regulatory trigger with no rubber-stamp escape.

The strongest piece of evidence is not a paper but a design decision: AP2, the one live system built for real-money agentic authorization, explicitly designed around this problem rather than through it. Its Mandates are typed, bounded, cryptographically signed fields (price ceiling, SKU, address, time window) specifically so no LLM judgment call about ambiguous prose is ever load-bearing at the authorization moment. MCP and A2A do not model terms at all — their only consent concept is OAuth-style scope-grant approval. ACP defines commerce mechanics with no terms model. None of the industry's actual live agentic-commerce infrastructure asks an LLM to adjudicate free text as an authorization gate; the consistent pattern is to make the negotiable surface small, typed, and boundable, and to keep interpretation off the critical path entirely. Any personal-data protocol design that instead proposes "the agent will read the terms and decide" is proposing something no comparable live system has attempted, against a backdrop of research showing every relevant failure mode (determinism, accuracy, adversarial robustness, legal form) working against it.
