---
title: "Vana serverless services use best-effort Datadog HTTP gauges and Slack for synthetic failures"
date: 2026-08-11
topic: observability
tags: [datadog, slack, vercel, serverless, metrics, monitoring]
status: settled
sources: [data-gateway-metrics, data-gateway-metrics-cron, context-gateway-canary, vana-stats-datadog, datadog-cost]
source_session: 2026-07-29T11-27-57-019faeb4-43df-75e1-9607-294f65e61bdf
---

## CLAIMS

- Data Gateway's Vercel runtime emits best-effort gauges directly to Datadog's HTTP intake with a bounded timeout and no dependency on a sidecar agent. Missing Datadog configuration is a no-op, and telemetry failure does not fail the business operation. [data-gateway-metrics]
- Data Gateway collects operational wallet-balance gauges in an authenticated scheduled route, always logs the values, and submits the gauges to Datadog when configured. [data-gateway-metrics-cron]
- Context Gateway's connector canary sends high-signal synthetic failures directly to Slack with links to telemetry and the CI run. [context-gateway-canary]
- Vana Stats has a reusable Datadog client that batches tagged metrics and retries failed submissions. [vana-stats-datadog]
- Vana already has a paid Datadog Pro commitment; metrics and synthetics are established infrastructure, while several other Datadog products have near-zero use. [datadog-cost]

## SOURCES

**data-gateway-metrics**
URL: https://github.com/vana-com/data-gateway/blob/84aa98322728e3f2d19d007f08ca05af67ca4f4c/lib/metrics.ts
Accessed: 2026-08-11

**data-gateway-metrics-cron**
URL: https://github.com/vana-com/data-gateway/blob/84aa98322728e3f2d19d007f08ca05af67ca4f4c/api/v1/cron/metrics.ts
Accessed: 2026-08-11

**context-gateway-canary**
URL: https://github.com/vana-com/context-gateway/blob/c55a130be38270a3659483aa516f1849fbe84f9e/.github/workflows/connector-canary.yml
Accessed: 2026-08-11

**vana-stats-datadog**
URL: https://github.com/vana-com/vana-stats-server/blob/1225fc675fa0afddb81c8dc7917b4f3c917eab0b/app/services/datadog.ts
Accessed: 2026-08-11

**datadog-cost**
URL: https://github.com/vana-com/knowledge/blob/364a9e9a1e5b5053612fea27ad2b9c96b50c9f97/maciej/25-02-2026-eng-infra-costs/04-datadog.md
Accessed: 2026-08-11

## SYNTHESIS

- Context Gateway should copy Data Gateway's bounded, best-effort HTTP gauge emitter for durable service-health signals rather than add a new queue or agent.
- Datadog monitors should evaluate durable state such as last successful control pass, oldest due webhook, uncertain transaction count, and funding-float balance. Slack is the appropriate first notification destination; direct Slack remains suitable for synthetic canary failures.
- No concrete production PagerDuty integration was found in the vana-com code search on 2026-08-11, so it is not a precedent to copy without further live-operations evidence.
- A Datadog API/MCP connection is not needed to choose this architecture. It is useful later to inspect existing notification routing and provision or verify live monitors.
