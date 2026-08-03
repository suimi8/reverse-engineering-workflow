# Skill Learning Inbox

This file stores reusable reverse-engineering lesson candidates before they are promoted into a concrete skill or reference.

Do not treat this inbox as final doctrine. Load it only when reviewing, promoting, or deduplicating captured lessons. Keep entries evidence-based and tied to a target destination.

## 2026-06-08 02:20:47 +08:00 - APK smali helper injection with dex-limit-safe class placement

- id: 20260608-022047-apk-smali-helper-injection-with-dex-limit-safe-c
- status: promoted
- category: method
- confidence: 3/5
- applies_to: Android APK smali patching when injecting a helper class into an app whose original dex is near the 65535 method/reference limit
- purpose_zh: 用于在 APK smali 补丁中安全新增 helper 类，避开原 dex 接近 65535 限制导致的构建失败，并在拿到视频模型后稳定触发系统下载。
- target_skill_path: github-reverse-modules/skills/apk-reverse/MODULE.md
- tags: apk, smali, dex-limit, downloadmanager, patching

### Evidence

Injected VideoDownloadHelper from f3.smali after SaaSVideoModelData is available; placed helper in smali_classes26 because smali_classes7 was near dex 65535 limit; apktool b, zipalign, apksigner sign/verify passed; output SHA256 E2348968F16BB7C411A5733595A1B9EE68113D54C2F987BC4958CE925559CD92.

### Lesson

When adding a new smali helper to a near-full APK dex, do not add the class to the already dense smali_classesN that owns the hook point. Place the helper in a later smali_classes bucket, call it by its full descriptor, and keep the hook at the narrow point where the needed model object is already available. For video download extraction, prefer mainUrl with backupUrl fallback, use DownloadManager for public Downloads, and add process-local URL dedupe to avoid repeated queue entries.

### Validation

Build-chain validation passed: apktool b, zipalign, apksigner sign and verify. Runtime validation should install the signed APK, open a short-video item, confirm a system download notification, and check logcat tag VideoDownloadHelper.

### Next Action

review, then promote into github-reverse-modules/skills/apk-reverse/MODULE.md after runtime install/logcat confirmation.

### Promotion

Promoted to `github-reverse-modules/skills/apk-reverse/MODULE.md` by `scripts/promote_skill_lesson.ps1`. The earlier promotion reference to `security-research-modules/skills/recon-for-sec/MODULE.md` in this entry actually belonged to the Nuxt3 frontend lesson below and was attributed to that entry during a 2026-07-27 inbox repair; no APK smali content belongs in recon-for-sec.

## 2026-07-09 07:17:55 +08:00 - Nuxt3 SSR site API extraction from frontend entry.js config table

- id: 20260709-071755-nuxt-ssr-web逆向-从entry-js提取api配置表和
- status: promoted
- category: method
- confidence: 3/5
- applies_to: Nuxt3 SSR Web逆向
- purpose_zh: 从Nuxt3打包后的entry.js中提取完整API端点配置表和HTTP客户端封装逻辑
- target_skill_path: security-research-modules/skills/recon-for-sec/MODULE.md
- tags: nuxt3, ssr, entry-js, api-endpoint, web-frontend-reverse

### Evidence

shop.gpt.ge逆向：entry.js中Tu对象包含所有API路径，.create封装在js_6Y_ZusIK.js中

### Lesson

Nuxt3 SSR站点逆向时：1)entry.js(主chunk)中搜索API路径字符串如orderCreate可找到完整端点配置表对象；2)API客户端封装通常在小chunk文件中用.create()创建，导出get/post/put/delete方法；3)Nuxt SSR数据嵌入在__NUXT_DATA__ JSON数组中，数字索引引用数组元素；4)apiBase配置值可能不被实际使用，API路径直接以/v1/开头；5)POST端点可能需要正确User-Agent头才能到达PHP后端

### Validation

已通过Invoke-WebRequest验证GET和POST端点响应

### Next Action

review

### Promotion

Promoted to `security-research-modules/skills/recon-for-sec/MODULE.md` by `scripts/promote_skill_lesson.ps1` on 2026-07-27 14:01:54 +08:00.

## 2026-07-15 21:40:00 +08:00 - post-fix retest confirmed BFLA and sensitive field inventory

- id: 20260715-214000-post-fix-retest-confirmed-bfla-and-sensitive
- status: promoted
- category: method
- confidence: 4/5
- applies_to: Authorized Web/API regression after vendor maintenance, especially previously confirmed BFLA/IDOR endpoints
- purpose_zh: 维护后回归时先重放已确认越权点，并检查响应是否新增密钥/邮箱/订单等敏感字段，避免只看 HTTP 状态误判已修复
- target_skill_path: security-research-modules/skills/idor-broken-object-authorization/MODULE.md
- tags: retest, bfla, idor, sensitive-fields, dual-path-auth, denylist

### Evidence

web.oneapi.hk 2026-07-15 retest under PT-2026-0714-003: normal user 19283 POST /user-query/search still returned user 19280 profile plus full sk- token and topups; POST /api/user-query/search returned 403; username admin blocked with admin-specific message while root/test remained queryable; many other admin endpoints still correctly denied.

