# Service Persistence Checklist

Use this checklist after `windows-local-service-persistence` is selected.

## Baseline

```powershell
Get-NetTCPConnection -LocalPort <PORT> -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,State,OwningProcess
Get-Process -Id <PID> -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path,StartTime,Responding
curl.exe -s http://127.0.0.1:<PORT>/<health-or-status-path>
```

## PowerShell Launcher Pattern

```powershell
$ErrorActionPreference = "SilentlyContinue"
$port = 18788
$existing = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($existing) { exit 0 }
$exePath = Join-Path $env:LOCALAPPDATA "AppName\runtime\helper.exe"
$scriptPath = Join-Path $env:LOCALAPPDATA "AppName\helper-script.js"
if (!(Test-Path -LiteralPath $exePath) -or !(Test-Path -LiteralPath $scriptPath)) { exit 1 }
Start-Process -FilePath $exePath -ArgumentList @($scriptPath) -WindowStyle Hidden -WorkingDirectory (Split-Path -Parent $scriptPath)
```

## Startup Cmd Pattern

```cmd
@echo off
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%LOCALAPPDATA%\AppName\start-helper.ps1"
```

## Scheduled Task Fallback

If user-level scheduled task registration fails with access denied, use the Startup folder pattern and report the fallback.

```powershell
schtasks /Query /TN "AppNameLocalHelper"
```

## Cold-Start Verification

Only stop the helper process, not the main app, unless the user asks for a full app restart:

```powershell
$listener = Get-NetTCPConnection -LocalPort <PORT> -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($listener) { taskkill /PID $listener.OwningProcess /F | Out-Null }
Start-Sleep -Milliseconds 800
& "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\AppNameHelper.cmd"
Start-Sleep -Milliseconds 1200
Get-NetTCPConnection -LocalPort <PORT> -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,State,OwningProcess
curl.exe -s http://127.0.0.1:<PORT>/<health-or-status-path>
```

Report the launcher path, helper executable path, PID, port, health response summary, and whether the cold-start check passed.
