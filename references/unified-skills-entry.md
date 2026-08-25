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
| suimi x64dbg 动态调试 | `github-reverse-modules/skills/x64dbg-reverse/MODULE.md` | suimi 支持的 x64dbg/MCP 运行时调试、断点/内存/寄存器观察、脱壳找 OEP |
| suimi Cheat Engine 逆向 | `github-reverse-modules/skills/ce-reverse/MODULE.md` | suimi 支持的 Cheat Engine/MCP 内存扫描、指针链追踪、函数 Hook、代码注入 |
| suimi抓包与流量分析 | `github-reverse-modules/skills/traffic-capture/MODULE.md` | suimi 支持的 tshark 接口级抓包（SSLKEYLOGFILE 解密）与 mitmproxy 中间人抓包，还原本地程序/移动端真实网络请求 |
| suimi .NET 逆向 | `github-reverse-modules/skills/dotnet-reverse/MODULE.md` | suimi 支持的 .NET/C# 程序集逆向，dnSpyEx + de4dot，NativeAOT，Sharp* 工具 |
| suimi JS 逆向 | `github-reverse-modules/skills/js-reverse/MODULE.md` | suimi 支持的 JS/Web 前端逆向，webpack/IIFE 去混淆，AST 重写，浏览器运行时捕获 |
| suimi Ghidra 逆向 | `github-reverse-modules/skills/ghidra-reverse/MODULE.md` | suimi 支持的 Ghidra 无头/脚本逆向工作流，反编译 API，Sleigh，插件 |
| suimi Go/Rust 逆向 | `github-reverse-modules/skills/go-rust-reverse/MODULE.md` | suimi 支持的 Go/Rust 二进制逆向，符号恢复，类型信息，string 恢复 |
| suimi 恶意软件分析 | `github-reverse-modules/skills/malware-analysis/MODULE.md` | suimi 支持的恶意软件分类、沙箱分析、脱壳、持久化、IOC 提取 |
| suimi 固件渗透 | `github-reverse-modules/skills/firmware-pentest/MODULE.md` | suimi 支持的固件提取、文件系统分析、启动加载器/安全启动审查、设备模拟 |
| suimi 协议逆向 | `github-reverse-modules/skills/protocol-reverse/MODULE.md` | suimi 支持的网络协议逆向、流量重放、字段映射 |
| suimi 厚客户端逆向 | `github-reverse-modules/skills/thick-client/MODULE.md` | suimi 支持的厚客户端（桌面应用）逆向，API 拦截、进程内存、配置提取 |
| suimi 补丁差异利用 | `github-reverse-modules/skills/patch-diff-exploit/MODULE.md` | suimi 支持的补丁差异分析定位已修复漏洞 |
| suimi 漏洞利用链 | `github-reverse-modules/skills/pwn-chain/MODULE.md` | suimi 支持的利用链组装、缓解绕过（ASLR/DEP/CFG） |
| suimi EDR 绕过逆向 | `github-reverse-modules/skills/edr-bypass-re/MODULE.md` | suimi 支持的 EDR/AV 规避、API unhooking、syscall 分析 |
| suimi macOS 逆向 | `github-reverse-modules/skills/macos-reverse/MODULE.md` | suimi 支持的 macOS/iOS 二进制逆向，Mach-O、OC 运行时、entitlements |
| suimi 浏览器扩展逆向 | `github-reverse-modules/skills/browser-extension-reverse/MODULE.md` | suimi 支持的浏览器扩展逆向，CRX 解包、manifest/权限分析 |
| suimi DSL 自定义虚拟机逆向 | `github-reverse-modules/skills/reverse-engineering/dsl-vm-reverse/MODULE.md` | suimi 支持的 JS 自定义 DSL/VM 逆向，opcode 调度表、字节码语义恢复 |
| suimi Web 后端 API 逆向 | `github-reverse-modules/skills/web-api-reverse/MODULE.md` | suimi 支持的从网络请求/HAR/cURL 逆向内部 API 协议，REST/GraphQL/batchexecute/gRPC-web 多协议检测、认证检测、生成 Python httpx / TypeScript 客户端 + API 文档 |
| suimi Web 前端 JS 逆向 | `github-reverse-modules/skills/web-js-reverse/MODULE.md` | suimi 支持的 JS 混淆分级与还原、JSVMP 五步逆向法、CDP 检测绕过、TLS/HTTP2/QUIC 指纹、环境修补、WASM 逆向、反爬分层击破 |
| suimi Web/APK 加密算法逆向 | `github-reverse-modules/skills/web-crypto-reverse/MODULE.md` | suimi 支持的从 Web JS 与 Android APK 识别并 Python 重构加密/签名算法，30 个 specialist 索引、Web2/Web3 判定、线上验证闭环 |
| suimi游戏安全研究 | `github-reverse-modules/skills/game-security-research/MODULE.md` | suimi 支持的游戏安全攻防目录检索：游戏破解/外挂（Cheat）、反作弊（EAC/BattlEye/Vanguard）、DMA/RPM、易受攻击驱动、内核保护（PatchGuard/DSE）、引擎安全、移动游戏安全、图形 API Hook、模拟器；含 4231 条目离线快照与官方 10 技能对照 |

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
| suimi OSINT 侦察工具库 | `security-research-modules/skills/osint-recon/MODULE.md` |
| suimi常见服务未授权访问 | `security-research-modules/skills/unauthorized-access-common-services/MODULE.md` |
| suimi 攻击链 | `security-research-modules/skills/attack-chain/MODULE.md` |
| suimi 浏览器自动化 | `security-research-modules/skills/browser-automation/MODULE.md` |
| suimi 案例审查 | `security-research-modules/skills/case-review/MODULE.md` |
| suimi 云与K8s安全 | `security-research-modules/skills/cloud-k8s/MODULE.md` |
| suimi 代码审计 | `security-research-modules/skills/code-audit/MODULE.md` |
| suimi CTF沙箱 | `security-research-modules/skills/ctf-sandbox/MODULE.md` |
| suimi 数据库安全 | `security-research-modules/skills/database-security/MODULE.md` |
| suimi 图表生成 | `security-research-modules/skills/diagram-generator/MODULE.md` |
| suimi 数字取证 | `security-research-modules/skills/digital-forensics/MODULE.md` |
| suimi 文档生成 | `security-research-modules/skills/docs-generator/MODULE.md` |
| suimi 邮件安全 | `security-research-modules/skills/email-security/MODULE.md` |
| suimi 硬件安全 | `security-research-modules/skills/hardware-security/MODULE.md` |
| suimi 身份联合 | `security-research-modules/skills/identity-federation/MODULE.md` |
| suimi LLM安全 | `security-research-modules/skills/llm-security/MODULE.md` |
| suimi OT/ICS安全 | `security-research-modules/skills/ot-ics/MODULE.md` |
| suimi 无线电SDR | `security-research-modules/skills/radio-sdr/MODULE.md` |
| suimi 供应链安全 | `security-research-modules/skills/supply-chain-security/MODULE.md` |
| suimi 威胁狩猎 | `security-research-modules/skills/threat-hunting/MODULE.md` |
| suimi 威胁情报 | `security-research-modules/skills/threat-intelligence/MODULE.md` |
| suimi WiFi无线安全 | `security-research-modules/skills/wifi-wireless/MODULE.md` |
| suimi Windows AD安全 | `security-research-modules/skills/windows-ad/MODULE.md` |
| suimi 渗透测试工具链 | `security-research-modules/skills/pentest-tools/MODULE.md` |
| suimi AD证书滥用比赛 | `security-research-modules/skills/competition-ad-certificate-abuse/MODULE.md` |
| suimi Agent云环境比赛 | `security-research-modules/skills/competition-agent-cloud/MODULE.md` |
| suimi Android Hook比赛 | `security-research-modules/skills/competition-android-hooking/MODULE.md` |
| suimi 浏览器持久化比赛 | `security-research-modules/skills/competition-browser-persistence/MODULE.md` |
| suimi 前端Sourcemap恢复比赛 | `security-research-modules/skills/competition-bundle-sourcemap-recovery/MODULE.md` |
| suimi 云元数据路径比赛 | `security-research-modules/skills/competition-cloud-metadata-path/MODULE.md` |
| suimi 容器运行时比赛 | `security-research-modules/skills/competition-container-runtime/MODULE.md` |
| suimi 移动端密码学比赛 | `security-research-modules/skills/competition-crypto-mobile/MODULE.md` |
| suimi 自定义协议重放比赛 | `security-research-modules/skills/competition-custom-protocol-replay/MODULE.md` |
| suimi DPAPI凭据链比赛 | `security-research-modules/skills/competition-dpapi-credential-chain/MODULE.md` |
| suimi 文件解析链比赛 | `security-research-modules/skills/competition-file-parser-chain/MODULE.md` |
| suimi 固件布局比赛 | `security-research-modules/skills/competition-firmware-layout/MODULE.md` |
| suimi 取证时间线比赛 | `security-research-modules/skills/competition-forensic-timeline/MODULE.md` |
| suimi GraphQL/RPC漂移比赛 | `security-research-modules/skills/competition-graphql-rpc-drift/MODULE.md` |
| suimi Windows身份比赛 | `security-research-modules/skills/competition-identity-windows/MODULE.md` |
| suimi iOS运行时比赛 | `security-research-modules/skills/competition-ios-runtime/MODULE.md` |
| suimi JWT声明混淆比赛 | `security-research-modules/skills/competition-jwt-claim-confusion/MODULE.md` |
| suimi K8s控制面比赛 | `security-research-modules/skills/competition-k8s-control-plane/MODULE.md` |
| suimi Kerberos委派比赛 | `security-research-modules/skills/competition-kerberos-delegation/MODULE.md` |
| suimi 内核容器逃逸比赛 | `security-research-modules/skills/competition-kernel-container-escape/MODULE.md` |
| suimi Linux凭据跳板比赛 | `security-research-modules/skills/competition-linux-credential-pivot/MODULE.md` |
| suimi LSASS票据材料比赛 | `security-research-modules/skills/competition-lsass-ticket-material/MODULE.md` |
| suimi 邮箱滥用比赛 | `security-research-modules/skills/competition-mailbox-abuse/MODULE.md` |
| suimi 恶意软件配置比赛 | `security-research-modules/skills/competition-malware-config/MODULE.md` |
| suimi OAuth/OIDC链比赛 | `security-research-modules/skills/competition-oauth-oidc-chain/MODULE.md` |
| suimi PCAP协议比赛 | `security-research-modules/skills/competition-pcap-protocol/MODULE.md` |
| suimi Prompt注入比赛 | `security-research-modules/skills/competition-prompt-injection/MODULE.md` |
| suimi 队列/Worker漂移比赛 | `security-research-modules/skills/competition-queue-worker-drift/MODULE.md` |
| suimi 竞态条件比赛 | `security-research-modules/skills/competition-race-condition-state-drift/MODULE.md` |
| suimi 中继强制链比赛 | `security-research-modules/skills/competition-relay-coercion-chain/MODULE.md` |
| suimi 请求归一化走私比赛 | `security-research-modules/skills/competition-request-normalization-smuggling/MODULE.md` |
| suimi 逆向Pwn比赛 | `security-research-modules/skills/competition-reverse-pwn/MODULE.md` |
| suimi 运行时路由比赛 | `security-research-modules/skills/competition-runtime-routing/MODULE.md` |
| suimi SSRF元数据跳板比赛 | `security-research-modules/skills/competition-ssrf-metadata-pivot/MODULE.md` |
| suimi 隐写媒体比赛 | `security-research-modules/skills/competition-stego-media/MODULE.md` |
| suimi 供应链比赛 | `security-research-modules/skills/competition-supply-chain/MODULE.md` |
| suimi 模板渲染路径比赛 | `security-research-modules/skills/competition-template-render-path/MODULE.md` |
| suimi Web运行时比赛 | `security-research-modules/skills/competition-web-runtime/MODULE.md` |
| suimi WebSocket运行时比赛 | `security-research-modules/skills/competition-websocket-runtime/MODULE.md` |
| suimi Windows跳板比赛 | `security-research-modules/skills/competition-windows-pivot/MODULE.md` |
| suimi ZIP归档比赛 | `security-research-modules/skills/competition-zip-archive/MODULE.md` |
| suimi CTF沙箱协调器 | `security-research-modules/skills/ctf-sandbox-orchestrator/MODULE.md` |

