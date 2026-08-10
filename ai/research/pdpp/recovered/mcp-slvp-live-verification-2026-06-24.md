# MCP SLVP live verification — 2026-06-24

Status: passed live smoke after PR #48, #49, and #50.

## Deployed revision

- `origin/main`: `79e480f502c156a253f9df081a23e9b8b710a6a0`
- Reference container: `PDPP_REFERENCE_REVISION=v0.15.0-3-g79e480f50`
- Live origin: `https://pdpp.vivid.fish`

## Gates

- PR #49: `CLEAN`; docker validation, Vercel, and `typecheck + full test suite` passed.
- PR #50: `CLEAN`; docker validation, Vercel, and `typecheck + full test suite` passed.
- Local MCP gates before PR #50:
  - `pnpm --dir packages/mcp-server run test:read-surface`
  - `pnpm --dir packages/mcp-server test`
  - `git diff --check`

## Live smoke

Target: Vana Slack `messages`, connection `cin_f565a96cb0a114b0a27e9606`.

- `search(q=Hyperlane, mode=lexical, limit=1)` passed through the live MCP app. It returned one result with canonical id `cin_f565a96cb0a114b0a27e9606/messages:C08CDMJ8206:1733441013.139829`.
- `search(q=hyperlane, mode=lexical, limit=1)` also passed.
- `read_record_field` on the canonical id returned inline bounded `text` with window metadata: `total_chars=1215`, `start_chars=286`, `end_chars=686`, `limit_chars=400`, `has_more=true`, `next_cursor=686`, and match offsets.
- `fetch` with projected small fields returned inline document output and a content ladder; it did not require file materialization.
- The visible `pdpp://record/...` handle returned by the content ladder was accepted directly by `read_record_field`.
- The same visible `pdpp://record/...` handle was accepted directly by projected `fetch`.

## Result

The ChatGPT-facing path now satisfies the intended read-evidence ladder for this live Slack case:

`compact discovery -> bounded visible evidence -> directly usable record handles -> callable bounded read -> deliberate fetch only when needed`.

Remaining caveat: this verification proves the `pdpp://record/...` handle path through callable tools. It does not prove that every generic host resource reader can read every `pdpp://field-window/...` resource URI.
