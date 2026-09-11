---
title: "Phala Cloud / dstack has no built-in CVM scheduler (start/stop/delete are manual CLI/API-only), so scheduled per-tenant wake for a scale-to-zero confidential-compute fleet must be built as a central job queue against the existing warm-pool claim-loop, not a provider feature — matching how Fly.io, Cloud Run, and AWS all solve this (only Cloudflare Durable Object alarms give a true per-tenant wake primitive)"
date: 2026-09-11
topic: confidential-computing-scheduling
tags: [phala, dstack, tee, confidential-computing, scale-to-zero, cron, scheduling, multi-tenant, cloud-run, fly-io, durable-objects]
status: draft
sources: [phala-cvm-lifecycle-cli, phala-cloud-cli-archived, dstack-github-repo, dstack-onboarding-docs, cf-do-alarms-blog, cf-do-alarms-gitnotifier, cf-agents-sdk-schedule, flyio-autostop-autostart, flyio-scheduled-machines, flyio-cron-manager, gcp-cloud-run-jobs-scheduler, gcp-cloud-run-min-instances-tradeoff, aws-eventbridge-scheduler-quotas, aws-eventbridge-scheduler-pricing, azure-container-apps-jobs-schedule, azure-container-apps-scale-zero-cron-caveat, nitro-enclaves-no-scale-to-zero, gcp-confidential-space-single-flag]
source_session: d2141e7d-8e99-4ad0-bc09-f089e4597605
---

## CLAIMS

