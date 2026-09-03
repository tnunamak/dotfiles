---
title: "Cross-platform process sandboxes do not share one equivalent guarantee; a portable hostile-code boundary requires a VM or an OS-specific policy plus explicit broker design"
date: 2026-08-31
topic: cross-platform-connector-runtime
tags: [sandboxing, namespaces, seatbelt, appcontainer, chromium, virtual-machines]
status: settled
sources: [linux-primitives, bubblewrap, seccomp, macos-app-sandbox, seatbelt, endpoint-security, windows-appcontainer, windows-jobs, wsl, chromium-sandbox, gvisor, nsjail, docker-vm, container-escapes]
source_session: waspflow-res-sandbox-cross-os-0831:019ab19b-fde4-4f44-84e4-ea11db55019e
---

> **Headline findings**
>
> - There is no portable native-process primitive with the same semantics on Linux, macOS, and Windows. A connector runtime must either own three policy implementations or run a common Linux workload inside a VM/microVM.
> - On Linux, `CLONE_NEWNET` plus a carefully constructed mount/user/IPC/PID namespace and inherited seccomp filter can deny direct host network and most host IPC. Namespaces are not a complete security boundary: inherited file descriptors, mounted host sockets, privileged capabilities, kernel/runtime bugs, and deliberately shared namespaces defeat the intended guarantee.
> - On macOS, Seatbelt (`sandbox_init`/`sandbox-exec`) and the App Sandbox are kernel-enforced, deny-by-default policy systems that can deny file, Mach-service, and network operations. They are policy sandboxes, not containers; already-open descriptors and brokered/inherited capabilities remain usable. `sandbox-exec` is deprecated and App Sandbox has signing/entitlement constraints.
> - On Windows, AppContainer/LPAC can deny access to securable objects and network by capability, but regular Win32 applications are not automatically AppContainers. Restricted tokens and job objects are useful defense-in-depth and lifecycle/resource controls, not a standalone “cannot reach host IPC/network” guarantee. Named objects and handles remain an ACL/inheritance problem.
> - WSL 2 and Docker Desktop provide a Linux VM, but integration features intentionally connect guest and host filesystems, processes, and networking. Treat the VM as the boundary only after disabling or tightly brokering those integrations.
> - Chromium is the strongest practical prior art: it uses a broker architecture and a per-OS stack (Linux namespaces/seccomp, macOS Seatbelt, Windows restricted token/job/desktop/integrity/AppContainer layers). Security tools similarly layer primitives; they do not pretend one cross-platform API has identical enforcement.
> - gVisor, Kata, and Docker/OCI runtimes provide portable *workload interfaces*, not portable host guarantees. gVisor and Kata are Linux-side technologies; Docker Desktop makes the Linux runtime portable by inserting a VM. `nsjail` and `bubblewrap` are Linux-specific.

## Scope and vocabulary

The question is about a native child and all of its descendants, including programs it launches after `execve`/`CreateProcess`. “Prevent” below means “the kernel denies a direct attempt under the stated default configuration.” It does not mean that a compromised broker, a pre-opened handle, a permitted host service, or a kernel/hypervisor vulnerability cannot be abused.

The reliable design rule is: create the boundary before untrusted code runs, close or mark all unintended inherited descriptors/handles, and expose required host functionality through a small broker. A sandbox that merely changes the visible filesystem or kills a process tree is not equivalent to a deny-by-default resource policy.

## Comparison

