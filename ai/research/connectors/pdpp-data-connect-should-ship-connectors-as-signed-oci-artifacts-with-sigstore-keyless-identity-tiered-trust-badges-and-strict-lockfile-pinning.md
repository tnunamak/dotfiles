---
title: "PDPP Data Connect should ship connectors as signed OCI artifacts using Sigstore keyless identity tied to repo-level OIDC, a TUF-lite signed index for official + unverified-by-default custom repos, strict lockfile pinning with no silent auto-update, and permission-diff re-consent gates modeled on OAuth incremental authorization and Chrome's permission-escalation disable-until-approved behavior"
date: 2026-08-14
topic: connectors
tags: [supply-chain-security, pdpp, data-connect, connector-distribution, sigstore, tuf-lite, trust-tiers, lockfiles, revocation, capability-manifest]
status: draft
sources: [companion-survey]
source_session: 90eda2e1-11b6-4c94-8c04-49c89508b2e4
---

## CLAIMS

This file is the PDPP-specific synthesis and recommendation. All underlying factual
claims (TUF, Sigstore, VS Code/Firefox/Obsidian/Raycast, HACS/ComfyUI, Terraform
Registry tiers, cosign/OCI, lockfiles, revocation, permission re-consent precedent)
are cited with sources in the companion file:

`tuf-sigstore-and-app-store-precedent-converge-on-signed-transparency-logged-distribution-but-only-firefox-amo-gates-execution-on-a-central-signature.md`

[companion-survey]

This file contains no new external claims — it is the recommendation built on that
evidence, scoped to PDPP's Data Connect architecture (capability-manifest + scoped-env
isolation, no OS-level sandbox, official + custom third-party repos, third-party
authors expected to be pseudonymous/independent).

## SOURCES

**companion-survey**
URL: (local corpus file, no external URL)
Accessed: 2026-08-14
Quote: n/a — see companion file's own SOURCES section for the 21 external citations underlying this synthesis.

## SYNTHESIS

### 1. Packaging format: signed OCI artifact wrapping a manifest + script bundle

Recommend: **a connector package is an OCI artifact** — not a bespoke tarball format,
not a bare script. Concretely: a small OCI image (or "artifact" per the OCI 1.1
artifact spec, no runnable base layer needed) whose layers are (a) the capability
manifest (JSON, declares scopes/permissions/env access — this already exists in
Data Connect's model), (b) the connector script(s), (c) optional metadata (changelog,
publisher identity pointer). Rationale from the survey: cosign already treats OCI
registries as a generic signed-artifact transport for exactly this kind of thing —
Helm charts, SBOMs, Kubernetes config bundles, arbitrary binaries — not just
containers, and it's tested against essentially every major registry vendor (so
PDPP is not locked into hosting its own registry infra; GHCR, Docker Hub, etc. all
work). This buys three things at once with no bespoke tooling: (1) content-addressed
distribution (digest = identity, immune to CDN/mirror tampering), (2) a signing
story that's literally the same command (`cosign sign`/`cosign verify`) for an
official connector and a third-party one hosted on a totally different registry,
and (3) versioning/tagging for free via existing OCI tooling. Reject a custom
tarball+detached-signature format — it would require reinventing content-addressing,
mirror/CDN integrity, and a bespoke verify tool, all of which OCI registries and
cosign already solve and are already fluent with container-adjacent tooling
maintainers (relevant since PDP-Connect likely already touches Docker/OCI for other
infra).

### 2. Signing identity model: Sigstore keyless tied to repo-level OIDC, with a documented fallback for authors who can't/won't wire CI

