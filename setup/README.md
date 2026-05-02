# MCP Setup for Claude Desktop, Claude Code, and Cursor

Corrected install sequence and configs for the local Windows workstation
used with MOR-Trading. Covers all three Claude/Cursor surfaces.

## Hard rule on access

Anything that touches your Windows machine - PowerShell, file copies into
`%APPDATA%`, killing/starting `claude.exe`, reading `.env` - **you have to
run yourself**. The remote agent that produced these files only has access
to your GitHub repos via the GitHub MCP server. It cannot reach your
workstation, your filesystem, or your installed apps.

## Files

| File | Target |
| --- | --- |
| `claude_desktop_config.json` | Claude Desktop (`%APPDATA%\Claude\claude_desktop_config.json`) |
| `claude_code_mcp.json` | Claude Code CLI, project-scoped (`./.mcp.json` in a project root) |
| `cursor_mcp.json` | Cursor, global (`%USERPROFILE%\.cursor\mcp.json`) or per-project (`<project>/.cursor/mcp.json`) |
| `install-mcp-servers.ps1` | Installs the underlying npm + uv tooling |
| `register-claude-code-mcp.ps1` | Registers servers with the Claude Code CLI at user scope |

## Install order

```powershell
# 1. Install the underlying servers (npm packages + uv).
.\setup\install-mcp-servers.ps1 -GithubPat '<your PAT>'

# 2a. Claude Desktop: copy the config and restart the app.
Copy-Item .\setup\claude_desktop_config.json `
  $env:APPDATA\Claude\claude_desktop_config.json
# Edit the copied file to paste your real PAT in place of the placeholder.
taskkill /IM claude.exe /F
Start-Process "$env:LOCALAPPDATA\AnthropicClaude\claude.exe"

# 2b. Claude Code CLI: register at user scope (recommended).
.\setup\register-claude-code-mcp.ps1 -GithubPat '<your PAT>'
claude mcp list   # verify

# 2c. Cursor: copy the config to the global location and restart Cursor.
New-Item -ItemType Directory -Force "$env:USERPROFILE\.cursor" | Out-Null
Copy-Item .\setup\cursor_mcp.json "$env:USERPROFILE\.cursor\mcp.json"
# Edit the copied file to paste your real PAT in place of the placeholder.
# Then: Cursor -> Settings -> MCP -> reload, or fully restart Cursor.
```

## Fixes vs. the original handoff sequence

1. **`pip install uvx` is invalid.** `uvx` ships with `uv`. Use
   `pip install --upgrade uv` (and optionally `uv tool install pinescript-mcp`).
2. **`~/.claude/mcp.json` is the wrong path for Claude Desktop.** Desktop
   reads `%APPDATA%\Claude\claude_desktop_config.json`. The `.claude/`
   directory is for the Claude Code CLI.
3. **`${GITHUB_PERSONAL_ACCESS_TOKEN}` interpolation isn't reliable.**
   Some Claude Desktop versions don't expand env-var references in the
   JSON config. The committed configs use a `REPLACE_WITH_PAT_OR_USE_ENV_VAR`
   placeholder so a real PAT is never committed - paste it into your local
   copy after running `Copy-Item`.

## Health checks (run inside the client after restart)

- `tv_health_check`
- `list_github_repos`
- `list_directory C:/Users/michael oregan/MOR-Trading`

All three should succeed.

## Security notes

- Scope the PAT minimally (typically `repo` + `read:org`).
- Never commit a populated config. The `.gitignore` should already block
  `*.local.json`; if you fork these files for personal edits, rename them
  with a `.local.json` suffix.
- Rotate the PAT if it has been pasted into any shared channel or doc.
