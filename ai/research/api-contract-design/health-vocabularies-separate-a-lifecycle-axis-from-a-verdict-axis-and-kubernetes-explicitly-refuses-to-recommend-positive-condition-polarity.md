---
title: "Production health vocabularies separate a lifecycle axis from a verdict axis, and Kubernetes explicitly refuses to recommend positive condition polarity — the widely-repeated 'abnormal-true' rule was removed from api-conventions.md"
date: 2026-08-19
topic: api-contract-design
tags: [health-conditions, state-machines, kubernetes-conditions, status-taxonomy, naming-conventions, reason-vs-message, tri-state]
status: draft
sources: [k8s-api-conventions, k8s-pod-lifecycle, k8s-community-pr-4521, maelvls-conditions, gh-checks-runs, gh-status-checks, gh-skip-runs, aws-elb-health, consul-checks, systemd-unit-def, systemd-man, plaid-errors, prom-jobs-instances, rfc9293-tcp, rfc9110-http]
source_session: af82d1f3-1838-4307-a3a9-6bbf07e77c6f
---

## CLAIMS

### Kubernetes conditions — the structural spine

- Kubernetes' condition schema is exactly four semantic fields plus provenance: `type` (PascalCase), `status` (`True`/`False`/`Unknown`), `reason` (required, CamelCase, programmatic), `message` (human-readable, may be empty), plus `lastTransitionTime` (required) and `observedGeneration`. [k8s-api-conventions]
- `reason` is required — "Use of the `Reason` field is required." — so there is no condition without a machine-readable cause. [k8s-api-conventions]
- The documented division of labor is by RENDER SURFACE, not by audience politeness: "`Reason` is intended to be used in concise output, such as one-line `kubectl get` output, and in summarizing occurrences of causes, whereas `Message` is intended to be presented to users in detailed status explanations, such as `kubectl describe` output." [k8s-api-conventions]
- **Kubernetes explicitly declines to recommend positive polarity.** Verbatim: "Condition type names should make sense for humans; neither positive nor negative polarity can be recommended as a general rule. A negative condition like \"MemoryExhausted\" may be easier for humans to understand than \"SufficientMemory\". Conversely, \"Ready\" or \"Succeeded\" may be easier to understand than \"Failed\", because \"Failed=Unknown\" or \"Failed=False\" may cause double-negative confusion." [k8s-api-conventions]
- The doc names the polarity vocabulary precisely: "(\"Normal-true\" conditions are sometimes said to have \"positive polarity\", and \"normal-false\" conditions are said to have \"negative polarity\".)" [k8s-api-conventions]
- The often-cited "abnormal-true polarity" rule is NOT in the current api-conventions.md — a grep of the current master document for `abnormal-true` returns zero hits; the surviving text is the neutral "neither positive nor negative polarity can be recommended" paragraph. Third-party explainers still quote the removed rule. [k8s-api-conventions] [maelvls-conditions]
- The consequence of mixed polarity is stated as a hard limitation: "Without further knowledge of the conditions, it is not possible to compute a generic summary of the conditions on a resource." A generic worst-wins rollup over an arbitrary condition set is therefore not well-defined without per-condition polarity knowledge. [k8s-api-conventions]
- Conditions are additive and open-world: "Conditions should be added to explicitly convey properties that users and components care about rather than requiring those properties to be inferred from other observations. Once defined, the meaning of a Condition can not be changed arbitrarily - it becomes part of the API." [k8s-api-conventions]
- Conditions are explicitly NOT a state machine: "conditions are observations and not, themselves, state machines, nor do we define comprehensive state machines for objects... The system is level-based rather than edge-triggered, and should assume an Open World." [k8s-api-conventions]
- Absent ≡ Unknown, and Unknown means "not yet observed", not "bad": "For known conditions, the absence of a condition `status` should be interpreted the same as `Unknown`, and typically indicates that reconciliation has not yet finished (or that the resource state may not yet be observable)." [k8s-api-conventions]
- Controllers must write conditions eagerly even when they know nothing: "Controllers should apply their conditions to a resource the first time they visit the resource, even if the `status` is Unknown. This allows other components in the system to know that the condition exists and the controller is making progress." [k8s-api-conventions]
- Condition names must be observed-state adjectives or past-tense verbs, never present-tense progress verbs: "the name should be an adjective (\"Ready\", \"OutOfDisk\") or a past-tense verb (\"Succeeded\", \"Failed\") rather than a present-tense verb (\"Deploying\"). Intermediate states may be indicated by setting the `status` of the condition to `Unknown`." [k8s-api-conventions]
- In-flight transitions are modeled as `Unknown` on the outcome condition, NOT as `False`. The monotonic example is explicit: "A `True` status for `Succeeded` would imply completion... An object that was still active would generally have a `Succeeded` condition with status `Unknown`." [k8s-api-conventions]
- Long transitions (>~1 minute) may be promoted to their own condition rather than left transient: "it is reasonable to treat the transition itself as an observed state. In these cases, the Condition (such as \"Resizing\") itself should not be transient, and should instead be signalled using the `True`/`False`/`Unknown` pattern." [k8s-api-conventions]
- A designated top-level summary condition is recommended: "it's helpful to have a common top-level condition which summarizes more detailed conditions. Simple consumers may simply query the top-level condition." `Ready` (long-running) and `Succeeded` (bounded-execution) are the named-but-non-normative choices. [k8s-api-conventions]
- Short names are preferred: "Condition types should be named in PascalCase. Short condition names are preferred (e.g. \"Ready\" over \"MyResourceReady\")." [k8s-api-conventions]
- `phase` (a single lifecycle enum) is deprecated in favor of conditions, and the stated reason is enum extensibility, not that lifecycle is the wrong idea: "The pattern of using `phase` is deprecated... Phase was essentially a state-machine enumeration field, that contradicted system-design principles and hampered evolution, since adding new enum values breaks backward compatibility." [k8s-api-conventions]
- Despite the deprecation, Pod still carries BOTH a lifecycle `phase` and an additive `conditions` list on the same object. Pod phases: `Pending`, `Running`, `Succeeded`, `Failed`, `Unknown`; Pod conditions: `PodScheduled`, `PodReadyToStartContainers`, `ContainersReady`, `Initialized`, `Ready`. Pod `Unknown` phase = "For some reason the state of the Pod could not be obtained." [k8s-pod-lifecycle]
- The polarity guidance is actively contested inside SIG-Architecture: PR #4521 proposed an explicit optional `polarity`/`isProblem` field (absence = abnormal-true) precisely because a generic consumer cannot otherwise compute a summary; reviewers pushed back that "good/bad" is a vague proclamation and that consumers are mostly humans who can read the name. [k8s-community-pr-4521] [maelvls-conditions]
- Real Kubernetes ships mixed polarity in-tree: `Ready`, `Available`, `Initialized`, `ContainersReady`, `PodScheduled` are normal-true; `MemoryPressure`, `DiskPressure`, `NetworkUnavailable` are abnormal-true. [maelvls-conditions]

