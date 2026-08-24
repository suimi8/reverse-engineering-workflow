---
name: competition-mailbox-abuse
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for enterprise mail abuse, OAuth consent, inbox or forwarding rules, transport rules, shared mailbox access, phishing chains, and token-to-mailbox side effects. Use when the user asks to trace mailbox rules, OAuth consent grants, forwarding or delegate abuse, shared mailbox access, message-trace evidence, or explain how mail artifacts turn into persistence, exfiltration, or privilege. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi 邮箱滥用比赛

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition Mailbox Abuse

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the decisive path runs through mailbox behavior, consent flow, or message-routing effects rather than generic AD evidence alone.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Decide whether the active path is phishing-to-consent, token-to-mailbox, rule-based persistence, or transport-level mail rerouting.
2. Keep mailbox evidence, identity evidence, and message-trace evidence tied to the same user, mailbox, token, or message ID.
3. Separate possession of a token or delegate edge from the actual mailbox effect it enables.
4. Record forwarding targets, rule predicates, consent scopes, shared mailbox edges, and resulting mail flow in compact blocks.
5. Reproduce the smallest mail effect that proves persistence, exfiltration, or privilege.

## Workflow

### 1. Map The Mail Trust Path

- Identify the principal, mailbox, token or session, consent grant, delegate edge, shared mailbox relationship, or app registration involved.
- Record consent scopes, mailbox permissions, rule ownership, transport actions, and message-trace identifiers.
- Distinguish client-visible symptoms from server-side mailbox or transport state.

### 2. Prove The Mailbox Effect

- Correlate consent logs, sign-ins, message traces, inbox rules, transport rules, forwarding settings, and mailbox audit events.
- Show which rule or token produces which concrete effect: silent forwarding, marking read, deletion, delegate access, or message rerouting.
- Keep message IDs, sender or recipient pairs, and timestamps aligned across logs.

### 3. Reduce To The Decisive Abuse Chain

- Compress the path to the smallest sequence: lure or grant -> token or delegate edge -> mailbox or transport mutation -> resulting mail effect.
- State clearly whether persistence lives in consent, mailbox rules, transport config, or shared mailbox permissions.
- If the task broadens into host pivots or Kerberos acceptance, switch back to the broader identity skill.

## Read This Reference

- Load `references/mailbox-abuse.md` for the consent checklist, rule checklist, and evidence packaging.

## What To Preserve

- Consent scopes, token claims, mailbox permissions, rule definitions, forwarding targets, and message IDs
- Message-trace lines, audit events, and mailbox effects tied to the same mail path
- The smallest replayable sequence that proves persistence, exfiltration, or delegate access