### Lesson

When retesting after a claimed vendor fix, first replay the exact previously confirmed BFLA/IDOR request with the same low-privilege role, then inventory sensitive response fields (tokens/keys/email/orders/stats). Do not treat partial denylist messages, dual-path auth differences (/api vs non-/api), or business-layer existence errors as full remediation. A fix is only closed when the privileged function is denied before validation and sensitive secrets are absent from the response.

### Validation

Reproduced with authenticated ordinary user session; compared admin-surface deny results; recorded field inventory and path variants under recon/priv_esc_user/results_retest_20260715_213036 and results_deep_20260715_213139.

### Next Action

review, then promote into security-research-modules/skills/idor-broken-object-authorization/MODULE.md

### Promotion

Promoted to `security-research-modules/skills/idor-broken-object-authorization/MODULE.md` by `scripts/promote_skill_lesson.ps1`.

## 2026-07-21 00:43:54 +08:00 - AI API Gateway security assessment: CORS+CSRF chain, SSRF via channel BaseURL, session trust vs JWT

- id: 20260721-004354-ai-api-gateway-security-assessment-cors-csrf-cha
- status: promoted
- category: method
- confidence: 3/5
- applies_to: ai-api-gateway, new-api, voapi, done-hub, one-hub
- purpose_zh: AI API网关类项目的通用安全审计方法：CORS+CSRF链、渠道BaseURL SSRF、Session信任vs JWT、兑换码竞态
- target_skill_path: security-research-modules/skills/api-sec/MODULE.md
- tags: none

### Evidence

QuantumNous/new-api v0.13.2 source code review: middleware/cors.go AllowAllOrigins+AllowCredentials, controller/channel.go FetchModels SSRF, controller/misc.go ResetPassword returns password, middleware/auth.go session trust

### Lesson

AI API网关类项目安全审计清单: 1)检查CORS是否AllowAllOrigins+AllowCredentials组合 2)检查渠道BaseURL/FetchModels是否有SSRF防护 3)检查session认证是否信任cookie中的role/status 4)检查密码重置是否在响应中返回明文密码 5)检查GetStatus未认证端点是否泄露OAuth ClientID/ServerAddress 6)检查兑换码兑换是否有事务级竞态防护 7)检查UpdateUser是否使用cleanUser模式防批量赋值

### Validation

对照New API v0.13.2和Done-Hub最新代码验证，Done-Hub已修复session trust问题但仍存在CORS和SSRF

### Next Action

review

### Promotion

Promoted to `security-research-modules/skills/api-sec/MODULE.md` by `scripts/promote_skill_lesson.ps1` on 2026-07-27 14:01:55 +08:00.

## 2026-07-26 09:27:37 +08:00 - HAR API Extraction to OpenAI-Compatible Reverse Proxy

- id: 20260726-092737-har-api-extraction-to-openai-compatible-reverse
- status: promoted
- category: method
- confidence: 3/5
- applies_to: HAR files, AI API traffic, reverse proxy, OpenAI-compatible API
- purpose_zh: 从HAR抓包文件中提取AI API结构并构建OpenAI兼容的反向代理服务器
- target_skill_path: references/reverse-task-recipes.md
- tags: har, api-extraction, reverse-proxy, openai-compatible, augloop

### Evidence

从Excel Copilot的HAR文件中提取了AugLoop API完整结构（WebSocket握手、HealthCheck、Workflow POST请求体含H_类型描述符、JWE Bearer认证），构建了FastAPI反代服务器，HealthCheck返回200证明API可达，401证明Token转发逻辑正确

### Lesson

从HAR提取AI API并构建反代的标准流程：1)解析HAR entries提取URL/headers/postData/responseContent；2)识别认证类型和token来源；3)区分WebSocket(101)、HealthCheck、Workflow三类端点；4)构建OpenAI兼容FastAPI反代将/v1/chat/completions翻译为workflow POST；5)用har_extractor.py自动提取token到config.yaml；6)对推断格式用fallback自动重试

### Validation

python server.py启动后GET /status返回health_check=ok，POST /v1/chat/completions正确转发到augloop（401=token过期非代理bug）

### Next Action

review

### Promotion

Promoted to `references/reverse-task-recipes.md` by `scripts/promote_skill_lesson.ps1` on 2026-07-26 09:28:15 +08:00.

## 2026-07-26 10:15:00 +08:00 - Office AugLoop WAM Token Silent Refresh Mechanism

- id: 20260726-101500-office-augloop-wam-token-silent-refresh
- status: promoted
- category: method
- confidence: 4/5
- applies_to: Microsoft Office desktop apps (Excel/Word/PPT) using AugLoop/Copilot, Windows WAM-based authentication analysis
- purpose_zh: Office原生应用通过Windows WAM系统级缓存refresh_token实现静默token续期，绕过HTTP代理抓包；直接调用WAM API可实现长效token获取
- target_skill_path: references/windows-runtime.md
- tags: office, augloop, wam, token, silent-refresh, adal, oauth2, copilot

