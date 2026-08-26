---
name: cybersecurity-projects-catalog
description: >-
  网络安全 / 逆向工程「可运行项目」教学目录模块（基于 CarterPerez-dev/Cybersecurity-Projects 全量静态快照）。当用户需要查询、参考、对照学习成体系的安全/逆向开源项目实现时使用：42 个已建成项目（目标 70）、四层难度（foundations/beginner/intermediate/advanced）、20+ 语言（Go/Python/Rust/TypeScript/Zig/Crystal/Haskell/Ruby/C++/V/Nim）、368879 行代码 + 594192 词教学讲义。覆盖二进制静态分析（binary-analysis-tool：ELF/Mach-O/PE 解析 + 反汇编 + YARA）、在线逆向教学靶场（rveng：capstone + pyelftools + 真实 ELF 关卡）、模糊测试框架（zero-day-vulnerability-scanner / lisdex）、TLS 指纹（ja3-ja4）、SIEM/蜜罐/威胁检测、以及双用途攻防工具（c2-beacon、keylogger、deserialization-gadget-lab、credential-enumeration、systemd-persistence）。也用于用户提及 CarterPerez、certgames、cybersecurity projects、安全项目源码参考、安全学习路线、渗透/SOC/GRC 认证路线图（ROADMAPS）、安全项目蓝图规格（SYNOPSES）时。只读目录，不自动安装、不自动运行任何列出的工具；上游 AGPL-3.0，切勿把其代码抄进闭源/商业项目。
---

中文名：suimi网络安全项目目录
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# 网络安全 / 逆向工程可运行项目教学目录

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到
`reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，
明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用
`record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

## 模块性质与安全边界（必读）

本模块是对外部公开教育仓库 `CarterPerez-dev/Cybersecurity-Projects`（AGPL-3.0，6220+ stars，持续开发中）的**只读本地全量快照与导航**，不是工具安装器，也不是"抄代码"的捷径。

- **真实性质**：它表面是"70 个安全项目集"，实质是一个**教学内容工厂 + 课程导流漏斗**——用 42 个可运行的完整全栈项目当教材，配 594192 词（约 2000 页）的五段式讲义（`00-OVERVIEW/01-CONCEPTS/02-ARCHITECTURE/03-IMPLEMENTATION/04-CHALLENGES`），最终导流到作者自营的 `certgames.com` 付费/免费课程平台。代码是"看得见的成品"，讲义才是核心产品。
- **只做目录记录与对照学习**：模块不自动下载、不执行任何列出的项目，也不把任何项目写入 `bootstrap-manifest.json` 或任何自动安装清单。
- **授权前提**：仅用于本地/沙箱/自有资产或明确授权的安全研究、防御评估、教学与源码对照学习。
- **双用途内容并存**：目录内含功能完整的攻击性工具（见下方 ⚠️ 标记）——`c2-beacon`（10 个 MITRE ATT&CK 命令的 C2）、跨平台 `keylogger`（含 webhook 外传）、`deserialization-gadget-lab`、`credential-enumeration`、`systemd-persistence-scanner`。读取攻击视角资料的目的应是理解威胁模型、研究检测与防御、完成授权评估，而非在未授权系统上使用。
- **⚠️ 许可陷阱（务必转达用户）**：上游 README 写有 "use as a reference, or even **copy directly**"，但仓库许可是 **AGPL-3.0**（强 copyleft + 网络服务分发传染）。把其代码抄进闭源或商业项目是明确违约。**学结构、学方法，不要直接粘贴其代码**；商业使用须另行取得作者授权。
- **证据等级**：项目 README/讲义是作者自述，不是安全结论；引用前按 evidence 优先级（运行时/流量 > 源码 > 注释）自行验证。

## 三层接入结构

按模块入库规范，本模块对这类**体量大、条目多、有稳定分类字段**的外部目录仓库采用"三层接入"：

