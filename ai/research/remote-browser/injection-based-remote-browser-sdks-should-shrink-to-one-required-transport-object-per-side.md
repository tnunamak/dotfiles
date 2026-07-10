---
title: "Injection-based remote-browser SDKs like remote-surface should shrink their required config to one small transport/client object per side (client: a wire; server: a CdpCommandTransport), collapse the two confusingly-named CDP adapters into one client-facing entry point, and ship a ~150-line both-sides CDP quickstart instead of pointing at the 2,900-line playground"
date: 2026-07-10
topic: remote-browser
tags: [sdk-design, config-surface, injection, cdp, neko, quickstart, dx, prior-art]
status: draft
sources: [stripe-node, supabase-js, openapi-fetch-middleware, playwright-cdp, temporal-ts-activities, trpc-client, chrome-remote-interface, neko-faq, neko-quickstart, neko-v3-roadmap, remote-surface-readme, remote-surface-cookbook, remote-surface-cdp-adapter, remote-surface-cdp-backend, remote-surface-vanilla-example, remote-surface-playground-readme]
---

## CLAIMS

**Q1 — how SLVP-grade injection-based SDKs shape host-provided config**

- Stripe's `stripe-node` requires exactly one positional argument to construct (`new Stripe('sk_test_...')`); every other concern (network host/port/protocol, retries, timeout, telemetry, `appInfo`, proxy agent) is one optional second-argument options object with documented defaults (`apiVersion: null`, `maxNetworkRetries: 1`, `timeout: 80000`, `host: 'api.stripe.com'`, `telemetry: true`). [stripe-node]
- Supabase's `createClient(supabaseUrl, supabaseKey, options?)` takes exactly two required positional strings; all further behavior (`db.schema`, `auth.autoRefreshToken`/`persistSession`/`detectSessionInUrl`, `realtime`, `storage`, `global.fetch` for custom fetch injection, `global.headers`) lives in one optional third options object. [supabase-js]
- Playwright's `chromium.connectOverCDP(endpointURL, options?)` takes exactly one required argument (a CDP websocket or http URL); `headers`, `slowMo`, `timeout`, `artifactsDir`, `isLocal`, `noDefaults` are all optional. [playwright-cdp]
- `openapi-fetch`'s `createClient({ baseUrl, fetch? })` accepts an injectable `fetch` (defaulting to `globalThis.fetch`) and layers authentication via a separate composable `client.use({ onRequest })` middleware call — auth is not a constructor parameter, it is injected after construction via a function that mutates the outgoing request. [openapi-fetch-middleware]
- tRPC's `createTRPCClient<AppRouter>({ links: [httpBatchLink({ url })] })` takes one config object whose only required field is a `links` array containing one terminating link (`httpBatchLink`/`httpLink`/`wsLink`); the terminating link, not the client constructor, owns transport-specific options (URL, batching limits, headers). `createTRPCProxyClient` is a legacy name now re-exported as an alias of `createTRPCClient` — the SDK collapsed two names for the same concept into one. [trpc-client]
- Temporal's TypeScript SDK activity-injection pattern is a plain factory function (`createActivities(db)`) that closes over injected dependencies and returns the activities object; this is passed directly as the `activities` field alongside `taskQueue`/`workflowsPath` when constructing the `Worker` — dependency injection is delegated to an ordinary closure, not a bespoke DI framework, keeping the `Worker`'s own config surface to task queue + workflow path + activities. [temporal-ts-activities]
- chrome-remote-interface's entire "Sample API usage" README snippet — connect, subscribe to a domain event, enable two domains, navigate, wait for load, close — is 26 lines including error handling and the wrapping async function; `CDP()`/`CDP.New()` default `host`/`port`/`target` are all optional (defaults `localhost`/`9222`/first available). [chrome-remote-interface]

**Q1 — remote-surface's current config surface (read directly from source)**

