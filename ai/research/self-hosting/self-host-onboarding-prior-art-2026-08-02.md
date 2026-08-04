---
title: "Leading self-host and MCP-client tools converge on auto-generated first-boot secrets, doctor-style preflight commands, API-enforced (not just UI-hinted) capability gating, and a hard public-HTTPS requirement for cloud-hosted MCP clients that Claude Code's local transport does not share"
date: 2026-08-02
topic: self-hosting
tags: [onboarding, self-hosting, mcp, cloudflare-tunnel, tailscale-funnel, doctor-command, capability-gating, docker-cross-platform, claude-code, chatgpt-connectors]
status: draft
sources: [gitea-docker-install, supabase-docker-selfhost, portainer-initial-setup, jellyfin-setup-wizard, gh-auth-status-manual, flutter-doctor-troubleshoot, homebrew-troubleshooting, tailscale-funnel-docs, stripe-capabilities, stripe-capability-requirements, plaid-institution-status, cloudflare-quick-tunnels, cloudflare-quick-tunnels-mirror, tailscale-funnel-cli-ref, claude-remote-mcp-docs, claude-remote-mcp-support-article, claude-code-mcp-docs, openai-developer-mode-help, docker-compose-volumes-ref, docker-bind-mounts-ref, docker-compose-envvars-ref, docker-desktop-windows-troubleshoot]
source_session: unknown
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

### 1. First-run secret generation

- Gitea auto-generates `SECRET_KEY` and `INTERNAL_TOKEN` on every new Docker installation and writes them into `app.ini` with no operator action required; operators who want to set them explicitly instead run `docker run -it --rm docker.gitea.com/gitea:1 gitea generate secret SECRET_KEY` (and the same for `INTERNAL_TOKEN`), and the docs warn "Do not lose/change your SECRET_KEY after the installation, otherwise the encrypted data can not be decrypted anymore." [gitea-docker-install]
- Supabase's self-host Docker guide requires operators to manually generate several secrets via `openssl` (JWT secret ≥64 chars via `openssl rand -base64 48`, S3 access key/secret, `MINIO_ROOT_PASSWORD`), but also ships an automated `generate-keys.sh` / `add-new-auth-keys.sh` pair (invokable non-interactively with `-y`) that generates all secrets including a random `DASHBOARD_PASSWORD` and the asymmetric JWT signing key pair, wiring the results into `docker-compose.yml`. [supabase-docker-selfhost]
- Portainer's official initial-setup flow requires the admin to set the password through the web wizard within a short, expiring window (5 minutes by default) after first launch, reading a `setup_token=` value from the server logs to authorize that first request; the password must be ≥12 characters. If the window is missed, Portainer ships an official reset-password container helper (scale the service to zero, run the helper against the same data volume) rather than a support ticket flow. Portainer also supports scripted/non-interactive first-admin creation via CLI flags, including a `--admin-password-file` flag for a plaintext-file-sourced password. [portainer-initial-setup]
- Jellyfin does not ship any pre-configured admin credential; the first browser visit runs a `StartupController`-backed setup wizard (gated by a `Policies.FirstTimeSetupOrElevated` authorization policy) that creates the first admin account as one step in a multi-step wizard (language → admin account → media libraries → metadata region), and only completes when a `CompleteWizard` call sets an `IsStartupWizardCompleted` flag. [jellyfin-setup-wizard]

### 2. Environment doctor / preflight

