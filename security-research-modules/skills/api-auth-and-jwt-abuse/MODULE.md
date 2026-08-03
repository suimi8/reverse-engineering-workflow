---
name: api-auth-and-jwt-abuse
description: >-
  API authentication and JWT abuse playbook. Use when testing bearer tokens, API keys, claim trust, header spoofing, rate limits, and API auth boundary weaknesses.
---


中文名：suimi API 认证与 JWT 滥用

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# SKILL: API Auth and JWT Abuse — Token Trust, Header Tricks, and Rate Limits

> **AI LOAD INSTRUCTION**: Use this skill when APIs rely on JWT, bearer tokens, API keys, or weak request identity signals. Focus on token trust boundaries, claim misuse, header spoofing, and rate-limit bypass.

## 1. TOKEN TRIAGE

Inspect:

- `alg`, `kid`, `jku`, `x5u`
- role, org, tenant, scope, or privilege claims
- issuer and audience mismatches
- reuse of mobile and web tokens across products

## 2. QUICK ATTACK PICKS

| Pattern | First Test |
|---|---|
| `alg:none` acceptance | unsigned token with trailing dot |
| RS256 confusion | switch to HS256 using public key as secret |
| `kid` lookup trust | path traversal or injection in `kid` |
| remote key fetch trust | attacker-controlled `jku` or `x5u` |
| weak secret | offline crack with targeted wordlists |

## 3. HIDDEN FIELDS AND BATCH ABUSE

### Mass assignment field picks

```text
role
isAdmin
admin
verified
plan
tier
permissions
org
owner
```

### Rate limit and batch abuse picks

```text
X-Forwarded-For: 1.2.3.4
X-Real-IP: 5.6.7.8
Forwarded: for=9.9.9.9
```

GraphQL or JSON batch abuse candidates:

- arrays of login mutations
- bulk object fetches with varying IDs
- repeated password reset or verification calls in one request

## 4. RATE LIMIT BYPASS FAMILIES

```text
X-Forwarded-For
X-Real-IP
Forwarded
User-Agent rotation
Path case / slash variants
```

## 5. NEXT ROUTING

- For GraphQL batching and hidden parameters: [graphql and hidden parameters](../graphql-and-hidden-parameters/MODULE.md)
- For default credential and brute-force planning: [authentication bypass](../authbypass-authentication-flaws/MODULE.md)
- For full JWT and OAuth depth: [jwt oauth token attacks](../jwt-oauth-token-attacks/MODULE.md)
- For OAuth or OIDC configuration flaws in browser and SSO flows: [oauth oidc misconfiguration](../oauth-oidc-misconfiguration/MODULE.md)
- For credentialed browser reads and origin trust bugs: [cors cross origin misconfiguration](../cors-cross-origin-misconfiguration/MODULE.md)