### Two-axis models (lifecycle × outcome)

- GitHub check runs are an explicit two-axis model. Axis 1 `status` (lifecycle): `queued`, `in_progress`, `completed`, `waiting`, `requested`, `pending`. Axis 2 `conclusion` (outcome): `success`, `failure`, `neutral`, `cancelled`, `skipped`, `timed_out`, `action_required`, `stale`, `null`. [gh-checks-runs]
- The axes are coupled by exactly one documented rule: conclusion is "Required if you provide completed_at or a status of completed." Before completion, conclusion is legitimately `null` — the absence of a verdict is representable rather than being faked as a verdict. [gh-checks-runs]
- `stale` can only be set by GitHub, not by the app: "You cannot change a check run conclusion to stale, only GitHub can set this." Staleness is a platform-owned judgment, not a reporter-owned one. [gh-checks-runs]
- GitHub treats three conclusions as passing for branch protection: "Successful check statuses are success, skipped, and neutral." `stale` is NOT in the passing set. So "didn't apply" (`skipped`) and "ran but declines to judge" (`neutral`) are both non-failures, and are distinct from each other and from `success`. [gh-status-checks]
- GitHub's own documented footgun proves lifecycle must be representable: a workflow skipped by path/branch filtering leaves "checks associated with that workflow... in a 'Pending' state" and blocks the PR forever — an unstarted lifecycle collapsed into the verdict axis reads as a failure. [gh-skip-runs]
- systemd uses a three-column model where the summary axis is explicitly defined as a generalization of the detail axis: "LOAD = Reflects whether the unit definition was properly loaded. ACTIVE = The high-level unit activation state, i.e. generalization of SUB. SUB = The low-level unit activation state, values depend on unit type." [systemd-man]
- systemd's ACTIVE enum mixes settled and in-flight states in one axis: `active`, `reloading`, `inactive`, `failed`, `activating`, `deactivating`, `maintenance`, `refreshing` (canonical `unit_active_state_table` in `src/basic/unit-def.c`). Its LOAD axis is separate: `stub`, `loaded`, `not-found`, `bad-setting`, `error`, `merged`, `masked`. [systemd-unit-def] [systemd-man]
- systemd defines its in-flight states purely as transitions between settled states — "activating: Changing from inactive to active", "deactivating: Changing from active to inactive" — and defines `failed` by reference to `inactive` plus a cause: "Similar to inactive, but the unit failed in some way." [systemd-man]
- systemd separates "in-flight" from "unmeasurable": `maintenance` = "Unit is inactive and a maintenance operation is in progress", distinct from `failed`. [systemd-man]

### Folding lifecycle into one enum (and its documented costs)

- AWS ELB folds lifecycle and applicability into a single target-health enum: `initial`, `healthy`, `unhealthy`, `unused`, `draining`, `unavailable`. [aws-elb-health]
- `initial` is "not yet measured": "The load balancer is in the process of registering the target or performing the initial health checks on the target." Its reason codes are `Elb.RegistrationInProgress` and `Elb.InitialHealthChecking`. [aws-elb-health]
- `unused` is "not applicable": "The target is not registered with a target group, the target group is not used in a listener rule, the target is in an Availability Zone that is not enabled, or the target is in the stopped or terminated state." Reason codes `Target.NotRegistered`, `Target.NotInUse`, `Target.InvalidState`, `Target.IpUnusable`. [aws-elb-health]
- `unavailable` is a third distinct non-failure: "Health checks are disabled for the target group", reason `Target.HealthCheckDisabled` — i.e. measurement was deliberately turned off, separate from both "not yet measured" and "doesn't apply". [aws-elb-health]
- `draining` is an intentional lifecycle exit, not a fault: "The target is deregistering and connection draining is in process", reason `Target.DeregistrationInProgress`. [aws-elb-health]
- ELB pairs every non-healthy state with a machine reason code AND a fixed human description, and renders the same description in the console: "If the status of a target is any value other than `Healthy`, the API returns a reason code and a description of the issue, and the console displays the same description." [aws-elb-health]
- ELB namespaces reason codes by BLAME: "Reason codes that begin with `Elb` originate on the load balancer side and reason codes that begin with `Target` originate on the target side." The prefix encodes who is at fault, and therefore who can act. [aws-elb-health]
- Consul collapses "cannot determine health" into the health enum as `warning` (`passing`/`warning`/`critical`, from script exit codes 0/1/other), and documents `warning` for OSService checks as: "A `warning` status indicates that the check is not reliable because an issue is preventing it from determining the health of the service." This is an `unknown` semantically, rendered as a degraded tier. [consul-checks]