- `gh` (GitHub CLI) has **no official `gh doctor` command**; the closest primary-source equivalent is `gh auth status`, which per the official manual (`cli.github.com/manual/gh_auth_status`) exits 1 with stderr diagnostics on auth failure and — in real failure output — names the exact broken file and prescribes the exact fix command, e.g. "The token in /home/jonathan/.config/gh/hosts.yml is invalid" followed by "To re-authenticate, run: gh auth login -h github.com". [gh-auth-status-manual]
- Supabase CLI likewise has **no official `doctor` or `preflight` command** in its documented command surface (init, bootstrap, login, functions, etc.) — ruled out as a comparator for this problem. [confirmed via targeted search of supabase.com/docs/reference/cli, no entry found]
- `flutter doctor` inspects the local toolchain and prints a per-section report (Flutter, Android toolchain, Xcode, etc.) using a checkmark/X status per section; it "provides a comprehensive report of any issues it finds and suggestions on how to fix them" and frequently suggests the exact remediation command inline, but it is explicitly diagnose-only: it does not auto-fix (e.g. Android SDK license acceptance still requires the human to run `flutter doctor --android-licenses` separately). Verbose mode (`flutter doctor -v`) gathers SDK paths, versions, and device info for support escalation. [flutter-doctor-troubleshoot]
- `brew doctor` is positioned by Homebrew's own troubleshooting docs primarily as a pre-bug-report gate, not a general health dashboard: official guidance is to run `brew update` (twice), then `brew doctor` and "fix all warnings" before filing any issue, and to attach `brew doctor` + `brew config` output when reporting problems that aren't formula-specific. [homebrew-troubleshooting]
- Tailscale's nearest official diagnostic primitives are `tailscale netcheck` ("Print an analysis of local network conditions" — UDP/DERP/NAT reachability) and `tailscale bugreport` (generates a shareable diagnostic identifier plus, with `--diagnose`, verbose system info sent to Tailscale's own logs for support triage); Tailscale has no command literally named `doctor`. [tailscale-funnel-cli-ref]

### 3. Capability gating / progressive disclosure

- Stripe Connect's `Capability` API object carries a `requirements` hash (`currently_due`, `past_due`, `eventually_due`, `current_deadline`) that names exactly which fields are missing to keep a capability enabled, and a `disabled_reason` enum (`requirements.fields_needed`, `pending.onboarding`, `pending.review`, `rejected.other`, etc.) that states *why* a capability is currently off — the account cannot silently attempt an action a capability blocks; the capability object itself reports the blocking state before any transaction is attempted. [stripe-capabilities][stripe-capability-requirements]
- Stripe explicitly recommends previewing capability requirements *before* requesting the capability, "to enable a requirement faster and avoid disabling the Account" — i.e., surfacing the gate before the user commits, not after a failed attempt. [stripe-capability-requirements]
- Plaid Link enforces capability gating at Link-initialization time via the `products` / `optional_products` / `required_if_supported_products` arrays: if an institution doesn't support a product Link was hard-initialized with, the user gets a "Connectivity not supported" error immediately upon institution selection — Plaid's own remediation guidance is to move non-essential products out of the hard-required `products` array specifically so unsupported institutions are not blocked from the flow at all, rather than shown a late failure. [plaid-institution-status]
- GitHub's branch-protection "required status checks" is a comparator that does **not cleanly fit** "prevent starting" — it blocks the merge action after the fact (a blocked button/status, not a pre-flow gate), and GitHub's own community/docs surface acknowledge a known gap: a required check tied to a path-filtered workflow that never triggers leaves the PR permanently stuck "Waiting for status to be reported" rather than gracefully skipping — i.e., GitHub's architecture only supports post-hoc blocking, not upfront capability disclosure. [confirmed via GitHub docs/community search — ruled out as the primary comparator for problem 3, kept as a negative example]

### 4. Local-to-public HTTPS: Cloudflare Quick Tunnel vs Tailscale Funnel

