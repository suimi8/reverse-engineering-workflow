---
name: competition-oauth-oidc-chain
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for OAuth, OIDC, redirect flows, state or nonce handling, PKCE, token exchange, refresh logic, claim mapping, and accepted login paths. Use when the user asks to trace redirects, callback parameters, scopes, state, nonce, PKCE, refresh tokens, consent, or explain how an OAuth or OIDC chain turns into accepted identity or privilege. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi OAuth/OIDC链比赛

> 归一化提示（suimi 审计）：本模块聚焦 CTF 沙箱场景；通用/生产环境的完整方法论、payload 与检测清单见主模块 [oauth-oidc-misconfiguration](../oauth-oidc-misconfiguration/MODULE.md)，避免重复维护。


本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition OAuth OIDC Chain

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the hard part is proving how an OAuth or OIDC flow is shaped, exchanged, and ultimately accepted.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Map the auth chain in order: entry route, redirect, authorize request, callback, token exchange, refresh, and final accepting service.
2. Record scopes, state, nonce, PKCE material, redirect URIs, and claim-bearing tokens before mutating anything.
3. Separate token possession from actual identity acceptance.
4. Keep browser-visible redirects and backend-visible token exchange in one compact chain.
5. Reproduce the smallest redirect-to-acceptance flow that proves the decisive identity edge.

## Workflow

### 1. Map The Redirect And Token Path

- Record issuer, client ID, redirect URI, authorize parameters, callback parameters, token endpoint, and refresh path.
- Note which values are user-controlled, derived, cached, or validated: `state`, `nonce`, PKCE verifier, audience, scope, or prompt.
- Keep browser redirects, server-side exchanges, and resulting session state tied together.

### 2. Prove Token-To-Identity Acceptance

- Show how code, ID token, access token, or refresh token turns into app session, claims mapping, tenant selection, or accepted privilege.
- Record token claims, expiration, audience, subject, scopes, and the exact accepting app or backend edge.
- Distinguish UI login success from backend authorization success.

### 3. Reduce To The Decisive OAuth Chain

- Compress the result to the smallest sequence: entry request -> redirect -> callback -> token or claim acceptance -> resulting capability.
- Keep one canonical good flow and one minimal mutated flow if a parameter change matters.
- If the task broadens into generic web routing or storage behavior outside the auth chain, switch back to the broader web-runtime skill.

## Read This Reference

- Load `references/oauth-oidc-chain.md` for the redirect checklist, token checklist, and evidence packaging.
- If the hard part is JWT header parsing, claim normalization, key lookup, or token validation confusion after issuance, prefer `$competition-jwt-claim-confusion`.

## What To Preserve

- Redirect URIs, parameters, codes, token claims, scopes, and the accepting service or callback
- The exact point where claims or tokens become accepted app identity
- One minimal replayable redirect-to-acceptance sequence