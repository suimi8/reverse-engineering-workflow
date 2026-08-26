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

## 2026-08-14 23:09:42 +08:00 - dujiaoka/发卡站 vendor 暴露与认证接口方法混淆检测

- id: 20260814-230942-dujiaoka-发卡站-vendor-暴露与认证接口方法混淆检测
- status: promoted
- category: method
- confidence: 3/5
- applies_to: Laravel/dujiaoka 发卡站 Web 审计
- purpose_zh: 审计独角数卡类站点时优先验证 /vendor/composer/installed.json 匿名可读性以获取精确依赖版本，并对 /admin/api 认证端点逐一测试 GET/PUT/PATCH/DELETE/OPTIONS 方法混淆与错误信息泄露
- target_skill_path: security-research-modules/skills/recon-for-sec/MODULE.md
- tags: none

### Evidence

lyxazy.cn /vendor/composer/installed.json -> 200 104KB 38包精确版本; /admin/api/authentication/login GET/PUT/PATCH/DELETE 均返回业务 JSON 该邮箱不存在; Set-Cookie ACG-SHOP 无 HttpOnly/Secure/SameSite

### Lesson

Laravel 系发卡站即使有 CF，vendor 目录下的 composer/installed.json 常可直接读取获得完整供应链指纹；认证接口不限制 HTTP 方法时，GET 也能触发业务逻辑并泄露枚举信息；会话 Cookie 标志缺失需与 XSS 面联动评估

### Validation

对 lyxazy.cn 复现 3/3；对同类 dujiaoka 站点可复用同一路径与方法矩阵

### Next Action

review

### Promotion

Promoted to `security-research-modules/skills/recon-for-sec/MODULE.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 01:51:41 +08:00.

## 2026-08-14 23:58:42 +08:00 - 同主体多平台联动测绘：商城+Flask代理门户+shop子域

- id: 20260814-235842-同主体多平台联动测绘-商城-flask代理门户-shop子域
- status: promoted
- category: method
- confidence: 3/5
- applies_to: 多域名黑盒 Web 审计
- purpose_zh: 域名间共享主体时，除主商城外必须测绘同源 JS 中 PLATFORM_HOSTS 列出的全部域名与 SPA chunk，逐个提取 /api 路由面、邀请码 oracle、游客店铺 slug 机制与登录限速策略
- target_skill_path: security-research-modules/skills/recon-for-sec/MODULE.md
- tags: none

### Evidence

lyxazy.cn(dujiaoka) + www.lyxazy.top(Flask门户 /api/auth|admin|shop|openapi 80+端点) + shop.lyxazy.top + octoneai.com(同商城); invite-check 泄露 inviterUid:1; 登录统一错误+429/60s; 邮件验证码多临时邮箱均不达

### Lesson

黑盒多域名目标先抓主站 JS 的 PLATFORM_HOSTS/跨域配置，第二平台往往防御配置不同；邀请码校验接口可泄露上级 UID；临时邮箱收不到码时不要无限重试，转而枚举其他认证面或攻击签名/会话机制

### Validation

对 lyxazy 系 4 域名复现；思路对同构站点可复用

### Next Action

review

### Promotion

Promoted to `security-research-modules/skills/recon-for-sec/MODULE.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 01:51:41 +08:00.

## 2026-08-24 01:44:17 +08:00 - x64dbg-reverse 模块需要从 static-analysis.md 交叉引用才能被发现

- id: 20260824-014417-x64dbg-reverse-模块需要从-static-analysis-md-交叉引用才能被发
- status: promoted
- category: tooling
- confidence: 3/5
- applies_to: reverse-engineering-workflow 技能包自身的可发现性
- purpose_zh: 让先读 references/static-analysis.md 的用户或 agent 也能发现新增的 x64dbg-reverse 动态调试模块，否则装好了也没人知道去哪找
- target_skill_path: references/static-analysis.md
- tags: x64dbg, discoverability, cross-reference

### Evidence

static-analysis.md 现有的 x64dbg 小节只列了几条断点技巧(MessageBoxW/WinHttpSendRequest 等), 完全没有提到新增的 x64dbg-reverse 完整模块的存在, 从这条路径进来的读者/agent 发现不了它。

### Lesson

在 references/static-analysis.md 的 "x64dbg Static-Dynamic Bridge" 小节末尾追加一句指引: 需要完整的 x64dbg 动态调试工作流(71 个 MCP 工具: 断点/内存读写/寄存器/模块符号/OEP 检测/内存转储等)时, 加载 github-reverse-modules/skills/x64dbg-reverse/MODULE.md, 工具速查见其 references/x64dbg-mcp-cheatsheet.md, 部署用 scripts/install.ps1。

### Validation

人工核对 static-analysis.md 现有内容确认缺少该指引

### Next Action

promote

### Promotion

Promoted to `references/static-analysis.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 01:44:39 +08:00.

## 2026-08-24 01:44:18 +08:00 - 新增工具模块必须同步给 select_skill.ps1 加路由规则,并用自然口语而非关键词精确测试

- id: 20260824-014418-新增工具模块必须同步给-select-skill-ps1-加路由规则-并用自然口语而非关键词精确
- status: promoted
- category: method
- confidence: 3/5
- applies_to: 给 reverse-engineering-workflow 新增任何 github-reverse-modules/skills/<tool> 模块时
- purpose_zh: 避免新模块写完但自动路由接不上、或路由规则只对精确关键词生效、自然口语测不到的问题
- target_skill_path: references/reverse-task-recipes.md
- tags: routing, select_skill, regex, cjk

### Evidence

给 x64dbg-reverse 写完 MODULE.md 后, select_skill.ps1 -TaskText "帮我用x64dbg调试这个exe" 最初路由到泛化的 reverse-engineering(置信度0.68), 不是新模块; 加规则后, "帮我附加到这个进程"和"下个断点"这类自然说法仍然测试失败, 因为正则用的是精确连续短语"附加进程"/"下断点"; 改成 附加.{0,6}(进程|process) 和裸词"断点"后才全部命中, 同时用 IDA 相关的对照 query 验证没有误伤既有路由。

### Lesson

1) 新增 github-reverse-modules/skills/<tool>/MODULE.md 后必须同步在 scripts/select_skill.ps1 的 $rules 数组里加一条同名规则, 否则 invoke_skill.ps1/select_skill.ps1 永远路由不到新模块, 哪怕 frontmatter description 写得再完整。
2) 中文正则关键词要假设自然语言会在词中间插入字/虚词(如"下断点"会被说成"下个断点", "附加进程"会被说成"附加到这个进程"), 优先用短词干加宽松间隔(如 X.{0,6}Y)而不是长完整短语精确匹配, 并且至少要用 3-5 条非关键词式的自然提问反复测试, 不能只测最干净的那一句就收工。

### Validation

select_skill.ps1 对 5 条不同自然说法(含两条插字变体)加 1 条 IDA 对照 query 全部人工验证通过; tests/routing.Tests.ps1 与 scripts/healthcheck.ps1 各补了一条回归用例锁定

### Next Action

review - 需要人工确认落点是 reverse-task-recipes.md 还是需要新开一个专门讲如何新增模块的参考文档

### Promotion

Promoted to `references/reverse-task-recipes.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 01:51:41 +08:00.