## 推荐加载顺序

1. 不确定任务类型：先读 `SKILL.md`，再读本文件。
2. 需要快速执行路线：读“suimi逆向任务配方”，先跑健康检查或入口路由脚本。
3. 需要给其他 Agent 或脚本集成：读“suimi可复用调用契约”，优先使用 JSON 输出脚本。
4. 任务结束或出现新思路：读“suimi技能学习闭环”，先写入候选池，再按验证结果晋级。
5. 逆向发现接口、后台、认证或上传下载面：加载“suimi安全研究总入口”。
6. 已明确漏洞类型或逆向子方向：直接加载上表对应专题技能。

## Promoted Learning Notes

### Web 逆向路由必须指向统一根入口而非子模块

- source: `20260825-074923-web-逆向路由必须指向统一根入口而非子模块`
- category: method
- applies_to: web-api-reverse, web-js-reverse, web-crypto-reverse, routing
- purpose_zh: 新增 web 逆向子模块时，routing-rules.json 的规则目标必须设为根入口 reverse-engineering-workflow（0.85 置信度），由根 SKILL.md 按需加载内部 MODULE.md，避免绕过统一入口造成多入口分裂
- confidence: 3/5

**Lesson**

规则：select_skill.ps1 的 task-rule 目标只允许根入口或安全/本地既有模块；新增子模块只注册进 unified-skills-entry.md/INDEX.md/SKILL.md/chinese-skill-names.json 四文件，不新增顶层路由规则

**Evidence**

3 条指向 web-api-reverse/web-js-reverse/web-crypto-reverse 的路由规则改为 1 条合并规则指向 reverse-engineering-workflow 后，6 个 NL 路由用例全部命中根入口；回归测试同步更新

**Validation**

healthcheck cross-reference-completeness PASS（38→36 规则一致）；routing.Tests.ps1 25 用例全过；APK/BOLA/x64dbg 等非 web 场景路由不变