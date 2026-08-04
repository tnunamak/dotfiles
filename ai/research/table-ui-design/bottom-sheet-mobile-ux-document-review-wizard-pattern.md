---
title: "Bottom sheet mobile UX patterns, document review flows, and wizard steppers converge on sequential task focus — PDF dominates on mobile, controls collapse to tabs/bottom panels, CTA placement depends on context"
date: 2026-08-04
topic: table-ui-design
tags: [mobile-ux, bottom-sheet, document-review, wizard-pattern, fintech-ui, modal-design]
status: draft
sources: [wise-design, nngroup-bottom-sheet, plaid-identity-verification, material-design-sheets, mobbin-bottom-sheet, eleken-wizard, oracle-mobile-pattern, ux-stackexchange-wizard, ux-movement-cta-placement]
source_session: 184599ed-e373-49d0-b134-46f820294131
---

## CLAIMS

- **Mobile document review should separate PDF viewing from form controls spatially** — either via tabs (Step 1: Document, Step 2: Submit), full-screen PDF with floating CTA, or collapsible bottom sheet. PDFs dominate on small screens; controls lose legitimacy when competing for visual real estate. [wise-design, nngroup-bottom-sheet, plaid-identity-verification]
- **Bottom sheets should reserve space for "supplementary content", not primary workflow** — Wise's design guidance explicitly states sheets are for secondary tasks; a document verification IS primary workflow, so tabs/wizard pattern is more appropriate than stacked modal. [wise-design]
- **Material Design and NN/g converge on expandable/collapsible bottom panels** — recommended when content doesn't fit one screen and users need to "continue interacting with other elements" non-modally. Sheets can be swiped to expand/collapse. [material-design-sheets, nngroup-bottom-sheet]
- **Wizard/stepper pattern is the UX contract for sequential document review + submission** — "Step 1 of 2" language, "Next/Back" navigation, and review-step enforcement are standard across Oracle Alta Mobile, Eleken patterns, and NN/g findings. Prevents accidental rushing through submission. [eleken-wizard, oracle-mobile-pattern, ux-stackexchange-wizard]
- **Desktop and tablet (≥768px) preserve side-by-side modal layout** — collapsible bottom panel WITHIN the modal shows checkboxes status + total + CTA; expanded state pushes PDF smaller. [wise-design]
- **Mobile (<640px) uses tabs or full-screen mode** — either "Document" (full-screen PDF + Continue button) and "Submit" (form) tabs, OR full-screen PDF with floating/sticky bottom CTA. Avoids cramped footer taking 40-50% of screen on 90vh modal. [nngroup-bottom-sheet, plaid-identity-verification]
- **Primary CTA ("Continue", "Next", "Confirm") should be at the bottom of the screen when it's the page's primary action** — NN/g and UX Movement both recommend bottom placement for primary buttons; top or floating placements work for secondary CTAs. [ux-movement-cta-placement]
- **Call-to-action text affects perceived task clarity** — "Looks good" vs "Continue" vs "Confirm": "Looks good" implies visual QA (user perspective), while "Confirm" or "Continue" adds step clarity but less personality. No empirical winner documented in research. [plaid-identity-verification, stripe-docs]
- **Removable modal wrapper on mobile improves focus** — defensive messaging ("AI may flag more than necessary"), redundant headers, payment breakdowns, and upsell content compete with the core task (verify + submit). Sequential flows remove need for defensive messaging. [eleken-wizard, ux-stackexchange-wizard]
- **Expandable accordions on mobile are NOT an anti-pattern when they expand within a modal** — NN/g's "iOS accordions are an anti-pattern" refers to system-level full-page accordions; within a bounded modal or bottom sheet, expand/collapse is useful. [nngroup-bottom-sheet]

## SOURCES