1. **主入口**：本 `MODULE.md`（含完整分类索引表 + 使用指引 + 安全边界）。
2. **本地全量快照**：`references/cybersecurity-projects-snapshot.json` —— 42 个项目的结构化快照（每条含 tier / project_number / title / 主语言 + 各语言 LOC / build_systems / learn_docs / learn_words / engineering_flags / dual_use / **github_url**），另含 65 篇蓝图规格（SYNOPSES）、10 条认证路线图、5 份资源指南、语言聚合与分层统计；离线可查，无需访问外网。
3. **无官方 AI Agent skills**：与 `game-security-research` 不同，本上游仓库**不自带** `.claude/skills/` 或 `SKILL.md` 官方 Agent 技能（它的"官方内容"是 216 篇 `learn/*.md` 教学文档，属教材而非可安装技能），故本模块不设 `references/official-skills/`。

## 量化画像（快照时点）

| 维度 | 实测值 |
|---|---|
| 已建成项目 / 目标 | **42 / 70**（README 徽标 `42/70` 自述一致） |
| 蓝图规格（SYNOPSES） | 65 篇（含 APT 模拟器、Exploit Dev Framework、Trojan Builder、Rootkit 检测等未建项） |
| 代码总量 | **368,879 行**（不含 md/json/yaml） |
| 教学讲义 | 216 篇 md / **594,192 词** |
| 语言数 | **19** 种：Go / Python / Rust / TypeScript / Zig / Shell / SCSS / Crystal / Haskell / Ruby / C++ / V / Nim / C / JS / Lua / SQL 等 |
| 分层代码量 | foundations 6,035 · beginner 85,224 · intermediate 102,427 · advanced 175,193 |
| 工程成色 | 几乎每个项目带 README + 测试 + Just/Make + 多数带 Docker；仓库级 67 hook pre-commit、945 行矩阵 CI、dependabot、Claude Code Action；全树占位符仅 1 TODO/1 FIXME |
| 认证路线图 / 资源 | 10 条 ROADMAPS（SOC/Pentester/Cloud/GRC…）+ 5 份 RESOURCES |
| 许可 / 导流 | AGPL-3.0 · homepage → certgames.com |

## 何时触发本模块

用户提及以下任一方向且目标是**项目发现 / 源码对照 / 实现参考 / 学习路线**时优先路由到本模块：

- 想找"某类安全/逆向功能的完整开源实现参考"（如 ELF/PE 解析器、反汇编器、模糊测试框架、TLS 指纹、SIEM、蜜罐、DLP、SBOM、密钥扫描器怎么写）
- 想按难度阶梯系统学习网络安全/安全工程编码（foundations → beginner → intermediate → advanced）
- 提到 `CarterPerez` / `Cybersecurity-Projects` / `certgames` / "70 个安全项目" / "gamified cybersecurity"
- 想参考多语言安全项目工程化实践（pre-commit 多语言 lint、矩阵 CI、Docker 化、justfile、测试布局）
- 查安全职业认证路线图（SOC Analyst / Pentester / Security Engineer / Cloud / GRC / Incident Responder / Threat Intel / AppSec / Network / Security Architect）
- 查安全项目蓝图/选题（SYNOPSES 里 65 个从入门到高级的项目设计规格）

**工具操作类任务不走本模块**：真正要对目标跑 IDA/Ghidra/x64dbg/CE/Frida、要解析某个具体 ELF/PE、要抓包、要打补丁时，走对应工具模块（见下方"与其他模块的边界"）。本模块只回答"有哪些实现/资料可参考、怎么定位"。

## 完整项目索引表（42 已建成项目，⚠️ = 双用途攻击性工具）

> 数据来自 `references/cybersecurity-projects-snapshot.json` 的 `projects` 字段；每条含完整 `languages`（各语言 LOC）、`learn_words`、`engineering_flags`、`github_url`，供程序化检索。

### Foundations（入门前 · 3） — 6035 LOC

