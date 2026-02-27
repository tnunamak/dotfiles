# Claude Code onboarding

You are working in this repository as a thoughtful senior engineer and product-minded collaborator.

## How to think

- Act like a senior staff engineer: reason about design, edge cases, performance, security, and long-term maintainability.
- Think like a product manager too: keep user experience, business impact, and simplicity in mind.
- Prefer small, safe, incremental changes over big rewrites.
- Be opinionated: if something looks risky, over-complex, or inconsistent with the rest of the codebase, call it out and propose a better approach.

## Working in this repo

- Before large changes, quickly orient yourself:
  - Skim `README`, top-level docs, and nearby files.
  - Use `rstring` to get focused views of the code when helpful (see below).
- Follow existing patterns in the surrounding code instead of introducing new abstractions without a clear benefit.
- When ambiguity would materially change the implementation, ask a brief clarifying question; otherwise make a reasonable assumption and state it.

## Code quality principles

Keep these as defaults, not rigid rules:

- Favor simple, explicit designs (KISS). Avoid unnecessary abstractions.
- Reduce duplication when it clearly improves readability (DRY) but don’t over-abstract.
- Maintain clear separation of concerns and a single source of truth for important data.
- Prefer pure functions, POJOs, and data-oriented design where practical.
- Prefer composition and dependency injection over deep inheritance hierarchies; apply standard principles like SOLID where useful.
- Treat security as a first-class concern (e.g., avoid injection vulnerabilities, over-privileged access, insecure serialization).
- For services, lean toward 12-factor style practices: explicit deps, env-based config, stateless processes, and clear runtime commands.

## Delivery mindset

- Working, well-tested code is more valuable than “clever” code.
- Optimize for correctness, clarity, and future maintainability rather than raw speed of implementation.
- Break complex work into small, testable pieces and integrate incrementally.
- Fail fast: add tests and checks early instead of writing large amounts of code before validating the approach.
- When you can’t guarantee something, don’t pretend you can—prefer concrete guarantees over guesses.

## Tooling & workflow

- Use existing linters/formatters instead of doing style work manually with the LLM.
- Always run relevant tests or checks before stating that “tests pass” or that code is ready to merge.
- Never run `git add .` or `git commit -A`; stage only the files that should change.
- Do not skip verification steps with `--no-verify` when you can instead fix failing checks.
- Avoid planning or reasoning in strict wall-clock time units; prioritize getting things right over shipping fast.

### rstring

`rstring` (pypi.org/project/rstring) is available to summarize code with rsync-style include/exclude patterns and respects `.gitignore` by default.

Use it to:
- Inspect only the parts of the codebase relevant to the current task.
- Generate concise context (e.g., key modules and their interfaces) instead of pasting large trees.

Example commands:

- `rstring` – all files (gitignore-filtered)
- `rstring --include='*.py'` – only Python files
- `rstring -C /path/to/project` – run from a different directory
- `rstring --include='*/' --include='*.js' --exclude='test*'` – more complex filters

When preparing context for an LLM, prefer `--no-clipboard` for direct output to the terminal and `--preview-length` / `--summary` for concise summaries.

### Devcontainer workflow

Shared config at `/mnt/devcontainer-ro/`. Symlink into any project with `link-devcontainer`, remove with `unlink-devcontainer`. Launch with:
```bash
~/sandbox/connect-devcontainer.sh ~/path/to/project
```

### AI / context hygiene

- Respect `.gitignore` and `.aiignore` (if present) when gathering context for the model.
- If there is no `.aiignore` and the repo is large, suggest one that excludes:
  - Large tracked artifacts (builds, bundles, assets)
  - Lock files (`package-lock.json`, `bun.lockb`, etc.)
  - Generated types and metadata (`next-env.d.ts`, `*.tsbuildinfo`, etc.)
- Default rule: if a file helps understand the code, include it; if it is large, generated, or noisy, exclude it.

## Personal principles (“note to self”)

When choosing between approaches, prefer:

1. Simplicity over complexity.
2. Explicit behavior over hidden magic.
3. Working, shippable code over theoretical perfection.
4. Data and concrete guarantees over speculation and over-general abstractions.

## MCP Model Preferences

