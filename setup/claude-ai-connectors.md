# claude.ai (web/mobile chat) - what's portable

claude.ai supports MCP via **Connectors** on Pro / Max / Team / Enterprise
plans. Free tier has no MCP. Connectors must be **remote** (HTTP/SSE) -
local `stdio` servers (the kind in `claude_desktop_config.json`) cannot be
attached directly.

## Portability of the seven servers

| Server | Portable to claude.ai? | How |
| --- | --- | --- |
| `github` | YES - easiest | Use the built-in GitHub connector. No install, OAuth login. |
| `filesystem` | NO | Cloud chat can't see your local disk. Closest substitute: Google Drive / Dropbox connector. |
| `scheduler` | MAYBE | Wrap behind `mcp-proxy` or rebuild as a Cloudflare Worker, expose with auth. |
| `pinescript-docs` | MAYBE | Same - wrap behind a remote MCP bridge. |
| `pinescript-strategy` | MAYBE | Same. |
| `tradingview` | NO (practically) | Needs `CDP_URL=127.0.0.1:9223` on your box. Would require a tunnel back to your machine - brittle. |
| `computer-use` | NO | Local-only by design. |

## Recommended posture

- **claude.ai:** enable the built-in GitHub connector and stop there.
- **Claude Desktop / Claude Code / Cursor:** use the seven local stdio
  servers from `setup/`. That's where they belong.
- Don't try to bridge `tradingview` / `filesystem` / `computer-use` into
  claude.ai - the maintenance cost outweighs the value.

## Enabling the GitHub connector in claude.ai

1. Open https://claude.ai/ -> click your profile -> **Settings** ->
   **Connectors** (or **Integrations**, depending on plan/version).
2. Find **GitHub** in the connector list and click **Connect**.
3. Authorize via OAuth. Grant the same scopes you use for the local PAT
   (typically `repo` + `read:org`).
4. In a new chat, type `/` or use the connector menu to confirm GitHub
   tools are available.

No PAT needed - the connector uses OAuth.
