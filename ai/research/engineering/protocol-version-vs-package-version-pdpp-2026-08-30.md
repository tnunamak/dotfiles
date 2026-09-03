---
title: "PDP-Connect should decouple connector-protocol's npm SemVer (owned uncontested by semantic-release) from its wire-level protocol identity (an explicit, hand-authored constant checked at runtime) — mirroring the pattern PDP-Connect's own collector-runtime package already ships, every mature spec/SDK ecosystem studied, and today's own reverted 0.0.2 pipeline failure"
date: 2026-08-30
topic: engineering
tags: [semver, protocol-versioning, semantic-release, pdp-connect, connector-protocol, versioning-decision]
status: final
sources: [session-corpus-standards-craft, session-corpus-semrel-monorepo, repo-fork-pin-checks, prior-art-fork-decoupling]
source_session: 714989e4-d512-421b-8ec9-cc514a81eac5
---

## QUESTION

npm registry has `@pdpp/connector-protocol` at `0.0.1`. A PR (data-connect#36, branch
`fix/protocol-stream-evidence-boundary-claim-0828`) hand-bumps `package.json` to `0.0.2`
and claims that number is a "protocol compatibility boundary" via a `BREAKING CHANGE:`
commit footer. `semantic-release`, run for real against that same commit history,
independently computed the next version as `1.0.0-rc.1` — and disagreed with the
hand-edited `0.0.2`, producing an `npm version` / `ETARGET` failure because the
registry's actual last-published version (`0.0.1`) didn't match the working tree's
manual edit (`0.0.2`).

Candidates:
- **(A)** Force the package version to `0.0.2` to match "protocol identity."
- **(B)** Let semantic-release mint `1.0.0-rc.1` (or whatever it computes) uncontested;
  represent protocol/wire identity as an explicit constant, decoupled from package semver.
- **(C)** Something better found in research.

## METHOD

1. Corpus-first: read `ai/research/INDEX.md`, then the two directly relevant existing
   entries — the semver/OAuth/Sigstore/OTel spec-separation entry and the
   semantic-release monorepo-scoping entry (both cited below).
2. Repo reality: a forked agent cloned PDP-Connect/data-connect and data-connectors
   fresh and read the actual pin/gate/identity code, not prose claims.
3. Prior art: a second forked agent researched protobuf/gRPC, Kubernetes client-go,
   OpenAPI, Stripe, and Plaid, plus semantic-release maintainers' own stated position on
   0.x and initial versions. Full capture:
   [[package-semver-vs-protocol-wire-version-decoupling-prior-art-2026-08-30]].
4. Verdict below synthesizes all three.

## REPO REALITY (file:line evidence, from the forked repo-mapping agent)

- **`connector-protocol` package.json version**: `0.0.1` on `main` and on the npm
  registry (confirmed via `npm view @pdpp/connector-protocol version`). The `0.0.2` bump
  exists only on the open PR #36 branch, via commit `cadf936`
  (`fix(protocol)!: version STREAM_EVIDENCE wire additions`), with a
  `BREAKING CHANGE: STREAM_EVIDENCE is shipped as connector-protocol 0.0.2 and requires
  a compatible runtime` footer.
- **data-connectors' actual pin mechanism**: `packages/polyfill-connectors/package.json:35,62`
  pins via `"@pdpp/connector-protocol": "file:./vendor/pdpp-connector-protocol-0.0.1.tgz"`
  — a **vendored tarball filename with the semver string baked into the path**, not a SHA
  and not a protocol constant. A *second*, uncoordinated pin exists elsewhere keyed on a
  git SHA (`9155e57ae`, checked by a CI job called "Check data-connectors' recorded pin"),
  already stale by 6 commits independent of PR #36. Two different pin mechanisms, neither
  aware of the other, both string/path-keyed rather than protocol-identity-keyed.
