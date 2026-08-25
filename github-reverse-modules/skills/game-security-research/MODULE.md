---
name: game-security-research
description: |
  游戏安全攻防研究目录模块（基于 gmh5225/awesome-game-security 全量快照）。当用户需要查询游戏破解/游戏外挂/反作弊（Anti-Cheat）/游戏内存修改/DMA 攻击/Overlay 绘制/W2S/Triggerbot/内核驱动保护（PatchGuard、DSE、HVCI）/易受攻击驱动（Vulnerable Driver）/游戏引擎（Unreal、Unity、Source）安全/移动端游戏安全（Frida、Magisk、Xposed、iOS jailbreak）/游戏专项逆向（CS、Fortnite、Valorant、LOL、PUBG、原神等）/主机模拟器安全研究资料、工具、教程与开源项目时使用，或用户提到 anti-cheat、game hacking、cheat engine 研究、EAC、BattlEye、Vanguard、FACEIT、BYOVD、DMA、RPM、W2S、speedhack、HWID、spoof、反作弊绕过研究时使用。

  This module provides a read-only curated directory of game security resources: offline snapshot (references/awesome-game-security-snapshot.json) with 4231 categorized entries across 36 top-level categories (Cheat 2770, Anti Cheat 714, Game Engine 181, Game Develop 188, plus Windows kernel, emulators, graphics APIs), the online awesome-game-security taxonomy, and the official 10 skill topics (anti-cheat-systems, dma-attack-techniques, game-hacking-techniques, graphics-api-hooking, mobile-security, windows-kernel-security, reverse-engineering-tools, game-engine-resources, research-rigor, awesome-game-security-overview). Use it to discover tools, methodologies, academic material, and open-source projects for authorized game security research, anti-cheat analysis, and defensive assessment. It is a read-only index — do NOT auto-install the listed meta-installers or download tools from it into bootstrap manifests.
---

中文名：suimi游戏安全研究
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# 游戏安全攻防研究目录

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到
`reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，
明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用
`record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

## 模块性质与安全边界（必读）

本模块是对外部公开目录仓库 `awesome-game-security`（MIT，作者 gmh5225，3424+ stars，持续每日更新）的**只读本地快照与导航**，不是工具安装器。

- **只做目录记录与用法检索**：模块不自动下载、不执行任何列出的仓库/工具，也不把任何 meta-installer（含外挂框架、C2/RAT/钓鱼套件嫌疑项目）写入 `bootstrap-manifest.json` 或任何自动安装清单。
- **授权前提**：仅用于本地/沙箱/自有资产或明确授权的安全研究、反作弊防御评估、恶意软件与作弊样本分析、教学目的。
- **攻防双面内容并存**：Cheat 分类记录的是"作弊如何实现"的攻击视角，Anti Cheat 分类记录"如何检测与防御"。读取攻击视角资料的目的应是理解威胁模型、研究检测对抗、完成授权评估，而非在真实线上游戏中使用。
- **证据等级**：条目描述是第三方仓库自述，不是安全结论；引用前按 evidence 优先级（运行时/流量 > 源码 > 注释）自行验证。
- **外部依赖不稳定**：快照中的 GitHub 链接可能失效或仓库被删除；离线优先用本地快照检索，在线访问失败时回退到本地条目描述。

## 三层接入结构

按模块入库规范，本模块对 awesome-* 类大型目录采用"三层接入"：

1. **主入口**：本 `MODULE.md`（含完整分类索引表 + 使用指引 + 安全边界）。
2. **本地全量快照**：`references/awesome-game-security-snapshot.json` —— 4231 条目的结构化分类快照（36 个顶层分类，每个条目含 url + desc），离线可查，无需访问外网。
3. **官方技能完整副本**：`references/official-skills/` —— 上游官方 10 个 AI Agent skill 的本地全文（见下文"官方 10 技能完整收录"），离线可读，无需在线安装。

## 何时触发本模块

用户提及以下任一方向且目标是**资料/工具/教程/项目发现**时优先路由到本模块：

