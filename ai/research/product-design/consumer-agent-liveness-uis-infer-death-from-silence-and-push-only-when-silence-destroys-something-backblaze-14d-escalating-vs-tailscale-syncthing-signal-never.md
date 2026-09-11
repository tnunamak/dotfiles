---
title: "Consumer agent-liveness UIs infer death from silence rather than error reports, and only push unprompted when the silence itself destroys something — Backblaze escalates by email at 14/21/28/60/90 days because data is purged at 30, while Tailscale, Syncthing and Signal never push at all"
date: 2026-09-09
topic: product-design
tags: [agent-liveness, offline-ux, dead-mans-switch, notification-thresholds, last-seen]
status: draft
sources: [backblaze-missing-computer, backblaze-retention, datadog-host-monitor, datadog-infra-list, signal-linked-devices, signal-desktop-strings, syncthing-config, syncthing-offline-notify-declined, tailscale-lastseen-semantics]
source_session: 5cbd97d7-83ca-4916-992d-d0ca0b6c2324
---

## CLAIMS

- Backblaze alerts by email when a computer "has not updated for more than 14 days", and re-nags on an escalating-then-decaying ladder at 14, 21, 28, 60 and 90 days after the machine "was last seen by Backblaze servers". [backblaze-missing-computer]
- Backblaze's push is justified by a destructive consequence, not by staleness alone: backup data is retained only "30 days from the last time data was scanned", so a drive must be connected at least once every 30 days to be maintained. The alert ladder (14 d) is deliberately set to fire well before the purge (30 d). [backblaze-retention]
- Datadog detects a stopped agent by absence, not self-report: the agent only ever emits `datadog.agent.up` as OK, and the host monitor asks the user to "Enter the number of minutes to check for missing data", defaulting to 2 minutes. The resulting monitor state is named `NO DATA`, and notification is explicitly opt-in ("Show NO DATA" vs "Show NO DATA and notify"). [datadog-host-monitor]
- Datadog's Infrastructure List defaults to "hosts with activity in the last 15 minutes"; non-reporting hosts become `INACTIVE` and "it could take up to 2 hours for these hosts to drop out of the Infrastructure List". [datadog-infra-list]
- Signal enforces two distinct inactivity thresholds that measure different actors: the primary phone must come online "at least once every 30 days" or linked devices unlink, and a linked device separately unlinks "after 45 days of inactivity". [signal-linked-devices]
- Signal surfaces inactivity only as an in-app banner rendered on open, never as a push: the device row label is "Last active %s", and the escalation copy is `CriticalIdlePrimaryDeviceModal__title` = "Account action required". The only device-related notification channel fires on *adding* a linked device, not on one going stale. [signal-desktop-strings]
- Syncthing's default `reconnectionIntervalS` is 60 seconds, and its UI distinguishes plain "Disconnected" from "Disconnected (Inactive)" — a severity gradient encoded in the label rather than a boolean. The 7-day threshold that flips to "(Inactive)" is present in `syncthingController.js` but is NOT stated in the official documentation prose. [syncthing-config]
- Syncthing declined to add offline notifications to core: the feature request for email/notification on device-offline was closed as "not planned", leaving push to third-party wrappers. [syncthing-offline-notify-declined]
- Tailscale's `LastSeen` is a "GoneAt" timestamp rather than a ticking heartbeat — a maintainer comment states `LastSeen` "is not updated when Online is true" — so the displayed value means "the moment it dropped", not "last contact". Tailscale publishes no numeric offline threshold. [tailscale-lastseen-semantics]

## SOURCES

**backblaze-missing-computer**
URL: https://help.backblaze.com/hc/en-us/articles/217665108
Accessed: 2026-09-09
Quote: "If Backblaze Computer Backup detects that a computer has not updated for more than 14 days, an alert is sent to the registered email address."

**backblaze-retention**
URL: https://www.backblaze.com/computer-backup/docs/retain-backups-during-extended-leaves
Accessed: 2026-09-09
Quote: "drives are required to be connected a minimum of once every 30 days to be maintained in your backup"

**datadog-host-monitor**
URL: https://docs.datadoghq.com/monitors/types/host/
Accessed: 2026-09-09
Quote: "Enter the number of minutes to check for missing data. The default value is 2 minutes."

**datadog-infra-list**
URL: https://docs.datadoghq.com/infrastructure/list/
Accessed: 2026-09-09
Quote: "it could take up to 2 hours for these hosts to drop out of the Infrastructure List"

**signal-linked-devices**
URL: https://support.signal.org/hc/en-us/articles/360007320551-Linked-Devices
Accessed: 2026-09-09
Quote: "After linking a device, your phone has to come online at least once every 30 days. Otherwise, your linked devices will become unlinked. Linked devices will also become unlinked after 45 days of inactivity."

**signal-desktop-strings**
URL: https://github.com/signalapp/Signal-Desktop/blob/main/_locales/en/messages.json
Accessed: 2026-09-09
Quote: "Your account will be deleted soon unless you open Signal on your phone"

**syncthing-config**
URL: https://docs.syncthing.net/users/config.html#options-element
Accessed: 2026-09-09
Quote: "reconnectionIntervalS ... The number of seconds to wait between each attempt to connect to currently unconnected devices. Default 60."

**syncthing-offline-notify-declined**
URL: https://github.com/syncthing/syncthing/issues/9587
Accessed: 2026-09-09
Quote: "closed as not planned"

**tailscale-lastseen-semantics**
URL: https://github.com/tailscale/tailscale/issues/2107
Accessed: 2026-09-09
Quote: "LastSeen is not updated when Online is true"

## SYNTHESIS

The organising principle across all five products is that **notification cost is priced against consequence, not against staleness**. Backblaze is the only one that pushes unprompted, and it is also the only one where silence destroys the asset (purge at 30 days) — so it nags at 14/21/28 while action still helps, then decays to 60/90 rather than either giving up or spamming forever. Tailscale, Syncthing and Signal all let a quiet agent stay quiet, because nothing is lost by waiting. The practical rule when designing an agent-liveness feature: if going dark has no destructive consequence, a dashboard with an honest "last seen" timestamp is sufficient and a push is unjustified noise.

Second, **silence is the detector, not error reports** — a crashed, powered-off or partitioned agent structurally cannot self-report, so Datadog's dead-man's switch (agent only ever says OK; the server infers death from missing data) is the correct default. Syncthing is the sole exception and only because it holds a live TCP connection whose teardown is itself an event. Any agent without a persistent socket gets Datadog's model, which means the server must hold an *expected cadence* to compare against; without that stored expectation there is nothing to be late relative to.

Third, **use two threshold tiers and don't collapse them**: machine-timescale detection ("is it up right now" — Datadog 2/15 min, Syncthing 60 s) and human-timescale escalation ("should a person act" — Backblaze 14 d, Syncthing 7 d, Signal 30/45 d). Encode the gradient in the vocabulary too ("Disconnected" vs "Disconnected (Inactive)"), since a single online/offline boolean discards information users need. Finally, Tailscale's `LastSeen`-is-really-`GoneAt` subtlety is a genuine trap: decide explicitly whether your timestamp means "last contact" or "moment of death", because the two differ and the difference leaks into the UI copy.

Caveats retained deliberately: Syncthing's 7-day "(Inactive)" threshold is source-verified but undocumented; Tailscale publishes no offline threshold at all; Datadog's 24-hour host-removal figure and `no_data_timeframe` minimum were not confirmable against primary docs. `help.backblaze.com` returned 403 to direct fetch, so those claims were corroborated via the first-party `backblaze.com/computer-backup/docs` mirror.