| 项目 | 主语言 | 代码行 | 用途（上游一句话） |
|---|---|---:|---|
| `hash-identifier` | Python | 1198 | 按前缀/长度/字符集识别哈希算法——破解与取证的第一步。 |
| `http-headers-scanner` | Python | 1054 | 抓一次 URL，用 Mozilla Observatory 式加权评分给 HTTP 安全响应头打 A–F。 |
| `password-manager` | Python | 3783 | 加密命令行密码管理器——Argon2id 派生密钥、AES-256-GCM 认证加密。 |

### Beginner（初级 · 17） — 85224 LOC

| 项目 | 主语言 | 代码行 | 用途（上游一句话） |
|---|---|---:|---|
| `base64-tool` | Python | 1870 | 多格式编解码 CLI，带递归分层检测。 |
| `c2-beacon` ⚠️双用途 | Python | 4475 | C2 beacon + 服务端：XOR/Base64 WebSocket 协议，10 个 MITRE ATT&CK 命令，实时操作员面板。 |
| `caesar-cipher` | Python | 774 | 凯撒密码加解密 + 词频暴力破解 CLI。 |
| `canary-token-generator` ⚠️双用途 | Go | 23487 | 自托管蜜标生成器，7 类触发式陷阱工件（隐形网页信标、诱饵文档等）。 |
| `deserialization-gadget-lab` ⚠️双用途 | Ruby | 5655 | Ruby 对象反序列化安全实验室：只读 Marshal/YAML 字节不复活对象，教 gadget 链。 |
| `dns-lookup` | Python | 1551 | 专业 DNS 查询 CLI，Rich 输出 + 反向查询 + WHOIS。 |
| `firewall-rule-engine` | V | 4371 | 防火墙规则解析/冲突检测/优化/加固 ruleset 生成（iptables + nftables）。 |
| `hash-cracker` ⚠️双用途 | C++ | 2029 | 多线程哈希破解：字典 + 暴力 + 规则变异。 |
| `keylogger` ⚠️双用途 | Python | 1014 | 教学键盘记录器：输入捕获、窗口追踪、C2 投递技术演示（跨三平台 + webhook 外传）。 |
| `linux-cis-hardening-auditor` | Shell | 5779 | Linux CIS 基线合规审计，评分报告 + 基线对比 + 修复建议。 |
| `linux-ebpf-security-tracer` | Python | 2327 | eBPF 实时系统调用追踪，监控进程执行/文件访问等安全可观测性。 |
| `network-traffic-analyzer` | Python | 4407 | 同一网络流量分析器的 Python 与 C++ 双实现，内核级抓包 + 协议头解析 + 实时统计。 |
| `prompt-injection-firewall` ⚠️双用途 | Python | 8620 | 提示注入防火墙：不猜攻击者意图，改为对不可信内容强制结构化边界。 |
| `simple-port-scanner` | C++ | 242 | 基于 Boost.Asio 的异步 TCP 端口扫描器。 |
| `simple-vulnerability-scanner` | Go | 4412 | Go 写的 Python 依赖升级器 + 漏洞扫描器。 |
| `steganography-multi-tool` | Go | 9644 | 多格式隐写：把消息/文件封进口令加密载体。 |
| `systemd-persistence-scanner` ⚠️双用途 | Go | 4567 | Linux 持久化机制扫描器——单个二进制找出所有后门。 |

### Intermediate（中级 · 11） — 102427 LOC

