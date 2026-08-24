---
name: web-js-reverse
description: 浏览器端 JS 逆向与反爬对抗技能。JS 混淆分级与还原（字符串加密、控制流平坦化、JSVMP 五步逆向法）、反爬检测绕过（CDP 检测、TLS/HTTP2/QUIC 指纹、浏览器指纹）、环境修补（Node 运行浏览器 JS、BOM/DOM 伪造）、WASM 逆向、验证码方案、多层保护逐层击破。当用户需要分析目标网站 JS 加密算法、还原请求签名、破解 JSVMP、绕过反爬检测、在 Node 中运行网页 JS 时使用。纯后端 API 逆向（无 JS 保护）请路由到 web-api-reverse。
---


中文名：suimi Web 前端 JS 逆向

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# suimi Web 前端 JS 逆向

> 面向「浏览器端 JS 保护」的逆向：JS 混淆/JSVMP/CDP 检测/TLS 指纹/环境修补/WASM。与 `web-api-reverse`（纯后端 API 逆向，无 JS 保护）互补。纯后端 API 逆向请路由到 `web-api-reverse`。

## 与相邻模块的边界

| 场景 | 用哪个模块 |
|------|-----------|
| 目标有 JS 混淆/JSVMP/CDP 检测/TLS 指纹/反爬保护 | **本模块（web-js-reverse）** |
| 纯后端 API 逆向（无 JS 保护，直接 curl 就能调） | `web-api-reverse` |
| 目标是识别加密算法并 Python 重构签名 | `web-crypto-reverse` |
| 只是抓包取证 | `traffic-capture` |

## 触发场景

- 网站使用 JS 混淆（变量名混淆、字符串加密、控制流平坦化、JSVMP），需要还原算法逻辑
- 遭遇 Cloudflare / DataDome / 瑞数 / 极验等反爬系统，需要绕过检测
- 请求带签名参数（`X-Sign`、`__zse_ck`、`X-Bogus` 等），需要复现签名生成
- 浏览器自动化脚本被识别为 Bot，需要绕过 CDP 检测 / 指纹检测
- 遭遇 TLS 指纹（JA3/JA4）/ HTTP2 SETTINGS / QUIC 传输参数检测
- 需要在 Node.js 中运行浏览器端 JS 代码，伪造 BOM/DOM 环境
- 滑块验证码 / 点选 / reCAPTCHA / Turnstile 等验证码的自动化方案
- 多重保护（Cloudflare + JSVMP + CDP + TLS 指纹）逐层击破

## 反爬技术全景：四层攻击面模型

| 层级 | 检测技术 | 对抗策略 | 工具链 |
|------|---------|---------|--------|
| 请求层 | IP 信誉评分、请求频率异常、Header 一致性校验 | 代理池轮换、请求间隔随机化、Header 模板化 | curl_cffi, httpx, requests |
| 协议层 | TLS 指纹(JA3/JA4)、HTTP/2 SETTINGS 帧指纹、QUIC 传输参数 | TLS 模拟、HTTP/2 参数伪造 | curl_cffi, tls-client, h2 |
| 浏览器层 | JS 环境检测、Canvas/WebGL/Audio 指纹、CDP 协议泄露 | 反检测浏览器、环境修补、CDP 隐藏 | nodriver, patchright, camoufox |
| 引擎层 | JSVMP 字节码 VM、WASM 保护、自定义 IR 混淆 | VM 执行追踪、操作码还原、WASM 反编译 | Chrome DevTools, Ghidra, Proxy Hook |

## 主流反爬技术分类（按难度）

| 类别 | 技术 | 难度 |
|------|------|------|
| JS 混淆 L1 | 变量名混淆（_0x1a2b3c） | ★☆☆☆☆ |
| JS 混淆 L2 | 字符串加密（数组+解密函数+旋转器） | ★★☆☆☆ |
| JS 混淆 L3 | 控制流平坦化（switch-case 状态机） | ★★★☆☆ |
| JS 混淆 L4 | 死代码注入+自我防御（debugger 陷阱+反格式化） | ★★★★☆ |
| JS 混淆 L5 | JSVMP 字节码 VM（自定义 VM 执行字节码） | ★★★★★ |
| 浏览器指纹 | Canvas/WebGL/AudioContext/字体枚举/屏幕属性 | ★★~★★★☆ |
| CDP 检测 | Runtime.enable 泄露 / sourceURL 注入 / navigator.webdriver 等 12 项 | ★★★~★★★★☆ |
| TLS 指纹 | JA3/JA4 握手指纹 / HTTP/2 SETTINGS / QUIC 传输参数 | ★★★~★★★★☆ |
| 行为分析 | 鼠标轨迹 / 键盘节奏 / 请求时序 / 页面交互序列 | ★★~★★★☆ |
| 验证码 | 滑块 / 点选 / reCAPTCHA v2/v3 / Turnstile / 极验 | ★★★~★★★★☆ |
| WAF | Cloudflare / DataDome / 瑞数 / 数美 | ★★★~★★★★★ |

## 系统化分析流程

### 10 分钟快速反爬类型判定

