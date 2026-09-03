---
title: "Deno, Chrome/Firefox extension manifests, systemd sandboxing directives, and Flatpak finish-args all converge on flat lists of exact-or-prefix path grants (no glob path grammar anywhere); systemd's SystemCallLog=/SCMP_ACT_LOG is the only system offering a genuine three-state (off / audit-only / enforcing) toggle, and Flatpak's flatpak-builder-lint is the most mature CI-gated drift detector with a human-justified exceptions file"
date: 2026-08-17
topic: execution-boundary-design
tags: [capability-declaration, deno-permissions, extension-manifests, systemd-sandboxing, flatpak-finish-args, seccomp, enforcement-toggle, drift-detection, permission-broker]
status: draft
sources: [deno-permissions-ref, deno-permissions-api, deno-issue-20061, deno-2.5-audit, chrome-declare-permissions, chrome-match-patterns, chrome-cws-privacy, systemd-analyze-hardening, systemd-seccomp-log, flatpak-sandbox-permissions, flatpak-builder-lint, flatpak-issue-463]
source_session: 8aa4436f-6d97-4d7d-a0b9-7b23964cafdf
---

## CLAIMS

- Deno's `--allow-read`/`--allow-write` grant directory-prefix access, not glob matching — `--allow-read=node_modules` covers any file in any subdirectory, but glob syntax like `**/*.ts` is not supported. A literal comma in a path must be escaped by doubling it. [deno-permissions-ref]
- Deno's `--allow-net=<hosts>` requires explicit `*.example.com` syntax for subdomain wildcards; a bare hostname does not implicitly cover subdomains. `--allow-env` gained suffix-wildcard support (`--allow-env='AWS_*'`) in Deno v2.1, but this wildcard capability was not extended to `--allow-read`/`--allow-write` path grammar. [deno-permissions-ref]
- Deno GitHub issue #20061: a user could not scope `--allow-read` to `~/.cache/deno` because tilde is not expanded by the permission grammar; the only workaround was a broader prefix (e.g. `/home`), which over-grants. [deno-issue-20061]
- Deno's `Deno.permissions` API exposes three states (`"granted"`, `"denied"`, `"prompt"`) via `query()`, `request()` (prompts interactively if state is `"prompt"`; does not re-prompt if already `"denied"`), and `revoke()` (downgrades `"granted"` back to `"prompt"`), plus sync variants. `--no-prompt` disables interactive prompting entirely for headless use. [deno-permissions-api]
- Deno's `--allow-all` flag is documented as having "the same security properties as running a script in Node.js, i.e. none" — the toggle between Deno's enforced and unenforced modes is grant-scope (nothing vs. everything) within the same binary and code path, not a structurally separate execution mode. [deno-permissions-ref]
- Chrome/Firefox Manifest V3 extensions declare three permission tiers: `permissions` (API-name strings, install-time), `host_permissions` (match patterns, install-time, MV3-specific — separated from `permissions` unlike MV2), and `optional_permissions`/`optional_host_permissions` (same syntax, granted at runtime via `chrome.permissions.request()` triggered from a user-gesture context). [chrome-declare-permissions]
- Chrome extension match pattern grammar: `<scheme>://<host>:<port>/<path>` where scheme is `http`, `https`, `file`, or `*` (matches only http/https, not file); host wildcard `*.example.com` must be the leading character followed immediately by `.`; bare `*` matches all hosts; port defaults to `:*`; `<all_urls>` is a special pattern matching any URL with a permitted scheme. [chrome-match-patterns]
- `chrome.permissions.request()` can only request permissions/hosts already listed in `optional_permissions`/`optional_host_permissions` in the manifest — it cannot request anything not pre-declared there. [chrome-declare-permissions]
- Chrome Web Store requires a "Permissions justification" field per declared permission at submission, with reviewer policy stating extensions must "request the minimum permissions consistent with their purpose" and disallowing permissions requested for unimplemented/future features. No publicly documented automated tool diffs declared-manifest permissions against runtime API usage for Chrome extensions — enforcement of the declared/used match is via human review at submission, not continuous or CI-based. [chrome-cws-privacy]
- systemd's `ProtectSystem=strict` makes the entire filesystem read-only except paths explicitly opened via `ReadWritePaths=`; it does not by itself cover `/dev`, `/proc`, `/sys` (separate directives `PrivateDevices=`, `ProtectKernelTunables=`, `ProtectControlGroups=` are needed for those). `ProtectHome=` accepts `true` (no access), `read-only`, or `tmpfs` (empty overlay). [systemd-analyze-hardening]
- The documented incremental-adoption workflow for systemd sandboxing directives is trial-and-error, directive by directive: add a directive, restart the service, and when it breaks, `journalctl -u <unit>` names the exact denied path, which is then added to `ReadWritePaths=`; repeat until stable. [systemd-analyze-hardening]
- `systemd-analyze security <unit>` produces a numeric exposure score (lower = less exposed), broken down per-directive, giving a quantified measure of incremental hardening progress; a cited example brought a unit's score from ~9.6 down to ~2.0-3.0 through incremental directive additions. [systemd-analyze-hardening]
- systemd's `SystemCallLog=` directive (since systemd 247) logs syscalls matching a filter set without blocking them, backed by the kernel seccomp-BPF `SCMP_ACT_LOG` action; the documented workflow is: set `SystemCallLog=`, exercise the app through all features, inspect `journalctl _AUDIT_TYPE_NAME=SECCOMP` to discover the real syscall surface, then switch to enforcing `SystemCallFilter=` with the discovered list. `SystemCallErrorNumber=EPERM` is a softer enforcing mode that returns an error to the process instead of killing it. [systemd-seccomp-log]
- Flatpak `--filesystem=` grants use an enumerated keyword vocabulary (`home`, `host`, `host-os`, `host-etc`, `xdg-download`, `xdg-config`, etc.) plus absolute paths, homedir-relative paths (`~/dir`), or XDG-relative subpaths (`xdg-config/autostart`), with suffix modifiers `:ro` (read-only) and `:create` (read-write, create if missing); default (no suffix) is read-write without creation. There is no glob syntax. [flatpak-sandbox-permissions]
- Flatpak issue #463: `--filesystem=xdg-config/autostart` (no suffix) silently fails to grant access even if the directory exists; `:create` is required to actually get access despite the directory already existing — an implicit-existence-check gotcha in the suffix-modifier grammar. [flatpak-issue-463]
- Flatpak expresses multiple candidate directories as repeated, independent `--filesystem=` lines (the option "can be used multiple times") — there is no union or glob construct for "one of several possible locations." [flatpak-sandbox-permissions]
- Flathub's `flatpak-builder-lint` runs in CI on Flathub submissions/updates with named rule IDs for over-broad grants, including `finish-args-host-filesystem-access` (flags any `--filesystem=host`) and `finish-args-unnecessary-xdg-data-access` (flags apps that should use their private per-app data dir instead of broad `xdg-data` access). Flagged grants are not auto-rejected outright — they can be justified and approved by reviewers, then recorded in a checked-in `exceptions.json` keyed by app ID with the justification stored inline. [flatpak-builder-lint]
- Deno 2.5 introduced `DENO_PERMISSION_BROKER_PATH`: setting it delegates ALL permission decisions to an external broker process, at which point "CLI flags and prompts no longer apply" — a first-party, shipped precedent for "declare capabilities in one place, delegate the grant/deny DECISION to a pluggable external process," structurally identical to PDPP wanting one manifest format evaluatable by either no enforcement or a pluggable backend's policy. [deno-2.5-audit]
- Deno 2.5 also added named, reusable permission sets definable in `deno.json`, explicitly framed for "reproducible CI runs" — moving "from ad-hoc CLI flags toward reproducible, auditable runs." Deno deliberately disallows "fragmented" permission states (a broad grant with narrower exclusions), stating "such a system would become complex and unpredictable" — a deliberate trade of granularity for predictability. [deno-2.5-audit]
- A subprocess spawned via Deno's `--allow-run` inherits none of the *restrictions* of its parent's permission grant — "child processes can access system resources regardless of the permissions you granted to the Deno process that spawned it," documented as a privilege-escalation risk whose only mitigation is scoping `--allow-run` to specific executable names. [deno-2.5-audit]
- systemd's `ProtectHome=` has a third state beyond `true`/`false` directly relevant to multi-location probing: `tmpfs` — home directories appear as an empty, writable-but-ephemeral overlay, useful "if the service probes for home directory existence" without needing real access. This answers "an app that checks N candidate directories" without allow-listing each one: let unlisted paths exist-but-be-empty rather than enumerating every candidate. [systemd-hardening-ctrlblog]
- A documented Flatpak composition hole: `--nofilesystem=host` does NOT retract a more specific, separately-granted `--filesystem=~/some-dir` — and if that grant carries `:create`, Flatpak will actually create the directory before running. Narrow grants can survive broad revocations; "broadest wins" is not a safe assumption about composition order. The fix was a NEW, stronger flag (`--nofilesystem=host:reset`, Flatpak 1.10.7/1.12.4+) rather than changing the existing flag's semantics — a backward-compatible way to tighten a composition bug without silently changing old manifests' behavior. [flatpak-issue-463]