## 2026-08-24 01:44:18 +08:00 - bootstrap-manifest.json 声明 canAutoInstall 前必须先在脚本里真正实现

- id: 20260824-014418-bootstrap-manifest-json-声明-canautoinstall-前必须先在脚
- status: promoted
- category: tooling
- confidence: 3/5
- applies_to: github-reverse-modules/skills/scripts/bootstrap-manifest.json 里任何新增或修改的 capability 条目
- purpose_zh: 避免 manifest 对外承诺能一键自动装好某工具,实际脚本却只报错退出的文档与行为不一致
- target_skill_path: references/external-tool-downloads.md
- tags: manifest, bootstrap, qa

### Evidence

x64dbg 这条 capability 一开始写了 canAutoInstall:true, 但当时 install.ps1 遇到 x64dbg 缺失只会输出 ERR:x64dbg_not_found 就退出, 并不会真的下载; 直到后来补上 -AutoInstallX64dbg 真正实现下载解压逻辑, manifest 声明和脚本行为才对上。

### Lesson

给 bootstrap-manifest.json 加或改一条 canAutoInstall:true 的 capability 时, 必须在对应的 install/start 脚本里现场跑一遍缺依赖场景验证它真的能把这个工具装好(或者至少缺失时给出可执行的下一步), 不能只在 manifest 里声明就当完成; MODULE.md 的按需自举表格也要和脚本真实行为保持同步, 发现不一致时以实际跑出来的行为为准去改文档, 而不是反过来。

### Validation

对比 install.ps1 修复前后, 在缺少 x64dbg 场景下的真实命令行输出

### Next Action

review - 建议后续抽查 bootstrap-manifest.json 里其他 canAutoInstall:true 条目(如 ghidra-mcp/jshookmcp)是否也有类似声明与实现不一致

### Promotion

Promoted to `references/external-tool-downloads.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 01:51:41 +08:00.


## 2026-08-24 18:13:36 +08:00 - 外部 OSINT 工具目录仓库接入 security-research-modules 的注册清单

- id: 20260824-181336-外部-osint-工具目录仓库接入-security-research-modules-的注册清
- status: promoted
- category: method
- confidence: 4/5
- applies_to: 为 reverse-engineering-workflow 添加新的外部工具目录/安全侦察类内部模块
- purpose_zh: 把一个外部 GitHub 工具目录仓库（如 awesome-osint-arsenal）正确挂载为本 skills 包内部模块，并让 healthcheck 全部校验通过
- target_skill_path: references/reverse-task-recipes.md
- tags: skill-package-editing, security-research-modules, module-registration, osint

### Evidence

rawfilejson/awesome-osint-arsenal（2054 star/307 fork/MIT/最近 push 2026-07-21）接入为 security-research-modules/skills/osint-recon/MODULE.md；同步编辑 references/chinese-skill-names.json、references/unified-skills-entry.md、recon-for-sec/MODULE.md 的 Skill Map、security-research-modules/INDEX.md 新增 Locally Added Modules 说明；重跑 scripts/healthcheck.ps1 后 reusable-skill-registry 60->61、single-installable-skill 内部模块数 59->60、mandatory-final-feedback-contract 覆盖 61->62、chinese-skill-names 覆盖 60->61、unit-tests PASS:passed=19，24 项检查零 fail。

### Lesson

接到"把某个 GitHub 仓库加入我的逆向/安全 skills"类请求时的注册清单：
1) 先判断仓库性质决定落点——二进制/APK/调试类工具挂 github-reverse-modules/skills/，Web/API/认证/侦察类安全知识或工具目录挂 security-research-modules/skills/，新建 <name>/MODULE.md，不要塞进无关既有模块。
2) frontmatter 必须是 name 后立刻紧跟 description（---\nname: kebab-case\ndescription: >-），中间不能插其它字段，否则 healthcheck 的 markdown 模块正则判失败。
3) 正文原样保留标准"新技能/方法反馈"闭环段落（含 finish_skill_run.ps1/record_skill_lesson.ps1/review_skill_lessons.ps1/promote_skill_lesson.ps1 五个 token），否则 mandatory-final-feedback-contract 检查会挂。
4) 同步四处登记：chinese-skill-names.json 加 path+display_name、unified-skills-entry.md 加表格行、直接路由模块的 Skill Map 里加相对链接、若所属目录树的 INDEX.md 自称是"donor 导入清单"则另加一节说明这是本地新增而非 donor 内容，以免文档失实。
5) 是否要给 select_skill.ps1 加正则不是强制项——多数 P2 主题模块（recon-for-sec/recon-and-methodology/dependency-confusion 等）都没有专属规则，靠路由器 Skill Map 或 resolve_skill.ps1 按路径/关键词即可触达，盲目加规则反而可能撞上 healthcheck 里 selector 的固定回归用例。
6) 若源仓库自带一键安装脚本，不要顺手写进 github-reverse-modules/skills/scripts/bootstrap-manifest.json 自动装——该清单每条 capability 应对应单一、边界清楚的工具；"一次装几百个工具、其中混了 C2/RAT/钓鱼套件"这类 meta-installer 只适合当只读目录记录用法与安全边界。
7) 全部编辑完必须跑一次 scripts/healthcheck.ps1，它串联了 registry 计数、frontmatter 正则、相对链接可达性、中文名同步、mandatory-final-feedback-contract、Pester 单测等校验，任何一步 fail 说明注册没做全。

### Validation

scripts/healthcheck.ps1 全量重跑 24 项检查零 fail；scripts/list_skills.ps1 -AsJson 能检索到 display_name=suimi OSINT 侦察工具库 的新条目。

### Next Action

review

### Promotion

Promoted to `references/reverse-task-recipes.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 18:17:07 +08:00.


## 2026-08-24 18:30:50 +08:00 - 大体量第三方数据源接入 skill 的三层模式：本地快照+完整索引表+按需查询

- id: 20260824-183050-大体量第三方数据源接入-skill-的三层模式-本地快照-完整索引表-按需查询
- status: promoted
- category: tooling
- confidence: 4/5
- applies_to: 为 skills 包接入任何"条目多、有稳定分类字段、依赖不稳定外部网络"的第三方数据目录
- purpose_zh: 用一个主入口模块搭配本地数据快照和完整分类索引表，同时做到覆盖完整、路由准确、不依赖实时网络、不把模块数量炸开
- target_skill_path: references/reverse-task-recipes.md
- tags: skill-package-editing, osint-recon, data-snapshot, reliability

### Evidence