- Cloudflare's official Quick Tunnels documentation states developers can use TryCloudflare "to experiment with Cloudflare Tunnel without adding a site to Cloudflare's DNS," generating a random `trycloudflare.com` subdomain — **no Cloudflare account is required** for this basic flow. [cloudflare-quick-tunnels]
- Cloudflare's own documented hard limit: Quick Tunnels cap concurrent in-flight requests at **200**; exceeding it returns HTTP `429`. [cloudflare-quick-tunnels]
- Cloudflare's own documented functional gap: Quick Tunnels **do not support Server-Sent Events (SSE)** (WebSockets are unaffected). [cloudflare-quick-tunnels]
- Cloudflare's own durability/SLA statement, verbatim: "We don't guarantee any SLA or uptime of TryCloudflare — we plan to test new Cloudflare Tunnel features and improvements on these free tunnels." [cloudflare-quick-tunnels]
- Cloudflare's own production-use statement, verbatim: "Quick Tunnels are intended for testing and development only. For production use, create a remotely-managed tunnel." [cloudflare-quick-tunnels]
- Quick Tunnel URLs do not survive a `cloudflared` process/container restart — Cloudflare assigns the hostname fresh at each startup handshake, so every restart yields a new, unpredictable `trycloudflare.com` URL. [cloudflare-quick-tunnels-mirror]
- Tailscale Funnel requires a Tailscale account and an installed client on the serving machine; enabling Funnel requires a `nodeAttrs: ["funnel"]` grant in the tailnet policy file (auto-granted when enabled via CLI), and by default any user in `autogroup:member` may use it. Funnel is restricted to three allowed listen ports (443, 8443, 10000) and issues real Let's Encrypt-backed HTTPS certs bound to the operator's own `<machine>.<tailnet>.ts.net` hostname — a stable hostname, unlike Quick Tunnel's ephemeral one — but the operator must have signed up for Tailscale first, which Quick Tunnel does not require. [tailscale-funnel-docs][tailscale-funnel-cli-ref]
- Tailscale documents a real operational trap distinct from Cloudflare's: repeatedly re-requesting a Funnel cert can hit **Let's Encrypt's own rate limit**, forcing a wait of up to 34 hours before a new cert can be issued. [tailscale-funnel-docs]

### 5. Remote MCP client requirements (claude.ai / ChatGPT)

- Anthropic's official Claude.ai docs state plainly: custom connectors "connect to your remote MCP server from Anthropic's cloud infrastructure, rather than from your local device," so "your MCP server must be reachable over the public internet from Anthropic's IP ranges" — "servers hosted on a private corporate network, behind a VPN, or blocked by a firewall won't connect, even if reachable from your own machine." This applies uniformly across claude.ai, Claude Desktop, Cowork, and mobile apps — Claude Desktop being an app that itself runs locally does not exempt its *remote-connector* path from this rule. [claude-remote-mcp-support-article]
- Anthropic's docs describe the actual server-side enforcement mechanism, not just a policy statement: before making any request, Claude resolves the server's hostname and rejects the connection pre-flight if any resolved address is a private range (RFC1918: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16), carrier-grade NAT (100.64.0.0/10), a mixed public/private result set, or has no public-DNS A record — connectors are IPv4-only for this check. TLS is effectively mandatory; self-signed certs are rejected without an intermediate trusted proxy. [claude-remote-mcp-support-article]
- Custom connectors are **not gated to paid-only plans** for the "add it yourself" path: per Anthropic's official docs, Free, Pro, and Max plan users can each individually add a custom connector via Settings > Connectors. Only on Team and Enterprise plans is connector-adding restricted to Owners (via Admin settings > Connectors), after which individual members separately opt in to connect. [claude-remote-mcp-docs]
- Anthropic's docs separately and explicitly distinguish this remote-connector mechanism from Claude Desktop's *local* MCP config (`claude_desktop_config.json`), which "uses your local network" and is "a separate mechanism" — but that local-config mechanism is not available in Cowork or claude.ai, only in the Desktop app. [claude-remote-mcp-support-article]
- OpenAI's Developer Mode (the mechanism that unlocks full read/write custom MCP connectors in ChatGPT) is available on **Plus, Pro, Business, Enterprise, and Education plans** and is **not available on the Free plan**; enabled per-account via Settings → Security and login → Developer mode (individual accounts) or via Admin/workspace settings for Business/Enterprise/Edu, where only admins/owners can enable it org-wide. [openai-developer-mode-help]
- Community/secondary sources describe the ChatGPT-side connectivity requirement as: the MCP server must be reachable "through a public HTTPS endpoint or Secure MCP Tunnel," with a public endpoint typically serving streamable HTTP at `/mcp` — this specific "public HTTPS or Secure MCP Tunnel" phrasing could **not be independently confirmed against OpenAI's own Help Center page** (the direct fetch returned HTTP 403); treat as **UNVERIFIED** pending a source that isn't blocked. [openai-developer-mode-help — access blocked, see SOURCES note]

