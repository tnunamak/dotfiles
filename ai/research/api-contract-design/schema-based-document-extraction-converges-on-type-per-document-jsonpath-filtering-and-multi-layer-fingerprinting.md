---
title: "Schema-based document extraction converges on type-specific parsers, JSONPath-style filtering, and multi-layer fingerprinting for deduplication"
date: 2026-08-04
topic: api-contract-design
tags: [document-extraction, schema, filtering, fingerprinting, deduplication]
status: draft
sources: [plaid-doc-income, stripe-identity, azure-doc-intelligence]
source_session: 2ddab0f1-d932-40ad-a56f-7058be12fe57
---

## CLAIMS
- Document extraction APIs (Plaid, Stripe, Azure) use schema-per-document-type rather than generic "extract everything" [plaid-doc-income, stripe-identity, azure-doc-intelligence]
- Output filtering uses JSONPath-style include/exclude patterns for PII masking and field selection [design-patterns]
- Multi-layer fingerprinting distinguishes document-level (exact + fuzzy hash) from person-level identity hashing for cross-submission deduplication [design-patterns]
- Tax document extraction endpoints accept optional `output_filter` with `include`/`exclude` JSONPath arrays and optional `schema` override parameter [design-patterns]
- Fuzzy content hashing (ssdeep) catches OCR variations and different PDF exports of the same document; identity hashing (SSN-last-4 + zip + tax year + filing status) catches same person across years [design-patterns]

## SOURCES

**plaid-doc-income**
URL: https://plaid.com/docs/income/document-income/
Accessed: 2026-08-04
Quote: "Pre-built parsers for specific document types (W-2, 1099, paystubs). Optional 'document parsing' feature for raw JSON representation."

**stripe-identity**
URL: https://docs.stripe.com/identity/access-verification-results
Accessed: 2026-08-04
Quote: "Extraction tied to document type (passport, driver's license, etc.). Separate fields for raw extracted data vs. verified outputs."

**azure-doc-intelligence**
URL: https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/prebuilt/tax-document
Accessed: 2026-08-04
Quote: "Pre-built tax document parser with structured field extraction for 1040, W-2, 1099 forms."

**design-patterns**
URL: unknown (synthesized from research)
Accessed: 2026-08-04
Quote: "Schema-guided LLM extraction with optional JSONPath filtering. Multi-layer fingerprinting: file_hash (SHA256) + content_hash (ssdeep fuzzy) + identity_hash (normalized PII subset) + person_hash (cross-year identity)."

## SYNTHESIS

All three platforms (Plaid, Stripe, Azure) reject generic extraction in favor of schema-per-document-type — the structure of a W-2 is predictable and machine-readable, making it more reliable than "extract everything and hope the LLM gets it right."

Filtering strategy converges: include/exclude arrays using JSONPath-style paths (`"**.ssn"`, `"taxpayer.ssn_last4"`) allow consumers to request only the fields they need while redacting sensitive data. This is distinct from the schema definition — the schema defines *what can be extracted*, the filter defines *what the API returns*.

Fingerprinting is multi-layer because single hashes fail:
- Exact SHA256 catches exact duplicates (same file submitted twice).
- Fuzzy ssdeep catches near-duplicates (same document, re-exported PDF, OCR variation).
- Identity hash (ssn_last4 + zip + tax_year + filing_status) catches same person across submissions; person hash (ssn_last4 + name + zip) catches cross-year recurrence.

Implementation pattern: extract with schema → validate fields → compute all four hashes → apply output_filter → return. The filter layer should be post-extraction (don't omit from LLM, filter on response) so extraction can still find sensitive fields for validation before redacting output.

Related: [[jsonpath-filtering-document-extraction-configurable-schema]], [[fingerprint-deduplication-multi-layer-hashing]], [[schema-per-type-extraction-vs-generic]].