### Measured-false vs not-measured

- Prometheus separates "measured and bad" from "never measured" structurally rather than by enum value: `up` is 1 "if the instance is healthy, i.e. reachable, or 0 if the scrape failed". `up == 0` means the target IS being scraped and the scrape failed; an ABSENT `up` series means service discovery never produced the target at all — hence the standard idiom pairs `up == 0` with `absent(up{...})`. [prom-jobs-instances]
- `up` is synthetic — generated by Prometheus for every scrape attempt, not exposed by the target — which is what makes "we tried and failed" representable at all. [prom-jobs-instances]

### Lifecycle state machines that carry no health verdict

- TCP's state machine is pure lifecycle with zero health semantics: `LISTEN`, `SYN-SENT`, `SYN-RECEIVED`, `ESTABLISHED`, `FIN-WAIT-1`, `FIN-WAIT-2`, `CLOSE-WAIT`, `CLOSING`, `LAST-ACK`, `TIME-WAIT`, `CLOSED`. `ESTABLISHED` is defined as "an open connection... The normal state for the data transfer phase." [rfc9293-tcp]
- TCP's terminal state is explicitly a modeling fiction rather than an observation: "CLOSED is fictional because it represents the state when there is no TCB, and therefore, no connection." [rfc9293-tcp]
- HTTP status classes are designed so an unrecognized specific code degrades gracefully to its class: "A client that receives a status code it does not recognize can safely assume that the overall meaning is given by the first digit." Classes: 1xx Informational (provisional, request received and understood), 2xx Successful, 3xx Redirection, 4xx Client Error, 5xx Server Error. [rfc9110-http]
- HTTP's 1xx class is a dedicated non-final/provisional band separate from the success and error bands — the wire-protocol equivalent of "still in progress, no verdict yet". [rfc9110-http]

### Machine reason → human message boundary

- Plaid's error object is a four-field split with an explicit safety contract per field: `error_type` "A broad categorization of the error. Safe for programmatic use."; `error_code` "The particular error code. Safe for programmatic use."; `error_message` "A developer-friendly representation of the error code. This may change over time and is not safe for programmatic use."; `display_message` "A user-friendly representation of the error code... This may change over time and is not safe for programmatic use." [plaid-errors]
- The enforceable boundary rule is encoded in Plaid's null semantics: `display_message` is "`null` if the error is not related to user action." A condition the user cannot act on has NO user-facing string by construction — the API makes "don't show this to the owner" representable rather than leaving it to UI discipline. [plaid-errors]
- Plaid marks the machine fields (`error_type`, `error_code`) as stable for branching and BOTH human strings as unstable ("may change over time and is not safe for programmatic use") — so code branches on codes, never on prose, in both directions. [plaid-errors]

## SOURCES

**k8s-api-conventions**
URL: https://raw.githubusercontent.com/kubernetes/community/master/contributors/devel/sig-architecture/api-conventions.md
Accessed: 2026-08-19
Note: Fetched raw master (2231 lines) and read the "Typical status properties" section (lines 352-533) verbatim. Grep for `abnormal-true` / `polarity` returned hits ONLY at lines 389-401 (the neutral paragraph); `abnormal-true` appears nowhere in the current document.
Quote: "Condition type names should make sense for humans; neither positive nor negative polarity can be recommended as a general rule. A negative condition like \"MemoryExhausted\" may be easier for humans to understand than \"SufficientMemory\". Conversely, \"Ready\" or \"Succeeded\" may be easier to understand than \"Failed\", because \"Failed=Unknown\" or \"Failed=False\" may cause double-negative confusion."
Quote: "Without further knowledge of the conditions, it is not possible to compute a generic summary of the conditions on a resource."
Quote: "conditions are observations and not, themselves, state machines... The system is level-based rather than edge-triggered, and should assume an Open World."
Quote: "the name should be an adjective (\"Ready\", \"OutOfDisk\") or a past-tense verb (\"Succeeded\", \"Failed\") rather than a present-tense verb (\"Deploying\"). Intermediate states may be indicated by setting the `status` of the condition to `Unknown`."
Quote: "An object that was still active would generally have a `Succeeded` condition with status `Unknown`."
Quote: "For known conditions, the absence of a condition `status` should be interpreted the same as `Unknown`, and typically indicates that reconciliation has not yet finished (or that the resource state may not yet be observable)."
Quote: "`Reason` is intended to be used in concise output, such as one-line `kubectl get` output... whereas `Message` is intended to be presented to users in detailed status explanations, such as `kubectl describe` output."
Quote: "Use of the `Reason` field is required."
Quote: "The pattern of using `phase` is deprecated. Newer API types should use conditions instead."

**k8s-pod-lifecycle**
URL: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
Accessed: 2026-08-19
Quote: "For some reason the state of the Pod could not be obtained. This phase typically occurs due to an error in communicating with the node where the Pod should be running."

**k8s-community-pr-4521**
URL: https://github.com/kubernetes/community/pull/4521/files
Accessed: 2026-08-19
Note: "Update Condition guidance" — proposes an explicit polarity/isProblem field. Read via search summary + SIG thread, not line-by-line; treat the specific field-name proposals as reported-not-verified.

