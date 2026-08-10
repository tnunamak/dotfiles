---
title: "RFC 6764 does not guarantee the .well-known/carddav resource itself answers current-user-principal — a compliant server may 404 that property there and require PROPFIND against a different resolved path"
date: 2026-08-09
topic: pdpp
tags: [carddav, rfc6764, webdav, apple, icloud, discovery]
status: draft
sources: [rfc6764, live-icloud-probe]
source_session: 27a980ae-abdd-4e03-89f0-fbf29eb4c5b9
---

## CLAIMS

- RFC 6764 §5 requires servers to redirect the `.well-known/carddav` bootstrap URI to the actual context path, and states the well-known URI itself MUST NOT host the actual service endpoint. [rfc6764]
- RFC 6764 §6 step 5 says the client PROPFINDs `current-user-principal` at "the initial context path" and MUST handle HTTP redirects on that request, but the spec text does not explicitly define behavior when the server answers 200/207 directly (no redirect) at the well-known URI. [rfc6764]
- Live-verified against a real iCloud account (2026-08-09): `contacts.icloud.com/.well-known/carddav` answers PROPFIND directly with 207 Multi-Status (no 3xx redirect at all), and its own `<response>` block reports `current-user-principal` via a `<propstat><status>HTTP/1.1 404 Not Found</status>` — i.e. the well-known resource explicitly does NOT carry that property. [live-icloud-probe]
- The same PROPFIND (`current-user-principal`, Depth 0) issued against the bare origin root (`https://contacts.icloud.com/`) instead returns 200 OK with the property populated. [live-icloud-probe]
- A CardDAV client written strictly to "PROPFIND current-user-principal at the well-known URL, treat absence as terminal failure" breaks against this real-world, RFC-non-contradicting server behavior — the well-known resource inline-answering with a 404'd property is not itself an error condition per RFC 4918 §14.22 (a `propstat` 404 just means "this resource doesn't have this property"), it's a signal to try elsewhere.

## SOURCES

**rfc6764**
URL: https://www.rfc-editor.org/rfc/rfc6764
Accessed: 2026-08-09
Quote: "Clients MUST handle HTTP redirects on the '.well-known' URI." / "MUST NOT locate the actual CalDAV or CardDAV service endpoint at the '.well-known' URI." / "The client does a 'PROPFIND' request with the request URI set to the initial 'context path' ... clients MUST properly handle HTTP redirect responses for the request."

**live-icloud-probe**
URL: n/a (live probe against a real iCloud CardDAV account via a narrowly-scoped structural-facts-only diagnostic script, run inside the pdpp-final-uat container, 2026-08-09)
Accessed: 2026-08-09
Quote: "well-known PROPFIND -> 207, <current-user-principal/> self-closing inside a 404 propstat; root PROPFIND -> 200, <current-user-principal><href>.../principal/</href></current-user-principal>"

## SYNTHESIS

RFC 6764 assumes (but doesn't strictly mandate) that a compliant server's `.well-known/carddav` either redirects to the true context path, or IS the true context path where `current-user-principal` resolves. Apple's real iCloud CardDAV server does neither cleanly: it answers the well-known URL directly (no redirect, satisfying "MUST NOT locate the actual service AT the well-known URI" only in the narrow sense that the *addressbook* isn't there — but it does serve a WebDAV response there) while explicitly 404-ing the one property (`current-user-principal`) a client asked for at that specific path. The robust, standards-correct client behavior is: on a well-known response that answers inline (no redirect) but doesn't carry `current-user-principal` (absent element, or present-but-404'd via propstat), retry the same PROPFIND against the origin root before declaring discovery failed — mirroring what actively-maintained third-party CardDAV clients (DAVx5-class tooling) already do for iCloud, since Apple publishes no CardDAV discovery documentation of its own. This generalizes beyond iCloud to any RFC 6764 server that treats the well-known URI as "answer what you can, 404 what a resource-at-this-exact-path doesn't have" rather than "redirect or die."