| OS / primitive | What it actually isolates | Direct host IPC / socket / network result | Main escape or weakening conditions |
|---|---|---|---|
| Linux namespaces | Separate views of selected kernel resources. IPC namespaces isolate System V IPC and POSIX message queues; network namespaces isolate devices, protocol stacks, routes, and ports; mount/PID/user namespaces isolate additional views. | With a new network namespace containing only loopback, direct host TCP/UDP and host network interfaces are unavailable. A new IPC namespace blocks SysV/POSIX IPC. Unix pathname sockets are still reachable if their containing path is mounted; abstract Unix sockets require care because sharing the network namespace exposes the abstract socket namespace. | `--share-net`, host-network joins, bind-mounted `/run` or socket paths, inherited FDs, host devices, `CAP_SYS_ADMIN`/other capabilities, user-namespace/kernel vulnerabilities, and namespace setup mistakes. Namespaces share the host kernel. |
| Linux bubblewrap | A policy-construction helper around namespaces, mounts, user IDs, capabilities, `no_new_privs`, and optional seccomp. It is not itself a complete policy. | `--unshare-net` gives only private loopback; `--unshare-ipc` isolates SysV/POSIX IPC; filesystem masking can hide pathname sockets. It can therefore block the ordinary direct paths, if the caller supplies the right flags and does not bind them back in. | The project explicitly says protection is determined by the arguments. `--share-net`, broad binds, exposed `/proc`/`/run`, inherited descriptors, missing seccomp, and policy-generation bugs can undo it. |
| Linux seccomp-BPF | Filters syscall numbers and scalar arguments and is inherited by fork/exec when those syscalls remain allowed. | It can remove whole syscall classes, but it cannot by itself express a general host/network policy: the filter cannot dereference pointer arguments such as a `sockaddr`. It is therefore an attack-surface reduction layer, not a complete filesystem, IPC, or network sandbox. | Incorrect architecture checks, overly broad allowlists, `ptrace`/user-notification mistakes, kernel bugs, and already-open FDs. The kernel documentation explicitly says seccomp “isn't a sandbox.” |
| Linux cgroups v2 | Hierarchical accounting and resource control for process groups: memory, CPU, I/O, PIDs, and related controllers. | No direct IPC or network confidentiality/isolation guarantee. It can bound resource consumption and make process-tree cleanup reliable when combined with a supervisor. | It is not an access-control boundary. Resource limits can be overcommitted or best-effort for some controllers; a process can still reach every resource its namespaces, credentials, and descriptors permit. |
| macOS App Sandbox | Signed-app entitlement policy restricting access to user data, files, network, hardware, and selected services. | With no network entitlement, ordinary socket access is denied; file and service access is deny-by-default except for entitlements, security-scoped grants, and brokered operations. It can protect a child tool embedded in a sandboxed app, but exact child/signing/entitlement behavior must be tested for the shipping bundle. | Entitlements are coarse capabilities; inherited/open descriptors remain usable. App Sandbox is tied to code signing and entitlements, and is not a general arbitrary-command container. A permitted broker, Mach service, TCC-approved path, or OS vulnerability expands the reachable surface. |
| macOS Seatbelt (`sandbox_init`, `sandbox-exec`) | Per-process TrustedBSD MAC profile, with rules for files, Mach services, syscalls, network, IOKit, and other resources. Chromium uses custom profiles. | A deny-default profile can deny new file, Mach IPC/service, and network operations, so it is the closest native macOS analogue to a connector policy. It does not revoke previously opened FDs or OS facilities; a child inherits the process sandbox. | `sandbox-exec` is deprecated; the profile language/API is under-documented and Apple can change behavior. Broad `(allow ...)` rules, inherited descriptors, permitted Mach services, and profile mistakes are common escape paths. Seatbelt shares the XNU kernel and is not a VM. |
| macOS Endpoint Security | A privileged/system-extension C API for event notification and authorization. It can observe or authorize selected executions, forks, signals, filesystem and other security events. | Not a child sandbox by itself. It can act as a host policy enforcement/broker component for supported events, but it does not turn an arbitrary child into a deny-by-default network/IPC container. | Requires entitlement, privilege, user/TCC approval, correct event coverage, and timely responses. Unsupported/unmonitored paths and a compromised authorization client remain outside the guarantee. |
| Windows AppContainer / LPAC | Low-box token with package/capability SIDs, low integrity, object-manager/DACL checks, and an isolated named-object namespace. | Without network capability, Windows documents that an AppContainer cannot access the network; with capability grants, network access is restored according to the capability and firewall model. Access to files, registry, devices, credentials, named objects, and other processes is denied unless ACLs/capabilities permit it. | It only applies when the process is actually launched in an AppContainer; MSIX desktop apps are often full-trust unless configured otherwise. Explicit ACL grants, brokered COM/RPC, inherited handles, objects with weak/null DACLs, and AppContainer/Windows vulnerabilities weaken it. |
| Windows restricted token | Removes groups/privileges or marks SIDs deny-only; commonly used for low/untrusted Chromium processes. | By itself, no reliable network guarantee: Chromium's design notes that TCP/IP and some non-securable resources are not protected by the token alone. Named pipes, sections, events, files, and RPC depend on their security descriptors. | Null/weak DACLs, inherited handles, permissive brokers, token impersonation, and resources that are not securable. It must be paired with AppContainer, integrity levels, job/desktop restrictions, and broker policy. |
| Windows job object | Groups a process tree and applies limits such as kill-on-close, active-process count, UI restrictions, and resource accounting. | It can make descendant containment and cleanup predictable, but it does not deny arbitrary sockets or general IPC access. | A child created before assignment, a process that escapes the job through a broken launch path, nested-job constraints, and host objects controlled by ACLs. Use it for lifecycle and quotas, not as the resource boundary. |
| WSL 2 | A Microsoft-managed Linux kernel in a lightweight VM, with guest/host integration. | The VM separates Linux syscalls from the Windows kernel, but default WSL integration allows Windows executables from Linux, Windows drives under `/mnt`, `\\wsl$` access, and networking/localhost forwarding. It is not a hostile-code boundary while those bridges are available. | Interop, 9P/file sharing, localhost forwarding, mounted Windows files, `wsl.exe`/Windows process launch, VM/Hyper-V bugs, and privileged host services. It is useful as a Linux runtime, not automatically as a sealed sandbox. |