## SOURCES

**deno-permissions-ref**
URL: https://docs.deno.com/runtime/reference/permissions/
Accessed: 2026-08-17
Quote: "the same security properties as running a script in Node.js, i.e. none"

**deno-permissions-api**
URL: https://docs.deno.com/api/deno/~/Deno.Permissions
Accessed: 2026-08-17
Quote: "When prompting, the CLI will request the narrowest permission possible, potentially making it annoying to the user. The permissions APIs allow the code author to request a wider set of permissions at one time in order to provide a better user experience."

**deno-issue-20061**
URL: https://github.com/denoland/deno/issues/20061
Accessed: 2026-08-17

**chrome-declare-permissions**
URL: https://developer.chrome.com/docs/extensions/develop/concepts/declare-permissions
Accessed: 2026-08-17

**chrome-match-patterns**
URL: https://developer.chrome.com/docs/extensions/develop/concepts/match-patterns
Accessed: 2026-08-17

**chrome-cws-privacy**
URL: https://developer.chrome.com/docs/webstore/cws-dashboard-privacy
Accessed: 2026-08-17
Quote: "Permissions justification section contains a list of permissions that the extension uses (as declared in its manifest), with a field for developers to state the justification for each permission."

**systemd-analyze-hardening**
URL: https://oneuptime.com/blog/post/2026-03-02-use-systemd-protectsystem-protecthome-directives-ubuntu/view
Accessed: 2026-08-17
Quote: "the service starts, tries to write to a path you did not whitelist, and dies with a permission or read-only-filesystem error, which is a feature; journalctl -u myapp will name the exact path, you add it to ReadWritePaths, and you move on"