**maelvls-conditions**
URL: https://maelvls.dev/kubernetes-conditions/
Accessed: 2026-08-19
Note: Third-party explainer. Quotes the OLDER "abnormal-true polarity" rule which is no longer present in master api-conventions.md — useful as evidence the removed rule still propagates.

**gh-checks-runs**
URL: https://docs.github.com/en/rest/checks/runs
Accessed: 2026-08-19
Quote: "Required if you provide completed_at or a status of completed."
Quote: "You cannot change a check run conclusion to stale, only GitHub can set this."

**gh-status-checks**
URL: https://docs.github.com/en/pull-requests/reference/status-checks
Accessed: 2026-08-19
Quote: "Successful check statuses are success, skipped, and neutral."
Note: Retrieved via search-result summary of the docs page, not a direct fetch of the page body.

**gh-skip-runs**
URL: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/skip-workflow-runs
Accessed: 2026-08-19
Quote: "If a workflow is skipped due to path filtering, branch filtering or a commit message, then checks associated with that workflow will remain in a 'Pending' state."

**aws-elb-health**
URL: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html
Accessed: 2026-08-19
Quote: "initial | The load balancer is in the process of registering the target or performing the initial health checks on the target."
Quote: "unused | The target is not registered with a target group, the target group is not used in a listener rule, the target is in an Availability Zone that is not enabled, or the target is in the stopped or terminated state."
Quote: "unavailable | Health checks are disabled for the target group."
Quote: "If the status of a target is any value other than `Healthy`, the API returns a reason code and a description of the issue, and the console displays the same description. Reason codes that begin with `Elb` originate on the load balancer side and reason codes that begin with `Target` originate on the target side."

**consul-checks**
URL: https://developer.hashicorp.com/consul/docs/services/usage/checks
Accessed: 2026-08-19
Quote: "A `warning` status indicates that the check is not reliable because an issue is preventing it from determining the health of the service."

**systemd-unit-def**
URL: https://raw.githubusercontent.com/systemd/systemd/main/src/basic/unit-def.c
Accessed: 2026-08-19
Note: Canonical `unit_active_state_table` and `unit_load_state_table` read directly from source.

**systemd-man**
URL: https://man7.org/linux/man-pages/man1/systemctl.1.html
Accessed: 2026-08-19
Quote: "ACTIVE = The high-level unit activation state, i.e. generalization of SUB."
Quote: "SUB = The low-level unit activation state, values depend on unit type."
Quote: "failed: Similar to inactive, but the unit failed in some way."

**plaid-errors**
URL: https://plaid.com/docs/errors/
Accessed: 2026-08-19
Quote: "display_message: A user-friendly representation of the error code. `null` if the error is not related to user action. This may change over time and is not safe for programmatic use."
Quote: "error_code: The particular error code. Safe for programmatic use."

**prom-jobs-instances**
URL: https://prometheus.io/docs/concepts/jobs_instances/
Accessed: 2026-08-19
Quote: "up{job=\"<job-name>\", instance=\"<instance-id>\"}: 1 if the instance is healthy, i.e. reachable, or 0 if the scrape failed."

**rfc9293-tcp**
URL: https://www.rfc-editor.org/rfc/rfc9293.html
Accessed: 2026-08-19
Quote: "CLOSED is fictional because it represents the state when there is no TCB, and therefore, no connection."
Quote: "ESTABLISHED - represents an open connection, data received can be delivered to the user. The normal state for the data transfer phase of the connection."

**rfc9110-http**
URL: https://www.rfc-editor.org/rfc/rfc9110.html
Accessed: 2026-08-19
Quote: "A client that receives a status code it does not recognize can safely assume that the overall meaning is given by the first digit."

## SYNTHESIS

### The headline correction

PDPP's condition model is structurally Kubernetes-derived, and that is a good ancestor. But the premise that "Kubernetes recommends positive polarity" is **false as of the current api-conventions.md**. The document deliberately refuses to pick: "neither positive nor negative polarity can be recommended as a general rule." The widely-quoted "abnormal-true" rule was removed and survives mainly in third-party explainers. PDPP's uniformly positive-polarity names are therefore *permitted and defensible* — but they are not blessed by the cited authority, and the real justification has to be made on its own terms.

That real justification is actually stronger than the one being borrowed. Kubernetes explains WHY it can't recommend a polarity: mixed polarity makes a generic rollup impossible ("it is not possible to compute a generic summary of the conditions on a resource"). PDPP has the thing Kubernetes lacks — a **closed, first-party condition set with a single owner**. Uniform positive polarity is exactly what buys PDPP a well-defined worst-wins rollup. So: keep positive polarity, but justify it as "closed set → computable summary", and write down that uniform polarity is an invariant of the set, not a style preference. The moment one negative-polarity condition is added, the rollup silently breaks.

### What PDPP actually does (verified against the code, 2026-08-19)

Before applying the prior art, three premise corrections from reading `reference-implementation/runtime/connection-health.ts` and `rendered-verdict.ts` directly:

1. **There is no "Import complete" label.** The label union (`rendered-verdict.ts:75-82`) has seven members, not eight.
2. **There is no conditions → label table.** The 13 conditions do not map to the label directly. Three stages intervene: (a) an ordered first-match-wins pipeline `HEALTH_CLASSIFICATION_STEPS` (`connection-health.ts:1226`, precedence documented `:27-43`) turns conditions into a headline `state`; (b) a worst-wins tone rollup runs over **six axes, not over the conditions** (`rendered-verdict.ts:2037-2045`), ranked `{green:0, grey:1, amber:2, red:3}`; (c) `labelForPill` (`:435-463`) maps tone → label with two badge overrides. So the conditions and the rollup are already decoupled — the pill is a projection of *axes*, and the 13 conditions are closer to a detail/evidence layer than to the rollup input.
3. **`Checking` and `Syncing` are NOT derived from the condition set.** Both are gated on `badges.syncing` (`rendered-verdict.ts:441`, `:457`), which comes from a separate boolean activity input `ConnectionActivityEvidence.active` (`connection-health.ts:1103-1106`, `:1652-1657`). A lifecycle axis therefore *already exists* — it is just a single unnamed boolean rather than a first-class field.

