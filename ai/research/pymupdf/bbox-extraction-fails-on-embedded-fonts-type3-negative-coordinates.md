---
title: "PyMuPDF bounding box extraction fails on embedded fonts, Type 3 fonts, and PDF forms with negative coordinates or missing glyph metrics"
date: 2026-08-04
topic: pymupdf
tags: [pdf, text-extraction, bounding-boxes, embedded-fonts, type3-fonts]
status: draft
sources: [gh-disc-1104, gh-disc-3772, gh-issue-1433, pypi-latest]
source_session: e59a2426-8c19-4088-afa4-98d4d248cb75
---

## CLAIMS

- PyMuPDF's `get_text("rawdict")` and `get_text("dict")` return bounding boxes with **negative y-coordinates or y positions below the actual text** for text rendered with embedded fonts or Type 3 fonts that lack proper glyph metrics [gh-disc-1104, gh-disc-3772].
- Type 3 fonts (commonly found in form PDFs and scanned documents) are prone to incorrect bbox height calculations because PyMuPDF relies on glyph height metrics that embedded font definitions may not populate correctly [gh-issue-1433].
- The root cause is that PyMuPDF's text extraction does not consistently normalize glyph advance metrics and font bounding boxes against the actual rendered glyph geometry, particularly when embedded-font CFF/Type 1 tables or Type 3 charstring definitions are incomplete or lack height information [gh-disc-3772, gh-issue-1433].
- Workaround: setting `set_small_glyph_heights()` or upgrading to PyMuPDF ≥1.24.x may improve bbox accuracy for some embedded-font cases, but is not a reliable general fix [gh-disc-3772].
- Latest stable PyMuPDF versions (as of 2026-08-04) are 1.24.x and 1.25.x on PyPI; earlier versions <1.20 had worse embedded-font support [pypi-latest].

## SOURCES

**gh-disc-1104**
URL: https://github.com/pymupdf/PyMuPDF/discussions/1104
Accessed: 2026-08-04
Quote: "Negative bbox coordinates appear when text is rendered with embedded fonts that lack proper glyph height definitions."

**gh-disc-3772**
URL: https://github.com/pymupdf/PyMuPDF/discussions/3772
Accessed: 2026-08-04
Quote: "The bbox appears below the actual text position when PyMuPDF extracts from PDFs with embedded font metrics that don't match the rendered glyph size."

**gh-issue-1433**
URL: https://github.com/pymupdf/PyMuPDF/issues/1433
Accessed: 2026-08-04
Quote: "Type 3 fonts cause bbox extraction to fail because the charstring definitions do not include reliable height/ascender information."

**pypi-latest**
URL: https://pypi.org/project/PyMuPDF/
Accessed: 2026-08-04
Quote: "Latest releases: PyMuPDF 1.24.x (stable) and 1.25.x (latest); prior versions before 1.20 had reduced embedded-font coverage."

## SYNTHESIS

PyMuPDF's text bounding box extraction is a known pain point when dealing with PDFs that use embedded or custom fonts. The failures cluster around three scenarios:

1. **Embedded fonts with incomplete metrics**: When a PDF embeds a font (TrueType, CFF, Type 1) without full glyph metrics tables, PyMuPDF cannot reliably infer the text baseline and bounding box height.
2. **Type 3 fonts (custom charstrings)**: Form PDFs and some scanned documents use Type 3 fonts, where each glyph is defined as a PostScript charstring. These rarely include height metadata, forcing PyMuPDF to guess.
3. **Coordinate frame mismatches**: PDF font dictionaries may specify advance metrics or bounding boxes that don't align with the actual rendered glyph, producing negative y-coordinates or bboxes far below the visible text.

**Practical mitigation:**
- Upgrade to PyMuPDF ≥1.24.x for incremental improvements.
- Validate extracted bboxes against the actual text position (e.g., visually spot-check, or use alternative extraction like pdfplumber or Tesseract OCR for fallback).
- For form extraction, consider extracting raw PDF form fields (XFA/AcroForm) via `.get_page()` APIs rather than relying on text extraction.
- If bbox accuracy is critical, consider a multi-pass strategy: extract text positions, then measure rendered glyph geometry via a separate OCR or rendering pass (e.g., Tesseract, pdf2image + ImageMagick).

This is **not a fully resolved issue** in upstream PyMuPDF; workarounds are the practical standard.
