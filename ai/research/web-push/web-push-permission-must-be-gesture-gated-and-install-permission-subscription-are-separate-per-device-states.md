---
title: "Web Push permission must be requested from an explicit user gesture in a settings surface, and PWA install, notification permission, service-worker/PushManager subscription, and delivery are separate per-browser/per-device states"
date: 2026-07-05
topic: web-push
tags: [web-push, notifications-api, push-api, pwa, permission-ux, service-worker]
status: draft
sources: [mdn-notifications-using, mdn-request-permission, mdn-push-api, mdn-pushmanager, webdev-permission-ux, chromium-quieter, webkit-web-push, apple-web-push, w3c-push-api]
source_session: 019e284d-1564-74e0-b1af-5b55f729f4ee
---

## CLAIMS

- MDN says notification permission should be requested only in response to a user gesture, and modern browsers increasingly enforce or penalize non-gesture prompts. [mdn-notifications-using][mdn-request-permission]
- web.dev recommends moving notification enablement into a settings panel rather than prompting on first load. [webdev-permission-ux]
- Chromium shipped a "quieter permission UI" for notifications specifically because unsolicited permission prompts are a poor user experience. [chromium-quieter]
- The web platform separates app installation, notification permission, service-worker registration, and `PushManager` subscription; Web Push subscription is done through a service worker via `ServiceWorkerRegistration.pushManager`, and WebKit documents iOS/iPadOS Web Push specifically for Home Screen web apps. [mdn-push-api][mdn-pushmanager][webkit-web-push][apple-web-push]
- Installing a PWA gives an app shell and launch surface but does not by itself subscribe the device or guarantee notification display. [webkit-web-push][apple-web-push]
- Web Push subscriptions are browser/device artifacts exposed through `ServiceWorkerRegistration.pushManager` and can be present, absent, revoked, stale, or blocked independently on each browser profile and installed app. [mdn-pushmanager][w3c-push-api]
- The Push API gives the service worker a delivery path even when the web app is inactive, and a notification click can route to a specific URL/action via the service worker. [mdn-push-api][w3c-push-api]

## SOURCES

**mdn-notifications-using**
URL: https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API
Accessed: 2026-07-05

**mdn-request-permission**
URL: https://developer.mozilla.org/en-US/docs/Web/API/Notification/requestPermission_static
Accessed: 2026-07-05

**mdn-push-api**
URL: https://developer.mozilla.org/en-US/docs/Web/API/Push_API
Accessed: 2026-07-05

**mdn-pushmanager**
URL: https://developer.mozilla.org/en-US/docs/Web/API/ServiceWorkerRegistration/pushManager
Accessed: 2026-07-05

**webdev-permission-ux**
URL: https://web.dev/articles/push-notifications-permissions-ux
Accessed: 2026-07-05

**chromium-quieter**
URL: https://blog.chromium.org/2020/01/introducing-quieter-permission-ui-for.html
Accessed: 2026-07-05

**webkit-web-push**
URL: https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/
Accessed: 2026-07-05

**apple-web-push**
URL: https://developer.apple.com/documentation/usernotifications/sending-web-push-notifications-in-web-apps-and-browsers
Accessed: 2026-07-05

**w3c-push-api**
URL: https://www.w3.org/TR/push-api/
Accessed: 2026-07-05

## SYNTHESIS

The platform constraints (stable, sourced from MDN, W3C, WebKit/Apple, web.dev, Chromium) yield a clear SLVP shape for enabling Web Push in a PWA:

- Request notification permission only after an explicit user click, ideally from a dedicated notifications/settings surface — never on page load, during setup, or after a background event.
- Do not conflate states in the UI: show install/open-correct-device, browser permission, service-worker/subscription, server-side subscription/delivery, and a test-delivery step as distinct states. "Installed PWA" does not equal "notifications enabled."
- Frame enablement as per-device/per-browser-profile ("enable this device"), not per-account, and tell multi-device users each phone/desktop/installed-app profile is configured separately.
- Route notification clicks to the concrete action surface, with a safe fallback URL; the service worker should allow only known-good routes and reject stale/legacy paths.
- For clean-route migrations, account for already-installed PWAs that may retain old app metadata or restore a last-window URL: provide a bounded migration/repair path (time-bounded route shim, migration page, or install-repair affordance) so a stale install does not open to a raw 404, rather than supporting legacy URLs indefinitely.

Anti-patterns: prompting on first load; treating install as subscription; hiding notification setup in an unrelated page; rendering the setup component only in tests with no real route; sending clicks to a generic home when a concrete action is known; and removing legacy launch paths with no migration path for installed PWAs.
