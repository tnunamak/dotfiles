# Cross-platform connector runtime requirements

> **Headline:** A cross-platform desktop runtime must implement the same JSONL connector protocol and binding gate as the reference runtime, while supplying four materially different execution substrates: network-only connectors, local filesystem readers, persistent browser sessions, and native sidecar processes. It must not assume PostgreSQL or Docker for the basic server path. It must, however, provide durable local storage, outbound network access when declared, OS-specific local-file/keychain access for desktop connectors, and a visible or remote-CDP browser surface for headed browser work.
>
> **Reference inspected:** `origin/main` at `9202f6b0ab7b11f8e0b7e761bccd6bccf68be525` in `~/code/pdpp`. All findings below were checked with `git show origin/main:<path>` and `git -C ~/code/pdpp grep`; the divergent working checkout was not used as evidence.
>
> **Scope note:** `STREAM_EVIDENCE` is not a wire-message name in this ref. It names the CI/inventory gate (`scripts/ci-mode.ts:99-115`). The runtime contract it protects is the manifest-declared coverage/freshness strategy plus observed `STATE`, `DETAIL_COVERAGE`, `DETAIL_GAP`, and terminal `DONE` evidence.

## 1. Connector execution modes

The package registry describes 32 connectors by operational class (`packages/polyfill-connectors/CONNECTORS.md:8-23`), while the shipped manifest set contains the following runtime requirements. “Network-only” means no required browser, filesystem, or native sidecar binding; it does not claim that every source protocol is literally HTTP.

### Network-only

`apple_contacts`, `github`, `gmail`, `google_calendar`, `google_contacts`, `google_maps_data_portability`, `groupme`, `jellyfin`, `notion`, `oura`, `pocket`, `spotify`, `steam`, `strava`, and `ynab`.

These require the `network` binding in their manifests. Representative declarations are `github` (`packages/polyfill-connectors/manifests/github.json:8-13`), `gmail` (`.../gmail.json:8-13`), and `google_maps_data_portability` (`.../google_maps_data_portability.json:8-13`). The implementations use ordinary outbound HTTP for API sources, for example GitHub (`packages/polyfill-connectors/connectors/github/index.ts:163-171`) and YNAB (`packages/polyfill-connectors/connectors/ynab/index.ts:397-400`). Gmail is network-only but uses IMAP client operations rather than browser automation (`packages/polyfill-connectors/connectors/gmail/index.ts:1643-1648`).

The registry calls `ynab`, `github`, `gmail`, `notion`, `oura`, and `strava` API-based and calls out Reddit and Slack separately because their access paths are not pure token/API execution (`packages/polyfill-connectors/CONNECTORS.md:21-36`). Reddit is therefore not in this group even though its manifest has `network`.

### Browser-driven: Playwright/Patchright, headed display or remote CDP

`amazon`, `anthropic`, `chase`, `chatgpt`, `doordash`, `heb`, `linkedin`, `loom`, `meta`, `reddit`, `shopify`, `uber`, `usaa`, `venmo`, `wholefoods`, and `whoop` require `network` plus `browser` in their manifests. The complete browser-scraper roster and the persistent-profile rule are documented at `packages/polyfill-connectors/CONNECTORS.md:38-65`.

The actual launcher is Patchright, a patched Playwright drop-in, and creates an isolated per-connector profile (`packages/polyfill-connectors/src/browser-launch.ts:5-20`). Profiles default to `~/.pdpp/profiles/<name>/` and can be relocated with `PDPP_BROWSER_PROFILE_ROOT` (`packages/polyfill-connectors/src/browser-launch.ts:11-15`). In Core, that root is `/var/lib/pdpp/browser-profiles` (`packages/polyfill-connectors/CONNECTORS.md:42`).

The runtime has two browser shapes:

- Local Chromium: the Core image advertises `PDPP_RUNTIME_BROWSER=1`, starts Xvfb, and passes `DISPLAY`; the normal local mode is headed even without a physical desktop (`packages/polyfill-connectors/src/browser-launch.ts:22-27`).
- Remote browser: the launcher attaches with `patchright.chromium.connectOverCDP(remoteCdpUrl)` and disconnects without owning the remote browser lifecycle (`packages/polyfill-connectors/src/browser-launch.ts:62-76`). This is the n.eko path used for an operator-visible browser surface.

