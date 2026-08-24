<#
.SYNOPSIS
Deploy the x64dbg-mcp-server plugin (duty1g/x64dbg-mcp-server) into a local x64dbg
installation, let it generate its auth token, and register it as an MCP server in
Claude Code.

.DESCRIPTION
Every required piece of software is handled the same way when missing: this script
never fails silently. It either fetches the dependency for you when explicitly
allowed to, or it prints the exact official download page/command so you (or the
calling agent) can get it in one step. Nothing is installed system-wide without an
explicit switch.

.PARAMETER X64dbgDir
Root directory of an existing x64dbg installation. Accepts either a flat layout
(<dir>\x32, <dir>\x64) or the official snapshot layout (<dir>\release\x32,
<dir>\release\x64). Auto-detected from common paths when omitted.

.PARAMETER AutoInstallX64dbg
If x64dbg itself cannot be found, download the official x64dbg/x64dbg snapshot
release and extract it to -X64dbgInstallDir instead of just printing download
instructions. Opt-in: installing a full GUI debugger is a bigger action than
deploying a plugin, so this is never done unless explicitly requested.

.PARAMETER X64dbgInstallDir
Where to extract x64dbg when -AutoInstallX64dbg is used. Defaults to
"%USERPROFILE%\Tools\x64dbg" (same convention as the sibling jadx/apktool/r2/ghidra
entries in bootstrap-manifest.json).

.PARAMETER Arch
Which architecture's MCP endpoint to deploy/register: x64 (port 9094, default)
or x32 (port 9095). x64 and x32 are independent plugin instances; run this
script twice (once per Arch) to cover both.

.PARAMETER McpServerName
Name to register with `claude mcp add`. Defaults to "x64dbg" for -Arch x64 and
"x64dbg-x32" for -Arch x32, so both can be registered side by side.

.PARAMETER Scope
claude mcp add scope: user (global, default), local, or project.

.PARAMETER SkipClaudeRegister
Only deploy the plugin files; do not touch Claude's MCP configuration.

.PARAMETER TimeoutSeconds
How long to wait for x64dbg to generate mcp_config.json on first launch.
#>

param(
    [string]$X64dbgDir,
    [switch]$AutoInstallX64dbg,
    [string]$X64dbgInstallDir,
    [ValidateSet("x64", "x32")]
    [string]$Arch = "x64",
    [string]$McpServerName,
    [ValidateSet("user", "local", "project")]
    [string]$Scope = "user",
    [switch]$SkipClaudeRegister,
    [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($McpServerName)) {
    $McpServerName = if ($Arch -eq "x32") { "x64dbg-x32" } else { "x64dbg" }
}
if ([string]::IsNullOrWhiteSpace($X64dbgInstallDir)) {
    $X64dbgInstallDir = Join-Path $env:USERPROFILE 'Tools\x64dbg'
}

function Write-DownloadHint {
    param([string]$Tool, [string]$Page, [string]$Command)

    Write-Output "INFO:${Tool}_download_page:$Page"
    if ($Command) {
        Write-Output "INFO:${Tool}_download_command:$Command"
    }
}

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

        # Flat layout: <base>\x32\x32dbg.exe, <base>\x64\x64dbg.exe
        if ((Test-Path (Join-Path $base 'x64\x64dbg.exe')) -or (Test-Path (Join-Path $base 'x32\x32dbg.exe'))) {
            return (Resolve-Path -LiteralPath $base).Path
        }

        # Official snapshot layout: <base>\release\x32|x64
        $releaseRoot = Join-Path $base 'release'
        if ((Test-Path (Join-Path $releaseRoot 'x64\x64dbg.exe')) -or (Test-Path (Join-Path $releaseRoot 'x32\x32dbg.exe'))) {
            return (Resolve-Path -LiteralPath $releaseRoot).Path
        }
    }

    return $null
}

