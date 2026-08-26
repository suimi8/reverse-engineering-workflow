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

## General Diagnostic Method

Flet ships a Python application on top of a Flutter-based `flet` desktop view, so a "won't open" report almost always traces to one of three layers: the Python host process, the Flutter UI window, or a localhost dependency wired between them. Enumerate all three before calling it a crash. The commands for each step live in `references/flet-diagnostics-checklist.md`; the steps below are the reasoning skeleton.

1. Enumerate processes and window state.
   - Record PID, `MainWindowHandle`, `MainWindowTitle`, `Responding`, and `StartTime` for `app.exe`, `flet.exe`, and any embedded `python*.exe`.
   - A zero `MainWindowHandle` on the Python host is normal: the visible top-level window is usually owned by `flet.exe` (the Flutter view). Confirm which PID owns the real HWND before treating a blank host window as a failure.
   - If a process is alive but no window shows, enumerate top-level and child HWNDs (Win32 `EnumWindows`/`EnumChildWindows`, or the module window-dump helper) to separate "hidden/off-screen window" from "no window created".

2. Locate logs and diagnostic output.
   - Flet/Flutter desktop apps commonly log under `%LOCALAPPDATA%`, `%APPDATA%`, `%TEMP%`, the install folder, or a stdout/stderr stream that is swallowed when the app is launched windowless. Sort by `LastWriteTime` and read the newest `*.log`/`*.txt`/crash files.
   - Native Flutter-engine faults may surface as WER crash dumps under `%LOCALAPPDATA%\CrashDumps` or in the Windows Application event log; check both when the Python side shows no traceback.
   - To recover swallowed Python output, relaunch the host from a console so stdout/stderr are visible, or set the app's verbose/debug flag if one exists.
   - Actual log directory and filenames for this app: （待 suimi 补充实测：本应用实际日志目录与文件名）。

3. Triage the Python-side stack.
   - Read any traceback bottom-up: the last frame is the raising site; frames above trace the Flet path (page build, control event handler, or async task).
   - Common Flet failure classes: an aborted `ft.app(...)` target, an unhandled exception inside a control event handler that silently stalls the UI thread, a blocked or crashed `asyncio` task, a missing `assets/`/`resources/` path, or a failed call to the app's own localhost backend.
   - Separate a startup import/runtime error (window never appears) from a post-render logic error (window appears, then freezes or shows an error/modal state).
   - Observed failing frame/module for this app: （待 suimi 补充实测：本应用实际报错栈顶帧与触发路径）。

4. Verify the localhost dependency, if any.
   - Many Flet apps talk to their own `127.0.0.1` backend/helper; a UI that renders but stays empty or spins forever often means that endpoint never came up. List loopback listeners, match the owning PID to the expected helper, then probe the health/status path.
   - Distinguish "helper not started", "helper on the wrong port", and "helper up but returning an error body". Only the first two are startup-order problems; the third is a backend logic/state issue.
   - Expected loopback host/port and health path for this app: （待 suimi 补充实测：本应用实际本地端口与健康检查路径）。

### Common failure signatures

- Process pair alive but no HWND anywhere -> UI never constructed (startup import/config error); read logs and stdout.
- `flet.exe` HWND present but off-screen or minimized -> window-placement/multi-monitor issue, not a crash.
- UI renders, then freezes -> blocked UI thread or crashed async task; capture the Python stack.
- UI stays empty or shows a spinner forever -> unmet localhost dependency or a failed initial data load.

## Evidence and Rollback（证据与回滚）

Keep every change reversible and record enough to undo it.

1. Snapshot before changing anything: copy the target config/state file to a timestamped backup, and record process/window/port state plus each file's `LastWriteTime` and hash. Write down the exact command run and its output.
2. Change one thing at a time. After each change, re-capture the same evidence (process/window state, port listener, log tail, window title/`Responding`) so the before/after delta is attributable to that single change.
3. Maintain a change log: command run, file touched, backup path, before value, after value, observed effect.
4. Roll back by restoring the timestamped backups, stopping any helper process you started, then re-running the baseline capture to confirm the pre-change state returned.
5. Escalate to static binary patching only after config/state/helper repair is proven insufficient, and always save the original bytes first so the `.exe` can be byte-restored.
   - Concrete backup targets and rollback commands for this app: （待 suimi 补充实测：本应用实际需备份的配置/状态文件路径与回滚命令）。

## References

Read `references/flet-diagnostics-checklist.md` for command patterns covering package triage, process/window checks, AppData discovery, localhost dependencies, and final verification.

## Reporting

Report the concrete process/window state, config/state path, local dependency status, and final UI result. Do not include secrets, full `.env` files, tokens, or raw private config values.