A container without a managed display or remote CDP must fail closed for headed browser work; the only explicit escape hatch is `PDPP_ALLOW_HEADED_CONTAINER_BROWSER=1` (`packages/polyfill-connectors/src/browser-launch.ts:135-177`, `:199-218`).

### Filesystem/local-device connectors

`apple_health`, `apple_photos`, `claude_code`, `codex`, `google_maps`, `google_takeout`, `ical`, `imessage`, `netflix_export`, `twitter_archive`, and `whatsapp` require filesystem access and read user-supplied exports or local application data. The registry says these are local-file parsers and do not need network access (`packages/polyfill-connectors/CONNECTORS.md:69-85`).

The path contract is not portable by default: Claude Code and Codex use their respective home directories, iMessage auto-discovers `~/Library/Messages/chat.db`, and the import connectors use `~/.pdpp/imports/...` (`packages/polyfill-connectors/CONNECTORS.md:73-85`). A desktop implementation must expose explicit path overrides and permission diagnostics rather than assuming a Linux home layout. The manifests make this explicit for Claude Code and Codex via `runtime_requirements.local_paths` (`packages/polyfill-connectors/manifests/claude_code.json:8-28`, `packages/polyfill-connectors/manifests/codex.json:8-29`).

### Native sidecars and hybrid local connectors

- `slack` requires network, filesystem, and the `slackdump` executable. The manifest requires a detectable `slackdump version` and allows `SLACKDUMP_BIN` (`packages/polyfill-connectors/manifests/slack.json:8-28`). The connector wraps the CLI and maintains a SQLite archive under the durable artifact root (`packages/polyfill-connectors/connectors/slack/README.md:1-5`).
- `google_messages` requires filesystem plus external `gmcli`; the runtime must run `gmcli version` before spawning it (`packages/polyfill-connectors/manifests/google_messages.json:8-25`). It is a QR-paired local archive, not a browser connector; the phone must remain online for synchronization (`packages/polyfill-connectors/manifests/google_messages.json:28-43`).
- `signal` requires filesystem, a live `desktop_session`, and external `sigtop`. `sigtop` unwraps the Signal Desktop SQLCipher key through the OS keychain and exports attachments (`packages/polyfill-connectors/manifests/signal.json:8-29`). The connector resolves `SIGTOP_BIN` or `sigtop` on `PATH` and spawns it (`packages/polyfill-connectors/connectors/signal/index.ts:18-22`, `:192-227`). The cross-OS runtime must therefore integrate with Keychain on macOS, DPAPI on Windows, and an appropriate Linux keyring/session; copying `db.sqlite` alone is insufficient (`packages/polyfill-connectors/manifests/signal.json:13-15`).

The reference connector child is itself a subprocess, detached into its own POSIX process group so descendants such as Chromium and sidecars can be terminated together (`reference-implementation/runtime/index.ts:2292-2308`, `:2356-2388`). This is a lifecycle requirement, but the implementation comment explicitly says the current runtime assumes Linux/Docker and has no Windows support (`reference-implementation/runtime/index.ts:2303-2307`). A desktop port must replace that assumption with an equivalent process-tree/job-object strategy on Windows.

## 2. OS and deployment assumptions

### Xvfb, display, and browser packaging

The browser-bearing image installs and verifies Xvfb (`Dockerfile:172-179`). The Railway supervisor defaults to display `:99`, starts Xvfb, waits for `/tmp/.X11-unix/X99`, then injects `DISPLAY` into the server and its children (`deploy/railway/core-supervisor.ts:16-41`, `:73-102`, `:169-177`). The scheduler's browser readiness predicate accepts a direct CDP URL, managed n.eko, or `PDPP_RUNTIME_BROWSER=1` plus `DISPLAY` (`reference-implementation/runtime/scheduler-readiness.ts:120-148`).

Therefore a cross-OS desktop must provide either a real visible desktop session, a local virtual display with equivalent readiness semantics, or a remote CDP surface. “Headless Chromium happens to start” is not enough for flows that require `manual_action` or streaming.

### Filesystem durability and fixed paths

The Core deployment treats `/var/lib/pdpp` as the durable root. Browser profiles and bulk connector artifacts must be below it; the documented artifact root is `/var/lib/pdpp/connector-artifacts` (`packages/polyfill-connectors/CONNECTORS.md:42-44`; `deploy/docker/README.md:136-145`). Docker local imports are mounted at `/imports/claude` and `/imports/codex`, with host paths supplied through deployment variables (`packages/polyfill-connectors/CONNECTORS.md:87-93`).

