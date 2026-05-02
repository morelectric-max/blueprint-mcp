# DO THIS - step-by-step setup on the Windows workstation

Copy-paste in order. Each block is one command (or one file edit). Don't
skip steps. Stop and ping if anything errors.

## 0. Prerequisites (one-time)

You need these installed and on `PATH`. Check by running each in
PowerShell - if any errors with 'not recognized', install it first.

```powershell
node --version    # need v18+
npm --version
python --version  # need 3.10+
git --version
claude --version  # only needed if you want Claude Code CLI; skip if not
```

Installers if missing:
- Node.js: https://nodejs.org (LTS)
- Python: https://www.python.org/downloads/
- Git: https://git-scm.com/download/win
- Claude Code CLI: https://docs.claude.com/claude-code

## 1. Pull this branch

```powershell
cd "C:\Users\michael oregan"
git clone https://github.com/morelectric-max/blueprint-mcp.git
cd blueprint-mcp
git checkout claude/setup-github-pat-mcp-ekzLx
```

If you already have the repo cloned:

```powershell
cd "C:\Users\michael oregan\blueprint-mcp"
git fetch origin
git checkout claude/setup-github-pat-mcp-ekzLx
git pull origin claude/setup-github-pat-mcp-ekzLx
```

## 2. Get your PAT ready

Open your `.env` file in Notepad and copy the value of
`GITHUB_PERSONAL_ACCESS_TOKEN`. You'll paste it into commands below.
Do NOT paste it into chat or commit it.

If you don't have one, create at: https://github.com/settings/tokens
Scopes needed: `repo`, `read:org`. Set expiration to 90 days.

## 3. Install the underlying servers

Open PowerShell **as Administrator** (right-click -> Run as administrator),
then:

```powershell
cd "C:\Users\michael oregan\blueprint-mcp"
# Allow the script to run for this session only:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup\install-mcp-servers.ps1 -GithubPat 'PASTE_YOUR_PAT_HERE'
```

This takes 2-5 minutes. It installs five npm packages globally, installs
`uv` (which provides `uvx`), and verifies your local `tradingview-mcp`
build. Errors usually mean a prerequisite from step 0 is missing.

## 4a. Wire up Claude Desktop

```powershell
# Copy the config into Claude Desktop's config folder.
Copy-Item .\setup\claude_desktop_config.json `
  $env:APPDATA\Claude\claude_desktop_config.json -Force

# Open the copied file in Notepad and paste your real PAT in place of
# REPLACE_WITH_PAT_OR_USE_ENV_VAR. Save and close.
notepad $env:APPDATA\Claude\claude_desktop_config.json

# Restart Claude Desktop.
taskkill /IM claude.exe /F
Start-Process "$env:LOCALAPPDATA\AnthropicClaude\claude.exe"
```

## 4b. Wire up Claude Code CLI (skip if you don't use it)

```powershell
.\setup\register-claude-code-mcp.ps1 -GithubPat 'PASTE_YOUR_PAT_HERE'
claude mcp list
```

`claude mcp list` should show all seven servers with status `connected`.

## 4c. Wire up Cursor (skip if you don't use it)

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.cursor" | Out-Null
Copy-Item .\setup\cursor_mcp.json "$env:USERPROFILE\.cursor\mcp.json" -Force
notepad "$env:USERPROFILE\.cursor\mcp.json"
# Paste your real PAT, save, close.
# Then fully quit and restart Cursor.
```

## 5. Health checks

In each client where you wired things up, open a new chat and run:

```
tv_health_check
list_github_repos
list_directory C:/Users/michael oregan/MOR-Trading
```

All three should succeed. If `tv_health_check` fails, your TradingView
browser isn't running with `--remote-debugging-port=9223`. If
`list_github_repos` fails, the PAT is wrong or expired. If `list_directory`
fails, the path in the config doesn't exist.

## 6. (Optional) Enable the GitHub connector in claude.ai

For chatting in the browser. See `setup/claude-ai-connectors.md` for the
four-step OAuth flow. Recommended even if you also have it locally - lets
you check repos from your phone.

## 7. Post results

Drop a thumbs-up in the handoff channel with the three health-check
outputs. Gadget picks it up from there for the Push Comms build.

## Troubleshooting cheat sheet

| Symptom | Fix |
| --- | --- |
| `npm install -g` fails with EACCES / permission errors | Re-open PowerShell as Administrator. |
| `uvx: command not found` after install | Close and re-open PowerShell so `PATH` refreshes. |
| Claude Desktop shows no MCP tools after restart | Check `%APPDATA%\Claude\logs\mcp*.log` for the failing server name. |
| GitHub MCP returns 401 | PAT is expired or wrong scope. Regenerate, re-run step 4a/4b/4c. |
| `claude mcp list` shows `failed` | Run `claude mcp get <name>` to see the exact command + env it's using. |
