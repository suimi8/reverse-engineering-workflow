<#
.SYNOPSIS
Health-check the Cheat Engine MCP bridge: Node.js availability, Cheat Engine
process liveness, Lua bridge deployment, and Claude Code's MCP registration/
connection status. Every check is printed independently so a failure in one
step does not hide the others.

.PARAMETER CeDir
Root directory of the Cheat Engine installation (same resolution rules as
install.ps1). Only needed to check the autorun deployment.

.PARAMETER McpServerName
Server name to look up with `claude mcp get` (default: cheatengine).
#>

param(
    [string]$CeDir,
    [string]$McpServerName = "cheatengine"
)

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

Write-Host "Cheat Engine MCP status"

$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVersion = & node --version
    Write-Host "[OK] Node.js: $nodeVersion ($($nodeCmd.Source))"
} else {
    Write-Host "[WARN] Node.js not found on PATH."
    Write-Host "[INFO] download page: https://nodejs.org/en/download"
}

$ceRoot = Resolve-CeRoot -Hint $CeDir
if ($ceRoot) {
    Write-Host "[OK] Cheat Engine root: $ceRoot"
    $bridgePath = Join-Path $ceRoot 'autorun\ce_mcp_bridge.lua'
    if (Test-Path -LiteralPath $bridgePath) {
        Write-Host "[OK] Lua bridge deployed: $bridgePath"
    } else {
        Write-Host "[INFO] Lua bridge not deployed yet; run scripts\install.ps1"
    }
} else {
    Write-Host "[WARN] Cheat Engine root not found via auto-detect; pass -CeDir explicitly."
    Write-Host "[INFO] download page: https://cheatengine.org/"
}

$ceProcess = Get-Process -Name 'Cheat Engine' -ErrorAction SilentlyContinue
if ($ceProcess) {
    Write-Host "[OK] process running: Cheat Engine.exe (PID $($ceProcess.Id -join ','))"
} else {
    Write-Host "[INFO] process not running: Cheat Engine.exe (MCP bridge unreachable until it's open)"
}

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    Write-Host "[WARN] claude CLI not found on PATH; cannot check Claude-side registration."
    Write-Host "[INFO] install (PowerShell, no admin/Node.js needed): irm https://claude.ai/install.ps1 | iex"
    Write-Host "[INFO] alternative: winget install Anthropic.ClaudeCode"
    exit 0
}

Write-Host "--- claude mcp get $McpServerName ---"
& claude mcp get $McpServerName