## What the Linux stack can and cannot guarantee

For a Linux connector that needs no host network, the defensible baseline is a fresh user/mount/PID/IPC/network namespace, a minimal read-only root, no host `/run` or device tree, dropped capabilities, `PR_SET_NO_NEW_PRIVS`, a restrictive inherited seccomp filter, and cgroup v2 limits. The network namespace is the part that blocks ordinary host TCP/UDP. The mount policy is the part that blocks pathname Unix sockets. The IPC namespace is the part that blocks SysV/POSIX queues and shared-memory objects. Seccomp reduces the kernel attack surface but should not be described as the policy itself.

For an HTTP connector, “allow only these hosts” is not supplied by a bare network namespace: a private namespace with a proxy or a supervisor-owned firewall is needed. DNS is also a policy surface; resolving names outside the policy and then allowing arbitrary destination IPs is a confused-deputy failure. For a connector that needs a host service, pass one narrowly scoped broker FD or use an explicit proxy; do not mount the host's general-purpose socket directory.

The important Linux escape classes are structural rather than exotic:

1. An inherited connected socket, Unix socket, memfd, device FD, or directory FD remains usable even after the child enters a stricter namespace. Close-on-exec and an explicit FD allowlist are mandatory.
2. A bind mount or shared namespace can reintroduce host files, `/proc` data, abstract sockets, devices, or control APIs.
3. `CAP_SYS_ADMIN`, writable cgroup/mount control, host PID visibility, or a privileged container changes the threat model.
4. The host kernel and runtime remain in the trusted computing base. CVE-2022-0185 demonstrated that a Linux kernel heap overflow reachable through an unprivileged user namespace could produce privilege escalation; CVE-2019-5736 demonstrated that a container runtime's `/proc/self/exe` FD handling could let a container overwrite host `runc`. Patching is part of the boundary guarantee.

