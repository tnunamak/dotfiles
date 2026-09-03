---
title: "Manylinux, Node's prebuild ecosystem, and Go static linking establish ABI tag schemas plus build-time/CI audits for native binary portability, but no mainstream ecosystem verifies compatibility by executing the artifact on the real target before install"
date: 2026-08-17
topic: connectors
tags: [native-binaries, glibc, manylinux, abi-compatibility, prebuild, static-linking, install-time-verification, sidecar-binaries]
status: draft
sources: [pep600, pep513, pep599, packaging-tags-docs, manylinux-repo, auditwheel-issue67, prebuild-install-repo, prebuildify-repo, node-gyp-build-repo, nodejs-abi-stability, go-static-eli-bendersky, go-cgo-pure-go-alt, honnef-musl-static, homebrew-test-bot-docs, homebrew-security-docs]
source_session: unknown
---

## CLAIMS

- PEP 600 ("perennial manylinux") defines the `manylinux_x_y` tag format where `x_y` is a glibc major.minor floor (e.g. `manylinux_2_24` = works on any distro with glibc ≥ 2.24), replacing the old scheme of one PEP per named tag (manylinux1/2010/2014). [pep600]
- The floor logic relies on glibc's own upstream guarantee of backward compatibility (new glibc runs old binaries), so PEP 600 replaced version-branch comparison logic with a simple "wheel's declared floor ≤ runtime's glibc version" check. [pep600]
- A `manylinux_x_y`-tagged wheel must not reference glibc symbols newer than its declared floor, and must not link against a non-glibc libc (e.g., musl) — musllinux is a separate, parallel tag namespace. [pep600]
- PEP 513 explicitly states that pip/PyPI are NOT expected to enforce the manylinux policy; the policy exists "as advice to package builders, and as a method for allocating blame" — if a wheel satisfies the policy but still fails on some system, it's a spec/tool bug; if the wheel violates the policy, it's the wheel's bug. [pep513]
- pip's actual runtime check (in vendored `packaging`) is a lightweight, optimistic heuristic, not an ABI audit: it looks for an optional `_manylinux` module for an explicit compatibility signal, and otherwise falls back to comparing the host's glibc version number against the wheel's tag, defaulting to "compatible" when uncertain. [packaging-tags-docs]
- The actual compatibility guarantee is pushed to build time: `auditwheel` (a static analysis tool) inspects the compiled extension's shared-library dependencies and versioned symbols (via ELF symbol version tables) and either bundles/vendors external `.so`s or fails the build if symbols exceed the declared policy floor. [auditwheel-issue67]
- `auditwheel show` reports external versioned symbols an extension references (e.g., `GLIBC_2.3`, `GLIBCXX_3.4.20`) against the allowed set for a target policy, and `auditwheel repair` can vendor missing shared libraries into the wheel; both operate on the compiled artifact, not by executing it on a target machine. [auditwheel-issue67]
- The manylinux project ships pinned, deliberately old-glibc/old-toolchain Docker build images (historically CentOS 5/6/7-based) so that any extension compiled inside them can only pick up old symbol versions by construction — this is the shared build-infrastructure equivalent that removes the burden of manually tracking a symbol floor from individual package authors. [pep599]
- Node's `prebuildify`/`prebuild-install`/`node-gyp-build` stack tags prebuilt binaries by platform, arch, Node ABI (or N-API version), and — critically for Linux — libc family: non-glibc (musl) Linux builds get a distinct tag/directory (`linuxmusl`) so an Alpine/musl host does not silently receive a glibc-linked binary. [prebuild-install-repo] [node-gyp-build-repo]
- Libc family detection in the Node prebuild ecosystem is handled by a small dedicated package (`detect-libc`) that inspects the running system (not just OS/arch) specifically because early tooling defaulted to assuming glibc universally and downloaded broken prebuilds on musl hosts. [prebuild-install-repo]
- N-API (Node-API) is Node's ABI-stable native-addon interface: a module built against N-API for a given major version loads without recompilation across any later Node minor/patch of that major line (and across major lines in practice, since N-API versioning is cumulative/additive), because it deliberately shields addons from V8/engine-internal ABI churn that changes every major Node release. [nodejs-abi-stability]
- Non-N-API native addons remain tied to `NODE_MODULE_VERSION`; a mismatch (e.g., built for Node 18, loaded under Node 20) throws only at first `require()`/load time, not at install or build time — the same class of "looked fine at build, broke at runtime" failure the incident hit with glibc/libsecret. [nodejs-abi-stability]
- Go's `CGO_ENABLED=0` produces a fully static binary with no shared-library dependencies (no glibc, no libresolv, etc.), eliminating the runtime-glibc-floor problem entirely for pure-Go code paths. [go-static-eli-bendersky]
- A `CGO_ENABLED=0` (or `-tags netgo`) binary loses libc-mediated OS integration: the pure-Go DNS resolver does not support all NSS plugins (custom LDAP/mDNS/Winbind lookups), and packages like `os/user` that shell out to libc's NSS-based user database lose functionality or behave differently. [go-cgo-pure-go-alt]
- Static linking cannot solve dlopen-based dynamic plugin loading: NSS switch modules, PAM stack modules, and libsecret's Secret Service D-Bus/keyring backends are all loaded via `dlopen()` of `.so` plugins at runtime by the (glibc) libc/library itself — a statically linked binary that doesn't itself link glibc has no glibc `dlopen()` machinery to invoke these plugins through, so this class of dependency cannot be made static away. [go-cgo-pure-go-alt]
- Attempting to bridge this by having a CGO-disabled Go binary manually FFI-call into a glibc-linked shared library (e.g., libsecret) directly is a documented footgun: glibc uses the `%fs` segment register for its own pthread thread-local-storage on x86_64, but without cgo's runtime initialization the Go scheduler is using `%fs` for its own goroutine-pointer instead, so the first glibc call that touches TLS (including inside `dlopen`) crashes by misinterpreting Go's `g` pointer as a pthread struct. Tools like `purego` and `fakecgo` exist specifically to reimplement the cgo TLS setup glibc expects, precisely to make this kind of dynamic-library call survivable. [go-cgo-pure-go-alt]
- musl-based static Go builds (`CC=musl-gcc`, `-linkmode external -extldflags "-static"`, typically inside an Alpine build image) are the standard alternative when cgo is required (e.g., for cgo-dependent packages) but full static output is still wanted; musl itself does not support NSS, so a musl-static build has the same NSS-plugin limitation as the pure-Go/`netgo` path — this is a documented, known tradeoff, not a workaround. [honnef-musl-static]
- Homebrew's `brew test-bot` builds each formula from source and produces "bottles" (precompiled binaries) on Homebrew-operated CI runners covering the real macOS/Linux target matrix, and most end users install the pre-tested bottle rather than running the build/install script locally — this shifts execution-verification to CI machines that are stand-ins for real targets, but it is still not a check of the actual end-user's exact runtime environment at install time. [homebrew-test-bot-docs]
- Homebrew's own documentation contrasts this model directly against npm/PyPI: both npm's pre/postinstall lifecycle scripts and PyPI's arbitrary `setup.py` execution run publisher-controlled code directly on the installing machine by design — meaning npm/pip already have a general mechanism (arbitrary code execution at install time) that COULD run a smoke probe, but neither ecosystem has a standardized, ecosystem-blessed convention that does so specifically to gate native-binary ABI acceptance. [homebrew-security-docs]
- No source found in this research describes pip, npm's prebuild tooling, or Go's module system performing a mandatory "execute the downloaded binary against a declared smoke command on the real installation target, and reject/fall back on failure" step as a first-class, standardized install-time gate. `node-pre-gyp`'s documented fallback-to-source-compile-on-failure is the closest common pattern found, but it is triggered by prebuild absence/download failure, not by an executed correctness probe. [prebuild-install-repo]