| 项目 | 主语言 | 代码行 | 用途（上游一句话） |
|---|---|---:|---|
| `api-security-scanner` | Python | 6706 | 全栈 API 漏洞扫描器，覆盖 OWASP API Security Top 10。 |
| `binary-analysis-tool` | Rust | 12718 | 静态二进制分析引擎：多格式解析（ELF/Mach-O/PE）+ YARA + x86 反汇编 + MITRE ATT&CK 威胁标注。 |
| `credential-enumeration` ⚠️双用途 | Nim | 2676 | Linux 后渗透凭据暴露检测（Nim）。 |
| `credential-rotation-enforcer` | Crystal | 8899 | 凭据轮换强制器：追踪凭据、编译期校验策略。 |
| `dlp-scanner` | Python | 7887 | 面向文件/数据库/网络流量的数据防泄漏扫描。 |
| `docker-security-audit` | Go | 11561 | Docker 安全审计 CLI，对照 CIS Docker Benchmark v1.6.0 检查容器/镜像/Dockerfile。 |
| `ja3-ja4-tls-fingerprinting` | Rust | 16735 | 被动 TLS 指纹传感器（Rust），从抓包/网卡计算 JA3/JA4。 |
| `sbom-generator-vulnerability-matcher` | Go | 3810 | SBOM 生成 + 漏洞匹配，扫 Go/Node/Python，产出 SPDX 2.3。 |
| `secrets-scanner` | Go | 8704 | 代码库/git 仓库密钥扫描器（Go）。 |
| `security-news-scraper` | Go | 10427 | 无密钥安全新闻/CVE 情报引擎，聚合 RSS/Atom。 |
| `siem-dashboard` | Python | 12304 | 全栈 SIEM 面板，实时日志关联 + MITRE ATT&CK 攻击场景模拟引擎。 |

### Advanced（高级 · 11） — 175193 LOC

| 项目 | 主语言 | 代码行 | 用途（上游一句话） |
|---|---|---:|---|
| `ai-threat-detection` | Python | 13816 | AI 威胁检测：3 模型 ML 集成分析 nginx 访问日志分类攻击。 |
| `api-rate-limiter` | Python | 7044 | FastAPI 企业级限流（HTTP 420 Enhance Your Calm）。 |
| `bug-bounty-platform` | Python | 20506 | 生产级企业众测平台：RBAC + CVSS 评分 + 完整报告分诊。 |
| `encrypted-p2p-chat` | TypeScript | 13929 | 端到端加密 P2P 聊天，Signal 协议（Double Ratchet + X3DH）+ WebAuthn/Passkey。 |
| `haskell-reverse-proxy` | Haskell | 8461 | Haskell 高并发反向代理（上游标注 IN PROGRESS）。 |
| `honeypot-network` ⚠️双用途 | Go | 13576 | 多协议蜜罐网络，模拟 6 种真实服务、捕获攻击行为、映射 MITRE。 |
| `hsm-emulator` | Zig | 9706 | 软件硬件安全模块，编译成真实 Cryptoki（PKCS#11）共享库。 |
| `monitor-the-situation-dashboard` | Go | 30061 | 操作员级实时态势面板，11 路实时源（网络/世界/金融）。 |
| `rveng` | Python | 5403 | 交互式逆向学习平台：给你真实编译的二进制 + 具体问题 + 内建反汇编/CFG/Hex（capstone + pyelftools + FastAPI + React，含 6 个真实 ELF 关卡含 stripped）。 |
| `zero-day-vulnerability-scanner` | Rust | 42592 | 无密钥内存破坏扫描器（实为 lisdex，7-crate Rust 模糊测试工作区：语料/字典/最小化/符号化/覆盖/崩溃去重 + Mann-Whitney U 统计显著性判定）。 |
| `zig-stateless-scanner` | Zig | 10099 | masscan/zmap 血统的无状态线速 TCP/UDP 端口扫描器（Zig）。 |

## 对逆向工程师最有价值的项目（重点对照）

以下四个项目与本技能包的逆向主线直接相关，适合作为实现范本拆解（注意 AGPL 传染，学结构别抄贴）：

