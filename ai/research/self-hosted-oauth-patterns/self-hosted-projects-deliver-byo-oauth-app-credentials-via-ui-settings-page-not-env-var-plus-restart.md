---
title: "Self-hosted, user-owned software projects (Home Assistant, n8n, Immich, Nextcloud) universally require the operator to register their own OAuth app with the provider, but deliver the resulting client_id/secret via a DB-backed UI settings page with no restart, not env-var-only config"
date: 2026-08-07
topic: self-hosted-oauth-patterns
tags: [oauth, self-hosted, byo-app, ui-settings, home-assistant, n8n, immich, google-oauth-verification]
status: draft
sources: [home-assistant-app-credentials, home-assistant-cloud, n8n-oauth2-google, n8n-credential-overwrites, nextcloud-oauth2-provider, nextcloud-user-oidc, immich-oauth, jellyfin-sso-plugin, google-sensitive-scope-verification, google-unverified-apps]
source_session: 657d2c05-ec11-4605-aca4-8cda9b5b6b71
---

## CLAIMS

- Home Assistant's "Application Credentials" feature (added HA 2022.6) requires the user/admin to register their own OAuth client with the provider, then paste client_id/client_secret into a dedicated UI page (Settings → Devices & Services → Application Credentials); values take effect immediately, no core restart. [home-assistant-app-credentials]
- Home Assistant developer docs explicitly instruct that new integrations should NOT accept OAuth credentials via `configuration.yaml` — only legacy integrations import old YAML-configured credentials through a one-time migration path. [home-assistant-app-credentials]
- Home Assistant Cloud (Nabu Casa, a paid subscription service) is the only path in the HA ecosystem that ships a shared/pre-registered OAuth app so self-hosters skip registration entirely — it is explicitly a paid companion service, not something baked into HA core. [home-assistant-cloud]
- n8n's Google OAuth2 credential type (self-hosted) requires the user to paste their own client_id/secret obtained from Google Cloud Console into the credentials UI; there is no default/shared app for self-hosted instances. [n8n-oauth2-google]
- n8n offers "Managed OAuth2" (one-click, no setup) only on n8n Cloud, the hosted multi-tenant SaaS product — explicitly documented as unavailable for self-hosted n8n. [n8n-oauth2-google]
- n8n's self-hosted "credential overwrites" feature lets an instance admin inject a Client ID/Secret at process startup (env/config), which then surfaces as a one-click "Managed OAuth2 (recommended)" option in the credentials UI for every user of that instance — the admin still does one BYO registration, but end users of a shared instance get zero-setup OAuth. [n8n-credential-overwrites]
- n8n's credential-overwrites values are injected at startup, so changing the instance-level shared app requires a restart; per-user OAuth2 credentials entered via the normal UI take effect immediately with no restart. [n8n-credential-overwrites]
- Nextcloud's own OAuth2-provider admin UI (Settings → Administration → Security → "Add client") is entirely UI-driven with no config-file involvement, for registering third-party OAuth clients against Nextcloud itself. [nextcloud-oauth2-provider]
- Nextcloud's `user_oidc` app (Nextcloud as an OIDC consumer of an external IdP) is mostly UI-driven (Settings → Administration → OpenID Connect: client ID/secret/issuer), but some behavior flags require `occ` CLI commands and some networking edge cases require direct `config.php` edits — a genuinely mixed model, called out by integrators as confusing. [nextcloud-user-oidc]
- Immich's OAuth/OIDC login configuration is 100% UI-driven: Administration → Settings → Authentication Settings → OAuth, where the admin pastes Issuer URL, Client ID, Client Secret, Scope, and Button Text for any OIDC-compliant IdP; no env-var path is documented for this configuration, and no restart is required (DB-backed runtime settings). [immich-oauth]
- Jellyfin's SSO plugin (third-party, not core Jellyfin) is UI-driven for entering the OIDC discovery endpoint, Client ID, and Client Secret, but explicitly and repeatedly documented as requiring a Jellyfin restart after saving — called out by multiple community sources as a known limitation of Jellyfin's plugin-loading architecture, not a deliberate design choice. [jellyfin-sso-plugin]
- Google classifies Calendar (`calendar.readonly`) and Contacts (`contacts.readonly`) scopes as "sensitive," the lighter of Google's two OAuth review tiers — not "restricted" (which covers Gmail/Drive/health-adjacent data and requires an annual paid CASA security assessment). [google-sensitive-scope-verification]
- Google caps unverified ("Testing" status) OAuth apps at 100 test users total for the lifetime of the Cloud project, with no reset without publishing; each test user must be added individually by email in Cloud Console. [google-unverified-apps]
- Google auto-invalidates refresh tokens after 7 days for apps in Testing publishing status, forcing weekly re-authorization until the app is published/verified. [google-unverified-apps]
- Google explicitly exempts personal-use, dev/test/staging, and internal-only (Google Workspace) apps from its sensitive/restricted-scope verification requirement. [google-unverified-apps]
- Google's sensitive-scope verification (when required) demands a hosted privacy policy on the same verified domain, a home page describing app functionality, Search Console domain-ownership verification for every referenced domain, and a demo video (unlisted YouTube) showing the OAuth consent flow and actual use of each sensitive scope; turnaround is typically days to a few weeks. [google-sensitive-scope-verification]

## SOURCES