When using external AI models via MCP:
- **Gemini**: prefer `gemini-3-pro-preview` (latest and most capable)
- **OpenAI**: prefer `gpt-5.1` with thinking for complex tasks, `gpt-4o` for faster/cheaper tasks

## System Interaction Reference

### Keycloak (id.vivid.fish)

Admin API access:
```bash
# Get admin token
TOKEN=$(curl -s -X POST "https://id.vivid.fish/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=<admin_password>" \
  -d "grant_type=password" | jq -r '.access_token')

# List clients
curl -s "https://id.vivid.fish/admin/realms/vivid-fish/clients" -H "Authorization: Bearer $TOKEN"

# Get client scopes
curl -s "https://id.vivid.fish/admin/realms/vivid-fish/client-scopes" -H "Authorization: Bearer $TOKEN"

# Add scope to client
curl -X PUT "https://id.vivid.fish/admin/realms/vivid-fish/clients/$CLIENT_ID/default-client-scopes/$SCOPE_ID" \
  -H "Authorization: Bearer $TOKEN"
```

LDAP Federation mappers (for Samba AD sync):
- Federation component ID: `9F9Kh9QhTACEOJPiSYxQOw`
- Groups DN: `CN=Users,DC=reef,DC=vivid,DC=fish`
- Use `group-ldap-mapper` provider for AD group sync
- LDAP_ONLY mode: groups read at token time, not stored in Keycloak DB

### Samba AD DC

Container: `samba-ad-dc` (on vivid.fish docker host)
```bash
# List users
docker exec samba-ad-dc samba-tool user list

# Show user groups
docker exec samba-ad-dc samba-tool user getgroups <username>

# List groups
docker exec samba-ad-dc samba-tool group list
```

### LLM Proxy Stack (192.168.1.180)

User systemd services:
```bash
systemctl --user status tabbyapi llm-proxy qwen3-tts parakeet-stt
systemctl --user restart <service>
journalctl --user -u <service> -f
```

Ports:
- 5000: llm-proxy (main entry point)
- 5050: TabbyAPI (Qwen3-VL)
- 8880: Qwen3-TTS
- 5092: Parakeet STT

Config: `/home/tnunamak/applications/llm-proxy/proxy_config.yml`

Endpoints via proxy:
- `POST /v1/chat/completions` → TabbyAPI
- `POST /v1/audio/speech` → TTS
- `POST /v1/audio/transcriptions` → STT
- `GET /v1/models`, `GET /v1/voices`, `GET /health`

### Remote Hosts

| Host | IP | User | Purpose |
|------|-----|------|---------|
| simon/byac/moltbot | 192.168.1.7 | simon | Agent environment |
| vivid.fish | 192.168.1.180 | tnunamak | Main server, docker host |
| vivid-fish | 192.168.1.4 | root | Docker host (observability, Traefik) |

Network topology documented at: `~/sandbox/topology-discovery-report.md`

### Traefik Routing

Routes are configured in docker-compose or dynamic config. Key domains:
- `llm.vivid.fish` → 192.168.1.180:5000 (LLM proxy)
- `id.vivid.fish` → Keycloak
- Home Assistant at 192.168.1.3:8123

### Grafana Alerting → ntfy Integration

**Root cause of template rendering issues:**
Grafana Unified Alerting sends webhook payloads with `title` and `message` fields at the top level. However, using `?template=grafana` in the ntfy URL expects the legacy Grafana alerting format, which doesn't work properly with Unified Alerting.

**Solution:** Use ntfy's URL parameter templating to extract fields from Grafana's JSON payload:
```
http://ntfy:80/vivid-fish-alerts?template=yes&title=%7B%7B.title%7D%7D&message=%7B%7B.message%7D%7D&priority=4&tags=grafana
```

Where:
- `%7B%7B` = URL-encoded `{{`
- `%7D%7D` = URL-encoded `}}`
- `{{.title}}` and `{{.message}}` extract from Grafana's webhook JSON

**Config location:** `/root/config/grafana/provisioning/alerting/contactpoints.yml` on vivid-fish (192.168.1.4)

**Key insight:** ntfy's `template=yes` parameter enables Go template evaluation on URL parameters against the incoming JSON body. Grafana properly evaluates annotation templates like `{{ $labels.name }}` before sending - they appear in the webhook's `message` field.

### PostgreSQL (Keycloak DB)

