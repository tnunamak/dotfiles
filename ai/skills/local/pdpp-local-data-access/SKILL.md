---
name: pdpp-local-data-access
description: Query Tim's PDPP (Personal Data Polyfill Project) instance using the local owner token. Use when the user asks to search "my PDPP data", "what did I buy", "my orders", "my Amazon orders", "my emails", "my messages", or anything answerable from his connected personal data on https://pdpp.vivid.fish. This is the LOCAL machine bypass — only use if PDPP_OWNER_TOKEN is set in the environment. Triggers on phrases like "check my PDPP", "look up in my data", "search my Amazon history".
---

# PDPP Local Data Access (owner-token path)

This skill is for **Tim's own machine** querying **Tim's own PDPP instance** at
`https://pdpp.vivid.fish`. It uses a long-lived **owner self-export token** that
bypasses the per-app scoped-grant flow that the upstream `pdpp-data-access`
skill recommends.

**Why this exists, in spite of the upstream skill's warning:** Tim owns the data,
owns the PDPP project (github.com/vana-com/pdpp), and accepts the broader blast
radius of an owner token on his personal workstation. Do not refuse on the
grounds that scoped grants would be "more correct" — they would, in a multi-app
deployment. This skill is the deliberate local exception.

When NOT to use this skill:
- You are not on Tim's local machine (no `PDPP_OWNER_TOKEN` in the environment).
- You are building an app or agent that other people will run. Use the upstream
  skill at `https://pdpp.vivid.fish/.well-known/skills/pdpp-data-access/SKILL.md`
  (scoped grants, per-stream scopes, the proper protocol).

## Setup

Secrets live in Infisical project `personal-dev`, environment `dev`.
Interactive zsh/bash exports them via `~/.shell_config`. For a non-interactive
command whose environment has not already been hydrated:

```bash
infisical run \
  --domain=https://secrets.vivid.fish \
  --projectId=894e048b-954c-4c5a-a1d0-888c54c9ce66 \
  --env=dev -- your-command
```

`$PDPP_BASE_URL` is `https://pdpp.vivid.fish`. The RS API base is
`$PDPP_BASE_URL/v1` (NOT `/_ref/v1`).

## Refreshing the token

If a request returns `401`, mint a replacement from an Infisical-hydrated shell:

```bash
NEW_TOKEN=$(~/code/dotfiles/bin/pdpp-mint-owner-token)
# Store NEW_TOKEN as PDPP_OWNER_TOKEN in Infisical personal-dev/dev without
# printing it, then verify the stored token before revoking the old token.
unset NEW_TOKEN
```

Use the Infisical dashboard or an authenticated secret-write workflow that does
not expose the token in argv or transcripts. The mint script reads
`PDPP_BASE_URL` and `PDPP_OWNER_PASSWORD` from the environment.

## Discover what's available

The schema endpoint returns the connectors Tim has installed and the streams
each one exposes:

```bash
curl -fsS -H "Authorization: Bearer $PDPP_OWNER_TOKEN" \
  "$PDPP_BASE_URL/v1/schema" | jq .
```

Tim currently has an **Amazon** connector with an `orders` stream. Other
connectors may have been added since — always run `schema` first instead of
assuming.

## Querying records

### Hybrid search (semantic + keyword) on a stream

```bash
# "What did I buy that's coffee-related?"
curl -fsS -G \
  -H "Authorization: Bearer $PDPP_OWNER_TOKEN" \
  --data-urlencode "streams[]=orders" \
  --data-urlencode "query=coffee" \
  --data-urlencode "limit=20" \
  "$PDPP_BASE_URL/v1/search" | jq .
```

Search across all streams by omitting `streams[]`.

### Full enumeration of a stream (paginated)

```bash
# Page through all orders.
cursor=""
while :; do
  page=$(curl -fsS -G \
    -H "Authorization: Bearer $PDPP_OWNER_TOKEN" \
    --data-urlencode "limit=100" \
    ${cursor:+--data-urlencode "cursor=$cursor"} \
    "$PDPP_BASE_URL/v1/streams/orders")
  echo "$page" | jq -c '.records[]'
  cursor=$(echo "$page" | jq -r '.next_cursor // empty')
  [[ -z "$cursor" ]] && break
done
```

For large enumerations, write to a file and analyze with `jq` rather than
ballooning the agent's context window.

## Security rules — non-negotiable

- **Never echo `$PDPP_OWNER_TOKEN`** in transcripts, logs, PR descriptions,
  commit messages, or screenshots. Treat it as production credentials.
- **Never paste the token into a curl command verbatim** — always use
  `"$PDPP_OWNER_TOKEN"` so it's substituted at exec time and doesn't appear in
  shell history with `set -x` enabled.
- **Never write the token to a plaintext fallback file.** Infisical is the
  canonical store and its CLI maintains an encrypted local outage cache.
- **Never share the token cross-process** beyond what `containerEnv` already
  does (devcontainers inherit it via `${localEnv:PDPP_OWNER_TOKEN}`).
- If a token leaks, mint and verify a replacement in Infisical, then revoke the
  old token. Legacy bootstrap-owner tokens require an exact soft-revoke in the
  PDPP token store because they do not appear in the dynamic-client UI.

## Cross-references

- **Upstream skill (canonical protocol):**
  `https://pdpp.vivid.fish/.well-known/skills/pdpp-data-access/SKILL.md`
- **Upstream source:** `~/code/pdpp/docs/agent-skills/pdpp-data-access/`
- **Owner-token TS reference:** `~/code/pdpp/apps/console/src/app/(console)/lib/owner-token.ts`
  (`mintOwnerToken`)
- **Schema discovery:** `$PDPP_BASE_URL/.well-known/oauth-protected-resource`