**systemd-seccomp-log**
URL: https://linux-audit.com/systemd/how-to-harden-a-systemd-service-unit/
Accessed: 2026-08-17

**flatpak-sandbox-permissions**
URL: https://docs.flatpak.org/en/latest/sandbox-permissions.html
Accessed: 2026-08-17

**flatpak-builder-lint**
URL: https://github.com/flathub-infra/flatpak-builder-lint
Accessed: 2026-08-17

**flatpak-issue-463**
URL: https://github.com/flatpak/flatpak/issues/463
Accessed: 2026-08-17

**deno-2.5-audit**
URL: https://progosling.com/en/dev-digest/2025-10/deno-2-5-permissions-bundle ; https://safeguard.sh/resources/blog/deno-security-best-practices
Accessed: 2026-08-17
Quote: "using a permission broker changes Deno's decision authority — CLI flags and prompts no longer apply"

## SYNTHESIS

Four independently designed systems — Deno, Chrome/Firefox extension manifests, systemd, and Flatpak — all land on flat lists of exact, prefix, or enumerated-keyword path/host grants, and none support glob path grammar. Chrome's match patterns are the only thing glob-adjacent in this set, and even that constrains wildcards to a single position (leading subdomain component). Multiple candidate locations are uniformly expressed as "just list them" — a comma-separated list (Deno), an array (Chrome), or repeated directive lines (Flatpak, systemd `ReadWritePaths=`) — never a union or glob construct. This is useful negative evidence for PDPP: a full glob engine for its connector-capability manifest grammar would be a novel design choice with no supporting prior art among these four systems; prefix-or-exact-path lists are the well-trodden path.

