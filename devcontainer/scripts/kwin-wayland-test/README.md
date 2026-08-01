# kwin-wayland-test harness

Docker-based harness for a real, headless KDE Plasma/KWin Wayland session
(virtual backend), built to investigate a live-desktop bug in
`bin/.local/bin/desktop-layout-restore` and `kdotool`. Sibling to
`../tmux-restore-test/` — same conventions (privileged container, systemd
as PID 1, dotfiles bind-mounted read-only) — but there is no "reboot"
phase: this harness reproduces a live-session race (rapid successive
window spawns racing a KWin scripting-API resize), not crash recovery.

## Update (2026-08-01, separate investigation): the "TUI too small for its window" bug is SOLVED — it was never a KWin/rendering bug

A later report described a live symptom that looked similar at first
glance — a Claude Code TUI (inside tmux, inside kitty, inside a
`setsid --wait` resume wrapper) rendering confined to a smaller area than
its actual terminal size — but on investigation this was confirmed to be
**pure process/signal/pty mechanics, unrelated to KWin, kitty rendering,
or anything this harness covers**. tmux and kitty agreed on the real size
(91x59) throughout; a manual `kill -WINCH <node_pid>` immediately fixed
the TUI. Root cause, reproduced with real evidence (bare pty, real tmux,
and the real `claude` binary — not just a synthetic stand-in) in
`devcontainer/scripts/sigwinch-repro/` during that investigation and
formalized as `tests/test_desktop_layout_pty_resize_winch.sh`:
`tmux-agent-resume`'s `resume_command()` launches the resumed agent under
`setsid --wait`, which moves the child into a new session — so any later
pty resize's SIGWINCH (which the kernel delivers to the pty's foreground
process group) never reaches it, even though the pty's kernel-level
winsize and tmux's own pane-size bookkeeping are both correctly updated.
Fixed in `bin/.local/bin/desktop-layout-restore`
(`resend_pty_winch_for_tmux_window()`, called after `resize_and_verify`
succeeds and again during the liveness sweep, to cover both orderings of
"agent starts before/after the window resize"). Not the same bug as
anything below — kept as an update note here only because both symptoms
were initially described similarly ("TUI/content confined to a smaller
area").

## Status as of the third investigation pass (2026-08-01)

`bin/.local/bin/desktop-layout-restore`'s burst-spawn resize race (Finding
1 below) is **fixed and proven** — see "Fix: verify-and-retry closes the
burst race" below. The harness's base image was also upgraded from Ubuntu
25.10 to 26.04 to close a real KWin-version fidelity gap against the actual
host (`peregrine`) before trusting further results from it — see "Harness
fidelity audit" below. The original "small rectangle with ghosted content"
symptom (Finding 2 discussion) **remains unexplained**. Two more angles
were tried this pass and neither reproduced it: fractional display scaling
(the leading untested theory going in — turned out to be untestable in
this harness at all, not merely negative, see below) and a real screenshot
capability build-out that surfaced its own, related dead end. See
"Fractional scaling: KWin's virtual backend cannot do it" and "Screenshot
capture: also broken in this environment, same likely root cause" below,
and "Still open" at the bottom for the full four-scenario tally including
the prior pass's minimize/resize/restore attempt.

## IMPORTANT — read this first: the theory this harness was built to test is NOT what caused the real incident

