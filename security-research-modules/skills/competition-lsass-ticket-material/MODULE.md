---
name: competition-lsass-ticket-material
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for LSASS-resident secrets, Windows logon sessions, Kerberos ticket caches, DPAPI-backed material, SSP artifacts, and replayable credential extraction. Use when the user asks to inspect LSASS memory, recover tickets or logon sessions, trace DPAPI or SSP material, distinguish which credential artifacts are replayable, or connect host-resident credential material to an accepted pivot or privilege edge. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi LSASS票据材料比赛

> 归一化提示（suimi 审计）：本模块聚焦 CTF 沙箱场景；通用/生产环境的完整方法论、payload 与检测清单见主模块 [windows-ad](../windows-ad/MODULE.md)，避免重复维护。


本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition LSASS Ticket Material

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the decisive host artifact lives in LSASS, ticket caches, or adjacent credential material and the hard part is proving what is replayable.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Separate raw credential material from actually usable replay edges.
2. Record logon session, LUID, ticket cache, package, account, and target service before broad conclusions.
3. Keep host artifact, extracted secret, replay attempt, and resulting acceptance in one chain.
4. Distinguish password, hash, ticket, DPAPI secret, SSP residue, and token by where each can actually be used.
5. Reproduce the smallest host-artifact-to-accepted-privilege path that proves the decisive edge.

## Workflow

### 1. Map LSASS And Adjacent Credential State

- Record logon sessions, LUIDs, ticket caches, package names, SSPs, DPAPI context, and any service-account material tied to the active path.
- Note whether the decisive value is a TGT, service ticket, delegated ticket, DPAPI secret, plaintext, hash, or package-specific secret.
- Keep host source, account context, and cache location tied together.

### 2. Prove Replay Or Acceptance

- Show where the extracted material is accepted: SMB, WinRM, service ticket use, DPAPI unwrap, Schannel, or another host or service edge.
- Record SPN, target host, logon session, ticket flags, encryption type, and resulting privilege or token change.
- Distinguish material that is present from material that is actually replayable in this path.

### 3. Reduce To The Decisive Credential Chain

- Compress the result to the smallest sequence: host artifact -> extracted material -> accepted replay or unwrap -> resulting capability.
- State clearly whether the decisive edge lives in LSASS memory, ticket cache reuse, DPAPI context, or accepting service behavior.
- If the task broadens into full host-to-host pivoting, hand back to the tighter Windows pivot skill.

## Read This Reference

- Load `references/lsass-ticket-material.md` for the session checklist, replay checklist, and evidence packaging.
- If the task is specifically about DPAPI masterkeys, protected blobs, browser or vault stores, or proving which recovered DPAPI secret is accepted, prefer `$competition-dpapi-credential-chain`.

## What To Preserve

- LUIDs, session IDs, ticket types, SPNs, encryption types, package names, and cache or memory source
- The exact accepting host or service and the resulting privilege or logon effect
- One minimal host-artifact-to-replay sequence that proves the edge