- `CdpSurfaceAdapterDeps` (client-side, `src/adapters/cdp-surface-adapter.ts`) requires `client: CdpSurfaceClientApi` and `config: CdpSurfaceConfig`, with `logger?`/`screencast?` optional; `CdpSurfaceClientApi` is itself a union of two shapes (`DirectCdpSurfaceClientApi` — `cdp`, `getViewportInfo`, `mediaSink`, plus 5 more optional methods — or `LegacyCdpSurfaceClientApi` — `sendInput`, `getViewportInfo`, plus 4 more optional methods), selected at runtime via a duck-typing check (`isDirectCdpClient`/`isLegacyCdpClient`) rather than a single documented shape. [remote-surface-cdp-adapter]
- `CdpRemoteSurfaceBackendAdapterOptions` (server-side, `src/backends/cdp/backend.ts`) requires `transport: CdpCommandTransport` (`{ send(method, params); on(eventName, handler) }`) and `targetId: string`, with `clock?`/`descriptor?`/`screencast?` optional — this is already a tight, Playwright-style required-vs-optional split on the server side. [remote-surface-cdp-backend]
- The repo's own COOKBOOK.md documents, as unresolved "DX friction," that `CdpSurfaceAdapter` (client-side, DOM-attached) and `CdpRemoteSurfaceBackendAdapter` (server-side, lifecycle-based) "look like the same concept from their names but are two different integration points," that nothing in the public docs explains when to reach for which, and that `backend.start()` returns a `CdpBackendLifecycle` object that — not `backend` itself — is what every subsequent `input`/`setViewport`/`clipboard`/`onEvent` call goes through, which the README's own quick-start snippet does not make clear. [remote-surface-cookbook]
- The same COOKBOOK section documents that `surface.setViewport()` (client) and `lifecycle.setViewport()` (backend) take incompatible shapes for "the same" concept (bare `{width,height,...}` vs. wire `{type:"viewport",width,height,...}`), and that the lower-level functions the CDP adapter is built from (`dispatchCdpPointerInput`, `dispatchCdpKeyboardInput`, `insertCdpText`, `applyCdpViewport`) are exported but not mentioned in the README, discoverable only by reading `backend.ts` source. [remote-surface-cookbook]
- The published README's "Quick start" section shows client-side `createContainerFitStreamViewerSurface`/`createViewportMatchController` (client package) and, separately, server-side `createCdpRemoteSurfaceBackendAdapter` + `backend.start(...)` (backend package) as two independent snippets with no wire connecting them — neither snippet shows the other side, and no single runnable example exists showing both halves feeding one live session. [remote-surface-readme]

**Q2 — genuinely-minimal both-sides CDP quickstart sizing**

- The maintained `examples/vanilla-viewer/src/viewer.ts` in the repo is a 136-line, typechecked-in-CI, client-only example; its own header comment states it "intentionally does NOT open a CDP connection itself" and depends on a small host-implemented `RemoteSurfaceWire` interface (4 methods: `applyViewport`, `sendPointer`, `onFrame`, `onRemoteCursor`) — i.e. the repo already has a real, minimal, honest CLIENT half at ~136 lines, but no server-side counterpart implementing `RemoteSurfaceWire` over the actual CDP backend adapter. [remote-surface-vanilla-example]
- The repo's actual runnable both-sides reference is the `playground/`: `playground/server/cdp-surface.ts` (803 lines) + `playground/server/index.ts` (539 lines) + `playground/server/probe-page.ts` (252 lines) + `playground/client/main.js` (1,041 lines) = 2,948 lines total across server+client, explicitly documented as "an acceptance harness for remote-surface UX work, not part of the published package" with per-character input telemetry, pointer-accuracy telemetry, dual package/legacy driver comparison, and an Android acceptance checklist. [remote-surface-playground-readme]
- chrome-remote-interface's own minimal connect-and-drive-CDP snippet (README "Sample API usage") is 26 lines; extending that pattern with `Page.startScreencast`/`Page.screencastFrame` (per the serverless-chrome recipe found in the wiki ecosystem) adds a handler that acks each frame and forwards `data`/`sessionId` — a small, bounded addition, not a new architecture. [chrome-remote-interface]
- COOKBOOK's own recipe (d), "Server-side / injected-transport path," is a complete (if abbreviated for prose) working example: launch Patchright/Playwright, get a `CDPSession`, wrap it in a `{send, on}` transport, construct `createCdpRemoteSurfaceBackendAdapter`, call `backend.start(viewport)`, forward `lifecycle.onEvent` frames over a WebSocket, forward client input via `lifecycle.input(...)` — roughly 40 lines of prose-code as written, before WebSocket wiring. [remote-surface-cookbook]