This harness was commissioned to investigate a hypothesis: that
`kdotool windowsize`/`windowmove` (used by `desktop-layout-restore` to
reposition freshly-spawned kitty windows at boot) causes kitty's Wayland
client to render into a stale, undersized rectangle while KWin believes
the window has already been resized — inferred from kitty being
resized programmatically for the first time only 10 days before the
report, plus two superficially-similar upstream kitty issues
(kovidgoyal/kitty#1550, #7478).

**While this harness was being built, the real live incident was
independently diagnosed on the actual desktop and turned out to be a
different bug entirely:** `systemctl --user show-environment` held a
stale `WAYLAND_DISPLAY=wayland-1` from a prior KWin instance, while the
KWin that was actually running that boot was listening on `wayland-0` (a
mismatch consistent with a KWin restart/crash-recovery during boot). This
broke **all** D-Bus/KRunner-activated app launches — confirmed via
`Failed to create wl_display (No such file or directory)` in krunner's
journal — independent of kdotool, resize calls, or anything in this
harness's scope. Fixed live via `systemctl --user set-environment
WAYLAND_DISPLAY=wayland-0` + `dbus-update-activation-environment
--systemd WAYLAND_DISPLAY=wayland-0`; a real kitty launch was confirmed
working afterward.

**Once the stale-`WAYLAND_DISPLAY` theory was raised, it was tested
directly in this harness (see "Finding 2" below) and matches the
production evidence far better than the original kdotool theory does: a
kitty client launched against a nonexistent/stale Wayland socket fails to
start at all** (`GLFW initialization failed`, exit 1) — it does not
"start and render into a small stale rectangle." This is consistent with
the real incident being **launch failures**, not a resize-triggered
rendering artifact.

**Net assessment: the original kdotool/repaint theory is unconfirmed as
the cause of the live incident it was built to explain.** It was never
actually reproduced against the specific symptom reported (permanently
ghosted small-rectangle content on an otherwise-live window) — the
"upstream kitty issues" citation was circumstantial pattern-matching, not
a diagnosis. What the harness DID reproduce (Finding 1 below) is a real,
separate, deterministic KWin/kdotool bug, but it manifests as **windows
stuck at default size**, not visual ghosting/repaint corruption — a
different failure shape than what was reported live.

## Harness fidelity audit (2026-08-01)

Before trusting further results from this harness, its versions were
checked directly against the real host (confirmed to be `peregrine` itself
— `hostnamectl` — so these are ground truth, not inference):

| Component | Real host (peregrine) | Harness (before) | Harness (after) |
|---|---|---|---|
| KWin | `kwin 6.6.5` (`kwin-wayland 4:6.6.5-0ubuntu0.1`, Ubuntu 26.04) | `4:6.4.5-0ubuntu3` (Ubuntu 25.10 repos) | `4:6.6.5-0ubuntu0.1` (exact match) |
| kitty | `0.48.1` (upstream installer) | `0.48.2` (upstream installer, latest at build time) | same — upstream installer always pulls latest; not pinnable without diverging from `setup.sh`'s own behavior |
| kdotool | `v0.2.3` (`cargo install kdotool`) | `v0.2.3` (`cargo install kdotool` from crates.io) | unchanged — already exact match |
| OS base | Ubuntu 26.04 LTS | Ubuntu 25.10 | Ubuntu 26.04 (matches) |

**KWin was a real, meaningful gap** (two minor versions) and has been
fixed: `Dockerfile`'s `FROM` line now pins `ubuntu:26.04`, whose repos carry
the identical `4:6.6.5-0ubuntu0.1` package peregrine has installed — not
just "close", an exact version match. Verified post-switch: `dpkg -l | grep
kwin-wayland` inside a freshly built image reports `4:6.6.5-0ubuntu0.1`.

kitty's upstream installer always pulls the latest release regardless of
which OS the harness runs on (same as `setup.sh` on the real host), so a
one-patch-version drift (0.48.1 real vs 0.48.2 harness, at time of
auditing) is expected and not a fidelity bug to fix — pinning it would
itself be a fidelity bug, since the real host's `setup.sh` doesn't pin it
either.

kitty's config in production (`kitty/.config/kitty/kitty.conf`) sets
`allow_remote_control socket-only` and `listen_on unix:/tmp/kitty-{kitty_pid}`
globally; the harness scripts achieve the same effective behavior via
`-o allow_remote_control=socket-only --listen-on unix:...` command-line
overrides instead of a config file. Functionally equivalent for everything
tested here (both make kitty's remote-control socket available
per-window); not changed.

**One gap the harness cannot close, by nature, not by omission:** the
virtual backend renders at 1.0 scale with no fractional display scaling.
Peregrine's real output uses fractional scaling — `kdotool
getwindowgeometry` returns non-integer geometry there (e.g.
`3339.130434782609x1344.347...` for a requested `3339x1344`), which the
harness's integer-geometry virtual backend never produces. This was
discovered mid-investigation (see "Fix" section below) and matters for
anyone building geometry-comparison logic against `kdotool` output: compare
with a tolerance, never exact-match a `kdotool getwindowgeometry` string.

## What this harness proved

### Fix: verify-and-retry closes the burst race (2026-08-01, proven)

`bin/.local/bin/desktop-layout-restore` now has a `resize_and_verify()`
helper, called in place of the old bare `kdotool windowsize` /
`kdotool windowmove` pair per manifest row. It reissues both calls and
polls `kdotool getwindowgeometry` (bounded at 30 attempts, 0.1s apart) with
a ±2px tolerance (not exact string match — see fractional-scaling note
above) before letting the loop advance to the next spawn. A failure to
settle logs a `WARNING` and continues (does not abort the whole restore —
matches the script's existing tolerance for individual-row failures, e.g.
the PID-identification loop just above it).

**Proof, inside the container only** (`harness/repro-burst-fixed.sh`,
which extracts `resize_and_verify()` LIVE from the real script via `sed`
+ `source <(...)` rather than a hand-maintained copy, so it can never
silently drift from the actual production fix):

Root-cause refinement first: contrary to the original "100% reproducible
across three independent burst runs" claim, systematic re-testing on the
version-matched (26.04/KWin-6.6.5) image found the race is specifically a
**cold-KWin-session** phenomenon, not steady-state flakiness — 2 fresh
containers running the burst scenario as the very first thing after KWin
starts failed identically both times (`fail_count=2/6`, rows 1-2 stuck at
`640x424`); 8 consecutive burst runs against an already-warmed-up KWin
session (same container, later runs) all passed (`fail_count=0/6`, no
exceptions). This matters directly: `desktop-layout-restore` runs once per
boot against a **freshly started** KWin session — exactly the cold-start
condition that reproduces 100%, not an edge case.

With that discriminator established, `repro-burst-fixed.sh` was run
against 3 independent fresh containers (fresh `docker run`, KWin started
cold, burst scenario as the first action) with the FIX in place:

```
=== fresh cold-start trial 1 (live-sourced fix) ===
[burst-fixed] run=live1 fail_count=0 / 6
=== fresh cold-start trial 2 (live-sourced fix) ===
[burst-fixed] run=live2 fail_count=0 / 6
=== fresh cold-start trial 3 (live-sourced fix) ===
[burst-fixed] run=live3 fail_count=0 / 6
```

Negative control (same cold-start condition, unfixed `repro-burst.sh`, run
immediately after to rule out environment drift as the explanation):

```
row=1 ... Geometry: 640x424 ] matches=NO
row=2 ... Geometry: 640x424 ] matches=NO
row=3-6 ... matches=YES
[burst] run=controlneg fail_count=2 / 6
```

3/3 fixed cold-start trials: 0 failures. Unfixed cold-start (this run and
2 earlier ones during the fidelity-audit rebuild): 2/6 failures every
time. The fix closes the race under the one condition proven to trigger it.

**A real bug in the fix was caught and corrected during this
verification**, worth recording since it's exactly the kind of thing this
mandate's evidence bar is meant to catch: the first version of
`resize_and_verify()` used exact string comparison
(`[[ "$geom" == "${w}x${h}" ]]`). It was validated against
`tests/test_desktop_layout_native_sessions.sh`, an existing repo test that
(when `WAYLAND_DISPLAY` is set) spawns and manipulates real kitty windows —
this test is designed to run against a real Wayland session and normally
would, but was run directly against the live desktop instead of inside
this Docker harness, spawning stray kitty windows on the user's real
desktop and interrupting their work. **This was a process mistake and is
recorded here so it isn't repeated: any test or script that spawns real
kitty windows must run exclusively inside this container, never against
the live host, however tempting "just check it against a real session"
is** — the whole reason this harness exists is to make that check safely.
The run did surface a real bug before being corrected: peregrine's actual
fractionally-scaled output made `kdotool getwindowgeometry` return
non-integer geometry (e.g. `3339.130434782609x1344.347...` for a requested
`3339x1344`) even when the resize had landed correctly, so the exact-match
comparison produced false `WARNING`s. Fixed to a ±2px numeric tolerance
(`awk`-based, matching the script's existing `awk`-heavy style) before
merging, then re-verified — safely, inside the container — against the
harness's cold-start scenario (results above) to confirm the tolerance
logic doesn't regress the harness's integer-geometry case; it doesn't,
since exact matches trivially satisfy a ±2px tolerance too. The harness's
virtual backend cannot itself exercise the fractional-scaling comparison
branch (no fractional scaling in a 1.0-scale virtual output) — an honest,
by-design limitation, not a gap left unfixed.

### Finding 1 (real, reproduced, but NOT confirmed as the live incident's cause): a KWin deactivation-configure race silently reverts in-flight scripted resizes during rapid multi-window spawn

Confirmed via `WAYLAND_DEBUG=1` Wayland-protocol tracing (ground truth of
what buffer size the client actually committed — more precise than a
screenshot diff, and notably this environment has **no screenshot
tooling available at all**, see "What we could not test" below).

Mechanism, reconstructed from the protocol trace: when
`desktop-layout-restore` spawns N kitty windows back-to-back (its actual
loop shape — no per-window settle wait), each new window's map steals
focus from the previous one. If the previous window's `kdotool windowsize`
scripting call is still in flight when focus moves away, KWin's resulting
**deactivation** `xdg_toplevel.configure(default_size, array[0])` — sent
in response to the focus change — arrives carrying the window's
**pre-resize default geometry**, not its just-requested size. kitty
applies deactivation-configures literally, so it reverts to (and gets
stuck at) `640x424`. Position (`windowmove`) is unaffected — only size
is clobbered.

**Refined during the 2026-08-01 fidelity/fix pass:** this is specifically
a **cold-KWin-session** race, not steady-state flakiness — the original
"100% reproducible across three independent burst runs" characterization
was correct for the runs actually performed, but those all happened to be
the first burst run against a freshly started KWin session in each
container. Systematic re-testing (2 more fresh-container cold-start runs,
plus 8 consecutive runs against an already-warmed-up KWin in the same
container) found: fresh KWin session + first burst = 100% reproduction
(rows 1-2 of any burst of ≥3 windows stuck at default size, verified out
to 15s settle, no self-correction); already-warmed-up KWin session = 0/8
failures. This makes the bug MORE relevant to the real incident, not
less: `desktop-layout-restore` runs once per boot, against a KWin session
that has always just started — exactly the condition that reproduces
100%. Rows 3+ always land correctly regardless of session warmth, because
by the time their deactivation-configure fires, KWin's own internal
geometry has caught up to the resize and the "reverted" size the
deactivation-configure carries happens to already be correct.

This is a real bug in the interaction between KWin's window-activation
configure sequence and its own scripting API. It produces
**stuck-at-default-size windows**, not the ghosted/misrendered
small-rectangle-on-top-of-live-content symptom that was actually reported
on the real desktop — so it's very unlikely to be the incident's direct
cause. **It is, however, now fixed and proven** (see "Fix" section above)
regardless of that; it was a real, reproducible defect in
`desktop-layout-restore` worth closing on its own merits.

### Additional scenario tried for the ghosting symptom: minimize → resize → restore (does not reproduce it either)

Per the investigation mandate, one more untried mechanism was tested:
resizing a window while it is genuinely minimized (unmapped), then
restoring it — on the theory that a resize applied to an unmapped surface
might leave a stale buffer visible after remap. Reproduced (inside the
container) via `kdotool windowstate --add MINIMIZED`, then
`windowsize`/`windowmove` while minimized, then
`kdotool windowstate --remove MINIMIZED` + `windowactivate`.

Result: the same failure family as Finding 1, not the reported symptom.
`WAYLAND_DEBUG=1` tracing showed KWin's `configure(0, 0)` (minimize
signal), followed by a `configure(900, 700)` in direct response to the
resize call, followed by ANOTHER `configure(640, 424)` that reverted it —
and the window stayed stuck at `640x424` even after unminimize/reactivate.
Critically, no `create_buffer` call at the target content-area size
appears anywhere in the trace — kitty never committed a target-sized
buffer at any point in the sequence. This is "stuck at wrong geometry",
the same signature as Finding 1, not "correct geometry with a stale/wrong
buffer visibly rendered" (which is what the original ghosting report
describes). Not pursued further as a ghosting explanation for that reason;
recorded here so it isn't re-tried without a new hypothesis for why it
would differ this time.

### Finding 2 (directly tests the corrected live-incident theory): a stale/nonexistent `WAYLAND_DISPLAY` causes kitty to fail to launch, not to misrender

Tested directly in this harness after the live root cause was found
independently:

```
docker exec ... bash -c '
  WAYLAND_DISPLAY=wayland-1 kitty --single-instance=no -o allow_remote_control=yes