The desktop equivalent needs one durable application-data root, separate temporary space, and a migration-safe mapping for browser profiles, connector artifacts, SQLite, credentials, and import directories. Do not preserve the literal `/var/lib/pdpp` path as a requirement; preserve its durability and backup semantics.

### Docker, n.eko, systemd, and isolation

Dynamic n.eko surfaces are Docker-managed. The allocator defaults to `/var/run/docker.sock` and talks to the Docker Engine over its Unix socket (`reference-implementation/server/neko-surface-allocator-server.ts:19-31`, `:174-198`). The n.eko compose file mounts that socket (`docker-compose.neko.yml:157`). A desktop runtime that does not run Docker must replace this with an in-process or native surface allocator, or use a user-configured remote CDP browser.

`systemd` appears only as a supported supervisor/deployment variant in documentation and environment-resolution comments, not as a required server service unit (`deploy/docker/README.md:187`; `packages/polyfill-connectors/src/resolve-tsx-binary.ts:15`). The reference tree has no executable `unshare`, `bwrap`, or `bubblewrap` path. Its process isolation is the POSIX detached process-group mechanism above; a port must not infer that a Linux user-namespace sandbox exists.

Likewise, the runtime does not have a `/run`-directory contract. `XDG_RUNTIME_DIR` is merely one of the platform variables allowed through the child environment (`reference-implementation/runtime/connector-child-environment.ts:12-42`). A port should create only the runtime directories it owns and should not require Linux `/run` semantics.

## 3. Collection Profile and stream-evidence contract

The Collection Profile deliberately standardizes the runtime boundary, not the source-specific collection method: browser automation and export/API connectors use the same bindings, scope, state, and JSONL messages (`spec-collection-profile.md:35-47`).

Before spawn, the runtime must match manifest requirements against advertised capabilities and fail before starting the child when a required binding is absent (`spec-collection-profile.md:97-107`, `:119-128`; `reference-implementation/runtime/index.ts:1971-1980`). Standard bindings include browser automation/CDP, browser profile, filesystem, network, interactive, and loopback listen (`spec-collection-profile.md:97-107`).

The first message is `START`. It carries `run_id`, `collection_mode` (`full_refresh` or `incremental`), normalized explicit stream scope, prior state, and binding descriptors; it must not carry the raw grant or access token (`spec-collection-profile.md:150-208`). Scope is enforced both by connector obligation and runtime/downstream backstop: no records outside requested streams/resources/time range/fields, and unsupported constraints must become `SKIP_RESULT(scope_not_supported)` or a failed run (`spec-collection-profile.md:214-235`).

State is cursor data, not configuration. Proactive runs use global state, continuous grant runs use grant-scoped state, and single-use runs receive `state: null` with no persisted STATE (`spec-collection-profile.md:237-243`). A `STATE` checkpoint becomes durable only after preceding record batches are accepted (`spec-collection-profile.md:292-308`).

### Stream evidence

Each manifest stream declares a coverage strategy and freshness strategy; the generated inventory explicitly warns that these are declarations, not observed proof (`packages/polyfill-connectors/src/stream-evidence-strategy-manifest.test.ts:4-19`, `:35-73`; `docs/reference/stream-evidence-inventory.md:1-5`). The CI gate covers changes to the inventory and generator (`scripts/ci-mode.ts:99-115`).

The high-level evidence flow is:

1. `RECORD` carries durable data; `STATE` carries an opaque incremental cursor (`spec-collection-profile.md:268-308`).
2. `DETAIL_COVERAGE` accounts for list/detail hydration using `required_keys`, `hydrated_keys`, and optional `gap_keys`; every key must be accounted for, and unmatched gaps remain incomplete (`spec-collection-profile.md:363-396`, `:431-431`).
3. `DETAIL_GAP` records a retryable per-record detail failure and must be scoped to the correct parent boundary for multi-parent streams (`spec-collection-profile.md:402-429`).
4. `DONE` is terminal. Successful runs may commit final checkpoints; ordinary failed/cancelled runs must not advance state, subject to the certified stream-scoped exception (`spec-collection-profile.md:447-477`).