## SOURCES

**pep600**
URL: https://peps.python.org/pep-0600/
Accessed: 2026-08-17
Quote: "A wheel may never use symbols from a newer version of glibc than that indicated by its tag... if a wheel is tagged as manylinux_glibc_2_Y, then users can be reasonably confident that this wheel will work in any real-world linux-based python environment that uses glibc 2.Y or later."

**pep513**
URL: https://peps.python.org/pep-0513/
Accessed: 2026-08-17
Quote: "These recommendations do not suggest that pip or PyPI should attempt to check for and enforce the details of this policy, just as they don't check for and enforce the details of existing platform tags like win32... the policy is... a method for allocating blame."

**pep599**
URL: https://peps.python.org/pep-0599/
Accessed: 2026-08-17
Quote: "A manylinux2014 Docker image based on CentOS 7 x86_64 should be provided for building binary linux wheels that can reliably be converted to manylinux2014 wheels."

**packaging-tags-docs**
URL: https://packaging.python.org/specifications/platform-compatibility-tags/
Accessed: 2026-08-17
Quote: "manylinux_x_y (PEP 600) supersedes all previous PEPs to define a future-proof standard... if the platform has glibc 2.17 or newer, it is assumed compatible unless the _manylinux module says otherwise."

**manylinux-repo**
URL: https://github.com/pypa/manylinux
Accessed: 2026-08-17
Quote: "Python wheels that work on any linux (almost)"