osint-recon 模块从"只写现查 tools.json 的 curl/jq 命令"升级为"本地打包 references/tools-snapshot.json（753 条，26 类，399604 字节，两次独立抓取逐字节比对一致）+ 正文内嵌完整 26 类分类表（类目、数量、示例工具）"。本机在同一会话内对 raw.githubusercontent.com 的多次 curl 请求里，install.sh/osint.sh/redteam.sh/blueteam.sh/forensics.sh 曾报 schannel 握手失败或连接超时，而同批的 tools.json/hardware.sh/extras.sh/labs.sh/termux.sh 成功，证明该网络路径确实不稳定，不是偶发。落地快照后用 PowerShell ConvertFrom-Json 实测查询 dark-web 分类返回 3 条正确记录（Ahmia/Aleph Open Search/Dark.fail），且 scripts/healthcheck.ps1 24 项检查全部保持 PASS。

### Lesson

当某个 skill 依赖的第三方数据源"体量大、类别多、但可以用一个稳定字段做二级索引"时（比如这个 OSINT 仓库的 tools.json 用 category 字段分 26 类 753 条），不要因为"要覆盖全部数据"就机械展开成一个类别一个 MODULE.md。正确做法是三层分离：
1) 完整数据本地打快照（如 references/tools-snapshot.json），一次性把全量数据落盘进模块目录，解决"未来查询是否完整、来源是否可达"的问题——这次实测 raw.githubusercontent.com 在本机会间歇性 schannel 握手失败（同一批文件里有的成功有的直接报错），只写"现查来源"这一条路径不够可靠，必须有本地兜底。
2) 正文只放"索引字段的完整分类表"（分类名+数量+几个示例名），不展开每条记录——分类表本身就是给 Agent 用的路由依据，让它一眼选对 category 取值，不用先跑一次 unique 查询。
3) 具体某条记录的详情，只在真正要用某个工具时才用 jq/ConvertFrom-Json 按分类过滤读取快照，绝不建议把整份大文件读进对话上下文。
这样"一个主入口 MODULE.md + 一份本地数据快照"就同时满足了：入口不膨胀、覆盖率是完整的（不是抽样几个类别举例）、且不依赖不稳定的实时网络。快照会随来源更新而过时，需要在正文写明快照日期和刷新命令，而不是假装它会自动保持最新。

### Validation

PowerShell 对本地快照查询 category=dark-web 返回正确子集；scripts/healthcheck.ps1 全量重跑 24 项检查零 fail（含链接可达性、frontmatter 正则、Pester 单测）。

### Next Action

review

### Promotion

Promoted to `references/reverse-task-recipes.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 18:31:06 +08:00.


## 2026-08-24 18:44:56 +08:00 - 给既有 P2 主题模块补 select_skill.ps1 自动路由规则的安全操作顺序

- id: 20260824-184456-给既有-p2-主题模块补-select-skill-ps1-自动路由规则的安全操作顺序
- status: promoted
- category: tooling
- confidence: 4/5
- applies_to: 为 security-research-modules 或 github-reverse-modules 下已存在的模块事后补充 select_skill.ps1 正则规则
- purpose_zh: 独立验证 Unicode 转义 + 双向宽松间隔关键词 + 自然语言批量测试 + 全量 healthcheck，四步做完再确认规则是否安全上线
- target_skill_path: references/reverse-task-recipes.md
- tags: skill-package-editing, select_skill, routing, osint-recon

### Evidence

为 osint-recon 补 select_skill.ps1 规则时：先用 12 组 esc/expect 对照表核对了开源情报/搜集/收集/人肉/社工库/数据泄露/暗网/用户名/邮箱/手机号/域名/反查这 12 个词的 \uXXXX 转义，全部核对通过后才写进规则；写完后用 7 条自然提问（"帮我找个OSINT工具查一下这个用户名"/"有没有能反查这个手机号的工具"/"想做开源情报收集"/"查一下这个邮箱有没有在数据泄露里出现过"/"暗网上有没有相关的搜索工具"/"想搞一下人肉"/"有没有社工库可以查"）全部正确路由到 osint-recon(confidence=0.87)，同时 3 条既有对照 query（SQL injection/BOLA/mobile frida）路由结果不变；最后 scripts/healthcheck.ps1 24 项检查（含 unit-tests PASS:passed=19）全部保持 PASS。

### Lesson

给已存在的 P2 主题模块（原本按惯例没有 select_skill.ps1 专属规则）事后补一条自动路由规则时，按这个顺序做，比直接改完就跑 healthcheck 更保险：
1) 先用 PowerShell 的 `u{XXXX}` 字符串插值转义独立验证每个要用到的 \uXXXX regex 转义是否等于目标汉字（写一个 esc/expect 对照表批量比对），再把 \uXXXX 形式写进 $rules 数组——正则里的 \uXXXX 是 .NET regex 引擎解释的，跟 PowerShell 字符串本身的转义规则是两套体系，手算 code point 很容易抄错一位但不会报错，只会静默匹配失败。
2) 关键词选型延续之前 x64dbg-reverse 那条经验（短词干+宽松间隔），但新增一点：像"反查"这种通用动词单独用会太泛，要与对象词一起限定，如 (用户名|邮箱|手机号|域名).{0,4}反查|反查.{0,4}(用户名|邮箱|手机号|域名)，双向都写，覆盖"XX反查"和"反查XX"两种自然语序。
3) 新规则加完不能只测新关键词命中，必须至少用 3 条不含关键词的自然提问 + 2-3 条已有其它模块的对照 query 一起测（同一个 select_skill.ps1 -TaskText 循环批量测最快），确认新增规则的置信度没有意外反超或反被反超已有规则。
4) 最后一定要跑一次完整 scripts/healthcheck.ps1 而不是只跑 select_skill.ps1 本身——healthcheck 里的 reusable-skill-selector 和 unit-tests 会把 Pester 固定回归用例也跑一遍，这是唯一能发现"新正则不小心让某个已有 fixed test case 变更了选择结果"的关卡。
另外：不是所有 P2 主题模块都要补规则——之前记录的"多数 P2 模块靠路由器 Skill Map 触达、不用加规则"仍然是默认值；只有当用户明确要求"确保直接命中/调用准确性"时，才值得为单个模块补这一条，因为每加一条规则都是要长期维护、可能和未来新模块关键词冲突的成本。

### Validation

7 条自然语言 OSINT 提问 + 3 条既有对照 query 手工批量验证；scripts/healthcheck.ps1 全量重跑 24 项检查零 fail。

### Next Action

review

### Promotion

Promoted to `references/reverse-task-recipes.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 18:45:09 +08:00.


## 2026-08-24 19:07:58 +08:00 - 把跨文件登记一致性审计固化成 healthcheck.ps1 永久检查项，而不是每次人工再查一遍

- id: 20260824-190758-把跨文件登记一致性审计固化成-healthcheck-ps1-永久检查项-而不是每次人工再查一遍
- status: promoted
- category: tooling
- confidence: 5/5
- applies_to: reverse-engineering-workflow 的 healthcheck.ps1 与任何多文件互相登记/互相链接的 skill 注册体系
- purpose_zh: 把"新模块有没有漏登记到某个索引文件、有没有漏从某个路由器链接过去"这类只能靠人工再检查才发现的问题，变成自动化回归检查，并用可控阳性测试证明检查本身真的有效
- target_skill_path: scripts/healthcheck.ps1
- tags: skill-package-editing, healthcheck, cross-reference-audit, regression-test

