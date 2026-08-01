---
title: "Komodo copies tracked env-file contents plaintext into every stack's Mongo doc; track:false (its documented 'externally managed file' path) stops it, and the stored blobs clear on the next filtered rebuild"
date: 2026-07-16
topic: self-hosting
tags: [komodo, secrets, mongodb, docker-compose, gitops, infisical, sops]
status: settled
sources: [komodo-stack-rs, komodo-remote-rs, komodo-execute-stack-rs, komodo-variable-rs, komodo-vars-docs, deepwiki-53, deepwiki-62, komodo-issue-583, komodo-issue-74, komodo-disc-934, coolify-envvar, portainer-db-enc, docker-swarm-secrets, argo-secrets, flux-sops, sealed-secrets, eso, kamal-env, ansible-vault]
source_session: 019f9057-6ed2-77a1-ac39-4c6122c144ef
---

## CLAIMS

- Komodo's persistence of a `additional_env_files` entry is governed entirely by its `track` flag; `track` defaults to `true` [komodo-stack-rs].
- `track:true` => Komodo will "read, display, diff, and validate" the file (persisting contents into Mongo); `track:false` => "only passed to docker compose via --env-file. Useful for externally managed files (e.g., sops decrypted files)" — verbatim doc comment [komodo-stack-rs].
- The `tracked_env_files()` helper does `self.config.additional_env_files.iter().filter(|f| f.track)...`; both `all_file_dependencies()` (content reading) and `all_tracked_file_paths()` (change detection) source env files from it, so a `track:false` file is never read into any stored StackInfo field [komodo-stack-rs].
- `remote_contents` is rebuilt fresh (new Vec, `fs::read_to_string` per file, no merge) on every stack-cache refresh in `get_repo_compose_contents` [komodo-remote-rs]; `deployed_contents`/`deployed_config` are rebuilt from the deploy response's `file_contents` only on a successful deploy [komodo-execute-stack-rs].
- Core persists the whole StackInfo with a full-document `"$set": { "info": info }` (overwrite, not merge) [komodo-execute-stack-rs].
- CONSEQUENCE (inferred from the confirmed rebuild+filter+overwrite, NOT maintainer-stated): flipping `track:true→false` then triggering a refresh drops the plaintext from `remote_contents` on the next write; but `deployed_contents`/`deployed_config` persist until the next successful deploy or a manual mongosh scrub [derived from komodo-stack-rs + komodo-remote-rs + komodo-execute-stack-rs].
- A mongosh scrub while `track` is still `true` is pointless: Core periodically refreshes via CheckStackForUpdate and re-reads the still-tracked file, re-populating the field [deepwiki-53].
- Komodo has native `[[KEY]]` Variable/Secret interpolation (open-source GPL-3.0, not Enterprise-gated); Core interpolates before sending config to Periphery and returns secret_replacers to sanitize command logs [komodo-vars-docs, deepwiki-62].
- Komodo Variables do NOT solve at-rest: the `Variable.value` is a plain `String`, doc-comment says it is NOT encrypted and "will likely show up in database logs"; `is_secret` only masks in UI/updates/logs and blocks non-admin API reads (access control, not encryption) [komodo-variable-rs, komodo-vars-docs].
- Official docs: "Komodo is not intended as an enterprise level secret management solution" — recommends a dedicated external secret manager [komodo-vars-docs].
- Issue #583 requests masking of secret env values "exposed in plain text" in the UI; issue #74 added `${VAR}_FILE` support for Komodo's OWN config secrets (not app env-file tracking); discussion #934 covers SOPS/age decrypt-at-deploy workarounds (pairs with track:false) [komodo-issue-583, komodo-issue-74, komodo-disc-934].
- Prior-art at-rest models: Coolify encrypts the env `value` column via Laravel `encrypted` cast keyed by APP_KEY [coolify-envvar]; Portainer stores stack env as plaintext JSON in BoltDB, offers only coarse all-or-nothing whole-DB AES-256-GCM [portainer-db-enc]; Docker Swarm secrets are Raft-encrypted at rest and tmpfs-mounted at /run/secrets (not env) [docker-swarm-secrets]; Kamal 2 keeps no encrypted state, reads plaintext per-role .env at deploy (can source from 1Password/Vault) [kamal-env]; Ansible-Vault is genuine AES-256 at rest but decrypts to host at runtime [ansible-vault].
- GitOps winners keep plaintext out of tool state by referencing an external store at runtime (External Secrets Operator, Kamal→1Password/Vault) or encrypting in Git and decrypting on reconcile (Flux+SOPS+age, Sealed Secrets) [eso, kamal-env, flux-sops, sealed-secrets, argo-secrets].
- No CVEs found for moghtech/komodo [UNVERIFIED — not exhaustively checked across all CVE DBs].

