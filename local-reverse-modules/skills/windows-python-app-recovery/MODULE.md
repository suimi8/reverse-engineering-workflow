---
name: windows-python-app-recovery
description: Recover and diagnose authorized lost-source Windows desktop apps packaged from Python. Use for Nuitka, PyInstaller, cx_Freeze, Flet, embedded Python DLL bundles, app.exe/flet.exe pairs, LOCALAPPDATA/APPDATA state repair, localhost helper service recovery, startup persistence, and cases where the user cannot enter the functional UI of their own Windows Python app.
---


中文名：suimi Windows Python 程序恢复
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# Windows Python App Recovery

This internal module is supported by the suimi reverse workflow root. If this module is loaded directly, the final response must still include `新技能/方法反馈` generated from `reverse-engineering-workflow/scripts/finish_skill_run.ps1`; use `record_skill_lesson.ps1`, `review_skill_lessons.ps1`, and `promote_skill_lesson.ps1` when a reusable lesson is found.

## Scope

Use this module only for local software the user owns, developed, or is explicitly authorized to maintain. Keep the work framed as recovery, diagnostics, and continuity: restore access to a lost-source app, repair broken local config/state, rebuild a missing loopback helper, or make startup reliable.

Do not use this module for unauthorized third-party license bypass, cracking, credential theft, or exposing secrets. When ownership is unclear, ask for clarification before changing state.

## When To Use

- The target is a Windows directory or `.exe` bundle with `python*.dll`, `.pyd`, `base_library.zip`, Nuitka/PyInstaller markers, or embedded Python runtime files.
- The UI stack looks like Flet, PyQt, Tk, Qt, wxPython, or another Python desktop framework.
- The user lost source code and needs the packaged app to run again or enter its functional UI.
- The blocker appears to be `%LOCALAPPDATA%`, `%APPDATA%`, `.env`, JSON/SQLite state, machine ID, cached auth state, or a local helper process.
- A localhost-only helper service, node runtime, or startup script is needed to restore the expected runtime path.

## Workflow

1. Classify the package before heavy reverse engineering.
   - Look for `app.exe`, `flet.exe`, `python*.dll`, `*.pyd`, `_internal`, `base_library.zip`, `runtime/node.exe`, `resources/`, Nuitka strings, and PyInstaller bootloader markers.
   - For Flet-style apps, treat `app.exe` and `flet.exe` as a process pair; the visible window may belong to `flet.exe`.

2. Locate mutable state and preserve it.
   - Search `%LOCALAPPDATA%`, `%APPDATA%`, `%PROGRAMDATA%`, and the user profile for app-named folders.
   - Prioritize `.env`, JSON state, SQLite databases, machine IDs, logs, recently modified files, cached tokens, and endpoint settings.
   - Back up any file before modifying it. Do not dump full `.env` or token-bearing files; read only needed keys or redact values.

3. Map the gate that blocks the UI.
   - Distinguish config mismatch, corrupted local state, missing helper process, stale endpoint, failed status check, hidden/modal UI, event-loop freeze, and genuine binary patch needs.
   - Use runtime evidence first: process liveness, window title, logs, local ports, HTTP responses, state file writes, and timestamps.
   - If local state is signed, derive and verify the state format only from the user's artifacts; avoid hardcoding case-specific secrets in the skill.

4. Restore the minimum runtime path.
   - Prefer config/state repair or loopback helper restoration before static binary patching.
   - Keep local helpers bound to `127.0.0.1` only, reproduce the exact response schema the app expects, and avoid LAN exposure.
   - Keep edits reversible and scoped to the app's AppData/runtime files.

5. Make startup reliable when needed.
   - Use scheduled tasks when privileges allow; otherwise use the Startup folder with a `.cmd` that calls a PowerShell launcher.
   - Avoid non-ASCII `.cmd` path fragility by putting helper binaries or launchers under an ASCII-safe AppData path.
   - Add a no-op guard: if the expected port or process is already present, exit cleanly.

6. Validate cold start and UI access.
   - Confirm the helper endpoint, port listener, process path, app state validity, and visible window response.
   - When safe, stop only the helper process, invoke the persistence entry, and verify the helper returns from the expected path.
   - Close with a concrete status report and no secrets.

## Reference Checklist

Read `references/windows-recovery-checklist.md` for PowerShell command patterns covering package triage, AppData discovery, Flet process checks, loopback helper validation, Startup-folder persistence, and cold-start verification.

## Handoff Notes

Report: target type, mutable state path, config endpoint, helper process/path, port status, UI process/window, validation command results, and rollback files. Never include API keys, private tokens, raw secrets, or full environment files in final output.