| Step | 动作 | 观察 |
|------|------|------|
| 1（2min） | curl 直接请求 | 正常返回→无 JS 保护；403/空响应→有 TLS/IP 或 JS 检测；返回 HTML 无数据→需执行 JS |
| 2（3min） | 浏览器 DevTools Network | 是否 challenge 页面？cookie 名特征（`__cf_bm`、`$_ts`）？JS 混淆程度？ |
| 3（3min） | 检查关键请求参数 | 是否有签名参数（sign/token/X-Bogus）？每次变化？Header 有自定义加密字段？ |
| 4（2min） | 判定路径 | L1 用 curl_cffi；L2 环境修补；L3 nodriver；L4 VM 追踪；L5 分层击破 |

### 六步法

```
侦察 → 识别 → 定位 → 分析 → 还原 → 验证
```

1. **侦察**：DevTools Network 抓包，记录请求序列、Header、Cookie、响应状态码。
2. **识别**：判定反爬类型（参考分类表）、保护厂商、保护等级。
3. **定位**：找到关键 JS 文件/函数、签名参数生成点、检测代码。
4. **分析**：AST 反混淆、动态调试 trace、VM 操作码分析、算法逻辑提取。
5. **还原**：用 Python/JS/Node.js 复现算法；伪造浏览器环境。
6. **验证**：批量测试签名正确性，100 次连续请求成功率≥95%。

### 对抗策略决策矩阵

| 目标反爬类型 | 首选策略 | 备选策略 |
|-------------|---------|---------|
| 仅 IP 封禁 | 代理池+请求限速 | - |
| Header 校验 | curl 直接伪造 Header | - |
| TLS 指纹检测 | curl_cffi 模拟 Chrome | tls-client |
| 简单 JS 混淆 | AST 反混淆+环境修补 | webcrack 自动处理 |
| 重度 JS 混淆 | webcrack/js-deobfuscator+动态调试 | Chrome DevTools 条件断点 |
| JSVMP 保护 | Proxy Hook+执行追踪+操作码还原 | Chrome DevTools LogPoint |
| CDP 检测 | nodriver 直接 CDP 驱动 | rebrowser-patches |
| 行为分析 | 拟人轨迹+随机化 | 真实浏览器+人工辅助 |
| 验证码 | 专业打码平台+AI 分类 | 手动解决+逆向验证逻辑 |

## 详细参考文档

本模块携带以下 references（来源：kings0527/web-reverse-engineering-skill 的精选），按需加载：

| 参考文档 | 聚焦 |
|---------|------|
| `references/deobfuscation.md` | AST 反混淆、字符串解密、webcrack 自动化 |
| `references/jsvmp-reverse-methodology.md` | JSVMP 五步逆向法：VM 定位→操作码映射→执行追踪→还原→验证 |
| `references/jsvmp-architecture.md` | JSVMP 字节码 VM 架构：派发循环、操作码表、执行上下文 |
| `references/env-patching.md` | Node 中运行浏览器 JS：BOM/DOM 伪造、Proxy 监测法、检测点分类 |
| `references/cdp-bypass.md` | CDP 检测 12 项向量：Runtime.enable、sourceURL、navigator.webdriver 等 |
| `references/protocol-fingerprinting.md` | TLS JA3/JA4、HTTP/2 SETTINGS、QUIC 传输参数指纹与模拟 |
| `references/wasm-reverse.md` | WASM 逆向：wabt 反编译、Ghidra 分析、加密算法特征识别 |
| `references/crypto-identification.md` | 从 JS 中识别加密算法：Web Crypto API、CryptoJS、forge 等库特征 |
| `references/layered-protection-bypass.md` | 多层保护（Cloudflare+JSVMP+CDP+TLS）逐层击破决策矩阵 |
| `references/network-interception.md` | 请求拦截与修改：Proxy Hook、fetch/XHR 拦截、Cookie 跟踪 |
| `references/debugging-techniques.md` | Chrome DevTools 高级调试：条件断点、LogPoint、异步栈追踪 |
| `references/anti-crawler-maintenance.md` | 长期运维：版本追踪、快速反演、升级应对、成功率监控 |

## 工作流

1. 建立基线：目标 URL、保护类型判定、请求序列。
2. 分类目标混淆等级（L1-L5），选对应工具链。
3. 窄范围插桩：一次只定位一个签名参数/一个检测点。
4. 先回滚式探针验证假设（Proxy Hook/CDP 驱动），再落最小还原代码。
5. 端到端复验：独立运行还原代码，对比浏览器输出，100 次成功率≥95%。
6. 记录：保护类型、定位方法、还原代码、验证结果、版本号。

## 证据与回滚

- 记录命令、请求 URL/Header/Cookie 序列、签名参数生成过程、还原代码、验证结果。
- 保留原始 JS 文件、反混淆输出、还原代码、测试日志。
- 绝不绕过 Auth/Captcha/Rate-Limit 的合法边界；权限责任在用户侧。

## 参考

- 以上 `references/` 目录各文件（按需加载）。
- 纯后端 API 逆向（无 JS 保护）：`web-api-reverse`。
- 加密算法识别与 Python 重构：`web-crypto-reverse`。
- 统一技能目录与中文名映射见 `references/unified-skills-entry.md`。
- 通用可复用方法清单见 `references/reverse-engineering-methods.md`。