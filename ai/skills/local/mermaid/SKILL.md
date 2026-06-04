---
name: mermaid
description: Render and validate Mermaid diagrams locally with mermaid-cli (mmdc). Use when the user asks for a diagram, flowchart, sequence diagram, ERD, gantt, or state machine — or when you want to sanity-check that mermaid source you produced actually parses. Trigger words "mermaid", "diagram", "flowchart", "render this", "validate the diagram".
---

# Mermaid diagrams

`mmdc` (`@mermaid-js/mermaid-cli`) is installed globally on host and devcontainers. Use it to render Mermaid source to SVG/PNG/PDF AND to validate syntax — a parse error makes the command exit non-zero, so render = validate.

## Workflow

1. Write the diagram source to a `.mmd` file (or `.md` containing fenced ```mermaid blocks).
2. Render: `mmdc -i diagram.mmd -o diagram.svg`. Non-zero exit = invalid syntax; the stderr message points at the offending line.
3. For agent-friendly verification, render to SVG (text format) and grep for expected node labels. Mermaid splits long labels across multiple `<text>` spans, so use `grep -o` and count matches rather than expecting a single line: `grep -oE 'Start|Done' diagram.svg | sort -u`.

## Devcontainer / sandboxed Chromium

`mmdc` uses puppeteer → headless Chromium. In devcontainers and CI, sandboxing is unavailable, so pass a puppeteer config:

```bash
cat > /tmp/puppeteer.json <<'EOF'
{ "args": ["--no-sandbox", "--disable-setuid-sandbox"] }
EOF
mmdc -p /tmp/puppeteer.json -i diagram.mmd -o diagram.svg
```

If `mmdc` complains it can't find a browser inside the devcontainer (the bundled puppeteer Chromium isn't downloaded), reuse the playwright Chromium that's already installed:

```bash
BROWSER=$(find /opt/playwright -name 'chrome' -path '*chromium*' -type f 2>/dev/null | head -1)
cat > /tmp/puppeteer.json <<EOF
{ "executablePath": "$BROWSER", "args": ["--no-sandbox", "--disable-setuid-sandbox"] }
EOF
mmdc -p /tmp/puppeteer.json -i diagram.mmd -o diagram.svg
```

## Common flags

- `-t dark` / `-t neutral` — theme
- `-b transparent` — transparent background
- `-w 1200 -H 800` — explicit dimensions
- `-c config.json` — Mermaid config (e.g. `{"theme":"dark","flowchart":{"curve":"basis"}}`)
- `-e svg|png|pdf` — output format (inferred from `-o` extension)

## Validate without writing output

To check syntax only, render to a temp file and discard:

```bash
mmdc -i diagram.mmd -o /tmp/discard.svg && echo OK
```

There's no dedicated `--validate` flag; render-to-temp is the idiom.

## When to skip mmdc

- The user just wants to embed a mermaid block in markdown that GitHub/GitLab will render — no need to run mmdc unless they ask you to verify it parses.
- You need an interactive editor — point them at https://mermaid.live instead.