- 游戏破解 / 游戏外挂 / game hacking / cheat engine 研究（内存修改、注入、Hook、SpeedHack、Triggerbot、Aimbot、ESP、WallHack、W2S、Overlay、Render/Draw）
- 反作弊 / anti-cheat / AC 分析（EAC、BattlEye、Vanguard、FACEIT、VAC、Ricochet、XignCode、ACE、Byfron、EQU8、EasyAntiCheat、检测与绕过）
- 内核与驱动（PatchGuard、DSE、HVCI、PiDDBCache、MmUnloadedDrivers、EPROCESS/MMVAD、Ring0/Ring3 回调、驱动通信、易受攻击驱动 BYOVD、EFI 驱动、内核漏洞）
- DMA / FPGA / IOMMU / 硬件内存访问
- 游戏引擎安全（Unreal、Unity、Source、Godot 引擎内部、SDK 生成、引擎保护）
- 游戏专项逆向（CS:GO/CS2、Fortnite、Valorant、LOL、PUBG、Apex、Rust、原神、WOW、Dota2、Elden Ring、GTA5 等 130+ 游戏条目）
- 移动游戏安全（Android root/Magisk/Zygisk、Frida、Xposed、ART Hook、内核驱动、模拟器检测；iOS jailbreak、内存/文件/网络）
- 图形 API 拦截（DirectX、OpenGL、Vulkan hook、Present Hook、Draw Call Hook、截图）
- 模拟器与平台（WSL、WSA、Android/iOS/Windows/Linux 模拟器、Game Boy/Nintendo/Xbox/PlayStation 模拟器）
- 防作弊对抗专项（Anti Debugging、Anti Disassembly、混淆引擎、壳、VMProtect/Themida/OLLVM、Dump Fix、签名扫描、行为遥测）

工具操作类任务（真正要跑 CE/x64dbg/Frida/IDA）不走本模块，而走对应模块：`ce-reverse`、`x64dbg-reverse`、`apk-reverse`、`mobile-reverse`、`ida-reverse`、`ghidra-reverse`、`radare2`、`frida`（含在 mobile/apk 内）、`traffic-capture`、`malware-analysis`、`firmware-pentest`、`edr-bypass-re`、`pwn-chain`。

## 完整分类索引表（36 顶层分类，4231 条目）

> 以下数字为快照生成时的条目数；明细见 `references/awesome-game-security-snapshot.json` 的 `categories` 字段（category_order / category_stats / total_entries 供程序化消费）。

### 攻防核心：Cheat（2770 条）

| 子分类 | 条数 | 说明 |
|---|---|---|
| Guide | 63 | 游戏破解入门教程合集（game-hacking、game-reversing、Hypervisor-From-Scratch 等） |
| Debugging | 71 | 调试方法论与调试器资料 |
| RE Tools | 126 | 逆向工具集 |
| Packet Sniffer&Filter / Packet Capture&Parse | 9 | 游戏流量抓包/过滤/解析 |
| SpeedHack | 3 | 变速器实现 |
| Mixed boolean-arithmetic | 15 | MBA 混合布尔算术混淆 |
| Fix VMP / Fix Themida / Fix OLLVM | 37 | 商业壳/混淆还原 |
| Dynamic Binary Instrumentation | 24 | DBI（Frida/Intel PT 等） |
| PatchGuard-related | 18 | PatchGuard 相关研究与绕过 |
| Driver Signature enforcement | 6 | 驱动签名强制（DSE） |
| Windows Kernel Explorer | 97 | 内核探索工具与资料 |
| Linux Kernel Explorer | 4 | Linux 内核探索 |
| Magisk / Xposed / Frida | 76 | Android 注入三件套 |
| Hook ART / Hook syscall | 3 | ART 层与 syscall 层 Hook |
| Android 全系（Terminal/File/Memory/Network Explorer、CVE、Bootloader、Key Attestation、ROM、Device Trees、Kernel Source、Root、Kernel driver、IoT） | 164 | Android 生态安全研究与内核开发 |
| IOS jailbreak / Network / Memory / File / Packaging | 38 | iOS 越狱与内存/网络探索 |
| Virtual Environments | 6 | 虚拟环境 |
| Decompiler | 24 | 反编译器 |
| IDA themes / Plugins / Signature Database | 225 | IDA 生态 |
| Binary Ninja Plugins | 40 | Binary Ninja 生态 |
| Ghidra Plugins | 48 | Ghidra 生态 |
| Radare / Windbg / X64DBG Plugins | 55 | 其余调试器插件 |
| Cheat Engine Plugins | 16 | CE 插件 |
| Injection:Windows / Linux / Android / IOS / PlayStation | 63 | 跨平台注入技术 |
| DLL Hijack | 9 | DLL 劫持 |
| Hook | 30 | Hook 技术 |
| ROP Finder / ROP Generation | 7 | ROP 工具 |
| RPM | 32 | 远程进程内存读写 |
| DMA | 45 | PCIe DMA / FPGA 硬件访问 |
| W2S | 1 | World-to-Screen |
| Overlay / Render/Draw / UI Interface | 68 | 绘制与界面 |
| Vulnerable Driver | 139 | 易受攻击驱动（BYOVD 研究） |
| Driver Communication | 63 | 驱动通信 |
| EFI Driver | 37 | EFI 驱动开发 |
| QEMU/KVM/PVE/VBOX | 41 | 虚拟化平台 |
| Wine | 5 | Wine 兼容层 |
| Anti Screenshot | 5 | 防截图 |
| Spoof Stack / Hide / Anti Forensics | 66 | 反取证与隐藏 |
| Triggerbot & Aimbot | 40 | 自瞄/扳机辅助 |
| WallHack | 1 | 透视 |
| HWID | 39 | 硬件指纹 |
| SDK CodeGen | 3 | SDK 代码生成 |
| Game Engine Explorer:Unreal / Unity / Source | 101 | 引擎内部结构探索 |
| Explore UWP | 3 | UWP 应用 |
| Explore AntiCheat System:VAC/EAC/BE/EQU8/Ricochet/RIOT/XignCode/ACE/G-Presto/NeacSafe/BadlionAnticheat/Byfron/FACEIT/CS2 | 119 | 各反作弊系统逆向研究 |
| Game:（130+ 游戏专项） | ~860 | 按游戏分类的逆向资源（CSGO 87、CS2 70、Fortnite 66、Valorant 38、Apex 37、LOL 29、Rust 25、PUBG 12、GTA5 13、原神 19、EldenRing 3 等） |