**home-assistant-app-credentials**
URL: https://www.home-assistant.io/integrations/application_credentials/ ; https://developers.home-assistant.io/docs/core/platform/application_credentials/ ; https://www.home-assistant.io/integrations/google/
Accessed: 2026-08-07
Quote: "new integrations should not accept credentials via configuration.yaml" (developer docs, Application Credentials platform page)

**home-assistant-cloud**
URL: https://www.home-assistant.io/integrations/application_credentials/
Accessed: 2026-08-07
Quote: "Cloud Account Linking via Home Assistant Cloud / Nabu Casa... the recommended approach when available" (paraphrase of docs framing; requires Nabu Casa subscription)

**n8n-oauth2-google**
URL: https://docs.n8n.io/integrations/builtin/credentials/google/oauth-single-service ; https://docs.n8n.io/integrations/builtin/credentials/google/oauth-generic
Accessed: 2026-08-07
Quote: n8n's "Google OAuth2 single service" credential type instructs the user to obtain their own Client ID/Secret from Google Cloud Console and enter it, using n8n's own callback URL as the registered redirect URI.

**n8n-credential-overwrites**
URL: https://docs.n8n.io/hosting/configuration/configuration-examples/microsoft-oauth-credential-overwrites/
Accessed: 2026-08-07
Quote: Documented pattern for pre-configuring OAuth credentials at the instance/admin level so they appear as a "Managed OAuth2 (recommended)" option for all users, injected via env/startup config.

**nextcloud-oauth2-provider**
URL: https://docs.nextcloud.com/server/32/admin_manual/configuration_server/oauth2.html
Accessed: 2026-08-07
Quote: Admin manual describes registering an OAuth2 client via Settings → Administration → Security, "Add client," entirely through the admin UI.

**nextcloud-user-oidc**
URL: https://blog.cubieserver.de/2022/complete-guide-to-nextcloud-oidc-authentication-with-authentik/ ; https://github.com/pulsejet/nextcloud-oidc-login
Accessed: 2026-08-07
Quote: Community integration guides document `user_oidc`'s Settings UI configuration alongside `occ` CLI commands needed for certain flags (e.g. disabling fallback login backends) and `config.php` edits for networking edge cases (e.g. `allow_local_remote_servers`).

**immich-oauth**
URL: https://docs.immich.app/administration/oauth/ ; https://github.com/immich-app/immich/blob/main/docs/docs/administration/oauth.md
Accessed: 2026-08-07
Quote: Admin configures Issuer URL, Client ID, Client Secret, Scope, and Button Text entirely through Administration → Settings → Authentication Settings → OAuth in Immich's own admin UI.

**jellyfin-sso-plugin**
URL: https://github.com/9p4/jellyfin-plugin-sso/blob/main/providers.md ; https://github.com/kanidm/kanidm/discussions/3864 ; https://jellywatch.app/blog/jellyfin-sso-authelia-authentik-single-sign-on-2026
Accessed: 2026-08-07
Quote: "Hit save, remember to restart Jellyfin, and enjoy!" — explicit restart requirement documented across multiple independent setup guides for the jellyfin-plugin-sso plugin.

**google-sensitive-scope-verification**
URL: https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification ; https://developers.google.com/identity/protocols/oauth2/production-readiness/restricted-scope-verification ; https://support.google.com/cloud/answer/13804565?hl=en
Accessed: 2026-08-07
Quote: Google's own production-readiness docs classify Calendar and Contacts scopes under "sensitive scope verification" (not the stricter restricted-scope/CASA-audit tier), and specify demo video, privacy policy, and domain verification requirements for sensitive-scope apps seeking to publish.

**google-unverified-apps**
URL: https://support.google.com/cloud/answer/15549945?hl=en ; https://support.google.com/cloud/answer/7454865?hl=en
Accessed: 2026-08-07
Quote: Google's app-audience/publishing-status documentation specifies the 100-test-user cap for Testing-status apps and the exemption from verification for personal-use/internal apps.

## SYNTHESIS

The dominant, near-universal pattern among actively-maintained self-hosted/user-owned software (Home Assistant, n8n self-hosted, Nextcloud, Immich; Jellyfin's SSO plugin is the sole partial outlier) is a clean two-part separation: (1) the operator must register their own OAuth application with the provider — this is unavoidable and every project accepts it as such, since no OSS project ships a provider-issued client secret baked into public source code, and (2) delivering the resulting client_id/secret into the running instance is a DB-backed, UI-editable admin-settings operation with immediate effect, never an env-var-only + restart requirement. The only place a genuine env-var/startup-config path exists for OAuth app credentials is n8n's "credential overwrites," and even there it's an *instance-admin convenience layered on top of* the UI path (to give ordinary multi-user-instance users a zero-click experience), not a replacement for it. The only project requiring a restart after changing OAuth credentials (Jellyfin's SSO plugin) is a widely-complained-about symptom of Jellyfin's plugin-loading architecture, not evidence that restart-on-config-change is an accepted norm.

Practical implication for any project (like PDPP) building a self-hosted product that needs a user-registered OAuth app: build a settings store (DB-backed) with a UI form for client_id/secret, treat env vars as an optional startup-time default/override for automated deploys, and never require a process restart for this class of config change once the settings store exists. Also worth carrying forward: Google's Calendar/Contacts scopes sit in the lighter "sensitive" verification tier (no CASA audit), and a personal-use single-owner deployment is explicitly exempt from Google's verification requirement — the operational gotcha to design around is not verification but the 7-day refresh-token expiry Google enforces on unverified/Testing-status apps, which will look like a mystery recurring disconnect if not surfaced in-product.