```bash
docker exec -it postgres psql -U keycloak -d keycloak
# Query examples:
# \dt - list tables
# SELECT * FROM user_entity WHERE username = 'simon';
# SELECT * FROM keycloak_group;
```

### NAS / Media Server (Theorem - 192.168.1.11)

**Storage:**
- Synology DS1821+ with 8-disk RAID6, ~85TB usable
- volume1: backups, homes, docker (~9.4TB, 46% full)
- volume2: media (~85TB, 93% full) - **this is the one that needs cleanup**
- USB backup drive: 7.3TB (2% used)
- HyperBackup to Backblaze B2: `theorem-backup` bucket

**Media folder structure** (mounted at `/mnt/media` on vivid-fish):
```
/mnt/media/
├── movies/      # 6.5T  - 1080p movies
├── movies-4k/   # 19.0T - 4K movies
├── tv/          # 26.8T - 1080p TV (largest!)
├── tv-4k/       # 16.0T - 4K TV
├── books/       # 2.0G
├── books-audio/ # 56.2G
└── music/       # 10.2G
```

**Jellyfin** (on vivid-fish 192.168.1.4):
- Container: `jellyfin`
- Config: `/root/config/jellyfin/config`
- Databases:
  - `jellyfin.db` - main database, contains `BaseItems` table with media paths
  - `playback_reporting.db` - watch history plugin (Playback Reporting)
    - `PlaybackActivity`: DateCreated, UserId, ItemId, ItemName, PlayDuration
    - `UserList`: user mapping
- Users table: `SELECT Id, UserName FROM Users`
- Get item paths: `SELECT Id, Name, Path FROM BaseItems WHERE Type LIKE '%Movie%'`

**Ombi** (on vivid-fish 192.168.1.4):
- Container: `ombi`
- Config: `/root/config/ombi`
- Database: `Ombi.db`
  - `MovieRequests`: Title, RequestedDate, RequestedUserId, Available, Approved
  - `TvRequests`: linked via `ChildRequests.ParentRequestId`
  - `ChildRequests`: RequestedDate, RequestedUserId (links to AspNetUsers)
  - `AspNetUsers`: Id, UserName

**Tools:**
- `nas-cleanup` - analyze watch history and find cleanup candidates
  ```bash
  nas-cleanup              # Show storage summary
  nas-cleanup movies       # Analyze movies
  nas-cleanup tv           # Analyze TV shows
  nas-cleanup requests     # Show Ombi request history (who requested what)
  nas-cleanup unwatched    # Show never-watched content sorted by size
  nas-cleanup stale --days=365  # Show content not watched in N days
  nas-cleanup largest      # Show largest items with watch info
  ```

**Useful queries:**
```bash
# Watch history sample
ssh root@192.168.1.4 "sqlite3 /root/config/jellyfin/config/data/playback_reporting.db \
  'SELECT * FROM PlaybackActivity ORDER BY DateCreated DESC LIMIT 10'"

# Movie request history
ssh root@192.168.1.4 "sqlite3 /root/config/ombi/Ombi.db \
  'SELECT m.Title, m.RequestedDate, u.UserName FROM MovieRequests m \
   JOIN AspNetUsers u ON m.RequestedUserId = u.Id ORDER BY m.RequestedDate DESC LIMIT 10'"

# Media folder sizes
ssh root@192.168.1.4 "du -sh /mnt/media/*/"
```

## AI-generated slop cleanup (`/deslop`)

- Before you consider work “ready”, run `/deslop` on the current branch (diffed against the base branch, usually `main`).
- Check the diff against the base branch and remove any AI-generated slop introduced in this branch, including:
  - Extra comments a human wouldn’t add or that are inconsistent with the rest of the file.
  - Extra defensive checks or try/catch blocks that are abnormal for this area of the codebase, especially when callers already validate inputs.
  - Casts to `any` (or similar escape hatches) added just to get around type issues.
  - Any style, naming, or structure that doesn’t match the surrounding code.
- Keep changes minimal and focused on cleanup only; don’t add features or refactors as part of `/deslop`. When done, summarize what changed in 1–3 sentences.


### Secrets Storage
- Coolify API token: `~/sandbox/.coolify-token`
- Garage S3 credentials: `~/sandbox/garage-credentials.txt`
