---
name: windows-local-service-persistence
description: Repair and validate Windows localhost helper service startup for authorized local apps. Use for loopback-only Node/Python/helper services, Startup folder scripts, scheduled task fallback, port no-op guards, non-ASCII path failures in .cmd files, hidden Start-Process launchers, cold-start verification, and apps that need a local service on 127.0.0.1 to reach the functional UI.
---


中文名：suimi Windows 本地服务自启动
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# Windows Local Service Persistence

This internal module is supported by the suimi reverse workflow root. If this module is loaded directly, the final response must still include `新技能/方法反馈` generated from `reverse-engineering-workflow/scripts/finish_skill_run.ps1`; use `record_skill_lesson.ps1`, `review_skill_lessons.ps1`, and `promote_skill_lesson.ps1` when a reusable lesson is found.

## Scope

Use this module when an authorized local app depends on a helper process or localhost service that must run reliably at login or before app launch. Keep helpers bound to `127.0.0.1` unless the user explicitly requires a wider interface and the security impact is understood.

Do not expose private helper services on LAN interfaces. Do not print tokens, API keys, full environment files, or private service payloads unless strictly required and redacted.

## Workflow

1. Baseline the helper.
   - Identify expected port, host, process, binary path, working directory, and health endpoint.
   - Confirm whether failure is missing process, bad path, duplicate process, endpoint mismatch, or service crash.

2. Choose persistence deliberately.
   - Prefer scheduled tasks when permissions allow and reliability matters.
   - Use Startup folder `.cmd` plus PowerShell launcher when scheduled tasks are unavailable or denied.

3. Avoid path and encoding traps.
   - Keep `.cmd` files ASCII-safe by using `%LOCALAPPDATA%`, short paths, or a PowerShell launcher.
   - Copy small helper runtimes to an AppData runtime folder only when needed to avoid fragile non-ASCII install paths.

4. Add duplicate guards.
   - Check the expected port or process before launching so repeated login/startup events exit cleanly.
   - Prefer hidden `Start-Process` launchers for background helpers.

5. Validate cold start.
   - Stop only the helper process, run the persistence entry, verify the port returns, confirm the process path, and call the health endpoint.

## Persistence Inventory and Standard Locations

Before adding or changing any autostart, do a read-only inventory of every place Windows can launch something at login/boot, so you neither duplicate an existing entry nor miss the one already failing. The full command patterns are in `references/service-persistence-checklist.md`; the standard locations and what to check are below.

> Tip: Sysinternals `autorunsc -a lst -accepteula` enumerates services, logon/Run entries, and scheduled tasks in one pass; use it to cross-check the per-location reads below rather than trusting a single hive.

1. Windows Services (machine-level, changing them needs admin).
   - Enumerate with `sc query type= service state= all` or PowerShell `Get-Service`; inspect one with `sc qc <name>` (or `Get-CimInstance Win32_Service`) to read its `BINARY_PATH_NAME`, `START_TYPE`, and logon account.
   - Confirm whether the helper is a real service or just a per-user background process; a loopback helper for a desktop app usually should NOT be a system service.

2. Per-user and per-machine Run keys (registry).
   - Standard locations: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` and `...\RunOnce`; machine-wide `HKLM\...\Run` and `...\RunOnce`; on 64-bit Windows also the WOW6432Node mirror `HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run`.
   - Read with `reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"` (repeat per hive). Validate that each value's target path still exists and is the expected binary.

3. Startup folders.
   - Per-user: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`; all-users: `%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Startup`.
   - List the contents and open any `.lnk`/`.cmd` to confirm its target, arguments, and working directory.

4. Task Scheduler.
   - Enumerate with `schtasks /Query /FO LIST /V` (or PowerShell `Get-ScheduledTask`); inspect the trigger (At log on / At startup), the action's program + arguments, the "run whether user is logged on or not" setting, and the highest-privileges flag.
   - Prefer a per-user logon-triggered task when it works; fall back to the Startup folder + PowerShell launcher when task registration is denied.

5. Cross-check and de-duplicate.
   - After inventory, confirm exactly one mechanism owns the helper. Multiple autostarts racing on the same port produce duplicate processes and intermittent failures; the port/process no-op guard in the launcher is what keeps a stray duplicate harmless.
   - Existing autostart entries found for this app: （待 suimi 补充实测：本应用实际已存在的自启动项位置与内容）。

### Validation targets

- Exactly one autostart mechanism owns the helper.
- Its target path exists and points to the expected binary/launcher.
- The launcher's port/process guard makes a second trigger a clean no-op.
- Cold start reproduces a healthy listener on the expected loopback port.

## Evidence and Rollback（证据与回滚）

Every autostart change must be reversible and recorded.

1. Before changing anything, export or copy the current state: `reg export` the relevant Run key, copy existing Startup `.lnk`/`.cmd` files, and `schtasks /Query /XML` (or `Export-ScheduledTask`) any task you will touch. Record baseline port/process state.
2. Make one change at a time (one Run value, one Startup file, or one task), then re-capture port/process state and run the cold-start check so each before/after delta maps to that change.
3. Keep a change log: mechanism touched, exact command, backup/export path, before value, after value, observed effect.
4. Roll back by re-importing the exported registry key, restoring or deleting the Startup file, and re-registering or deleting the task from the saved definition; then re-run the baseline capture to confirm the prior state.
5. Never leave two mechanisms enabled for the same helper after testing; disable the losing one and record that you did.
   - Concrete backup/rollback commands for this app: （待 suimi 补充实测：本应用实际的自启动导出与还原命令）。

## References

Read `references/service-persistence-checklist.md` for safe command patterns covering port checks, Startup scripts, PowerShell launchers, scheduled task fallback, and cold-start validation.

## Reporting

Report the persistence method, launcher path, helper process path, port status, health endpoint result, and cold-start verification. Keep secrets out of the final answer.
