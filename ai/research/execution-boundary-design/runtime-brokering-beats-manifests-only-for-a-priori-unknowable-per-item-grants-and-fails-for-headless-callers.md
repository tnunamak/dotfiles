---
title: "XDG portals, Android SAF, and iOS security-scoped bookmarks all broker capability grants via a trusted-outside-the-sandbox proxy (file descriptor or persisted URI) rather than a manifest, specifically for user-picked-at-runtime items a manifest cannot predict — but every implementation documents the same four costs (dialog fatigue, IPC latency, broker-trust risk, finite grant ceilings) and none support headless/daemon-style callers without a visible window"
date: 2026-08-17
topic: execution-boundary-design
tags: [xdg-desktop-portal, flatpak-portals, android-scoped-storage, storage-access-framework, ios-security-scoped-bookmarks, wasi-capabilities, runtime-brokering]
status: draft
sources: [xdg-portal-docs, xdg-openuri-portal, xdg-documents-portal, flatpak-portal-hybrid, flatpak-headless-discussion, android-saf-docs, android-saf-perf, ios-security-scoped, wasi-tutorial, wasmtime-overlap-issue, ios-security-scoped-bookmark-forum-dts, ios-security-scoped-cap, wasi-cve-2025-53901, wasi-design-lineage]
source_session: 8aa4436f-6d97-4d7d-a0b9-7b23964cafdf
---

## CLAIMS

