# Windows Recovery Checklist

Use this checklist only after `windows-python-app-recovery` has been selected and the target is the user's own or authorized Windows Python desktop app.

## Package Triage

Read-only first pass:

```powershell
rg --files
Get-ChildItem -Force
Get-ChildItem -Recurse -Filter "*.exe" | Select-Object FullName,Length
Get-ChildItem -Recurse -Include "python*.dll","*.pyd","base_library.zip","flet.exe","node.exe" | Select-Object FullName,Length
```

Search binaries and resources for framework and state clues:

```powershell
rg -a -n "Nuitka|PyInstaller|cx_Freeze|flet|LOCALAPPDATA|APPDATA|127\.0\.0\.1|localhost|license|machine_id|token|\.env|sqlite|config" .
```

## Mutable State Discovery

Inspect user-writable locations before touching packaged files:

```powershell
Get-ChildItem "$env:LOCALAPPDATA" -Directory | Select-Object FullName,LastWriteTime
Get-ChildItem "$env:APPDATA" -Directory | Select-Object FullName,LastWriteTime
Get-ChildItem "$env:PROGRAMDATA" -Directory -ErrorAction SilentlyContinue | Select-Object FullName,LastWriteTime
```

For suspected app folders:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\AppName" -Force -Recurse | Select-Object FullName,Length,LastWriteTime
```

Filter secret-bearing config files instead of dumping them:

```powershell
Select-String -Path "$env:LOCALAPPDATA\AppName\.env" -Pattern '^SOME_SAFE_KEY='
```

## Process, Window, And Port Checks

Flet apps often have a hidden/no-window `app.exe` plus a visible `flet.exe`:

```powershell
Get-Process app,flet -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,MainWindowHandle,MainWindowTitle,Responding,StartTime
```

Map localhost helpers:

```powershell
Get-NetTCPConnection -LocalPort 18788 -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,State,OwningProcess
Get-Process -Id <PID> -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path,StartTime,Responding
curl.exe -s http://127.0.0.1:<PORT>/<expected/status/path>
```

## Persistence Pattern

Use a Startup-folder `.cmd` that calls a PowerShell launcher when scheduled tasks require elevated rights or fail with access denied. Keep `.cmd` paths ASCII-safe by relying on `%LOCALAPPDATA%` or by copying helper binaries into an AppData runtime folder.

PowerShell launcher pattern:

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

Startup `.cmd` pattern:

```cmd
@echo off
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%LOCALAPPDATA%\AppName\start-helper.ps1"
```

## Cold-Start Validation

Only do this when it will not disrupt important user work:

```powershell
$listener = Get-NetTCPConnection -LocalPort <PORT> -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($listener) { taskkill /PID $listener.OwningProcess /F | Out-Null }
Start-Sleep -Milliseconds 800
& "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\AppNameHelper.cmd"
Start-Sleep -Milliseconds 1200
Get-NetTCPConnection -LocalPort <PORT> -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,State,OwningProcess
```

Final verification should include helper port, helper process path, app config target, local state validity, visible UI window title, and responding state.