**Q3 — neko minimal path**

- n.eko v3's fastest documented path is `wget` the official `docker-compose.yaml` + `docker compose up -d`, with one required environment override for LAN use (`NEKO_NAT1TO1: <local-ip>`); the documented minimal `docker-compose.yml` for production is 12 lines (image, restart, 2 port mappings, 4 environment variables: `NEKO_WEBRTC_EPR`, `NEKO_WEBRTC_NAT1TO1`, `NEKO_MEMBER_MULTIUSER_USER_PASSWORD`, `NEKO_MEMBER_MULTIUSER_ADMIN_PASSWORD`). [neko-quickstart]
- n.eko's documented minimal *embedding* path (distinct from server setup) is a URL-parameter contract on the already-running server: `http://<host>:8080/?usr=<user>&pwd=<pass>` embeds without a login prompt, `?embed=1` hides the sidebar/topbar chrome, `?volume=<0-1>` sets initial volume, and the iframe itself needs `allow="fullscreen *"` (or the vendor-prefixed equivalents) for fullscreen to work across an origin boundary — this is a same-origin/query-string embed, not an SDK call. [neko-faq]
- n.eko v3's own roadmap states the client is being deliberately redesigned "to be as easy to integrate as embedding a video player," split into a Vue-free TypeScript library component explicitly aimed at being loaded by any host application (contrasted with the v2 client, which was UI-focused, not embed-focused) — i.e. upstream neko itself has identified "trivial host embedding" as an explicit, not-yet-fully-shipped v3 goal, the same gap remote-surface's n.eko backend sits in front of. [neko-v3-roadmap]

## SOURCES

**stripe-node**
URL: https://raw.githubusercontent.com/stripe/stripe-node/master/README.md
Accessed: 2026-07-10
Quote: "const stripeClient = new Stripe('sk_test_...');" / "maxNetworkRetries: 1, ... timeout: 1000, host: 'api.example.com', port: 123, telemetry: true"

**supabase-js**
URL: https://supabase.com/docs/reference/javascript/initializing
Accessed: 2026-07-10
Quote: "const supabase = createClient('https://xyzcompany.supabase.co', 'your-publishable-key')"

**openapi-fetch-middleware**
URL: https://openapi-ts.dev/openapi-fetch/middleware-auth
Accessed: 2026-07-10
Quote: "const client = createClient<paths>({ baseUrl: \"https://myapi.dev/v1/\" }); client.use(authMiddleware);"

**playwright-cdp**
URL: https://playwright.dev/docs/api/class-browsertype#browser-type-connect-over-cdp
Accessed: 2026-07-10
Quote: "const browser = await playwright.chromium.connectOverCDP('http://localhost:9222/');"

**temporal-ts-activities**
URL: https://docs.temporal.io/develop/typescript/activities/basics
Accessed: 2026-07-10
Quote: "createActivities is a function that takes a db parameter and returns an object with activity functions"

**trpc-client**
URL: https://trpc.io/docs/client/links/httpBatchLink ; https://trpc.io/docs/client/vanilla/setup ; https://trpc.io/docs/typedoc/client/index/
Accessed: 2026-07-10
Quote: "const client = createTRPCClient<AppRouter>({ links: [ httpBatchLink({ url: 'http://localhost:3000' }) ] });"

**chrome-remote-interface**
URL: https://github.com/cyrus-and/chrome-remote-interface (README "Sample API usage" + connection defaults)
Accessed: 2026-07-10
Quote: "client = await CDP(); const {Network, Page} = client; ... await Page.navigate({url: 'https://github.com'}); await Page.loadEventFired();"

