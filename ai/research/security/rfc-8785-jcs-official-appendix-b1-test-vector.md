---
title: "RFC 8785 (JSON Canonicalization Scheme) Appendix B.1 defines one official test object with input JSON and exact canonical output, plus 24 numeric edge-case vectors in Appendix B; number serialization defers to ECMA-262 §7.1.12.1 (with the 'Note 2' enhancement, i.e. V8/Ryu-style shortest-round-trip formatting) rather than a formula spelled out in the RFC itself"
date: 2026-09-02
topic: security
tags: [rfc8785, jcs, canonicalization, json, sha256, digest]
status: draft
sources: [rfc-editor-rfc8785]
source_session: 03595863-20c7-4f59-bc87-ec10762276f9
---

## CLAIMS

- RFC 8785 §3.2.2's worked test object input is: `{"numbers": [333333333.33333329, 1E30, 4.50, 2e-3, 0.000000000000000000000000001], "string": "€$
A'B"\\\\"\/", "literals": [null, true, false]}`. [rfc-editor-rfc8785]
- The official canonical output for that object is: `{"literals":[null,true,false],"numbers":[333333333.3333333,1e+30,4.5,0.002,1e-27],"string":"€$\nA'B\"\\\\\"/"}` — note the string value round-trips `B`→`B`, `"`→escaped `\"`, `\`→escaped `\\`, and the literal `\\\"` source sequence produces a doubled backslash before the closing escaped quote in the canonical form. [rfc-editor-rfc8785]
- RFC 8785 §3.2.2.3 mandates number serialization "according to Section 7.1.12.1 of [ECMA-262], including the 'Note 2' enhancement" and explicitly declines to spell out the algorithm itself ("Due to the relative complexity of this part, the algorithm itself is not included in this document"), instead pointing implementers to reference implementations like V8 or the Ryu algorithm. [rfc-editor-rfc8785]
- Appendix B provides 24 additional IEEE-754 double-precision sample values with their expected canonical JSON number strings, covering edge cases (zero, min/max magnitude, round-to-even rounding, e.g. one vector rounds to `"1424953923781206.2"`). [rfc-editor-rfc8785]

## SOURCES

**rfc-editor-rfc8785**
URL: https://www.rfc-editor.org/rfc/rfc8785.txt
Accessed: 2026-09-02
Quote: "Canonical Output: {\"literals\":[null,true,false],\"numbers\":[333333333.3333333,1e+30,4.5,0.002,1e-27],\"string\":\"€$\\u000f\\nA'B\\\"\\\\\\\\\\\"/\"}"

## SYNTHESIS

For a Node.js/V8 implementation, `String(number)` on a finite `number` genuinely *is* the ECMA-262 §7.1.12.1 abstract operation (V8 implements this natively), so naive `String()`-based number formatting already agrees with RFC 8785 for all 24 Appendix B vectors plus the worked example — verified locally against hand-reconstructed vectors from this fetch. The real risk area for a from-scratch JCS implementation is therefore NOT number formatting but (a) never having tested against the RFC's own published vectors (self-authored "golden vectors" are not independent proof), and (b) string/Unicode edge cases the RFC is stricter about than a casual `JSON.stringify`-based implementation: RFC 8785 requires canonicalization to fail/terminate on invalid Unicode (e.g. unpaired UTF-16 surrogates) rather than silently emitting a `\uD800`-style escape, since malformed UTF-16 cannot be re-encoded to valid UTF-8 (RFC 8785's normative serialization is UTF-8). A conformant implementation must validate surrogate pairing in both object keys and string values and throw rather than degrade.
