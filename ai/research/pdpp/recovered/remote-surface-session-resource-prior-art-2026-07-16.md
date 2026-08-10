---
title: "Remote Surface session, attachment, resource, and package boundaries"
date: 2026-07-16
topic: reference-implementation
tags: [remote-surface, browser-streaming, session, attachment, resource, packaging]
status: supports-proposed-architecture
---

# Remote Surface session and resource prior art — 2026-07-16

## Question and conclusion

Should Remote Surface treat a logical remote-control session, a connected viewer,
the viewer's transport connection, and the browser process/container as one object?
Should all Remote Surface code remain in one npm package?

**No to both as durable invariants.** Mature remote-access systems distinguish the
logical shared session from each attached participant and its transport. Browser
services also show that durable profile state and a live browser-process incarnation
have different lifetimes. These are necessary distinctions for PDPP's demonstrated
multi-client viewport contention, reconnect, retained-profile, and browser-recovery
requirements.

The evidence supports one Remote Surface repository and release train, but package
and process boundaries should follow runtime, dependency, and authority boundaries.
A browser-only viewer client and a secret-bearing Node host are justified eventual
packages. Provider packages or provisioner processes are justified only when they
carry optional heavyweight dependencies or privileged browser/container authority.

## Local evidence that makes the distinction necessary

- The current session store records a single `attached_at` timestamp but no
  attachment identity, participant set, transport generation, controller, or
  viewport owner (`src/sessions/token-session-store.ts` in the Remote Surface
  repository).
- The PDPP reference event route permits multiple concurrent event connections for
  the same token and intentionally keeps the logical session alive across a dropped
  SSE connection (`reference-implementation/server/streaming/routes.js`). Without a
  participant identity and controller lease, those connections can race input and
  viewport changes.
- The physical surface lease layer already has resource health, capacity, profile
  affinity, fencing, restart reconciliation, and retained-profile behavior. Those
  lifetimes differ from both the interaction session and the viewer connection
  (`src/leases/surface-lease-manager.ts` in the Remote Surface repository).
- The current package combines browser APIs with Node-only token code using
  `node:crypto` and declares Node 24 for the package as a whole. The browser and host
  artifacts therefore have a real runtime boundary, not merely different concerns.

## Prior-art findings

### Apache Guacamole: logical connection versus physical user connection

Guacamole's `guac_client` represents a shared logical proxy connection and tracks
the users joined to it. `guac_user` is explicitly a physical connection within that
larger logical connection, with its own ID, socket, owner flag, input handlers, and
optimal dimensions. Its handshake can create a new connection or join an existing
connection ID.

This is close to the required Remote Surface distinction:

```text
SurfaceSession     ~= guac_client
SurfaceAttachment  ~= guac_user
TransportConnection = the current socket/channel for that attachment
```

The analogy is not exact: Remote Surface also needs an explicit provider-owned
browser resource and recovery continuity. It nevertheless proves that participant
identity inside a shared logical session is established remote-access practice.

### LiveKit: room, participant, and reconnecting transport

LiveKit presents `Room` as the primary logical session and participants as joined
identities. Its client handles signaling/media recovery and distinguishes lightweight
resume from a full reconnect. A participant's network connection can therefore change
without every higher-level consumer treating that socket as the room itself.

This supports an assembled Viewer object that owns reconnect and resynchronization,
and a Host runtime that owns session membership. It does not prove that a logical
remote-browser session can survive browser-process replacement.

### Browserless: durable profile is not live browser continuity

Browserless persistent sessions preserve cookies, local storage, and cache after a
browser process ends, but a later browser starts with a blank page. Live tabs and
in-memory page state survive only while the process remains alive. This falsifies a
blanket claim that replacing a browser resource transparently resumes the same
interactive state.

Remote Surface should report one of three recovery continuity results:

- `same-resource`: the live page and in-memory state are expected to remain;
- `durable-profile-only`: cookies/storage/cache may remain, but live UI state is not
  guaranteed;
- `none`: the replacement has no proven continuity.

The logical session may remain as the audit/policy episode, but the Host must expose
the continuity result and either recover visibly or end honestly.

### noVNC: the valid simpler counterexample

noVNC exposes one `RFB` object per VNC connection and delegates desktop lifetime,
sharing, and resize semantics to the VNC server. This is the strongest case against a
public hierarchy of session/resource objects.

That simpler model wins when the upstream server already owns sharing and lifecycle,
resource death is terminal, and one viewer maps to one upstream connection. PDPP does
not meet those conditions: it has two backend families, attach tokens, multi-client
viewport contention, retained physical resources, and a recovery requirement. The
extra concepts should still remain mostly opaque behind the two primary façades,
rather than becoming seven equally prominent constructors.

### Capability negotiation is not authorization