- XDG Desktop Portal exposes D-Bus interfaces under `org.freedesktop.portal.Desktop`; every portal call returns a `Request` object handle, with completion signaled later via a `Response` D-Bus signal rather than a synchronous method return, because portal calls may involve a user dialog that exceeds a normal D-Bus method-call timeout. The frontend (`xdg-desktop-portal`, sandbox-facing) delegates to a desktop-specific backend implementing `org.freedesktop.impl.portal.*` (GTK for GNOME, Qt for KDE); this split exists because Flatpak's D-Bus proxy, once permitted to talk to one name, implicitly permits talking to any name owned by that connection, so the sandbox-facing and backend-facing buses must be kept separate. [xdg-portal-docs]
- The `OpenURI` portal's `OpenFile` and `OpenDirectory` methods take an already-open file descriptor (`IN fd h`) as their argument, not a path string — the fd itself is the proof of access, since the caller could only have an open fd because the portal's own picker UI (running outside the sandbox) opened it on the user's behalf. [xdg-openuri-portal]
- The document portal (`org.freedesktop.portal.Documents`) implements a FUSE filesystem mounted at `/run/user/[UID]/doc` on the host (visible inside the sandbox at `/run/flatpak/doc`); its `Add`/`AddFull` methods require an already-open fd as proof of access (an anti-confused-deputy design — the portal cannot be tricked by a caller-supplied path string alone), while `AddNamed` is a separate method for granting write access to a new file that doesn't exist yet. `GrantPermissions` sets POSIX bits directly on the FUSE view, so enforcement is delegated to the kernel's normal permission checks rather than a separate portal-side ACL re-check per syscall. [xdg-documents-portal]
- Flatpak's static `finish-args` manifest declarations (e.g. `--filesystem=xdg-documents`, `--filesystem=home`) and the runtime portal brokering system are independent, additive grant sources — the portal does not consult `finish-args` to decide whether to prompt; a `finish-args` grant simply means the app has direct sandbox filesystem access and never needs to go through the portal for that path. Flatpak's own documentation recommends favoring portals over broad `finish-args` grants wherever possible. [flatpak-portal-hybrid]
- A documented genuine hybrid exists for device access: the manifest's `finish-args` declares which device *types* are eligible to be enumerated at all, and the portal then brokers actual per-device runtime access on top of that — manifest narrows the menu, portal grants the specific item. [flatpak-portal-hybrid]
- `xdg-desktop-portal` discussion #1148 documents that GNOME's portal backend refuses to show permission dialogs to apps without a visible/focused window, which breaks headless/daemon-style apps (cited example: Flameshot, a screenshot daemon) — motivating a proposal to add manifest-declared, portal-mediated startup permissions as a supplement, explicitly inspired by Android's install-time permission dialog. [flatpak-headless-discussion]
- Android scoped storage (introduced Android 10/API 29) replaced broad `READ_EXTERNAL_STORAGE`/`WRITE_EXTERNAL_STORAGE` grants with the Storage Access Framework for out-of-scope access; a URI from `ACTION_OPEN_DOCUMENT`/`ACTION_OPEN_DOCUMENT_TREE` is by default only valid for the current process lifetime, but calling `contentResolver.takePersistableUriPermission(uri, flags)` (with `FLAG_GRANT_PERSISTABLE_URI_PERMISSION` requested in the original intent) makes the grant survive app restarts and device reboots. Persisted-grant counts are capped at 512 on API 30+, 128 below. [android-saf-docs]
- SAF file operations require two IPC round-trips (app → SAF → DocumentsProvider) per call versus zero for direct filesystem syscalls; independently reported benchmarks found directory operations 25-78x slower than direct access on some devices, with some operations going from under a second to 25+ seconds. [android-saf-perf]
- iOS's `startAccessingSecurityScopedResource()`/`stopAccessingSecurityScopedResource()` pair wraps a kernel-level sandbox-extension grant around an access window for a URL returned by `UIDocumentPickerViewController`; per an Apple DTS engineer, iOS does not support true security-scoped bookmarks (macOS-only) — on iOS, persisting access across launches uses a plain (non-security-scoped) bookmark instead. The system limits how many security-scoped URLs an app can access concurrently; leaking access windows (not calling `stop`) can exhaust this and block further grants until relaunch. [ios-security-scoped]
- WASI's design goal is zero ambient authority: a WASM module starts with no access to any host resource and can only reach what it was explicitly handed as a capability (e.g. `wasmtime run --dir=./in::input` preopens a directory at startup); `open("/etc/passwd")` cannot succeed structurally because no preopened file descriptor exists anywhere in that path's ancestry — this is a capability check (possession of a reference is sufficient), not an ambient-authority permission check (identity checked against a policy at call time). [wasi-tutorial]
- WASI's grants are set entirely by the host embedder at module-instantiation time (CLI flags or `WasiCtxBuilder` calls); there is no WASI equivalent of a runtime, user-facing picker dialog — WASI is purely static/upfront capability declaration with no brokering layer, and "capability-based" describes the enforcement mechanism (unforgeable handles), not a runtime-consent-UI pattern. [wasi-tutorial]
- wasmtime maintainers, responding to issue #13544 about preopening both `/` and `/lib` producing an ambiguous guest view, stated this is "not a Wasmtime implementation bug... a semantic ambiguity that falls out of the WASI preopen model," and the fix requires an explicit opt-in flag (`--allow-overlapping-wasi-dirs`) rather than fixing the ambiguity itself. [wasmtime-overlap-issue]
- The document-portal FUSE view does not preserve executable permission bits — every file appears non-executable to the sandboxed app regardless of its real mode, a known, currently-unfixed limitation. [xdg-documents-portal]
- Per an Apple DTS engineer on the developer forums, iOS does not actually implement true security-scoped bookmarks the way macOS does — that capability is macOS-only; on iOS, "if you have access to a resource then you should be able to persist that access using a regular bookmark," meaning the security-scoping enforcement named by the shared API is weaker/different on iOS than the naming implies. This is easy to assume has parity across Apple platforms from the shared class/method names, and it does not. [ios-security-scoped-bookmark-forum-dts]
- The system caps the number of *concurrently open* security-scoped URLs on iOS; failing to call `stopAccessingSecurityScopedResource()` can exhaust that cap and block further access until app termination — structurally the same failure class as a leaked file descriptor. `UIDocument` subclasses handle the start/stop accounting automatically and are the documented recommended default specifically to avoid this. [ios-security-scoped-cap]
- WASI preopens still have real implementation-level attack surface despite being conceptually cleaner than path-string matching: CVE-2025-53901 is a wasmtime host panic reachable via `fd_renumber` + `path_open`, which requires a preopened directory to exist at all — i.e. the mechanism itself, once preopens exist, is not automatically safe just because it's capability-shaped. Notably this bug does not affect the newer WASIp2/Component Model resolution path, suggesting the ecosystem already saw Preview 1's raw-fd preopen model as having narrower-but-real attack surface that the newer model was partly designed to close. [wasi-cve-2025-53901]
- WASI's own spec authors cite CloudABI and Capsicum (FreeBSD capability-mode `openat`) as direct ancestors and explicitly reject Unix's "everything is a path in one global namespace" as being in tension with least-authority design; `wasi-libc`'s `libpreopen` maps ordinary POSIX-style path calls onto preopen-relative capability calls under the hood, so guest application code doesn't need rewriting to benefit from the sandboxing. Newer WASI proposals (post-Preview1) are moving toward a "link-time authority namespace" specifically to avoid "ghost capabilities" — paths passed as plain strings between components, which silently degrades capability-passing back into ambient-authority path lookups at any boundary that isn't careful. [wasi-design-lineage]

## SOURCES

**xdg-portal-docs**
URL: https://flatpak.github.io/xdg-desktop-portal/docs/
Accessed: 2026-08-17
Quote: "xdg-desktop-portal works by exposing a series of D-Bus interfaces known as portals under a well-known name (org.freedesktop.portal.Desktop)."

**xdg-openuri-portal**
URL: https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.OpenURI.html
Accessed: 2026-08-17

**xdg-documents-portal**
URL: https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Documents.html
Accessed: 2026-08-17
Quote: "the file is passed in the form of an open file descriptor to prove that the caller has access to the file"

**flatpak-portal-hybrid**
URL: https://flatpak-docs.readthedocs.io/en/latest/sandbox-permissions.html
Accessed: 2026-08-17
Quote: "the Flatpak package specifies the devices it wishes to enumerate through finish-args, the application requests the portal to enumerate available devices based on that list, and when the application wants to access a device, it makes a request via the portal, which asks the user for permission if not already granted"

