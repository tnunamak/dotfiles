---
title: "systemd prefix drop-ins can order tmux transient spawn scopes before the parent service stops"
date: 2026-08-30
topic: systemd
tags: [systemd, tmux, cgroups, transient-units, shutdown-ordering]
status: settled
sources: [tmux-systemd-c, tmux-configure, systemd-unit-man7, systemd-unit-freedesktop, local-incident]
source_session: 019f8f87-ae5f-7721-bce3-9eb8862b0622
---

## CLAIMS

- tmux 3.6b includes `compat/systemd.c`, which creates a transient systemd scope for a process by calling `StartTransientUnit` through the per-user systemd manager's D-Bus connection. [tmux-systemd-c]
- tmux 3.6b's `configure.ac` includes a `--disable-cgroups` option, so cgroup support can be removed at build time. [tmux-configure]
- systemd accepts drop-in directories for units and applies dash-prefix drop-ins: for a unit name with dashes, systemd also reads drop-ins from successively truncated prefix names ending in `-.type.d/`. [systemd-unit-man7] [systemd-unit-freedesktop]
- systemd ordering dependencies are inverse on stop: if one unit has `Before=` another, and both are stopped, the unit with `Before=` is stopped after the other unit. [systemd-unit-man7] [systemd-unit-freedesktop]
- During the 2026-08-30 tmux recovery incident, `tmux.service` began stopping at 16:33:20 CDT; its ExecStop save began at 16:33:24 while tmux windows and `tmux-spawn` scopes were already disappearing. [local-incident]
- During the same incident, the degraded save captured 59 panes instead of the last proven clean 191 panes, and the 191-to-59 collapse passed the layout cliff guard because 59 panes was still above its 20% rejection threshold. [local-incident]
- Live local verification after `systemctl daemon-reload` showed both a disposable `tmux-spawn-UUID.scope` and an existing tmux-spawn scope had `Before=tmux.service shutdown.target`, proving the prefix drop-in applied to matching UUID-named transient scopes. [local-incident]

## SOURCES

**tmux-systemd-c**
URL: https://raw.githubusercontent.com/tmux/tmux/3.6b/compat/systemd.c
Accessed: 2026-08-30

**tmux-configure**
URL: https://raw.githubusercontent.com/tmux/tmux/3.6b/configure.ac
Accessed: 2026-08-30

**systemd-unit-man7**
URL: https://man7.org/linux/man-pages/man5/systemd.unit.5.html
Accessed: 2026-08-30

**systemd-unit-freedesktop**
URL: https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html
Accessed: 2026-08-30

**local-incident**
URL: ../../../inbox/2026-08-30-tmux-recovery-incident.md
Accessed: 2026-08-30

## SYNTHESIS

tmux 3.6b's systemd+cgroups path makes each pane child visible to systemd as a transient `tmux-spawn-UUID.scope`. That is useful isolation and accounting, but it also means shutdown ordering must include those generated scopes. In the incident, shutdown had no ordering edge that kept tmux's pane scopes alive until `tmux.service` ran its ExecStop save, so the scopes disappeared first and tmux saved a partially collapsed topology.

The local fix is a systemd dash-prefix drop-in at `tmux-spawn-.scope.d` with `[Unit] Before=tmux.service`. Prefix drop-ins apply to all UUID-suffixed `tmux-spawn-*.scope` units, including transient ones, and systemd's inverse stop ordering makes those scopes stop after `tmux.service` when both are in the same shutdown transaction. The measured local proof after daemon reload showed the intended `Before=tmux.service shutdown.target` edge on both a disposable and an existing tmux-spawn scope.

This is preferable to rebuilding tmux with `--disable-cgroups`: the drop-in preserves tmux's cgroup integration and fixes the missing ordering relationship at the systemd layer where the race occurs. Rebuilding without cgroups removes the transient scopes, but it also gives up the process-management behavior tmux deliberately compiled in.
