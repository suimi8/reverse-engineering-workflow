---
name: flet-desktop-diagnostics
description: Diagnose authorized packaged Flet desktop apps on Windows, especially Python app.exe plus flet.exe process pairs, hidden or blank windows, failure to reach the functional UI, AppData resource/config discovery, local webview/runtime issues, localhost API dependencies, and lost-source packaged Python/Flet applications.
---


中文名：suimi Flet 桌面诊断
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# Flet Desktop Diagnostics

This internal module is supported by the suimi reverse workflow root. If this module is loaded directly, the final response must still include `新技能/方法反馈` generated from `reverse-engineering-workflow/scripts/finish_skill_run.ps1`; use `record_skill_lesson.ps1`, `review_skill_lessons.ps1`, and `promote_skill_lesson.ps1` when a reusable lesson is found.

## Scope

Use this module for authorized Windows desktop apps built with Flet or likely Flet packaging. Treat `app.exe` and `flet.exe` as a paired runtime: `app.exe` may be the Python host while the visible main window belongs to `flet.exe`.

Do not assume a blank/missing `app.exe` main window is a crash. Verify process liveness, window handles, localhost dependencies, AppData state, logs, and modal dialogs first.

## Workflow

1. Identify Flet packaging signals.
   - Look for `flet.exe`, `app.exe`, `resources/`, `python*.dll`, `*.pyd`, Nuitka/PyInstaller markers, and local web runtime files.
   - Check whether the package writes user state under `%LOCALAPPDATA%` or `%APPDATA%`.

2. Map the live process tree.
   - Check both `app.exe` and `flet.exe` for PID, window handle, title, responding state, and start time.
   - Use HWND/window dumps when the visible UI does not match the expected process.

3. Trace the UI gate.
   - Determine whether the UI is blocked by a modal dialog, missing config, failed local endpoint, stale state, event loop freeze, or crashed helper process.
   - Use state timestamps and localhost traffic to confirm what changed during launch.

4. Repair the minimum path.
   - Prefer config/state repair, helper restart, or endpoint correction before static patching.
   - Keep edits reversible and scoped to user-writable app data when possible.

5. Validate user-visible behavior.
   - Confirm the real window title, responding state, relevant local ports, state validity, and a repeatable launch path.

## References

Read `references/flet-diagnostics-checklist.md` for command patterns covering package triage, process/window checks, AppData discovery, localhost dependencies, and final verification.

## Reporting

Report the concrete process/window state, config/state path, local dependency status, and final UI result. Do not include secrets, full `.env` files, tokens, or raw private config values.