function Install-X64dbgSnapshot {
    param([string]$DestDir)

    $releaseApi = "https://api.github.com/repos/x64dbg/x64dbg/releases/latest"
    $release = Invoke-RestMethod -Uri $releaseApi -Headers @{ "User-Agent" = "reverse-engineering-workflow" } -ErrorAction Stop
    $asset = $release.assets | Where-Object { $_.name -like "snapshot_*.zip" } | Select-Object -First 1
    if (-not $asset) {
        throw "no snapshot_*.zip asset found on the latest x64dbg/x64dbg release"
    }

    if (-not (Test-Path -LiteralPath $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }

    $tempZip = Join-Path $env:TEMP ("x64dbg-snapshot-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8) + ".zip")
    try {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $tempZip -DestinationPath $DestDir -Force
    } finally {
        Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue
    }
}

$root = Resolve-X64dbgRoot -Hint $X64dbgDir

if (-not $root -and $AutoInstallX64dbg) {
    try {
        Install-X64dbgSnapshot -DestDir $X64dbgInstallDir
    } catch {
        Write-Output "ERR:x64dbg_auto_install_failed:$($_.Exception.Message)"
        Write-DownloadHint -Tool "x64dbg" -Page "https://x64dbg.com/" -Command "https://github.com/x64dbg/x64dbg/releases (asset: snapshot_*.zip)"
        exit 1
    }
    $root = Resolve-X64dbgRoot -Hint $X64dbgInstallDir
}

if (-not $root) {
    Write-Output "ERR:x64dbg_not_found"
    Write-DownloadHint -Tool "x64dbg" -Page "https://x64dbg.com/" -Command "https://github.com/x64dbg/x64dbg/releases (asset: snapshot_*.zip)"
    Write-Output "INFO:x64dbg_auto_install_hint:re-run with -AutoInstallX64dbg to download and extract it to $X64dbgInstallDir automatically"
    exit 1
}

$archDir = Join-Path $root $Arch
$exeName = if ($Arch -eq "x32") { "x32dbg.exe" } else { "x64dbg.exe" }
$exePath = Join-Path $archDir $exeName
if (-not (Test-Path -LiteralPath $exePath)) {
    Write-Output "ERR:arch_binary_missing:$exePath"
    Write-DownloadHint -Tool "x64dbg" -Page "https://x64dbg.com/" -Command "https://github.com/x64dbg/x64dbg/releases (asset: snapshot_*.zip)"
    exit 1
}

$pluginFile = if ($Arch -eq "x32") { "x64dbg-MCP-Server.dp32" } else { "x64dbg-MCP-Server.dp64" }
$pluginsDir = Join-Path $archDir 'plugins'
$pluginDest = Join-Path $pluginsDir $pluginFile

if (-not (Test-Path -LiteralPath $pluginDest)) {
    $tempDir = Join-Path $env:TEMP ("x64dbg-mcp-" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8))
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    try {
        try {
            $releaseApi = "https://api.github.com/repos/duty1g/x64dbg-mcp-server/releases/latest"
            $release = Invoke-RestMethod -Uri $releaseApi -Headers @{ "User-Agent" = "reverse-engineering-workflow" } -ErrorAction Stop
            $asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
            if (-not $asset) {
                throw "no .zip asset found on the latest duty1g/x64dbg-mcp-server release"
            }

            $zipPath = Join-Path $tempDir $asset.name
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-Output "ERR:plugin_download_failed:$($_.Exception.Message)"
            Write-DownloadHint -Tool "x64dbg-mcp-server" -Page "https://github.com/duty1g/x64dbg-mcp-server/releases/latest" -Command "download the zip and re-run this script, or place $pluginFile directly into $pluginsDir"
            exit 1
        }

        $extractDir = Join-Path $tempDir 'extracted'
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

        $srcPlugin = Get-ChildItem -LiteralPath $extractDir -Filter $pluginFile -Recurse | Select-Object -First 1
        if (-not $srcPlugin) {
            Write-Output "ERR:plugin_file_not_in_release"
            Write-DownloadHint -Tool "x64dbg-mcp-server" -Page "https://github.com/duty1g/x64dbg-mcp-server/releases/latest" -Command ""
            exit 1
        }

        if (-not (Test-Path -LiteralPath $pluginsDir)) {
            New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $srcPlugin.FullName -Destination $pluginDest -Force
    } finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$configPath = Join-Path $archDir 'mcp_config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    Start-Process -FilePath $exePath | Out-Null

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $configPath)) {
        Start-Sleep -Milliseconds 1000
    }
    if (-not (Test-Path -LiteralPath $configPath)) {
        Write-Output "ERR:config_timeout"
        exit 1
    }
    # Give the plugin a brief moment to finish writing before reading it.
    Start-Sleep -Milliseconds 500
}

try {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
} catch {
    Write-Output "ERR:config_parse_failed"
    exit 1
}

$port = $config.Port
$token = $config.AuthToken
if (-not $port -or -not $token) {
    Write-Output "ERR:config_incomplete"
    exit 1
}

if ($SkipClaudeRegister) {
    Write-Output "OK:${McpServerName}:${port}:plugin-only"
    exit 0
}

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    Write-Output "OK:${McpServerName}:${port}:plugin-deployed"
    Write-Output "ERR:claude_cli_missing"
    Write-DownloadHint -Tool "claude_code" -Page "https://claude.ai/install.ps1" -Command "irm https://claude.ai/install.ps1 | iex   (PowerShell, no admin/Node.js needed; alt: winget install Anthropic.ClaudeCode)"
    exit 1
}

# Best-effort clean slate so a rotated token is picked up instead of erroring on a duplicate name.
& claude mcp remove --scope $Scope $McpServerName *> $null

& claude mcp add --transport http --scope $Scope $McpServerName "http://localhost:$port/" --header "Authorization: Bearer $token" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Output "ERR:claude_mcp_add_failed"
    exit 1
}

Write-Output "OK:${McpServerName}:${port}"
exit 0
