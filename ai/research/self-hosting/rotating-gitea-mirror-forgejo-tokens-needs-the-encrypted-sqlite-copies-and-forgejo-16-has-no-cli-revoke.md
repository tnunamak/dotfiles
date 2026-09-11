---
title: "Rotating a Gitea Mirror destination token requires rewriting its AES-256-GCM SQLite copies (keyed by the data-dir file secret, not BETTER_AUTH_SECRET); Forgejo 16 has no CLI revoke, only a basic-auth user route or an admin-scoped token route; Postgres accepts precomputed SCRAM verifiers so a password rotation never sends plaintext"
date: 2026-09-09
topic: self-hosting
tags: [gitea-mirror, forgejo, better-auth, postgres, scram, secret-rotation, infisical]
status: verified
sources: [gm-encryption, gm-entrypoint, gm-envloader, gm-docs, ba-jwt-sign, ba-sso-providers, forgejo-api-go, pg-scram]
source_session: 7a270059-796c-4b5b-9f78-042eeeac8efb
---

## CLAIMS

- Gitea Mirror v3.35.1 encrypts stored GitHub/Forgejo tokens with AES-256-GCM using a key derived by PBKDF2 (100k iterations, sha256) from `ENCRYPTION_SECRET || JWT_SECRET || BETTER_AUTH_SECRET`, and stores base64(JSON{encrypted, iv, salt, tag, version:1}); the random per-record salt is not used in key derivation. [gm-encryption]
- The Docker entrypoint exports `ENCRYPTION_SECRET` from `/app/data/.encryption_secret` (generated with `openssl rand -base64 36` on first boot) when the env var is unset, so with a persisted data dir the effective key is the file secret, not `BETTER_AUTH_SECRET`; `docker exec` env and pid 1 do not show it, only the bun child process does. [gm-entrypoint] (verified live: the file key decrypted all stored tokens; the auth secret decrypted none)
- `GITEA_TOKEN`/`GITEA_URL` env values are applied by `initializeConfigFromEnv()` on the first requests after start, only to the first user (ordered by createdAt), and the env token overwrites the stored one (`envConfig.gitea.token ? encrypt(env) : existing`); other users' configs keep their own encrypted copies. Docs describe this as "only set values for empty fields", which is not what the token branch does. [gm-envloader] [gm-docs]
- Better Auth 1.7.2 encrypts the JWKS private key with the auth secret by default (`!options?.jwks?.disablePrivateKeyEncryption`); after a secret change, signing fails with "Failed to decrypt private key ... either clean up your JWKS or disable private key encryption". [ba-jwt-sign]
- Better Auth 1.7.2 SSO plugin stores `oidcConfig`/SAML config as plaintext JSON (no symmetricEncrypt), so rotating the secret does not break configured SSO providers. [ba-sso-providers]
- Forgejo v16.0.3 routes: `/users/{username}/tokens/{id}` DELETE requires `reqBasicOrRevProxyAuth()` + `reqToken()` under `reqSelfOrAdmin()`; `/admin/users/{username}/tokens/{id}` DELETE lives in the `/admin` group guarded by `tokenRequiresScopes(AccessTokenScopeCategoryAdmin), reqToken(), reqSiteAdmin()`. The CLI `forgejo admin user` offers `generate-access-token` but no delete/revoke subcommand. [forgejo-api-go]
- PostgreSQL accepts a precomputed `SCRAM-SHA-256$<iter>:<b64 salt>$<b64 StoredKey>:<b64 ServerKey>` literal in `ALTER ROLE ... PASSWORD`, storing it verbatim; a client-side verifier (PBKDF2-HMAC-SHA256 SaltedPassword, ClientKey = HMAC(SaltedPassword,"Client Key"), StoredKey = SHA256(ClientKey), ServerKey = HMAC(SaltedPassword,"Server Key")) was accepted by postgres:16 and authenticated the correct password only. [pg-scram]

## SOURCES

**gm-encryption**
URL: https://raw.githubusercontent.com/RayLabsHQ/gitea-mirror/v3.35.1/src/lib/utils/encryption.ts
Accessed: 2026-09-09
Quote: "const secret = process.env.ENCRYPTION_SECRET || process.env.JWT_SECRET || process.env.BETTER_AUTH_SECRET;"

**gm-entrypoint**
URL: https://raw.githubusercontent.com/RayLabsHQ/gitea-mirror/v3.35.1/docker-entrypoint.sh
Accessed: 2026-09-09
Quote: "export ENCRYPTION_SECRET=$(cat \"$ENCRYPTION_SECRET_FILE\")"

**gm-envloader**
URL: https://raw.githubusercontent.com/RayLabsHQ/gitea-mirror/v3.35.1/src/lib/env-config-loader.ts
Accessed: 2026-09-09
Quote: "token: envConfig.gitea.token ? encrypt(envConfig.gitea.token) : existingConfig?.[0]?.giteaConfig?.token || ''"

**gm-docs**
URL: https://raw.githubusercontent.com/RayLabsHQ/gitea-mirror/v3.35.1/docs/ENVIRONMENT_VARIABLES.md
Accessed: 2026-09-09
Quote: "Environment variables only set values for empty fields"

**ba-jwt-sign**
URL: https://raw.githubusercontent.com/better-auth/better-auth/v1.7.2/packages/better-auth/src/plugins/jwt/sign.ts
Accessed: 2026-09-09
Quote: "Failed to decrypt private key. Make sure the secret currently in use is the same as the one used to encrypt the private key. If you are using a different secret, either clean up your JWKS or disable private key encryption."

**ba-sso-providers**
URL: https://raw.githubusercontent.com/better-auth/better-auth/v1.7.2/packages/sso/src/routes/providers.ts
Accessed: 2026-09-09
Quote: (no symmetricEncrypt/symmetricDecrypt; configs serialized with JSON.stringify)

**forgejo-api-go**
URL: https://codeberg.org/forgejo/forgejo/raw/tag/v16.0.3/routers/api/v1/api.go
Accessed: 2026-09-09
Quote: "m.Combo(\"/{id}\").Delete(reqBasicOrRevProxyAuth(), reqToken(), user.DeleteAccessToken)"

**pg-scram**
URL: https://www.postgresql.org/docs/current/sql-alterrole.html (verifier literal accepted as-is), local proof: postgres:16 container, `CREATE ROLE ... PASSWORD '<verifier>'`, psql over TCP with the plaintext succeeded, wrong password rc 2
Accessed: 2026-09-09

## SYNTHESIS

Rotating a "destination token" for gitea-mirror is a three-store change (Infisical/.env, the running container env, and every user's encrypted DB copy), and the DB copies must be re-encrypted with the file secret via the app's own algorithm. Rotating BETTER_AUTH_SECRET is cheap (sessions + delete jwks) precisely because token encryption does not use it once the data dir exists. For Forgejo tokens, plan for revocation at issue time: keep one admin-scoped token in a hydrated shell, or you will need the user's password or the web UI. Precomputed SCRAM verifiers make DB password rotation log-safe on any Postgres ≥ 10.
