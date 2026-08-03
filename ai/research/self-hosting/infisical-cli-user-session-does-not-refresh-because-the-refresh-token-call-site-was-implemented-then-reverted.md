---
title: "Infisical CLI user sessions never refresh because the refresh-token call site was implemented and then reverted upstream, leaving a live TODO"
date: 2026-08-02
topic: self-hosting
tags: [infisical, secrets, cli, auth, refresh-token, machine-identity, upstream-gap]
status: settled
sources: [cli-credentials-source, cli-auth-source, cli-api-source, mono-git-history, cli-release, local-binary-check, cli-secrets-source, cli-login-help, local-mi-timing]
source_session: 42569d54-d339-4dac-a5d0-9fe01269743e
---

## CLAIMS

- Infisical CLI `GetCurrentLoggedInUserDetails` computes `LoginExpired` purely from the stored JWT's expiry and contains a commented-out refresh block preceded by `// TODO: add refresh token`; no code path calls the refresh endpoint. [cli-credentials-source]
- The refresh machinery the TODO would use already exists: `api.CallGetNewAccessTokenWithRefreshToken` is implemented, `models.UserCredentials` carries a `RefreshToken` field, and the server returns a refresh token as a cookie during login. [cli-api-source]
- On expiry the CLI does not refresh; `EstablishUserLoginSession` shells out to `infisical login --silent` with the parent's stdin/stdout attached. [cli-auth-source]
- Commit `de917a5d74` (2025-06-14, author x032205) is titled "Fix CLI refresh token functionality + reduce token lifetime to 1d & 14d for refresh". Commit `f167ba0fb8` (2025-06-19, author Maidul Islam) is titled `Revert "Merge pull request #3797 from Infisical/ENG-2690"` and its body contains only the auto-generated revert text with no stated reason. [mono-git-history]
- The TODO's introduction is not attributable from the `Infisical/cli` repository alone: `git log -L` there resolves only to `9c3717a` (2025-07-12, "misc: migrated CLI code to dedicated repository"), the repo-split commit. [mono-git-history]
- Infisical CLI `v0.43.116`, published 2026-07-31, was the latest release as of 2026-08-02. [cli-release]
- The locally installed `v0.43.116` binary contains zero occurrences of the string `CallGetNewAccessTokenWithRefreshToken`. [local-binary-check]
- `WriteBackupSecrets` (the encrypted offline cache) is called only inside the user-login branch of `GetAllEnvironmentVariables`; the `UniversalAuthAccessToken` branch returns fetched secrets without writing or reading any cache. [cli-secrets-source]
- `ReadBackupSecrets` is invoked only when `!isConnected` and only inside that same user-login branch. [cli-secrets-source]
- `GetBackupEncryptionKey` reads `INFISICAL_BACKUP_SECRET_ENCRYPTION_KEY` from the configured vault backend, generating and storing a random 16-byte key on first miss. [cli-secrets-source]
- `infisical login` accepts non-interactive user credentials via `--email`/`--password`/`--organization-id` flags or the `INFISICAL_EMAIL`, `INFISICAL_PASSWORD`, `INFISICAL_ORGANIZATION_ID` environment variables, with `--domain`/`INFISICAL_DOMAIN` also required. [cli-login-help]
- On this host a machine-identity `login` plus `export` round trip completed in 0.27s wall clock, versus a measured 21.86s interactive `zsh -i -c exit` before the change and 1.86s after. [local-mi-timing]
- `infisical login status` returns exit code 1 for a locally-expired keyring session and verifies against the backend; the presence of `INFISICAL_UNIVERSAL_AUTH_CLIENT_ID`/`_SECRET` in the environment does not mask that non-zero exit. [local-mi-timing]

## SOURCES

**cli-credentials-source**
URL: https://github.com/Infisical/cli/blob/main/packages/util/credentials.go
Accessed: 2026-08-02
Quote: "// TODO: add refresh token\n\t\t// if !isAuthenticated {\n\t\t// \taccessTokenResponse, err := api.CallGetNewAccessTokenWithRefreshToken(httpClient, userCreds.RefreshToken)"