### 6. Claude Code local MCP

- Claude Code's official docs (`code.claude.com/docs/en/mcp`) document `claude mcp add --transport http <name> <url>` as the standard command for adding an HTTP-transport MCP server, with `streamable-http` accepted as an alias for `http` in JSON configs (`.mcp.json`, `~/.claude.json`, `claude mcp add-json`). [claude-code-mcp-docs]
- For servers requiring OAuth with a pre-registered redirect URI, Claude Code supports `--callback-port <PORT>` to pin the local OAuth callback to a fixed port, matching a redirect URI registered in the form `http://localhost:PORT/callback` — this is a **local loopback callback**, not a publicly reachable endpoint, confirming Claude Code's local MCP path does not require exposing anything to the public internet even when doing OAuth. [claude-code-mcp-docs]
- Claude Code's docs draw an explicit line between transports: "HTTP for cloud-hosted services, stdio for anything on your own machine" is the practical guidance, and every official example URL for `--transport http` in the docs uses `https://` against a cloud-hosted service (Notion, Stripe, Sentry, GitHub, HubSpot, Asana) — the docs do not show or explicitly bless an `http://localhost:PORT/mcp` server URL as a worked example, though nothing in the documented transport logic (which runs client-side, not via Anthropic's cloud like claude.ai connectors) forbids it. **This specific gap — no official first-party example of a local-loopback HTTP MCP server — should be treated as UNVERIFIED for "officially documented" though architecturally very likely to work**, since Claude Code executes entirely on the local machine and does not route MCP traffic through Anthropic's cloud the way claude.ai custom connectors do. [claude-code-mcp-docs]
- Claude Code also supports `stdio` transport (`claude mcp add --transport stdio myserver -- <command>`), which is the standard choice for a locally-run server and requires no network exposure of any kind — Claude Code spawns and communicates with the process directly over stdio pipes. [claude-code-mcp-docs]

### 7. Cross-platform Docker command correctness

- PowerShell's line-continuation character is the backtick (`` ` ``), not the backslash (`\`) bash/zsh use, and Docker's own Dockerfile syntax exposes an `escape` directive precisely because of this collision — the directive "at the moment only allows backslash or backtick as the escape character," and Docker's own example uses `# escape=\`` specifically to avoid ambiguity with Windows path separators inside a Dockerfile. [inferred from Docker docs `escape` directive semantics; see docker-bind-mounts-ref sibling docs — treat exact wording as community-summarized, not independently re-verified verbatim against the Dockerfile reference page in this pass]
- Docker Compose's official environment-variable reference documents `COMPOSE_CONVERT_WINDOWS_PATHS` ("Enable path conversion from Windows-style to Unix-style in volume definitions... Users of Docker Machine and Docker Toolbox on Windows should always set this," default `0`) and `COMPOSE_FORCE_WINDOWS_HOST` ("If set, volume declarations using the short syntax are parsed assuming the host path is a Windows path, even if Compose is running on a UNIX-based system") — both variables exist specifically because Compose's short volume syntax `[SOURCE:]TARGET[:MODE]` uses `:` as a field separator, which collides with a Windows drive letter (`C:\...`). [docker-compose-envvars-ref]
- Docker's own official troubleshooting docs give a canonical example command that embeds an unescaped, unquoted Windows path directly in `-v`: `docker run --rm -ti -v C:\Users\user\work:/work alpine`, with the accompanying note that "Docker Desktop detects the Windows-style path and provides the appropriate conversion to mount it" — i.e. Docker Desktop's CLI layer has special-cased handling that plain Compose short-syntax parsing does not get for free, which is exactly why `COMPOSE_FORCE_WINDOWS_HOST` had to be added as an escape hatch for Compose specifically. [docker-desktop-windows-troubleshoot]
- `host.docker.internal` behavior officially differs by platform per Docker's own docs: on Docker Desktop (macOS, Windows, and Docker Desktop for Linux) it resolves automatically to the host, and Docker's own text is explicit that this is "for development purpose and will not work in a production environment outside of Docker Desktop for Windows / Mac." On native Docker Engine on Linux (no Desktop), it does **not** work out of the box; since Docker Engine 20.10, it can be enabled via `--add-host=host.docker.internal:host-gateway` (CLI) or the equivalent `extra_hosts` Compose key. [docker-compose-volumes-ref][docker-bind-mounts-ref — cross-referenced against widely-corroborated Docker 20.10 release documentation; the exact host.docker.internal platform-difference quote was not independently re-fetched verbatim from a single Docker docs page in this pass and should be spot-checked before being treated as load-bearing for a security-relevant decision]

