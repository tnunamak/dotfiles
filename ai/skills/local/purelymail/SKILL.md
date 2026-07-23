---
name: purelymail
description: Manage a Purelymail email hosting account (purelymail.com) via its REST API — users, mailboxes, app passwords, password-reset methods, routing rules/aliases/catchalls, domains, and billing credit. Use when the user asks to add/remove a mailbox, set up an alias or forward, configure a catchall, add or verify a domain, rotate an app password, or check Purelymail account credit. Triggers on "purelymail", "add a mailbox", "email alias", "catchall address", "routing rule", "app password for email".
---

# Purelymail (`pmctl`)

Wrapper around the Purelymail REST API (`https://purelymail.com/api/v0/*`). All
endpoints are POST-only with a JSON body and a `Purelymail-Api-Token` header.
There is no partial-update semantics beyond what each endpoint documents —
read the current state before writing, always.

## Setup

`PURELYMAIL_API_TOKEN` must be set in the environment. `pmctl` reads it from
there only — **never** pass the token as a CLI argument (it would leak into
shell history and `ps`).

```
export PURELYMAIL_API_TOKEN=...   # from https://purelymail.com -> Settings -> API
```

If the token isn't set, `pmctl` refuses immediately with a clear error. Do not
look for it in Infisical, browser storage, or any secrets manager on this
user's behalf — get it from the user or their existing shell environment only.

## Using `pmctl`

```
scripts/pmctl <endpoint> [--data-file <path> | --data-stdin] [--secret-output-file <path>]
scripts/pmctl <endpoint> < body.json
```

- `<endpoint>` is the bare operation name, e.g. `listUser`, `createRoutingRule`,
  `deleteDomain` — see `references/api.md` for the full list and exact field
  names/types for each request body.
- Request bodies are always JSON. Pass them via `--data-file <path>`, via
  stdin (`--data-stdin` or just piping/redirecting in), or omit the body
  entirely for endpoints that take an empty request (e.g. `listUser`,
  `checkAccountCredit`). **Never** put field values (passwords, tokens,
  recovery targets) as argv — always via file/stdin so they don't appear in
  process listings or shell history.
- Secrets are never echoed: `pmctl` supplies the token through curl's stdin
  config, request JSON through a mode-`0600` temporary file, and requires
  `--secret-output-file` for generated app-password responses.

Examples:

```
echo '{}' | scripts/pmctl listUser
scripts/pmctl checkAccountCredit
printf '{"userName":"me@example.com","appPassword":"redacted","name":"laptop"}' \
  | scripts/pmctl deleteAppPassword --data-stdin
```

## Read-before-write

Before any create/modify/delete call, run the corresponding `list*`/`get*` call
first and show the user the current state relevant to the change. This repo's
`AGENTS.md` house rule ("verify behavior first") applies here as much as it
does to code — Purelymail has no dry-run and no undo for most operations.

- Before `createRoutingRule` — run `listRoutingRules`, check for an existing
  rule on the same `matchUser`/`domainName` to avoid duplicate/conflicting
  routes.
- Before `modifyUser` / `deleteUser` — run `listUser` (or `getUser` for the
  specific account) to confirm the exact `userName` you intend to touch.
- Before `deleteDomain` — run `listDomains` and confirm mailbox/routing
  dependents won't silently break; Purelymail does not cascade-warn.
- Before `upsertPasswordReset` / `deletePasswordReset` — run
  `listPasswordReset` to see existing methods so you don't strand the account
  without a reset path.

## Destructive operations require explicit confirmation

`pmctl` treats these endpoints as destructive and refuses to run them unless
`PMCTL_CONFIRM_DESTRUCTIVE=yes` is set for that invocation:

- `deleteUser`
- `deleteDomain`
- `deleteRoutingRule`
- `deleteAppPassword`
- `deletePasswordReset`

This is a deliberate speed bump, not a rubber stamp — as the agent, get the
user's explicit go-ahead for the specific target (which user/domain/rule) in
the conversation before setting the env var and re-running. Don't set it
preemptively "to save a round trip."

```
PMCTL_CONFIRM_DESTRUCTIVE=yes scripts/pmctl deleteDomain --data-stdin <<<'{"name":"old-domain.com"}'
```

## Task playbook

- **Add a mailbox**: `createUser` (domainName + userName + password). Read
  `references/api.md` for the optional recovery/2FA/welcome-email fields
  first — decide with the user whether `sendWelcomeEmail` should be `false`
  for bulk provisioning.
- **Alias / forward an address to another mailbox**: `createRoutingRule` with
  `prefix: false`, `matchUser` set to the local part, `targetAddresses`
  pointing at the destination(s). Check `listRoutingRules` first for clashes.
- **Catchall for a domain**: `createRoutingRule` with `catchall: true` and
  `matchUser` typically `""`/domain-wide per the field's semantics in
  `references/api.md` — confirm current routing rules don't already define
  one before creating a second.
- **Diagnose DNS / domain verification**: `getOwnershipCode` then
  `updateDomainSettings` with `recheckDns: true`; `listDomains` to see current
  verification status.
- **Add a new domain**: `addDomain`, then `getOwnershipCode`, have the user
  place the TXT record, then `updateDomainSettings` with `recheckDns: true`
  to trigger re-verification.
- **Rotate an app password**: `createAppPassword` for the new one first,
  update the consuming client, confirm it works, only then
  `deleteAppPassword` the old one (destructive — needs confirmation, see
  above).

## Error handling caveat

The published OpenAPI spec (`references/api.md`) documents only the HTTP 200
success shape (`{"result": {...}}`) for every endpoint — no endpoint has a
documented error response shape, though an `Error` schema (`code`, `message`)
exists unused in the spec's `components.schemas`. `pmctl` treats non-2xx HTTP
status as failure, and additionally treats a 200 body containing a top-level
`error` or `code`/`message` pair (no `result` key) as failure, since that
matches the unused schema. This is an inference from the spec, not a
documented guarantee — if you hit an error shape `pmctl` doesn't recognize,
show the user the raw response rather than guessing at its meaning.

## Verifying this skill (offline only)

`tests/test_pmctl.sh` exercises `pmctl` entirely offline (a fake `curl` on
`PATH`, no network, no live account). Run it after any change to `pmctl`:

```
bash ai/skills/local/purelymail/tests/test_pmctl.sh
```

Do not test against the live Purelymail API from an agent session — no
mailbox, domain, or billing state on a real account should be touched by
skill development or verification.