Recommend: **Sigstore keyless signing, identity = the GitHub repo + release workflow
(for authors using GitHub Actions CI), falling back to a pseudonymous OIDC login
identity (GitHub/Google account) for authors who sign manually outside CI.** This is
a direct fit for PDPP's stated constraint that third-party connector authors are
independent and pseudonymous, not all funneled through PDPP's own CI: Sigstore
explicitly designed for exactly this case — an author can register a pseudonymous
account with a supported OIDC provider and sign with that identity via interactive
login, with no long-lived key to generate, protect, or lose. The "continuity"
property (prove today's signer is the same as last release's signer, without
learning who they really are) is precisely the trust question a connector consumer
needs answered, and it's cheaper to get here via Sigstore than via a GPG-key model
(Terraform's approach) — GPG requires the author to generate, safeguard, and publish
a keypair, with no revocation mechanism as clean as "this identity's certs stop
appearing," and the survey found GPG signing has ~3 decades of persistently low
voluntary adoption outside registries that mandate it. Reject a "PDPP issues each
verified author a long-lived signing key" model — that recreates exactly the
key-custody liability Sigstore was built to eliminate, and gives PDPP an
inappropriate amount of custodial responsibility over third-party keys it doesn't
control the security practices of.

Practical friction to be honest about (per the survey's Sigstore-pseudonymous
finding): a third-party repo owner needs *some* OIDC-capable path — either their own
CI (GitHub Actions is the path of least resistance, free for public repos) or an
interactive login step at release time. This is real but modest friction, not zero;
document it clearly in connector-author onboarding docs as "sign in with GitHub once
per release" for the simplest case.

### 3. Index/registry design: TUF-lite signed index for the official repo; custom repos are self-describing and need no PDPP blessing

Recommend: the **official repo (`PDP-Connect/data-connectors`) publishes a small,
Sigstore-signed JSON index** listing connector name → latest version → OCI digest →
capability-manifest hash → publisher identity — essentially TUF's `targets` role
concept without adopting full TUF's four-role/threshold-signing machinery. This is
the right weight class per the survey: full custom TUF (offline root key ceremony,
threshold signing across independent roles) is heavier than even PyPI has fully
operationalized after ~10 years of PEP 458 effort; a single Sigstore-signed index
file, re-signed on every registry update via CI, gets most of the practical
protection (tamper-evidence, a public transparency-log record of every published
index state via Rekor) at a small fraction of the ops cost. Concretely this index
*is* PDPP's `targets` equivalent, Rekor's log substitutes for a dedicated `snapshot`
role (both exist to stop stale/mismatched state and rollback), and there's no need
for a separate offline `root` role at PDPP's scale — the index-signing identity
itself, backed by Sigstore/GitHub OIDC, is the root of trust, rotatable the same way
any GitHub-repo-scoped identity is rotated (repo access control), which is
proportionate for a project this size. Revisit true multi-role TUF only if PDPP's
official registry becomes large/high-value enough to be a compelling standalone
target independent of any single connector (i.e., if compromising the *index itself*
becomes worth attacking, not just individual connectors).

For **custom third-party repos**, the client needs zero blessing from PDPP to add
one — same UX as HACS's "paste a repo URL" or a Homebrew tap. The repo just needs to
expose the same shape of self-describing signed index (same schema PDPP's official
index uses) at a known path, so the same client-side verification code path handles
both; PDPP does not host, review, or gate anything about it. This directly avoids
the worst part of HACS's model — HACS's client only reads what you point it at, but
has no place to *display* a trust signal about how reviewed that source is, so every
custom repo looks the same as every other one to the end user regardless of actual
provenance. PDPP's client should visually and functionally distinguish official vs.
custom the moment a repo is added (see point 6).

### 4. Version pinning + lockfiles: a strict-by-default lockfile, no silent-drift mode exposed to end users

Recommend: Data Connect maintains a lockfile per user (analogous to
`package-lock.json`/`.terraform.lock.hcl`) recording exact connector version + OCI
digest + capability-manifest hash for every installed connector, and **the default
and only user-facing update path is the strict mode** — the equivalent of always
running `npm ci`/`terraform init -lockfile=readonly`, never a bare
`npm install`/`terraform init` that can silently rewrite the lock to a newer, unseen
version. The survey's clearest generalizable finding here: a lockfile without an
enforced strict mode is decorative — both npm and Terraform ship a "loose" mode that
silently drifts the lock the moment version constraints allow it, and that loose mode
is exactly the silent-auto-update failure PDPP needs to prevent given the credential-
theft stakes. There should be no PDPP-exposed equivalent of loose `install`/`init` at
all for connectors; every version bump is an explicit, visible lockfile-update event
gated by the update-time UX in point 5.

### 5. In-app update UX: treat every version bump as a diffable event, not a silent background swap

Recommend: on every connector update, before applying it, show the user: (a) a
capability-manifest diff (which scopes/permissions changed, highlighted, not buried
in a wall of JSON — mirrors Chrome's model of disabling an extension and blocking
re-enable until the user approves a materially different permission set, and
mirrors OAuth incremental-authorization's rule of asking in context with a stated
reason rather than blanket up-front); (b) the publisher identity (Sigstore-verified
repo/account) and whether it changed from the previously-installed version's signer
— a signer change on an existing connector name is exactly the "leaked publish
token" attack class the survey found hit VS Code Marketplace and Open VSX (100+
cases, up to 150,000 cumulative affected installs from stolen publish credentials),
so a signer-identity change should be flagged as a strong warning, not a routine
diff line; (c) a changelog if the publisher provided one. If the capability
manifest is unchanged, a quiet auto-update (respecting the lockfile-pin, i.e. only
after the user or a scheduled check explicitly advances the pin) is fine — reserve
the re-consent gate specifically for capability changes, matching Chrome's
"disable-until-approved" behavior and OAuth's "only re-prompt when scope actually
changes" rule; don't re-prompt on every trivial bugfix release, which would train
users to click through warnings (a documented failure mode — Obsidian's PHANTOMPULSE
incident succeeded specifically because the target had been conditioned/social-
engineered into clicking past multiple warning dialogs).