- **An explicit protocol version constant already exists, fully decoupled from
  package.json, for the OTHER PDP-Connect protocol pairing**:
  `COLLECTOR_PROTOCOL_VERSION = "1"` in
  `packages/collector-runtime/src/collector-protocol.ts:12`, sent as an HTTP header
  (`X-PDPP-Collector-Protocol`) so the reference server can reject an incompatible local
  collector. Plain integer string, own compatibility semantics, no relationship to any
  package.json version. **This is a working, already-shipped precedent for design B
  inside the same repo.**
- **The 1.0.0-rc.1 computation is real, not hypothetical**: PR #36's history shows a
  temporary prerelease-branch config (commit `cd07c84`, reverted as `8d66e6a`) that ran
  semantic-release for real. It found a genuine breaking-change commit
  (`feat(collector-runtime)!: require explicit executionRoot...`) among 78 commits since
  the last tag and computed `1.0.0-rc.1` — correctly, per semver rules, given a `!`-marked
  breaking commit on an already-published `0.0.1` package. The run then failed with
  `npm ETARGET` because `npm version` validated against the registry's real last-published
  version (`0.0.1`), which the manually-edited working tree (`0.0.2`) had silently
  diverged from.
- **The "0.0.2 = protocol boundary" claim is enforced by nothing automated**: it's a
  manual convention — co-editing two package.json fields in the same commit
  (`fix(collector-runtime,connector-protocol): bind legacy-artifact identity and pin
  0.0.2`) — plus a same-commit `artifact.json`/reproducible-build hash mechanism that
  checks build-input reproducibility, not cross-package version agreement. **No code
  anywhere compares `connector-protocol.version === collector-runtime.version` or rejects
  a mismatch.**

## PRIOR ART (full capture in the linked file; summary here)

Every mature ecosystem studied runs package/SDK SemVer and protocol/wire/spec version as
two fully independent identifiers:

- **Protobuf/gRPC**: binary wire format is a stability invariant across both release
  versions and language "editions" — decoupled by design since the 21.x release.
- **Kubernetes client-go**: README states its own SemVer is explicitly *unrelated* to
  the Kubernetes server version it targets; compatibility is a separate published matrix,
  not inferred from the version number.
- **OpenAPI**: maintainers admit they "dropped semver" in practice at 3.1.0 — tooling is
  told to ignore the patch component; the spec's own `openapi:` field has no defined
  relationship to any tool's package version.
- **Stripe** (closest SLVP-class analog): two independent schemes on the same SDK — npm
  SemVer for library code, a date+codename string (`Stripe-Version`) baked into SDK
  source at release time for the API. Explicit guidance: don't infer API compatibility
  from SDK SemVer.
- **Plaid**: identical two-axis pattern — `Plaid-Version` date-based header templated
  into SDK source at release, independent of the SDK's own SemVer.
- **semantic-release maintainers' own stated position** (discussion #1916): for
  pre-1.0 packages under active breaking change, the recommendation is *not* "keep
  breaking changes confined inside 0.x" — it's to skip 0.x releases entirely and use a
  `1.0.0-rc.x`/`beta.x` prerelease channel from the start. The tool computing
  `1.0.0-rc.1` on a real `!`-marked breaking commit is the maintainers' own recommended
  behavior, not a defect to work around.

No production system examined gates wire-level compatibility on `package.json`'s
`version` field. The enforcement mechanism, everywhere, is a constant baked into the
client/SDK at build/release time.

## CORPUS CROSS-REFERENCE (already on file, not re-derived)

- `lfdt-labs-prior-art/standards-that-won-on-craft-...` (2026-07-21): semver, OAuth,
  Sigstore, and OpenTelemetry all keep the *spec* separate from *implementations*;
  OTel's stated design goal is explicit per-language SDK version independence from the
  spec version — the same decoupling principle, one repo-structure level up from this
  question. Already-ratified verdict for PDP-Connect: spec repo split from reference
  impl. This session's question is the same principle applied one level down, inside a
  single package.