## SOURCES

**gitea-docker-install**
URL: https://docs.gitea.com/installation/install-with-docker
Accessed: 2026-08-02
Quote: "Gitea will generate new secrets/tokens for every new installation automatically and write them into the app.ini." / "Do not lose/change your SECRET_KEY after the installation, otherwise the encrypted data can not be decrypted anymore."

**supabase-docker-selfhost**
URL: https://supabase.com/docs/guides/self-hosting/docker
Accessed: 2026-08-02
Quote: "the JWT secret must be at least 64 characters and generated with `openssl rand -base64 48`"

**portainer-initial-setup**
URL: https://docs.portainer.io/start/install/server/setup ; https://docs.portainer.io/advanced/cli ; https://docs.portainer.io/advanced/reset-admin
Accessed: 2026-08-02
Quote: "your setup token can be found in your Portainer server logs" / password window default "5 minutes" / "--admin-password-file"

**jellyfin-setup-wizard**
URL: https://jellyfin.org/docs/general/post-install/setup-wizard/
Accessed: 2026-08-02
Quote: "the StartupController manages the initial configuration wizard and creation of the first administrative user, using the Policies.FirstTimeSetupOrElevated authorization policy"

**gh-auth-status-manual**
URL: https://cli.github.com/manual/gh_auth_status
Accessed: 2026-08-02
Quote: "To re-authenticate, run: gh auth login -h github.com"

**flutter-doctor-troubleshoot**
URL: https://docs.flutter.dev/install/troubleshoot
Accessed: 2026-08-02
Quote: "the documentation currently reflects Flutter 3.44.7, last updated 2026-07-31"

**homebrew-troubleshooting**
URL: https://docs.brew.sh/Troubleshooting
Accessed: 2026-08-02
Quote: "run brew update twice and brew doctor, fixing all warnings, before creating an issue"

**tailscale-funnel-docs**
URL: https://tailscale.com/docs/features/tailscale-funnel
Accessed: 2026-08-02
Quote: "requires a node attribute (nodeAttrs) of funnel in your tailnet policy file" / rate-limit wait "up to 34 hours"

**tailscale-funnel-cli-ref**
URL: https://tailscale.com/docs/reference/tailscale-cli/funnel ; https://tailscale.com/docs/reference/tailscale-cli
Accessed: 2026-08-02
Quote: "Print an analysis of local network conditions" (netcheck); bugreport generates "a random identifier into diagnostic logs"

**stripe-capabilities**
URL: https://docs.stripe.com/connect/account-capabilities ; https://docs.stripe.com/api/capabilities/object
Accessed: 2026-08-02
Quote: "requirements listed indicate what information is needed from your connected account to prevent that capability from being disabled"

**stripe-capability-requirements**
URL: https://docs.stripe.com/connect/handling-api-verification
Accessed: 2026-08-02
Quote: "To enable a requirement faster and avoid disabling the Account, preview the requirements and collect any required information before requesting the capability."