**neko-faq**
URL: https://neko.m1k1o.net/docs/v3/faq
Accessed: 2026-07-10
Quote: "http://<your-neko-server-ip>:8080/?usr=neko&pwd=neko" / "allow=\"fullscreen *\""

**neko-quickstart**
URL: https://neko.m1k1o.net/docs/v3/quick-start ; https://neko.m1k1o.net/docs/v3/installation
Accessed: 2026-07-10
Quote: "wget https://raw.githubusercontent.com/m1k1o/neko/master/docker-compose.yaml && sudo docker compose up -d" / "NEKO_WEBRTC_EPR: \"56000-56100\" NEKO_WEBRTC_NAT1TO1: \"127.0.0.1\" NEKO_MEMBER_MULTIUSER_USER_PASSWORD: \"neko\" NEKO_MEMBER_MULTIUSER_ADMIN_PASSWORD: \"admin\""

**neko-v3-roadmap**
URL: https://neko.m1k1o.net/docs/v3/roadmap
Accessed: 2026-07-10
Quote: "the client is being split into a library TypeScript component that doesn't use Vue.js ... aiming to be as easy to integrate as embedding a video player"

**remote-surface-readme**
URL: local checkout ~/.tmp/remote-surface-repo/README.md (github.com/vana-com/remote-surface)
Accessed: 2026-07-10

**remote-surface-cookbook**
URL: local checkout ~/.tmp/remote-surface-repo/docs/COOKBOOK.md, section "DX friction found"
Accessed: 2026-07-10
Quote: "CdpSurfaceAdapter (the DOM-attached class in /adapters) and CdpRemoteSurfaceBackendAdapter (the lifecycle-based one in /backends/cdp) look like the same concept from their names but are two different integration points"

**remote-surface-cdp-adapter**
URL: local checkout ~/.tmp/remote-surface-repo/src/adapters/cdp-surface-adapter.ts
Accessed: 2026-07-10

**remote-surface-cdp-backend**
URL: local checkout ~/.tmp/remote-surface-repo/src/backends/cdp/backend.ts
Accessed: 2026-07-10

**remote-surface-vanilla-example**
URL: local checkout ~/.tmp/remote-surface-repo/examples/vanilla-viewer/src/viewer.ts
Accessed: 2026-07-10
Quote: "This is the smallest wiring that is still representative of a real integration ... It intentionally does NOT open a CDP connection itself"

**remote-surface-playground-readme**
URL: local checkout ~/.tmp/remote-surface-repo/playground/README.md
Accessed: 2026-07-10
Quote: "This playground launches a local Chromium instance ... It is an acceptance harness for remote-surface UX work, not part of the published @opendatalabs/remote-surface package."

## SYNTHESIS

### (a) Proposed SLVP-ideal config surface for remote-surface

The cross-SDK pattern is unanimous and mechanical: **one required positional/object argument that is the transport, everything else optional with defaults.** Stripe needs an API key; Supabase needs a URL+key; Playwright needs an endpoint URL; openapi-fetch needs nothing (fetch defaults to global) and layers auth as a *second, separate, optional* call, not a constructor field; tRPC needs a `links` array with one terminating link; Temporal needs a plain closure. None of them make the host choose between two differently-named entry points for "the same" side of the same concern — the two-name problem tRPC once had (`createTRPCProxyClient` vs `createTRPCClient`) was resolved by aliasing the old name to the new one, not by keeping both as equally-valid unrelated APIs.

remote-surface's server side (`CdpRemoteSurfaceBackendAdapterOptions = { transport, targetId, clock?, descriptor?, screencast? }`) already matches this shape almost exactly — `CdpCommandTransport = { send(method, params); on(eventName, handler) }` is a two-method interface as small as Playwright's `endpointURL` string, and everything else is optional. This is the part to keep as-is and hold up as the model for the client side.

The client side is where the surface diverges from the pattern in three concrete ways, each traceable to a specific type in `src/adapters/cdp-surface-adapter.ts`:

