---
title: "Deterministic presentation replay should derive serializable state from explicit inputs while traces remain one-way evidence"
date: 2026-07-16
topic: product-design
tags: [deterministic-replay, event-sourcing, presentation-state, testing, privacy, pixi]
status: draft
sources: [redux-actions, redux-purity, temporal-history, temporal-versioning, eventsourcingdb-snapshots, playwright-clock, playwright-tracing, playwright-video, playwright-visual, rrweb-guide, pixi-render-loop, json-schema-dialect, protobuf-evolution]
---

## CLAIMS

- Redux documents that actions are plain objects which can be logged, serialized, stored, and replayed, while reducers receive prior state and an action and return new state. [redux-actions]
- Redux's style guide says reducers must only depend on state and action, and must not perform asynchronous work, generate random values, modify external variables, or otherwise make side effects. [redux-purity]
- Temporal documents that a workflow execution history is an ordered sequence of events whose sequence alone can recover the workflow's relevant state. [temporal-history]
- Temporal documents that an execution assigned to a worker build remains on that build unless redirected, and that redirecting requires compatibility; it recommends patching or retaining compatible workers for long-running executions. [temporal-versioning]
- EventSourcingDB documents snapshots as ordinary events holding a complete state representation; applications restore the latest snapshot and replay later events, while retaining responsibility for snapshot validity. [eventsourcingdb-snapshots]
- Playwright Clock can override native time-related globals and provides fixed time, installed clock, pause, fast-forward, and manual ticking for test control. [playwright-clock]
- Playwright tracing can capture browser operations, DOM snapshots, screenshots, network activity, and optionally source files; its API documentation recommends Playwright Test configuration when assertions must be in the diagnostic trace. [playwright-tracing]
- Playwright records test video under configurable modes and writes a video when the browser context closes. [playwright-video]
- Playwright says screenshot baselines can differ by host OS, browser/version/settings, hardware, power source, and headless mode. [playwright-visual]
- rrweb records a full DOM snapshot plus incremental DOM mutations replayed by timestamp; its recorder supports block/mask options and an optional canvas-recording mode. [rrweb-guide]
- Pixi's render loop is driven by requestAnimationFrame, measures elapsed time since the preceding frame, may cap it according to ticker FPS configuration, then runs ticker listeners before rendering. [pixi-render-loop]
- JSON Schema uses a root-level $schema declaration to identify the dialect under which a schema is evaluated. [json-schema-dialect]
- Protocol Buffers documentation warns that JSON/text interchange has weaker schema-evolution guarantees than binary protobuf and that JSON field/enum names can make renames or removals breaking. [protobuf-evolution]

## SOURCES

**redux-actions**
URL: https://redux.js.org/understanding/thinking-in-redux/three-principles
Accessed: 2026-07-16

**redux-purity**
URL: https://redux.js.org/style-guide/
Accessed: 2026-07-16

**temporal-history**
URL: https://github.com/temporalio/temporal/blob/main/docs/architecture/history-service.md
Accessed: 2026-07-16

**temporal-versioning**
URL: https://github.com/temporalio/temporal/blob/main/docs/worker-versioning.md
Accessed: 2026-07-16

**eventsourcingdb-snapshots**
URL: https://docs.eventsourcingdb.io/best-practices/snapshots-and-performance/
Accessed: 2026-07-16

**playwright-clock**
URL: https://playwright.dev/docs/clock
Accessed: 2026-07-16

**playwright-tracing**
URL: https://playwright.dev/docs/api/class-tracing
Accessed: 2026-07-16

**playwright-video**
URL: https://playwright.dev/docs/videos
Accessed: 2026-07-16

**playwright-visual**
URL: https://playwright.dev/docs/test-snapshots
Accessed: 2026-07-16

**rrweb-guide**
URL: https://github.com/rrweb-io/rrweb/blob/main/guide.md
Accessed: 2026-07-16

**pixi-render-loop**
URL: https://pixijs.com/8.x/guides/concepts/render-loop
Accessed: 2026-07-16

**json-schema-dialect**
URL: https://json-schema.org/understanding-json-schema/reference/schema
Accessed: 2026-07-16

**protobuf-evolution**
URL: https://protobuf.dev/best-practices/dos-donts/
Accessed: 2026-07-16

## SYNTHESIS

For a personal-data presentation player, use the event-sourcing transfer narrowly:
immutable program/tape plus explicit external actions reduce through a pure
fixed-tick core into one canonical serializable PresentationState. A checkpoint
is a hash-verified cache of that state, never a competing history. A trace is a
redacted, one-way observation of state transitions and effect intents; it is
never read to restore the player.

This reconciles the current product-design entry on immutable cue navigation with
a deterministic implementation: pause/resume, previous/next cue, source-open,
and mute are explicit actions at a logical tick. The renderer, Web Audio,
React, storage, and telemetry are adapters receiving derived state or effect
intents. They cannot feed timing, audio observations, DOM state, viewport, or
randomness back into the core.

Build this application-owned core and bundle format rather than adopting a
workflow service, Redux store, event database, or rrweb. Temporal transfers
replay/versioning discipline but solves a different distributed-workflow
problem. Redux transfers reducer purity but a store would add a second UI state
system. rrweb can at most become a separately consented, sanitized support
capture: it records DOM/canvas mutations, not Pixi semantic state or Web Audio,
and its privacy masking does not make personal conversation recording safe by
default. Pixi remains the renderer, but requestAnimationFrame deltas must not be
the replay clock.

A semantic replay claim requires matching program/core versions, input log, and
state digests at named ticks. A pixel replay claim additionally needs a pinned
browser, app/Pixi build, viewport/DPR, font and asset hashes; it cannot promise
identical pixels across arbitrary machines. Audio is likewise intent-equivalent,
not sample-exact across browser/device output paths. Playwright Clock belongs in
test control, while trace/video/screenshot belong to failure diagnosis; their
DOM/network capture makes them sample-fixture-only unless a stronger redaction
policy is proven.

Version the bundle explicitly, preserve originals during migration, test pure
upcasters against fixtures, and retain/pin an old compatible presentation core
when a new reducer would change historical behavior. Start with a pure core,
state-digest tests, and cue-boundary checkpoints; defer encrypted portable
bundles, periodic snapshots, trace UI, and any capture technology until a
measured product need appears.
