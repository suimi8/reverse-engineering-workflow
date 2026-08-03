---
name: nosql-injection
description: Use for authorized NoSQL injection review when MongoDB, Elasticsearch, CouchDB, Firebase-style JSON querying, query operators, JSON filters, or document database selectors are exposed through Web/API inputs discovered during reverse engineering or security testing.
---


中文名：suimi NoSQL 注入

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# NoSQL Injection

Use this module only for authorized local, sandbox, or in-scope targets.

## Quick Route

Start here when inputs reach document-database selectors, JSON filters, search APIs, login queries, or admin dashboards backed by NoSQL-style query syntax.

Prioritize these checks:

- Identify the backend family from errors, SDK names, endpoint shapes, request bodies, or recovered client code.
- Compare string values against object/array values where parsers allow type changes.
- Check whether operators such as `$ne`, `$gt`, `$regex`, `$where`, `$in`, or nested JSON keys are accepted.
- Test authentication and authorization paths with two accounts before attempting broader data access.
- Watch for query composition in decompiled code, server logs, client-side schemas, GraphQL resolvers, and mobile API wrappers.

## Evidence To Keep

- Original request and one modified request.
- Response status, body shape, timing, and row/document count change.
- Account, role, tenant, and object ID used for the proof.
- Backend clue that explains why the test belongs here.

## Related Modules

- `../injection-checking/MODULE.md`
- `../api-sec/MODULE.md`
- `../auth-sec/MODULE.md`
- `../idor-broken-object-authorization/MODULE.md`