## What macOS adds and omits

Seatbelt is closer to a capability policy than to Linux namespaces: it can name Mach services and resource classes, which is valuable for host IPC. App Sandbox is the supported product/deployment model, but its entitlement and signing requirements make it a poor drop-in for arbitrary third-party native connector binaries. The documented `sandbox-exec` command is deprecated, even though Chromium and other security-sensitive software continue to use the underlying Seatbelt API/profile machinery.

The most important implementation detail is temporal: Seatbelt restricts operations from the point it is applied; it does not retroactively revoke access represented by already-open descriptors. A launcher must create only intended pipes, apply the sandbox before exposing untrusted input, and avoid passing the Tauri process's inherited descriptors or broad Mach bootstrap capabilities. Endpoint Security complements this with host-wide monitoring/authorization, but it is an enforcement service, not a portable replacement for per-process confinement.

## What Windows adds and omits

AppContainer is the Windows primitive with the clearest direct answer to the question. A low-box token with no network capability and carefully authored ACLs can deny ordinary network and object access. However, the guarantee is resource-specific: Windows security descriptors decide access, and a permissive descriptor or explicit broker grant wins. Named-object namespaces are isolated by default for AppContainer apps, but cross-boundary sharing is intentionally possible through ACLs and qualified names.

Restricted tokens and jobs remain useful. Chromium uses them because the renderer needs a process-tree kill boundary, UI restrictions, integrity separation, and a very small set of brokered handles. A job object is especially valuable for descendants that do not cooperate. It should not be sold as “network isolation.” A full-trust packaged desktop app also should not be assumed to be AppContainer merely because it has package identity.

WSL 2 is the practical way to reuse a Linux connector binary on Windows, but its developer-friendly bridges are precisely the paths a hostile connector would use to reach the host. If WSL is chosen for isolation, run a dedicated distribution/VM, disable Windows-process interop and broad drive mounts, control networking, and expose only an explicit broker. At that point a dedicated VM or microVM is often a clearer product boundary.

## Browser and security-tool precedent

Chromium's architecture is the most relevant precedent for a connector runtime:

- Linux: a brokered multi-process model with namespaces and seccomp-BPF as current layers, plus filesystem and privilege reduction. The kernel's seccomp documentation explains why it is a surface-reduction layer, not the whole policy.
- macOS: custom Seatbelt profiles applied to child process types. Chromium's design says profiles explicitly list files, Mach services, IPC, sysctls, and IOKit operations.
- Windows: restricted/untrusted tokens, job objects, desktop/UI restrictions, integrity levels, process mitigations, and optional AppContainer. Required resources are acquired by the browser and brokered into the renderer rather than allowing the renderer to discover host resources itself.

This is also the broad security-tool pattern: make a small supervisor/broker trusted, launch the untrusted child with a deny-by-default OS policy, pass only explicit capabilities, and keep resource limits/lifecycle controls separate from access control. The browser does not seek a single “sandbox API”; it uses per-OS adapters behind one higher-level process model.

## Portability options