Manifest checkpoint dependencies are part of this contract: `state_stream` is the single-parent/checkpoint-window form; `parent_streams` is the multi-parent/detail-accounting form. They are mutually exclusive and must be validated, including unknown-stream, duplicate, self-reference, and cycle rejection, before spawn (`spec-collection-profile.md:63-88`).

## 4. What the server process actually needs

### Required for the basic server

- Node.js plus the native/runtime dependencies in `reference-implementation/package.json`, including `better-sqlite3`, `sqlite-vec`, and `pg` (`reference-implementation/package.json:60-78`).
- A writable durable application-data path if records must survive restart. The server defaults `PDPP_DB_PATH`/`DB_PATH` to `:memory:` (`reference-implementation/server/index.ts:908-917`), so an unset path is suitable only for ephemeral/test operation.
- Local loopback connectivity between the Authorization Server and Resource Server. The reference server defaults to AS `7662`, RS `7663`, and sets child-facing URLs to loopback (`reference-implementation/server/index.ts:908-910`, `:8346-8406`). Connector children post records/state to the local RS and, when streaming is enabled, register targets with the local AS (`reference-implementation/server/index.ts:8346-8406`; `reference-implementation/runtime/index.ts:551-579`).
- Outbound egress for the connector's declared source binding. The server does not need universal internet access for file-only connectors, but network connectors do; browser connectors also need access to their source sites and any login/2FA endpoints. The child environment explicitly carries approved proxy variables and source-specific runtime controls (`reference-implementation/runtime/connector-child-environment.ts:107-125`).

### PostgreSQL is optional, not a universal desktop prerequisite

SQLite is the default backend. PostgreSQL activates only when `PDPP_STORAGE_BACKEND=postgres` or `PDPP_DATABASE_URL`/`DATABASE_URL` is present (`reference-implementation/server/postgres-storage.ts:5-10`). In Postgres mode, the server deliberately opens only an in-memory SQLite handle and keeps durable persistence in Postgres (`reference-implementation/server/index.ts:7701-7731`). The production Docker Compose profile chooses Postgres plus pgvector, while the quickstart uses SQLite on a named volume (`deploy/docker/README.md:3-14`, `:44-46`, `:64-78`).

Design implication: the desktop should ship a reliable SQLite path first. Postgres is a deployment option for scale/semantic-search operations, not a condition for local collection.

### Browser is conditional

The server can run without a browser for network-only and file-only connectors. Browser-backed scheduled work is admitted only when a local managed display, a managed/remote n.eko surface, or an explicit unmanaged-browser policy is configured (`reference-implementation/runtime/scheduler-readiness.ts:120-148`). The Core image bundles Patchright Chromium and Xvfb, but that is an image/deployment choice, not a protocol requirement (`deploy/docker/README.md:10-14`, `:114-120`).

### Network egress patterns

The runtime makes three classes of network hop:

- connector-to-source egress, only when the manifest requires `network`;
- connector-to-local-RS ingest/state calls, normally loopback;
- optional connector-to-local-AS streaming-target registration and browser-to-CDP/stream-surface traffic (`reference-implementation/runtime/index.ts:551-579`; `reference-implementation/server/index.ts:8346-8406`).

Dynamic n.eko additionally needs Docker Engine access through `/var/run/docker.sock`, container-network reachability, CDP/HTTP health endpoints, and WebRTC port allocation; these are optional for a desktop that uses local Chromium or a pre-existing remote CDP surface (`reference-implementation/server/neko-surface-allocator-server.ts:19-31`, `:174-198`).

## Cross-OS acceptance requirements

An implementation satisfies the reference runtime’s reality only if it can:

1. Advertise and enforce the six standard bindings before spawn, with clear capability mismatch errors.
2. Run the four execution substrates above, including `slackdump`, `gmcli`, and `sigtop` capability checks and process lifecycle cleanup.
3. Map user homes, imports, browser profiles, artifacts, credentials, and the database to a durable per-user application-data root.
4. Provide headed browser visibility through a real display, equivalent virtual display, or remote CDP; support `manual_action` and streaming target registration.
5. Preserve JSONL `START`/`RECORD`/`STATE`/`DETAIL_COVERAGE`/`DETAIL_GAP`/`INTERACTION`/`DONE` semantics and fail-closed checkpoint advancement.
6. Operate with SQLite alone, with optional Postgres, and with connector-specific network egress rather than a blanket internet assumption.