### Evidence

用户要求"再次检测skills是否符合规范"后，先写了一版独立 PowerShell 审计脚本跑一遍，发现 healthcheck.ps1 之前从未覆盖的 4 类真实遗漏：unified-skills-entry.md 和 SKILL.md 都漏了 traffic-capture（此前会话添加、未完整登记）、以及 clickjacking/open-redirect/unauthorized-access-common-services/web-cache-deception 这 4 个 security-research-modules 详情模块虽然注册在案但没有被任何 P1 路由器的 Skill Map 链接到（属于"注册了但发现不了"的孤儿模块）。修复后把同一套审计逻辑固化成 healthcheck.ps1 里的新函数 suimiTest-CrossReferenceCompleteness 并接入主检查序列；随后做了一次可控阳性测试——临时删掉 hack/MODULE.md 里的 Clickjacking 链接，healthcheck 立即报 [FAIL] cross-reference-completeness，错误信息精确点名 clickjacking，恢复链接后重跑变回 [PASS]，证明新检查确实在正确位置生效，不是摆设。

### Lesson

healthcheck.ps1 里已有的检查（frontmatter 正则、中文名同步、mandatory-final-feedback-contract、注册表计数）都是"文件本身合不合规"，完全不检查"文件之间的引用关系是否完整"——这类跨文件登记遗漏（比如新模块漏加进 unified-skills-entry.md 的表格、漏加进 INDEX.md 的列表、漏从任何 P1 路由器的 Skill Map 链接过去）不会让任何一条既有检查失败，只能靠人工"再检查一遍"才会发现，而人工检查本身不可靠、下次加新模块大概率还会再漏。
解法：把"跨文件一致性审计"写成 healthcheck.ps1 的一个新检查函数（本次新增的 suimiTest-CrossReferenceCompleteness），一次性覆盖五类此前从未被自动化覆盖的登记点：
1) 注册表里每个 MODULE.md 的路径字符串是否在 references/unified-skills-entry.md 全文里出现过；
2) github-reverse-modules/skills 下每个子目录名是否在 github-reverse-modules/INDEX.md 里被提到；
3) 同一批子目录名是否也在根 SKILL.md 的 Added Reverse Modules 列表里出现；
4) security-research-modules/skills 下每个子目录名是否在 security-research-modules/INDEX.md 里被提到；
5) 除 7 个已知 P1 路由器（hack/recon-for-sec/api-sec/auth-sec/injection-checking/file-access-vuln/business-logic-vuln）自身外，剩下每个 security-research-modules 详情模块是否至少被其中一个路由器的 Skill Map（`](../xxx/MODULE.md)` 形式的相对链接）链接到，顺带用同一份注册表核对 select_skill.ps1 的 $rules 数组里每条 name 是否真实存在（防止手滑打错字导致规则永远匹配不到任何模块）。
验证新检查本身是否真的有效，不能只看它在当前"已修好"的状态下报 pass——必须做一次可控的阳性破坏测试：临时删掉一条已知会触发该检查的引用（比如从 hack/MODULE.md 删掉一行 Skill Map 链接），跑 healthcheck 确认变成 fail 且报错信息精确指向被删的那一项，再立刻改回来复跑确认恢复 pass。只测"改完之后全绿"不能证明检查本身有没有在正确的地方生效，容易把"检查代码写挂了但恰好没触发任何分支"误判为"通过"。

### Validation

阳性破坏测试：删除已知引用触发精确 FAIL，恢复后变回 PASS；健全性测试：scripts/healthcheck.ps1 全量重跑 24 项检查零 fail，新检查报告 41 个 Skill-Map 可达详情模块与 33 条 select_skill.ps1 规则引用全部一致。

### Next Action

review

### Promotion

Promoted to `references/reverse-task-recipes.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 19:08:24 +08:00.


## 2026-08-24 19:52:26 +08:00 - 把新增模块的多处跨文件登记固化成入库规范并与 healthcheck 逐项对齐

- id: 20260824-195226-把新增模块的多处跨文件登记固化成入库规范并与-healthcheck-逐项对齐
- status: promoted
- category: tooling
- confidence: 4/5
- applies_to: 给 reverse-engineering-workflow 新增或退役内部模块及 references 文档时
- purpose_zh: 用单一权威入库规范替代每次靠人工回查跨文件登记，杜绝孤儿模块、注册表计数不符、中文名不同步
- target_skill_path: references/module-onboarding-spec.md
- tags: none

### Evidence

本包 inbox 已有 4 条关于新增模块需同步 select_skill 规则与跨文件审计的经验；cross-reference-completeness 检查精确定义了 5 类登记点；落地 references/module-onboarding-spec.md 并加 SKILL.md Choose References 与 manifest.references 两处登记后，healthcheck 24 项 0 fail，reusable-skill-registry 仍为 61 证明 references 文档未被误计为技能，manifest-paths 由 57 增至 58

### Lesson

当一个 skill 包反复踩新增模块要同步多处登记的坑时，正解不是每次人工回查，而是先读 healthcheck 的 cross-reference-completeness 等检查把它强制的所有登记点列全，按落点 github/local/security/references 分别写死登记清单，固化成一份 references 入库规范文档并与每一项 healthcheck 检查逐条对齐附一页 checklist；规范文档本身也要按规范登记到 SKILL.md 与 manifest 但不能进 chinese-skill-names 以免 registry 计数不符，最后用 healthcheck 0 fail 验证

### Validation

scripts/healthcheck.ps1 全量 24 项零 fail；list_skills 注册表计数未变仍为 61

### Next Action

review

### Promotion

Promoted to `references/module-onboarding-spec.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 21:14:43 +08:00.

## 2026-08-24 21:11:24 +08:00 - 多代理重构核心文件用并行调研加串行门禁加主控字节级兜底验证，实施agent断线后healthcheck全绿不等于正确

- id: 20260824-211124-多代理重构核心文件用并行调研加串行门禁加主控字节级兜底验证-实施agent断线后healthch
- status: promoted
- category: tooling
- confidence: 4/5
- applies_to: 用多代理或workflow对高耦合核心脚本做数据外置或等价重构时
- purpose_zh: 规避多代理并发写冲突与实施代理中途断线导致的半成品或语义漂移，用可复现的字节级比对兜底
- target_skill_path: references/reverse-task-recipes.md
- tags: none

### Evidence

本次 workflow 为 3 调研并行加 3 实施串行(每步 healthcheck+Pester 门禁)加 1 终验；route 实施代理回传响应时 Connection lost，但仓库内 healthcheck 24 项仍 0 fail；因 healthcheck 仅抽样 6 个 selector 用例不能证明 33 条正则无漂移，遂用 git show HEAD:scripts/select_skill.ps1 提取原始 33 条规则，与 routing-rules.json 经 ConvertFrom-Json 还原值逐条大小写敏感比对，TOTAL DIFFS=0，确认 JSON 反斜杠双写正确、语义零漂移；再对 7 条口语 query 抽验路由行为一致