**auditwheel-issue67**
URL: https://github.com/pypa/auditwheel/issues/67
Accessed: 2026-08-17
Quote: "auditwheel show identifies whether a wheel is consistent with a platform tag and lists external versioned symbols found in system-provided shared libraries."

**prebuild-install-repo**
URL: https://github.com/prebuild/prebuild-install
Accessed: 2026-08-17
Quote: "On non-glibc Linux platforms, the Libc name is appended to platform name" (e.g. `linuxmusl`); libc detection motivated musl/Alpine hosts otherwise receiving broken glibc-built prebuilds by default.

**prebuildify-repo**
URL: https://github.com/prebuild/prebuildify
Accessed: 2026-08-17
Quote: "filenames of prebuilds are composed of tags which by default include runtime and either napi or abi version (for example: electron.abi40.node)."

**node-gyp-build-repo**
URL: https://github.com/prebuild/node-gyp-build
Accessed: 2026-08-17
Quote: "Values for the libc and armv tags are auto-detected but can be overridden through the LIBC and ARM_VERSION environment variables."

**nodejs-abi-stability**
URL: https://nodejs.org/en/learn/modules/abi-stability
Accessed: 2026-08-17
Quote: "Node.js native addons compiled against a given major version of Node.js will load successfully when loaded by any Node.js minor or patch version within the major version against which it was compiled... other Node.js interfaces such as libuv are not ABI-stable across Node.js major versions."

**go-static-eli-bendersky**
URL: https://eli.thegreenplace.net/2024/building-static-binaries-with-go-on-linux/
Accessed: 2026-08-17
Quote: "the cgo binary dynamically links against libresolv.so.2, libc.so.6, and other glibc libraries, while the CGO_ENABLED=0 binary is fully static with no shared libraries at all."

**go-cgo-pure-go-alt**
URL: https://peng.fyi/post/go-cgo-enabled-default-and-pure-go-alternatives/
Accessed: 2026-08-17
Quote: "the pure-Go DNS resolver doesn't support all NSS plugins... glibc uses the %fs segment register on x86_64 for its own pthread TLS block... without cgo init the Go scheduler uses %fs for its own g pointer instead, and calling dlopen or malloc crashes."

**honnef-musl-static**
URL: https://honnef.co/articles/statically-compiled-go-programs-always-even-with-cgo-using-musl/
Accessed: 2026-08-17
Quote: "musl doesn't support NSS, so using musl's DNS resolver is not much different from using netgo."

**homebrew-test-bot-docs**
URL: https://docs.brew.sh/BrewTestBot
Accessed: 2026-08-17
Quote: "brew test-bot will ensure the system is cleaned and set up to test the formula, install the formula, run various tests and checks on it, bottle (package) the binaries."

**homebrew-security-docs**
URL: https://docs.brew.sh/Homebrew-Security-and-Supply-Chain
Accessed: 2026-08-17
Quote: "both npm (preinstall/postinstall lifecycle scripts) and PyPI (arbitrary code in setup.py) execute publisher-controlled code on the installing machine by design... the vast majority of users install bottles... rather than running upstream build scripts on their own machine."

## SYNTHESIS