Guacamole negotiates protocol version, media support, and client dimensions. noVNC
reports negotiated server extension capabilities. Browserless separately exposes
whether a live URL is interactable or resizable. The evidence does not support one
capability bag that mixes all of these claims.

Remote Surface should keep four facts distinct:

1. wire versions/features understood by client and host;
2. operations executable by the bound provider/resource;
3. features available in the current browser/device;
4. operations authorized for this attachment right now.

The Host derives available operations from their intersection. Failure reasons remain
distinct: `unsupported`, `forbidden`, `not-controller`, `stale`, and
`temporarily-unavailable`.

### Control authority: start with one fenced controller lease

Guacamole supports an owner and read-only sharing profiles; Browserless exposes an
`interactable` switch. The reviewed systems do not justify a generalized collaborative
grant system for Remote Surface.

The smallest model fitting current behavior is a server-authoritative
`ControllerLease` with one attachment holder and a monotonically increasing fencing
generation. It governs input and remote viewport together initially. Other
attachments observe. Transfer is explicit. Commands from an expired or superseded
lease generation fail as stale.

The noun `lease` also avoids collision with PDPP's durable authorization grants,
whose lifecycle and meaning are unrelated.

## Repository, package, and process conclusions

### One repository

Keep the broad capability set in one Remote Surface repository: pure session state,
protocol, Viewer, Host, providers, examples, and conformance. Correct changes often
span both sides and must share one compatibility matrix.

### Eventual client/host package boundary

Target two mandatory runtime artifacts before a stable 1.0 boundary if current
conditions remain:

- a browser-only Viewer/client package with no Node engine or secret-bearing code;
- a Node Host package with session runtime, attachment-token enforcement, resource
  binding, and provider contracts.

During pre-1.0 migration, one package with runtime-safe subpaths is acceptable. Split
only when package-level enforcement prevents invalid imports or avoids dependency and
runtime leakage; do not create a package for each source concern.

### Conditional provider packages and provisioner process

Keep provider contracts internal/exact-versioned until real implementations prove the
extension shape. Split a CDP or n.eko provider package when it brings browser binaries,
Patchright/Playwright, Docker clients, or a distinct deployment/security lifecycle.

Run provisioning in a separate process when it holds Docker/Kubernetes, browser
launch, persistent-profile, broad network, or filesystem authority, or when capacity
must survive and coordinate across web-process restarts. Local development may embed
the same provider behind the identical contract.

## Compatibility conclusion

Before 1.0, release client and host atomically, exact-pin them in PDPP, include a wire
version in the attach handshake, and fail fast on untested mismatches. Promise rolling
compatibility only after independently deployed versions are a demonstrated need and
every supported pair is in a deterministic compatibility matrix.

## Sources

All external sources accessed 2026-07-16.

- Apache Guacamole, [`guac_user`](https://guacamole.apache.org/doc/libguac/structguac__user.html), [`guac_client`](https://guacamole.apache.org/doc/libguac/structguac__client.html), [libguac overview](https://guacamole.apache.org/doc/gug/libguac.html), and [protocol reference](https://guacamole.apache.org/doc/gug/protocol-reference).
- LiveKit, [connecting to a room](https://docs.livekit.io/intro/basics/connect/), [JavaScript `Room`](https://docs.livekit.io/reference/client-sdk-js/classes/Room.html), and [`RoomEvent`](https://docs.livekit.io/reference/client-sdk-js/enums/RoomEvent.html).
- Browserless, [persisting state](https://docs.browserless.io/baas/session-management/persisting-state) and [LiveURL options](https://docs.browserless.io/bql-schema/operations/mutations/live-url).
- Browserbase, [keep-alive sessions](https://docs.browserbase.com/platform/browser/long-sessions/keep-alive) and [Session Live View](https://docs.browserbase.com/platform/browser/observability/session-live-view).
- noVNC, [API](https://novnc.com/noVNC/docs/API.html) and [library usage](https://novnc.com/noVNC/docs/LIBRARY.html).
- LiveKit, [browser client repository](https://github.com/livekit/client-sdk-js) and [server SDK](https://docs.livekit.io/reference/server-sdk-js/).
- Apache Guacamole, [architecture](https://guacamole.apache.org/doc/gug/guacamole-architecture.html) and [`guacd`](https://guacamole.apache.org/doc/gug/guacamole-native.html).
- n.eko, [`neko-rooms`](https://github.com/m1k1o/neko-rooms).
- Playwright, [`BrowserType.connect`](https://playwright.dev/docs/api/class-browsertype) and [browser/version management](https://playwright.dev/docs/browsers).

## Confidence

**High (0.91)** on the session/attachment/transport/resource distinction and the
Viewer/Host dependency direction. **Medium-high (0.83)** on the eventual client/host
package split because the final provider dependency graph is not settled. **Medium
(0.72)** on exact recovery continuity until real CDP and n.eko death/reconnect tests
establish what each supported provider preserves.