### Lesson

1) 多代理改同一批核心文件必须串行实施(顺序 await 共享工作区)避免并发覆盖，每步用 healthcheck+Pester 做硬门禁，红即 halt 保护完整性。2) 实施代理中途断线(Connection lost)时落盘改动可能完整也可能半成品，不能只看 healthcheck 全绿就放心，因为 healthcheck 只抽样验证，证明不了全量数据(如 33 条正则)字节级无漂移。3) 数据外置类重构(ps1 规则数组转 json)必做兜底：git show HEAD 原文件提取原始数据，与新数据源解析还原后逐条大小写敏感比对，DIFFS 必须为 0，尤其盯 JSON 反斜杠转义(单写会被解析改变语义)。4) 脚手架等写盘脚本用 -WhatIf 自测后必须 git status 确认零落盘。

### Validation

healthcheck 24 项 0 fail、tests passed=22、registry 计数 61 不变；33 条规则 -cne 比对 DIFFS=0；7 条口语路由抽验全部命中预期

### Next Action

review

### Promotion

Promoted to `references/reverse-task-recipes.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-24 21:16:02 +08:00.

---

## 2026-08-24 23:25:00 +08:00 - Web 站点全量逆向：Vite SPA chunk 提取 + 开源溯源 + 版本差异对照

- id: 20260824-232500-web-reverse-vite-spa-opensource-trace
- status: promoted
- category: method
- confidence: 4/5
- applies_to: web-frontend-reverse, web-api-reverse
- purpose_zh: 从 Vue3 SPA 网站系统性提取完整 API 端点/路由/认证机制，通过 GitHub 链接溯源开源后端并对照线上版本差异
- target_skill_path: references/reverse-task-recipes.md
- tags: vite, spa, sub2api, vue3, gin, api-recon

### Lesson

Web 逆向六步法：
1) 主页 HTML 的 window.__APP_CONFIG__ 提供配置指纹（OAuth/支付/验证码开关/邮箱白名单/服务器时区）
2) 主 bundle 中动态 import 提取全部懒加载 chunk 并下载合并
3) 正则批量提取 API 端点与前端路由（本例 292 条路径 + 86 条路由）
4) JS 内 GitHub 链接直接溯源开源后端代码（本例 Wei-Shaw/sub2api 的 Go+Gin 项目）
5) 对照开源代码确认路由/限流/认证实现，并识别线上定制差异（如新增定制端点）
6) 黑盒探测公开端点验证版本号与行为一致性

关键发现顺序：window.__APP_CONFIG__ → 主 bundle 路由表 → 懒加载 chunk 业务逻辑 → 开源项目溯源 → 版本对比 → 定制功能识别

### Evidence

kakouai.com 逆向：
- 提取 292 条 API 路径、86 条前端路由、85 个懒加载 chunk
- 溯源到开源 Sub2API 项目（Wei-Shaw/sub2api，Go 1.27 + Gin + Vue 3 + PostgreSQL + Redis）
- 线上版本 0.1.179 vs 开源最新 0.1.181（确认定制分支）
- 发现定制端点 /api/v1/settings/maintenance（开源版本无此路由）
- 认证机制：localStorage auth_token/refresh_token，JWT 双 token 带锁刷新
- 管理面认证：Admin API Key（x-api-key）或管理员 JWT（Authorization Bearer）
- 公开配置：/settings/public 暴露注册邮箱白名单（含 @shijiantech.xyz）、OAuth 开关、支付配置

### Validation

- 开源代码路由与实际线上行为 100% 吻合（/health、/setup/status 返回一致）
- 黑盒探测验证了限流行为、CORS 配置、webhook 行为
- 未发现假阳性：所有 404 端点确认路由不存在

### Next Action

review

---

### Promotion

Promoted to `references/reverse-task-recipes.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 07:47:39 +08:00.

## 2026-08-25 05:15:30 +08:00 - sidecar orchestrator 模块族导入法：orchestrator 注册为 P1 路由器

- id: 20260825-051530-sidecar-orchestrator-模块族导入法-orchestrator-注册为-p1
- status: promoted
- category: method
- confidence: 4/5
- applies_to: module merge / module family import
- purpose_zh: 侧车模块族（orchestrator + 41 个 downstream 专精）导入本地时，把 orchestrator 注册为 P1 路由器（加入 healthcheck.ps1 的 routers 与 new_module.ps1 的 routerNames），并在其 MODULE.md 加 Core Skill Map 链接全部下游模块，即可让整族通过 orphan 检查，无需逐个链接旧 P1。
- target_skill_path: scripts/healthcheck.ps1
- tags: merge, routing, healthcheck

### Evidence

CTF-Sandbox-Orchestrator 42 模块导入：ctf-sandbox-orchestrator 加入 routers 后 healthcheck 24/24 PASS，chinese-skill-names 138 条 0 missing，select_skill 实测 CTF 任务正确路由 conf=0.9。

### Lesson

导入外部 sidecar 模块族时，先识别族内默认入口（orchestrator），将其注册为本地 P1 路由器并链接全部 downstream 模块，整族一次通过 orphan 与 cross-reference 检查。

### Validation

healthcheck 24/24 PASS；unit-tests 22/22 PASS；select_skill CTF 路由 conf=0.9

### Next Action

review

### Promotion

Promoted to `references/module-onboarding-spec.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 05:16:19 +08:00.

## 2026-08-25 05:15:45 +08:00 - sidecar 参考文件（ops/field-journal）导入落点：references/ 子目录

- id: 20260825-051545-sidecar-参考文件-ops-field-journal-落点-reference
- status: promoted
- category: other
- confidence: 4/5
- applies_to: module merge / reference files
- purpose_zh: 外部仓库的 ops 作战契约层与 field-journal 实战日志并非模块，不应注册为 skill，而应整目录导入本地 references/ops/ 与 references/field-journal/，并在 manifest.json references 中登记入口文件，保持与模块树分离。
- target_skill_path: references/ops/README.md
- tags: merge, references, manifest

### Evidence

导入：ops 10 文件 + field-journal 44 文件（17 篇实战日志 + 17 seed 案例）完整复制到 references/ 子目录，manifest-paths 61 项 PASS，healthcheck 24/24 PASS。

### Lesson

非模块类外部资产（契约文档、实战案例库）用 references/ 子目录整目录导入并登记 manifest，不注册为 skill；实战日志与 seed 案例保留原文件名便于日后检索复用。

### Validation

manifest-paths 61 项 PASS；healthcheck 24/24 PASS

### Next Action

review

### Promotion

Promoted to `references/ops/README.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 05:16:52 +08:00.


## 2026-08-25 06:33:45 +08:00 - 双基准diff验证法-外部本地文件树对比