### 攻防核心：Anti Cheat（714 条）

| 子分类 | 条数 | 说明 |
|---|---|---|
| Guide | 20 | 反作弊架构研究指南 |
| Stress Testing | 21 | 反作弊压力测试 |
| Driver Unit Test Framework | 1 | 驱动单测框架 |
| Anti Debugging | 20 | 反调试 |
| Page Protection | 16 | 页保护 |
| Binary Packer / CLR Protection / Anti Disassembly / Sample Unpacker / Dump Fix | 47 | 加壳与反反编译 |
| Encrypt Variable / Lazy Importer / Compile Time | 6 | 编译期混淆 |
| Anti-Cheat Programming | 11 | 反作弊程序设计 |
| Shellcode Engine & Tricks | 18 | Shellcode 引擎 |
| Obfuscation Engine | 47 | 混淆引擎 |
| Screenshot | 3 | 截图检测 |
| Game Engine Protection:Unreal / Unity / Source | 14 | 引擎级保护 |
| Open Source Anti Cheat System | 48 | 开源反作弊系统 |
| Analysis Framework | 8 | 分析框架 |
| Detection:（Hook/Memory Integrity/ShellCode/Attach/Triggerbot&Aimbot/Hide/Vulnerable Driver/Hacked Hypervisor/Virtual Environments/HWID/SpeedHack/Injection/Spoof Stack/ESP/DMA/Wall Hack/Obfuscation/Android root/Magisk/Frida/Overlay） | 64 | 21 类检测技术 |
| Signature Scanning | 4 | 特征码扫描 |
| Information System & Forensics | 16 | 取证与信息收集 |
| Dynamic Script | 2 | 动态脚本 |
| Kernel Mode Winsock | 1 | 内核态 Winsock |
| Fuzzer | 4 | 模糊测试 |
| Windows Ring3/Ring0 Callback | 24 | 回调机制 |
| User/Kernel Dump Analysis | 3 | 转储分析 |
| Sign Tools / Black Signature / Backup | 12 | 签名工具与备份 |
| Windows Ring0 | 14 | Ring0 开发 |

### 引擎/渲染/开发（Game Engine 181、Game Develop 188、DirectX 40、Renderer 18、Vulkan 11、Game Network 28 等）

Unreal/Unity/Source/Godot/自研引擎源码与插件、DirectX/OpenGL/Vulkan 资料、游戏网络协议、PhysX、数学库、游戏资源/热补丁/测试/工具/CI。

### 平台与安全特性

Windows Security Features（10）、WSL（4）、WSA（9）、Windows/Linux/Android/iOS 模拟器（20）、主机模拟器（Game Boy 4、GameCube/Wii 1、Nintendo 3DS 3、Switch 8、Xbox 8、PlayStation 7）、Some Tricks（130，含 Ring0/Ring3/Linux 技巧）。

## 官方 10 技能完整收录（本地离线副本）

上游仓库为 AI Agent 提供了 10 个官方 skill 主题（`.claude/skills/`），本模块已**完整下载并本地收录**于 `references/official-skills/`（MIT 许可，来源标注于各文件 frontmatter 与文首；保留原名内容，仅将跨文件相对链接改写为本地可达）。**无需再 `npx skills add` 在线安装**，离线即可阅读全文。

