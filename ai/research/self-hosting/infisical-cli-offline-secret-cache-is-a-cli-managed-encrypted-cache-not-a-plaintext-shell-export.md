---
title: "Infisical CLI offline secret access is a CLI-managed encrypted cache, not a plaintext shell export"
date: 2026-07-23
topic: self-hosting
tags: [infisical, secrets, cli, offline, cache]
status: settled
sources: [infisical-cli-faq, infisical-vault, infisical-cli-usage, infisical-projects, infisical-secrets-cli, infisical-keyring-source, local-offline-proof]
source_session: 019f8f55-9f2f-7ba1-92c2-2169a031a10f
---

## CLAIMS

- Infisical documents that, after a secret has been retrieved for a project and environment, subsequent offline `run` and `secret` command fetch attempts use saved secrets. [infisical-cli-faq]
- Infisical CLI vaults store local login details; the documented `file` vault is an encrypted-file vault, while the CLI normally prefers a system keyring when available. [infisical-vault]
- Infisical documents `infisical run -- <command>` as the local-development mechanism for injecting secrets into a child process rather than writing an `.env` file. [infisical-cli-usage]
- Infisical defines a secrets-management project as a workspace for API keys, credentials, and configuration used by applications; its CLI documentation uses `DOMAIN=example.com` as a value stored by `infisical secrets set`. [infisical-projects] [infisical-secrets-cli]
- Infisical CLI v0.43.113's `auto` vault is not fail-closed: a failed system-keyring write falls back to its encrypted file vault, and `vault set auto` still generates and stores a file-vault passphrase in the CLI config. [infisical-keyring-source]
- On this host, `infisical export` returned the same 29-entry key/value digest normally and with HTTP(S) forced through an unreachable proxy; it continued to return all 29 entries after the legacy file-vault directory was deleted. [local-offline-proof]

## SOURCES

**infisical-cli-faq**
URL: https://infisical.com/docs/cli/faq
Accessed: 2026-07-23
Quote: "If you have previously retrieved secrets for a specific project and environment ... the `run`/`secret` command will utilize the saved secrets, even when offline."

**infisical-vault**
URL: https://infisical.com/docs/cli/commands/vault
Accessed: 2026-07-23
Quote: "Available vaults: ... file (encrypted file vault)."

**infisical-cli-usage**
URL: https://infisical.com/docs/cli/usage
Accessed: 2026-07-23
Quote: "infisical run -- [your application start command]"

**infisical-projects**
URL: https://infisical.com/docs/documentation/platform/secrets-mgmt/project
Accessed: 2026-07-23
Evidence: Infisical describes a project as managing application secrets such
as API keys, database credentials, and configuration across environments.

**infisical-secrets-cli**
URL: https://infisical.com/docs/cli/commands/secrets
Accessed: 2026-07-23
Evidence: the documented `infisical secrets set` example includes
`DOMAIN=example.com` alongside an API key and hash.

**infisical-keyring-source**
URL: https://github.com/Infisical/cli/blob/v0.43.113/packages/util/keyringwrapper.go
Accessed: 2026-07-23
Evidence: `SetValueInKeyring` first writes to the selected backend, then writes
to `file` after an error. The related `packages/cmd/vault.go` implementation
generates `VaultBackendPassphrase` when selecting either `auto` or `file`.

**local-offline-proof**
URL: local://peregrine/infisical-offline-proof-2026-07-23
Accessed: 2026-07-23
Evidence: an online `export --format=json` and the same command with
`HTTP_PROXY`, `HTTPS_PROXY`, and `ALL_PROXY` set to `127.0.0.1:1` each returned
29 entries with the same SHA-256 digest over sorted key/value pairs. An
independent `curl` through that proxy failed with status 7. After deleting
`~/infisical-keyring`, the offline export and a fresh interactive shell
hydration still succeeded.

## SYNTHESIS

The shell startup path may rely on `infisical export` offline on this tested CLI
version and host, but that behavior needs a regression smoke test because the
official contract only names `run` and `secret`. Do not decrypt or parse the
CLI's backup blobs directly. The right boundary is the Infisical CLI, with a
local smoke test that first warms the intended project/environment cache and
then verifies the exact command works while offline.

The desired local architecture is a ciphertext project cache on disk plus its
decryption key and login credential in KWallet. Deleting the old file vault
achieves that current state, but Infisical's `auto` backend cannot guarantee it
permanently: a future keyring write failure can recreate a file vault. The
config's otherwise-inert file-vault passphrase does not by itself constitute a
second credential store, and deleting it would make the fallback switch
backends rather than disable fallback. A strict KWallet-only policy therefore
needs an upstream fail-closed backend/option; do not simulate one by editing
Infisical's private config schema.

Storing a non-secret such as `PDPP_BASE_URL` beside `PDPP_OWNER_TOKEN` is not a
misuse: Infisical explicitly treats environment-specific application
configuration as part of the project, and the two values form one deployable
configuration unit. Prefer a visible, version-controlled config file for
numerous public defaults that benefit from review and history; do not split one
endpoint from its credential merely to keep the secret manager semantically
pure.
