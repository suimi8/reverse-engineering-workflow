<#
.SYNOPSIS
Health-check the x64dbg-mcp-server plugin: process liveness, HTTP-layer
connectivity on both architecture ports, local mcp_config.json contents, and
Claude Code's own MCP registration/connection status. Every check is printed
independently so a failure in one step does not hide the others.

.PARAMETER X64dbgDir
Root directory of the x64dbg installation (same resolution rules as
install.ps1). Only needed to read mcp_config.json; the port probes work
regardless.

.PARAMETER McpServerName
Server name to look up with `claude mcp get` (default: x64dbg).
#>

param(
    [string]$X64dbgDir,
    [string]$McpServerName = "x64dbg"
)

function Resolve-X64dbgRoot {
    param([string]$Hint)

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($Hint)) {
        $candidates += $Hint
    }
    $candidates += @(
        'D:\x64dbg',
        'C:\x64dbg',
        (Join-Path $env:USERPROFILE 'Tools\x64dbg'),
        (Join-Path $env:USERPROFILE 'Tools\x64dbg\release')
    )

    foreach ($base in $candidates) {
        if ([string]::IsNullOrWhiteSpace($base)) { continue }
        if ((Test-Path (Join-Path $base 'x64\x64dbg.exe')) -or (Test-Path (Join-Path $base 'x32\x32dbg.exe'))) {
            return (Resolve-Path -LiteralPath $base).Path
        }
        $releaseRoot = Join-Path $base 'release'
        if ((Test-Path (Join-Path $releaseRoot 'x64\x64dbg.exe')) -or (Test-Path (Join-Path $releaseRoot 'x32\x32dbg.exe'))) {
            return (Resolve-Path -LiteralPath $releaseRoot).Path
        }
    }

    return $null
}

function Test-PortListening {
    param([int]$Port)

    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/" -Method Post -Body '{}' `
            -ContentType "application/json" -TimeoutSec 3 -ErrorAction Stop
        return $true
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response
        if ($resp -and [int]$resp.StatusCode -eq 401) {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

Write-Host "x64dbg MCP status"

$root = Resolve-X64dbgRoot -Hint $X64dbgDir
if ($root) {
    Write-Host "[OK] x64dbg root: $root"
} else {
    Write-Host "[WARN] x64dbg root not found via auto-detect; pass -X64dbgDir explicitly."
    Write-Host "[INFO] download page: https://x64dbg.com/"
    Write-Host "[INFO] direct releases: https://github.com/x64dbg/x64dbg/releases (asset: snapshot_*.zip)"
    Write-Host "[INFO] or run: scripts\install.ps1 -AutoInstallX64dbg   (downloads + extracts it for you)"
}

foreach ($proc in @('x64dbg', 'x32dbg')) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "[OK] process running: $proc.exe (PID $($running.Id -join ','))"
    } else {
        Write-Host "[INFO] process not running: $proc.exe"
    }
}

$ports = @{ x64 = 9094; x32 = 9095 }
foreach ($arch in $ports.Keys) {
    $port = $ports[$arch]
    if (Test-PortListening -Port $port) {
        Write-Host "[OK] $arch MCP endpoint listening on port $port"
    } else {
        Write-Host "[INFO] $arch MCP endpoint not reachable on port $port (x64dbg/x32dbg not running or plugin not loaded)"
    }

    if ($root) {
        $configPath = Join-Path (Join-Path $root $arch) 'mcp_config.json'
        if (Test-Path -LiteralPath $configPath) {
            try {
                $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
                $tokenPreview = if ($config.AuthToken) { $config.AuthToken.Substring(0, [Math]::Min(8, $config.AuthToken.Length)) + "..." } else { "(missing)" }
                Write-Host "[OK] $arch mcp_config.json: bind=$($config.IpAddress) port=$($config.Port) token=$tokenPreview"
            } catch {
                Write-Host "[WARN] $arch mcp_config.json exists but failed to parse: $configPath"
            }
        } else {
            Write-Host "[INFO] $arch mcp_config.json not found yet (plugin has not completed a first run)."
        }
    }
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
