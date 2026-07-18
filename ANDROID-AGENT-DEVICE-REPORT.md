# Shared Android Agent Device report

## Outcome

Implemented and host-proven the durable shared-device capability in this branch: a focused,
user-scoped Android SDK/AVD installer; an ownership-validating fixed-name emulator lifecycle CLI with locking; a shared
local agent skill; an end-to-end real-device smoke script; and tests that do not download artifacts.
No desktop browser emulation was substituted.

## Research and decision

The full evidence log is [the Android-device research entry](ai/research/android-agent-device/shared-android-agent-device-uses-official-sdk-locked-cli-not-an-android-mcp.md), indexed at the top of
[the research corpus index](ai/research/INDEX.md).

The resulting design is:

| Concern | Decision |
|---|---|
| SDK/AVD | Official Android command-line tools, fixed package IDs, fixed AVD `agent_pixel_8_api_36`, Android 36 Google Play x86_64 image |
| Integrity/update | HTTPS-only download and Google-published SHA-1 verification for command-line-tools archive build `14742923` (package revision `20.0`); explicit mutable `--update`, never implicit SDK update |
| Host prerequisites | `apt` for stable `ca-certificates`, `curl`, Java 21 JRE, and `unzip`; KVM group preflight and no SDK/emulator sudo execution |
| Shared state | SDK, AVD, Android user home, cache, lock, logs, and evidence in XDG user directories; no root-owned Android state |
| Concurrency | One `flock`-backed CLI lock; recorded PID start-time plus AVD/port argument validation, AVD property identity, and both reserved ports prevent accidental reuse/kill |
| Determinism | Bounded 3 GiB/4-core headless emulator, fixed port, cold boot/no snapshots, boot-complete wait, explicit `reset` using `-wipe-data` |
| Browser | Explicit Chromium/Chrome baseline from the Google Play image; no Brave substitution |
| Agent interface | Local skill automatically symlinked to Claude, Codex, and Gemini by existing setup logic; no MCP registration/config mutation |

Android's official CLI tools cover the AVD lifecycle, while UI Automator, Appium UiAutomator2, and
Maestro are retained as project-level testing options rather than the shared-device control plane.
CDP remains an optional Android Chrome diagnostic via the documented `adb forward ...chrome_devtools_remote` route. The keyboard/viewport evidence remains device-side and fixture-side, because
desktop Playwright mobile emulation cannot prove Android IME behavior.

### MCP decision

No Android MCP was added. CursorTouch/Android-MCP is actively maintained and materially adopted,
but its default device discovery prefers physical devices and it exposes a broad shell tool. The
active uiautomator2 MCP has low adoption and a 70+ tool surface. Neither has a fixed shared serial,
participates in this lock, or provides a documented, equally safe Claude/Codex/Gemini configuration
path. The CLI+skill is the smaller, safer boundary. Reconsider only when an MCP can meet all of
those conditions.

### Brave

Brave documents Google Play and its F-Droid repository as supported Android channels and calls
GitHub APKs development builds. The reviewed material did not establish a pinned,
independently-verifiable x86_64 artifact path appropriate for unattended installation, so this
implementation intentionally does not install Brave. Chromium baseline coverage is clearly
separate; Brave-specific behavior remains unverified.

## Files changed

- `android-agent-device/common.sh` — centralized paths, fixed package IDs, verified bootstrap revision, ports, and resource defaults.
- `android-agent-device/setup.sh` — idempotent Linux installer, installer lock, verified command-line-tools revision check, and explicit SDK update path.
- `android-agent-device/cli.sh` — ownership-validating `start`, `status`, `lock`, `run`, `stop`, `reset`, `diagnose`, `screenshot`, and `logs`.
- `android-agent-device/fixtures/keyboard-viewport.html` and `smoke-test.sh` — one-lock real browser/IME/VisualViewport/rotation proof journey with token-scoped cleanup.
- `scripts/android-agent-device-setup.sh` and `bin/.local/bin/android-agent-device` — focused setup and stowed CLI entry points.
- `ai/skills/local/android-agent-device/SKILL.md` — exact agent workflow with locking, CDP, touch, IME platform evidence, rotation, and artifacts.
- `tests/android-agent-device-test.sh` — no-download syntax/configuration and lifecycle-contract regression checks.
- `setup.sh` and `README.md` — opt-in, minimal integration and user-facing entry point.
- `ai/research/...` and `ai/research/INDEX.md` — prior-art record and decision.

## Installation, operation, and update

Install from the dotfiles entry point:

```bash
cd ~/code/dotfiles
ANDROID_AGENT_DEVICE_SETUP=1 ./setup.sh
```

Or install only this capability:

```bash
~/code/dotfiles/scripts/android-agent-device-setup.sh --install
```

