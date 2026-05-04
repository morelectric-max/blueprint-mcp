<#
.SYNOPSIS
  One-shot cleanup for the MOR-Trading workstation.

.DESCRIPTION
  Run this from PowerShell. It does everything in order:
    1. Deletes the plaintext PAT file from iCloud (it leaked into logs).
    2. Truncates the Claude Desktop MCP logs that contain the leaked PAT.
    3. Adds Git to the User PATH so uvx-spawned servers stop failing.
    4. Removes the three broken MCP servers (tradingview-screener,
       Desktop Commander, openbb) from claude_desktop_config.json -
       backed up first.
    5. Restarts Claude Desktop.

  After running, open https://github.com/settings/tokens and revoke the
  leaked PAT manually (the script can't do that for you).

.NOTES
  No parameters. Run from any PowerShell prompt:
    iwr https://raw.githubusercontent.com/morelectric-max/blueprint-mcp/main/setup/fix-everything.ps1 -OutFile fix.ps1
    .\fix.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "   OK  $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "   !!  $msg" -ForegroundColor Yellow }

Step '1/5  Deleting leaked PAT file'
$leaked = "C:\Users\michael oregan\iCloudDrive\AA WORK FILES\A1 Trading\GITHUB KEY NEW.txt"
if (Test-Path $leaked) {
  Remove-Item $leaked -Force
  Ok "Deleted $leaked"
} else {
  Warn 'File already gone (or path different).'
}

Step '2/5  Truncating MCP log files (they contain the PAT)'
$logDir = "$env:AppData\Claude\logs"
if (Test-Path $logDir) {
  Get-ChildItem $logDir -Filter 'mcp*.log' | ForEach-Object {
    Clear-Content $_.FullName
    Ok "Cleared $($_.Name)"
  }
} else {
  Warn 'No log dir found - skipping.'
}

Step '3/5  Adding Git to User PATH (fixes uvx-spawned servers)'
$gitPath = 'C:\Program Files\Git\cmd'
if (Test-Path $gitPath) {
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($userPath -notlike "*$gitPath*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$gitPath", 'User')
    Ok "Added $gitPath to User PATH (takes effect on next process start)"
  } else {
    Ok 'Git already on User PATH.'
  }
} else {
  Warn "Git not found at $gitPath - install from https://git-scm.com/download/win"
}

Step '4/5  Pruning broken servers from claude_desktop_config.json'
$cfg = "$env:AppData\Claude\claude_desktop_config.json"
if (Test-Path $cfg) {
  $backup = "$cfg.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  Copy-Item $cfg $backup
  Ok "Backed up to $backup"

  $json = Get-Content $cfg -Raw | ConvertFrom-Json
  $broken = @('tradingview-screener', 'Desktop Commander', 'openbb')
  foreach ($name in $broken) {
    if ($json.mcpServers.PSObject.Properties.Name -contains $name) {
      $json.mcpServers.PSObject.Properties.Remove($name)
      Ok "Removed '$name'"
    }
  }
  $json | ConvertTo-Json -Depth 10 | Set-Content $cfg -Encoding UTF8
} else {
  Warn "Config not found at $cfg - skipping."
}

Step '5/5  Restarting Claude Desktop'
Get-Process claude -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
$exe = "$env:LocalAppData\AnthropicClaude\claude.exe"
if (Test-Path $exe) {
  Start-Process $exe
  Ok 'Claude Desktop restarted'
} else {
  Warn "Claude exe not found at $exe - start it manually."
}

Write-Host @"

DONE. One thing left for you to do manually:

  1. Open https://github.com/settings/tokens
  2. Revoke the token starting with 'ghp_feH6...'
  3. Generate a new one with scopes: repo, read:org
  4. Paste the new value into your .env (NOT into any .txt file inside
     an MCP-readable folder this time).

Then test in Claude Desktop:
  tv_health_check
  list_github_repos

"@ -ForegroundColor Green
