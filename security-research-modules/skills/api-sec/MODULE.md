---
name: api-sec
description: >-
  Entry P1 category router for API security. Use when choosing between API
  recon, authorization, token abuse, and hidden-parameter workflows before any
  deeper API topic skill.
---


中文名：suimi API 安全路由

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# API Security Router

这是 API 安全测试的分类入口。

先用这个 skill 判断当前 API 更像是文档和资产发现、对象授权、令牌信任问题，还是 GraphQL 与隐藏参数问题，再进入更细的专题 skill。

## When to Use

- 目标暴露 REST API、移动端后端或 GraphQL 接口
- 你需要先确定 API 测试顺序，再进入具体专题
- 你想把对象授权、JWT、GraphQL、隐藏字段这些方向分开处理

## Skill Map

- [API Recon and Docs](../api-recon-and-docs/MODULE.md): OpenAPI、Swagger、版本漂移、隐藏文档
- [API Authorization and BOLA](../api-authorization-and-bola/MODULE.md): BOLA、BFLA、方法滥用、隐藏可写字段
- [API Auth and JWT Abuse](../api-auth-and-jwt-abuse/MODULE.md): Bearer token、Header 信任、Claim 滥用、限流绕过
- [GraphQL and Hidden Parameters](../graphql-and-hidden-parameters/MODULE.md): introspection、batching、未公开字段、隐藏参数

## Quick Triage

| Observation | Route |
|---|---|
| Swagger 或 OpenAPI 存在 | [api-recon-and-docs](../api-recon-and-docs/MODULE.md) |
| IDs 出现在 URL、JSON、Header 或 GraphQL args | [api-authorization-and-bola](../api-authorization-and-bola/MODULE.md) |
| JWT token visible in traffic | [api-auth-and-jwt-abuse](../api-auth-and-jwt-abuse/MODULE.md) |
| `/graphql` 或 batched JSON arrays 存在 | [graphql-and-hidden-parameters](../graphql-and-hidden-parameters/MODULE.md) |
| 注册、登录、资料更新接受额外字段 | [api-authorization-and-bola](../api-authorization-and-bola/MODULE.md) 然后 [api-auth-and-jwt-abuse](../api-auth-and-jwt-abuse/MODULE.md) |

## Recommended Flow

1. 先看接口暴露面和文档资产
2. 再看对象级和功能级授权
3. 再看令牌、Header、签名与限流边界
4. 如果有 GraphQL 或复杂 JSON，再进入隐藏字段和 schema 滥用

## Related Categories

- [auth-sec](../auth-sec/MODULE.md)
- [business-logic-vuln](../business-logic-vuln/MODULE.md)
- [recon-for-sec](../recon-for-sec/MODULE.md)

## Promoted Learning Notes

### AI API Gateway security assessment: CORS+CSRF chain, SSRF via channel BaseURL, session trust vs JWT

- source: `20260721-004354-ai-api-gateway-security-assessment-cors-csrf-cha`
- category: method
- applies_to: ai-api-gateway, new-api, voapi, done-hub, one-hub
- purpose_zh: AI API网关类项目的通用安全审计方法：CORS+CSRF链、渠道BaseURL SSRF、Session信任vs JWT、兑换码竞态
- confidence: 3/5

**Lesson**

AI API网关类项目安全审计清单: 1)检查CORS是否AllowAllOrigins+AllowCredentials组合 2)检查渠道BaseURL/FetchModels是否有SSRF防护 3)检查session认证是否信任cookie中的role/status 4)检查密码重置是否在响应中返回明文密码 5)检查GetStatus未认证端点是否泄露OAuth ClientID/ServerAddress 6)检查兑换码兑换是否有事务级竞态防护 7)检查UpdateUser是否使用cleanUser模式防批量赋值

**Evidence**

QuantumNous/new-api v0.13.2 source code review: middleware/cors.go AllowAllOrigins+AllowCredentials, controller/channel.go FetchModels SSRF, controller/misc.go ResetPassword returns password, middleware/auth.go session trust

**Validation**

对照New API v0.13.2和Done-Hub最新代码验证，Done-Hub已修复session trust问题但仍存在CORS和SSRF