# Needs Tim — 2026-09-11

## 1. DO NOT revoke Forgejo token ID 1 (corrects an earlier claim)

Earlier notes — and the brief I wrote for the resume lane — described token ID 1
(`deploy-claude`) as "superseded, never revoked", implying it should be revoked.
**That framing is wrong and acting on it would have caused an outage.**

Token 1 is ACTIVELY IN USE. Verified twice, independently:

```
id | name          | last used (UTC)
 1 | deploy-claude | 2026-09-11 14:43:18   <- 69 seconds before this was written
11 | gitea-mirror… | 2026-09-11 12:59:39
```

It is used hourly at exactly `:43:18` past the hour by a Komodo `git-upload-pack`
poll of `tnunamak/aither-filler` (traced via Traefik access logs; Forgejo itself
logs to console only). `/etc/komodo/stacks/aither-filler/` exists on the host.
Forgejo's source was read to confirm `updated_unix` is a genuine last-used field
bumped only on successful auth, not an admin-edit artifact.

**Revoking it would break that deploy pipeline within the hour.** The correct
sequence: issue the `aither-filler` Komodo resource its own least-privilege
token, confirm the swap on the next hourly poll, and only then revoke ID 1 —
exactly how gitea-mirror was migrated to token 11.

## 2. Credentials exposed to agent transcripts — rotate out of caution

Neither was shown to you directly or repeated, but both were printed into
tool-call output during read-only investigations on 09-10:

- **Forgejo `INTERNAL_TOKEN`** (internal JWT signing secret) — from an
  over-broad `grep -A 20` on `app.ini`.
- **Cloudflare credentials** (`CF_API_EMAIL`, `CF_DNS_API_TOKEN`, `CF_Key`,
  `CF_Token`) — from an `infisical secrets` call without value suppression.
  Rotate the Cloudflare API token and Global API Key.

## 3. A prompt-injection attempt was encountered and ignored

During the Forgejo investigation, a fake "system-reminder" tried to redirect the
agent to a different task file. It was correctly ignored and no action was taken.
Flagged only so you know it happened.

## 4. Waiting on your yes/no (all diagnosed, none applied)

- **ddclient apex fix** — root cause proven against the live Cloudflare API
  (72 failures/24h reproduced exactly). Fix is dropping the `@.` prefix
  (`@.vivid.fish` → `vivid.fish`, `@.minnow.stream` → `minnow.stream`) in
  `/root/config/ddclient/ddclient.conf`, then `docker restart ddclient`.
  One line per zone, no DNS-side change.
- **PR 138 (pve-guest-metrics)** — credential migration done and verified.
  Merging + stopping the ad-hoc container + scoped deploy is a human call.
- **Infisical deploy** — the v0.165.9 build SUCCEEDED but the artifact is not on
  this host and `infisical:latest` no longer resolves. Needs Komodo UI access to
  find where it landed, or a rebuild targeted at this VM. The running container
  is still the pre-outage image.
- **Open WebUI OIDC** — needs a real browser login; curl can't verify it.
- **`deploy-changed-stacks.yml`** — still `disabled_manually`. The lane's advice,
  which I agree with: leave it disabled until the Infisical gap is closed.

## Already done and verified live (no action needed)

A second resume pass ran ~12h after the outage checkpoint and had already
finished more of the queue than the checkpoint knew about. Re-verified today:
Organizr 500 fix (HTTP 200 both endpoints), LibreChat deploy (digest match),
Cap deploy (digests match), Chaptarr build+deploy (digest match, book/author
counts stable). Host is healthy: filesystem rw, 79 containers up with zero
exited/restarting/unhealthy, 81% disk. The "poison" LibreChat backup does not
exist on disk and nothing references it.