The enforcement-toggle shapes differ meaningfully by system, and this is where PDPP's specific requirement — "sandbox enforcement is a per-deployment toggle, unsandboxed stays supported indefinitely" — has real precedent to draw from. Deno's toggle is grant-scope, not a structural mode switch: `--allow-all` is "grant everything" through the identical enforcement code path (documented as having "the same security properties as running a script in Node.js, i.e. none" — the escape hatch is named and its danger stated explicitly, a pattern worth copying so unsandboxed use is visible in logs/config rather than silently defaulted), which directly supports PDPP running the same manifest-declared-capability engine unsandboxed by simply not narrowing grants, rather than needing a parallel unsandboxed code path. Deno 2.5's `DENO_PERMISSION_BROKER_PATH` is the single most directly load-bearing precedent found for PDPP's exact shape: it lets one declaration format be evaluated either by Deno's own built-in logic or handed off entirely to a pluggable external decision-maker — structurally identical to "the manifest is always evaluated the same way, but WHO evaluates it (no-op / Docker-backend policy / OS-sandbox-backend policy) is swappable." systemd is the standout for offering a genuine three-state model as a first-class, documented, incrementally-adoptable feature: unset (no restriction) / log-only via `SystemCallLog=`+`SCMP_ACT_LOG` (declared and observed, not enforced) / enforcing via `SystemCallFilter=`. This is the closest match found anywhere in this research to PDPP's stated need for a real audit-without-enforcement tier. `ProtectHome=tmpfs` is a materially better answer than Deno's binary allow/deny to "a connector probes 5 candidate config dirs": make unlisted paths exist-but-empty so a probe (`stat`/`access`) succeeds without granting real access, rather than trying to enumerate every candidate path in the manifest. Flatpak and Chrome extensions have no comparable audit-only mode — Flatpak's sandbox is always kernel-enforced once running, and Chrome extensions are always browser-enforced; neither offers a "declare and observe" state. Flatpak's own composition bug (`--nofilesystem=host` not retracting a more specific prior grant, fixed by adding `--nofilesystem=host:reset` rather than changing existing semantics) is a concrete warning: if PDPP's grammar allows both allow-list and deny-list entries, define and test composition/precedence explicitly rather than assuming "more specific wins" or "broadest revocation wins" — and if a composition bug is found post-ship, fix it by adding a new stronger primitive, not by silently changing what an existing declaration means.

For drift detection between declared and actual capability use, Flathub's `flatpak-builder-lint` is the most mature model found: a CI-gated linter with named rule IDs per over-broad grant pattern, that doesn't hard-reject exceptions but instead routes them through human justification recorded in a checked-in, auditable `exceptions.json`. This is a directly reusable pattern for a PDPP connector-manifest linter — flag over-broad capability grants automatically, but allow a reviewed, recorded justification rather than a blanket ban, since some connectors (as Flathub's own exceptions show for document-signing and log-viewer apps) legitimately cannot predict every path they'll need at manifest-authoring time. Chrome's drift catching, by contrast, is purely human review at submission with no public automated tool diffing declared vs. used permissions — a weaker model than Flathub's, and not one to emulate over Flatpak's.