Every mature ecosystem studied here converges on the same two-part answer to "prebuilt binary across environments I can't see": (1) a declarative ABI tag that encodes the compatibility floor (glibc x.y version, libc family, Node ABI/N-API version), and (2) a build-time-only audit that verifies the artifact against that floor by static analysis (auditwheel's symbol-version scan) or by construction (a pinned old-toolchain build image, an ABI-stable interface like N-API, full static linking). None of them — pip/manylinux, Node's prebuild stack, Homebrew's bottling, or Go's build tooling — treats "execute the artifact on the real target and check it actually runs" as a first-class install-time gate. PEP 513 says this outright: enforcement is explicitly punted, and the policy exists only to allocate blame after the fact. Containers "solve" the problem by collapsing build-target and run-target into the same environment, which is not available to a personal-data-platform connector shipping to arbitrary user machines.

This is exactly the gap the incident hit: a binary that satisfies "compiles clean" and even "matches a symbol-version audit" can still fail at runtime for two structurally different reasons — a missing shared library entirely (libsecret-1.so.0 not installed) versus a present-but-too-old shared library (GLIBC_2.38 symbol vs 2.36 runtime) — and neither failure mode is caught by anything upstream ecosystems consider sufficient. Static linking (Go's `CGO_ENABLED=0`/musl) removes glibc-floor risk entirely for pure-Go code, which is why it should be the default posture for connector sidecars — but it cannot remove the dependency for tools that need `dlopen()`-based OS integration (libsecret Secret Service access, PAM, keychain equivalents), because those are inherently dynamic-loading contracts the OS provides, not something Go's linker can absorb. For those cases, dynamic linking against system libraries is unavoidable and the compatibility floor must be declared and checked, not assumed away by "it built."

Given that no ecosystem's *convention* already solves execute-on-target verification, the design direction described in the incident (a declared smoke probe executed on the real runtime before acceptance) is not redundant with prior art — it is filling a real, named gap. Recommended minimal tag schema, modeled directly on the manylinux/prebuildify precedent:

```
{
  "os": "linux",
  "arch": "amd64",
  "libc": "glibc",            // or "musl" — mirrors prebuildify's linuxmusl tag
  "libc_floor": "2.38",        // mirrors manylinux_x_y; omit/null if statically linked
  "linkage": "dynamic",        // "static" | "dynamic"
  "smoke_cmd": "slackdump --version && slackdump doctor --check-secret-service"
}
```

Verification steps a connector registry should adopt, in order of cost:
1. **Prefer static linking** (`CGO_ENABLED=0`, or musl-static) whenever the tool has no genuine `dlopen()`-based OS dependency — this is strictly Go's version of manylinux's approach of removing the variable rather than managing it, and it is unverified-but-likely that most Go CLI sidecars (slackdump-class tools) fall into this bucket unless they specifically need a system keyring.
2. **When dynamic linking is unavoidable** (libsecret, PAM, keychain), declare the tag schema above and build inside a pinned old-glibc image (a manylinux-equivalent), so the floor is a controlled build property, not a discovered one.
3. **Execute the declared `smoke_cmd` on the actual install target before accepting the binary**, treating non-zero exit or a missing-library dynamic-linker error as an install failure with a clear message (missing lib vs. too-old symbol are distinguishable from `ldd`/loader error text) rather than a silent success followed by a later runtime crash. This is the one step no surveyed ecosystem does as a standard, and it directly would have caught both failure modes in the incident (missing `libsecret-1.so.0` and the GLIBC_2.38-vs-2.36 mismatch) at install time instead of first invocation.
4. **Fall back to a source build or an alternate (musl-static/pure-Go) variant on smoke-probe failure**, mirroring `node-pre-gyp`'s prebuild-absent fallback pattern, so a floor mismatch degrades gracefully instead of hard-failing the connector.

Shared build infrastructure (a manylinux-image equivalent — one or a small number of pinned old-glibc Docker images used for all connector sidecar builds) buys authors the same thing it buys the Python ecosystem: individual connector authors stop needing to personally track "what's the oldest glibc my users might have," because the floor becomes a property of the shared image, verified once, reused everywhere. Unverified: whether `node-pre-gyp`'s "fallback to source compile" is triggered only by download/network failure or also by a failed prebuild smoke test in some configurations — the search here did not turn up its exact fallback trigger logic, only prior documented feature requests for musl/libc-aware tagging.
