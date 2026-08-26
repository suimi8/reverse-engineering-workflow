---
name: competition-windows-pivot
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for Kerberos, WinRM, SMB, RDP, Windows credential material, replayable tickets, delegation edges, and host-to-host pivot chains. Use when the user asks to replay Kerberos material, trace a WinRM, SMB, or RDP pivot, understand host-to-host privilege movement, or prove which Windows service accepted a credential or ticket. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi Windows跳板比赛

> 归一化提示（suimi 审计）：本模块聚焦 CTF 沙箱场景；通用/生产环境的完整方法论、payload 与检测清单见主模块 [windows-ad](../windows-ad/MODULE.md)，避免重复维护。


本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition Windows Pivot

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the challenge path is dominated by host-to-host movement, replayable ticket material, or Windows privilege edges.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Compress the pivot into a concrete chain: foothold -> recovered artifact -> replay path -> pivot host -> resulting capability.
2. Separate stored credential material from usable privilege.
3. Keep host evidence, ticket evidence, and privilege effect on one timeline.
4. Record the exact accepting service or host for every replayed artifact.
5. Reproduce the smallest pivot that still proves the privilege edge.

## Workflow

### 1. Recover The Replay Material

- Inspect SAM, SECURITY, SYSTEM, NTDS, DPAPI, LSA secrets, browser stores, PowerShell history, ETW, Sysmon, and event logs in the active path.
- Distinguish password, hash, ticket, cookie, vault blob, or gMSA material by where it can actually be used.

### 2. Trace The Pivot Chain

- Map the protocol actually used: WinRM, SMB, RDP, WMI, admin shares, remote registry, or service control.
- When Kerberos matters, record SPN, delegation, PAC or group data, encryption type, and the accepting service.
- When AD edges matter, inspect ACLs, GPO links, SIDHistory, delegation, certificate templates, and replication rights.

### 3. Report The Edge

- Keep the pivot path concrete and replayable.
- State what artifact crossed which boundary and what capability appeared on the destination host.

## Read This Reference

- Load `references/windows-pivot.md` for the pivot checklist, Kerberos evidence block, and common replay mistakes.
- If the task is specifically about DPAPI masterkeys, browser or vault stores, protected blobs, or proving where a recovered DPAPI secret is accepted, prefer `$competition-dpapi-credential-chain`.
- If the task is specifically about LSASS memory, ticket caches, replayable session material, or host-resident credential extraction, prefer `$competition-lsass-ticket-material`.
- If the task is specifically about delegation edges, SPN trust, S4U flow, or which service accepts the delegated ticket, prefer `$competition-kerberos-delegation`.
- If the hard part is forced authentication, coercion primitives, relay targets, or the service that accepts relayed auth, prefer `$competition-relay-coercion-chain`.

## What To Preserve

- Host names, logon IDs, SIDs, SPNs, ticket fields, service names, and event IDs
- Exact replay point and resulting logon session, token, or group change
- Raw host artifacts and derived timeline separately