**plaid-institution-status**
URL: https://plaid.com/docs/link/institution-status/ ; https://plaid.com/docs/link/initializing-products/ ; https://plaid.com/docs/link/troubleshooting/
Accessed: 2026-08-02
Quote: "Make sure not to initialize Link with any products your application isn't using."

**cloudflare-quick-tunnels**
URL: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/
Accessed: 2026-08-02
Quote: "Quick Tunnels are intended for testing and development only. For production use, create a remotely-managed tunnel." / "this limit is 200 in-flight requests" / "Quick Tunnels do not support Server-Sent Events (SSE)." / "We don't guarantee any SLA or uptime of TryCloudflare"

**cloudflare-quick-tunnels-mirror**
URL: https://developers.cloudflare.com/sandbox/api/tunnels/
Accessed: 2026-08-02
Quote: "Quick tunnel URLs do not survive container restart"

**claude-remote-mcp-docs**
URL: https://claude.com/docs/connectors/custom/remote-mcp
Accessed: 2026-08-02
Quote: "For Free, Pro, and Max plans / Navigate to Settings > Connectors / Click 'Add custom connector'" vs "For Team and Enterprise plans / Owners must: Navigate to Admin settings > Connectors"

**claude-remote-mcp-support-article**
URL: https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp
Accessed: 2026-08-02
Quote: "your MCP server must be reachable over the public internet from Anthropic's IP ranges" / "Servers hosted on a private corporate network, behind a VPN, or blocked by a firewall won't connect, even if you can reach them from your own machine." / rejection on private/CGNAT ranges "10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16" and "100.64.0.0/10"

**claude-code-mcp-docs**
URL: https://code.claude.com/docs/en/mcp
Accessed: 2026-08-02
Quote: "claude mcp add --transport http <name> <url>" / "Use --callback-port to fix the port so it matches a pre-registered redirect URI of the form http://localhost:PORT/callback"

**openai-developer-mode-help**
URL: https://help.openai.com/en/articles/12584461-developer-mode-and-mcp-apps-in-chatgpt
Accessed: 2026-08-02
Note: Direct WebFetch to this URL and its `-beta` variant both returned HTTP 403; claims sourced via WebSearch snippet aggregation of this page's indexed content, not a verbatim direct fetch. Quote (via search snippet, not independently re-verified): "Developer mode is available to Pro, Plus, Business, Enterprise, and Education accounts on the web."

**docker-compose-volumes-ref**
URL: https://docs.docker.com/reference/compose-file/volumes/
Accessed: 2026-08-02
Quote: "[SOURCE:]TARGET[:MODE]" short syntax definition; page fetched directly but did not itself contain Windows-specific colon-collision guidance (that lives in the envvars reference and Desktop troubleshooting docs instead — see below).

**docker-bind-mounts-ref**
URL: https://docs.docker.com/engine/storage/bind-mounts/
Accessed: 2026-08-02
Quote: "If you're on Windows, see also Path conversions on Windows." (link-only reference, no inline Windows guidance on this specific page)

**docker-compose-envvars-ref**
URL: https://docs.docker.com/compose/how-tos/environment-variables/envvars/
Accessed: 2026-08-02
Quote: "COMPOSE_CONVERT_WINDOWS_PATHS — Enable path conversion from Windows-style to Unix-style in volume definitions" / "COMPOSE_FORCE_WINDOWS_HOST — If set, volume declarations using the short syntax are parsed assuming the host path is a Windows path, even if Compose is running on a UNIX-based system"

**docker-desktop-windows-troubleshoot**
URL: https://docs.docker.com/desktop/troubleshoot-and-support/troubleshoot/topics/
Accessed: 2026-08-02
Quote: "docker run --rm -ti -v C:\Users\user\work:/work alpine"

## SYNTHESIS

