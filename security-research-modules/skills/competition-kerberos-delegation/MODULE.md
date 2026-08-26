---
name: competition-kerberos-delegation
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for Kerberos delegation, SPN trust edges, S4U abuse, RBCD, constrained or unconstrained delegation, and service-ticket acceptance. Use when the user asks about constrained delegation, unconstrained delegation, RBCD, S4U, SPNs, ticket acceptance, or how a Kerberos trust edge turns into effective privilege under sandbox assumptions. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi Kerberos委派比赛

> 归一化提示（suimi 审计）：本模块聚焦 CTF 沙箱场景；通用/生产环境的完整方法论、payload 与检测清单见主模块 [windows-ad](../windows-ad/MODULE.md)，避免重复维护。


本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition Kerberos Delegation

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the hard part is not "is there Kerberos here," but which delegation edge exists, which ticket is being minted, and which service really accepts it.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Write the trust chain first: principal -> delegation edge -> ticket type -> target SPN -> accepting service -> resulting privilege.
2. Separate ticket possession from accepted privilege.
3. Keep SPNs, delegation mode, PAC/group data, encryption type, and service acceptance in one compact evidence block.
4. Reproduce one minimal delegation chain before broadening into variants.
5. Tie every privilege claim to a specific accepted ticket or service-side effect.

## Workflow

### 1. Identify The Delegation Edge

- Determine whether the path is constrained delegation, unconstrained delegation, resource-based constrained delegation, protocol transition, or another trust edge.
- Inspect SPNs, ACLs, service accounts, SIDHistory, certificate templates, and replication rights only when they affect the active path.

### 2. Trace Ticket Minting And Acceptance

- Record TGT/TGS type, S4U steps when relevant, delegation flags, PAC or group data, encryption type, cache location, and target SPN.
- Prove which service actually accepts the ticket and what capability appears after acceptance.

### 3. Report The Effective Edge

- Compress the chain into one replayable path, not a vague "domain compromise" statement.
- Separate candidate edges from the edge that really lands privilege.

## Read This Reference

- Load `references/kerberos-delegation.md` for the delegation checklist, ticket fields to preserve, and common proof mistakes.

## What To Preserve

- SPN, ticket type, delegation mode, PAC/group data, encryption type, cache location, accepting service
- Service-side logs, event IDs, logon session changes, or group changes proving effective privilege
- The exact trust edge that makes the ticket replayable