The `ProjectionReliable` bug is now precisely located, and it is worse than "a condition is wrong". The in-flight signal reaches the verdict by **two independent, uncoordinated routes**: (a) `activity.active` → `badges.syncing` → label `Checking`; and (b) `controller_active_runs` → the evidence engine deliberately defers the summary rollup (`connector-summary-evidence-engine.ts:89-90`, `:1326-1331`) → `record_snapshot.state !== "current"` → a `record_checkpoint_lag` source (`ref-control.ts:3879-3881`) → `ProjectionReliable: false` (severity `blocked`) → `classifyUnreliableProjection` fires **first** in precedence → state `unknown` → grey. Nothing guarantees the two agree. When (b) fires and (a) does not, an actively-running connection renders **"Not measured"**. `Checking` and `Not measured` share the same grey tone and are separated *solely* by that boolean.

Two further findings that change my naming verdict below:

- **`BacklogClear` has the same defect as `ProjectionReliable`**: `outbox === "active"` ("work is draining right now") yields `status: "false"` (`connection-health.ts:3080-3094`). It is held harmless only by severity plumbing (`isDegradingCondition` skips `BacklogClear` at `info` severity, `:1683-1685`; `isHealthyConditionSet` checks severity not status, `:1750`). So a second condition encodes *activity* as `false`.
- **`LocalExporterAvailable` is `BacklogClear`'s mirror image**: the identical `outbox === "active"` axis yields `true` there (`:2647-2655`) and `false` in `BacklogClear`. Two conditions reading one axis to opposite polarity is a naming/modeling contradiction, not just redundancy.
- **`CredentialsValid` can never be `not_applicable`** — a connector storing no credential lands on `unknown` (`:2232`), which is exactly the gap the quad-state was introduced to close (`:94-101`). Meanwhile `ProjectionReliable` and `AttentionClear` are pure binaries (never `unknown`, never `not_applicable`). The quad-state is applied inconsistently across the set: five conditions can never be `not_applicable` at all.

PDPP also already has **two** machine codes per condition — `reason` (closed vocabulary, `:123-185`) and a separate `reason_code` (`:228-237`) — but only `ProjectionReliable` ever populates the latter (`:1851`). That is a taxonomy smell in its own right: a field that exists for one condition.

### The state-model recommendation: two axes, not one

> **[CORRECTION 2026-08-19 — THE PREMISE IS LARGELY ALREADY IMPLEMENTED, AND THE ANALOGY MISFITS. Red-team verdict: do the minimal fix (step 1 below), NOT the refactor (steps 2-3).]** Two problems with this section. **(a) PDPP already separates the axes.** `connection-health.ts:22-25` states it as a shipped design decision in its own module docstring: "`syncing` (active work) and `stale` (freshness violation) are NOT headline states. They are exposed as orthogonal axes/badges so the dashboard can render activity/freshness without inventing a new pill every time we add an evidence source" — under a named decision, "Connection Health Uses Ordered Projection Plus Orthogonal Axes". `ConnectionAxes` is a typed five-field interface (`:725-732`) and `ConnectionBadges` is documented "never replace the headline pill" (`:734-740`). The recommendation below restates the existing architecture. **(b) The TanStack/GitHub analogy does not fit PDPP.** Both govern a bounded unit of work whose design turns on the moment it finishes. Only 1 of PDPP's 13 conditions (`CollectionSucceeded`) is settled by a run finishing. `Fresh` flips to stale on `Date.now()` with no run at all (`server/freshness.ts:44,59-61`). `RetryPolicyClear`/`AttentionClear` expire on the clock. `ProjectionReliable` is repaired by a background sweep. `RuntimeAvailable`/`RemoteSurfaceAvailable` are live environment probes. There is no single as-of moment to settle *to*: each condition carries its OWN `observed_at` (`:1776-1783`) and the whole read model is recomputed against the current clock per request. PDPP is a materialized view with per-row staleness, not a fetch. `verdict = null until settled` is also vacuous for import-only connectors (`google_takeout`, `twitter_archive`: `recommended_mode: manual`, no `maximum_staleness_seconds`, pinned `current` forever at `ref-control.ts:4686-4693`) which will never run again. **Cost:** 265 label literals across 31 files (RI tests, apps/console, polyfill-connectors) plus rework of the 11-invariant honesty gate whose invariant 6 recomputes and pins `pill.label`. **Keep step 1 — it is real and high-value. Drop steps 2-3.** See `product-design/consumer-products-do-show-raw-condition-lists-to-owners-...md`.

**PDPP is making a modeling error by folding `Checking` and `Syncing` into the same enum as `Healthy`/`Degraded`.** The prior art is lopsided here.

