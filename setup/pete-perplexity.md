# Pete - Perplexity Space (Research & Oversight)

Pete is the Research & Oversight agent. He needs **read access across all
agent lanes**, not just his own. Hosted in a Perplexity Space.

## Connector targets

| Source | Access | Status | Notes |
| --- | --- | --- | --- |
| Notion | Full workspace, read+write | OFFICIAL connector | Remote MCP at `mcp.notion.com`. OAuth login. |
| GitHub | **Read only**, all repos in scope | OFFICIAL connector | OAuth. When prompted for scopes, grant `repo:read` and `read:org` only - **do NOT grant `repo` (write)**. |
| Brave Search | Web + news search | OFFICIAL connector OR self-hosted | If Spaces lists Brave in the connector catalog, use that. Otherwise self-host the remote MCP build of `brave-search-mcp` and add as Custom Connector. |
| Filesystem (MOR_INC + iCloudDrive/A1 Trading) | Read | NOT directly portable | See workaround below. |

## Filesystem workaround

Perplexity Spaces are cloud-hosted. They cannot read your local disk. Pick
one:

1. **Sync the folders to a cloud provider Pete already supports.**
   - Move (or symlink) `MOR_INC` and `iCloudDrive/A1 Trading` into a
     Google Drive / OneDrive / Dropbox folder, then add that provider's
     connector. Easiest. No code.
2. **Run a local-to-remote bridge.** On the Windows box:
   ```
   npx -y @modelcontextprotocol/server-filesystem `
     "C:/Users/michael oregan/MOR_INC" `
     "C:/Users/michael oregan/iCloudDrive/A1 Trading" |
   npx -y mcp-proxy --port 8765
   cloudflared tunnel --url http://localhost:8765
   ```
   Take the public `https://...trycloudflare.com` URL, register it as a
   Custom Connector in Pete's Space with bearer auth. Brittle - the
   tunnel dies if your laptop sleeps. Only use if option 1 won't work.
3. **Don't give Pete filesystem access at all.** If the docs Pete needs
   are also in Notion or GitHub, skip filesystem entirely. Lowest blast
   radius.

Recommendation: **option 1.** Don't run a tunnel just for read access.

## Setup steps

1. Open Perplexity, switch to Pete's Space, click the gear icon ->
   **Connectors**.
2. **Notion:** click Connect, OAuth, choose 'All pages' or scope to the
   workspace.
3. **GitHub:** click Connect, OAuth. On the GitHub authorize screen,
   review the scopes carefully:
   - Allow: `repo:status`, `public_repo`, `read:org`, `read:user`
   - Deny / do not grant: `repo` (full write), `admin:*`, `delete_repo`
   - If the connector requests broader scopes than read-only, **stop**
     and report it. Do not grant write to a research agent.
4. **Brave Search:** if listed, Connect + paste API key. If not listed,
   skip until the self-hosted bridge is up.
5. **Filesystem (MOR_INC + A1 Trading):** apply the workaround above.

## Hard rules for Pete

- **Read only.** No write tools attached. If a connector exposes write
  endpoints, disable them in the Space's tool toggle list.
- **No PAT reuse.** Pete uses OAuth on Notion/GitHub. Do not paste the
  workstation PAT (`GITHUB_PERSONAL_ACCESS_TOKEN` from `.env`) into a
  Perplexity connector - that PAT has write scope and would silently
  upgrade Pete's privileges.
- **Audit log.** After setup, ask Pete to list every tool he has
  available. Compare against the table above. Flag anything extra.

## Verification prompts

In Pete's chat after connecting:

```
List every tool you currently have access to, grouped by source.
For GitHub specifically, confirm whether you can write (create issues,
open PRs, push commits) or only read.
```

Expected: Notion (read+write), GitHub (read only - no create/push/merge
tools listed), Brave Search (search only), filesystem-equivalent (Drive
or whichever cloud provider). If GitHub write tools show up, revoke
the OAuth grant at https://github.com/settings/applications and
re-authorize with narrower scopes.
