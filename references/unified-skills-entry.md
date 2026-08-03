# 统一 Skills 入口

这是本项目所有已集成内部模块的统一入口，由 suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持。机器可识别的目录名保持不变；中文名用于人读、检索和路由说明。对外只安装根目录 `SKILL.md` 这一个 skill；下面的 `MODULE.md` 均由根 skill 内部调用，不作为独立 skills 安装。

## 使用边界

- 只处理本地、沙箱、自有或明确授权的目标。
- 逆向工作优先从主技能开始，先做基线、分类、证据收集，再加载专题模块。
- Web/API/Auth 安全研究是可选扩展，只在逆向发现相关攻击面或任务明确要求时加载。
- 不使用外部 hook、上下文注入规则、本地权限配置或个人环境设置作为技能内容。

## 第一入口

优先加载根目录 `SKILL.md`，然后按下面的中文名选择内部模块。

| 中文名 | 机器名 / 路径 | 适用场景 |
|---|---|---|
| suimi逆向总入口 | `reverse-engineering-workflow` / `SKILL.md` | suimi 支持的本地授权逆向、PE/APK/ELF、运行时诊断、补丁、打包、WPeGPT/IDA 路由 |
| suimi统一技能目录 | `references/unified-skills-entry.md` | 查看所有技能中文名、路由关系和模块边界 |
| suimi逆向任务配方 | `references/reverse-task-recipes.md` | 命令优先的 PE/ELF、APK、GUI、网络认证、打包任务升级路线 |
| suimi可复用调用契约 | `references/reusable-invocation-contract.md` | 给 Agent、脚本、包装器使用的 JSON 调用字段、路由、解析、健康检查契约 |
| suimi技能学习闭环 | `references/skill-learning-loop.md` | 记录、审查、晋级逆向过程中发现的新方法和新思路 |
| suimi技能学习候选池 | `references/skill-learning-inbox.md` | 暂存带证据、等待审查和晋级的可复用经验 |
| suimi外部工具下载 | `references/external-tool-downloads.md` | 官方下载页、安装入口和工具链依赖说明 |

## 核心逆向技能

| 中文名 | 路径 | 适用场景 |
|---|---|---|
| suimi逆向方法全集 | `github-reverse-modules/skills/reverse-engineering/MODULE.md` | suimi 支持的通用逆向方法、语言平台、反分析、模式识别、较宽的参考材料 |
| suimi radare2 逆向 | `github-reverse-modules/skills/radare2/MODULE.md` | suimi 支持的 radare2 CLI 静态分析、快速侦察、命令行工作流 |
| suimi IDA 逆向 | `github-reverse-modules/skills/ida-reverse/MODULE.md` | suimi 支持的 IDA/MCP 打开目标、函数/交叉引用/伪代码分析 |
| suimi二进制 Diff | `github-reverse-modules/skills/binary-diff/MODULE.md` | suimi 支持的版本对比、符号迁移、补丁差异分析 |
| suimi APK 逆向 | `github-reverse-modules/skills/apk-reverse/MODULE.md` | suimi 支持的 APK 解包、manifest 汇总、Frida、重打包签名安装 |
| suimi移动端逆向 | `github-reverse-modules/skills/mobile-reverse/MODULE.md` | suimi 支持的 Android/iOS 移动端逆向方法论 |

## 本地逆向恢复技能

| 中文名 | 路径 | 适用场景 |
|---|---|---|
| suimi Flet 桌面诊断 | `local-reverse-modules/skills/flet-desktop-diagnostics/MODULE.md` | suimi 支持的 Flet 桌面 app.exe/flet.exe 进程关系、窗口响应、AppData、localhost 依赖和功能界面诊断 |
| suimi Windows Python 程序恢复 | `local-reverse-modules/skills/windows-python-app-recovery/MODULE.md` | suimi 支持的 Windows Python/Flet/Nuitka/PyInstaller 打包程序恢复、源码丢失后运行修复、AppData 状态恢复、本地服务和自启动验证 |
| suimi Windows 本地服务自启动 | `local-reverse-modules/skills/windows-local-service-persistence/MODULE.md` | suimi 支持的 127.0.0.1 本地辅助服务、Startup 启动项、计划任务 fallback、端口防重复和冷启动验证 |

## Web/API 安全研究路由技能

| 中文名 | 路径 | 适用场景 |
|---|---|---|
| suimi安全研究总入口 | `security-research-modules/skills/hack/MODULE.md` | Web/API/Auth 安全研究总路由 |
| suimi安全侦察路由 | `security-research-modules/skills/recon-for-sec/MODULE.md` | 授权范围、资产、端点、技术栈、测试路线 |
| suimi API 安全路由 | `security-research-modules/skills/api-sec/MODULE.md` | REST/GraphQL/API 鉴权、对象授权、Token、隐藏参数 |
| suimi认证安全路由 | `security-research-modules/skills/auth-sec/MODULE.md` | 登录、会话、JWT、OAuth/OIDC、SAML、MFA、CSRF、CORS |
| suimi注入检测路由 | `security-research-modules/skills/injection-checking/MODULE.md` | XSS、SQLi、SSRF、XXE、SSTI、CMDi、JNDI、NoSQL 等注入分类 |
| suimi文件访问路由 | `security-research-modules/skills/file-access-vuln/MODULE.md` | 上传、下载、路径穿越、LFI、源代码泄露 |
| suimi业务逻辑路由 | `security-research-modules/skills/business-logic-vuln/MODULE.md` | 支付、优惠券、库存、邀请、竞态、多步骤流程 |

