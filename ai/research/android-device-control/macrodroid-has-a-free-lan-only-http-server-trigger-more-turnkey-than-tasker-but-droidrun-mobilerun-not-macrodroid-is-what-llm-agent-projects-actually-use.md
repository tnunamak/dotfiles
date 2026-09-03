---
title: "MacroDroid ships a free, LAN-only 'HTTP Server Request' trigger that is more turnkey than Tasker's for simple remote-trigger use cases, but the actual 2025-2026 LLM-agent-controls-Android ecosystem (DroidRun/Mobilerun) bypasses both automation apps in favor of adb + an accessibility-service 'Portal' app"
date: 2026-08-30
topic: android-device-control
tags: [macrodroid, tasker, webhook, http-server, droidrun, mobilerun, llm-agent, android-automation]
status: draft
sources: [macrodroid-http-server-wiki, macrodroid-webhook-medium, macrodroid-webhook-wiki, tasker-vs-macrodroid-2026, droidrun-hn, mobilerun-readme, mobilerun-blog]
source_session: 3463e3ab-cbe6-426b-b831-a07c925c883c
---

## CLAIMS

- MacroDroid ships two distinct inbound-HTTP trigger mechanisms, documented on its community wiki: a **Webhook (URL)** trigger that fires via a cloud relay (`trigger.macrodroid.com/[device-id]/...`, delivered to the device over Firebase Cloud Messaging, reachable from the public internet), and a separate **HTTP Server Request** trigger that runs an actual HTTP server directly on the device, explicitly restricted to the local network. [macrodroid-webhook-wiki][macrodroid-http-server-wiki]
- The Webhook trigger predates the HTTP Server trigger and was introduced in MacroDroid v3.25, per the developer's own announcement: "In V3.25 of MacroDroid a new trigger was introduced... you can type a particular URL into a web browser and a trigger will be invoked on your device," supporting both GET and POST. [macrodroid-webhook-medium]
- The on-device HTTP Server trigger supports GET and POST, lets multiple triggers share one port via distinct path identifiers, can capture POST body content (or query parameters, in a later update) into a string or dictionary variable, and can send a configurable response body + HTTP status code back to the caller — functionally comparable to Tasker's native "HTTP Request" event/`HTTP Response` action pair. [macrodroid-http-server-wiki]
- Both MacroDroid HTTP triggers document IP-address allowlisting (with wildcard support) and a "variable whitelist" to block unauthorized variable writes via URL parameters as their built-in safeguards; neither documents a native bearer-token/API-key auth field the way an API gateway would — the outbound HTTP Request *action* (for MacroDroid calling out) supports Basic Auth and mTLS, but the inbound *trigger* does not carry the same auth options. [macrodroid-http-server-wiki][macrodroid-webhook-wiki]
- A 2026 comparison piece (independent of both vendors) frames the two apps' relative agent/API friendliness as a tradeoff, not a clean win for either side: "pick Tasker if you want unlimited Android automation power and you accept a steep learning curve, and pick MacroDroid if you want most of the same automations working in five minutes," and cites Tasker's plugin ecosystem as roughly 10x larger — i.e., MacroDroid's HTTP Server trigger is easier to wire up out of the box, but Tasker's HTTP Request event is more composable once combined with Tasker's broader plugin/action library. [tasker-vs-macrodroid-2026]
- Neither Tasker nor MacroDroid is the tool that current (2025-2026) open-source "LLM agent controls an Android phone" projects actually build on. DroidRun (MIT-licensed, 8,000+ GitHub stars as of its Hacker News launch thread) and its successor Mobilerun instead drive the device directly via **adb** (screenshots + UI/accessibility-tree inspection + tap/swipe/type action execution), with Mobilerun additionally requiring its own "Portal" companion app whose Android Accessibility Service is enabled once during setup — not a Tasker or MacroDroid profile. [droidrun-hn][mobilerun-readme]
- Mobilerun's own setup instructions require "ADB installed and an Android device with Developer options and USB debugging enabled," followed by a `mobilerun setup` step that installs the Portal app and walks the user through manually enabling its accessibility service — a one-time interactive grant, not something remotely bootstrappable without touching the phone at least once. [mobilerun-readme][mobilerun-blog]

## SOURCES

**macrodroid-webhook-wiki**
URL: https://macrodroidforum.com/wiki/index.php/Trigger:_Webhook_(URL)
Accessed: 2026-08-30
Quote: webhook fires "when the specified web URL is called from anywhere," delivered via Firebase Cloud Messaging; URL is unique per device and changes on reinstall/data-clear; supports an IP Address Whitelist (wildcards + Magic Text) and a Variable Whitelist.

