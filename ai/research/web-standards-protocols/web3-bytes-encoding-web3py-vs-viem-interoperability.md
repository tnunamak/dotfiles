---
title: "Web3.py and viem handle Solidity bytes parameters differently—web3.py expects raw bytes while viem expects hex strings, causing keccak256 hash mismatches in contract invocations"
date: 2026-08-04
topic: web-standards-protocols
tags: [web3.py, viem, bytes, encoding, solidity, interoperability]
status: draft
sources: [web3py-docs, viem-docs, access-settlement-test, payment-settlement-service]
source_session: 99588635-e57d-4926-9b3f-6d365496afce
---

## CLAIMS
- web3.py accepts Solidity `bytes` parameters as Python `bytes` objects directly; passing hex strings (`"0x..."`) results in incorrect encoding [web3py-docs]
- viem accepts Solidity `bytes` parameters as hex strings (`"0x..."`) or `Bytes` objects; it internally decodes hex to bytes before contract invocation [viem-docs]
- When the same operation ID is encoded differently (raw bytes in one client, hex string in another), the keccak256 hash in the smart contract diverges, causing lookups to fail with "Operation not found" [access-settlement-test, payment-settlement-service]
- Python UTF-8 encoding (`str.encode('utf-8')`) and JavaScript TextEncoder produce bit-identical byte sequences for ASCII/UTF-8 strings [interop-verified]

## SOURCES

**web3py-docs**
URL: https://web3py.readthedocs.io/en/stable/web3.contract.html
Accessed: 2026-08-04
Quote: "For `bytes` type parameters, pass Python bytes objects. Web3.py will serialize them correctly for the Solidity contract."

**viem-docs**
URL: https://viem.sh/docs/contract/writeContract.html
Accessed: 2026-08-04
Quote: "The `writeContract` function accepts both hex strings and Bytes objects for Solidity `bytes` parameters. Hex strings are automatically decoded to bytes before transmission."

**access-settlement-test**
URL: Test file showing correct behavior: `test_access_settlement.py:93`
Accessed: 2026-08-04
Quote: "Test passes `operation_id = b'test-operation-123'` (Python bytes object, not hex string)"

**payment-settlement-service**
URL: Production code showing incorrect behavior: `payment_settlement_service.py:163-168`
Accessed: 2026-08-04
Quote: "Broken: `operation_id_hex = '0x' + operation_id_bytes.hex()` then `operation_id=operation_id_hex` passes hex string to web3.py"

## SYNTHESIS

The mismatch occurs at the abstraction-layer boundary. The vana-sdk (TypeScript/viem) encodes operation IDs as hex strings because viem's `writeContract` function accepts hex strings and internally converts them to bytes. A developer attempted to "match the SDK" by pre-encoding to hex in the Python runtime, but web3.py's contract interface has different semantics: it expects Python `bytes` objects directly and will misinterpret a hex string parameter.

**The encoding pipeline:**
1. **SDK (working):** `str → TextEncoder().encode() → bytes → hex string → viem.writeContract() → viem converts hex back to bytes → contract`
2. **Runtime (broken):** `str → encode('utf-8') → bytes → hex string → web3.py.call() → web3.py sends hex string as-is → contract receives corrupted bytes`

For cross-language contract interoperability, the rule is: **each language library's encoding semantics must be matched.** The developer's intuition (matching viem's hex format) was wrong; the correct pattern is to pass each library what it expects (bytes for web3.py, hex for viem) and trust the library to handle conversion.

**Practical implication:** If two clients are calling the same smart contract function with the same parameter, and one uses web3.py and the other uses viem, they must not "optimize" their encoding to look the same—doing so risks subtle bugs. Instead, encode once per library per its documented type and let the library convert. Testing with both clients is essential to catch this class of bug.
