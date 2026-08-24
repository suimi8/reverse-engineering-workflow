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

## References

Read `references/service-persistence-checklist.md` for safe command patterns covering port checks, Startup scripts, PowerShell launchers, scheduled task fallback, and cold-start validation.

## Reporting

Report the persistence method, launcher path, helper process path, port status, health endpoint result, and cold-start verification. Keep secrets out of the final answer.