1. **Two adapters, one name-collision.** `CdpSurfaceAdapter` (client, DOM-attached) and `CdpRemoteSurfaceBackendAdapter` (server, lifecycle-based) read as the same concept and aren't — this is the repo's own COOKBOOK admission, independently confirmed by reading both files. The tRPC precedent (alias the legacy name, promote one canonical name) doesn't map cleanly because these are genuinely two different concepts (client DOM driver vs. server CDP driver), so the fix isn't aliasing — it's renaming for *positional* clarity the way Stripe's `FetchHttpClient`/`NodeHttpClient` or Playwright's `chromium`/`firefox`/`webkit` namespaces do: prefix by side, not by "which one came first." Concretely: `CdpSurfaceAdapter` → `CdpClientSurface` (or keep `CdpSurfaceAdapter` but rename `CdpRemoteSurfaceBackendAdapter` → `CdpServerBackend`), so the two names differ in the first distinguishing word (`Client`/`Server`) rather than sharing a stem and differing in a suffix a skimming reader won't parse (`SurfaceAdapter` vs `RemoteSurfaceBackendAdapter`).

2. **A required-config union instead of one required shape.** `CdpSurfaceClientApi = DirectCdpSurfaceClientApi | LegacyCdpSurfaceClientApi`, selected by runtime duck-typing (`"cdp" in client && "mediaSink" in client`). No SDK in the cited cohort makes the *required* config surface a discriminated union the host must reverse-engineer from field presence — Stripe/Supabase/Playwright/tRPC all have exactly one required shape, with variation pushed into optional fields or separate factory functions (Stripe's `NodeHttpClient` vs `FetchHttpClient` are two *injectable implementations of one interface*, not two shapes the constructor accepts and disambiguates itself). The `Legacy` path should either become a named legacy constructor (`createLegacyCdpSurfaceAdapter(deps)`) so the type-level ambiguity disappears from the primary `CdpSurfaceAdapterDeps`, or be deleted if truly legacy — a union that both call sites and the adapter itself must branch on for nearly every method (`isDirectCdpClient`/`isLegacyCdpClient` guards appear ~15 times in `cdp-surface-adapter.ts`) is exactly the "two adapters" smell one level down.

3. **No single wire object connects both README snippets.** The README's client snippet and server snippet are independently correct but never shown talking to each other — there is no `RemoteSurfaceWire`-shaped object in the README itself (that only exists in the example, which the README doesn't point to). Supabase/Stripe/Playwright don't have this problem because they are single-process SDKs; remote-surface is inherently two-process, so its "one obvious entry point per side" is not one function but **one obvious required interface per side plus one runnable example wiring them**, which the repo has *already built* (`examples/vanilla-viewer` + COOKBOOK recipe (d)) but the README doesn't surface as *the* onboarding path — it shows two disconnected inline snippets instead of linking to the one place both halves are proven to work together.