| Option | What is portable | What is not portable | Verdict for a connector runtime |
|---|---|---|---|
| OCI/container runtime (`runc`, Docker Engine) | Image format, lifecycle, much of the process contract. | Native enforcement: Linux namespaces/cgroups/seccomp; Windows process or Hyper-V isolation; macOS normally a Linux VM. | Good workload API, not a same-guarantee native sandbox. Never infer security from OCI compatibility alone. |
| gVisor (`runsc`) | Linux container-facing interface and OCI integration. | It requires Linux and a Linux-compatible kernel/host integration; it is not a macOS/Windows native sandbox. | Stronger Linux defense-in-depth because a user-space application kernel handles many syscalls, but still requires a VM or OS boundary around the Linux host for cross-OS deployment. |
| nsjail | Linux namespaces, cgroups, rlimits, and seccomp-BPF. | No macOS or Windows equivalent implementation. | Useful Linux backend, not a portable abstraction. |
| Kata Containers | OCI/CRI-shaped lifecycle over a lightweight VM with its own guest kernel. | VM/hypervisor availability, guest integration, performance, and host platform support. | Closest existing “same Linux workload, stronger boundary” option; on macOS/Windows it still needs the platform's VM layer. |
| Docker Desktop / similar | Docker CLI/images and a Linux VM on macOS/Windows; Docker documents VM-backed VMM choices by OS. | Host integration semantics, file sharing, localhost networking, resource controls, and trust in the desktop daemon. | A practical common Linux runtime. For hostile connectors, configure it as a dedicated VM boundary and disable broad mounts/host sockets; do not treat the default developer experience as sealed. |
| Native abstraction in the application | A common policy schema, capability vocabulary, broker protocol, and lifecycle API. | The actual enforcement and audit evidence for Linux, macOS, and Windows. | Recommended only if the schema is honest about per-OS support and has explicit “strong / brokered / degraded” states. |

There is therefore a portable abstraction at the *control-plane* level, not at the *kernel-guarantee* level. A credible API can say `network: none`, `network: proxy(endpoint-set)`, `filesystem: allowlist`, `ipc: broker-only`, and `descendants: kill-on-exit`; each OS backend must prove those claims with tests. If an OS backend cannot prove direct host-IPC/network denial, it should report degraded isolation rather than silently map the request to an ordinary child process.

## Design conclusion for PDPP Data Connect

For heterogeneous native connectors, the decision is not “which flags are equivalent?” It is “which guarantee is the product willing to promise?”

- If the promise is **native descendants cannot reach arbitrary host IPC/sockets/network**, Linux can meet it with a carefully audited namespace/mount/seccomp/cgroup launcher; macOS can approach it with Seatbelt plus a strict broker/FD discipline; Windows needs AppContainer/LPAC plus ACLs, handle hygiene, and jobs. These are three security implementations and three test suites.
- If the promise must be **the same for all supported hosts**, use one Linux connector runtime inside a dedicated VM/microVM and expose host access through a small, explicit host broker. Docker Desktop/WSL can supply the Linux VM, but only after host bridges are constrained; a purpose-built VM often makes the policy easier to reason about.
- If either is too heavy, the honest product is **Linux-strong, macOS/Windows-degraded**, with a visible capability report and no claim that a native child is unable to reach arbitrary host services.

## SOURCES

**linux-primitives**  
URL: https://man7.org/linux/man-pages/man7/namespaces.7.html and https://man7.org/linux/man-pages/man7/ipc_namespaces.7.html  
Accessed: 2026-08-31  
Grounds the namespace inventory and IPC isolation semantics.

**bubblewrap**  
URL: https://github.com/containers/bubblewrap/blob/main/README.md  
Accessed: 2026-08-31  
Grounds bubblewrap's namespace options, private-loopback behavior, and explicit statement that its security level depends on caller-supplied arguments.

**seccomp**  
URL: https://docs.kernel.org/userspace-api/seccomp_filter.html  
Accessed: 2026-08-31  
Grounds inheritance across fork/exec, pointer-argument limitations, ptrace caveats, and the statement that seccomp is not a complete sandbox.

**cgroups**  
URL: https://docs.kernel.org/admin-guide/cgroup-v2.html  
Accessed: 2026-08-31  
Grounds cgroup v2's resource-control model and hard/best-effort/overcommit distinctions.

**macos-app-sandbox**  
URL: https://developer.apple.com/documentation/security/app-sandbox and https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html  
Accessed: 2026-08-31  
Grounds entitlement-based resource restriction, code-signing configuration, and the sandbox daemon's violation reporting.