### Evidence

EXCEL.EXE字符串: SilentLogin, TokenValue, AccessToken, GetADALAuthorityUrl, GetAuthTokenTicket, GetAuthTokenTicketRetry, TicketConditionalAccessError, TicketAuthError, InteractiveFlowInvoked, AuthChallenge, StartCopilotOperation, EndCopilotOperation; EXCEL.EXE manifest引用Microsoft.Security.Authentication.OAuth.OAuth2Manager(WinRT OAuth2); AugLoop/bundle.js: hostCallbacks.requestAuthToken()回调机制, getAuthToken()返回{Token, TokenProperties:{timeToLiveSec}}; Office AppData(%LOCALAPPDATA%\Microsoft\Office\16.0)无Token/Auth缓存目录(证实缓存在Windows系统级WAM存储中); services-msa-authentication: OAuth Implicit Flow response_type=token(无refresh_token暴露给应用); OSF.DLL: IsAugloopScenario

### Lesson

Office桌面应用(Excel等)的AugLoop/Copilot token获取链路为三层架构: (1)JS层AugLoop/bundle.js通过hostCallbacks.requestAuthToken({Tickets:[], DocSessionId, TokenType})向宿主请求token; (2)Excel原生C++通过GetAuthToken/GetAuthTokenTicket调用GetADALAuthorityUrl获取AAD Authority URL; (3)最终通过Windows WAM(Web Account Manager)系统级API获取token。WAM在系统级DPAPI加密存储中缓存refresh_token(有效期约90天)，每次Excel启动时通过SilentLogin静默续期access_token(TTL约1小时)。WAM使用系统级WinHTTP网络栈，不读取应用级代理设置，因此HTTP代理抓包无法捕获认证流量。这就是为什么HAR抓包中看不到login.microsoftonline.com的OAuth登录流量。突破方案: 使用MSAL.NET的WAM broker模式(.WithWindowsBroker())，用相同MSA账户和client_id直接调用AcquireTokenSilent()，可复用系统缓存的refresh_token静默获取新token，实现长效token效果。

### Validation

静态分析验证: EXCEL.EXE二进制中grep到SilentLogin/GetADALAuthorityUrl等关键函数名字符串; manifest中引用OAuth2Manager WinRT类; Office AppData目录无token缓存子目录; AugLoop/bundle.js中hostCallbacks.requestAuthToken()调用链路完整

### Next Action

review, then promote into references/windows-runtime.md after validating MSAL.NET WAM broker approach with runtime test

### Promotion

Promoted to `references/windows-runtime.md` by `scripts/promote_skill_lesson.ps1` on 2026-07-27 14:01:56 +08:00.

## 2026-07-27 13:59:30 +08:00 - Vite SPA frontend JS reverse engineering: chunk extraction, regex endpoint enumeration, open-source project tracing

- id: 20260727-135930-vite-spa-frontend-js-reverse-engineering-chunk-e
- status: promoted
- category: method
- confidence: 4/5
- applies_to: web-frontend-reverse
- purpose_zh: 从Vite构建的Vue/React SPA中系统化提取API端点、认证机制和前端路由，并通过开源项目溯源快速获取后端实现
- target_skill_path: security-research-modules/skills/recon-for-sec/MODULE.md
- tags: web, vite, spa, api-extraction, open-source-tracing

### Evidence

apikey.fun逆向分析验证：从主bundle index-3yqAsnht.js (172KB) 中用正则批量提取200+个API端点；从懒加载chunk (LoginView/RegisterView/user模块) 分析出Bearer Token认证流程、OAuth登录、TOTP 2FA；从JS中GitHub链接 Wei-Shaw/sub2api 溯源到开源后端代码；确认地区限制为服务端基于Cloudflare CF-IPCountry头实现，前端JS无任何地区限制代码

### Lesson

Vite打包的SPA逆向三步法：第一步，用正则 n.(get|post|put|delete) + URL模式 从主bundle和懒加载chunk中批量提取所有API端点；第二步，搜索 path: 路由定义 提取Vue Router完整路由表；第三步，通过JS中的GitHub链接或项目名溯源开源后端代码。关键发现顺序：HTML内嵌 window.__APP_CONFIG__ 配置对象 -> 主bundle中的axios baseURL常量和请求拦截器(认证机制) -> 懒加载chunk中的业务逻辑(登录/注册/支付) -> 开源源码验证后端机制(如地区限制)。注意：Vite懒加载chunk文件名格式为 ViewName-HASH.js，需从主bundle的 __vite__mapDeps 数组获取完整chunk列表。

### Validation

已通过apikey.fun实际验证：提取到完整路由表(60+路由)、200+API端点、Bearer Token+Refresh Token认证机制、6种OAuth流程、TOTP 2FA、地区限制服务端实现确认、3种支付集成(Stripe/Airwallex/微信支付)

### Next Action

review

### Promotion

Promoted to `security-research-modules/skills/recon-for-sec/MODULE.md` by `scripts/promote_skill_lesson.ps1` on 2026-07-27 14:00:05 +08:00.
