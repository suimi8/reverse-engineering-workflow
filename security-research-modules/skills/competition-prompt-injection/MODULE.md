---
name: competition-prompt-injection
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for prompt-injection, retrieval poisoning, memory contamination, planner drift, MCP or tool-boundary abuse, and agent exfiltration challenges. Use when the user asks to analyze prompt injection, retrieval poisoning, memory contamination, planner drift, tool-argument corruption, or secret exposure caused by an agent chain. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi Prompt注入比赛

> 归一化提示（suimi 审计）：本模块聚焦 CTF 沙箱场景；通用/生产环境的完整方法论、payload 与检测清单见主模块 [llm-security](../llm-security/MODULE.md)，避免重复维护。


本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition Prompt Injection

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the challenge is primarily about trust boundaries inside an agentic system.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Identify the first untrusted content that becomes model-visible.
2. Map the chain from retrieval, memory, or transcript into planner or executor behavior.
3. Record the exact point where text becomes a tool argument, file path, network target, or secret request.
4. Prove one minimal exploit chain before exploring variants.
5. Keep prompt snippets and tool transitions in compact evidence blocks.

## Workflow

### 1. Map The Control Stack

- Track system, developer, user, retrieved, memory, planner, and tool-response layers separately.
- Distinguish claimed capability from runtime-exposed capability.
- Note what the model can actually call, read, or mutate.

### 2. Prove The Boundary Crossing

- Reproduce one chain from untrusted text to changed planner behavior, changed tool args, or secret exposure.
- Keep the decisive transcript compact: source chunk, rewritten planner state, final tool invocation.
- Prefer the smallest transcript that still demonstrates the bug.

### 3. Report By Boundary

- State which layer failed: retrieval, summarizer, planner, executor, tool normalization, or output post-processing.
- Separate instruction drift from actual side effect.

## Read This Reference

- Load `references/prompt-injection.md` for the checklist, evidence layout, and common prompt-boundary pitfalls.

## What To Preserve

- Original malicious chunk or prompt
- Intermediate summary or planner drift if it matters
- Final tool args, file paths, or exposed secret surface