**1. Secret generation.** Gitea and Supabase both converge on the same shape: auto-generate on first boot by default, but expose an explicit CLI escape hatch (`gitea generate secret`, `generate-keys.sh`) for operators who want deterministic/scripted secrets. Neither forces rotation after the fact — Gitea's docs actively warn *against* rotating `SECRET_KEY` post-install (it breaks decryption of existing data), which cuts against "force rotation" as a design goal; the safer transferable pattern is "generate strong secrets automatically before first boot, never ship a placeholder default, and don't make silent rotation possible for keys that encrypt existing state." Portainer's real contribution is the *scoped setup token* pattern — a short-lived, log-delivered one-time token that authorizes exactly one first-admin-creation request and expires (5 minutes, not 24 hours — correct any prior assumption of a 24-hour window). **PDPP implication:** ship a generate-secrets step (script or first-boot auto-gen, matching Gitea's default-auto-generate model) that writes strong random values with no committed placeholder; if there's a decryption-sensitive secret (e.g. an at-rest data key), explicitly warn against post-install rotation the way Gitea does, rather than implying rotation is always safe.

**2. Doctor/preflight.** Two of the five originally-suggested comparators (`gh`, Supabase CLI) turned out not to have a doctor/preflight command at all — ruled out, not force-fit. The real, primary-sourced pattern across Flutter/Homebrew/Tailscale is: a single command that (a) enumerates independent subsystems/sections, (b) reports pass/fail per section with a terse status glyph, (c) suggests — but does not always auto-run — the exact fix command, and (d) has a verbose/diagnostic mode whose output is meant to be pasted into a support channel (Flutter's `-v`, Tailscale's `bugreport --diagnose`). None of these tools auto-fix; they all stop at diagnosis + a copyable next command. **PDPP implication:** a `pdpp doctor` (or dashboard-native equivalent) should check independent subsystems (Docker reachable, ports free, required env vars present, DB migrated, tunnel/HTTPS reachable, MCP endpoint respondable) each as its own pass/fail line with the exact remediation command inline — and should not attempt silent auto-fix of anything that could destroy state (mirroring Flutter's refusal to auto-accept Android licenses).

**3. Capability gating.** Stripe Connect is the strongest fit and should anchor PDPP's design: capabilities carry a structured, API-visible reason for being blocked (not just a UI hint), and Stripe explicitly recommends surfacing the requirement *before* the user requests the capability, not after a failed attempt. Plaid Link's product-array gating is the second-best fit and is arguably more directly analogous to PDPP's problem (a client wants to start a flow the current install can't complete) — Plaid's own remediation guidance is structural: don't just show an error, remove the impossible option from what can be selected in the first place. GitHub's required-status-checks was the suggested comparator that does **not** fit well — it is a post-hoc block on a different action (merging), not a pre-flow capability gate, and it has a documented "stuck forever" failure mode precisely because it lacks the kind of proactive requirements-object Stripe has. **PDPP implication:** any client-facing "start MCP connector setup" affordance must check deployment capability (public HTTPS reachable? account plan sufficient? tunnel active?) via a structured, machine-checkable status *before* rendering the option as available — matching Stripe's `requirements`/`disabled_reason` shape and Plaid's "don't offer what can't work" philosophy — rather than letting the user click through and fail deep in a multi-step flow the way GitHub's stuck-PR pattern allows.

