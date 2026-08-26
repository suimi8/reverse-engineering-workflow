# Reverse Engineering Workflow

Claude Code entrypoint. Follow `SKILL.md`; use `AGENTS.md` only as a short index. This is a suimi-supported reverse-engineering workflow.

For the unified Chinese skill name map and single human-facing entry, read `references/unified-skills-entry.md`; keep machine skill names and folder names unchanged for compatibility.

Treat this skill as the fixed auto-routing entry. When a user asks for reverse engineering, APK/mobile reverse, firmware, binary analysis, Frida/IDA/x64dbg/Ghidra, traffic/API extraction, auth/update-flow analysis, patching, packaging, authorized penetration-testing toolchain (nmap, nuclei, sqlmap, ffuf, hashcat, ZAP/Burp), src/bug-bounty hunting, or reverse-discovered security assessment, first run `scripts/invoke_skill.ps1 -TaskText <goal> [-TargetPath <path>] -AsJson`, then load and follow the returned concrete internal `MODULE.md`. Do not ask the user to run the router. Skip it only when editing this skill package, answering conceptual skill-system questions, or when the user explicitly names one concrete internal module to inspect.

Default workflow: baseline run -> static/runtime map -> widgets/modules/traffic -> instrument one narrow path -> patch only after proof -> verify end to end -> package minimal reversible artifacts.

At task close, and after any surprising pivot that unblocks analysis, load `references/skill-learning-loop.md` and record reusable lessons with `scripts/record_skill_lesson.ps1` before promoting them into a concrete internal module or reference.

Every final response after using this skill must include a `新技能/方法反馈` section. Report whether this run found a new reusable reverse skill/method, the recommended add count, whether it should be added to the skills list, and how to add it with `record_skill_lesson.ps1`, `review_skill_lessons.ps1`, and `promote_skill_lesson.ps1`. Use `scripts/finish_skill_run.ps1` and `scripts/pending_skill_lessons.ps1` to keep the result consistent; still report count 0 when no new method exists.

After editing this skill package, run `scripts/healthcheck.ps1`. Use `scripts/invoke_skill.ps1 -TaskText <goal> [-TargetPath <path>]` as the fixed reusable entrypoint. For lower-level calls: list modules with `scripts/list_skills.ps1 -AsJson`, resolve one module with `scripts/resolve_skill.ps1 -Query <name-or-display-name-or-path> -AsJson`, or inspect automatic selection with `scripts/select_skill.ps1 -TaskText <goal> [-TargetPath <path>] -AsJson`. For unknown targets, run `scripts/re_workflow_entry.ps1 -TargetPath <target> -Intent auto -TaskText <goal> -NoExecute` before heavy tooling. For CLI-first recipes and escalation templates, load `references/reverse-task-recipes.md`.

For APK package rename, smali/resource/provider/native residue checks, or fixed-offset `.so` patches, load `references/apk-package-rename.md`.

For WPeGPT/IDA automated PE or ELF analysis, prefer `scripts/re_workflow_entry.ps1` as the first executable entry. If it routes to IDA, load `references/wpegpt-ida-analysis.md` and use `scripts/check_wpegpt_env.ps1` plus `scripts/wpegpt_analyze.ps1`.

WPeGPT/IDA is optional. If `config/config.ini` is absent or `check_wpegpt_env.ps1` is not ready, continue with lightweight or manual triage instead of blocking the task.

When reverse findings expose authorized Web/API/auth/security-assessment surfaces, load `security-research-modules/skills/hack/MODULE.md` first, then route to the narrower module. Do not use donor hook/context-injection files or local permission settings.