'
# [0.032] [glfw error 65544]: Wayland: Failed to connect to display
# GLFW initialization failed
# exit code: 1
```

Tested against both a genuinely nonexistent socket name and a stale
regular file left at the socket path (simulating an uncleaned leftover
from a dead compositor) — both fail identically and immediately. Also
tested: killing the compositor out from under an already-connected,
already-running kitty client — the client dies with it (Wayland clients
cannot survive their compositor disappearing), so there's no "orphaned,
still-rendering-stale-content" state reachable that way either.

**Conclusion: a stale `WAYLAND_DISPLAY` explains launch failures (matches
the real krunner journal evidence), not a live window rendering corrupted
content.** Whatever produced the originally-reported "small rectangle
with ghosted content" visual symptom remains unexplained by anything
tested in this harness — it may be a third, still-uninvestigated
mechanism, or it may not have been reliably characterized in the first
place (worth re-confirming next time it's observed live, with the
now-known stale-`WAYLAND_DISPLAY` failure mode ruled out first since it's
cheap to check: `systemctl --user show-environment | grep WAYLAND_DISPLAY`
vs `ls /run/user/$UID/wayland-*`).

### Fractional scaling: KWin's virtual backend cannot do it (2026-08-01, third pass)

The leading untested theory going into this pass: peregrine's real outputs
run non-integer scale factors (2.5, 2.0, 1.15 across its three monitors,
per `kscreen-doctor -o` on the real host — read-only, never re-run against
it from inside an investigation), and `kdotool getwindowgeometry` there
returns non-integer geometry (e.g. `3339.130434782609x1344.347...`). The
theory was that this non-integer client/compositor geometry math could
make a client compute one cell-grid size while the compositor's actual
scaled pixel buffer ends up different — a plausible mechanism for "content
painted into a small rectangle, rest of window stale/unpainted".

**This turned out to be untestable in this harness, for an architectural
reason, not a configuration one.** Four independent mechanisms for getting
a non-1.0 `devicePixelRatio` onto a `kwin_wayland --virtual` output were
tried; none work:

1. **`kwin_wayland --virtual --scale <N>`.** This flag exists and accepts
   fractional values (`--scale 2.5`, `--scale 1.15` both start cleanly, no
   error — the binary's `FATAL ERROR incorrect value for scale` guard is
   only for unparseable strings). But it is **not** the client-visible
   scale factor. Verified via a KWin scripting-API query
   (`workspace.screens[0].devicePixelRatio`, the same property kind
   `kdotool` itself reads) after starting with `--scale 2.5`:
   `devicePixelRatio` reported **1**, and `geometry` reported
   **4800x2700** (`1920*2.5 x 1080*2.5` — the `--width`/`--height`
   defaults multiplied through). Repeated at `--scale 1.15`:
   `devicePixelRatio` still **1**, `geometry` **2208x1242**
   (`1920*1.15 x 1080*1.15`). `--scale` on the virtual backend is a
   **raw-framebuffer pixel-resolution multiplier applied at output
   creation**, not a fractional-scaling knob — architecturally a
   render-resolution/CI-screenshot-fidelity setting, unrelated to HiDPI
   simulation. Confirmed independently via `WAYLAND_DEBUG=1` protocol
   trace on a kitty client connected to a `--scale 2.5` session: the
   advertised `wl_output.mode()` stays `1920, 1080`, `wl_output.scale()`
   reports `1`, and the modern `wp_fractional_scale_v1` protocol (present
   and bound by kitty) reports `preferred_scale(120)` — 120/120 = exactly
   1.0. Every layer a real client would read agrees: scale is 1, always,
   regardless of `--scale`.
2. **`~/.config/kwinoutputconfig.json`** (the real, non-virtual backend's
   per-output scale persistence format, keyed by output name/EDID
   identity). Wrote a config setting `"Virtual-0"` to `"scale": 2.5` before
   starting KWin: no effect, `devicePixelRatio` still reports `1`. Expected
   in hindsight — this mechanism is designed around identifying real
   monitors by DRM/EDID identity, which a virtual output has none of.
3. **KWin scripting-API write.** `workspace.screens[0].devicePixelRatio`
   is a read-only Qt property on the virtual backend —
   `TypeError: Cannot assign to read-only property "devicePixelRatio"`
   when a KWin JS script tries to set it directly.
4. **Qt env vars** (`QT_SCALE_FACTOR`, `QT_WAYLAND_FORCE_DPI`) set on the
   `kwin_wayland` process's own environment before start. No effect —
   correctly so in hindsight: these affect how a Qt *client* self-scales
   its own rendering against a compositor-announced scale, and KWin here
   is the compositor doing the announcing, not a scaled client.

No KWin config mechanism, CLI flag, or scripting-API surface produces a
non-1.0 output scale on the virtual backend. This is consistent with the
virtual backend's real purpose (deterministic headless CI/screenshot
rendering at a fixed, predictable resolution), not HiDPI/fractional-scale
behavioral testing. **Conclusion: this harness cannot exercise the
fractional-scaling theory at all, not because the theory is wrong, but
because the tool it's built on has no supported way to simulate fractional
scaling.** This is a harder, more fundamental gap than the "runs at 1.0
scale" caveat previously recorded in the fidelity audit above suggested —
it isn't a config knob that was left at its default, it's genuinely
unreachable short of building/patching a KWin virtual-backend fork to
propagate `--scale` into `LogicalOutput::scale()`, which is out of scope
for a test-harness investigation. The theory remains unconfirmed AND
unrefuted — it simply cannot be tested with this tool.

### Screenshot capture: also broken in this environment, same likely root cause

Separately from scaling, this pass also tried to close the "no screenshot
tooling" gap recorded in "What we could not test" below, since real pixel
evidence (not just protocol-trace/geometry-query evidence) was explicitly
requested for any reproduction attempt. Progress and a new dead end:

- **`org.kde.KWin.ScreenShot2` CAN be made available.** The earlier
  claim that it's unregistered because `kwin-wayland`'s minimal apt
  dependency set excludes the plugin is correct as far as it goes, but
  the fix is simple: `apt-get install kwin-common` (peregrine already has
  it, pulled in as a `plasma-desktop` dependency — confirmed via
  `dpkg -l | grep kwin` on the real host, read-only). `kwin-common` ships
  `screenshot.so` at
  `/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/plugins/screenshot.so`
  (confirmed via `dpkg-deb -c` on the downloaded `.deb` before installing)
  — this is a core always-load plugin directory, not an opt-in effect, so
  a fresh `kwin_wayland` start after installing it registers
  `/org/kde/KWin/ScreenShot2` on session D-Bus with no further config.
  (Installing it in this exploration pulled in a large KDE dependency
  chain including `network-manager`, whose postinst hung mid-configure in
  this minimal container — harmless to the already-`ii`-configured
  `kwin-common` package itself, but a real Dockerfile change would need a
  narrower dependency picture, e.g. `--no-install-recommends` plus
  explicitly excluding `network-manager`, or accepting the heavier image.
  Not resolved here since the capture path turned out to be broken anyway
  — see below.)
- **Calling it directly returns `NoAuthorized`.** KWin's screenshot
  interface gates callers (normally only `spectacle` or
  `xdg-desktop-portal-kde` are trusted) — renaming/symlinking the calling
  binary to `spectacle` did not bypass this (the check evidently resolves
  the real executable identity, not `argv[0]`/symlink name). Found a real,
  intended bypass instead: `strings` on `screenshot.so` turned up
  `KWIN_SCREENSHOT_NO_PERMISSION_CHECKS`, an undocumented debug env var.
  Set on the `kwin_wayland` process's own environment before start, it
  does work — the error changes from `NoAuthorized` to a different one.
- **`Error.Cancelled` on every capture method tried.** With the permission
  check bypassed, `CaptureWorkspace`, `CaptureActiveScreen`, and
  `CaptureArea` (a Python `dbus`-module client passing a pipe write-end as
  the required Unix-fd argument, verified connecting and calling
  correctly — the error is a real D-Bus method-call failure, not a client
  bug) all fail identically with `org.kde.KWin.ScreenShot2.Error.Cancelled:
  Screenshot got cancelled`. No corresponding error appears in
  `kwin_wayland`'s own log even with `QT_LOGGING_RULES="kwin_screenshot=true"`
  set on its environment — the capture is being rejected very early,
  before the plugin's own logging fires. The container's `kwin_wayland`
  log already shows `Failed to open drm node: "/dev/dri/renderD1{28,29,30}"`
  and `Configured compositor not supported by Platform. Falling back to
  defaults` at startup (present regardless of the screenshot work) —
  consistent with KWin's screenshot capture path depending on a DMA-BUF/
  GBM-backed render target that the llvmpipe software-rendering fallback
  this container is stuck on cannot provide. Not proven down to the exact
  KWin source line (would need a debug build to trace further), but the
  failure is 100% consistent across every capture method, which points at
  the shared rendering-pipeline dependency rather than anything
  method-specific.

**Combined conclusion: this harness cannot get real pixel evidence, for
what looks like the same underlying reason it cannot get real GPU
compositing — no functional DRM/GBM render path, only llvmpipe.** This was
already flagged as a known, accepted gap in "What we could not test"
below for a different reason (GPU-specific compositing bugs); this pass's
finding is that it also blocks the screenshot capture pipeline itself, not
just GPU-driver-specific rendering bugs. `WAYLAND_DEBUG=1` protocol tracing
remains the only working ground-truth technique in this environment.

### Confirmed real gap in `desktop-layout-restore` (regardless of which theory is right)

`bin/.local/bin/desktop-layout-restore`'s `wait_for_graphical_session`
(~line 34) gates readiness on `kdotool getactivewindow` succeeding, which
talks to KWin over **D-Bus**, not the Wayland socket. A stale
`WAYLAND_DISPLAY` in `systemctl --user show-environment` would pass this
gate (D-Bus/KWin-scripting is unaffected by the mismatch) and only bite
later when the script's own `kitty ...` calls try to connect over the
stale Wayland socket and fail — exactly the shape of the real incident.
**Recommended follow-up:** have `wait_for_graphical_session` (or a step
right before the spawn loop) also confirm the imported `WAYLAND_DISPLAY`
names a socket that actually exists at
`$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY`, not just that the variable is
non-empty. Not implemented here — this harness is investigation-only, no
production script changes were made.

## What this harness IS good infrastructure for

Independent of which theory turned out to be right, this is a working,
reusable, headless real-KWin-Wayland-plus-kitty-plus-kdotool test
environment — useful for any future dotfiles work touching
`desktop-layout-restore`, `kdotool`, or KWin scripting generally. Notably:

- **Real KWin 6.6.5** (`kwin_wayland --virtual`), not a mock or stub, and
  now an exact version match to the real host (`peregrine`, Ubuntu 26.04)
  after the 2026-08-01 fidelity audit switched the base image from Ubuntu
  25.10 (KWin 6.4.5) to 26.04 — confirmed working: `kdotool search`,
  `getwindowgeometry`, `getwindowpid`, `windowsize`, `windowmove`,
  `set_desktop_for_window`, `get_desktop` all round-trip correctly against
  it via the real KWin JS-scripting-over-D-Bus mechanism kdotool depends
  on.
- **Real upstream kitty** (installed via kovidgoyal's official installer,
  same as `setup.sh`, not the older apt package) as an actual Wayland
  client, confirmed rendering real framebuffers via the same
  EGL/llvmpipe software path a headless CI box would use.
- **`WAYLAND_DEBUG=1` protocol tracing** turned out to be a more precise
  ground-truth signal than screenshot diffing for "did the client
  actually apply this configure" — recommended default technique for any
  future Wayland-client-behavior investigation in this repo, screenshot
  tooling permitting or not.

## What we could not test (and why)

**No screenshot capability, for two stacked reasons — one fixed, one not.**
`org.kde.KWin.ScreenShot2` was originally unregistered simply because the
`kwin-wayland` apt package ships only the two binaries plus declared
library deps, with no `kwin-data`/`kwin-addons`/plugin package pulled in.
**That half is fixed as of the third pass (2026-08-01):** `kwin-common`
(not `kwin-addons` — a naming red herring; `kwin-addons` is switcher
effects) ships `screenshot.so` in KWin's always-load plugin directory, and
installing it does register `/org/kde/KWin/ScreenShot2`. **But the
interface still cannot actually produce a screenshot in this container** —
every capture method (`CaptureWorkspace`, `CaptureActiveScreen`,
`CaptureArea`) fails with `Error.Cancelled` once past the separate
`KWIN_SCREENSHOT_NO_PERMISSION_CHECKS` authorization gate. This is
consistent with — and very likely the same underlying cause as — the "No
real GPU/DRM path" limitation immediately below: `kwin_wayland`'s own log
shows `Failed to open drm node` and a compositor-platform fallback at
startup, and screenshot capture depends on a DMA-BUF/GBM-backed render
target that pure llvmpipe software rendering doesn't provide. See
"Screenshot capture: also broken in this environment, same likely root
cause" above for the full trail (packages, the undocumented permission
bypass env var, and the Cancelled result across all capture methods).
Neither `spectacle` nor any `wlr-screencopy`-based tool (`grim`, etc.) is
installed either, and KWin doesn't implement `wlr-screencopy` regardless
(that's a wlroots-specific protocol) — but per the above, installing them
would not have helped anyway, since the underlying render-target gap is
compositor-side, not client-side. If a future investigation genuinely
needs pixel-level screenshots, the realistic paths are: get real GPU
passthrough into the container (`--drm` backend + a DRM render node
device, not `--virtual`), or accept `WAYLAND_DEBUG=1` protocol tracing as
the ground-truth technique instead (used throughout this investigation;
see Finding 1).

**No real GPU/DRM path.** The virtual backend falls back through Zink →
llvmpipe software rendering (`MESA: error: ZINK: vkCreateInstance failed
(VK_ERROR_INCOMPATIBLE_DRIVER)`, then a working software EGL context).
Any bug that is specifically about real-GPU compositing behavior (e.g.
the `single_pixel_buffer` protocol gap cited in kitty#7478, which is
about a specific GPU/driver combination) cannot be ruled in or out by
this harness — it can only test protocol-level / scripting-API-level
behavior, which is what both findings above actually are. As of the third
pass, this same gap is now also confirmed to block screenshot capture
itself (see above), not just GPU-driver-specific compositing bugs.

## Quick start

```bash
cd ~/code/dotfiles/devcontainer/scripts/kwin-wayland-test