### 6. Custom-repo support with tiered trust: three visible tiers, unverified defaults to no-silent-update

Recommend three trust tiers, shown as a persistent visible badge in the connector's
UI card, not a one-time install-time notice:

- **Official** — from `PDP-Connect/data-connectors`, passed PDPP's own review process
  (whatever that is functionally — separate from this supply-chain research), signed,
  auto-update enabled by default (subject to point 5's capability-diff gate).
- **Verified-signed custom** — a third-party repo PDPP has not reviewed the *content*
  of, but whose index+connectors are properly Sigstore-signed and the signing
  identity has a consistent history (matches Terraform's Community tier: signing is
  a uniform floor, not a vetting signal — badge communicates "cryptographically
  consistent," not "safe").
- **Unverified custom** — anything added by raw repo URL with no working signature
  chain, the direct HACS-equivalent case. This tier should default to **no
  auto-update at all** — every update requires an explicit manual re-approval action,
  never silent, regardless of whether the capability manifest changed. This is the
  single concrete lesson from HACS/ComfyUI's incident history: every documented
  custom-node/custom-repo compromise in the survey was an *update* pushed after
  initial trust was established (or a typosquat exploiting the same "just paste a
  URL" flow with no differentiation from a legitimate one) — gating updates, not just
  installs, on this tier directly closes that hole.

This is a strict improvement over HACS's actual behavior (no visible trust signal
differentiating a heavily-audited official integration from an unmaintained
one-person repo) and over ComfyUI's pre-2025 posture (no registry-side restriction
on `eval`/`exec` at all until after a real incident forced the issue) — PDPP gets to
ship the tiering from day one rather than retrofitting it after an incident.

### 7. Revocation: a signed, append-only revocation list checked on every launch, backed by a Rekor-style log

Recommend: PDPP publishes a signed **revocation list** (digest/version → reason →
timestamp) as part of the same signed index infrastructure from point 3, and the
Data Connect client checks it on every launch (or at minimum on a short TTL, e.g.
hourly) before running any connector — refusing to execute a revoked digest even if
already installed and pinned. This directly mirrors npm's placeholder-package
mechanism (permanently block reuse of a compromised name/version rather than merely
un-listing it) and PyPI's yank semantics (a pinned/already-installed reference to a
revoked version should still be *visible and blocked*, not silently allowed to keep
running, which is a stricter posture than PyPI's "still installs with a warning" —
justified because PDPP's stakes are direct credential/data theft, not a broken build).
If Sigstore/Rekor is the signing backend chosen in point 2, Rekor's own transparency
log is a natural place to anchor the revocation record's own tamper-evidence — a
revocation is itself just a new signed statement in the log, publicly checkable and
timestamped, giving PDPP the "was this revocation itself legitimate and when did it
happen" property for free rather than needing a separate audit trail.

### 8. Permission/capability prompts: escalate at three points, matching OAuth's in-context model

Recommend three escalation points, not one blanket prompt:

- **Install-time**: full capability manifest shown up front (matches app-store /
  OAuth consent-screen precedent — the user sees the complete ask before the first
  run, no incremental hiding of scope at this stage since this is the one moment the
  user is making a considered "should I trust this at all" decision).
- **First-run**: if the manifest declares an optional/conditional capability that
  isn't exercised until a specific feature is used, defer that specific prompt to
  the point of actual use — this is Google's incremental-authorization pattern
  (request only what's needed now, ask for more in context, with a stated reason,
  when the feature triggers it) applied to connectors instead of OAuth scopes. Avoids
  the "consent screen fatigue" failure mode explicitly called out in Google's own
  incremental-auth guidance (users bounce off an overwhelming up-front ask).
- **Update-time**: per point 5, a manifest diff and re-consent gate specifically when
  the capability set changes, not on every version bump — mirroring Chrome's
  privilege-increase-only disable behavior, which distinguishes "materially new
  access" from "same permission bucket, new warning wording" using a graded
  comparison rather than naive string diffing of the manifest (worth building
  PDPP's diff logic to be semantic — e.g. "still just Gmail read access" shouldn't
  re-trigger even if the underlying scope string format changes — rather than
  treating any byte-level manifest change as a full re-prompt).

### Summary of what NOT to build

Given PDPP's scale: no full custom TUF deployment (offline root ceremony, four
independently-keyed roles, threshold signing) — the survey shows this is heavier
than even PyPI has fully shipped after a decade. No bespoke package format — OCI +
cosign already solves content-addressing and cross-registry signing. No PDPP-issued
long-lived per-author keys — recreates the GPG custody problem Sigstore was built to
avoid. No silent auto-update path exposed anywhere in the UI, even for the Official
tier, when the capability manifest changes — this is the one non-negotiable, since
it is the exact mechanism every cited real-world incident (VS Code leaked tokens,
ComfyUI Registry node, ComfyUI Reddit node) used to convert an initially-trusted
install into a credential-theft event.