| 上游官方 skill（本地文件） | 上游覆盖分类 | 本地对应/互补模块 |
|---|---|---|
| `official-skills/anti-cheat-systems.md`（40KB） | Anti Cheat 全系 + Detection:* + 各 AC 系统（EAC/BattlEye/Vanguard/FACEIT） | 本模块 Anti Cheat 索引；深挖用 `malware-analysis` 方法 |
| `official-skills/dma-attack-techniques.md`（71KB） | Cheat > DMA / RPM / Vulnerable Driver / IOMMU / FPGA / 设备模拟 | 本模块 DMA/驱动索引；实际内存操作用 `ce-reverse` |
| `official-skills/game-hacking-techniques.md`（28KB） | Cheat 全系攻击面威胁模型（注入/Overlay/输入模拟/引擎攻击面） | 本模块 Cheat 索引 + 各游戏专项 |
| `official-skills/graphics-api-hooking.md`（15KB） | DirectX/OpenGL/Vulkan hook、Overlay、Present/Draw Call Hook、截图 | 本模块图形索引；实践参考 `ce-reverse`（注入 Hook 思路） |
| `official-skills/mobile-security.md`（16KB） | Android/iOS 逆向、Frida/Zygisk/Magisk、越狱/root 绕过、模拟器检测 | 本模块移动子分类；工具实操走 `mobile-reverse` / `apk-reverse` |
| `official-skills/windows-kernel-security.md`（41KB） | EPROCESS/ETHREAD/MMVAD、IOCTL、DSE、PatchGuard、HVCI、PiDDBCache | 本模块内核索引；实践走 `edr-bypass-re` / `malware-analysis` |
| `official-skills/reverse-engineering-tools.md`（18KB） | 调试器、转储分析、反分析 | 本模块 RE Tools/Decompiler/插件索引；实操走 `ida-reverse` / `ghidra-reverse` / `x64dbg-reverse` / `radare2` |
| `official-skills/game-engine-resources.md`（10KB） | Unreal/Unity/Source/Godot 引擎内部 | 本模块 Game Engine 索引 |
| `official-skills/research-rigor.md`（8KB） | 研究严谨性方法论（把威胁模型当版本化示例而非事实） | 本模块"安全边界"段已内化该原则；本文为其权威全文 |
| `official-skills/awesome-game-security-overview.md`（11KB） | 仓库分类法/导航/贡献 | 本模块索引表即其导航等价物 |

> 收录说明：各文件保留了上游 `name:`/`description:` frontmatter 供检索，但它们是**参考文档**不是可路由技能（不参与 `chinese-skill-names.json` 注册、不被 select_skill 路由）；阅读时优先以本 `MODULE.md` 的索引表定位，再进对应官方文档看深度内容。

## 使用方法

1. **查分类**：看上方"完整分类索引表"，确定目标子分类。
2. **查明细**：读 `references/awesome-game-security-snapshot.json`，取 `categories["<顶层分类>"]["<子分类>"]` 数组（每项 `{"url": "...", "desc": "..."}`），或按 `category_stats` / `total_entries` 程序化统计。
3. **检索**：对快照做关键字过滤（如"kernel""overlay""BattlEye"），得到候选项目列表。
4. **验证**：对候选项目，按授权前提评估用途；需要实际分析工具时切换到对应工具模块。
5. **更新快照**：快照是固定生成物；如需刷新，重新拉取上游 README（`https://raw.githubusercontent.com/gmh5225/awesome-game-security/main/README.md`）并按下述解析规则重建（分类 `## `，子分类 `> `，条目 `- url [desc]`），生成后保持 `references/awesome-game-security-snapshot.json` 路径不变。

## 与其他模块的边界

- 本模块是**目录/导航**：回答"有什么资料/项目/方法可查"。
- 工具模块是**执行**：回答"怎么对目标跑 CE/x64dbg/Frida/IDA"。
- 若用户已明确要操作某个工具，直接路由工具模块，不要把本模块当工具手册。

## 已知限制

- 条目数为快照时点数据，上游持续增长（Cheat 分类日均新增）；离线快照滞后于线上。
- 部分条目链接已失效（上游 README 自述"失效可把用户名替换为 gmh5225"或发 issue）。
- 分类粒度不均：Cheat 下既有 130+ 游戏专项，也有单条子分类；检索时注意同义关键词（如 anti-cheat / anticheat / AC）。

## 新技能/方法反馈

任务结束时按根 `SKILL.md` 的强制反馈契约执行：用 `finish_skill_run.ps1` 生成反馈，候选经验用 `record_skill_lesson.ps1` 入池，`review_skill_lessons.ps1` 审查，`promote_skill_lesson.ps1` 晋级到最窄的既有模块或本模块 references。
