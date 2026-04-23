# gws + gog: Google Workspace CLI tools setup

## What was done

### gws (Google Workspace CLI — official Google tool)
- Added `@googleworkspace/cli` to `npm-global-packages.txt`
- Installed globally via npm; provides `gws` command
- Auth is manual: `gws auth setup` then `gws auth login`

### gog (gogcli — third-party Google Workspace CLI)
- Added `go install github.com/steipete/gogcli/cmd/gog@latest` to `setup.sh`
- Added `~/go/bin` to PATH in `shell/.shell_config`
- Auth is manual: `gog auth login`
- Source: https://gogcli.sh / https://github.com/steipete/gogcli

## What's NOT done

### MCP server for Google Workspace
Neither tool has a built-in MCP server mode:
- `gws mcp` does not exist — confirmed by running `gws mcp --help` (returns "Unknown service 'mcp'")
- `gog` has no MCP mode either

To expose Google Workspace as tools to Claude/Gemini/Codex, options are:
1. **Find a community MCP server** — search npm/GitHub for a Google Workspace MCP server
2. **Write a thin stdio wrapper** around `gws` or `gog` that speaks MCP protocol
3. **Wait** — Google may add `gws mcp` in a future release (the CLI is from March 2026)

### Auth not automated
Both tools require interactive OAuth browser flows. Not scriptable in `setup.sh`.
`setup.sh` only ensures the binaries are installed.

## Related
- `sync-mcps.sh` + `ai/mcp-servers.json` is the existing MCP registration system
- `inbox/claude-json-stow-management.md` covers the broader MCP config drift question