Then log out/in once if the installer says it added the user to `kvm`, and run:

```bash
android-agent-device diagnose --json
android-agent-device start
android-agent-device status --json
```

The updater is explicit and serialized with installation:

```bash
~/code/dotfiles/scripts/android-agent-device-setup.sh --update
```

It never runs with `sudo` for SDK/AVD state and never pipes a remote script to a shell. The only
downloaded bootstrap archive is HTTPS-only and verified against Google's published checksum before
extraction. The installer rechecks installed command-line-tools package revision `20.0`. Android SDK
packages remain fixed IDs in code, not fully revision-pinned artifacts: `--update` is deliberately
mutable and must be treated as a new test environment after inspection.

`diagnose --json` is safe before the XDG paths exist. It reports `/dev/kvm` node access separately
from the emulator's `-accel-check`; both are required. The focused installer has no Node dependency:
the smoke's CDP client uses the already-required Python standard library.

## Smoke evidence

The smoke oracle is [`android-agent-device/smoke-test.sh`](android-agent-device/smoke-test.sh). It:

1. starts the actual x86_64 KVM AVD and waits for `sys.boot_completed`;
2. serves a local fixture, launches actual Android Chrome/Chromium, and records a UI dump;
3. locates and taps the browser input from the Android accessibility/UI XML;
4. requires `dumpsys input_method`/`dumpsys window` IME visibility evidence after focus;
5. captures initial, keyboard, and landscape screenshots plus UI XML and logcat;
6. reads rendered `VisualViewport` and orientation values from the real page;
7. rotates to landscape and verifies the page's real orientation; and
8. keeps the entire journey under one CLI lock, then stops only the emulator process whose invocation token it recorded.

### Executed evidence on this host (2026-07-18)

```text
$ tests/android-agent-device-test.sh
PASS android-agent-device lifecycle/configuration contracts (no downloads)

$ ANDROID_AGENT_DEVICE_SMOKE_EVIDENCE_DIR=~/.local/share/android-agent-device/evidence/smoke-20260718T-revise5 \
  android-agent-device/smoke-test.sh
PASS: real Android browser fixture
initial:   {"layoutWidth":412,"layoutHeight":784,"visualWidth":412.19049072265625,"visualHeight":784,"orientation":"portrait-primary","focused":""}
keyboard:  {"layoutWidth":412,"layoutHeight":784,"visualWidth":412.19049072265625,"visualHeight":424,"orientation":"portrait-primary","focused":"keyboard-test"}
landscape: {"layoutWidth":864,"layoutHeight":304,"visualWidth":864,"visualHeight":304,"orientation":"landscape-primary","focused":"keyboard-test"}
IME evidence: input-method.txt + window.txt

$ rg 'mInputShown=true|mImeWindowVis=3' input-method.txt
mImeWindowVis=3
mInputShown=true

$ cat stop.log
Shared Android device stopped.
```

Exact retained evidence is under
`~/.local/share/android-agent-device/evidence/smoke-20260718T-revise5/`: `01-initial.png`,
`02-keyboard.png`, `03-landscape.png`, the three CDP metric JSON files, `input-method.txt`,
`window.txt`, `logcat.txt`, UI XML, and `result.txt`. The host exposes a usable ACL on `/dev/kvm`,
so no sudo action was needed on this machine. A fresh machine missing Java/curl/unzip/python or KVM
access will still need the installer’s documented apt/KVM-group action. The rerun's diagnose JSON
recorded `kvm_device_access=true` and `emulator_accel_check=true`.

## Residual limitations

- This is Linux/KVM only. iOS requires macOS plus an iOS Simulator or physical device; Android
  Chromium results do not establish Safari/WebKit behavior.
- The smoke test needs a Chrome/Chromium package present in the selected Google Play image. It fails
  honestly if that baseline is absent instead of installing an unverified browser.
- The fixture is a platform/browser journey, not a replacement for an app's own Appium, UI Automator,
  Maestro, Espresso, or WebDriver test suite.
- Cooperation is enforced through the CLI lock. A process intentionally using raw `adb` can bypass it,
  so the shared-agent skill explicitly forbids that path.
- Fixed SDK package IDs make installs repeatable at the package-name level, but Android's repository
  can change the artifact resolved by an ID. Only the command-line-tools bootstrap archive is checksum
  pinned; use the explicit update path and retain test evidence when upgrading SDK packages.
- Brave-specific features remain out of scope until a supportable integrity-verified x86_64 channel
  is available.

## Reconciliation and commit scope

This isolated checkout began at committed HEAD `8505acc`. Its working tree had no unrelated changes,
while the shared primary checkout is known to be dirty. Reconcile only this focused commit into the
primary checkout; in particular, merge the surgical opt-in `setup.sh` hunk rather than overwriting
the primary checkout's current setup changes.
