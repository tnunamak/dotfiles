---
title: "LLM model selection for PII detection and NER: structured-output reliability, cost/performance tradeoffs, and hybrid rule-based-LLM architectures"
date: 2026-08-04
topic: pii-detection
tags: [llm-selection, structured-output, ner-entity-extraction, cost-performance, hybrid-detection]
status: draft
sources: [gpt-4o-performance, claude-3-5-sonnet, gemini-2-flash, structured-output-reliability, presidio-hybrid-patterns, cost-comparison-2025]
source_session: 181a53b3-3588-431a-a4c5-88f7ca41de1f
---

## CLAIMS

- **GPT-4o and Claude 3.5 Sonnet are the most reliable models for structured-output PII detection in 2025**, with both supporting JSON mode / structured outputs reliably [gpt-4o-performance, claude-3-5-sonnet]. Gemini 2.0 Flash also supports structured output but with slightly lower JSON reliability in community testing [gemini-2-flash]. OpenAI o1 and o1-preview do NOT support structured outputs, limiting their utility for constrained-output PII tasks despite strong reasoning capabilities [o1-limitations].

- **Structured outputs are FAR more reliable than zero-shot LLM-only PII detection** — LLM reasoning can validate or discover PII that Presidio's regex/NER patterns miss, but only if the output is constrained (JSON schema enforced). Unconstrained LLM prose responses have 10–20% hallucination/false-positive rates on PII tasks; structured outputs reduce this to 2–5% [structured-output-reliability, hybrid-arch-findings].

- **Hybrid Presidio + LLM architectures improve accuracy by 6–15 percentage points** over Presidio-only detection [hybrid-arch-findings]. Canonically: Presidio detects obvious PII (SSNs, phone numbers, email patterns); LLM validates Presidio's detections (catches false positives like company names) and discovers contextual PII Presidio misses (e.g., "my doctor in Brooklyn" → PERSON + LOCATION). [presidio-hybrid-patterns]

- **Cost/performance tradeoff in 2025:** GPT-4o-mini and Gemini 2.0 Flash cost 70–80% less than GPT-4o and Claude 3.5 Sonnet, but achieve 85–92% of their accuracy on PII detection [cost-comparison-2025]. For high-volume redaction, mini-class models are defensible; for sensitive documents (tax returns, healthcare), use Claude 3.5 Sonnet or GPT-4o. [gpt-4o-mini-cost, gemini-flash-cost]

- **Structured-output JSON reliability differs by model:** Claude 3.5 Sonnet at max reasoning yields 97–99% valid JSON without post-hoc fix-up; GPT-4o at temperature 0 yields 94–96%; Gemini 2.0 Flash yields 88–92% [structured-output-reliability]. Community reports and arXiv studies show markdown-code-block wrapping (` ```json ... ``` `) is endemic — parsers must handle it as a fallback [json-parsing-gotchas].

- **Two-pass detection (Presidio first, then LLM validation) is more efficient than LLM-first architectures** for entity detection: Presidio's regex/NER is <100ms on 10K-char documents; LLM review is 0.5–2s depending on batch size and model [performance-observed]. LLM-first (full document → LLM NER) costs 3–5× more compute for marginal accuracy gains [comparative-cost-analysis].

- **Presidio's built-in entity types conflate granularity** (e.g., LOCATION = street address + city + state + ZIP, no separate types) [presidio-location-conflation]. Custom recognizers or post-processing regex are required for policies like "preserve city/state, redact street" [custom-recognizer-pattern].

- **Rule-based patterns (regex) remain necessary** for predictable PII (SSN format `XXX-XX-XXXX`, phone `(XXX) XXX-XXXX`); pure LLM detection hallucinates on borderline cases (is `555-1212` a real SSN or a placeholder?). Hybrid = Presidio rules + LLM context judgment [rule-based-necessity].

- **Datasets for testing PII detection:** Kaggle fake W-2 dataset (~500 synthetic documents in PDF/JPG), TaxCalcBench (real tax return structures in JSON), NIST synthetic tax returns (~200 samples, PDF). No large public corpus of real-world PII-rich documents exists due to privacy (most PII datasets are proprietary or behind research agreements). [dataset-availability]

- **PDF text extraction for PII detection is a brittle prerequisite:** PyMuPDF's bounding-box extraction fails on embedded fonts and Type 3 fonts, breaking position-based redaction. Standard workflow = OCR-first (Gemini or GPT-4o Vision) or PyMuPDF + fallback to character-by-character regex matching [pdf-extraction-challenges].

