<#
.SYNOPSIS
Launch a target program with SSLKEYLOGFILE set, capture its network traffic
with tshark, and save a .pcapng (+ TLS key log when the target respects the
env var) for later analysis with capture-extract.ps1.

.DESCRIPTION
This is the broad-coverage capture path: it works at the OS/interface level,
so it sees traffic regardless of whether the target respects HTTP(S)_PROXY
env vars (unlike capture-mitm-run.ps1, which only sees what gets routed
through the proxy). The tradeoff is that TLS payloads only decrypt if the
target's TLS stack honors SSLKEYLOGFILE (most Chromium/Electron/OpenSSL/
BoringSSL-linked binaries do when the feature is compiled in; some apps
resolve their own auth via OS-level caches and bypass this — see
references/capture-cheatsheet.md "已知问题" for a real example).

Missing tshark prints the official download page and exits; it never
fabricates a direct-download URL or tries to silently install a packet
capture driver.

.PARAMETER TargetExe
Path to the program to launch.

.PARAMETER TargetArgs
Command-line arguments to pass to TargetExe (single string, passed as-is).

.PARAMETER DurationSeconds
How long tshark captures before auto-stopping (default 60).

.PARAMETER Interface
tshark interface number/name (from `tshark -D`). Auto-detected from the
default route's network adapter when omitted.

.PARAMETER CaptureFilter
Optional BPF capture filter (e.g. "host 1.2.3.4" or "tcp port 443") applied
live to keep the capture small. Omit to capture everything on the interface
and filter later at analysis time instead.

.PARAMETER OutDir
Directory to write the .pcapng and .sslkeylog.log files to (default .\captures).

.PARAMETER NoSslKeyLog
Skip setting SSLKEYLOGFILE (capture stays TLS-encrypted; useful when you
only need connection metadata/SNI hostnames, not decrypted payloads).

.PARAMETER ListInterfaces
Print `tshark -D` output and exit — use this once to find -Interface values
when auto-detection fails.
#>

param(
    [string]$TargetExe,
    [string]$TargetArgs = "",
    [int]$DurationSeconds = 60,
    [string]$Interface = "",
    [string]$CaptureFilter = "",
    [string]$OutDir = ".\captures",
    [switch]$NoSslKeyLog,
    [switch]$ListInterfaces
)

$ErrorActionPreference = 'Stop'

function Write-DownloadHint {
    param([string]$Tool, [string]$Page, [string]$Command)

    Write-Output "INFO:${Tool}_download_page:$Page"
    if ($Command) {
        Write-Output "INFO:${Tool}_download_command:$Command"
    }
}

$tsharkCmd = Get-Command tshark -ErrorAction SilentlyContinue
if (-not $tsharkCmd) {
    Write-Output "ERR:tshark_missing"
    Write-DownloadHint -Tool "wireshark" -Page "https://www.wireshark.org/download.html" -Command "the Windows installer bundles Npcap — make sure the 'Install Npcap' checkbox stays checked during setup"
    exit 1
}

if ($ListInterfaces) {
    & $tsharkCmd.Source -D
    exit 0
}

if ([string]::IsNullOrWhiteSpace($TargetExe)) {
    Write-Output "ERR:target_exe_required"
    exit 1
}
if (-not (Test-Path -LiteralPath $TargetExe)) {
    Write-Output "ERR:target_not_found:$TargetExe"
    exit 1
}

if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$pcapPath = Join-Path $OutDir "capture-$stamp.pcapng"
$sslKeyLogPath = Join-Path $OutDir "capture-$stamp.sslkeylog.log"

if ([string]::IsNullOrWhiteSpace($Interface)) {
    $defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
        Sort-Object -Property RouteMetric | Select-Object -First 1
    $adapter = if ($defaultRoute) { Get-NetAdapter -InterfaceIndex $defaultRoute.InterfaceIndex -ErrorAction SilentlyContinue } else { $null }
    $tsharkList = & $tsharkCmd.Source -D
    $matchLine = $null
    if ($adapter) {
        $matchLine = $tsharkList | Where-Object { $_ -like "*$($adapter.InterfaceDescription)*" } | Select-Object -First 1
    }
    if (-not $matchLine) {
        Write-Output "ERR:interface_autodetect_failed"
        Write-Output "INFO:list_interfaces_hint:re-run with -ListInterfaces, then pass -Interface <number>"
        exit 1
    }
    $Interface = ($matchLine -split '\.')[0].Trim()
}

$tsharkArgs = @('-i', $Interface, '-w', $pcapPath, '-a', "duration:$DurationSeconds")
if ($CaptureFilter) {
    $tsharkArgs += @('-f', $CaptureFilter)
}

$tsharkProcess = Start-Process -FilePath $tsharkCmd.Source -ArgumentList $tsharkArgs -PassThru -WindowStyle Hidden
Start-Sleep -Milliseconds 800

try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $TargetExe
    if ($TargetArgs) { $psi.Arguments = $TargetArgs }
    $psi.UseShellExecute = $false
    if (-not $NoSslKeyLog) {
        $psi.EnvironmentVariables["SSLKEYLOGFILE"] = $sslKeyLogPath
    }
    $targetProcess = [System.Diagnostics.Process]::Start($psi)
} catch {
    Stop-Process -Id $tsharkProcess.Id -Force -ErrorAction SilentlyContinue
    Write-Output "ERR:target_launch_failed:$($_.Exception.Message)"
    exit 1
}

Write-Output "INFO:capturing:target_pid=$($targetProcess.Id):interface=$Interface:duration=${DurationSeconds}s"

$tsharkProcess.WaitForExit()

Write-Output "OK:pcap=$pcapPath"
if (-not $NoSslKeyLog) {
    Write-Output "OK:sslkeylog=$sslKeyLogPath"
    Write-Output "INFO:decrypt_hint:open pcap in Wireshark, Edit > Preferences > Protocols > TLS > (Pre)-Master-Secret log filename = sslkeylog path above"
}
Write-Output "INFO:target_still_running:$(-not $targetProcess.HasExited)"
exit 0