- `semantic-release-monorepo-scoping/commit-analyzer-has-no-built-in-scope-filter...`
  (2026-08-20): confirms `@semantic-release/commit-analyzer` has no native scope-gating
  — relevant because any attempt to "protect" `0.0.2` by filtering which commits count
  toward connector-protocol's release requires an explicit `releaseRules` allowlist, not
  a config flag; this is orthogonal machinery to the version-identity question but
  affects implementation of either A or B.

## VERDICT: (B), decouple — confidence 92%

**Do not fight semantic-release's computed package version.** Let it own
`@pdpp/connector-protocol`'s npm SemVer uncontested, including crossing into
`1.0.0-rc.x` if that's what a real breaking-change commit computes. Separately, introduce
an explicit, hand-authored protocol/wire version constant — same shape as the
already-shipped `COLLECTOR_PROTOCOL_VERSION` in `collector-runtime` — checked at runtime
by whatever needs to assert compatibility (e.g. `CONNECTOR_PROTOCOL_VERSION = "2"` or a
`STREAM_EVIDENCE`-aware capability flag), independent of `package.json`. Fix
data-connectors' two uncoordinated pin mechanisms (vendored-tarball filename + stale SHA
file) to key on that constant instead of a version string baked into a file path.

**Why this wins over (A):**
1. It is not hypothetical caution — hand-pinning `0.0.2` already broke the real release
   pipeline in this exact repo, today, on PR #36 (`npm ETARGET`). (A) is a design that is
   currently empirically broken, not merely theoretically risky.
2. PDP-Connect has already independently converged on (B) for its *other* protocol
   pairing (`collector-runtime` ↔ local collector, via `COLLECTOR_PROTOCOL_VERSION`).
   (A) would leave the same repo running two different, contradictory version-identity
   philosophies for its two protocol packages.
3. Every external precedent — protobuf, k8s client-go, OpenAPI, Stripe, Plaid, plus
   semantic-release's own maintainers — converges on the same answer with no
   counterexample found. That's a strong signal this isn't a stylistic preference; it's
   a load-bearing pattern that shows up wherever a package ships both "code that changes
   often" and "a compatibility boundary that must change rarely and explicitly."
4. (A) conflates two things that change at different rates and for different reasons
   (library code edits vs. wire-format compatibility), which is exactly the kind of
   braided concern the code-quality canon says to decomplect, not merge.

**Top counter-argument, stated fairly:** semantic-release computing `1.0.0-rc.1` from a
single breaking-change commit inside an internal, not-yet-externally-consumed monorepo
package could read as a false signal of stability/maturity to anyone skimming npm — "why
is an unreleased internal protocol package already at 1.0"? This is a real, if cosmetic,
cost: version-number semantics ("1.0 means stable") and semantic-release's mechanical
semver-from-commits computation aren't the same thing, and a human reading the number
without context could draw the wrong conclusion. The corpus's own semantic-release
research and the fresh prior-art fork both surface the direct rebuttal: semantic-release
maintainers explicitly recommend *against* trying to keep a package artificially confined
to 0.x once real breaking changes are landing — the fix for the optics concern is a
`1.0.0-rc.x`/`beta.x` prerelease channel (which resolves the "looks too mature" worry
without breaking the tool's computation), not hand-overriding the version number, which
is the specific move that already broke the pipeline.

## RECOMMENDED IMPLEMENTATION SKETCH (not evaluated for full detail — flag for a
follow-up pass if adopted)

1. Revert `connector-protocol`'s package.json to whatever semantic-release would
   naturally compute; let PR #36 run through the real pipeline instead of hand-editing.
2. If the "looks too mature at 1.0" optics matter, configure a `beta`/`rc` prerelease
   branch per semantic-release's own recommended pattern, not a hand-frozen 0.x.
3. Add a `CONNECTOR_PROTOCOL_VERSION` (or capability-flag) constant to connector-protocol,
   mirroring `collector-runtime/src/collector-protocol.ts:12`'s shape, and have consumers
   (data-connectors) assert against that constant, not against `package.json`'s version.
4. Reconcile data-connectors' two pin mechanisms (vendored-tarball filename, stale SHA
   file) into one, keyed on the new protocol constant rather than a semver string
   embedded in a path.
