---
title: "Self-hosted ntfy is the missing mobile ambient channel: click-URL and view/http action buttons plus five priority levels give actionable job/agent notifications, but ntfy can only deep-link to a URL scheme — there is no supported deep-link into a Termius session, so the actionable link should open a web surface, not the terminal"
date: 2026-07-16
topic: session-ux
tags: [ntfy, notifications, mobile, deep-link, agent-events, priority, actionable]
status: draft
sources: [ntfy-publish, ntfy-sh, ntfy-examples]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- ntfy is HTTP pub/sub: publish to a topic with a PUT/POST (e.g. `curl -d "msg" ntfy.sh/topic`); anyone subscribed to the topic receives the push. Topics function as passwords (no signup), so self-hosted instances add token/ACL auth for read/write scoping per topic. [ntfy-sh][ntfy-publish]
- ntfy supports five priority levels (min=1 … max=5) via the `X-Priority`/`Priority` header, mapping to different sound/vibration and prominence; High/Max make critical notifications stand out. [ntfy-publish]
- A single **click action** opens a URL when the notification is tapped, set via `X-Click`/`Click`; an `http(s)://` URL opens the browser/app, and any other URI that a registered app can handle will open that app. [ntfy-publish]
- ntfy supports interactive **action buttons** via `X-Actions`/JSON, with action types **view** (open a URL), **http** (send an HTTP request in the background), and **broadcast** (Android intents). Action buttons require self-hosting + CORS configuration to work. [ntfy-publish]
- The canonical use case is "notify me when a long job finishes/fails": chain `long-cmd && curl -H "Title: Job done ✅" -H "Priority: high" -H "Click: https://.../logs" -d "..." https://ntfy.example/jobs`, and the failure-wrapper pattern sends a high-priority tagged message on non-zero exit. [ntfy-sh][ntfy-examples]
- Tags/emojis classify and personalize notifications (`X-Tags`), and titles are set with `X-Title`. [ntfy-publish]
- Self-hosting keeps notifications on your own network, allows raising or disabling rate limits, and manages access via tokens/ACLs (read-write / read-only / write-only per topic per user). [ntfy-publish]
- No ntfy documentation describes a deep-link into a specific SSH-client session; the deep-link primitive is a URL/URI handled by whatever app registers that scheme, not a terminal-session address. [ntfy-publish]

## SOURCES

**ntfy-publish**
URL: https://docs.ntfy.sh/publish/
Accessed: 2026-07-16
Quote: "To define a click action for the notification, pass a URL as the value of the X-Click header (or its alias Click). If you pass a website URL (http:// or https://) the web browser will open." / Action button types: view (open URL), http (send HTTP request), broadcast (Android intent). / Priority via `X-Priority` (1 min … 5 max). / "For actions to work, you need to self host ntfy and adjust your CORS value."

**ntfy-sh**
URL: https://ntfy.sh/
Accessed: 2026-07-16
Quote: "Whether it's receiving alerts from cronjobs, or when a GitHub Actions pipeline finishes ... ntfy will let you know." / topics created on first use, function as passwords.

**ntfy-examples**
URL: https://docs.ntfy.sh/examples/
Accessed: 2026-07-16
Quote: Wrap a command to notify on completion/failure; combine title, priority, tags, and a click URL for job-done/job-failed alerts.

## SYNTHESIS

Tim already self-hosts ntfy, so the ambient-awareness gap (no Plasma → no notifications on mobile) is closeable today with primitives that exist. The design questions the corpus can answer:

**What events?** The high-value ones are agent/job lifecycle transitions the phone can't otherwise see: agent finished / agent needs input (idle-waiting-on-a-prompt) / long build or test passed-or-failed / a watched window went idle. These map cleanly onto tmux hooks and the assistant-resurrect sidecar Tim already runs (it knows per-pane agent session state). "Agent is blocked waiting for me" is the killer event — it's exactly the thing that today only surfaces if he happens to be looking at that window.

**What priorities?** Reserve Max/High for "agent blocked on input" and "job failed" (the ones that should override silent mode). Default for "job finished OK." Min/Low for informational/idle transitions. One topic per class or per host, with per-topic ACL tokens (Tim's infra already has the auth pattern).

**Actionable links — the important constraint:** ntfy's `Click`/`view` action can only open a **URL/URI**. There is *no supported deep-link into a Termius session* — you cannot tap a notification and land in the specific tmux window inside Termius. What you *can* do:
- Open a **web surface** that shows the relevant context (a log view, a Grafana panel, a small status page listing which windows are blocked). This is the honest, supported path.
- Use an **http action button** to *act* without opening anything — e.g. "Approve" / "Send Enter to the blocked agent" as a background HTTP call to a tiny endpoint on peregrine that runs `tmux send-keys`. This is powerful: the notification itself can unblock an agent without opening the terminal at all, sidestepping the whole reconnect cost for simple approvals.
- A Termius `termius://` URL scheme, if one exists, would be an app-specific URI (unverified — not documented by ntfy or confirmed in Termius docs here; treat as an open question to test, low confidence). Even if it opened Termius, it would not target a specific tmux window — that requires the server-side reconnect queue from the grouped-sessions entry.

**Recommendation:** stand up ntfy topics for agent-blocked / job-done / job-failed, priority-tiered; make the primary actionable affordance an **http action button** that performs the common responses (approve, send-enter, kill) via a minimal peregrine endpoint, so the phone becomes a control surface, not just a viewer. Use `Click` → a small web status page (not Termius) for "show me more." This gives ambient awareness *and* lets many interactions complete without ever paying the SSH-reconnect + tab-hunt cost — the highest-leverage part of the whole redesign.
