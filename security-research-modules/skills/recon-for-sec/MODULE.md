---
name: recon-for-sec
description: >-
  Entry P1 category router for reconnaissance and methodology. Use when mapping
  scope, discovering assets, fingerprinting technology, building endpoint
  inventory, and choosing the first high-value security testing path.
---


中文名：suimi安全侦察路由

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# Recon and Methodology Router

这是新目标和未知攻击面的起始入口。

## When to Use

- 你刚接一个新的目标，还不知道先测什么
- 你需要先做资产发现、技术识别、接口清点和测试路线规划
- 你想把后续测试建立在结构化方法论上，而不是随机枚举 payload

## Skill Map

- [Recon and Methodology](../recon-and-methodology/MODULE.md)
- [Insecure Source Code Management](../insecure-source-code-management/MODULE.md) — .git/.svn/.hg exposure detection
- [Dependency Confusion](../dependency-confusion/MODULE.md) — Supply chain reconnaissance for internal package names

## Recommended Flow

1. 先确认 in-scope 资产和目标类型
2. 再做资产发现、端口与服务识别、技术指纹与端点收集
3. 按收集到的现象再路由到 [api-sec](../api-sec/MODULE.md)、[auth-sec](../auth-sec/MODULE.md)、[injection-checking](../injection-checking/MODULE.md) 或 [business-logic-vuln](../business-logic-vuln/MODULE.md)

## Promoted Learning Notes

### Vite SPA frontend JS reverse engineering: chunk extraction, regex endpoint enumeration, open-source project tracing

- source: `20260727-135930-vite-spa-frontend-js-reverse-engineering-chunk-e`
- category: method
- applies_to: web-frontend-reverse
- purpose_zh: 从Vite构建的Vue/React SPA中系统化提取API端点、认证机制和前端路由，并通过开源项目溯源快速获取后端实现
- confidence: 4/5

**Lesson**

Vite打包的SPA逆向三步法：第一步，用正则 n.(get|post|put|delete) + URL模式 从主bundle和懒加载chunk中批量提取所有API端点；第二步，搜索 path: 路由定义 提取Vue Router完整路由表；第三步，通过JS中的GitHub链接或项目名溯源开源后端代码。关键发现顺序：HTML内嵌 window.__APP_CONFIG__ 配置对象 -> 主bundle中的axios baseURL常量和请求拦截器(认证机制) -> 懒加载chunk中的业务逻辑(登录/注册/支付) -> 开源源码验证后端机制(如地区限制)。注意：Vite懒加载chunk文件名格式为 ViewName-HASH.js，需从主bundle的 __vite__mapDeps 数组获取完整chunk列表。

**Evidence**

apikey.fun逆向分析验证：从主bundle index-3yqAsnht.js (172KB) 中用正则批量提取200+个API端点；从懒加载chunk (LoginView/RegisterView/user模块) 分析出Bearer Token认证流程、OAuth登录、TOTP 2FA；从JS中GitHub链接 Wei-Shaw/sub2api 溯源到开源后端代码；确认地区限制为服务端基于Cloudflare CF-IPCountry头实现，前端JS无任何地区限制代码

**Validation**

已通过apikey.fun实际验证：提取到完整路由表(60+路由)、200+API端点、Bearer Token+Refresh Token认证机制、6种OAuth流程、TOTP 2FA、地区限制服务端实现确认、3种支付集成(Stripe/Airwallex/微信支付)

### Nuxt3 SSR site API extraction from frontend entry.js config table

- source: `20260709-071755-nuxt-ssr-web逆向-从entry-js提取api配置表和`
- category: method
- applies_to: Nuxt3 SSR Web逆向
- purpose_zh: 从Nuxt3打包后的entry.js中提取完整API端点配置表和HTTP客户端封装逻辑
- confidence: 3/5

**Lesson**

Nuxt3 SSR站点逆向时：1)entry.js(主chunk)中搜索API路径字符串如orderCreate可找到完整端点配置表对象；2)API客户端封装通常在小chunk文件中用.create()创建，导出get/post/put/delete方法；3)Nuxt SSR数据嵌入在__NUXT_DATA__ JSON数组中，数字索引引用数组元素；4)apiBase配置值可能不被实际使用，API路径直接以/v1/开头；5)POST端点可能需要正确User-Agent头才能到达PHP后端

**Evidence**

shop.gpt.ge逆向：entry.js中Tu对象包含所有API路径，.create封装在js_6Y_ZusIK.js中

**Validation**

已通过Invoke-WebRequest验证GET和POST端点响应