# Finding 1's discriminator: burst-spawn N kitty windows the way the
# UNFIXED desktop-layout-restore used to. Reliably FAILS (rows 1-2 stuck
# at default size) when run as the FIRST burst against a freshly started
# KWin session (this harness's run.sh always starts KWin fresh, so this
# reliably reproduces) — the harness's proven, reproducible discriminator.
bash run.sh --scenario burst --count 6

# Supplementary: one window at a time, no multi-window contention. Mostly
# passes (only the very-first-window-in-a-session cold-start blip fails,
# and it self-corrects within ~1s, unlike the burst scenario's permanent
# stuck state) — demonstrates the bug needs focus-steal contention from a
# subsequent spawn, not just "any resize is racy".
bash run.sh --scenario single --count 5 --mode cold

# Proves the FIX (bin/.local/bin/desktop-layout-restore's
# resize_and_verify(), extracted live from the real script — see "Fix"
# section above). Run this manually inside a kept container (run.sh has no
# --scenario flag for it yet; not wired into run.sh since it wasn't part
# of the original discriminator set):
bash run.sh --scenario burst --keep   # starts + keeps a fresh container
docker exec -u tester -e XDG_RUNTIME_DIR=/run/user/1000 -e HOME=/home/tester \
  -e SETTLE_SECONDS=8 kwin-wayland-test \
  bash /opt/harness/repro-burst-fixed.sh myrun 6