**4. Local-to-public HTTPS for testing.** Cloudflare Quick Tunnel is a strictly better fit for PDPP's "test use, no account" case than Tailscale Funnel: no account needed, official docs explicitly scope it to "testing and development only," and the concrete numeric limits (200 concurrent in-flight requests, no SSE, no SLA, URL changes every restart) are all directly documented and quotable. Tailscale Funnel is the better fit *if* PDPP is willing to require a free Tailscale account, in exchange for a stable hostname, real Let's Encrypt certs, and no request-count ceiling — but it has its own sharp edge (Let's Encrypt rate limits on repeated re-issuance, up to a 34-hour lockout) that Quick Tunnel simply doesn't have because Cloudflare owns the whole cert chain. **PDPP implication:** if PDPP's friend-ready flow uses Quick Tunnel for a same-day demo, the copy must set expectations matching Cloudflare's own language — "for testing, not production, URL will change if you restart, don't push more than light single-user traffic" — and must not rely on SSE-based transports over that tunnel. If PDPP wants a stable link across restarts, Tailscale Funnel (accepting the account-creation cost) is the documented path, not a Quick Tunnel workaround.

**5. Remote MCP client requirements.** The single most consequential, least-obvious finding: Anthropic's custom-connector requirement is **not a soft recommendation** — it is enforced with a documented pre-flight DNS/IP-range check that rejects private, CGNAT, and mixed-address results before any HTTP request is even attempted, and rejects self-signed TLS. This means "just point Claude.ai at your home server's LAN IP" cannot ever work, categorically, no matter what account plan or configuration is used — the only path from claude.ai/Claude Desktop's *remote-connector* surface to a self-hosted PDPP is a real public HTTPS hostname with a CA-trusted cert. The plan-gating finding corrects a likely wrong assumption: connector-adding is available on **Free, Pro, and Max** individually, not gated to paid tiers the way ChatGPT gates Developer Mode (Plus/Pro/Business/Enterprise/Edu only, explicitly excluding ChatGPT Free). **PDPP implication:** the friend-ready contract must not assume "any Claude plan will work if I just give them a URL" without also solving the public-HTTPS problem — that's a hard architectural wall, not a config nudge. For ChatGPT specifically, the flow must gate on "does your friend have a paid ChatGPT plan," since Free-tier ChatGPT users structurally cannot use custom MCP connectors at all, independent of PDPP's own setup.

**6. Claude Code local MCP.** This is the one client surface where PDPP does **not** need public HTTPS: Claude Code runs entirely on the user's own machine and both its `http`/`streamable-http` transport (via `--callback-port` pinning OAuth to a `localhost` redirect) and its `stdio` transport are architecturally local — no Anthropic-cloud hop, unlike claude.ai. The docs don't showcase a first-party `http://localhost:PORT/mcp` example, which is a real (if narrow) documentation gap, but nothing in the documented client-side routing logic requires public reachability, and OAuth-over-localhost is explicitly supported via the callback-port flag. **PDPP implication:** for developer/friend users running Claude Code locally against a locally-run PDPP instance, skip the tunnel/HTTPS story entirely and document `claude mcp add --transport http pdpp http://localhost:<port>/mcp` (or `stdio` if PDPP can run as a spawned local process) as the zero-infrastructure onboarding path — this should be the *first* recommended path for any technical friend, with the tunnel-based flow reserved for claude.ai/ChatGPT users who lack a local Claude Code install.

**7. Cross-platform Docker commands.** The two concrete, docs-grounded landmines for copy-paste `docker run`/Compose snippets across OSes are: (a) PowerShell's backtick vs bash/zsh's backslash for line continuation, which Docker's own Dockerfile `escape` directive exists specifically to accommodate; and (b) Compose's short-volume-syntax `:`-as-field-separator colliding with a Windows drive letter, serious enough that Docker shipped two dedicated environment variables (`COMPOSE_CONVERT_WINDOWS_PATHS`, `COMPOSE_FORCE_WINDOWS_HOST`) purely to paper over it, and Docker Desktop's own CLI layer has bespoke Windows-path detection that plain Compose parsing doesn't get for free. `host.docker.internal` is the third landmine: automatic on every Docker Desktop platform (macOS/Windows/Linux-Desktop) but requires an explicit `--add-host=host.docker.internal:host-gateway` / `extra_hosts` addition on plain Docker Engine on Linux (the exact platform most self-hosted PDPP installs will run on) — get this wrong and a container silently can't reach a host-bound service instead of failing loudly. **PDPP implication:** any copy-paste `docker run`/`docker compose` snippet in PDPP's onboarding docs must be OS-forked (bash block + PowerShell block, not one block with inline "adjust for Windows" prose), must use the Compose long-form volume syntax or `./`-relative paths to sidestep the colon collision entirely rather than relying on env-var workarounds, and must explicitly add `extra_hosts: ["host.docker.internal:host-gateway"]` in the shipped Compose file so Linux Engine users don't hit a silent connectivity gap that macOS/Windows Desktop users would never see.
