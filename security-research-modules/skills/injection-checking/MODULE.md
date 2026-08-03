---
name: injection-checking
description: >-
  Entry P1 category router for injection testing. Use when routing between XSS,
  SQLi, SSRF, XXE, SSTI, command injection, and NoSQL injection workflows based
  on how attacker-controlled input is consumed.
---


中文名：suimi注入检测路由

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# Injection Testing Router

这是输入进入危险解释器或执行环境时的分类入口。

它适合在确认“这是注入类问题”之后，继续判断更偏向浏览器上下文、数据库、模板引擎、服务端请求、XML 解析器还是系统命令。

## When to Use

- 输入会进入 HTML、JS、SQL、模板、URL 提取器、XML 解析器或 shell
- 你还没决定应该先走 XSS、SQLi、SSRF、XXE、SSTI、CMDi 还是 NoSQL
- 你需要按输入流向选择正确的深度专题 skill

## Skill Map

- [XSS Cross Site Scripting](../xss-cross-site-scripting/MODULE.md)
- [SQLi SQL Injection](../sqli-sql-injection/MODULE.md)
- [SSRF Server Side Request Forgery](../ssrf-server-side-request-forgery/MODULE.md)
- [XXE XML External Entity](../xxe-xml-external-entity/MODULE.md)
- [SSTI Server Side Template Injection](../ssti-server-side-template-injection/MODULE.md)
- [CMDi Command Injection](../cmdi-command-injection/MODULE.md)
- [NoSQL Injection](../nosql-injection/MODULE.md)
- [Deserialization Insecure](../deserialization-insecure/MODULE.md)
- [JNDI Injection](../jndi-injection/MODULE.md)
- [Expression Language Injection](../expression-language-injection/MODULE.md)
- [CRLF Injection](../crlf-injection/MODULE.md)
- [Extra Injection Types (SSI, LDAP, XPath)](./EXTRA_INJECTION_TYPES.md)
- [Request Smuggling](../request-smuggling/MODULE.md)
- [Prototype Pollution](../prototype-pollution/MODULE.md)
- [Type Juggling](../type-juggling/MODULE.md)
- [HTTP Parameter Pollution](../http-parameter-pollution/MODULE.md)
- [XSLT Injection](../xslt-injection/MODULE.md)
- [CSV Formula Injection](../csv-formula-injection/MODULE.md)

## Recommended Flow

1. 先识别输入最终落点
2. 再选与该解释器最匹配的专题 skill
3. 小样本 payload 与 quick triage 已并入各主 skill，不再额外走 payload router

## Related Categories

- [file-access-vuln](../file-access-vuln/MODULE.md)