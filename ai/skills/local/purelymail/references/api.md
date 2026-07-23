# Purelymail API reference

Source: `https://news.purelymail.com/api/swagger-spec.js` (the JSON OpenAPI spec
backing the rendered Swagger UI at `https://news.purelymail.com/api/index.html`),
fetched directly on 2026-07-12. Field names/types below are transcribed from
that spec, not from memory or a screen-scrape of the rendered page.

- **Base URL**: `https://purelymail.com`
- **Auth**: header `Purelymail-Api-Token: <token>`
- **All endpoints**: `POST /api/v0/<name>`, JSON request body, JSON response
- **Success shape**: `{"result": {...}}` (200) — documented in the spec for
  every endpoint
- **Error shape**: **not documented** in the spec for any endpoint. An `Error`
  schema (`code`, `message`) exists in `components.schemas` but is not
  referenced by any path's `responses`. Treat any non-2xx status, or a 200
  body without a `result` key, as an error — this is an inference `pmctl`
  makes, not a spec guarantee.

## User management

### `createUser`
Request (`CreateUserRequest`):
- `userName` (string, required) — local part only
- `domainName` (string, required)
- `password` (string, required)
- `enablePasswordReset` (boolean, optional, default `true`)
- `recoveryEmail` (string, optional)
- `recoveryEmailDescription` (string, optional)
- `recoveryPhone` (string, optional)
- `recoveryPhoneDescription` (string, optional)
- `enableSearchIndexing` (boolean, optional, default `true`)
- `sendWelcomeEmail` (boolean, optional, default `true`)

Response: `EmptyResponse` (`{}`)

### `deleteUser` — DESTRUCTIVE
Request (`DeleteUserRequest`):
- `userName` (string, required) — full username (user@domain)

Response: `EmptyResponse`

### `listUser`
Request: `EmptyRequest` (`{}`)
Response (`ListUserResponse`):
- `users` (array of strings, required)

### `modifyUser`
Request (`ModifyUserRequest`):
- `userName` (string, required) — full username
- `newUserName` (string, optional)
- `newPassword` (string, optional)
- `enableSearchIndexing` (boolean, optional)
- `enablePasswordReset` (boolean, optional)
- `requireTwoFactorAuthentication` (boolean, optional)

Response: `EmptyResponse`

### `getUser`
Request (`GetUserRequest`):
- `userName` (string, required) — full username

Response (`GetUserResponse`):
- `enableSearchIndexing` (boolean, required)
- `recoveryEnabled` (boolean, required)
- `requireTwoFactorAuthentication` (boolean, required)
- `enableSpamFiltering` (boolean, required)
- `resetMethods` (array of `GetUserPasswordResetMethod`, required)

### `createAppPassword`
Request (`CreateAppPassword`):
- `userHandle` (string, required) — full `user@domain.com`
- `name` (string, optional, default `""`)

Response (`CreateAppPasswordResponse`):
- `appPassword` (string, required) — generated secret; `pmctl` does not log
  this value in full to any persistent log

### `deleteAppPassword` — DESTRUCTIVE
Request (`DeleteAppPasswordRequest`):
- `userName` (string, required) — full username
- `appPassword` (string, required)

Response: `EmptyResponse`

## Password reset

### `upsertPasswordReset`
Request (`UpsertPasswordResetRequest`):
- `userName` (string, required)
- `existingTarget` (string, optional) — set to update an existing method
- `type` (string, required) — `"email"` or `"phone"`
- `target` (string, required) — the email address or phone number
- `description` (string, optional, default `""`)
- `allowMfaReset` (boolean, optional, default `true`)

Response: `EmptyResponse`

### `deletePasswordReset` — DESTRUCTIVE
Request (`DeletePasswordResetRequest`):
- `userName` (string, required)
- `target` (string, optional)

Response: `EmptyResponse`

### `listPasswordReset`
Request (`ListPasswordResetRequest`):
- `userName` (string, required)

Response (`ListPasswordResetResponse`):
- `users` (array of `ListPasswordResetResponseItem`, required)

## Routing (aliases, forwards, catchalls)

### `createRoutingRule`
Request (`CreateRoutingRequest`):
- `domainName` (string, required)
- `prefix` (boolean, required) — whether `matchUser` is a prefix match
- `matchUser` (string, required) — local part of the address to match
- `targetAddresses` (array of strings, required) — destination address(es)
- `catchall` (boolean, optional, default `false`)

Response: `EmptyResponse`

### `deleteRoutingRule` — DESTRUCTIVE
Request (`DeleteRoutingRequest`):
- `routingRuleId` (integer/int64, required)

Response: `EmptyResponse`

### `listRoutingRules`
Request: `EmptyRequest`
Response (`ListRoutingResponse`):
- `rules` (array of `RoutingRule`, required)

## Domains

### `addDomain`
Request (`AddDomainRequest`):
- `domainName` (string, required)

Response: `EmptyResponse`

### `getOwnershipCode`
Request: `EmptyRequest`
Response (`GetOwnershipCodeResponse`):
- `code` (string, required) — TXT record value for domain verification

### `listDomains`
Request (`ListDomainsRequest`):
- `includeShared` (boolean, optional, default `false`)

Response (`ListDomainsResponse`):
- `domains` (array of `ApiDomainInfo`, required)

### `updateDomainSettings`
Request (`UpdateDomainSettingsRequest`):
- `name` (string, required)
- `allowAccountReset` (boolean, optional)
- `symbolicSubaddressing` (boolean, optional)
- `recheckDns` (boolean, optional, default `false`)

Response: `EmptyResponse`

### `deleteDomain` — DESTRUCTIVE
Request (`DeleteDomainRequest`):
- `name` (string, required)

Response: `EmptyResponse`

## Billing

### `checkAccountCredit`
Request: `EmptyRequest`
Response (`CheckCreditResponse`):
- `credit` (string, required) — decimal string, precision 64

## Gaps / not verified

- Nested object schemas referenced above by name only
  (`GetUserPasswordResetMethod`, `ListPasswordResetResponseItem`,
  `RoutingRule`, `ApiDomainInfo`) were summarized by field count/purpose in
  the fetched spec but their individual field names were not enumerated in
  the fetch result used to write this doc. Before relying on a specific
  nested field name (e.g. reading a `RoutingRule`'s exact property for its
  ID), re-fetch `https://news.purelymail.com/api/swagger-spec.js` and check
  `components.schemas.<Name>` directly rather than assuming a name.
- The actual runtime error response shape is unverified against a live
  account (see "Error shape" above) — this is a documentation gap in the
  upstream spec, not something resolvable by re-reading it.
