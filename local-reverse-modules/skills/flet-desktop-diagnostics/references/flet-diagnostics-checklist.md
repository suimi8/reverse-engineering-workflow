# Flet Diagnostics Checklist

Use this checklist after `flet-desktop-diagnostics` is selected.

## Package Signals

```powershell
Get-ChildItem -Force
Get-ChildItem -Recurse -Include "app.exe","flet.exe","python*.dll","*.pyd","base_library.zip" | Select-Object FullName,Length,LastWriteTime
rg -a -n "flet|Flet|LOCALAPPDATA|APPDATA|127\.0\.0\.1|localhost|resources|assets|\.env|config|state" .
```

## Process And Window Checks

```powershell
Get-Process app,flet -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,MainWindowHandle,MainWindowTitle,Responding,StartTime
```

If the UI is missing but processes are alive, inspect visible HWNDs with an existing helper when available:

```powershell
python .\scripts\windows_window_dump.py --pid <PID>
```

## AppData Discovery

```powershell
Get-ChildItem "$env:LOCALAPPDATA" -Directory | Select-Object FullName,LastWriteTime
Get-ChildItem "$env:APPDATA" -Directory | Select-Object FullName,LastWriteTime
Get-ChildItem "$env:LOCALAPPDATA\AppName" -Force -Recurse | Select-Object FullName,Length,LastWriteTime
```

Filter config safely:

```powershell
Select-String -Path "$env:LOCALAPPDATA\AppName\.env" -Pattern '^SAFE_KEY='
```

## Local Dependencies

```powershell
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalAddress -in @('127.0.0.1','::1') } | Select-Object LocalAddress,LocalPort,OwningProcess
Get-Process -Id <PID> -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path,StartTime,Responding
curl.exe -s http://127.0.0.1:<PORT>/<health-or-status-path>
```

## Final Verification

- `flet.exe` or the actual UI process has a nonzero `MainWindowHandle`.
- `MainWindowTitle` matches the expected app.
- `Responding` is true for the UI process.
- Required AppData state/config was updated at launch time.
- Required localhost helper endpoints return expected status.