**flatpak-headless-discussion**
URL: https://github.com/flatpak/xdg-desktop-portal/discussions/1148
Accessed: 2026-08-17

**android-saf-docs**
URL: https://developer.android.com/training/data-storage/shared/documents-files
Accessed: 2026-08-17

**android-saf-perf**
URL: https://commonsware.com/blog/2019/06/05/storage-access-framework-counterpoints.html
Accessed: 2026-08-17

**ios-security-scoped**
URL: https://developer.apple.com/documentation/foundation/nsurl/startaccessingsecurityscopedresource()
Accessed: 2026-08-17

**wasi-tutorial**
URL: https://github.com/bytecodealliance/wasmtime/blob/main/docs/WASI-tutorial.md
Accessed: 2026-08-17

**wasmtime-overlap-issue**
URL: https://github.com/bytecodealliance/wasmtime/issues/13544
Accessed: 2026-08-17

**ios-security-scoped-bookmark-forum-dts**
URL: https://developer.apple.com/forums/thread/773373
Accessed: 2026-08-17
Quote: "if you have access to a resource then you should be able to persist that access using a regular bookmark"

**ios-security-scoped-cap**
URL: https://developer.apple.com/forums/thread/766646
Accessed: 2026-08-17

**wasi-cve-2025-53901**
URL: https://advisories.gitlab.com/pkg/cargo/wasmtime/CVE-2025-53901
Accessed: 2026-08-17

**wasi-design-lineage**
URL: https://blog.sunfishcode.online/capabilities-and-filesystems/
Accessed: 2026-08-17

## SYNTHESIS

The recurring case where brokering beats a manifest, stated once: static declaration handles "I know the shape of what I need at build/manifest time" well (a folder, a permission category) and handles badly "the user or agent picks a specific, a-priori-unknowable item at the moment of use" (a particular file, a particular device). Every brokered system studied — Flatpak's FileChooser/document portal, Android's SAF picker, iOS's document picker — exists specifically to cover that second case without widening the static grant to cover every possible item up front. Notably, no system found lets the broker gate on the manifest as a policy check — in every case the static declaration and the runtime broker are independent, additive grant sources whose union is the effective access; the manifest never narrows what the broker is willing to grant, it only reduces how often the app needs to go through the broker at all.

The one clean, citable hybrid across all this research is Flatpak's device-portal pattern: `finish-args` declares which device *categories* are even eligible to be enumerated, and the portal brokers the actual per-device grant at runtime. That is a genuinely reusable shape for PDPP: a connector's manifest could declare capability *categories* (network, filesystem, browser) as the eligible menu, with a brokered layer handling the specific runtime instance (which file, which URL, which device) within that category — narrower manifest scope, broker fills in the specific grant.

The costs are consistent and well-documented across every brokered system, which argues for weighing them seriously rather than assuming brokering is strictly better than static declaration: dialog fatigue (Flatpak's own GNOME UX team has pushed back on adding more brokered surface, calling extra prompts "surprising and confusing"), IPC/architectural latency (Android SAF's measured 25-78x slowdown for brokered vs. direct filesystem operations is the most concretely quantified cost found in this entire research pass), broker-process trust risk (a real Flatpak portal CVE let caller-controlled environment variables reach non-sandboxed host processes — the broker itself is an attack surface, not a free safety layer), and finite resource ceilings on persisted grants (Android's 512-grant cap, iOS's undocumented-but-real concurrency limit on security-scoped URLs).

Most directly relevant to PDPP: brokering structurally requires a visible, focused UI surface to safely anchor a consent prompt to, and this breaks for headless/daemon-style callers — Flatpak's own Flameshot case is the exact precedent. PDPP's connectors are scripts run by a server, a desktop app, or a remote device collector, not interactive GUI apps with a natural window — a pure-brokering design (no manifest baseline) would hit the identical wall XDG portals hit with headless apps. This is a strong argument for keeping PDPP's manifest-declared-capability baseline as the primary mechanism (which is also what WASI does exclusively, with no runtime brokering layer at all), and treating any future brokered/portal-style layer as a *supplement* for the specific case of an interactive, GUI-attached deployment (e.g. the desktop app) picking a runtime-unknowable file — not as a replacement for declared capabilities, and not something the remote/headless collector deployment could rely on at all.

Two further nuances worth flagging so PDPP doesn't over-trust brokering by analogy: (1) iOS's security-scoped bookmark API shares a class/method name with macOS's but is NOT the same enforcement mechanism underneath — a documented Apple engineer statement, not an inference — so cross-platform "the API name matches, the guarantee matches" assumptions are specifically unsafe in this space and should be independently verified per-platform, per-backend, for PDPP's own future backends too. (2) Even WASI's capability-passing model, which has no human-in-the-loop broker at all and is conceptually the cleanest of everything surveyed, still has real CVE-class implementation bugs once preopens exist (CVE-2025-53901) — "capability-shaped" is a design property, not a correctness guarantee, and PDPP's eventual OS-native-sandbox backend should expect and budget for real implementation bugs in its confinement layer, not treat the design pattern as self-verifying.
