---
title: "Komodo key expiry requires replacement and resource scope belongs to users"
date: 2026-09-09
topic: self-hosting
tags: [komodo, credentials, automation, permissions]
status: settled
sources: [creation, model, auth, management]
source_session: unknown
---

## CLAIMS

- Komodo v2.3.3 offers 90-day, 180-day, one-year and Never expiry choices; Never is represented by zero. [creation]
- Authentication skips expiry rejection for zero, and resolves the key's associated user. Invalid credentials can mean expiry, wrong credentials or an unavailable user; HTTP401 alone does not distinguish them. [auth]
- The key model has user ownership but no per-key resource scopes. [model]
- Supported key management creates and deletes keys; it has no expiry-renewal operation. [management]

## SOURCES

**creation**
URL: https://github.com/moghtech/komodo/blob/v2.3.3/ui/src/components/api-keys/new.tsx
Accessed: 2026-09-09

**model**
URL: https://github.com/moghtech/komodo/blob/v2.3.3/client/core/rs/src/entities/api_key.rs
Accessed: 2026-09-09

**auth**
URL: https://github.com/moghtech/komodo/blob/v2.3.3/bin/core/src/auth/middleware.rs
Accessed: 2026-09-09

**management**
URL: https://github.com/moghtech/komodo/blob/v2.3.3/bin/core/src/auth/api_key.rs
Accessed: 2026-09-09

## SYNTHESIS

A separately named deployment key improves attribution and independent revocation, not authorization scope. Use a restricted service user to restrict resources. Finite expiry needs actual monitored rotation; Never avoids surprise expiry but requires deliberate revocation and careful storage. Replace keys through supported management rather than editing the database. Remove confirmed expired keys after recording ownership; do not delete an active operator key merely because its name is untidy.
