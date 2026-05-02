<#
.SYNOPSIS
  Installs the MCP servers used by the MOR-Trading Claude Desktop setup.

.DESCRIPTION
  Run from an elevated PowerShell prompt. Idempotent: safe to re-run.
  Replaces the original handoff sequence with corrected commands:
    - 'pip install uvx' -> 'pip install uv' (uvx ships with uv)
    - 'uvx install pinescript-mcp' removed (uvx runs tools on demand;
      use 'uv tool install pinescript-mcp' if you want it persisted)

.PARAMETER GithubPat
  Optional. If supplied, sets GITHUB_PERSONAL_ACCESS_TOKEN at User scope.
  Prefer passing via -GithubPat over hardcoding.
#>
[CmdletBinding()]
param(
  [string]$GithubPat,
  [string]$TradingViewMcpPath = "C:\Users\michael oregan\tradingview-mcp"
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

Write-Step 'Checking prerequisites (node, npm, python)'
foreach ($cmd in 'node','npm','python') {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "Required command '$cmd' not found in PATH."
  }
}

if ($GithubPat) {
  Write-Step 'Setting GITHUB_PERSONAL_ACCESS_TOKEN (User scope)'
  [System.Environment]::SetEnvironmentVariable(
    'GITHUB_PERSONAL_ACCESS_TOKEN', $GithubPat, 'User')
  $env:GITHUB_PERSONAL_ACCESS_TOKEN = $GithubPat
} else {
  Write-Host 'Skipping PAT setup (no -GithubPat passed).' -ForegroundColor Yellow
}

Write-Step 'Installing global npm MCP servers'
$npmPackages = @(
  '@modelcontextprotocol/server-filesystem',
  '@modelcontextprotocol/server-github',
  'scheduler-mcp',
  'pinescript-mcp-server',
  'claude-computer-use-mcp'
)
foreach ($pkg in $npmPackages) {
  Write-Host "  npm install -g $pkg"
  npm install -g $pkg
}

Write-Step 'Installing uv (provides uvx)'
# Original handoff said 'pip install uvx' which does not exist on PyPI.
# uvx is bundled with uv.
pip install --upgrade uv

Write-Step 'Installing pinescript-mcp as a persistent uv tool'
# Optional: pre-warm so first 'uvx pinescript-mcp' launch is fast.
uv tool install pinescript-mcp

Write-Step 'Verifying TradingView MCP build'
if (-not (Test-Path $TradingViewMcpPath)) {
  Write-Warning "TradingView MCP path not found: $TradingViewMcpPath (skipping build check)"
} else {
  Push-Location $TradingViewMcpPath
  try {
    if (-not (Test-Path 'dist/index.js')) {
      Write-Host '  dist/index.js missing - running npm install && npm run build'
      npm install
      npm run build
    }
    node dist/index.js --version
  } finally {
    Pop-Location
  }
}

Write-Step 'Done. Next: copy setup/claude_desktop_config.json into:'
Write-Host '  %APPDATA%\Claude\claude_desktop_config.json'
Write-Host 'Then restart Claude Desktop.'