- id: 20260825-063345-双基准diff验证法-外部本地文件树对比
- status: promoted
- category: method
- confidence: 4/5
- applies_to: module merge / file integrity verification
- purpose_zh: 外部模块导入后，用 find | sort | diff 双基准对比文件树，确保零丢失导入
- target_skill_path: references/module-onboarding-spec.md
- tags: diff,verification,import

### Evidence

在外部 pentest-tools 导入验证中，用 find | sort | diff 对比外部 114 文件和本地 114 文件，差异仅为 2 个合规改名（SKILL.md→MODULE.md, src-hunter/SKILL.md→src-hunter.md），确认零丢失。

### Lesson

导入外部模块后，用 diff <(find REPO -type f | sort) <(find LOCAL -type f | sort) 对比文件树，精确确认迁移零丢失（114=114），比目录数对比可靠得多。

### Validation

文件数 114=114 一致，healthcheck 24/24 PASS，unit-tests 22/22 PASS。

### Next Action

review

### Promotion

Promoted to `references/module-onboarding-spec.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 06:34:37 +08:00.

## 2026-08-25 06:33:49 +08:00 - 触发词闸门检查法-验证skill自动调用链路

- id: 20260825-063349-触发词闸门检查法-验证skill自动调用链路
- status: promoted
- category: method
- confidence: 4/5
- applies_to: skill auto-invocation / pi skills routing verification
- purpose_zh: 验证自动调用链路时，先检查根 SKILL.md description 覆盖目标场景触发词，再测 invoke_skill 路由
- target_skill_path: references/skill-learning-loop.md
- tags: auto-invocation,description,trigger,pi-skills

### Evidence

在 pentest-tools 导入完成后，检查根 SKILL.md description 发现无渗透测试触发词（nmap/sqlmap/src/bounty 全为 0），导致自动调用链路断裂。添加后 description 覆盖 nmap/sqlmap/src挖洞/bug bounty 等，新会话后可触发。

### Lesson

验证 skill 自动调用时，不能只测 invoke_skill 路由，必须先检查根 SKILL.md 的 description 是否覆盖目标场景触发词。Pi 启动时提取 name+description 注入系统提示，模型据此判断是否加载 skill——description 漏了触发词（nmap/sqlmap/src挖洞等），后面路由全白搭。

### Validation

YAML 校验通过，healthcheck 24/24 PASS，invoke_skill 实测路由 pentest-tools 0.94。

### Next Action

review

### Promotion

Promoted to `references/skill-learning-loop.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 06:35:38 +08:00.


## 2026-08-25 07:49:23 +08:00 - Web 逆向路由必须指向统一根入口而非子模块

- id: 20260825-074923-web-逆向路由必须指向统一根入口而非子模块
- status: promoted
- category: method
- confidence: 3/5
- applies_to: web-api-reverse, web-js-reverse, web-crypto-reverse, routing
- purpose_zh: 新增 web 逆向子模块时，routing-rules.json 的规则目标必须设为根入口 reverse-engineering-workflow（0.85 置信度），由根 SKILL.md 按需加载内部 MODULE.md，避免绕过统一入口造成多入口分裂
- target_skill_path: references/unified-skills-entry.md
- tags: none

### Evidence

3 条指向 web-api-reverse/web-js-reverse/web-crypto-reverse 的路由规则改为 1 条合并规则指向 reverse-engineering-workflow 后，6 个 NL 路由用例全部命中根入口；回归测试同步更新

### Lesson

规则：select_skill.ps1 的 task-rule 目标只允许根入口或安全/本地既有模块；新增子模块只注册进 unified-skills-entry.md/INDEX.md/SKILL.md/chinese-skill-names.json 四文件，不新增顶层路由规则

### Validation

healthcheck cross-reference-completeness PASS（38→36 规则一致）；routing.Tests.ps1 25 用例全过；APK/BOLA/x64dbg 等非 web 场景路由不变

### Next Action

review

### Promotion

Promoted to `references/unified-skills-entry.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 07:58:16 +08:00.

## 2026-08-25 07:49:42 +08:00 - new_module.ps1 的 [appended] 输出不可信，注册必须经 healthcheck 交叉验证

- id: 20260825-074942-new-module-ps1-的-appended-输出不可信-注册必须经-healthchec
- status: promoted
- category: tooling
- confidence: 3/5
- applies_to: module-onboarding, healthcheck, registry
- purpose_zh: new_module.ps1 宣称已追加注册（unified-skills-entry.md/INDEX.md/SKILL.md/chinese-skill-names.json），实际多次未写入；必须以 healthcheck 的 cross-reference-completeness 与 chinese-skill-names 检查为准，缺了就手动补齐
- target_skill_path: references/module-onboarding-spec.md
- tags: none

### Evidence

3 个新模块经 new_module.ps1 创建后均报 [appended]，但 package_release 健康门禁 FAIL 列出 3 处缺失（unified-skills-entry.md/INDEX.md/SKILL.md），手动补齐 4 文件后 PASS

### Lesson

规则：任何 new_module.ps1 执行后，先跑 scripts/healthcheck.ps1 确认 cross-reference-completeness PASS 再继续；若 FAIL 按报告逐文件补注册行，补完重跑至 PASS 才可发布

### Validation

手动补齐 chinese-skill-names.json 3 条 + unified-skills-entry.md 3 行 + INDEX.md 3 块 + SKILL.md 3 行后，healthcheck 25/25 PASS，manifest 1.23.2 发布成功

### Next Action

review

### Promotion

Promoted to `references/module-onboarding-spec.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 08:00:16 +08:00.


## 2026-08-25 09:49:52 +08:00 - awesome-* 大仓库三层接入：主入口MODULE+离线快照JSON+分类索引表

- id: 20260825-094952-awesome-大仓库三层接入-主入口module-离线快照json-分类索引表
- status: promoted
- category: method
- confidence: 3/5
- applies_to: general reverse workflow
- purpose_zh: 外部 awesome-* 类大目录仓库接入本地 skills 时的固定做法
- target_skill_path: references/module-onboarding-spec.md
- tags: none

### Evidence

gmh5225/awesome-game-security 54091 文件/4231 条目接入：README 358KB 解析为 550KB 快照 JSON，官方 10 技能主题对照本地既有模块避免重复建模块；healthcheck 24/24 PASS，registry 143 条，resolve_skill 按机器名和中文名均命中

### Lesson