## Web/API 安全研究专题技能

| 中文名 | 路径 |
|---|---|
| suimi API 侦察与文档分析 | `security-research-modules/skills/api-recon-and-docs/MODULE.md` |
| suimi API 授权与 BOLA | `security-research-modules/skills/api-authorization-and-bola/MODULE.md` |
| suimi API 认证与 JWT 滥用 | `security-research-modules/skills/api-auth-and-jwt-abuse/MODULE.md` |
| suimi GraphQL 与隐藏参数 | `security-research-modules/skills/graphql-and-hidden-parameters/MODULE.md` |
| suimi IDOR 对象授权 | `security-research-modules/skills/idor-broken-object-authorization/MODULE.md` |
| suimi JWT/OAuth Token 攻击 | `security-research-modules/skills/jwt-oauth-token-attacks/MODULE.md` |
| suimi OAuth/OIDC 配置审查 | `security-research-modules/skills/oauth-oidc-misconfiguration/MODULE.md` |
| suimi SAML/SSO 断言审查 | `security-research-modules/skills/saml-sso-assertion-attacks/MODULE.md` |
| suimi认证绕过审查 | `security-research-modules/skills/authbypass-authentication-flaws/MODULE.md` |
| suimi XSS 跨站脚本 | `security-research-modules/skills/xss-cross-site-scripting/MODULE.md` |
| suimi SQL 注入 | `security-research-modules/skills/sqli-sql-injection/MODULE.md` |
| suimi SSRF 服务端请求伪造 | `security-research-modules/skills/ssrf-server-side-request-forgery/MODULE.md` |
| suimi SSTI 模板注入 | `security-research-modules/skills/ssti-server-side-template-injection/MODULE.md` |
| suimi XXE XML 外部实体 | `security-research-modules/skills/xxe-xml-external-entity/MODULE.md` |
| suimi命令注入 | `security-research-modules/skills/cmdi-command-injection/MODULE.md` |
| suimi不安全反序列化 | `security-research-modules/skills/deserialization-insecure/MODULE.md` |
| suimi表达式语言注入 | `security-research-modules/skills/expression-language-injection/MODULE.md` |
| suimi JNDI 注入 | `security-research-modules/skills/jndi-injection/MODULE.md` |
| suimi原型污染 | `security-research-modules/skills/prototype-pollution/MODULE.md` |
| suimi请求走私 | `security-research-modules/skills/request-smuggling/MODULE.md` |
| suimi HTTP 参数污染 | `security-research-modules/skills/http-parameter-pollution/MODULE.md` |
| suimi PHP 类型混淆 | `security-research-modules/skills/type-juggling/MODULE.md` |
| suimi XSLT 注入 | `security-research-modules/skills/xslt-injection/MODULE.md` |
| suimi CRLF 注入 | `security-research-modules/skills/crlf-injection/MODULE.md` |
| suimi NoSQL 注入 | `security-research-modules/skills/nosql-injection/MODULE.md` |
| suimi路径穿越与 LFI | `security-research-modules/skills/path-traversal-lfi/MODULE.md` |
| suimi不安全文件上传 | `security-research-modules/skills/upload-insecure-files/MODULE.md` |
| suimi CSRF 跨站请求伪造 | `security-research-modules/skills/csrf-cross-site-request-forgery/MODULE.md` |
| suimi CORS 跨域配置审查 | `security-research-modules/skills/cors-cross-origin-misconfiguration/MODULE.md` |
| suimi开放重定向 | `security-research-modules/skills/open-redirect/MODULE.md` |
| suimi点击劫持 | `security-research-modules/skills/clickjacking/MODULE.md` |
| suimi Web 缓存欺骗 | `security-research-modules/skills/web-cache-deception/MODULE.md` |
| suimi WebSocket 安全 | `security-research-modules/skills/websocket-security/MODULE.md` |
| suimi业务逻辑漏洞 | `security-research-modules/skills/business-logic-vulnerabilities/MODULE.md` |
| suimi竞态条件 | `security-research-modules/skills/race-condition/MODULE.md` |
| suimi依赖混淆 | `security-research-modules/skills/dependency-confusion/MODULE.md` |
| suimi源码管理泄露 | `security-research-modules/skills/insecure-source-code-management/MODULE.md` |
| suimi CSV 公式注入 | `security-research-modules/skills/csv-formula-injection/MODULE.md` |
| suimi通用安全方法论 | `security-research-modules/skills/recon-and-methodology/MODULE.md` |
| suimi常见服务未授权访问 | `security-research-modules/skills/unauthorized-access-common-services/MODULE.md` |

## 推荐加载顺序

1. 不确定任务类型：先读 `SKILL.md`，再读本文件。
2. 需要快速执行路线：读“suimi逆向任务配方”，先跑健康检查或入口路由脚本。
3. 需要给其他 Agent 或脚本集成：读“suimi可复用调用契约”，优先使用 JSON 输出脚本。
4. 任务结束或出现新思路：读“suimi技能学习闭环”，先写入候选池，再按验证结果晋级。
5. 逆向发现接口、后台、认证或上传下载面：加载“suimi安全研究总入口”。
6. 已明确漏洞类型或逆向子方向：直接加载上表对应专题技能。