Proposed shape (minimal, both sides, matching the cohort's "one required arg, rest optional" law):

```ts
// CLIENT — one required interface, not a union.
// (rename to disambiguate from the server-side adapter; keep the transport tiny)
createCdpClientSurface(container: HTMLElement, wire: RemoteSurfaceWire, viewport): CdpClientSurfaceHandle
// where RemoteSurfaceWire is exactly examples/vanilla-viewer's 4-method interface:
// { applyViewport, sendPointer, onFrame, onRemoteCursor }
// — already correct, just needs to be the DOCUMENTED primary client entry point
// instead of a side example.

// SERVER — already correct; just needs to be shown wired to the client above.
createCdpRemoteSurfaceBackendAdapter({ transport, targetId }) // -> backend
await backend.start(viewport) // -> lifecycle: { input, setViewport, clipboard, onEvent }
```

The legacy client path becomes an explicit opt-in constructor, not a union member of the default one; screencast tuning, clock, descriptor stay optional exactly as they are today.

### (b) Minimal-quickstart shape + line estimate

The repo already contains 80% of a genuinely minimal both-sides quickstart in two places that are currently disconnected from each other and from the README:

- **Client half — already minimal, already correct.** `examples/vanilla-viewer/src/viewer.ts` is 136 lines, CI-typechecked, and honestly scoped (it explicitly does not open CDP itself). This should become the README's canonical client snippet, or the README's snippet should shrink to match it.
- **Server half — needs to be written; COOKBOOK recipe (d) is the spec.** COOKBOOK's recipe (d) is the correct shape (Patchright/Playwright → `CDPSession` → `{send,on}` transport → `createCdpRemoteSurfaceBackendAdapter` → `backend.start()` → forward `lifecycle.onEvent` frames + `lifecycle.input()` calls over a WebSocket implementing `RemoteSurfaceWire`) but is currently prose-interleaved code, not a standalone file. Written as a standalone file matching chrome-remote-interface's 26-line core-loop density plus the WebSocket relay glue, this is realistically **~90-130 lines**: ~15 lines browser launch + CDPSession, ~15 lines transport wrapping, ~10 lines `backend.start()` + viewport, ~20-30 lines WebSocket server accept + `RemoteSurfaceWire`-shaped message router (frame-out, pointer-in, viewport-in), ~10-20 lines error/cleanup. This is far closer to chrome-remote-interface's 26-line core than to the playground's 803-line `cdp-surface.ts` — the playground is 20-30x larger because it also implements dual driver comparison (package vs. legacy), per-character telemetry, pointer-accuracy telemetry, and an Android acceptance harness, none of which belong in a "fill a div with a URL" quickstart.
- **Target total: one client file (~136 lines, already exists) + one server file (~100-130 lines, needs writing) ≈ 250-270 lines both-sides, split across exactly two files**, each independently runnable and each pointing at the other only via the shared `RemoteSurfaceWire` message shape — not the 2,948-line playground, and not two disconnected README snippets that never show a live session.

### (c) neko-doc approach

neko's own docs already draw the two-tier line remote-surface's docs should mirror: (1) a genuinely tiny **server quickstart** (12-line docker-compose.yml, 4 env vars, one command) that stands alone and produces a working neko instance reachable in a normal browser tab, then separately (2) a genuinely tiny **embed recipe** (URL query params + one iframe `allow` attribute) layered on top of an already-running server, explicitly distinct from server setup. remote-surface's n.eko backend docs should present the same two-step split rather than one combined "set up n.eko for remote-surface" page: step 1 = link straight to neko's own quick-start (don't re-document docker-compose, it's not remote-surface's concern and would drift), step 2 = a remote-surface-specific recipe showing only what the *host* adds on top (the `NekoSafeClientDescriptor`/proxy path construction in `src/backends/neko/index.ts`, and how that descriptor maps onto neko's `?usr=&pwd=&embed=1` URL contract). Note upstream neko's own v3 roadmap already states an explicit goal of a Vue-free, host-embeddable TypeScript client component "as easy to integrate as embedding a video player" — remote-surface's n.eko backend is filling a gap upstream neko has acknowledged but not yet fully shipped, which is worth stating plainly in the docs rather than presenting the current integration as more finished than it is.

### Top-line changes, ranked

1. **Rename to kill the two-adapter name collision** — `CdpSurfaceAdapter` (client) vs. `CdpRemoteSurfaceBackendAdapter` (server) differ only in a shared-stem suffix; rename so the distinguishing word (client/server) is first, matching how every cited SDK disambiguates same-concept-different-side constructs.
2. **Collapse `CdpSurfaceClientApi`'s required-config union into one required shape** — `Direct` vs. `Legacy` selected by runtime duck-typing on field presence is a smell no cohort SDK exhibits at the constructor boundary; make the legacy path an explicit, separately-named opt-in constructor instead of a union member of the default required type.
3. **Promote `examples/vanilla-viewer` + COOKBOOK recipe (d) into one documented, connected, both-sides quickstart in the README** (~136-line client, already exists; ~100-130-line server, needs writing) — replacing the current two disconnected inline snippets and never pointing a first-time reader at the 2,948-line playground as "the" example.