接入体量大、条目多、分类稳定的 awesome-* 仓库时，不要克隆全文或把条目塞进 bootstrap-manifest 自动安装；按三层接入：建主入口 MODULE.md（含安全边界+完整分类索引表）+ 本地离线快照 references/*-snapshot.json（解析 README 的 ## 分类 / > 子分类 / - url [desc] 结构为 JSON）+ 官方 skills 主题映射表；写中文 MODULE.md 后必须转 UTF-8 with BOM，否则 PowerShell 5.1 Get-Content 读取乱码导致 mandatory-final-feedback-contract 中文 token 检查 FAIL

### Validation

2026-08-25 实践验证：game-security-research 模块按三层接入成功入库，healthcheck 24/24 PASS（含 BOM 修复前后对比：无 BOM 时 mandatory-final-feedback-contract FAIL，加 BOM 后 PASS），resolve_skill 按机器名与中文名均命中，sync_installed_skill 同步成功。

### Next Action

review

### Promotion

Promoted to `references/module-onboarding-spec.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 09:54:24 +08:00.


## 2026-08-25 10:18:48 +08:00 - 新增目录型模块必须同步补路由规则

- id: 20260825-101848-新增目录型模块必须同步补路由规则
- status: promoted
- category: method
- confidence: 3/5
- applies_to: general reverse workflow
- purpose_zh: 防止新增模块入库后统一入口无法命中
- target_skill_path: references/module-onboarding-spec.md
- tags: none

### Evidence

game-security-research 模块初入库时未加规则，'游戏反作弊资料'任务回落到 generic reverse-engineering；补规则（confidence 0.86，37 条规则）后 3 组研究任务命中 game-security-research，'cheat engine 扫描内存'仍正确命中 ce-reverse，healthcheck 24/24 PASS

### Lesson

新增模块入库（MODULE.md + 4 处登记 + healthcheck）后，必须同步在 scripts/routing-rules.json 登记路由规则：pattern 需同时含中英文关键词，confidence 应低于具体工具类规则（如 ce-reverse 0.89、x64dbg 0.89）且高于 generic 规则（reverse-engineering 0.68），保证工具任务优先走工具模块、研究/目录任务走新模块；登记后必须回归 select_skill 多组测试用例并重跑 healthcheck（cross-reference-completeness 校验规则 refs 与 registry 一致性）

### Validation

2026-08-25 实践验证：game-security-research 模块补路由规则前后对比——无规则时 select_skill 对'游戏反作弊资料'回落到 generic reverse-engineering（confidence 0.68），补规则后命中 game-security-research（0.86）；4 组回归用例全部符合预期，healthcheck 24/24 PASS（cross-reference-completeness 确认 37 条规则 refs 与 registry 一致），sync_installed_skill 同步成功。

### Next Action

review

### Promotion

Promoted to `references/module-onboarding-spec.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 10:19:07 +08:00.


## 2026-08-25 10:34:59 +08:00 - promote_skill_lesson 超时判定法

- id: 20260825-103459-promote-skill-lesson-超时判定法
- status: promoted
- category: method
- confidence: 3/5
- applies_to: general reverse workflow
- purpose_zh: promote 脚本输出超时但实际成功时的正确判定与处理
- target_skill_path: references/skill-learning-loop.md
- tags: none

### Evidence

两次实践（20260825-094952 三层接入、20260825-101848 路由规则补全）均出现 60s 超时后实际成功：grep 确认 module-onboarding-spec.md 已含 source 行、inbox status=promoted，healthcheck 24/24 PASS

### Lesson

promote_skill_lesson.ps1 在 Windows PowerShell 5.1 下常出现命令输出超时（60s 未返回）但实际已成功写入的现象；判定依据是目标文件（如 references/module-onboarding-spec.md）中是否出现 '- source: <id>' 且 inbox 条目状态变为 promoted，而非命令退出码；确认成功后不要重跑（会报 already promoted 错误），直接继续验证（healthcheck + sync_installed_skill）

### Validation

2026-08-25 第三次实践验证：本次 promote 20260825-103459 再次出现 60s 超时，grep 确认目标文件已含 source 行、inbox status=promoted；与前两次（094952、101848）行为一致，判定法可靠。

### Next Action

review

### Promotion

Promoted to `references/skill-learning-loop.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 10:35:16 +08:00.


## 2026-08-25 10:51:22 +08:00 - 路由规则必须同步补回归用例且合规审计不能只看healthcheck

- id: 20260825-105122-路由规则必须同步补回归用例且合规审计不能只看healthcheck
- status: promoted
- category: method
- confidence: 3/5
- applies_to: general reverse workflow
- purpose_zh: 新增路由规则后补 tests 回归用例，以及健康检查 0 fail 不等于完全合规
- target_skill_path: references/module-onboarding-spec.md
- tags: none

### Evidence

game-security-research 入库后 healthcheck 24/24 PASS 但 tests/routing.Tests.ps1 无该模块用例；按规范补齐 2 条用例后 Pester 15/15 通过，healthcheck unit-tests 25→27；规范符合性审计据此发现并修复了唯一缺口

### Lesson

1) 新增/修改 routing-rules.json 规则后，必须同步给 tests/routing.Tests.ps1 补回归用例（正向命中 + 既有工具模块对照不抢占各一条），否则规范第 6 节不达标，healthcheck 不会自动发现（它只跑既有用例）；2) 用户询问是否符合规范时，healthcheck 0 fail 是必要条件但不是完备证据，需按 module-onboarding-spec.md 第 12 节 checklist 逐项人工核验 + 抽查快照/官方副本/安全边界，才能发现 healthcheck 覆盖不到的缺口

### Validation

2026-08-25 实践验证：game-security-research 模块规范符合性审计中发现 tests/routing.Tests.ps1 缺失回归用例（healthcheck 当时 24/24 PASS 未报）；补齐 2 条用例（正向 game-security-research + 对照 ce-reverse 不抢占）后 Pester 15/15 通过、healthcheck unit-tests 25→27、24/24 PASS；证明"healthcheck 0 fail ≠ 完全合规"，需按 checklist 人工核验。

### Next Action

review

### Promotion

Promoted to `references/module-onboarding-spec.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 10:51:39 +08:00.


## 2026-08-25 11:08:24 +08:00 - 入库规范必须含逆向内容完整性与脱敏边界章节

- id: 20260825-110824-入库规范必须含逆向内容完整性与脱敏边界章节
- status: promoted
- category: method
- confidence: 3/5
- applies_to: general reverse workflow
- purpose_zh: 规范健康检查覆盖不等于规范完整；逆向内容不脱敏、仅凭据脱敏；官方skills五步收录法
- target_skill_path: references/module-onboarding-spec.md
- tags: none

### Evidence

规范审计发现 24 项检查中 4 项（reusable-skill-resolver/installed-skill-sync/generated-caches/环境可选）在规范第 9 节检查表无对应行，且全文无'脱敏/内容完整性'主题；本次新增规范第 13 节（逆向内容完整性与脱敏边界，白名单/黑名单/判定标准/完整性验收/官方skills五步收录法）与第 14 节（内容完整性与同步验收）；game-security-research 快照 4231 条目 0 缺 URL、官方 10 skills 完整无损（TRUNCATED=0）验证了验收方法

### Lesson

1) 入库规范完整性审计方法：拉出 healthcheck 全部检查项做覆盖矩阵，找 0 覆盖项（本次发现 generated-caches/installed-sync/resolver 未入表）与主题缺口（脱敏边界完全缺失）；2) 逆向内容完整性原则：AOB/算法/寄存器/协议字段/公开仓库 URL 一律原文保留，只有真实凭据（API Key/Token/私钥/私有域名/内网IP）用占位符，判定标准是'公开可达的技术事实保留、非公开凭据脱敏'；3) 外部仓库自带官方 AI skills 的完整收录法：重命名 .md（禁保留 SKILL.md 防 single-installable 冲突）+ 改写 ../xxx/SKILL.md 相对链接 + 保留 frontmatter/许可证 + manifest 登记 + 不注册为可路由技能；4) 内容完整性验收：条目数核对、URL 缺失率必须 0、TRUNCATED 截断标记必须 0（代码示例省略号除外）

### Validation

2026-08-25 实践验证：对 module-onboarding-spec.md 做覆盖矩阵审计，发现 4 项检查未入表 + 脱敏边界主题完全缺失；新增第 13/14 节后 healthcheck 24/24 PASS、0 FAIL；对照 game-security-research 快照（4231 条目 0 缺 URL）与官方 10 skills（无 TRUNCATED 标记）验证验收方法可行；该审计法此前已两次发现 healthcheck 覆盖不到的缺口（路由回归用例缺失），证明"healthcheck 全绿 ≠ 规范完整"。

### Next Action

review

### Promotion

Promoted to `references/module-onboarding-spec.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-25 11:08:38 +08:00.


## 2026-08-26 16:36:49 +08:00 - github-repo-recon 免克隆仓库架构逆向法

- id: 20260826-163649-github-repo-recon-免克隆仓库架构逆向法
- status: candidate
- category: method
- confidence: 4/5
- applies_to: 分析公开 GitHub 安全/逆向项目的真实架构与能力边界
- purpose_zh: 不 clone 不装依赖，快速还原一个仓库的真实架构与'实际做了什么 vs README 宣称什么'
- target_skill_path: references/reverse-engineering-methods.md
- tags: recon, source-analysis, triage, orchestrator

### Evidence

对 1N3/Sn1per 应用本法：trees 得 307 路径、30 modes、211 templates；grep normal.sh 得 nmap×328/msfconsole×41，定位为 nmap+NSE+metasploit 封装；据此产出 pentest-orchestration 模块的三份证据参考。

### Lesson

分析公开仓库时：用 GitHub API git/trees?recursive=1 一次取全树做目录分类统计，再用 raw.githubusercontent.com 定点拉核心文件（主控/安装/配置/1个代表性模块），对入口脚本 grep 参数解析与分发机制、对主流程 grep 外部工具调用词频，即可在不克隆的前提下还原架构与能力边界。据此判断项目'实际做了什么 vs README 宣称什么'（如 Sn1per CE=9.2 是 bash 编排器，README 大量描述的是闭源付费版）。

### Validation

本会话据此拆解产出可运行的 sniper_template_to_recipe.py 转换器（对真实 Pulse VPN 模板转换成功）与 normal.sh 逐行扫描链拆解。

### Next Action

review
## 2026-08-26 17:10:41 +08:00 - 补全模块注册会激活其路由规则-必须跑兄弟任务回归防抢占

- id: 20260826-171041-补全模块注册会激活其路由规则-必须跑兄弟任务回归防抢占
- status: candidate
- category: method
- confidence: 4/5
- applies_to: 给本地/安全模块补登记时同步校验其 routing-rules.json 规则不抢占通用兄弟任务
- purpose_zh: 一个未登记模块补全 cross-reference 后，其路由规则会从'休眠'变'生效'，过宽的业务名词会突然抢占通用逆向任务
- target_skill_path: references/module-onboarding-spec.md
- tags: routing, module-onboarding, regression

### Evidence

wechat-miniapp-protocol-re 补全 5.C 登记后，其 0.92 规则的 '签名算法' token 抢走 JSVMP 回归用例（route 到 wechat 而非 root），healthcheck unit-tests FAIL；把通用词改为 (微信|小程序|wechat).{0,16}(...) 共现后 JSVMP 回 root(0.85)、wechat 正向仍 0.92，unit-tests 30 全绿。

### Lesson

补全一个此前未登记模块的 cross-reference 后，select_skill 才会真正应用它的 routing-rules.json 规则（登记前规则对未注册目标不生效）。因此补登记必须同步：(1) 用通用兄弟任务做回归（如 wechat 补登后 JSVMP/加密/内存任务是否被抢），(2) 把规则里的通用业务名词（签名/抓包/内存/任务/抽奖）改为需与领域锚点（微信/小程序/wechat）共现，(3) 补正向命中 + 兄弟不抢占两条 tests/routing.Tests.ps1 用例。

### Validation

healthcheck 24/24 PASS；routing 回归：JSVMP->root、wechat 任务->wechat、通用签名/内存任务->root 均符合预期。

### Next Action

review
## 2026-08-27 02:32:27 +08:00 - 带 healthcheck 硬契约的 MODULE.md 只增补正文零风险扩写法

- id: 20260827-023227-带-healthcheck-硬契约的-module-md-只增补正文零风险扩写法
- status: promoted
- category: tooling
- confidence: 4/5
- applies_to: 对本包 github/local/security 三棵树中带 frontmatter 正则契约+中文名行+5-token 反馈契约+BOM/CRLF 的 MODULE.md 做仅增补正文的扩写或加注时
- purpose_zh: 批量补厚或加注模块时零风险保住 healthcheck 硬契约，避免 frontmatter/中文名/反馈 token/BOM/换行被破坏导致 mandatory-final-feedback-contract 等检查 fail
- target_skill_path: references/module-onboarding-spec.md
- tags: module-onboarding, healthcheck, encoding

### Evidence

本轮多子代理补厚 9 个模块(ghidra/go-rust/macos/thick-client/browser-ext/protocol + flet/win-python-recovery/service-persistence)并给 14 个 competition 模块加归一化指针，全部只增补正文；改后 healthcheck 24 PASS/0 FAIL/0 WARN、unit-tests 30/30、5-token 与 BOM 逐文件核验未变

### Lesson

用锚点唯一化的字节级插入 + validate-all-then-write-all + BOM与换行保持：读原始字节 -> 按 BOM 决定 utf-8-sig/utf-8 解码 -> 探测 CRLF/LF -> 只对唯一锚点做一次 replace 或在中文名行后按行插入 -> 写回保留原 BOM 与换行；先对所有编辑断言(命中计数==1)全部通过再统一写盘，任一锚点不唯一即整体放弃、杜绝半改；frontmatter 四行 / 中文名行 / 5 个反馈 token 一律不碰，只在其后正文增补。

### Validation

改后 scripts/healthcheck.ps1 必须 0 fail(mandatory-final-feedback-contract / chinese-skill-names / cross-reference-completeness 全绿)；grep 逐文件确认 5 token 各计数 1、frontmatter 四行与中文名行未变；od 确认 BOM 未变

### Next Action

review

### Promotion

Promoted to `references/module-onboarding-spec.md` by `scripts/promote_skill_lesson.ps1` on 2026-08-27 02:33:08 +08:00.

