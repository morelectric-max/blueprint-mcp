# MCP Setup for Claude Desktop (MOR-Trading)

Corrected install sequence and config for the local Windows Claude Desktop
environment used with MOR-Trading.

## Files

- `claude_desktop_config.json` - drop-in config for Claude Desktop. Goes in:
  ```
  %APPDATA%\Claude\claude_desktop_config.json
  ```
  (NOT `~/.claude/mcp.json` - that path is for the Claude Code CLI.)
- `install-mcp-servers.ps1` - idempotent PowerShell installer.

## Fixes vs. the original handoff

1. **`pip install uvx` is invalid.** `uvx` ships with `uv`. The script now
   runs `pip install --upgrade uv` and then `uv tool install pinescript-mcp`
   to pre-warm the tool cache.
2. **Config file location was wrong.** Claude Desktop on Windows reads
   `%APPDATA%\Claude\claude_desktop_config.json`. `~/.claude/mcp.json` is the
   Claude Code CLI config and is not loaded by Claude Desktop.
3. **`${GITHUB_PERSONAL_ACCESS_TOKEN}` substitution is unreliable.** Some
   versions of Claude Desktop do not expand env-var references in the JSON
   config. The committed config has a `REPLACE_WITH_PAT_OR_USE_ENV_VAR`
   placeholder - either paste the PAT in directly (and keep this file out
   of any public repo), or test that your Desktop version expands `${VAR}`
   first.

## Usage

```powershell
# From an elevated PowerShell:
.\install-mcp-servers.ps1 -GithubPat '<your PAT>'

# Then copy the config:
Copy-Item .\claude_desktop_config.json $env:APPDATA\Claude\claude_desktop_config.json

# Restart Claude Desktop:
taskkill /IM claude.exe /F
Start-Process "$env:LOCALAPPDATA\AnthropicClaude\claude.exe"
```

## Health checks (run in Claude after restart)

- `tv_health_check`
- `list_github_repos`
- `list_directory C:/Users/michael oregan/MOR-Trading`

All three should return successfully.

## Security notes

- The PAT should be scoped minimally (typically `repo` + `read:org`).
- Do not commit a real PAT to this repo. The placeholder in
  `claude_desktop_config.json` is intentional.
- Rotate the PAT if it has been pasted into any shared channel or doc.