- **`advanced/rveng`**：ELF 解析 + capstone 反汇编 + CFG 可视化 + Hex 查看的完整 Web 逆向教学靶场，`challenges/*/target` 是 6 个真实编译的 x86-64 ELF（含 stripped 关卡）。可移植为自建逆向演示/教学靶场。对照本包 `ida-reverse` / `ghidra-reverse` / `radare2`。
- **`intermediate/binary-analysis-tool`**：ELF/Mach-O/PE **三格式统一解析** + 反汇编 + 熵分析 + 导入表 + 字符串 + YARA + 威胁评分的 Rust 分层设计（`passes/*.rs`）。对照本包 `go-rust-reverse` / `malware-analysis`。
- **`advanced/zero-day-vulnerability-scanner`（lisdex）**：模糊测试语料管理 + 崩溃去重 + 符号化 + Mann-Whitney U 统计显著性判定的工程范本，`stats.rs` 的统计学实现对齐 scipy/numpy 参考值。对照本包 `pwn-chain` / `patch-diff-exploit`。
- **`intermediate/ja3-ja4-tls-fingerprinting`**：被动 TLS 指纹（JA3/JA4）Rust 实现，对协议逆向/流量分析有参考价值。对照本包 `protocol-reverse` / `traffic-capture`。

## 使用方法

1. **查分层/项目**：看上方"完整项目索引表"，按难度层与用途定位候选项目。
2. **查明细**：读 `references/cybersecurity-projects-snapshot.json`，取 `projects` 数组按 `name` 过滤，得到该项目的 `languages`（各语言 LOC）、`build_systems`、`learn_words`、`engineering_flags`、`github_url`。
3. **看源码/讲义**：用 `github_url` 打开对应项目源码树；每个项目的 `learn/` 目录是五段式讲义（概念/架构/实现/挑战）。
4. **查蓝图选题**：读快照 `synopses_blueprints`（65 篇），获取从入门到高级的项目设计规格与未建选题。
5. **查认证路线**：读快照 `roadmaps`（10 条）与 `resource_guides`（5 份）。
6. **需要实操逆向**：切换到对应工具模块（见下）。
7. **更新快照**：快照是固定生成物；如需刷新，重新 `git clone https://github.com/CarterPerez-dev/Cybersecurity-Projects.git`，按每项目 LOC/语言/测试/构建/learn 词数重新测量后重建，保持 `references/cybersecurity-projects-snapshot.json` 路径不变。

## 与其他模块的边界

- 本模块是**目录/导航**：回答"有哪些安全/逆向项目实现、资料、学习路线可参考，在哪"。
- 工具模块是**执行**：回答"怎么对目标跑 IDA/Ghidra/x64dbg/CE/Frida、怎么解析这个 ELF/PE、怎么抓包/打补丁"。
- 逆向实操路由到：`ida-reverse`、`ghidra-reverse`、`radare2`、`x64dbg-reverse`、`ce-reverse`、`go-rust-reverse`、`malware-analysis`、`protocol-reverse`、`traffic-capture`、`pwn-chain`、`patch-diff-exploit`。
- 授权 Web/API/认证/注入安全评估路由到 `security-research-modules`（先 `hack`，再具体主题）。
- 若用户已明确要操作某个工具或分析某个具体目标，直接路由工具模块，不要把本模块当工具手册。

## 已知限制

- 项目数/LOC/词数为快照时点数据；上游持续开发（README 标注"Currently building: DDoS Mitigation Tool"），离线快照会滞后。
- 42 已建成 vs 70 目标 vs 65 蓝图：三者不完全一一对应（部分蓝图未建、部分已建项目无独立蓝图）；以快照 `projects`（已建）为准，`synopses_blueprints` 仅作选题参考。
- 双用途项目为"如何实现"的攻击视角；本模块仅记录用途与安全边界，不提供也不鼓励在未授权系统上使用。
- 上游 AGPL-3.0：源码可读可学，但**不可直接复制进闭源/商业项目**（README 的 "copy directly" 与许可冲突，以许可为准）。

## 新技能/方法反馈

任务结束时按根 `SKILL.md` 的强制反馈契约执行：用 `finish_skill_run.ps1` 生成 `新技能/方法反馈`，候选经验用 `record_skill_lesson.ps1` 入池，`review_skill_lessons.ps1` 审查，`promote_skill_lesson.ps1` 晋级到最窄的既有模块或本模块 references。
