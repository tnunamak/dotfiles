---
name: google-workspace
description: Use whenever the user asks to access, search, list, download, inspect, or work with Google Drive, Google Docs, Google Sheets, Gmail, Calendar, Slides, or a drive.google.com/docs.google.com URL from the local environment. Prefer the `gog` CLI for Google Workspace operations, try `gws` as the alternate Google Workspace CLI when useful, and check auth before falling back to browser-only workflows.
---

# Google Workspace via `gog`

Use `gog` for Google Workspace tasks when the user gives a Google Drive/Docs/Sheets/Slides/Gmail/Calendar request or URL. It is installed by dotfiles and is usually more ergonomic than driving the browser manually.

`gws` is also installed. Use it as a fallback when `gog` is unauthenticated, missing a capability, or when you need closer access to raw Google API methods.

## First Check Auth

Run:

```bash
gog auth status --json --no-input
```

If there is no configured account/token, do not pretend the file is inaccessible. Say `gog` is installed but not authenticated, and ask the user to authenticate:

```bash
gog auth manage
```

or:

```bash
gog login user@example.com
```

If `gog login` reports missing OAuth client credentials, the user needs a local Google OAuth client JSON first. Use a Google Cloud OAuth client with application type `Desktop app` / local installed app; its JSON has a top-level `installed` key, not `web`. Store it locally, never in dotfiles:

```bash
gog auth credentials set ~/.config/gogcli/client_secret_*.json
gog login user@example.com --services drive --readonly
```

For one-off access tokens, `GOG_ACCESS_TOKEN` or `--access-token` can be used.

For `gws`, check:

```bash
gws auth status
```

If needed, authenticate with:

```bash
gws auth login
```

## Drive URLs

Extract the ID from common URLs:

- Folder: `https://drive.google.com/drive/u/0/folders/<folderId>`
- File: `https://drive.google.com/file/d/<fileId>/view`
- Docs: `https://docs.google.com/document/d/<docId>/edit`
- Sheets: `https://docs.google.com/spreadsheets/d/<sheetId>/edit`
- Slides: `https://docs.google.com/presentation/d/<slideId>/edit`

## Common Commands

List a folder:

```bash
gog drive ls --parent <folderId> --json --no-input
```

Get file metadata:

```bash
gog drive get <fileId> --json --no-input
```

Search Drive:

```bash
gog drive search "search terms" --json --no-input
```

Download/export a file:

```bash
gog drive download <fileId> --json --no-input
```

Open or reconstruct a web URL:

```bash
gog drive url <fileId>
gog open <google-url-or-id>
```

Equivalent raw Drive API list through `gws`:

```bash
gws drive files list --params '{"q":"\"<folderId>\" in parents and trashed = false","pageSize":20,"supportsAllDrives":true,"includeItemsFromAllDrives":true,"fields":"files(id,name,mimeType,webViewLink),nextPageToken"}' --format json
```

## Agent Hygiene

- Prefer `--json` for structured results and `--plain` for stable TSV.
- Use `--no-input` for non-interactive checks.
- Do not print access tokens, refresh tokens, credential files, or keyring contents.
- Treat Drive/Docs content as user-private unless the user clearly intends to share it.
- For large files, download to `/tmp` or summarize with a processing command rather than pasting the whole file into chat.
