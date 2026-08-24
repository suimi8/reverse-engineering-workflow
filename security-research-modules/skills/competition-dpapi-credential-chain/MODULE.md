---
name: competition-dpapi-credential-chain
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for DPAPI masterkeys, vault blobs, browser credential stores, protected secrets, domain backup keys, and secret-to-acceptance replay chains. Use when the user asks to inspect DPAPI blobs or masterkeys, recover browser or vault credentials, trace DPAPI context or backup-key use, or explain how protected Windows secrets become accepted access or privilege. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi DPAPI凭据链比赛

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition Dpapi Credential Chain

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the decisive Windows secret is DPAPI-protected and the hard part is proving which context unwraps it and where the plaintext is accepted.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Separate protected blob, masterkey, decrypting context, and final accepting service.
2. Record SID, user or machine context, masterkey path, vault or browser store, and target replay point before broad conclusions.
3. Keep DPAPI source artifact, unwrap step, plaintext secret, and acceptance edge in one chain.
4. Distinguish local user DPAPI, machine DPAPI, domain backup key use, and application-specific wrapping.
5. Reproduce the smallest DPAPI-to-accepted-access path that proves the decisive edge.

## Workflow

### 1. Map Protected Secret And DPAPI Context

- Record blob source, masterkey location, SID, protector scope, profile path, credential store, and any application wrapper such as browser encryption or vault metadata.
- Note whether the decisive value lives in Credential Manager, Vault, browser cookies, browser passwords, Wi-Fi profiles, RDP files, or custom app storage.
- Keep protected artifact, masterkey candidate, and account or machine context tied together.

### 2. Prove Unwrap And Acceptance

- Show how the secret is decrypted: user logon material, machine context, domain backup key, or another recovered protector.
- Record plaintext type, target host or service, replay method, and resulting session, token, or data access.
- Distinguish successful blob decryption from actual accepted access.

### 3. Reduce To The Decisive DPAPI Chain

- Compress the result to the smallest sequence: protected artifact -> masterkey or unwrap context -> plaintext secret -> accepted replay or access -> resulting capability.
- State clearly whether the decisive edge lives in masterkey recovery, DPAPI scope confusion, application wrapper handling, or the service that accepts the recovered secret.
- If the task broadens into generic LSASS ticket material or full Windows pivoting, hand back to the tighter host or pivot skill.

## Read This Reference

- Load `references/dpapi-credential-chain.md` for the blob checklist, masterkey checklist, and evidence packaging.

## What To Preserve

- Blob paths, masterkey paths, SIDs, protector scope, store names, and application wrapper details
- The exact accepting service or dataset unlocked by the recovered plaintext
- One minimal protected-artifact-to-accepted-access sequence that proves the edge