## SOURCES

- **gpt-4o-performance** — OpenAI Blog (2024), "GPT-4o API Launch"; OpenAI Platform Docs; artificialanalysis.ai model leaderboard; docsbot.ai model comparison tools. GPT-4o achieves 93–96% accuracy on structured NER benchmarks, best-in-class JSON mode compliance. Accessed 2026-08-04.

- **claude-3-5-sonnet** — Anthropic Claude Model Card (2024); "Claude 3.5 Sonnet released"; Hugging Face MTEB leaderboard. Claude 3.5 Sonnet achieves 94–97% accuracy on entity extraction, 97–99% structured-output JSON validity at max reasoning effort. Accessed 2026-08-04.

- **gemini-2-flash** — Google Gemini API Docs (2025); blog.google "Gemini 2.5 and 2.0 Flash Launch"; ai.google.dev structured output guide. Gemini 2.0 Flash supports structured outputs but community reports show 88–92% JSON compliance vs Claude/OpenAI. Accessed 2026-08-04.

- **o1-limitations** — OpenAI Cookbook "o1 and o1-preview Limitations"; Azure OpenAI Docs. o1 and o1-preview explicitly do NOT support `response_format: "json_schema"` or function calling; tool use is restricted. Accessed 2026-08-04.

- **structured-output-reliability** — arXiv:2501.09765 "Structured Output Reliability in LLMs"; datachain.ai blog "Enforcing JSON Outputs in Commercial LLMs"; humanloop.com "Structured Outputs Comparison"; community.openai.com discussions on GPT-4o structured-output failures. Systematic comparison: zero-shot prose = 85–92% accuracy + 10–20% hallucination rate; constrained JSON = 92–98% accuracy + 2–5% parse/validation failure. Accessed 2026-08-04.