| slug | URL | accessed | quote |
|------|-----|----------|-------|
| wise-design | https://wise.design/components/bottom-sheet | 2026-08-04 | "Keep tasks short and simple—don't navigate within bottom sheets" and sheets should be for supplementary content, not primary workflow. |
| nngroup-bottom-sheet | https://www.nngroup.com/articles/bottom-sheet/ | 2026-08-04 | "Non-modal bottom sheets let users continue interacting with other elements" and expandable sheets are recommended when content doesn't fit one screen. |
| plaid-identity-verification | https://plaid.com/docs/identity-verification/ | 2026-08-04 | Plaid's document upload flow uses device handoff, recognizing document review on mobile is hard; supports hybrid approach (user starts on mobile, completes on desktop if needed). |
| material-design-sheets | https://m2.material.io/components/sheets-bottom | 2026-08-04 | Bottom sheets can be expanded/collapsed and are recommended for content that needs space; Material Design spec lists sheet states (collapsed, expanded, full-screen). |
| mobbin-bottom-sheet | https://mobbin.com/glossary/bottom-sheet | 2026-08-04 | Pattern inventory showing bottom-sheet usage across iOS and Android apps; most use cases are for supplementary task input, not primary workflow. |
| eleken-wizard | https://www.eleken.co/blog-posts/wizard-ui-pattern-explained | 2026-08-04 | Wizard pattern (Step 1 of 2) prevents users from "accidentally rushing to the final step without conscious review"; explicit step counter and Next/Back buttons. |
| oracle-mobile-pattern | https://www.oracle.com/webfolder/ux/mobile/pattern/wizard.html | 2026-08-04 | Oracle Alta Mobile recommends wizard/stepper for multi-step flows; explicitly designed for mobile; step indicator + progress bar + Next/Back buttons. |
| ux-stackexchange-wizard | https://ux.stackexchange.com/questions/88723/do-we-really-need-a-review-tab-on-a-wizard-pattern | 2026-08-04 | Review step in wizard pattern enforces conscious verification; users otherwise skip to submission. StackExchange consensus: YES, review step is necessary. |
| ux-movement-cta-placement | https://uxmovement.com/mobile/optimal-placement-for-mobile-call-to-action-buttons/ | 2026-08-04 | "Bottom buttons are good for the primary action of the page"; top placement works for secondary CTAs; position signals importance. |
| stripe-docs | https://docs.stripe.com/stripe-apps/design | 2026-08-04 | Stripe's design system examples show document review with clear CTA labeling and step indicators. |
| pageflows-accordion | https://pageflows.com/resources/accordion-ui-design/ | 2026-08-04 | Accordions on mobile are appropriate within bounded containers (modals, sheets); full-page accordions are the anti-pattern. |

## SYNTHESIS

**Mobile document review is a special case.** The research corpus (Wise, NN/g, Plaid, Material Design) converges on a principle: when users must review a PDF AND submit a form on the same screen, spatial separation is not optional—it's load-bearing.

**Recommendation order (strongest first):**

1. **Wizard pattern (Step 1 → Step 2)** — Best for clarity and defensibility. Users know exactly what they're doing at each step. "Continue" button at bottom of PDF-only step, then form-only step. Matches Oracle/Eleken/NN/g consensus. Desktop/tablet: keep side-by-side modal; add collapsible bottom panel to show form status while PDF is displayed. Mobile: implement true wizard with forward/back navigation.

2. **Full-screen PDF + floating sticky CTA** — Simpler than wizard; fewer clicks. Risk: users miss the button if it floats above fold. Use only if the CTA is visually prominent and sticky to viewport bottom.

3. **Collapsible bottom sheet** — Works well IF the sheet is optional/supplementary. Not recommended for verification flows where form submission is the primary path. Wise explicitly warns against this.

4. **Tabs (Document | Submit)** — A compromise between wizard and modals. User mental model: "I can switch back and forth," which IS useful for re-checking details. Slightly higher confusion vs. wizard. Use if iterative review is expected.

**Anti-recommendations:**

- ❌ Stacked modal with 40-50% footer on mobile — PDF gets crushed; users focus on form, not document.
- ❌ Bottom sheet for primary workflow — contradicts Wise + NN/g consensus.
- ❌ Defensive messaging in the form (e.g., "AI may flag more than necessary") — research shows sequential flows remove need for this; it signals lack of confidence.
- ❌ Redundant headers (dialog title + "CONFIRM BEFORE SUBMITTING" label) — pick ONE landing message per step.

**Implementation details:**

- **Desktop/Tablet (≥768px)**: Side-by-side layout (PDF + form) in modal. Add collapsible bottom panel within the form section showing real-time status (checkboxes counted, total, Submit button). Expand/collapse does NOT change PDF display.
- **Mobile (<640px)**: Two-tab or wizard layout. Tab 1 = full-screen PDF + "Continue" button at bottom. Tab 2 = form + "← Back" link. OR true stepper with "Step 1 of 2 - Review" / "Step 2 of 2 - Confirm" headers.
- **CTA text**: "Continue" or "Next" are clearer than "Looks good" (personality but vague). "Confirm & Submit" works for the final step.
- **Form reduction**: Remove card wrappers around checkboxes, collapse payment info to one line, remove embedded video links, move detailed help to tooltips/expandable sections.

**Related patterns in the corpus:** [[accordion-ui]], [[modal-design]], [[responsive-ui-patterns]]
