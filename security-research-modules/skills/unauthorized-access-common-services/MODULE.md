---
name: unauthorized-access-common-services
description: Use for authorized review of exposed management services and middleware consoles such as Redis, Elasticsearch, Solr, Docker API, Kubernetes dashboard, Jenkins, JMX, RMI, T3, AJP, message queues, databases, and admin interfaces discovered during recon or reverse engineering.
---


中文名：suimi常见服务未授权访问

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# Unauthorized Access To Common Services

Use this module only for owned, local, sandboxed, or explicitly authorized targets. Prefer read-only enumeration until scope and impact are clear.

## Quick Route

Start here when reverse or recon evidence shows management protocols, internal service ports, debug consoles, middleware endpoints, or default service banners.

Prioritize these checks:

- Confirm the service identity, version, bind address, and whether exposure is intended.
- Separate unauthenticated access, weak/default credentials, over-permissive roles, and network segmentation gaps.
- Capture only minimal proof: banner, harmless metadata endpoint, current user/role, version endpoint, or list-count response.
- Map service trust boundaries before changing state: internal-only service, admin plane, CI/CD, container runtime, message queue, database, or search index.
- If deserialization, JNDI, request smuggling, SSRF, or file access is involved, route to the corresponding specialist module.

## Evidence To Keep

- Host/port or URL pattern inside the authorized scope.
- Service banner or version clue.
- Authentication result and privilege clue.
- One minimal, non-destructive proof response.

## Related Modules

- `../recon-for-sec/MODULE.md`
- `../deserialization-insecure/MODULE.md`
- `../jndi-injection/MODULE.md`
- `../ssrf-server-side-request-forgery/MODULE.md`
- `../file-access-vuln/MODULE.md`