- The Phala Cloud CLI (`phala cvms ...`) exposes CVM lifecycle as discrete manual commands — `stop`, `start`, `delete`, `get` (status), `attestation` — with no scheduling, cron, or auto-wake parameters documented anywhere in the CLI usage guide. [phala-cvm-lifecycle-cli]
- The original `Phala-Network/phala-cloud-cli` GitHub repo is archived (as of Feb 20, 2026) and folded into the `phala-cloud` monorepo under `/cli`; no scheduling feature surfaced in either location. [phala-cloud-cli-archived]
- The dstack architecture (`dstack-vmm` managing CVMs on a bare TDX host, `dstack-gateway` reverse-proxying TLS, `dstack-kms` for key derivation, `dstack-guest-agent` inside the CVM) documents full lifecycle control — create, start, shut down, delete, replicate — as operations the *application developer* triggers via the VMM client; none of the reviewed docs (deployment.md, onboarding.md) describe a time-based or cron trigger for these operations. [dstack-github-repo][dstack-onboarding-docs]
- No search of docs.phala.com, docs.phala.network, or the Dstack-TEE/dstack GitHub repo surfaced a built-in scheduler, cron trigger, or "wake CVM on a timer" feature. The only cron-adjacent changelog mention found was for Phala's own internal node-monitoring infrastructure, not a user-facing CVM scheduling primitive. [phala-cvm-lifecycle-cli]
- Cloudflare Durable Objects give each object instance its own alarm (`alarm()`), guaranteed to fire within a few seconds of the requested time; a Workers service can have only 3 Cron Triggers total, but unlimited Durable Objects each with their own independently-scheduled alarm — this is architecturally the cleanest "one wake-up per tenant" primitive among all providers surveyed. [cf-do-alarms-blog]
- A documented production pattern ("GitNotifier") runs one Durable Object per user with a single self-rescheduling alarm and zero central cron triggers; the object hibernates to zero compute between alarms and reconstitutes from durable storage when the alarm fires. [cf-do-alarms-gitnotifier]
- Cloudflare's Agents SDK builds cron-like recurring schedules on top of the single-alarm-per-object primitive by storing multiple schedules in a SQLite table (`cf_agents_schedules`) and always arming just one alarm for the next-due row; cron schedules reschedule themselves after firing, one-time schedules self-delete. [cf-agents-sdk-schedule]
- Fly.io Machines support only coarse built-in scheduling — start hourly/daily/weekly/monthly via an interval-bucket API, no cron expressions — and have "no first-class scheduler" beyond that; the two production-recommended workarounds are (a) an external scheduler (GitHub Actions cron, EasyCron, etc.) hitting an HTTP route, which relies on Fly's autostart-on-request to boot the sleeping machine, or (b) the community `fly-apps/cron-manager` tool, which runs each cron job in its own fresh ephemeral machine from a central JSON config. [flyio-autostop-autostart][flyio-scheduled-machines][flyio-cron-manager]
- Fly.io's `auto_stop_machines`/`auto_start_machines` triggers only on proxy-visible inbound traffic; background work with no inbound request (including a machine's own internal cron loop) does not count as "load" and will not prevent auto-stop, and will not itself trigger auto-start. [flyio-autostop-autostart]
- Google Cloud Run's documented and widely-repeated best practice is: Cloud Scheduler triggers a Cloud Run **Job** (billed only for execution duration) at `min-instances=0`; paying for 23 hours of idle warm capacity to avoid a 2-15 second cold start on an hourly/daily job is treated as irrational by cost-optimization guides, several of which cite $150/mo → $5/mo case studies from switching min-instances=1 to scale-to-zero. [gcp-cloud-run-jobs-scheduler][gcp-cloud-run-min-instances-tradeoff]
- Cloud Run's `min-instances` floor can itself be time-scheduled (Cloud Scheduler calling `gcloud run services update --min-instances=N` on a cron), used to pre-warm during known business hours and drop to zero overnight — this is a documented pattern for the narrower case of avoiding cold starts on *user-facing* traffic, not for periodic batch jobs. [gcp-cloud-run-min-instances-tradeoff]
- AWS EventBridge Scheduler's default quota (as of the version surveyed) is 10 million schedules per account and up to 1,000 invocations/second, explicitly marketed for multi-tenant SaaS use ("manage all the different scheduled tasks that their customers have"); pricing is $1/million invocations after a permanent 14M/month free tier, with downstream Lambda/Fargate execution billed separately. [aws-eventbridge-scheduler-quotas][aws-eventbridge-scheduler-pricing]
- Azure Container Apps Jobs support a native `Schedule` trigger type (cron expression) as one of three trigger kinds (Schedule / Event via KEDA scaler / Manual), separate from the scale-to-zero behavior of standing Container Apps. [azure-container-apps-jobs-schedule]
- A documented Azure Container Apps caveat: an app relying on KEDA queue-based scale-to-zero cannot also run an internal periodic cron loop once at zero replicas, because nothing triggers a wake — the workaround used in practice is keeping `minReplicas: 1` specifically to keep the cron loop alive, which defeats scale-to-zero for that workload. This is the generic failure mode of "put cron inside the thing that scales to zero." [azure-container-apps-scale-zero-cron-caveat]
- AWS Nitro Enclaves run atop an always-on parent EC2 instance and have no native scale-to-zero concept for the enclave itself; any "wake on schedule" pattern there is really "start/stop the parent EC2 instance via EventBridge," which is architecturally closer to Phala's manual CVM stop/start than to a serverless wake primitive. [nitro-enclaves-no-scale-to-zero]
- GCP Confidential Space extends Confidential VMs to attestation-verified multi-party workloads and can be enabled with a single flag on existing machine types (lighter-weight than Nitro Enclaves' required parent/enclave re-architecture), but no scheduled-wake-specific feature for Confidential Space was found in this search. [gcp-confidential-space-single-flag]

## SOURCES

**phala-cvm-lifecycle-cli**
URL: https://docs.phala.com/phala-cloud/phala-cloud-user-guides/advanced-deployment-options/start-from-cloud-cli
Accessed: 2026-09-11
Quote: "phala cvms stop", "phala cvms start", "phala cvms delete jupyter-notebook", "phala cvms get jupyter-notebook", "phala cvms attestation" — no scheduling/cron parameters documented.

**phala-cloud-cli-archived**
URL: https://github.com/Phala-Network/phala-cloud-cli
Accessed: 2026-09-11
Quote: "archived by the owner on Feb 20, 2026 ... All development has moved to the monorepo at Phala-Network/phala-cloud, under the /cli directory."

**dstack-github-repo**
URL: https://github.com/Dstack-TEE/dstack
Accessed: 2026-09-11

**dstack-onboarding-docs**
URL: https://github.com/Dstack-TEE/dstack/blob/master/docs/onboarding.md
Accessed: 2026-09-11

**cf-do-alarms-blog**
URL: https://blog.cloudflare.com/durable-objects-alarms/
Accessed: 2026-09-11
Quote: "Cloudflare guarantees it will call the alarm() method at that time within a few seconds of accuracy" — contrasted with "a Workers service can have up to three Cron Triggers configured at once" vs. "an unlimited amount of Durable Objects, each of which can have a single alarm active at a time."

**cf-do-alarms-gitnotifier**
URL: https://dev.to/francoislp/how-to-schedule-weekly-tips-with-cloudflare-durable-objects-and-alarms-2eac
Accessed: 2026-09-11
Quote: "one Durable Object per user, a single alarm, and no cron trigger anywhere in the codebase."

**cf-agents-sdk-schedule**
URL: https://developers.cloudflare.com/agents/runtime/execution/schedule-tasks/
Accessed: 2026-09-11
Quote: "cron schedules automatically reschedule themselves after execution, one-time schedules delete themselves" — schedules persisted to a `cf_agents_schedules` SQLite table, single alarm armed for the next-due row.

**flyio-autostop-autostart**
URL: https://fly.io/docs/launch/autostart-stop/
Accessed: 2026-09-11
Quote: "load... means traffic the proxy can see — background work running inside the machine... doesn't count."

**flyio-scheduled-machines**
URL: https://fly.io/docs/blueprints/task-scheduling/
Accessed: 2026-09-11
Quote: "Fly Machines support basic scheduling out of the box — you can tell a Machine to start hourly, daily, weekly, or monthly... you don't get fine-grained control, just interval buckets."

**flyio-cron-manager**
URL: https://github.com/fly-apps/cron-manager
Accessed: 2026-09-11
Quote: "each job runs in its own isolated machine... configured centrally via a simple JSON configuration."

**gcp-cloud-run-jobs-scheduler**
URL: https://nicheelab.com/en/articles/gcp/cloud-run-complete-guide/
Accessed: 2026-09-11
Quote: "Jobs bill only for execution duration... scheduled with Cloud Scheduler."

**gcp-cloud-run-min-instances-tradeoff**
URL: https://cloudguard.dev/blog/cloud-run-min-instances
Accessed: 2026-09-11
Quote: "paying for 23 hours of idle time to avoid a 2-second cold start on an hourly job is not rational."

**aws-eventbridge-scheduler-quotas**
URL: https://aws.amazon.com/about-aws/whats-new/2024/08/amazon-eventbridge-scheduler-higher-quotas/
Accessed: 2026-09-11
Quote: "default service quota for number of schedules now at 10 million schedules... invocation throughput at 1000 invocations per second."

**aws-eventbridge-scheduler-pricing**
URL: https://aws.amazon.com/eventbridge/pricing/
Accessed: 2026-09-11
Quote: "14 million free invocations per month... $1.00 per million invocations" thereafter.

**azure-container-apps-jobs-schedule**
URL: https://tomodahinata.com/en/blog/azure-container-apps-jobs-batch-scheduled-event-driven-guide
Accessed: 2026-09-11
Quote: "Jobs can be triggered by Schedule (periodic with a cron expression), Event (triggered via a KEDA scaler), or Manual triggers."

**azure-container-apps-scale-zero-cron-caveat**
URL: https://tomodahinata.com/en/blog/azure-container-apps-keda-autoscaling-scale-to-zero-event-driven-guide
Accessed: 2026-09-11
Quote: "keeping the minimum replicas at one ensures the cron job can still run even with no incoming messages."

**nitro-enclaves-no-scale-to-zero**
URL: https://phala.com/learn/Phala-vs-AWS-vs-Azure-vs-GCP
Accessed: 2026-09-11
Quote: "Nitro Enclaves ... isolated execution environments ... from Amazon EC2 instances" — enclaves run atop an always-on parent instance; re-architecture required, no native scale-to-zero.

**gcp-confidential-space-single-flag**
URL: https://safeguard.sh/resources/blog/comparing-confidential-vm-offerings-across-major-cloud-providers
Accessed: 2026-09-11
Quote: "confidential VMs can typically be enabled with a single flag on existing machine types with minimal re-architecture."

## SYNTHESIS

No confidential-computing provider surveyed — Phala Cloud/dstack, AWS Nitro Enclaves, Azure Confidential Containers, GCP Confidential Space — ships a scheduled-wake primitive for its TEE/CVM compute unit. This is consistent with the broader serverless/scale-to-zero landscape: Fly.io Machines, GCP Cloud Run, and AWS Lambda/Fargate all solve "run this on a schedule against scale-to-zero compute" the same way — an external, always-available scheduler (Cloud Scheduler, EventBridge Scheduler, GitHub Actions cron, a `fly-apps/cron-manager`-style JSON-driven trigger) fires a lightweight, cheap-to-run trigger that either directly invokes a Job/Function (Cloud Run, Lambda) or hits an HTTP route that causes autostart (Fly). The scheduler itself is never the scale-to-zero unit; only the *work* scales to zero, while something durable and centrally-billed (a managed scheduler service) does the waking. Cloudflare Durable Object alarms are the one genuine exception — a true per-tenant wake primitive where the "always-on" cost is a persisted SQLite row and a guaranteed timer callback, not a warm process — but that requires buying into Cloudflare's Workers/DO runtime model wholesale, which is a different compute substrate than a TDX CVM running gVisor sandboxes.

For Vana's actual architecture, this maps directly onto option 2 from the question: a central scheduler enqueuing per-owner collection jobs, picked up by the existing warm-pool claim-loop, is not a workaround for a missing provider feature — it IS the industry-standard pattern, structurally identical to "Cloud Scheduler → Cloud Run Jobs" or "EventBridge Scheduler → Lambda/Fargate." A provider-level "wake my CVM on a cron" feature would only be architecturally superior if Vana needed one dedicated CVM per owner with strict compute isolation per wake (the Durable-Object-per-tenant shape); since Vana already multiplexes many owners' collection jobs through a shared warm pool of worker CVMs inside gVisor sandboxes, the per-tenant isolation is happening at the sandbox layer, not the CVM layer — so CVM-level scheduling would be the wrong unit of granularity even if Phala offered it. The real engineering question the question posed in part 4 (10k owners × 6h sync) is therefore not "does the provider support cron" but "does the job-enqueue-and-claim system have a cheap fan-out path for periodic bulk-enqueue" — answerable by: a single lightweight cron (GitHub Actions or equivalent) that does one bulk INSERT of due jobs into the existing queue table on a fixed interval (e.g., every 15–60 min, filtering owners whose next-sync-due timestamp has passed), letting the existing warm-pool claim-loop absorb the burst exactly as it already absorbs request-triggered work. This avoids per-tenant scheduler objects/entries entirely and keeps the cost model identical to today's Gateway cron, with the additional load being proportional to due-jobs-per-tick, not tenant count. The main failure mode to design against (seen explicicitly in the Azure Container Apps caveat) is accidentally putting the scheduling logic inside a component that itself scales to zero — the enqueuer must live in something that is always reachable (a scheduled job outside the TEE fleet, e.g. GitHub Actions or a small always-on control-plane service), never inside a CVM that could itself be asleep when its own wake time arrives.
