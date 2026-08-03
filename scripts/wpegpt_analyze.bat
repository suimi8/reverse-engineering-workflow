@echo off
REM WPeGPT Binary Analyzer fallback launcher.
REM Prefer scripts\wpegpt_analyze.ps1 in agent workflows.

setlocal
set SCRIPT_DIR=%~dp0

if "%~1"=="" (
    echo Usage: %~nx0 ^<binary_path^> [light^|full^|vuln]
    echo Example: %~nx0 .\samples\target.exe light
    exit /b 1
)

set MODE=%~2
if "%MODE%"=="" set MODE=light

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%wpegpt_analyze.ps1" -BinaryPath "%~1" -Mode "%MODE%"
exit /b %ERRORLEVEL%