**macrodroid-http-server-wiki**
URL: https://www.macrodroidforum.com/wiki/index.php/Trigger:_HTTP_Server_Request
Accessed: 2026-08-30
Quote: "The HTTP server only operates on the local network and is not accessible from the internet." Documents port config in MacroDroid Settings, multiple triggers sharing one port via distinct identifiers, GET/POST support, saving POST body to a variable or file (Android 11+ file-save requires "All Files Access"), and an IP whitelist for access restriction.

**macrodroid-webhook-medium**
URL: https://medium.com/@macrodroid/introducing-the-webhook-trigger-a760e2ee140d
Accessed: 2026-08-30
Quote: "In V3.25 of MacroDroid a new trigger was introduced... you can type a particular URL into a web browser and a trigger will be invoked on your device."

**tasker-vs-macrodroid-2026**
URL: https://www.droidrooter.com/blog/macrodroid-vs-tasker-vs-automate-2026/
Accessed: 2026-08-30
Quote: "pick Tasker if you want unlimited Android automation power and you accept a steep learning curve, and pick MacroDroid if you want most of the same automations working in five minutes."

**droidrun-hn**
URL: https://news.ycombinator.com/item?id=43703688
Accessed: 2026-08-30
(Launch thread for DroidRun, described by its creator as an open-source tool letting AI agents execute tasks in Android apps by mimicking human interaction via adb + screenshot analysis; MIT license, 8,000+ stars per AlternativeTo's later listing.)

**mobilerun-readme**
URL: https://github.com/droidrun/mobilerun/blob/main/README.md
Accessed: 2026-08-30
Quote: setup requires "ADB installed and an Android device with Developer options and USB debugging enabled"; `mobilerun setup` installs the Portal app and enables its accessibility service; control uses "UI trees, screenshots, text input, gestures, app launching, and device state from the Portal runtime."

**mobilerun-blog**
URL: https://knightli.com/en/2026/05/29/mobilerun-mobile-device-agent-framework/
Accessed: 2026-08-30
(Describes Mobilerun as DroidRun's successor framework, targeting both Android and iOS, positioned as the execution layer between mobile devices and LLM agents rather than a vendor-specific tool.)

## SYNTHESIS

For the narrow question "is there an automation app more agent-friendly than Tasker," MacroDroid's on-device **HTTP Server Request** trigger is a genuine, free-tier, well-documented answer for LAN-reachable remote triggering — it is arguably more turnkey than Tasker's equivalent HTTP Request event because it's positioned as MacroDroid's main selling point (ease of setup) rather than a power-user feature buried in a much larger action/plugin surface. Security posture is roughly equivalent to Tasker's: IP allowlisting is the primary safeguard on both, neither ships bearer-token auth on the inbound trigger, so an agent (or the user setting this up) should treat "LAN-only + IP allowlist" as the safety boundary and not port-forward either app's HTTP listener to the internet without adding an explicit auth layer (e.g., a reverse proxy with basic auth, or a VPN/Tailscale hop) in front of it.

But this framing — "which automation app is more agent-friendly" — turns out to be the wrong question for the broader goal of LLM-agent-driven phone control. The actual 2025-2026 open-source ecosystem building "AI agent has hands on an Android phone" (DroidRun, and its successor Mobilerun, MIT-licensed with real community traction) doesn't route through Tasker or MacroDroid profiles at all. It drives the phone directly over adb, using its own lightweight "Portal" companion app purely to expose an Accessibility Service for structured UI-tree reads (the semantic upgrade over blind coordinate taps described in the companion entry on adb+screencap). This is a materially different and more general integration path than "trigger a pre-built macro" — it lets the agent improvise arbitrary UI navigation task-by-task rather than being limited to whatever profiles/macros were hand-authored in advance. The practical implication for a home-lab setup: Tasker/MacroDroid's HTTP triggers remain the right tool for *fixed, pre-defined* actions (send this notification, run this specific script, toggle this specific setting) where a human already knows exactly what should happen; a DroidRun/Mobilerun-style adb+accessibility-tree pipeline is the right tool when the agent needs open-ended "do whatever this natural-language task requires" phone control. The two are complementary, not competing — an agent could reasonably use Tasker's HTTP Server for known, safe, frequently-repeated actions and fall back to an adb-driven loop only for one-off or unanticipated tasks.
