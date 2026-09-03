---
title: "Mature pluggable-isolation systems (CRI, OCI runtime spec, containerd shim v2, HashiCorp go-plugin) converge on a minimal closed verb set (create/start/kill/wait/state) with an opaque backend-owned ID and backend-specific config kept OUT of the shared schema; process-tree kill is not free and must be actively engineered per backend"
date: 2026-08-17
topic: execution-boundary-design
tags: [handle-interface, cri, oci-runtime-spec, containerd, shim-v2, kata, go-plugin, vault, vm2, process-groups, sandboxing]
status: draft
sources: [cri-proto, oci-runtime-spec, containerd-shim-v2, containerd-shim-v1-proposal, kata-shim-v2-issue, go-plugin-runner, go-plugin-internals, go-plugin-issue-136, go-plugin-pkg-docs, vault-plugin-arch, vm2-ghsa-7jxr]
source_session: 8aa4436f-6d97-4d7d-a0b9-7b23964cafdf
---

## CLAIMS

- Kubernetes CRI's RuntimeService exposes a two-tier handle model: a pod-sandbox handle (`RunPodSandbox`/`StopPodSandbox`/`RemovePodSandbox`/`PodSandboxStatus`) for the isolation boundary, and nested container handles (`CreateContainer`/`StartContainer`/`StopContainer`/`RemoveContainer`/`ContainerStatus`) inside it, plus `ExecSync`/`Exec`/`Attach`/`PortForward` and stats/event RPCs. [cri-proto]
- `StopContainer` takes only a grace-period `timeout` in seconds, no signal parameter — the runtime owns the SIGTERM→SIGKILL escalation policy internally, not the caller. Default `timeout=0` means "forcibly terminate immediately." [cri-proto]
- CRI's `NamespaceMode` enum (`POD=0`, `CONTAINER=1`, `NODE=2`, `TARGET=3`) governs whether a container shares the pod's PID namespace or has its own; the comment states "The CRI default is POD, but the v1.PodSpec default is CONTAINER" — whether killing a process tree affects one process or everything in the sandbox is a namespace-sharing configuration choice exposed as data, not a fixed API behavior. [cri-proto]
- CRI's `Exec`/`Attach`/`PortForward` RPCs return a `url` field to a separate streaming server rather than streaming bytes over the control-plane gRPC call itself. [cri-proto]
- CRI's proto documents an explicit 16MB output cap on `ExecSyncResponse`, citing CVE-2022-1708 and CVE-2022-31030 as the reason for capping captured stdout. [cri-proto]
- CRI leaves "how the sandbox is actually implemented" (namespaces vs VM vs gVisor) fully out of scope — that's selected by the `runtime_handler` string on `RunPodSandboxRequest`, opaque to the API. [cri-proto]
- The OCI Runtime Spec defines exactly four core verbs — `create`, `start`, `kill <signal>`, `delete` — plus a `state` query, with the container passing through states `creating → created → running → stopped`. [oci-runtime-spec]
- OCI spec: config is snapshotted at `create` time; later edits to `config.json` do not affect the running container. `start` on a non-`created` container "MUST have no effect on the container and MUST generate an error." `delete` is only valid on `stopped` state and must not delete resources "not created by this container." [oci-runtime-spec]
- OCI spec error-safety invariant: "Unless otherwise stated, generating an error MUST leave the state of the environment as if the operation were never attempted." [oci-runtime-spec]
- OCI State schema's `pid` field is REQUIRED on Linux when created/running but OPTIONAL on other platforms — an explicit spec-level acknowledgment that exposing a PID in the handle is a Linux-specific leak, not a universal property. [oci-runtime-spec]
- OCI spec explicitly puts networking setup and lifecycle hooks (prestart/createRuntime/createContainer/poststart/poststop) in a separate extension layer around the four core verbs, not inside them. [oci-runtime-spec]
- containerd's shim v2 architecture: containerd never talks to runc/gVisor/Kata directly. It invokes a shim *binary* (e.g. `containerd-shim-runc-v2`) which opens a control socket and speaks ttrpc (a lighter substitute for gRPC, chosen "to save memory and binary size to keep shims small") back to containerd. [containerd-shim-v2]
- Runtime-name-to-shim-binary resolution: a runtime name like `io.containerd.runc.v2` maps to binary `containerd-shim-runc-v2` (dots→dashes, last 2 components, prepend `containerd-shim`). Swapping runc for gVisor (`runsc`) or Kata means installing a different shim binary — containerd's own code never changes. [containerd-shim-v2]
- containerd shim v2 Task service RPCs: `Create` (returns PID), `Start`, `Wait` (blocks until exit, returns exit status), `Kill`, `Pause`/`Resume`, `CloseIO`, `Exec`/`ExecProcessRequest`, `Delete` (returns exit info), `Shutdown`. [containerd-shim-v2]
- `CreateTaskRequest` carries `terminal bool`, `stdin`, `stdout`, `stderr` as string paths; I/O is wired via fifos (Linux), named pipes (Windows), or log files, with the same fields duplicated on `ExecProcessRequest` for secondary processes — no separate wire protocol for interactive vs non-interactive. [containerd-shim-v2]
- containerd's event-ordering contract is a MUST, not just documentation convention: `TaskCreateEventTopic` before `TaskStartEventTopic` before `TaskExitEventTopic` before `TaskDeleteEventTopic` — exit/event reporting is asynchronous and ordered, not embedded synchronously in the RPC response. [containerd-shim-v2]
- containerd explicitly does not know or care whether the shim-to-container relationship is one-to-one or one-to-many — that grouping (e.g. one shim multiplexing many containers in a Kubernetes pod via the `io.kubernetes.cri.sandbox-id` label) is shim-internal and invisible to containerd. [containerd-shim-v2]
- containerd provides no host-level shim configuration via the API; per-instance backend tuning is expected to live in a shim-specific configuration file outside the shared RPC schema. [containerd-shim-v2]
- Shims own filesystem mount/unmount lifecycle for the container's `rootfs/`; containerd does not manage it. A shim that doesn't implement an RPC must return a typed `errdefs.ErrNotImplemented` error rather than silently no-op. [containerd-shim-v2]
- containerd's shim v2 doc documents a specific reparenting gotcha: when a `setns(2)` process forks a grandchild that exits, a kernel patch prevents cross-namespace reparenting, so the grandchild reparents into the target namespace instead of back to the calling process's own reaper — meaning process-tree cleanup differs depending on whether the container is in its own PID namespace or shares the shim's. [containerd-shim-v2]
- HashiCorp go-plugin's `Runner`/`AttachedRunner` Go interfaces expose: `Start`, `Diagnose` (best-effort failure debug text), `Stdout()`/`Stderr()` as `io.ReadCloser`, `Name()`, `Wait(ctx)`, `Kill(ctx)`, `ID() string` (doc comment: "pid or container ID"), and an `AddrTranslator` with `PluginToHost`/`HostToPlugin` methods. [go-plugin-runner]
- go-plugin's `AddrTranslator` doc comment explicitly names the containerized case: "translates addresses between the execution context of the host process and the plugin. For example, if the plugin is in a container, the file path for a Unix socket may be different between the host and the container." [go-plugin-runner]
- go-plugin's handshake is a single line of text on the plugin's stdout: `CORE-PROTOCOL-VERSION|APP-PROTOCOL-VERSION|NETWORK-TYPE|NETWORK-ADDR|PROTOCOL` (e.g. `1|3|unix|/path/to/socket|grpc`); `NETWORK-TYPE` must be `unix` or `tcp`, `PROTOCOL` is `netrpc` or `grpc`. `PLUGIN_MIN_PORT`/`PLUGIN_MAX_PORT` env vars constrain the ephemeral TCP range. [go-plugin-internals]
- go-plugin's default subprocess backend (`CmdRunner`) implements `Kill()` as `cmd.Process.Kill()` on the single tracked PID only — it does not kill a process group or any children the plugin itself spawned. [go-plugin-runner]
- go-plugin's liveness probe is platform-split at the same conceptual point: POSIX uses `proc.Signal(syscall.Signal(0))` (signal-0 probe, no actual signal delivered); Windows uses `syscall.OpenProcess` + `GetExitCodeProcess`, checking for `STILL_ACTIVE (259)`. [go-plugin-runner]
- go-plugin issue #136 ("client.Kill() does not kill child processes") documents that a plugin's own spawned children become orphans after `Kill()`; the community-proposed fix is Unix process-group kill (`Setpgid: true` at spawn, then `syscall.Kill(-pid, syscall.SIGKILL)`), which has no direct equivalent on Windows — the Windows kernel-enforced equivalent is a Job Object with `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`, which kills every process in the job tree including grandchildren when the job handle is closed. [go-plugin-issue-136]
- vm2 (a widely used Node.js in-process "sandbox" for untrusted JS) accumulated at least 7 distinct sandbox-escape CVEs from Oct 2022 through Jul 2023 (CVE-2022-36067, CVE-2023-29017, CVE-2023-29199, CVE-2023-30547, CVE-2023-32314, CVE-2023-37466, CVE-2023-37903, plus GHSA-g644-9gfx-q4q4 disclosed with no available patch), and was formally deprecated with its README updated to state "The library contains critical security issues and should not be used for production!" [vm2-ghsa-7jxr]
- vm2's CVE-2023-29017 root cause: vm2 did not properly handle host objects passed to `Error.prepareStackTrace` during unhandled async errors, allowing RCE. [vm2-ghsa-7jxr]
- vm2's CVE-2023-32314 mechanism: V8 itself invokes `err.name.toString` inside `prepareStackTrace` directly, bypassing vm2's own Proxy-based wrapper layer in `vm2/lib/bridge.js`, because that code path is called by the V8 engine rather than through vm2's proxied object graph. [vm2-ghsa-7jxr]
- containerd's v1 shim design (CLI-invocation per lifecycle call) was explicitly rejected for VM-based runtimes because "more VM based runtimes have internal state and more abstract actions" than a stateless CLI-per-call model can represent — the v2 redesign's origin is a leaky-abstraction problem: VM lifecycle didn't fit the v1 shape at all, not a performance tweak. [containerd-shim-v1-proposal]
- Kata Containers' shim v2 adaptation required structural changes beyond swapping a binary: the shim self-reports its serving address back to containerd via stdout (rather than containerd dictating it), enabling one shim per pod instead of one shim per CLI invocation, and moved the `Stats` RPC's implementation into the shim itself so it can represent a whole VM's state, not just a process's. [kata-shim-v2-issue]
- A live containerd bug (issue #13849, filed ~3 weeks before this research) shows the "stable regardless of backend" claim still leaks under stress: `containerd-shim-runc-v2` can end up with PID 1 dead (OOM-killed) but the shim itself alive in `futex_wait_queue` with zero children, never emitting a task-exit event and hanging all further API calls against that container — observed under high swap pressure. Abstraction stability and correctness-under-all-failure-modes are different guarantees; only the first is consistently achieved. [containerd-shim-v1-proposal]
- go-plugin's handshake (`HandshakeConfig` + magic-cookie key/value) is explicitly a UX guard, not a security boundary — its stated purpose is a friendly error when a plugin binary is executed directly or pointed at a plugin-free directory, not authentication. The actual security property go-plugin provides is OS-process isolation (crash and memory-space containment), inherited for free from subprocess use, not added by the RPC/handshake layer. [go-plugin-pkg-docs]
- Vault chose out-of-process plugins specifically because "dynamic library loading is not acceptable for security reasons" for a secrets-management product, and separately supports plugin *multiplexing* (one process serving all mounts of a given plugin type across namespaces) as a resource-efficiency layer bolted on top of, not a replacement for, per-mount process isolation. Vault enforces storage isolation independently via a per-mount `BarrierView` with a unique key prefix at the encryption layer — process isolation and storage-access isolation are two separately-enforced mechanisms in the same product. [vault-plugin-arch]

## SOURCES

**cri-proto**
URL: https://raw.githubusercontent.com/kubernetes/cri-api/release-1.30/pkg/apis/runtime/v1/api.proto
Accessed: 2026-08-17
Quote: "The CRI default is POD, but the v1.PodSpec default is CONTAINER. The kubelet's runtime manager will set this to CONTAINER explicitly for v1 pods."

**oci-runtime-spec**
URL: https://raw.githubusercontent.com/opencontainers/runtime-spec/main/runtime.md
Accessed: 2026-08-17
Quote: "Unless otherwise stated, generating an error MUST leave the state of the environment as if the operation were never attempted - modulo any possible trivial ancillary changes such as logging."

**containerd-shim-v2**
URL: https://raw.githubusercontent.com/containerd/containerd/main/core/runtime/v2/README.md
Accessed: 2026-08-17
Quote: "containerd, the daemon, does not directly launch containers. Instead, it acts as a higher-level manager... The v2 API is minimal and scoped to the execution lifecycle of a container."

**go-plugin-runner**
URL: https://github.com/hashicorp/go-plugin/blob/main/runner/runner.go
Accessed: 2026-08-17
Quote: "translates addresses between the execution context of the host process and the plugin. For example, if the plugin is in a container, the file path for a Unix socket may be different between the host and the container."

**go-plugin-internals**
URL: https://github.com/hashicorp/go-plugin/blob/main/docs/internals.md
Accessed: 2026-08-17
Quote: "1|3|unix|/path/to/socket|grpc"

**go-plugin-issue-136**
URL: https://github.com/hashicorp/go-plugin/issues/136
Accessed: 2026-08-17
Quote: "client.Kill() does not kill child processes"

**vm2-ghsa-7jxr**
URL: https://github.com/advisories/GHSA-7jxr-cg7f-gpgv
Accessed: 2026-08-17
Quote: "The library contains critical security issues and should not be used for production!"

**containerd-shim-v1-proposal**
URL: https://github.com/containerd/containerd/issues/2426
Accessed: 2026-08-17
Quote: "More VM based runtimes have internal state and more abstract actions"

**kata-shim-v2-issue**
URL: https://github.com/kata-containers/runtime/issues/485
Accessed: 2026-08-17
Quote: "the shim writes the serving address back to containerd through stdout"; "stats function is moved to shim, making the shim more self-contained"

**vault-plugin-arch**
URL: https://developer.hashicorp.com/vault/docs/plugins/plugin-architecture
Accessed: 2026-08-17
Quote: "dynamic library loading is not acceptable for security reasons"

**go-plugin-pkg-docs**
URL: https://pkg.go.dev/github.com/hashicorp/go-plugin
Accessed: 2026-08-17
Quote: "plugins over a real network are not supported and will lead to unexpected behavior"

## SYNTHESIS

Across CRI, the OCI runtime spec, and containerd shim v2 — three independently evolved but interoperating systems — the same shape recurs for a handle that must swap confinement backends without the caller's code changing: a small closed verb set (create/start → run → kill/stop → delete, plus a blocking wait-for-exit and a state/status query); an opaque backend-owned identity string the caller never interprets, only round-trips; stdio wired through filesystem handles (fifos/pipes/sockets) rather than embedded in the control-plane call, so the data plane can scale independently of the control plane; and asynchronous, ordered exit/event reporting rather than a synchronous return value. go-plugin — a different lineage entirely (RPC plugin framework, not container orchestration) — converges on the identical shape in Go interface form, down to an `ID()` that is deliberately typed as "pid or container ID" in its own doc comment.

The single most actionable, least obvious pattern for PDPP: every system studied keeps backend-specific configuration OUT of the shared schema — containerd passes it through an opaque `google.protobuf.Any options` field or an out-of-band shim config file, not as new fields on the shared request messages. PDPP's spawn-handle Create/Start/Kill/Wait signature should stay backend-agnostic, with Docker-specific, OS-native-specific, or browser-specific tuning riding through an opaque per-backend config blob rather than growing the shared interface.

The clearest trap for PDPP's plain-child-process backend specifically: process-tree kill is not free and does not fall out of "kill the PID." go-plugin's own unfixed issue #136 shows the default subprocess backend orphans a plugin's children on `Kill()`, and the fix (Setpgid + negative-PID kill on Unix, Job Objects on Windows) is backend-specific plumbing that must be deliberately engineered, not assumed. Container/namespace backends get this "for free" structurally — killing the cgroup or namespace kills everything inside it — which is a real robustness argument for containers as a *kill boundary*, independent of their value as a security boundary. containerd's own documented PID-namespace reparenting gotcha reinforces that even within namespaced backends, "kill top-level PID and assume the tree dies" is not a safe universal assumption; the shim must actively act as a sub-reaper.

vm2's CVE history is the negative precedent that anchors why PDPP's enforcement layer cannot be purely language-level: every one of its ~7 escapes routes through the same structural gap — V8-internal machinery (stack-trace preparation, Proxy traps, Promise `@@species`, custom-inspect) that runs host-side code paths a Proxy-based object-graph wrapper cannot intercept, because those paths are invoked directly by the engine rather than through the sandbox's own wrapped references. That recurrence pattern — fix the specific exploit, leave the general seam, watch a structurally similar bug reappear one release later — is characteristic of "enumerate and block dangerous APIs" sandboxes, not "the guest has no capability to reach the host by construction" ones. This is why "declared capabilities enforced in-process via language tricks" should never be labeled a security boundary in PDPP's design doc — only a real OS/kernel confinement backend (Docker, OS-native sandbox) makes an enforcement claim meaningful; anything else is "unsandboxed" or "best-effort" regardless of how the capability manifest is worded.

Also worth internalizing before locking an interface: go-plugin's own docs are explicit that its RPC/handshake layer is not itself a security boundary — the boundary is whichever OS/VM primitive actually separates address spaces, and the RPC layer is just how the two sides talk once that separation exists. PDPP should not conflate "we have a structured API between engine and connector" with "we have confinement"; the two are orthogonal, and the API should be designed to work identically whether or not real confinement sits behind it.
