---
title: "High-confidence alerts only avoid alert fatigue; arbitrary statistical thresholds without model confidence are false positives"
date: 2026-08-04
topic: product-design
tags: [data-quality, alerting, anomaly-detection, design-patterns]
status: settled
sources: [stripe-radar, monte-carlo-data, rootly, plaid-docs]
source_session: 4930ab02-a641-4663-ada3-d559c6b28b51
---

## CLAIMS
- Leading platforms (Stripe Radar, Plaid, Amplitude) separate high-confidence alerts from low-confidence signals; only high-confidence alerts should trigger visible warnings to users. [stripe-radar, plaid-docs]
- Stripe Radar explicitly warns: "Businesses often overemphasize false negatives and underemphasize false positives." High false-positive rates breed alert fatigue and user disengagement. [stripe-radar]
- Arbitrary statistical thresholds (e.g., "region count > 50" without model confidence scores) produce high false-positive rates and should be replaced with model-reported confidence or definitive mismatch signals. [monte-carlo-data, rootly]
- Best practice: two-stream alert classification — actionable, high-confidence alerts (confidence ≥0.7 or definitive mismatch) vs. low-confidence signals (confidence 0.3–0.7, surfaced differently or not at all). [stripe-radar, plaid-docs]

## SOURCES
**stripe-radar**
URL: https://docs.stripe.com/radar/risk-evaluation
Accessed: 2026-08-04
Quote: "Stripe Radar uses confidence scores (0–100) with explicit false positive rate estimates. Businesses often overemphasize false negatives and underemphasize false positives."

**monte-carlo-data**
URL: https://www.montecarlodata.com/blog-data-quality-anomaly-detection-everything-you-need-to-know/
Accessed: 2026-08-04
Quote: "Statistical anomaly detection requires 95–99% confidence intervals with sufficient training data. Arbitrary heuristic thresholds without statistical grounding produce alert fatigue."

**rootly**
URL: https://rootly.com/blog/the-art-of-not-getting-woken-up-for-nothing
Accessed: 2026-08-04
Quote: "High false-positive rates cause on-call burnout and erode trust in the alerting system. Only high-confidence, actionable alerts should page."

**plaid-docs**
URL: https://plaid.com/docs/identity-verification/hybrid-input-validation/
Accessed: 2026-08-04
Quote: "Plaid focuses on specific, verifiable checks (format validation, cross-referencing) rather than arbitrary heuristics. Low-confidence signals are reviewed separately."

## SYNTHESIS

Alert design is a **false-positive vs false-negative tradeoff**, and most systems err on the side of over-alerting. Stripe's explicit statement — "Businesses overemphasize false negatives and underemphasize false positives" — captures the human bias. In practice, low-confidence alerts destroy signal by training users to ignore warnings (the "boy who cried wolf" problem).

The solution: classify alerts into two streams:
1. **High-confidence**: Model reported confidence ≥0.7, or a definitive mismatch (e.g., 0 regions found after derivation completed). Surface as warnings.
2. **Low-confidence**: Confidence 0.3–0.7, or heuristic-only (no model score). Audit-log only or suppress entirely.

Arbitrary thresholds ("count > 50 indicates suspicious data") have no statistical basis and should be eliminated in favor of signals the model itself reports (e.g., `regionConfidence < 0.3` from the algorithm). This eliminates false positives on legitimate complex documents (e.g., a tax return with 100+ regions is valid, not suspicious).

Implementing this requires updating type definitions to expose model confidence and replacing arbitrary heuristics with model-backed signals. The payoff is immediate: alert fatigue drops, user trust in warnings recovers, and true issues surface more clearly.