**cli-auth-source**
URL: https://github.com/Infisical/cli/blob/main/packages/util/auth.go
Accessed: 2026-08-02
Quote: "loginCmd := exec.Command(exePath, \"login\", \"--silent\")"

**cli-api-source**
URL: https://github.com/Infisical/cli/blob/main/packages/api/api.go
Accessed: 2026-08-02
Quote: "func CallGetNewAccessTokenWithRefreshToken(httpClient *resty.Client, refreshToken string) (GetNewAccessTokenWithRefreshTokenResponse, error)"

**mono-git-history**
URL: https://github.com/Infisical/infisical (git log -S 'TODO: add refresh token')
Accessed: 2026-08-02
Quote: "de917a5d74 2025-06-14 x032205 — Fix CLI refresh token functionality + reduce token lifetime to 1d & 14d for refresh / f167ba0fb8 2025-06-19 Maidul Islam — Revert \"Merge pull request #3797 from Infisical/ENG-2690\""

**cli-release**
URL: https://api.github.com/repos/Infisical/cli/releases/latest
Accessed: 2026-08-02
Quote: "tag: v0.43.116, published: 2026-07-31T19:14:47Z"

**local-binary-check**
URL: local — `strings ~/.local/bin/infisical | grep -c CallGetNewAccessTokenWithRefreshToken`
Accessed: 2026-08-02
Quote: "0"

**cli-secrets-source**
URL: https://github.com/Infisical/cli/blob/main/packages/util/secrets.go
Accessed: 2026-08-02
Quote: "if err == nil { backupEncryptionKey, err := GetBackupEncryptionKey(); ...; WriteBackupSecrets(...) } ... } else if params.UniversalAuthAccessToken != \"\" { ...; res, err := GetPlainTextSecretsV4(params.UniversalAuthAccessToken, ...); errorToReturn = err; secretsToReturn = res.Secrets }"

**cli-login-help**
URL: local — `infisical login --help` (v0.43.116) and packages/cmd/login.go `validateDirectUserLoginFlagsAndEnvsSet`
Accessed: 2026-08-02
Quote: "requiredFlagsEnvs := map[string]string{ \"email\": \"INFISICAL_EMAIL\", \"password\": \"INFISICAL_PASSWORD\", \"organization-id\": \"INFISICAL_ORGANIZATION_ID\" }"

**local-mi-timing**
URL: local — timed runs on peregrine, 2026-08-02
Accessed: 2026-08-02
Quote: "MI login+export 0.267s total; `zsh -i -c exit` 21.859s before / 1.858s after; `infisical login status` rc=1 with expired session, rc=1 also with MI env vars present"

## SYNTHESIS

The ~14-day re-login is an upstream gap, not a security decision and not a
local misconfiguration. The refresh path was built (PR #3797 / ENG-2690) and
reverted five days later with an empty commit body; no public issue explains
it, and searches surface only adjacent complaints (session-lost-on-upgrade,
non-interactive login requests, headless keyring failures). The reverted PR
also set token lifetimes to 1d access / 14d refresh, which matches the
observed cadence — suggesting the server-side lifetime change outlived the
CLI-side revert.

This interacts badly with the offline cache. Only the user-login branch writes
`secrets-backup/`, so a host authenticating solely by machine identity gets
fast, non-expiring, keyring-free hydration but accumulates no outage cache at
all. That matters here specifically because Infisical self-hosts on a VM whose
underlying NVMe wedges periodically — the outage this cache exists for is a
recurring local event, not a hypothetical.

The resulting local design is deliberately split: machine identity as the
primary path (least-privilege, sub-second, no Secret Service dependency), and
a periodic manual `infisical login` retained purely to keep the cache warm.
Automating that second step was considered and rejected: the only non-
interactive user-login mechanism the CLI offers takes an account password,
and putting an org-scoped credential at rest to protect a Viewer-scoped one
inverts the privilege gradient. A throttled background `infisical login
status` probe surfaces the lapse instead, since nothing else does until the
cache is needed and found stale.

Two consequences worth carrying forward. First, the KWallet apparatus on this
host is now a durability concern (cache freshness) rather than an availability
one (shell startup), because the primary path never touches the Secret
Service. Second, if upstream ever restores the refresh call site, the manual
step and its nag can both be deleted — the machine-identity path is unaffected
either way.
