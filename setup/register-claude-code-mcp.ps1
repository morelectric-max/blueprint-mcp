<#
.SYNOPSIS
  Registers the same MCP servers with the Claude Code CLI at user scope.

.DESCRIPTION
  Uses 'claude mcp add' so the servers are available across every Claude
  Code session on this machine, not just one project. Idempotent: removes
  any existing entry with the same name before re-adding.

.PARAMETER GithubPat
  GitHub PAT to inject into the github MCP server. Required.

.PARAMETER TradingViewMcpPath
  Path to the local tradingview-mcp build directory.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$GithubPat,
  [string]$TradingViewMcpPath = "C:\Users\michael oregan\tradingview-mcp",
  [string]$FilesystemRoot = "C:\Users\michael oregan\MOR-Trading"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  throw "'claude' CLI not found in PATH. Install Claude Code first: https://docs.claude.com/claude-code"
}

function Add-McpServer {
  param(
    [string]$Name,
    [string[]]$CommandArgs,
    [hashtable]$EnvVars = @{}
  )
  Write-Host "==> Registering '$Name'" -ForegroundColor Cyan
  # Remove if it already exists; ignore failure if it doesn't.
  & claude mcp remove $Name --scope user 2>$null | Out-Null

  $envArgs = @()
  foreach ($key in $EnvVars.Keys) {
    $envArgs += @('-e', "$key=$($EnvVars[$key])")
  }

  & claude mcp add $Name --scope user @envArgs -- @CommandArgs
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to register MCP server '$Name'"
  }
}

Add-McpServer -Name 'tradingview' `
  -CommandArgs @('node', "$TradingViewMcpPath\dist\index.js") `
  -EnvVars @{ CDP_URL = 'http://127.0.0.1:9223' }

Add-McpServer -Name 'scheduler' `
  -CommandArgs @('npx', '-y', 'scheduler-mcp')

Add-McpServer -Name 'filesystem' `
  -CommandArgs @('npx', '-y', '@modelcontextprotocol/server-filesystem', $FilesystemRoot)

Add-McpServer -Name 'github' `
  -CommandArgs @('npx', '-y', '@modelcontextprotocol/server-github') `
  -EnvVars @{ GITHUB_PERSONAL_ACCESS_TOKEN = $GithubPat }

Add-McpServer -Name 'pinescript-docs' `
  -CommandArgs @('uvx', 'pinescript-mcp')

Add-McpServer -Name 'computer-use' `
  -CommandArgs @('npx', '-y', 'claude-computer-use-mcp')

Add-McpServer -Name 'pinescript-strategy' `
  -CommandArgs @('npx', '-y', 'pinescript-mcp-server')

Write-Host "`nDone. Verify with: claude mcp list" -ForegroundColor Green
