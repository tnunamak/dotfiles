---
title: "A bundled Linux VM makes cross-platform connector behavior uniform, but its real cost is a resident guest, mutable disk image, OS integration, and a permanent compatibility program"
date: 2026-08-31
topic: cross-platform-connector-runtime
tags: [virtual-machine, containers, desktop, apple-virtualization, wsl2, gpu]
status: settled
sources: [docker-vmm, docker-settings, docker-disk, docker-mac, docker-windows, docker-wsl, docker-gpu, docker-permissions, podman-machine, podman-init, podman-machine-desktop, colima, lima, rancher-install, rancher-vz, rancher-history, rancher-settings, rancher-wsl-global, apple-vz, apple-rosetta, wsl-install, wsl-config, wsl-troubleshooting, hyperv-nested, firecracker-spec, firecracker-faq, firecracker-prod]
source_session: WASPFLOW_LANE_MARKER:res-bundled-vm-0831:66b6173a-4a5d-43f7-ab29-e91d8f8ef804
---

> **Headline findings**
>
> - A bundled Linux VM is a credible way to run the same Linux-only backend on macOS, Windows, and Linux. It moves most OS variance below the guest boundary, but it does not make the product small or maintenance-free.
> - Plan for two storage numbers: a compressed/download payload and a growing writable guest disk. Real tools expose 50–100 GiB VM disks (Colima: 100 GiB; Rancher Desktop: 100 GiB; Podman supports an explicit disk-size setting), even though the initial sparse file may consume much less. A connector product should budget roughly 1–3 GiB compressed for a deliberately minimal guest/runtime, 4–8 GiB installed before connector/browser assets, and 10–30 GiB of practical free disk for updates, caches, browser binaries, logs, and rollback. The last three figures are engineering estimates, not vendor minimums.
> - A small headless connector VM can start in the low seconds after image extraction and guest boot; a Firecracker-style microVM can reach documented sub-125-ms guest-user-space boot, but Firecracker is Linux/KVM-specific and does not solve macOS/Windows host integration. Treat first install/provisioning and cold start as separate UX states.
> - RAM is both a reservation and a working-set problem. Docker documents 4 GiB as the minimum VM allocation for Docker VMM and 50% of host RAM as the default limit in several VM modes; Colima defaults to 2 GiB; Rancher recommends 8 GiB system RAM and 4 CPUs on Windows. For a browser-capable connector, 4 GiB guest memory is a sensible lower target and 8 GiB is safer when Chromium, fonts, and several pages are live.
> - Apple Virtualization.framework is the native macOS substrate. WSL2 is the practical Windows substrate, with Hyper-V as the more explicit VM boundary. Both require hardware virtualization and can be blocked or complicated by a host that is itself a VM, enterprise policy, or another hypervisor.
> - “Identical backend” does not mean “identical host UX.” File mounts, networking, notifications, auto-start, updates, signing, firewall prompts, sleep/resume, and diagnostics still need per-OS adapters. Headed browser GPU behavior is the sharpest boundary: Windows Docker supports NVIDIA GPU paravirtualization only with WSL2; this is not a portable guarantee for macOS, Intel graphics, or a generic embedded VM.

## Question and scope

This note estimates the product cost of shipping a Linux VM or container runtime inside a cross-platform desktop app so a Linux-only backend can execute consistently on macOS, Windows, and Linux. “Bundled” means the app owns or bootstraps the guest/runtime rather than requiring the user to install Docker Desktop, Podman Desktop, WSL, Colima, or Lima separately.

The target workload matters. An HTTP-only connector is much cheaper than a connector that launches native descendants, Playwright/Chromium, X11/Wayland, fonts, or a headed browser. The estimates below assume a long-lived local service with occasional connector jobs, not a general-purpose Kubernetes distribution.

## What real products actually ship

### Docker Desktop

