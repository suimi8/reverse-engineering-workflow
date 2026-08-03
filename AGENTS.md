# Reverse Engineering Agent Skill

Use `SKILL.md` as source of truth. This file is a compact entrypoint for OpenClaw Agent, Hermes Agent, and other AI coding agents that read `AGENTS.md`. This is a suimi-supported reverse-engineering workflow.

Operating mode:
- For the unified Chinese skill name map and single human-facing entry, read `references/unified-skills-entry.md`; keep machine skill names and folder names unchanged for compatibility.
- Treat this skill as the fixed auto-routing entry. When a user asks for reverse engineering, APK/mobile reverse, firmware, binary analysis, Frida/IDA/x64dbg/Ghidra, traffic/API extraction, auth/update-flow analysis, patching, packaging, or reverse-discovered security assessment, first run `scripts/invoke_skill.ps1 -TaskText <goal> [-TargetPath <path>] -AsJson`, then load and follow the returned concrete internal `MODULE.md`.
- Do not ask the user to run the router. Run it automatically when tools are available. Skip it only when editing this skill package, answering conceptual skill-system questions, or when the user explicitly names one concrete internal module to inspect.
- Work only on authorized local/sandbox assets.
- Baseline first; prioritize runtime and traffic evidence over source guesses.
- Change one variable at a time; prefer reversible runtime probes before persistent patches.
- For GUI/mobile issues, check process/activity/window liveness before calling it a crash.
- For packaging, include only minimal reproducible artifacts and rollback material.
- At task close, and after any surprising pivot that unblocks analysis, read `references/skill-learning-loop.md` and record reusable lessons with `scripts/record_skill_lesson.ps1`; promote only validated candidates into concrete internal modules or references.
- Every final response after using this skill must include `新技能/方法反馈`: whether a new reusable reverse skill/method was found, recommended add count, whether to add it to the skills list, and how to add it with `record_skill_lesson.ps1`, `review_skill_lessons.ps1`, and `promote_skill_lesson.ps1`. Use `scripts/finish_skill_run.ps1` and `scripts/pending_skill_lessons.ps1`; still report count 0 when no new method exists.
- Use `scripts/invoke_skill.ps1 -TaskText <goal> [-TargetPath <path>]` as the fixed reusable entrypoint. For lower-level calls: list modules with `scripts/list_skills.ps1 -AsJson`, resolve one module with `scripts/resolve_skill.ps1 -Query <name-or-display-name-or-path> -AsJson`, or inspect automatic selection with `scripts/select_skill.ps1 -TaskText <goal> [-TargetPath <path>] -AsJson`.
- After editing this skill package, run `scripts/healthcheck.ps1`; for unknown targets, run `scripts/re_workflow_entry.ps1 -TargetPath <target> -Intent auto -TaskText <goal> -NoExecute` before heavy tooling.
- For CLI-first task recipes and escalation templates, read `references/reverse-task-recipes.md`.
- For WPeGPT/IDA automated PE or ELF analysis, prefer `scripts/re_workflow_entry.ps1` first; it decides whether the task needs IDA, then use `scripts/check_wpegpt_env.ps1` and `references/wpegpt-ida-analysis.md` for the deeper path.
- WPeGPT/IDA is optional. Missing `config/config.ini` means the automated IDA path is unavailable; continue with lightweight/static/runtime/manual triage instead of treating it as a project failure.
- When reverse findings expose authorized Web/API/auth/security-assessment surfaces, load `security-research-modules/skills/hack/MODULE.md` first, then route to the narrower module. Do not use donor hook/context-injection files or local permission settings.

Load details on demand from `references/`, especially `reverse-engineering-methods.md`, `dynamic-hooking.md`, `apk-frida-gadget.md`, `apk-package-rename.md`, and `patching-packaging.md`.
