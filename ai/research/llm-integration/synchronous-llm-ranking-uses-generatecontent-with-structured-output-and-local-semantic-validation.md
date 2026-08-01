---
title: "Synchronous LLM ranking uses GenerateContent with structured output and local semantic validation"
date: 2026-07-10
topic: llm-integration
tags: [gemini, generatecontent, structured-output, ranking, validation]
status: draft
sources: [gemini-structured-output, gemini-batch-api]
source_session: 019f4eef-c376-7351-a499-0ce35f7cdf8a
---

## CLAIMS

- Gemini structured output is intended for structured classification and supports JSON schema constraints, but Google says applications must still validate semantic correctness and handle errors. [gemini-structured-output]
- Gemini's Batch API is asynchronous, has a target turnaround of 24 hours, and is intended for non-urgent large-volume work. [gemini-batch-api]

## SOURCES

**gemini-structured-output**
URL: https://ai.google.dev/gemini-api/docs/generate-content/structured-output?hl=en
Accessed: 2026-07-10
Quote: "Always validate the final output in your application code before using it."

**gemini-batch-api**
URL: https://ai.google.dev/gemini-api/docs/batch-api
Accessed: 2026-07-10
Quote: "The target turnaround time is 24 hours."

## SYNTHESIS

Interactive ingest ranking should send the extracted candidate list through GenerateContent in a small number of structured JSON calls, then reject unknown identifiers, invalid tags, non-finite scores, and non-verbatim receipts locally. Batch API is inappropriate for a request that must complete inside the route duration.