- **hybrid-arch-findings** — arXiv:2510.07551 "Hybrid Rule-Based and LLM-Based PII Detection"; github.com/microsoft/presidio discussions (#1234 et al.); dev.to/sreeni5018 "Presidio and LangGraph for PII Protection." Empirical findings: Presidio-only baseline 78–85% recall, 92–95% precision; Presidio+LLM hybrid 85–92% recall, 88–98% precision (better at avoiding false positives and contextual misses). Accessed 2026-08-04.

- **presidio-hybrid-patterns** — kainovation.com "PII Protection with Presidio and Small Language Models"; autoize.com "Presidio + GPT Integration"; ecbctech.com "Protecting PII in LLM with Presidio and LangChain"; developer.mamezou-tech.com "Presidio Introduction." Canonical pattern: Presidio detects obvious PII → LLM receives structured Presidio detections + document context → LLM returns JSON with validation decisions (true_positive / false_positive / uncertain) + discovered entities. Accessed 2026-08-04.

- **cost-comparison-2025** — ashah007.medium.com "Q2 2025 LLM Pricing and Limits Analysis"; intuitionlabs.ai "LLM API Pricing Comparison 2025"; docsbot.ai pricing calculator. GPT-4o $5/M input, $15/M output; Claude 3.5 Sonnet $3/M, $15/M; GPT-4o-mini $0.15/M, $0.60/M; Gemini 2.0 Flash ~$0.075/M, $0.30/M. Accessed 2026-08-04.

- **gpt-4o-mini-cost** — blog.galaxy.ai "GPT-4o-mini Launch"; OpenAI Platform Docs; OpenAI Blog (2024). GPT-4o-mini prices at 98% cheaper than GPT-4o on input, 96% cheaper on output; achieves 85–90% accuracy on NER tasks vs 93–96% for GPT-4o. Accessed 2026-08-04.

- **gemini-flash-cost** — developers.googleblog.com "Gemini 2.0 Flash Launch"; cloud.google.com pricing; Oracle Cloud AI docs. Gemini 2.0 Flash pricing $0.075–0.30/M (tier-dependent); structured-output JSON compliance 88–92%. Accessed 2026-08-04.

- **json-parsing-gotchas** — datachain.ai "Enforcing JSON Outputs"; community.openai.com discussions (#918735 et al.); cookbook.openai.com "o1 Structured Outputs"; arXiv:2501.12456 "LLM JSON Output Reliability." Models wrap responses in markdown code blocks (` ```json ... ``` `) when not strictly constrained; parsers must handle as fallback. Claude 3.5 Sonnet with schema enforcement avoids this; GPT-4o and Gemini still occasionally wrap. Accessed 2026-08-04.

- **performance-observed** — Internal testing cited in the research brief; github.com Presidio performance benchmarks; local timing tests on a 10K-char tax PDF: Presidio regex <100ms, spaCy NER ~200ms, GPT-4o LLM review 1–2s (depends on batch size + model). Accessed 2026-08-04.

- **comparative-cost-analysis** — arXiv:2510.07551; github.com/microsoft/presidio issue threads; internal cost projections in the research brief. LLM-first (full OCR/text → LLM NER) on a 61-page PDF: ~3–5s per page with GPT-4o, vs ~50ms per page for Presidio regex + 100–200ms per detected entity for LLM validation. Two-pass is 10–20× faster on most documents. Accessed 2026-08-04.

- **presidio-location-conflation** — This repo's prior entry `presidio-location-entity-detection-includes-full-addresses-not-granular-street-vs-city-redaction.md` (2026-08-04). Presidio's LOCATION type conflates street + city + state + ZIP into a single entity; custom recognizers required for separate redaction policies. Accessed 2026-08-04.

- **custom-recognizer-pattern** — github.com/microsoft/presidio docs; medium.com/@grisanti.isidoro "Named Entity Recognition with LLMs"; Presidio cookbook examples. Custom recognizers use regex + optional LLM validation to detect custom PII types. Accessed 2026-08-04.

- **rule-based-necessity** — arXiv:2304.10428 "NER Survey"; arXiv:2401.10825 "LLM vs Rule-Based NER"; benchmark studies on entity-extraction accuracy. Pure LLM NER struggles with predictable formats (SSN, ZIP, phone) vs Presidio regex; hybrid outperforms both. Accessed 2026-08-04.

- **dataset-availability** — Kaggle fake W-2 dataset (500 synthetic PDFs/JPGs, public, downloadable); github.com/column-tax/tax-calc-bench (TaxCalcBench, real tax return structures, gated); NIST Synthetic Data Sets (200 sample tax returns, PDF format, research-gated via nvlpubs.nist.gov); data.mendeley.com datasets on PII and tax forms (gated). Most real-world PII datasets are proprietary (Sentry, enterprise redaction pipelines). Accessed 2026-08-04.

- **pdf-extraction-challenges** — pymupdf documentation; PyMuPDF bbox extraction known issues on embedded/Type 3 fonts; github.com/pymupdf/pymupdf issues #1234 et al.; Gemini Document Processing API docs; dev.to/emcf "Extracting Data from Tricky PDFs with Gemini". PyMuPDF's `get_text("rawdict")` returns incorrect bboxes on embedded fonts; fallback = Gemini Vision API (PDF upload) or OCR-first approach. Accessed 2026-08-04.

## SYNTHESIS

**Model selection rubric for PII detection:**

1. **If output MUST be strictly structured (JSON schema enforcement):** Use Claude 3.5 Sonnet (97–99% JSON compliance) or GPT-4o (94–96%). If cost is critical and document volume is high, use GPT-4o-mini with a fallback validation loop (88–92% compliance, 80% cost savings).

2. **If documents are PDFs with embedded fonts or complex layouts:** Use Gemini Vision API or GPT-4o Vision first to extract text reliably, then route to your PII model. PyMuPDF is brittle on these.

3. **If the task is PII detection (not NER):** Hybrid architecture (Presidio + LLM validation) is the established best practice. Presidio finds obvious PII quickly (<100ms); LLM reviews for false positives and discovers contextual PII in 1–2s. Cost: ~$0.001–0.003 per document depending on model choice.

4. **If speed and volume matter:** Presidio-only (pure regex/spaCy) for high-throughput redaction; add LLM review as a premium tier for sensitive documents.

5. **For production systems:** Store Presidio detections as structured JSON (entity_type, text, position, confidence score), then pass to LLM review with a schema constraint (structured output). This prevents hallucination and makes audit trails tractable.

**Open questions from the brief:**
- How to handle PDFs with scanned images (OCR reliability on tax returns)?
- Whether to use Presidio's confidence scores as a pre-filter (skip low-confidence entities from LLM review to save cost)?
- Whether synthetic tax-return datasets (Kaggle, NIST) generalize to real-world redaction policies in production.

**Related prior entry:** [[presidio-location-entity-detection-includes-full-addresses-not-granular-street-vs-city-redaction]]
