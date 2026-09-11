# Homelab maintenance queue — resume — 2026-09-11

Picks up from `ROOT-CLOSEOUT-20260910-0222.md` (the outage checkpoint) and a previously-unknown-to-me
second resume pass I found already on disk under `resume-0910/` (dated 2026-09-10 14:37-15:00 UTC,
~20h before this session). That pass did real, verified work on the VM — I independently re-verified
its claims below rather than trusting the files. No Codex workers were used anywhere in this session
(waspflow was not needed — everything here was direct SSH/gh/psql read/verify work).

## Host state now

**VERIFIED**, checked directly by me at 2026-09-11 14:35 UTC:
- SSH to `root@192.168.1.4`: OK.
- `/proc/mounts`: `/dev/sda3 / ext4 rw,relatime` — filesystem is read-write.
- `uptime`: up 1 day 9h52m → booted ~2026-09-10 04:43 UTC (the VM's own self-recovery reboot after
  the outage; no one rebooted it in this session).
- `docker ps -q | wc -l` = 79. Zero exited, zero restarting, zero unhealthy containers.
- Disk: 498.7G total, 385.6G used, 87.6G available (81% used) — healthy headroom.
- Host `/root` git HEAD = `438b8660bad5179abbea1761c940ef564992483b` = `origin/main`. Confirmed via
  `git rev-parse HEAD` and `git rev-parse origin/main` after a fresh fetch — genuinely equal, not
  assumed.
- Poison backup `/root/config-backups/pin-deploys-20260910/librechat.pre-0909dev`: **does not exist**
  on disk. Grepped `/root/scripts`, `/root/compose`, `/root/.tmp` for the literal path — zero hits.
  Nothing references or could use it as a rollback source.

**Data integrity around the outage:** the resume-0910 pass took real backups with manifests/checksums
before every mutation it made (LibreChat: fresh `cp -a` + 622-file manifest + sha256; Cap: mysqldump
0600, 72,850 bytes, 43 tables; Chaptarr: pre-build backup, file count verified 53119==53119; Infisical:
pg_dump 4.6MiB, 755 tables). I did not re-verify these backup files' bytes myself (would require
touching production data again for no new information) but the container-level evidence below is
independently consistent with what they claim.

## Reconciliation — checkpoint vs. reality

The 02:22 UTC checkpoint (`ROOT-CLOSEOUT-20260910-0222.md`) assumed the paused queue was untouched.
It was not — a second Sonnet-based resume pass ran ~12 hours after that checkpoint (2026-09-10
14:37-15:00 UTC) and materially advanced the queue before apparently stopping (no further HANDOFF
files after ~15:00 UTC). I reconciled each checkpoint claim against live host state myself:

| Item | Checkpoint said | Reality (VERIFIED by me just now) |
|---|---|---|
| Organizr 500 fix | never applied | **Fixed.** Stale `.git/index.lock` removed, container restarted. `/` and `/api/v2/ping` both return HTTP 200 live. |
| LibreChat pin PR | merged, not deployed | **Deployed.** Running image digest `a85d9093…` matches the PR pin exactly. Sibling containers (mongo/meili/crw) unchanged. |
| Cap pin PR | merged, not deployed | **Deployed.** `cap-web` and `cap-media-server` digests match pins exactly (`8ee4cbd3…`, `886ecc9b…`). mysqldump backup exists. |
| Chaptarr PR 141 | merged, 78 tests pass, not deployed | **Deployed.** Running image `sha256:a64fb502e8ac…` matches the local build output digest. Book/author counts matched pre/post. |
| Infisical pin PR 140 | merged, rebuild not started | **Build succeeded, deploy NOT done — still open.** See below. |
| PR 138 (pve-guest-metrics) | credential migration undone | **Credential migration done, PR pushed.** Still open (by design — needs a human merge + deploy decision). |
| ddclient Organizr-style defect | unverified diagnosis | **Root cause confirmed with live API evidence**, fix described, not applied (config edit, needs Tim's approval). |
| Open WebUI OIDC | unverified | **Still unverified** — `/api/version` confirms `0.11.3` is live, but no one has done an actual browser OIDC login click-through. Unchanged from checkpoint. |
| deploy-changed-stacks.yml | disabled_manually | **VERIFIED still `disabled_manually`** via `gh api .../actions/workflows`. Nobody re-enabled it. |

**Infisical — the one incomplete item.** The Komodo Build (`infisical`, branch bumped to `v0.165.9`)
did complete successfully — I confirmed this live: `komodo_poll_update.py` against update id
`6aa2c303c1a137d3bd66939a` returns `status: Complete, success: True`, all 6 build stages
(git remote/checkout/pull/latest-commit/pre-build/docker-build) succeeded, and `GetBuild` now shows
`branch: v0.165.9, built_hash: 7c35765d0a`. **But the running `infisical` container is still on the
old image** (`sha256:3811fd998e5e…`, StartedAt = the reboot, i.e. pre-outage state) — its `infisical:latest`
tag no longer resolves to anything (`docker inspect infisical:latest` → "no such object"), and I could
not locate the newly built image under any tag or as a dangling image on this host. Komodo's build
config has `image_registry: []` (no registry push) and a `builder_id` set, which typically means the
build ran on a Komodo-configured builder resource — possibly not this VM. **INFERRED, not verified:**
the image was built somewhere I don't have visibility into and was never pulled/deployed here. This
needs a human (or a lane with Komodo UI/build-target access) to locate the actual build artifact
before Infisical can be deployed. I did not attempt to force a local rebuild or guess at a deploy
path — that would be exactly the kind of unilateral deploy action the task told me to avoid.

## Forgejo token

Followed the checkpoint's mandated order exactly: inspected existing app-job evidence first, did not
reset the observer baseline, did not probe with the replacement token, before even considering revoking.

**What the resume-0910 pass already found (2026-09-10, independently corroborated by me today):**
- Old token ID 1 (`deploy-claude`, created 2026-06-26) was rotated to ID 11 (`gitea-mirror-…`,
  created 2026-09-10 01:43:58) for gitea-mirror specifically. Gitea-mirror's 3 accounts synced
  cleanly post-rotation (938 jobs, 0 failed) — token 11 is confirmed app-driven and healthy.
- Token 1's `updated_unix` kept advancing *after* the rotation cutover — meaning something other
  than gitea-mirror is still actively using it. A follow-up forensic pass traced this via Traefik
  access logs (Forgejo itself logs nowhere — `MODE = console`, not captured) to an hourly
  `git-upload-pack` fetch of repo `tnunamak/aither-filler`, whose own description says "Deployed via
  Komodo," matching a live `/etc/komodo/stacks/aither-filler` directory on the host. Cadence: exactly
  hourly at `:43:18` past the hour (3 consecutive hits, 12:43/13:43/14:43 UTC on 09-10).
- Forgejo source (`v16.0.3`/gitea-1.22.0, the exact running version) was read directly to confirm
  `updated_unix` is a genuine last-used field (`AccessToken.Verify()` → `UpdateLastUsed()`), bumped
  only on successful authentication — not an admin-edit artifact. So this really is "used," not noise.

**What I verified myself, live, right now (2026-09-11 14:41 UTC), via a read-only `psql` query
against the Forgejo Postgres DB:**

```
id | name                         | created_unix | updated_unix
 1 | deploy-claude                | 1782493442   | 1789134198   → 2026-09-11 13:43:18 UTC
 3 | Peregrine Admin              | 1783607265   | 1789074670
11 | gitea-mirror-20260910-014358 | 1789004638   | 1789131579   → 2026-09-11 12:59:39 UTC
```

**Token 1 was used again TODAY at 13:43:18 UTC — the same `:43:18`-past-the-hour mark documented
yesterday.** This is a second, independent day of evidence for the same hourly Komodo poll. I also
confirmed `/etc/komodo/stacks/aither-filler/` still exists on the host (git-managed directory, last
touched Jul 15-16). Token 11 also shows recent legitimate use (12:59:39 UTC), consistent with its
own scheduled 8h sync cadence.

**Decision: did NOT revoke token 1.** The evidence bar the checkpoint itself set ("revoke only after
valid sync evidence" — implicitly, evidence that nothing else needs the old token) is not met; the
opposite is true. Revoking token 1 right now would break Komodo's `aither-filler` deploy pipeline on
its next poll (within the hour of whenever it's revoked). This directly reverses the framing in my
original task brief, which described token 1 as merely "superseded... never revoked" — that framing
is now known to be wrong. **Token 1 must stay valid until Komodo's `aither-filler` resource is given
its own least-privilege token and switched over, the same way gitea-mirror already was.**

**Also flagged, not yet actioned (found by the resume-0910 pass, still true, needs Tim):**
- Forgejo's `INTERNAL_TOKEN` (internal JWT-signing secret, unrelated to the PAT under investigation)
  was incidentally printed into a tool-call transcript during an over-broad `grep -A 20` on `app.ini`.
  Recommend rotating it out of caution.
- Several Cloudflare credentials (`CF_API_EMAIL`, `CF_DNS_API_TOKEN`, `CF_Key`, `CF_Token`, etc.) were
  printed in plaintext into a tool-call transcript during the ddclient investigation (an `infisical
  secrets` call without a value-suppressing flag). Recommend rotating the Cloudflare API token and
  Global API Key.
- A prompt-injection attempt was encountered and correctly ignored during the Forgejo token
  investigation (a fake "system-reminder" trying to redirect the agent to a different task file). No
  action was taken on it; flagging only so you're aware it happened.

## Queue status

| Item | Still needed? | Safe to proceed? | Status |
|---|---|---|---|
| Organizr 500 fix | No | — | **DONE**, verified live (HTTP 200 both endpoints) |
| LibreChat deploy | No | — | **DONE**, verified live (digest match) |
| Cap deploy | No | — | **DONE**, verified live (digests match, mysqldump backup exists) |
| Chaptarr host build+deploy | No | — | **DONE**, verified live (digest match, book/author counts stable) |
| Infisical rebuild | Yes — deploy step only | Blocked on locating the build artifact | Build succeeded server-side; artifact not found on this host; needs Komodo access or a rebuild-and-deploy-in-one-shot on this VM |
| PR 138 (pve-guest-metrics) | Yes | Ready for merge decision | Credential migration done, config resolves cleanly, Proxmox token confirmed live. Deploy also requires stopping the ad-hoc `pve-guest-metrics` container (still running, `Up 34 hours`) first — not done, correctly left as a deploy action for a human/gated lane |
| ddclient apex fix | Yes | Yes, but needs your approval — one-line config edit | Root cause fully proven against live Cloudflare API (72/24h failures reproduced exactly); fix is dropping the `@.` prefix in `/root/config/ddclient/ddclient.conf`, then `docker restart ddclient` |
| Open WebUI OIDC verification | Yes | N/A (verification only, no deploy) | Still needs an actual browser login click-through; app itself confirmed live on 0.11.3 |
| Forgejo token 1 revoke | Not yet — blocked | **No — do not revoke** | Komodo's `aither-filler` still actively uses it hourly, confirmed again today |
| Re-enable `deploy-changed-stacks.yml` | Your call | See recommendations | Still `disabled_manually`; I did not touch it |

## Recommended next actions (ranked by risk, lowest first)

1. **(No risk) Rotate `INTERNAL_TOKEN` (Forgejo) and the Cloudflare API token/Global API Key.** Both
   were incidentally exposed to agent tool-call transcripts during read-only investigations, never to
   me directly, never repeated, but should be rotated out of caution. Doesn't touch production state.
2. **(Low risk) Apply the ddclient config fix.** Single-line-per-zone edit
   (`@.vivid.fish`→`vivid.fish`, `@.minnow.stream`→`minnow.stream`) + `docker restart ddclient`. Root
   cause is proven with live API evidence, not a guess. No DNS-side change. I can do this if you want
   me to, or you can.
3. **(Low risk, needs your review) Merge PR 138 and deploy pve-guest-metrics.** Credential migration
   is done and verified live; the only remaining steps are a normal merge + stopping the ad-hoc
   container + a scoped compose deploy. I did not do this myself since it's a production deploy and
   the task asked me to report go/no-go rather than deploy unilaterally on this pass.
4. **(Low risk) Verify Open WebUI OIDC with an actual browser login.** Pure verification, no mutation.
5. **(Medium risk, needs Komodo access) Resolve the Infisical deploy gap.** Either find where the
   `v0.165.9` build artifact landed (Komodo UI, check the configured `builder_id` resource) and pull
   it here, or re-run the build with a builder explicitly targeted at this VM, then `pg_dump` (fresh
   one — the existing 09-10 dump is now ~20h stale) → scoped `docker compose up -d --no-deps` → verify
   migrations/health before calling it done. I did not attempt this myself — it's a real production
   database service and guessing at the deploy path felt like exactly the kind of thing to check with
   you first.
6. **(Do not do yet) Forgejo token 1 revoke.** Needs: issue Komodo's `aither-filler` resource a
   dedicated least-privilege token, confirm the swap on the next hourly poll, only then revoke ID 1.
   None of that was started this session (correctly, per the checkpoint's own ordering).
7. **(Your call, no urgency) Re-enable `deploy-changed-stacks.yml`.** Everything currently paused in
   its queue has now either been manually deployed-and-verified (items 1-4 in the table above) or is
   correctly still gated behind a human decision (Infisical, PR 138, token revoke). I'd lean toward
   leaving it disabled until Infisical's deploy gap is closed, since re-enabling before that could
   cause the next Renovate/pin merge to try to deploy against a host whose Infisical state I can't
   fully explain yet — but this is your call, not mine to make unilaterally.

## Not done / needs Tim

- **Infisical deploy** — build succeeded, artifact location unresolved by me. Needs Komodo
  UI/API access with a wider scope than I used, or a decision to just rebuild targeting this VM.
- **PR 138 merge/deploy decision** — mechanically ready; merging and deploying is a human call I left
  alone per the task's scope limits.
- **ddclient fix application** — diagnosed and proven, not applied; needs your yes/no.
- **Open WebUI OIDC browser click-through** — needs an actual human/browser session, not something I
  verified via curl.
- **Forgejo token 1 → Komodo least-privilege token migration** — needs to happen before any revoke;
  not started.
- **Credential rotations flagged above** (`INTERNAL_TOKEN`, Cloudflare token/key) — your decision on
  timing/method.
- **Bravo/hardware wedge investigation** — explicitly out of scope for me; untouched, as instructed.
- I did **not** independently re-verify the byte contents of the 09-10 backups (LibreChat manifest
  sha256, Cap mysqldump, Chaptarr pre-build copy, Infisical pg_dump) beyond trusting their recorded
  sizes/checksums in the resume-0910 report files — re-reading multi-hundred-MB production config
  directories a second time for no new information seemed like unnecessary risk/cost. If you want an
  independent re-verify of any specific one, say which and I will.