The two-axis camp (GitHub check runs, systemd LOAD/ACTIVE/SUB, HTTP's 1xx provisional band) can represent "in flight, no verdict yet" without lying. GitHub's design is the sharpest: `conclusion` is legitimately `null` until `status == completed`. Absence of a verdict is a first-class representable value. That is the single most important idea in this lane.

The one-axis camp (AWS ELB, Consul) folds lifecycle into the health enum — and both then have to spend enum slots on it (`initial`, `draining`, `unavailable`; `warning`) and pair every non-healthy value with a reason code to explain that it isn't really a failure. ELB needed *three* separate non-failure states (`initial`, `unused`, `unavailable`) to keep them from reading as `unhealthy`. That's the cost of the fold, paid in vocabulary.

The decisive evidence is GitHub's own documented footgun: when a skipped workflow's lifecycle can't be expressed, its checks sit in `Pending` and block the PR forever. An unstarted lifecycle collapsed into a verdict axis reads as a failure. That is PDPP's `ProjectionReliable: false`-while-a-run-is-in-flight bug, exactly, in a different system.

And Kubernetes prescribes the fix directly: in-flight belongs on the *status* value, not the verdict — "Intermediate states may be indicated by setting the `status` of the condition to `Unknown`", with `Succeeded` = `Unknown` for a still-active object. `ProjectionReliable: false` during an in-flight run is a straight violation: nothing is known to be wrong, so it must be `unknown`, not `false`. This is a one-line semantic fix independent of any larger refactor, and it's the highest-value change in this report.

Recommended shape:

- **Axis 1 — `lifecycle`** (where the connection is in its collection cycle): `never_run` / `checking` / `collecting` / `settled`. Derived from **one** authoritative run-state source, never from condition truth values.
- **Axis 2 — `verdict`** (the health judgment, valid only when `lifecycle == settled`, otherwise `null`): `healthy` / `needs_you` / `degraded` / `blocked` / `not_measured`.

Then `Checking` and `Syncing` leave the health enum as lifecycle values, and the pill renders the lifecycle axis while a run is in flight and the verdict axis when settled. `Needs refresh` is not a peer of `Healthy` either; it's `needs_you` + a credential-scoped required action, which PDPP's existing `RequiredAction` type already models.

Because PDPP already has a de facto lifecycle signal (`badges.syncing`) and a *second* uncoordinated one (the deferred-evidence route), the refactor is smaller than it looks and its main payoff is **collapsing two racing liveness routes into one**. Concretely, in dependency order:

1. **Make `ProjectionReliable` return `unknown`, not `false`, when the only unreliable source is the active-run deferral** (`record_checkpoint_lag`-class). This alone kills the "nothing is wrong but a condition reads failing" bug and is independent of everything else. Per Kubernetes: an in-flight outcome is `Unknown`, never `False`.
2. **Promote lifecycle to a named field** sourced from `controller_active_runs` — the same table the evidence engine already gates on — and derive `badges.syncing` from it, so the two routes cannot disagree and "Not measured" can no longer appear for a running connection.
3. **Gate the verdict axis on `lifecycle === "settled"`**, making `Checking`/`Syncing` unreachable as health values.

One caution from Kubernetes worth honoring: `phase` was deprecated because *adding enum values breaks clients*. Keep both axes small and closed, and version them deliberately. Kubernetes' Pod is the honest precedent — it kept `phase` alongside `conditions` despite the deprecation, because a lifecycle summary is genuinely useful. PDPP should do the same rather than treating "phase is deprecated" as a reason to keep folding.

### `unknown` vs `not_applicable` — the rendering rule

Three systems distinguish these and none render either as failure:

- ELB: `initial` (not yet measured) vs `unused` (doesn't apply) vs `unavailable` (measurement disabled) — three distinct states, each with its own reason code.
- GitHub: `neutral` (ran, declines to judge) vs `skipped` (didn't apply) — and critically, *both count as passing* for branch protection, alongside `success`.
- Prometheus: `up == 0` (measured, failed) vs an *absent* series (never measured) — the distinction is structural, not an enum value.

The rule for PDPP, stated so it's enforceable:

> **`not_applicable` is not a condition state — it is the absence of a condition.** A condition that doesn't apply to a source should not appear in that source's condition list at all. It must never render, never count in a denominator, and never contribute to the rollup.
>
> **`unknown` means "we have not measured this yet", and it is never a failure.** It renders in a neutral tone (grey, never amber/red), reads as "Not checked yet", and contributes to the rollup only by *withholding* a `healthy` verdict — never by producing a `degraded` one. A pill whose conditions are all `true` or `unknown` is `Checking`, never `Degraded`.

Dropping `not_applicable` from the list follows Kubernetes' additive/open-world design ("absence of a condition should be interpreted the same as `Unknown`") — with one PDPP-specific amendment. Kubernetes conflates absent with `Unknown`, which PDPP should *not* copy, because PDPP has a closed condition set and can afford the sharper distinction ELB and GitHub both pay for. Since PDPP knows its full condition set statically, absent ≡ not-applicable is unambiguous, and `unknown` stays an explicit written value (matching Kubernetes' "apply conditions on first visit even if Unknown"). Encode this in the type: make the list sparse and drop the fourth state, so a `not_applicable` pill becomes structurally unrepresentable rather than merely discouraged.

### The reason → message boundary rule

Kubernetes splits by render surface (`reason` for one-line output, `message` for detailed output). Plaid splits by *audience and actionability*, which is the stronger model and the one that fixes PDPP's "Connector code needs a fix" leak. Plaid's rule is enforceable because it's structural: `display_message` is **null when the error is not related to user action**.

PDPP already has the right primitive — `ActionAudience = "maintainer" | "none" | "owner"` (`rendered-verdict.ts:127`) — but the type permits the bug and the code commits it. Verified mechanism for the "Connector code needs a fix" leak:

- The string is a plain `cta` on a `code_fix` action with `audience: "maintainer"`, `surface: { kind: "maintainer" }`, and `satisfied_when: { kind: "none" }` (`rendered-verdict.ts:735-740`, attached `:1052-1061`).
- The grant-scoped redaction boundary strips only two fields: `GrantScopedVerdict = Omit<RenderedVerdict, "detail" | "trace">` (`:2125-2130`). **`required_actions` is not stripped.**
- `computeChannel` caps the *channel* at `advisory` for maintainer actions (`:1300-1303`) but does not suppress the text.
- `assertInvariants` actively *pins* the string rather than gating it: `if (actions.some((action) => action.kind === "code_fix" && action.cta !== "Connector code needs a fix"))` (`:1593-1594`).

So any grant-scoped client that renders `required_actions[].cta` shows a maintainer instruction to an owner who cannot act on it — with `satisfied_when: { kind: "none" }`, a dead CTA by construction. The only signal it isn't theirs is `audience`/`surface`, which a naive renderer ignores. Note this is a *safe-by-convention* design where every other layer is safe-by-construction; the invariant test pinning the exact string is the tell that the string was treated as a constant rather than as a leak.

> **[CORRECTION 2026-08-19 — THIS IS NOT A LIVE LEAK.]** The paragraph above describes a real type-level weakness but overstates it as a shipped defect reaching owners. Verified by exhaustive repo grep: **`toGrantScopedVerdict` has ZERO production callers.** The only two non-test references are the function's own definition (`rendered-verdict.ts:2127`) and a doc comment recommending it (`ref-control.ts:787`). Its own docstring explains why — "Dispatch C wires this at the wire seam" — and Dispatch C was never wired. Both production emitters of `rendered_verdict` (`ref_connector_detail` at `ref-control.ts:7172`, `owner_connection_diagnostics` at `:7404`) are owner-authenticated behind `requireToken` + `requireOwner` (`server/index.ts:6807-6840`). The MCP grant-scoped path cannot leak it: `packages/mcp-server/test/canonical-mirror.test.ts:343-356` asserts `rendered_verdict` "must not appear in MCP grant-scoped reads". The public contract has no health field at all — `reference-public.openapi.json` contains no `health`/`state`. So there is currently **no grant-scoped surface that renders `required_actions`**, and no owner sees "Connector code needs a fix" through this path. The recommended discriminated-union fix is still worth doing as pre-emptive hygiene for whenever Dispatch C is wired, but it closes a latent design gap, not an active leak — grade it accordingly. See `product-design/consumer-products-do-show-raw-condition-lists-to-owners-...md`.

The code-review-enforceable rule:

> Every condition and required action carries a machine `reason` (CamelCase, stable, branchable, always present) and an **optional** `owner_message`. `owner_message` MUST be `null` whenever `audience !== "owner"`. Owner-facing surfaces render only `owner_message`; when it is null they render the generic verdict label and nothing else. No owner surface may render `reason`, and no code may branch on any human string.

Make it structural, not a lint: replace the flat `cta: string` with a discriminated union so `{ audience: "maintainer" }` has no `cta` field at all, and add `required_actions` filtering to the `GrantScopedVerdict` boundary so maintainer actions are dropped, not merely labelled. Then the leak is a type error rather than a convention, and the invariant test at `:1593-1594` becomes unnecessary instead of load-bearing. Two supporting rules from the prior art: namespace reason codes by blame like ELB's `Elb.*` / `Target.*` prefixes (PDPP wants something like `Owner.*` / `Connector.*` / `Source.*` — the prefix then *derives* the audience rather than restating it), and treat human strings as unstable while machine codes are stable, per Plaid marking both `error_message` and `display_message` "not safe for programmatic use."

### Verdict on the 13 condition names

> **[PERSONA UPDATE 2026-08-19 — THIS SECTION IS UPGRADED, NOT REFUTED.]** The renames below were derived from Kubernetes naming conventions and from PDPP's own vocabulary, not from an assumed audience, so nothing here is void. But their PRIORITY changes: the product owner has stated PDPP is a **consumer** product (the earlier technical-operator reading, argued in the red-team companion entry, is void — see `product-design/consumer-products-do-show-raw-condition-lists-to-owners-...md`). Under a technical-operator persona, renaming `ProjectionReliable` → `DataQueryable` or `RemoteSurfaceAvailable` → `BrowserSessionAvailable` was taxonomy hygiene an operator could live without. Under a consumer requirement it is a **product** requirement: these strings are internal event-sourcing and PDPP-deployment vocabulary rendered to a consumer. The red-team's cost argument against the two-axis redesign (265 label literals across 31 files) counts occurrences of the `VerdictLabel` union and does **not** weigh against renaming conditions, which are a separate and much smaller surface. Treat the renames as the highest-value item in this section, second only to the `ProjectionReliable` `unknown` fix.
>
> The "Hide behind details (2)" disposition below is the one genuinely persona-sensitive call here, and it now points the same way for a stronger reason: `RetryPolicyClear` describes PDPP's own scheduling policy and `SourceCoverageComplete` is a maintainer diagnostic, so hiding them from a consumer's rollup is more clearly right, not less. This aligns with the surviving prior-art rule (filter to non-passing rows) rather than conflicting with it.

Judged against: PascalCase adjective-or-past-participle (Kubernetes), short names preferred, observed state not transition, no implementation nouns, and — PDPP's own addition — uniform positive polarity to keep the rollup computable.

**Keep as-is (3).** `Fresh`, `ScheduleEligible`, `RuntimeAvailable`. Adjectival, positive polarity, owner-legible or honestly infrastructural. `Fresh` is the best name in the set: one word, an adjective, no jargon. (`ScheduleEligible` earns its keep partly through a well-reasoned `not_applicable` branch at `connection-health.ts:1878-1894` — the comment there is the clearest statement of the taxonomy's intent anywhere in the codebase.)

**Keep the name, fix the semantics (2).**
- `CollectionSucceeded` — correct past-tense-verb form, matching Kubernetes' `Succeeded` precedent exactly, and it already sits at `unknown` (not `false`) while a run is in flight. This is the one condition that models in-flight correctly today; use it as the template for the others.
- `CredentialsValid` — good name, but it can never be `not_applicable`; a credential-less connector lands on `unknown` (`:2232`) and so reads as "not checked yet" forever. Give it the `not_applicable` branch the type was introduced for.

**Rename (5).**
- `ProjectionReliable` → **`DataQueryable`**. "Projection" is an internal event-sourcing noun; the owner-visible property is whether their data can be read. This is also the condition carrying the in-flight bug — do the rename and the `unknown` fix together, because the rename forces the question the current name lets you dodge: *queryable by whom, and when?* The present name lets "the read model is mid-rebuild" masquerade as "your data is untrustworthy."
- `RemoteSurfaceAvailable` → **`BrowserSessionAvailable`**. "Remote surface" is PDPP-internal vocabulary that means nothing to an owner.
- `LocalExporterAvailable` → **`ExportToolAvailable`**. Same problem, milder.
- `AttentionClear` → **`NoActionNeeded`**. `AttentionClear` is a double negative in disguise — precisely the confusion Kubernetes warns about with "Failed=False". `ActionRequired` is more natural English but flips polarity, so only take it alongside an explicit per-condition polarity flag.
- `BacklogClear` → **`BacklogDrained`**. "Clear" is vague about whether it means empty or permitted.

**Merge (3).**
- `CredentialsValid` + `CredentialContinuity` → one condition with two `reason` values (`Expired` vs `Discontinuous`). Two conditions for one owner-visible fact ("can we still log in?") is shallow abstraction; the distinction is a *cause*, which is what `reason` is for. Kubernetes' additive principle read correctly: add a condition for a property *users care about*, not for every internal discriminator.
- `BacklogClear` + `LocalExporterAvailable` → **one** condition. These two read the *same* `outbox` axis to *opposite* polarity — `active` yields `false` in one (`:3080-3094`) and `true` in the other (`:2647-2655`). That is not redundancy, it is a contradiction the rollup is currently absorbing via severity plumbing. Collapse to one `ExportQueueHealthy` condition where `active` is `true` with `reason: Draining`, and let the new lifecycle axis carry "work in progress."

**Hide behind details (2).** `RetryPolicyClear` and `SourceCoverageComplete` are maintainer diagnostics. Keep them as conditions in the API (they are real observations) but exclude them from the owner rollup and render them only in an expanded detail view. `RetryPolicyClear` in particular describes PDPP's own scheduling policy, not the source's health.

That takes 13 → 10 conditions, with 2 of those owner-hidden, leaving 8 owner-visible.

Two cross-cutting moves. First, at 13 conditions PDPP is well past the point where an owner reads them individually; Kubernetes' advice — "it's helpful to have a common top-level condition which summarizes more detailed conditions. Simple consumers may simply query the top-level condition" — argues for an explicit `Ready` summary condition the pill binds to, with the rest as drill-down. That is smaller than the two-axis refactor and can land first. Second, **collapse `reason` and `reason_code` into one field.** Two machine codes where only one condition populates the second is a field that exists for a single caller; Kubernetes ships exactly one required `reason`, and PDPP's `reason_code` content (`record_checkpoint_lag`) is just a `reason` value that never got added to the closed vocabulary.

Finally, the polarity invariant needs to be written down and tested. PDPP's uniform positive polarity is what makes its worst-wins rollup well-defined — Kubernetes says so explicitly ("Without further knowledge of the conditions, it is not possible to compute a generic summary"). Add a test asserting every condition name is normal-true, so the first negative-polarity addition fails CI rather than silently corrupting the rollup.

### Confidence

High confidence, verified against primary text: all Kubernetes claims (raw master markdown read directly, including a negative grep confirming `abnormal-true` is absent); systemd state tables (canonical C source); ELB's full state/reason tables; Plaid's field definitions; the Prometheus `up` semantics; the TCP and HTTP RFC quotes; GitHub's check-run enums and the `stale`/`completed` rules.

High confidence on the PDPP-side claims: every statement in "What PDPP actually does" and in the naming verdict is cited to file:line from a direct read of `connection-health.ts`, `rendered-verdict.ts`, `ref-control.ts`, and `connector-summary-evidence-engine.ts` on 2026-08-19. The two-route liveness race and the `BacklogClear`/`LocalExporterAvailable` polarity contradiction were traced through the caller chain, not inferred from names. Caveat: I verified the *mechanism* by reading code, not by executing it — I did not run the suite or reproduce the "Not measured while running" render at runtime, so the race is proven possible by construction but its observed frequency is unmeasured.

Medium confidence: GitHub's "success, skipped, and neutral" passing set and the skipped-run Pending behavior came via search summaries of the docs pages rather than direct fetches of the page bodies — the claim is consistent across several independent sources but the exact sentence should be re-verified before being quoted in a spec. PR #4521's specific proposed field names (`polarity`/`isProblem`) are reported, not read line-by-line.

Not verified: Consul's multi-check aggregation rule (whether it's worst-wins) — the docs page fetched did not state it, so the rollup-semantics question is answered here from Kubernetes, ELB, and GitHub only, plus the Datadog worst-wins finding already in the corpus. I did not find any primary source that prescribes *weighted* rollup; every system surveyed is either worst-wins or priority-ordered, which supports PDPP's existing worst-wins tone ranking. I also did not verify SMART attribute semantics or BGP's state machine; TCP and HTTP were sufficient for the lifecycle-vs-health point and both BGP and SMART would have been survey padding.