Docker Desktop runs Linux containers inside a Linux VM on macOS and Windows. Current macOS installations use Apple Virtualization.framework by default; HyperKit is legacy on Intel Macs. On Windows, WSL2 is the default backend, with Hyper-V and Docker VMM alternatives. Docker’s current VMM documentation says Docker VMM requires at least 4 GiB allocated to the Linux VM, and that it is designed to reclaim idle memory and reduce engine/container startup time. [docker-vmm]

Docker’s resource UI exposes CPU, memory, swap, disk usage limits, and a Linux disk image. Its documented default memory limit is 50% of host memory in the modes where the setting applies, with 1 GiB default swap. Resource Saver can shut down the Linux VM while idle and restart it when containers run; Docker documents a 3–10 second restart. [docker-vmm] [docker-settings](https://docs.docker.com/desktop/settings-and-maintenance/settings/)

The disk image is a large sparse/virtual file rather than a fixed amount of immediately consumed host storage. Docker’s Mac FAQ shows an example with a 64 GiB maximum image whose actual consumption is about 2.2 GiB, and explains that tools may display the maximum rather than actual usage. Image deletion and reclamation are separate concerns. [docker-disk](https://docs.docker.com/desktop/troubleshoot-and-support/faqs/macfaqs/)

The operational lesson is important for an embedded app: a VM can have a generous logical ceiling without consuming it at install time, but the product must show and manage actual usage, free space, upgrades, failed downloads, and reset/repair. Docker also needs a privileged helper for selected macOS integrations such as privileged ports and host configuration, although it offers an advanced install mode that avoids some privileged setup. [docker-permissions]

### Podman Desktop and Podman machine

Podman’s own documentation states the core constraint plainly: Linux containers need a Linux kernel, so Podman on macOS and Windows requires a VM. The supported providers are QEMU on Linux, libkrun or Apple Hypervisor on macOS, and WSL or Hyper-V on Windows. [podman-machine]

Podman machine makes the resource model user-visible: CPU count, memory in MiB, disk size in GiB, image path/URL, rootful mode, mounts, and provider. Its documented default guest image is Fedora CoreOS; it generates SSH keys and connections, and Fedora CoreOS updates are detected and installed automatically, with reboots during upgrades. [podman-init]

That is a useful lower bound on maintenance for a product-owned runtime: an image is an operating system release stream, not a one-time asset. The app needs an update policy, compatibility testing, an interrupted-update recovery path, and a way to preserve or migrate connector state.

Podman Desktop exposes a particularly relevant Windows caveat: user-mode networking is required to route through the Windows session and is needed to reach resources behind the user’s VPN. On macOS ARM64, its default GPU-enabled LibKrun provider differs from Apple Hypervisor, while Intel Macs cannot use that GPU provider. [podman-machine-desktop](https://podman-desktop.io/docs/podman/creating-a-podman-machine)

### Colima and Lima

Colima is a compact example of a user-facing VM wrapper. Its current defaults are 2 CPUs, 2 GiB memory, and 100 GiB storage; the VM architecture is host by default, and the runtime is Docker by default. It supports QEMU, Apple’s `vz`, and experimental/targeted `krunkit` modes, plus Rosetta-based amd64 emulation on Apple Silicon. [colima]

Colima’s configuration documents the tradeoffs directly: `vz` needs macOS 13, VirtioFS is limited to macOS plus `vz`, QEMU commonly uses SSHFS or 9p, and nested virtualization is available only on supported Apple hardware/VM combinations. It also says the default home-directory mount is intended to provide a familiar UX. [colima]

Lima’s project description is the corresponding platform abstraction: Linux VMs with automatic file sharing and port forwarding, similar to WSL2, with templates for Docker, containerd, Podman, and Kubernetes. This makes Lima valuable prior art for an embedded runtime architecture, but it also shows the surface area that must be owned: guest provisioning, mounts, port forwarding, SSH/control channels, templates, and multiple container engines. [lima](https://github.com/lima-vm/lima)

### Rancher Desktop

Rancher Desktop demonstrates the “desktop product around a VM” cost. On Windows it requires WSL and hardware virtualization; its installation documentation recommends 8 GiB system RAM and 4 CPUs. On first launch it sets up the backend and downloads a VM image, which can take a while on a slow connection. [rancher-install]

On macOS, Rancher Desktop’s VZ option uses the native Virtualization.framework, and can enable Rosetta for x86_64 instructions in an ARM Linux guest. On Windows, WSL2 is the backend. Its documentation also notes that the uninstaller leaves data and WSL distributions behind, which is a reminder that uninstall, reset, and data-retention semantics are product features, not installer afterthoughts. [rancher-vz] [rancher-history](https://docs.rancherdesktop.io/blog/history-of-rancher-desktop/) [rancher-install]

Rancher’s current settings documentation gives macOS/Linux a 100 GiB default VM disk. Its Windows settings have a special limitation: WSL2 resource settings are global across WSL2 distributions, so a product cannot assume it owns an isolated RAM/CPU budget merely because it owns one distribution. [rancher-settings](https://docs.rancherdesktop.io/1.24/references/non-gui-settings/) [rancher-wsl-global](https://docs.rancherdesktop.io/blog/rancher-desktop-2-alpha-2/)

## Cost model

### Install size and writable storage

There is no single vendor number for “install size” because four layers are commonly conflated:

1. The desktop app, launcher, helper binaries, hypervisor/VMM, and CLI.
2. The compressed Linux kernel/root filesystem or VM image downloaded on first run.
3. The expanded guest disk, often sparse and copy-on-write.
4. Workload data: connector dependencies, Chromium/Playwright browsers, fonts, caches, logs, and update rollback copies.

For a deliberately narrow connector runtime, a reasonable initial product budget is:

| Component | Planning budget | Why |
| --- | ---: | --- |
| App + runtime binaries | 100–500 MiB | Depends on framework, architectures, signing, and bundled CLI tools. |
| Compressed guest/kernel/rootfs | 1–3 GiB | Estimate for a minimal Linux guest with the service and base libraries; validate with the actual image. |
| Expanded base guest | 2–6 GiB | Includes filesystem overhead and package metadata. |
| Browser/font/native assets | 1–5+ GiB | Chromium and multi-architecture/native dependency choices dominate this line. |
| Mutable working space | 5–20 GiB | Logs, caches, downloads, updates, and recovery headroom. |

Thus a 4–8 GiB first-run footprint and 10–30 GiB recommended free space are sensible product targets for a small connector runtime. They are not minimum requirements promised by Docker, Podman, or Rancher. General-purpose tools choose much larger logical disks: Colima defaults to 100 GiB and Rancher Desktop documents 100 GiB on macOS/Linux; Docker exposes a configurable disk image and Podman exposes `--disk-size`. [colima] [rancher-settings] [podman-init]

Multi-architecture distribution increases storage or build complexity. A single ARM64 guest is efficient on Apple Silicon and Windows ARM, but cannot execute x86_64-only native binaries without translation. Shipping both x86_64 and ARM64 guests increases download/update/test/signing work; shipping only x86_64 imposes emulation on ARM hosts.

### RAM

The guest’s configured RAM is not the entire app’s footprint. Add the VMM process, guest kernel/page tables, filesystem cache, control daemon, browser processes, and the desktop app. Dynamic reclaim helps but is not a guarantee that a browser-heavy workload will return memory quickly.

Observed product defaults span a meaningful range: Colima defaults to 2 GiB; Docker VMM requires 4 GiB allocated; Docker documents 50% of host RAM as a default VM limit in applicable modes; Rancher recommends 8 GiB system RAM and 4 CPUs for Windows installation. [colima] [docker-vmm] [docker-settings] [rancher-install]

For this workload, budget approximately 2 GiB guest RAM for HTTP-only connectors, 4 GiB for a normal browser-capable service, and 6–8 GiB when headed Chromium, several concurrent pages, or native tooling must coexist. Make the limit configurable and fail with a diagnostic that distinguishes “guest limit reached” from “host is under memory pressure.”

### Startup and lifecycle

There are at least five user-visible startup phases:

`app launch → VMM available → guest kernel boot → service ready → browser/connector ready`

Only the first two are usually described as “app startup.” First install adds image download, verification, disk creation, guest provisioning, package/browser installation, and possibly a reboot or OS-feature enablement. A warm VM can be kept resident, stopped after idle, or resumed from a snapshot; each policy trades RAM/CPU for latency.

Docker documents a 3–10 second restart after Resource Saver stops its VM. [docker-vmm] That is a useful UX expectation for a mature full VM, not a universal benchmark. Firecracker’s specification is much faster: up to 125 ms from `InstanceStart` to Linux `/sbin/init`, with a VMM memory overhead of at most 5 MiB for a 1-vCPU, 128 MiB configuration under its test conditions. [firecracker-spec]

Firecracker is not a drop-in cross-platform answer. It relies on KVM, is tested as a Linux host/guest VMM, and intentionally exposes a minimal device model. It is attractive for Linux hosts or a server-side worker, but embedding it in a macOS/Windows desktop would still require a host VM substrate and would lose much of its simplicity. Production operation also expects a jailer, cgroups/resource controls, patched host and guest kernels, and careful networking/storage setup. [firecracker-prod] [firecracker-faq](https://github.com/firecracker-microvm/firecracker/blob/main/FAQ.md)

Recommended UX: show first-run provisioning separately from ordinary “starting connector” progress; retain a health/repair command; keep the guest warm while the app is active; and make an idle-stop policy explicit. Do not promise sub-second cold start unless it is measured end-to-end with the real guest, service, browser, and host substrate.

### UX and integration

The Linux boundary improves backend reproducibility, but host integration becomes a contract:

- **Files:** mounts use VirtioFS, 9p, SSHFS, DrvFs, or a synchronization layer depending on OS/backend. Performance and file-event behavior differ. Keep hot runtime state inside the guest; use narrow explicit import/export paths rather than treating the host filesystem as a native Linux tree.
- **Networking:** localhost forwarding, DNS, proxy/PAC, VPN reachability, IPv6, firewall prompts, and port collisions vary. Podman specifically documents a Windows user-mode networking option for VPN access. [podman-machine-desktop]
- **Identity and permissions:** the service user, mounted-file ownership, secret storage, and privileged port behavior differ. Docker’s Mac installer may need a privileged helper or user-selected advanced setup. [docker-permissions]
- **Updates:** update the app, guest kernel, rootfs, service, browsers, and native dependencies as a tested unit. Preserve data across guest replacement; keep rollback until the new guest passes health checks.
- **Support:** collect host OS/build, CPU architecture, VMM/provider, guest image digest, resource limits, mount mode, and last lifecycle phase. “The connector failed” is not enough to debug a VM product.

The cost is therefore an additional platform product, not just a binary blob. The mature examples all expose settings, diagnostics, image lifecycle, reset behavior, and explicit provider choices because users eventually need them.

## OS-native substrates

### macOS: Apple Virtualization.framework

Apple documents Virtualization.framework as a high-level API for creating and managing VMs on Apple Silicon and Intel Macs. On macOS 13 and later on Apple Silicon, it supports running Intel binaries in ARM Linux VMs through Apple’s translation support. [apple-vz] [apple-rosetta]

This is the right default substrate for a macOS-owned app because it avoids shipping a second general-purpose hypervisor and aligns with the platform’s supported virtualization path. It does not remove the need to ship a Linux kernel/rootfs, configure virtual devices, implement networking and file sharing, handle entitlements/signing, and test each supported macOS/CPU combination.

Apple Silicon creates a strategic choice:

- ARM64 guest plus native ARM connector builds: best performance and lowest complexity.
- ARM64 guest plus Rosetta/x86 translation: useful for x86-only browser/native assets, but translation is an extra dependency and not identical to an x86 host.
- x86_64 guest emulation: broadest binary compatibility, materially worse performance/startup, and more testing.

### Windows: WSL2 and Windows Hypervisor Platform/Hyper-V

WSL2 runs a full Linux kernel in a lightweight VM and provides dynamic memory allocation, faster cold starts, and Windows integration. Docker uses it as its default Windows backend. [docker-wsl]

Microsoft’s `.wslconfig` documents the global WSL2 controls: memory defaults to 50% of Windows RAM, processors default to all logical processors, swap defaults to 25% of memory rounded up, localhost forwarding defaults to enabled, and nested virtualization is configurable. These are machine-wide WSL2 settings, not necessarily private to one app or distro. [wsl-config]

WSL2 is the easiest Windows UX when the customer already has WSL enabled, but it is a poor fit for an app that requires a completely private resource and lifecycle boundary. A product-owned WSL distribution shares the WSL utility VM and may interact with other distributions, global `.wslconfig`, Windows updates, corporate policy, and user-installed tooling.

Hyper-V/WHP provides a more explicit VM boundary and is appropriate when isolation and ownership matter more than zero-admin setup. The tradeoff is more installation privilege, feature conflicts, and enterprise policy surface. Docker documents Hyper-V as all-users/admin-only in its Windows installation modes, while its per-user WSL2 mode avoids administrator privileges for most installation/update flows. [docker-windows](https://docs.docker.com/desktop/setup/install/windows-install/)

## What breaks

### Nested virtualization and virtualized hosts

If the desktop runs inside VMware, Parallels, a VDI image, or another VM, the outer host must expose virtualization extensions. Microsoft’s troubleshooting documentation calls out missing Virtual Machine Platform, BIOS virtualization, and nested virtualization as causes of WSL2 startup failure. Hyper-V nested virtualization requires a powered-off VM and exposed virtualization extensions; networking may additionally require MAC spoofing or NAT configuration. [wsl-troubleshooting] [hyperv-nested]

Treat “runs on a physical laptop” and “runs in corporate VDI” as separate support tiers. Detect the condition before provisioning and give a clear fallback or remote-runtime path.

### Corporate lockdown and permissions

VM features can be disabled by BIOS settings, Group Policy, Credential Guard/Device Guard, endpoint security, MDM, or a corporate image. Installers may need administrator approval; firewall, VPN, proxy, code-signing, kernel/driver, and background-service policies can each block a different phase. Docker’s documented privileged helper and enterprise installation options illustrate the minimum scope of this problem. [docker-permissions] [docker-windows]

Do not make first-run setup depend on an opaque installer prompt. Provide a preflight that reports: virtualization available, required OS feature present, architecture supported, disk headroom, proxy reachability, signing/permission status, and whether an existing runtime conflicts.

### ARM versus x86

A Linux VM gives identical Linux semantics only when the guest architecture and native dependencies match. ARM hosts running x86 binaries need Rosetta, binfmt/QEMU, or another translation layer. Colima documents Rosetta as requiring Apple Silicon, macOS 13, and `vz`; Rancher documents Rosetta for x86_64 instructions in ARM Linux guests. [colima] [rancher-vz]

Translation can fail on instructions, native browser dependencies, performance-sensitive code, or kernel assumptions. Build and test both guest architectures where possible. If one architecture is intentionally unsupported, expose that before download rather than failing after provisioning.

### Headed browsers and GPU passthrough

Headless Chromium is much easier: run it inside the guest with a virtual display or headless mode and collect screenshots/video as files or streams. A headed browser needs display forwarding, input forwarding, audio if relevant, fonts, sandbox permissions, and a graphics path.

GPU support is not portable across the substrates. Docker documents NVIDIA GPU paravirtualization for Windows only with the WSL2 backend, requiring a compatible NVIDIA GPU, current drivers, and a current WSL2 kernel. [docker-gpu] That does not establish a matching path for macOS Apple GPUs, Intel GPUs, Hyper-V, generic WHP, or a custom embedded VM. Podman’s macOS ARM64 default can use a GPU-enabled LibKrun provider, but its provider matrix differs by architecture and is not a general cross-platform contract. [podman-machine-desktop]

For a cross-platform product, define headed-browser support as one of:

- supported only through software rendering/headless capture;
- supported on a tested allowlist of GPU/provider/OS combinations;
- delegated to a host browser or remote browser service;
- an explicit degraded mode with no GPU acceleration.

Do not promise “headed browser identical on macOS and Windows” merely because the backend is Linux.

## Recommendation for a connector product

For PDPP/Data Connect, a bundled Linux guest is justified when backend fidelity and isolation are more valuable than a small installer. Use the OS-native substrate per host—Apple Virtualization.framework on macOS, WSL2 by default on Windows with a Hyper-V/WHP path where a stronger boundary is required, and KVM/namespaces or a normal Linux container path on Linux. Keep the guest image and service API identical; keep lifecycle, mounts, networking, and diagnostics behind a small host adapter.

Start with an HTTP/headless profile and make browser/native descendants an explicit higher resource profile. Ship a signed, pinned guest image; use atomic guest replacement; retain the previous image until health checks pass; keep mutable connector state outside the replaceable base image; and expose `doctor`, `start`, `stop`, `reset`, `logs`, `resources`, and `version` operations to the app and automated tests.

The practical decision rule is:

- **Choose the bundled VM** if “same Linux backend and isolation semantics” is a hard product requirement and a 4–8 GiB RAM / 10–30 GiB free-disk budget is acceptable.
- **Choose native per-OS execution** if install size, instant startup, and host UX dominate, and the team can maintain three isolation implementations.
- **Choose honest degradation** if headed GPU browsers, locked-down corporate machines, or nested-VM support are requirements that cannot be guaranteed by the chosen substrates.

## CLAIMS

- Docker Desktop’s current macOS default is Apple Virtualization.framework; HyperKit is legacy, and Windows supports WSL2, Hyper-V, and Docker VMM. [docker-vmm]
- Docker VMM requires at least 4 GiB allocated to the Linux VM. [docker-vmm]
- Docker documents VM memory controls, a 50% host-memory default in applicable modes, 1 GiB default swap, and a 3–10 second Resource Saver restart. [docker-settings]
- Docker’s Mac disk image is a large virtual file whose maximum size can exceed actual host usage; its example shows a 64 GiB maximum with about 2.2 GiB consumed. [docker-disk]
- Docker Desktop on Mac requires at least 4 GiB RAM and supports current plus two previous major macOS releases. [docker-mac]
- Podman requires a Linux VM on macOS and Windows; its providers include libkrun/Apple Hypervisor on macOS and WSL/Hyper-V on Windows. [podman-machine]
- Podman machine exposes CPU, memory, disk-size, image, mount, and provider configuration; its documented default guest distribution is Fedora CoreOS and updates can reboot the VM. [podman-init]
- Colima defaults to 2 CPUs, 2 GiB RAM, and 100 GiB storage. [colima]
- Rancher Desktop requires WSL2 on Windows, hardware virtualization, and recommends 8 GiB system RAM and 4 CPUs; first launch downloads a VM image. [rancher-install]
- Rancher Desktop’s VZ mode uses macOS Virtualization.framework and can use Rosetta for x86_64 instructions in ARM Linux guests. [rancher-vz]
- Apple Virtualization.framework supports VMs on Apple Silicon and Intel Macs; macOS 13+ on Apple Silicon supports Intel binary translation in ARM Linux VMs. [apple-vz] [apple-rosetta]
- WSL2 uses a full Linux kernel in a lightweight VM and supports dynamic resource allocation; `.wslconfig` defaults include 50% host RAM, all logical processors, and swap equal to 25% of memory rounded up. [docker-wsl] [wsl-config]
- WSL2 startup failures can result from missing Virtual Machine Platform, disabled BIOS virtualization, or missing nested-virtualization exposure when the host is itself a VM. [wsl-troubleshooting]
- Hyper-V nested virtualization requires exposed virtualization extensions and can require MAC spoofing or NAT for nested networking; Group Policy and security features can block it. [hyperv-nested]
- Docker’s documented Windows GPU path supports NVIDIA GPU paravirtualization only with WSL2 and current NVIDIA/WSL prerequisites. [docker-gpu]
- Firecracker documents up to 125 ms from `InstanceStart` to Linux `/sbin/init` and at most 5 MiB VMM overhead for its tested 1-vCPU/128-MiB configuration; it relies on KVM and a minimal device model. [firecracker-spec]
- Firecracker production guidance requires KVM, patched host/guest components, resource controls, and jailer-style isolation for production deployments. [firecracker-prod]

## SOURCES

**docker-vmm**  
URL: https://docs.docker.com/desktop/features/vmm/  
Accessed: 2026-08-31

**docker-settings**  
URL: https://docs.docker.com/desktop/settings-and-maintenance/settings/  
Accessed: 2026-08-31

**docker-disk**  
URL: https://docs.docker.com/desktop/troubleshoot-and-support/faqs/macfaqs/  
Accessed: 2026-08-31

**docker-mac**  
URL: https://docs.docker.com/desktop/setup/install/mac-install/  
Accessed: 2026-08-31

**docker-windows**  
URL: https://docs.docker.com/desktop/setup/install/windows-install/  
Accessed: 2026-08-31

**docker-wsl**  
URL: https://docs.docker.com/desktop/features/wsl/  
Accessed: 2026-08-31

**docker-permissions**  
URL: https://docs.docker.com/desktop/setup/install/mac-permission-requirements/  
Accessed: 2026-08-31

**docker-gpu**  
URL: https://docs.docker.com/desktop/features/gpu/  
Accessed: 2026-08-31

**podman-machine**  
URL: https://docs.podman.io/en/stable/markdown/podman-machine.1.html  
Accessed: 2026-08-31

**podman-init**  
URL: https://docs.podman.io/en/latest/markdown/podman-machine-init.1.html  
Accessed: 2026-08-31

**podman-machine-desktop**  
URL: https://podman-desktop.io/docs/podman/creating-a-podman-machine  
Accessed: 2026-08-31

**colima**  
URL: https://github.com/abiosoft/colima/blob/main/README.md  
Accessed: 2026-08-31

**lima**  
URL: https://github.com/lima-vm/lima  
Accessed: 2026-08-31

**rancher-install**  
URL: https://docs.rancherdesktop.io/getting-started/installation/  
Accessed: 2026-08-31

**rancher-vz**  
URL: https://docs.rancherdesktop.io/ui/preferences/virtual-machine/emulation/  
Accessed: 2026-08-31

**rancher-settings**  
URL: https://docs.rancherdesktop.io/1.24/references/non-gui-settings/  
Accessed: 2026-08-31

**apple-vz**  
URL: https://developer.apple.com/documentation/virtualization  
Accessed: 2026-08-31

**apple-rosetta**  
URL: https://developer.apple.com/documentation/virtualization/running-intel-binaries-in-linux-vms  
Accessed: 2026-08-31

**wsl-install**  
URL: https://learn.microsoft.com/en-us/windows/wsl/install-manual  
Accessed: 2026-08-31

**wsl-config**  
URL: https://learn.microsoft.com/en-us/windows/wsl/wsl-config  
Accessed: 2026-08-31

**wsl-troubleshooting**  
URL: https://learn.microsoft.com/en-us/windows/wsl/troubleshooting  
Accessed: 2026-08-31

**hyperv-nested**  
URL: https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/enable-nested-virtualization  
Accessed: 2026-08-31

**firecracker-spec**  
URL: https://github.com/firecracker-microvm/firecracker/blob/main/SPECIFICATION.md  
Accessed: 2026-08-31

**firecracker-prod**  
URL: https://github.com/firecracker-microvm/firecracker/blob/main/docs/prod-host-setup.md  
Accessed: 2026-08-31

## SYNTHESIS

The bundled-VM option buys a strong and testable Linux execution contract, but the product inherits the responsibilities of a small VM distribution: image release engineering, disk lifecycle, guest updates, host adapters, preflight diagnostics, architecture policy, and degraded UX for graphics. The most defensible initial scope is a headless, service-oriented guest with a warm lifecycle and explicit resource profiles. Headed browser GPU support should remain an allowlisted capability, not part of the base cross-platform promise.
