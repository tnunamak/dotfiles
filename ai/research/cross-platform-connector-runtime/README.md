# Cross-platform connector-runtime & isolation architecture for Data Connect

**Question:** Data Connect (Tauri desktop app) must run PDPP's connector-collection
runtime on macOS, Windows, and Linux. The connector runtime has heterogeneous needs
(HTTP-only, headed/headless browser via Playwright/neko, vendored native binaries),
and the *isolation* guarantee (preventing a connector's native descendants from
reaching unrecorded host services) is currently built on Linux-only kernel primitives
(network namespaces, bubblewrap, /run masking, AF_UNIX pathname-socket masking).

**The pivotal, hard-to-reverse choice:** how the runtime + isolation exist on OSes
without Linux namespaces —
- (A) bundled Linux runtime (VM/container) everywhere: identical runtime, heavy;
- (B) native per-OS isolation (Linux namespaces / macOS App Sandbox+sandbox-exec /
  Windows AppContainer+job objects): light, but three isolation impls to keep honest;
- (C) Linux-full, others honestly-degraded claim.

Owner (2026-08-31) declined to decide without proper engineering: amass prior art,
ground in our actual system, converge with the counterpart to high confidence.

## Findings
(pending — synthesis lands here)

## Sources
(agent captures below)
