<#
.SYNOPSIS
Deploy the Cheat Engine MCP Lua bridge into Cheat Engine's autorun folder and
register the Node.js-based ce_mcp stdio MCP server with Claude Code.

.DESCRIPTION
Every required piece of software is handled the same way when missing: this
script never fails silently. Missing Node.js or missing Cheat Engine print
the official download page and exit — neither has a reliable, scriptable
direct-download URL (unlike x64dbg/Ghidra/radare2's GitHub Releases API), so
this script does not fabricate one and does not attempt to auto-install
either. See MODULE.md "已知问题" for the reasoning.

.PARAMETER CeMcpSourceDir
Path to a local checkout of the ce_mcp project (must contain ce_mcp_server.js
and ce_mcp_bridge.lua). Required — this project has no confirmed stable
public source repo to auto-fetch from, so a local path must be provided.

.PARAMETER CeDir
Root directory of an existing Cheat Engine installation (contains
"Cheat Engine.exe"). Auto-detected from common paths when omitted.

.PARAMETER McpServerName
Name to register with `claude mcp add` (default: cheatengine).

.PARAMETER Scope
claude mcp add scope: user (global, default), local, or project.

.PARAMETER SkipClaudeRegister
Only deploy the Lua bridge; do not touch Claude's MCP configuration.

.PARAMETER LaunchWaitSeconds
How long to wait after launching Cheat Engine for it to finish starting and
loading autorun scripts (only used when CE was not already running).
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CeMcpSourceDir,
    [string]$CeDir,
    [string]$McpServerName = "cheatengine",
    [ValidateSet("user", "local", "project")]
    [string]$Scope = "user",
    [switch]$SkipClaudeRegister,
    [int]$LaunchWaitSeconds = 8
)

$ErrorActionPreference = 'Stop'

function Write-DownloadHint {
    param([string]$Tool, [string]$Page, [string]$Command)

    Write-Output "INFO:${Tool}_download_page:$Page"
    if ($Command) {
        Write-Output "INFO:${Tool}_download_command:$Command"
    }
}

function Resolve-CeRoot {
    param([string]$Hint)

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($Hint)) {
        $candidates += $Hint
    }
    $candidates += @(
        'D:\Cheat Engine',
        'C:\Cheat Engine',
        'C:\Program Files\Cheat Engine',
        'C:\Program Files (x86)\Cheat Engine'
    )

    foreach ($base in $candidates) {
        if ([string]::IsNullOrWhiteSpace($base)) { continue }
        if (Test-Path (Join-Path $base 'Cheat Engine.exe')) {
            return (Resolve-Path -LiteralPath $base).Path
        }
    }

    return $null
}

$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Output "ERR:node_missing"
    Write-DownloadHint -Tool "nodejs" -Page "https://nodejs.org/en/download" -Command ""
    exit 1
}

$serverScript = Join-Path $CeMcpSourceDir 'ce_mcp_server.js'
$bridgeScript = Join-Path $CeMcpSourceDir 'ce_mcp_bridge.lua'
if (-not (Test-Path -LiteralPath $serverScript) -or -not (Test-Path -LiteralPath $bridgeScript)) {
    Write-Output "ERR:ce_mcp_source_not_found:$CeMcpSourceDir"
    exit 1
}

$ceRoot = Resolve-CeRoot -Hint $CeDir
if (-not $ceRoot) {
    Write-Output "ERR:ce_not_found"
    Write-DownloadHint -Tool "cheatengine" -Page "https://cheatengine.org/" -Command ""
    exit 1
}

$autorunDir = Join-Path $ceRoot 'autorun'
if (-not (Test-Path -LiteralPath $autorunDir)) {
    New-Item -ItemType Directory -Path $autorunDir -Force | Out-Null
}
Copy-Item -LiteralPath $bridgeScript -Destination (Join-Path $autorunDir 'ce_mcp_bridge.lua') -Force

$ceProcess = Get-Process -Name 'Cheat Engine' -ErrorAction SilentlyContinue
if (-not $ceProcess) {
    Start-Process -FilePath (Join-Path $ceRoot 'Cheat Engine.exe') | Out-Null
    Start-Sleep -Seconds $LaunchWaitSeconds
}

if ($SkipClaudeRegister) {
    Write-Output "OK:${McpServerName}:bridge-deployed"
    exit 0
}

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    Write-Output "OK:${McpServerName}:bridge-deployed"
    Write-Output "ERR:claude_cli_missing"
    Write-DownloadHint -Tool "claude_code" -Page "https://claude.ai/install.ps1" -Command "irm https://claude.ai/install.ps1 | iex   (PowerShell, no admin/Node.js needed; alt: winget install Anthropic.ClaudeCode)"
    exit 1
}

# Best-effort clean slate so re-running after moving CeMcpSourceDir updates the command path.
& claude mcp remove --scope $Scope $McpServerName *> $null

& claude mcp add --transport stdio --scope $Scope $McpServerName -- node $serverScript | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Output "ERR:claude_mcp_add_failed"
    exit 1
}

Write-Output "OK:${McpServerName}"
exit 0