**seatbelt**  
URL: https://www.chromium.org/developers/design-documents/sandbox/osx-sandboxing-design/ and https://man.freebsd.org/cgi/man.cgi?manpath=macOS+13.6.5&query=sandbox-exec&sektion=1  
Accessed: 2026-08-31  
Grounds Seatbelt's per-process policy behavior, already-open-FD limitation, custom profiles, and `sandbox-exec` deprecation.

**endpoint-security**  
URL: https://developer.apple.com/documentation/endpointsecurity  
Accessed: 2026-08-31  
Grounds Endpoint Security's monitoring/authorization role, entitlement, privilege, and event model.

**windows-appcontainer**  
URL: https://learn.microsoft.com/en-us/windows/win32/secauthz/implementing-an-appcontainer and https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/app-capability-declarations  
Accessed: 2026-08-31  
Grounds AppContainer SIDs/capabilities, low integrity, network capability behavior, named-object isolation, and full-trust packaged desktop caveat.

**windows-jobs**  
URL: https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects and https://learn.microsoft.com/en-us/windows/win32/secauthz/job-object-security-and-access-rights  
Accessed: 2026-08-31  
Grounds job assignment irreversibility, process-tree/lifecycle controls, nesting, and ACL-based job security.

**wsl**  
URL: https://learn.microsoft.com/en-us/windows/wsl/compare-versions, https://learn.microsoft.com/en-us/windows/dev-environment/wsl-interop, and https://learn.microsoft.com/en-us/windows/wsl/networking  
Accessed: 2026-08-31  
Grounds WSL 2's lightweight VM architecture and its Windows process, filesystem, and networking interop.

**chromium-sandbox**  
URL: https://chromium.googlesource.com/chromium/src/%2B/refs/heads/main/docs/design/sandbox.md, https://chromium.googlesource.com/chromium/src/sandbox/%2B/refs/heads/main/mac/, and https://www.chromium.org/developers/design-documents/sandbox/osx-sandboxing-design/  
Accessed: 2026-08-31  
Grounds Chromium's broker model and per-OS use of restricted tokens, jobs, integrity/desktop controls, AppContainer, seccomp/namespaces, and Seatbelt.

**gvisor**  
URL: https://gvisor.dev/docs/ and https://gvisor.dev/docs/user_guide/install/  
Accessed: 2026-08-31  
Grounds gVisor's user-space application kernel model and Linux 5.6+/x86_64/ARM64 support.

**nsjail**  
URL: https://github.com/google/nsjail  
Accessed: 2026-08-31  
Grounds nsjail's Linux-only namespaces/cgroups/rlimits/seccomp design.

**kata**  
URL: https://kata-containers.github.io/kata-containers/quick-start-guide/ and https://github.com/kata-containers/kata-containers/blob/main/docs/design/virtualization.md  
Accessed: 2026-08-31  
Grounds Kata's OCI/CRI interface and VM/guest-kernel isolation model.

**docker-vm**  
URL: https://docs.docker.com/desktop/features/vmm/ and https://docs.docker.com/desktop/troubleshoot-and-support/faqs/linuxfaqs/  
Accessed: 2026-08-31  
Grounds Docker Desktop's Linux VM and per-OS VMM architecture.

**container-escapes**  
URL: https://nvd.nist.gov/vuln/detail/CVE-2019-5736, https://kubernetes.io/blog/2019/02/11/runc-and-cve-2019-5736/, and https://nvd.nist.gov/vuln/detail/CVE-2022-0185  
Accessed: 2026-08-31  
Grounds the runc runtime escape and Linux kernel user-namespace-reachable privilege-escalation examples.

## SYNTHESIS

The strongest portable product boundary is a common workload protocol over a VM-backed Linux runtime, with host integration reduced to an explicit broker. Native sandboxes remain valuable for latency, footprint, and platform integration, but they should be separate backends with separate conformance tests and an explicit degraded mode. The security claim belongs to the tested backend configuration, not to the words “sandbox,” “container,” or “cross-platform.”