# Keep the container up for manual poking
bash run.sh --scenario burst --keep
docker exec -it -u tester -e XDG_RUNTIME_DIR=/run/user/1000 kwin-wayland-test bash
```

**IMPORTANT — never spawn real kitty windows outside this container.**
Any script that spawns real kitty windows against a real Wayland session
(this includes `tests/test_desktop_layout_native_sessions.sh` in the repo
root when `WAYLAND_DISPLAY` is set) must run exclusively inside this
Docker harness. Running it directly against the live desktop spawns real,
focus-stealing windows on the user's actual desktop — this happened once
during the 2026-08-01 pass (see "Fix" section above) and was a process
mistake, not a deliberate test strategy.

## Architecture

- `Dockerfile` — Ubuntu **26.04** (switched from 25.10 on 2026-08-01 to
  exactly match the real host's KWin version — see "Harness fidelity
  audit") + systemd + dbus + `kwin-wayland` (virtual backend is built into
  the binary itself; no separate `kwin-wayland-backend-virtual` package)
  + Mesa software rendering libs + kdotool (built from crates.io, matching
  how it's provisioned on the real host) + kitty (upstream installer,
  matching `setup.sh`)
- `harness/start-kwin.sh` — runs inside the container as the test user;
  starts `kwin_wayland --virtual` under its own private D-Bus session
  (the `dbus-run-session` pattern used by `isac322/kwin-mcp`), self-
  daemonizes via `setsid` so it survives the launching `docker exec`
  returning, writes `WAYLAND_DISPLAY`/`DBUS_SESSION_BUS_ADDRESS` to
  `~/.local/state/kwin-test/env` for later commands to source
- `harness/repro-burst.sh` — the primary, discriminating scenario against
  the UNFIXED behavior: spawns N kitty windows back-to-back exactly like
  `desktop-layout-restore`'s old loop (before/after-diff + `getwindowpid`
  window discovery — NOT `kdotool search --pid`, which proved unreliable
  in manual testing here), calls bare `windowsize`/`windowmove` per window
  with no settle wait or verification, then independently re-queries every
  window's geometry after a fixed settle period
- `harness/repro-burst-fixed.sh` — same loop shape, but calls the FIXED
  `resize_and_verify()`, extracted live via `sed`/`source <(...)` from the
  real `bin/.local/bin/desktop-layout-restore` (bind-mounted read-only at
  `/workspace`) rather than a hand-maintained copy, so it can't silently
  drift from the actual production fix. Proves the fix closes the race.
- `harness/repro-cold-resize.sh` — supplementary single-window scenario
  with `WAYLAND_DEBUG=1` tracing baked in per-run, `--mode cold|settled`
  for isolating spawn-timing from focus-steal contention
- `run.sh` — outside-container orchestrator, `--scenario burst|single`
  (does not yet drive `repro-burst-fixed.sh` — run it manually per the
  Quick Start snippet above)

## Reusing for other KWin/kdotool/desktop-layout dotfiles testing

This is the cleanest way to test anything in dotfiles that depends on a
real (not mocked) KWin scripting session — `kdotool`-based tooling,
`desktop-layout-restore` changes, or general KWin D-Bus/scripting-API
behavior. The container has dbus + logind running via systemd, matching
the real desktop's plumbing model (though KWin itself runs on a private
per-test D-Bus session via `dbus-run-session`, isolated from the
system/user D-Bus buses systemd manages — this mirrors `kwin-mcp`'s
isolation pattern and means this harness cannot test systemd-user-session
environment-variable propagation bugs like the one that actually caused
the live incident; testing that class of bug would need KWin started
under the container's real `systemctl --user` session instead).

## Limitations

Same infra caveats as `../tmux-restore-test/`: `--privileged` +
`--cgroupns=host` (standard/acceptable for an isolated systemd-in-Docker
test container, not for anything user-facing), read-only bind mount, no
host secrets involved. Additional to this harness:

- Window IDs / process discovery: `kdotool search --pid` is NOT a
  reliable filter in this environment (returned a stale, already-dead
  window's ID across multiple fresh spawns in manual testing) — use the
  before/after-diff + `getwindowpid`-confirmation pattern instead (same
  as the real `desktop-layout-restore` script already does; this was
  independently rediscovered while debugging the harness, not copied at
  first).
- No screenshot capability, no real GPU path — see "What we could not
  test" above.
- Rebuild the image (`--rebuild`) when `Dockerfile` or `harness/*.sh`
  change (they're `COPY`'d in). The bind-mounted dotfiles repo is read
  live otherwise.

## Still open: the original "small rectangle with ghosted content" symptom

Not explained, despite two independent theories tested and disproven, and
now four scenarios tried:

1. Burst-spawn resize race (Finding 1 / the Fix) — produces
   stuck-at-default-size windows, not ghosted content. Now fixed anyway,
   on its own merits.
2. Stale `WAYLAND_DISPLAY` (Finding 2, and the actual live-incident root
   cause) — produces launch failures, not misrendering of an already-live
   window.
3. Minimize → resize → restore — produces the same stuck-at-wrong-geometry
   signature as (1), not ghosted content either.
4. Fractional display scaling (the leading theory this third pass was
   built to test) — **could not be tested at all**: KWin's virtual backend
   has no working mechanism to produce a non-1.0 client-visible scale
   factor (four independent approaches tried and confirmed dead —
   `--scale` CLI flag, `kwinoutputconfig.json`, scripting-API write, Qt
   env vars — see "Fractional scaling: KWin's virtual backend cannot do
   it" above). This is a **harness-capability gap, not a disproof of the
   theory** — unlike (1)-(3), which were reproduced and shown to produce a
   different failure shape than the reported symptom, fractional scaling
   was never actually exercised, so it remains neither confirmed nor
   ruled out.

Everything this harness CAN test is **protocol-level / scripting-API-level
behavior** against a **software-rendered (llvmpipe), non-scaled virtual
KWin backend**. Two real, evidenced architectural limits now confirmed
(not assumed) for why the ghosting symptom's actual mechanism is likely
out of reach here regardless of further scenario attempts:

- **No real GPU/DRM compositing path.** Confirmed via `kwin_wayland`'s own
  startup log (`Failed to open drm node`, Zink→llvmpipe fallback) and,
  this pass, via the fact that even KWin's own screenshot-capture pipeline
  (`org.kde.KWin.ScreenShot2`) fails with `Error.Cancelled` on every
  method tried once the plugin is installed and permission-gated — a
  DMA-BUF/GBM-dependent capture path failing is a stronger signal of a
  real render-target gap than the startup log alone. If the ghosting
  symptom's mechanism involves buffer age tracking, damage-region
  tracking, or a specific driver's swapchain behavior (the kind of thing
  kitty#7478's `single_pixel_buffer` citation was originally gesturing
  at), this harness cannot reproduce or rule it out.
- **No fractional/non-integer output scaling**, confirmed exhaustively
  this pass (see above) rather than just noted as a default-config gap.

Both are honest, evidenced reasons the symptom stays open — not a gap in
this investigation's effort. Closing either would require infrastructure
beyond a test-harness investigation's scope: real GPU passthrough
(`kwin_wayland --drm` against an actual render node, not `--virtual`) for
the first, or a patched/forked KWin virtual backend that propagates
`--scale` into `LogicalOutput::scale()` for the second.

The most productive next step, if the symptom recurs live, is direct
observation on the real desktop at the moment it happens: capture
`WAYLAND_DEBUG=1` output for the affected kitty process (if it's still
running — `kitty --wait-for-single-instance-window-close` isn't needed,
just attach `strace -f -e trace=network -p <pid>` or restart kitty's
`--debug-rendering` flag if it has one, and check `journalctl --user -b 0
| grep -i kwin` around the timestamp) rather than trying to construct more
synthetic repro scenarios without a concrete new mechanism to test —
further scenario-guessing without new evidence would be exactly the kind
of unevidenced speculation this investigation is trying to avoid. If it
recurs on a fractionally-scaled output specifically, that observation
itself would be significant evidence for the scaling theory, since this
harness has now confirmed it structurally cannot check that condition.