## SOURCES

- komodo-stack-rs: https://raw.githubusercontent.com/moghtech/komodo/main/client/core/rs/src/entities/stack.rs — Accessed 2026-07-16. `AdditionalEnvFile.track` doc comment + `tracked_env_files()` filter.
- komodo-remote-rs: https://github.com/moghtech/komodo/blob/main/bin/core/src/stack/remote.rs — `get_repo_compose_contents` rebuilds remote_contents.
- komodo-execute-stack-rs: https://github.com/moghtech/komodo/blob/main/bin/core/src/api/execute/stack.rs — deployed_contents build + `$set` whole-doc write.
- komodo-variable-rs: https://github.com/moghtech/komodo/blob/main/client/core/rs/src/entities/variable.rs — Variable.value plaintext, not encrypted.
- komodo-vars-docs: https://komo.do/docs/configuration/variables — is_secret semantics + "not enterprise secret management".
- deepwiki-53: https://deepwiki.com/moghtech/komodo/5.3-stack-and-compose-operations — periodic CheckStackForUpdate refresh.
- deepwiki-62: https://deepwiki.com/moghtech/komodo/6.2-variable-and-secret-interpolation — two-phase interpolation + secret_replacers.
- komodo-issue-583: https://github.com/moghtech/komodo/issues/583
- komodo-issue-74: https://github.com/moghtech/komodo/issues/74
- komodo-disc-934: https://github.com/moghtech/komodo/discussions/934
- coolify-envvar: Coolify `app/Models/EnvironmentVariable.php` (Laravel encrypted cast).
- portainer-db-enc: https://docs.portainer.io/advanced/db-encryption ; issues #12765/#12825 (encryption bugs).
- docker-swarm-secrets: https://docs.docker.com/engine/swarm/secrets/
- argo-secrets: https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/
- flux-sops: https://fluxcd.io/flux/guides/mozilla-sops/
- sealed-secrets: https://github.com/bitnami-labs/sealed-secrets
- eso: https://external-secrets.io/
- kamal-env: https://kamal-deploy.org/docs/configuration/environment-variables/
- ansible-vault: https://docs.ansible.com/ansible/latest/vault_guide/index.html

NOTE: Reddit/HN thread *content* UNVERIFIED (reddit blocked to crawler); community sentiment came from practitioner blogs/HN, not primary Reddit posts. Exact live Mongo collection/field paths and the Periphery-side read path are UNVERIFIED against this specific instance — inspect before writing and verify after redeploying.

## SYNTHESIS

For a homelab already running an external secret store (Infisical), the correct architecture is: external store renders `/root/.env` → Komodo passes it via `--env-file` but never reads/stores it. That is *exactly* what `track:false` is documented for ("externally managed files, e.g. sops decrypted"). Recommended remediation order: (a) `track:false` on all stacks + refresh/redeploy (or mongosh `$unset` after flipping) — closes the plaintext-in-Mongo leak with zero new infra, reversible; verify in Mongo post-redeploy because the retroactive-clear is inferred-not-maintainer-confirmed. (b) per-stack scoped env files to make the residual blast radius least-privilege. (d) LUKS/Proxmox-disk encryption of mongo-data as defense-in-depth for snapshots/backups. Skip Komodo native Variables (also plaintext in Mongo — moves the problem, doesn't fix it), Swarm-tmpfs (overkill single-node), and do-nothing (the vector is root/backup/snapshot dump, not the network). Tradeoff of (a): loses Komodo's env-file drift-diff UI (compose-file drift still works).
