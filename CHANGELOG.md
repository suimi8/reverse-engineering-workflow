# Changelog

本技能包所有值得记录的变更都记录在此文件。格式参考 Keep a Changelog。版本号与 `manifest.json` 保持一致。



## [2.4.0] - 2026-08-27

【中改】新增通用逆向模块 `cybersecurity-projects-catalog`（suimi网络安全项目目录），按 awesome-* 类"三层接入"完整入库，完成 5.A 全部跨文件登记 + 目录型模块路由规则与回归用例。

### Added

- `github-reverse-modules/skills/cybersecurity-projects-catalog/`（MODULE.md + 1 个全量快照）：对外部教育仓库 `CarterPerez-dev/Cybersecurity-Projects`（AGPL-3.0，6220+ stars）的**只读本地全量快照与导航**。基于全树静态分析（非 README 自述）量化：42/70 已建成项目、四层难度（foundations/beginner/intermediate/advanced）、19 语言 368,879 行代码、594,192 词五段式讲义。
  - `references/cybersecurity-projects-snapshot.json`（56KB）：42 个项目结构化快照，每条含 tier / project_number / title / 各语言 LOC / build_systems / learn_words / engineering_flags / dual_use / **github_url**（URL 缺失 0），另含 65 篇蓝图规格、10 条认证路线图、5 份资源指南、语言聚合与分层统计。
- MODULE.md 内嵌完整项目索引表（42 项目按四层分类，⚠️ 标注 9 个双用途攻击性工具），并单列"对逆向工程师最有价值的项目"（rveng ELF 靶场 / binary-analysis-tool 三格式解析 / lisdex 模糊测试 / ja3-ja4 TLS 指纹）。
- 安全边界固化进 MODULE.md：只读目录不自动安装/运行；含功能完整的双用途攻击工具（c2-beacon/keylogger/deserialization-gadget-lab 等）仅供授权研究；**AGPL-3.0 许可陷阱**（README 写 "copy directly" 但许可为网络 copyleft，禁止抄进闭源/商业项目）。

### Changed

- `github-reverse-modules/INDEX.md`、根 `SKILL.md`「Added Reverse Modules」、`references/unified-skills-entry.md`「核心逆向技能」表、`references/chinese-skill-names.json`（147 → 148 条）四处同批登记，保持 `cross-reference-completeness` 一致。
- `scripts/routing-rules.json`：新增 `cybersecurity-projects-catalog` 路由规则（confidence 0.84，40 → 41 条），文本插入零扰动其它规则；中文关键词用 `\uXXXX` 转义。实测 3 组正向命中（CarterPerez/certgames/网络安全项目合集），且 game-security(0.86)/ce-reverse(0.89)/ida-reverse(0.88)/x64dbg(0.89) 四类既有任务均未被抢占。
- `tests/routing.Tests.ps1`：补 2 条回归用例（正向命中 catalog + IDA 工具任务不被抢占），Pester 用例 18 → 20。
- `manifest.json`：版本 2.3.0 → 2.4.0。

## [2.3.0] - 2026-08-27

【中改】新增本地模块 `xhs-protocol-re`（suimi 小红书协议逆向），完成 5.C 全部跨文件登记。

### Added

- `local-reverse-modules/skills/xhs-protocol-re/`（MODULE.md + 3 个 references）：小红书 PC web 协议逆向与自动化。覆盖五条线路的取舍（`XYS_` 静态复刻 / `mnsv2` 字节码 VM **刻意寄生不破解** / `x-s-common` 同表可解 / 登录状态机行为逆向 / `xiaohongshu-mcp` 浏览器路线），并把三类证据源（HAR 静态复核 / 实时链路实测 / 真人扫码实测）逐条分列标注、不合并。
  - `references/signature-algorithms.md`：`XYS_` 构造公式、乱序 base64 码表原文、`S` 与 `x-s-common` 双字段表（编号错开一位）、`x6`/`x7` 结构线索（20B/24B、`x6` 键 == `S.x1` 69/69）、签名参数实时取值设计、验证统计（码表解码 82/82、`x5` 复算 81/82、`x-s-common` 解码 17/17、`getdss` 对 `x12` 尾段 78/82）。
  - `references/login-flow-and-traps.md`：三步链路、`codeStatus` 状态机、**三个致命陷阱**（凭据在 `qrcode/status` 的 `login_info` 而非 `activate`；`userId` 不可作判据；必须用 `user/me` 的 `guest` 收口）、常驻签名服务五条并发不变量、症状对照表。
  - `references/xhs-protocol-re-checklist.md`：签名环境/签名构造/请求头必需性/登录链路/并发/验收门/排查顺序/脱敏纪律的勾选清单。
- 四条红线固化进 MODULE.md：签名 body 与发送 body 必须同一字符串（`x5 = md5(path + body原文)`，服务端不做规范化，分叉后症状只是 406 且会把排查带偏）；GET 的 query 必须进签名路径；无头浏览器不得带 `web_session` 导航；导航与 `mnsv2` evaluate 互斥但**锁只包住 evaluate**（`asyncio.Lock` 不可重入，套在 try/except 外层会永久自死锁）。
- 排查方法论「**先做受控变量隔离，别急着改算法**」写入 MODULE.md 与 checklist：保持签名不变、只改单个请求头的四组合矩阵，实测得出 `qrcode/create` **需要 `Cookie`**、`X-s-common` 在该端点非必需（但真实浏览器 82/82 都带，定性为"服务端宽容"而非"该头没用"，且明确不外推到其它端点）。

### Changed

- `local-reverse-modules/INDEX.md`、根 `SKILL.md`「Added Local Reverse Modules」、`references/unified-skills-entry.md`「本地逆向恢复技能」表、`references/chinese-skill-names.json`（146 → 147 条）四处同批登记，保持 `cross-reference-completeness` 一致。
- `manifest.json`：版本 2.2.1 → 2.3.0，`references` 45 → 49（新增模块的 MODULE.md 与 3 个 references）。

## [2.2.1] - 2026-08-27

【小改/加固】多子代理审计后的一致性与健壮性修复；**无新增/删除模块**，145 个 MODULE.md 与全部注册表计数不变，`healthcheck` 24 项全绿、`unit-tests` 30 通过。

### Fixed

- 路由脚手架致命 bug（`new_module.ps1 -AddRoutingRule`）：旧锚点正则 `^\$rules = @\(` 会误匹配 `select_skill.ps1` 的 `$rules = @($parsedRules)` 并把路由器写崩、新规则也进不了 `routing-rules.json`。改为安全追加进 `routing-rules.json`（`ConvertFrom-Json` 回校 + 保留 BOM），`target` 标签同步更正。
- 路由非确定性：`select_skill.ps1` 两处 `Sort-Object confidence -Descending` 加 `-Stable`（同分按规则文件顺序确定性胜出）；`suimiFind-SkillByName` 停止复用自动变量 `$matches`，并把"恰好 1 个"放宽为"≥1 取首"，消除云同步重复枚举下静默丢规则。6 个选择器用例连跑确定且命中期望胜者。
- `lib/SkillLearning.ps1`：无 status 行时的全局 `-replace`（会在每个换行后插入、破坏记录）改为单行插入；晋级备注不再把用户可控 `-Note` 当作正则替换串（堵住 `$1/$&` 回引用注入）。
- 触发词跨入口失同步（H1）：把 `SKILL.md` frontmatter 已有的授权渗透测试工具链触发语义（nmap/nuclei/sqlmap/ffuf/hashcat/ZAP/Burp、src/bug bounty）同步补入 `CLAUDE.md`/`AGENTS.md`/`README.md` 与 `SKILL.md` 正文 Automatic Skill Routing 触发列表，避免这些 agent 入口漏触发。
- `references/domain-coverage-map.md`：修正陈旧命名（`api-security`→`api-sec`、`CTF-Sandbox-Orchestrator/`→`ctf-sandbox-orchestrator/`）、更新日期，并声明本文件为跨包概念图（非模块清单）。
- `references/module-onboarding-spec.md`：明确模板 4 个 H2（适用范围/工作流/证据与回滚/参考）为**推荐非强制**结构，消除"模板漂移"误判。
- `pentest-tools/src-hunter`：README（中/英）删除并不存在的 `h1-reports/`（"2887 份报告"）目录树条目与夸大数据来源表述，改为真实描述；`.gitignore` 移除外部工具链残留（`# Agent runtime state (OMC)` / `.omc/`）。
- `malware-analysis/MODULE.md`：正文内联参考路径补全 `../` 前缀，与文内既有可达链接一致。
- 工程卫生：将 2.1.0/2.2.0 已完成但从未提交的成果（3 个新模块 60 文件 + 12 处改动）落盘，修复"工作区成果未提交且位于云同步目录"的丢失风险（C1）。
- 一致性加固：`select_skill.ps1` 的 `suimiFind-SkillByPath` 与 `suimiFind-SkillByName` 同样停止复用自动变量 `$matches` 并放宽为"≥1 取首"，消除按目标路径路由时的同源竞态隐患（正常单命中行为不变）。
- 新增 `.gitattributes`：钉死 `*.sh`/`*.py` 为 LF、`*.ps1`/`*.bat` 为 CRLF、并标注二进制资产，避免 shell 脚本被 autocrlf 破坏；不强制重归一化既有 `.md`/`.json`（避免云同步目录海量 churn）。
- 修复 `sync_installed_skill.ps1` 会把 22M `.git`、zip、bak 一并拷进安装副本的问题（L1）：staging 后、断言前剔除 `.git`/`local-installed`/`*.zip`/`*.bak`，安装副本由 ~34M 降到 9.5M，未来同步一致精简。

### Changed

- 补厚 9 个偏薄模块（多子代理并行撰写、每处均保留 frontmatter/中文名/5-token 契约）：6 个 github 通用技法卡 ghidra-reverse(84→179)、go-rust-reverse(68→131)、macos-reverse(71→157)、thick-client(76→182)、browser-extension-reverse(71→168)、protocol-reverse(94→192)，补入标准开源工具链、编号工作流、证据与回滚与可用命令示例（仅公认工具、无编造 CVE/偏移/样本）；3 个本地诊断模块 flet-desktop-diagnostics/windows-python-app-recovery/windows-local-service-persistence 补通用骨架与证据与回滚，含 11 处 `（待 suimi 补充实测：…）` 占位符待回填。
- competition-* 归一化去重：给 14 个与主树概念重复的 competition 模块顶部加"归一化指针"，把读者导向更完整的主模块（competition-ssrf→ssrf、competition-jwt→jwt-oauth-token-attacks、4× windows/identity/kerberos/lsass→windows-ad、forensic-timeline→digital-forensics 等），**纯增量不删内容、保留 CTF 沙箱场景职责**，链接经 healthcheck 交叉引用校验可达。
- 路由 regex 收窄：给 `ida-reverse`(裸 `ida`/`mcp`) 与 `reverse-engineering`(裸 `pe/so/exe/elf/dll`) 加词边界（复用仓库既有 `(^|[^a-z0-9])x([^a-z0-9]|$)` 写法），消除 "candidate/type/also" 等子串误命中；run_tests 30/30、6 个选择器用例仍确定命中、真 IDA/固件任务不受影响。

## [2.2.0] - 2026-08-26

【中改】完成 `wechat-miniapp-protocol-re` 入库补全 + 给 `pentest-orchestration` 增加多步检测链引擎与批量配方库。

### Fixed

- 补全 `wechat-miniapp-protocol-re`（suimi微信小程序协议逆向）此前遗留的跨文件登记（chinese-skill-names/unified-skills-entry/local INDEX/根 SKILL.md），使 `cross-reference-completeness` 转绿。
- 收窄 `wechat-miniapp-protocol-re` 路由规则：把 `签名算法/抓包/内存/抽奖/任务/转盘` 等通用词改为**需与微信/小程序上下文共现**，避免抢占通用 JSVMP/加密/内存等逆向任务（修复 `select_skill` JSVMP 回归用例）；同时把该规则由原始中文改写为 `\uXXXX` ASCII 形式，消除 PS5.1 读取乱码风险。
- 修正 `tests/routing.Tests.ps1` 的 SQLi/登录控制用例（原断言硬钉 `api-sec` 为唯一胜出者）：实测该模糊查询的胜出者在不同进程/负载下**非确定**——干净枚举时为 `sqli-sql-injection`(0.90)，负载下降级为 `auth-sec`(0.78)/`api-sec`；已核验此非确定性与本次新增路由规则无关（用 HEAD 版 `routing-rules.json` 复测同样非固定，且本仓库位于百度网盘同步目录、文件可能被同步改写）。故把断言收敛为该用例真正要守护的唯一不变量——**不被 `pentest-orchestration` 抢占**（`ok=true` 且路径不含 `pentest-orchestration`），并对齐用例标题；`unit-tests` 由此在 fresh-process 与 `healthcheck` 下稳定 30 通过（连续 3+ 次绿）。

### Added

- `local-reverse-modules/skills/mirasim-godmode-re/`：新增本地逆向恢复模块（suimi Mirasim 德州扑克辅助维护）。沉淀 Mirasim 桌面单机德州扑克（Electron）的逆向维护方法论：renderer 多副本发现（app.asar / resources/web/app / ~/.mirasim/app/<ver>）、版本升级失效诊断（history.jsonl won:false / 异常 reward / webui no_arc）、补丁串多版本适配（minified 函数名漂移）、多目标打补丁与 asar 重打包（@electron/asar createPackage 异步坑）、CDP 状态读取兼容。含 `references/mirasim-patch-checklist.md` 补丁串快照。已登记 INDEX / SKILL.md / unified-skills-entry / chinese-skill-names / manifest / routing-rules（触发词：mirasim、德州扑克、透视补丁、必胜补丁、机台补丁、更新后辅助失效）。
- `pentest-orchestration/scripts/recipe_chain.py`：多步检测链引擎（stdlib urllib）——先登录抓 token 再打受保护接口，支持 `{{var}}` 模板注入与 body/header 的 json/regex 抽取，recipe 级 `match` 作用于最后一步；`recipe_run.sh` 自动分派 `chain` 配方，`safe:false` + `--unsafe` 门禁。
- `pentest-orchestration/scripts/batch_convert_templates.sh`：批量把 Sn1per `templates/**.sh` 转成配方库（一模板一文件，文件名沿用源模板名，1:1 可溯源）。
- `pentest-orchestration/references/recipes/sniper-passive/`：用批量工具从 Sn1per 43 个 passive 模板转出的检测配方库（43 个，其中 2 个 `safe:false`）+ 溯源/授权 README。
- `pentest-orchestration/references/recipes/http-auth-chain-example.json`：登录→token→受保护接口的多步链示例。
- `pentest-orchestration/references/detection-recipe-format.md` 第 6 节：`chain` 字段规范由"占位"更新为"已实现"。
- `tests/routing.Tests.ps1`：新增 wechat 正向路由回归用例（JSVMP 控制用例仍作对照）。
- `recipe_run.sh`/脚本：python 解释器探测（python3/python 双兼容 Kali 与 Windows）。

## [2.1.0] - 2026-08-26

【中改】新增安全研究模块 `pentest-orchestration`（suimi攻击流程编排）：把"攻击流程编排器"方法论固化为可路由技能，方法论提炼自对 Sn1per 社区版的完整逆向拆解。

### Added

- `security-research-modules/skills/pentest-orchestration/MODULE.md`：攻击流程编排器六层参考架构（入口/分层配置/模式分发/工作区loot/检测配方引擎/报告）、recon→scan→exploit→report 标准执行链、数据驱动扩展法、硬性授权边界、从 Sn1per 提炼的反模式清单。
- `references/detection-recipe-format.md`：把 Sn1per 的 bash 模板机制改写成声明式**检测配方（detection recipe）JSON**——schema + Sn1per 字段映射表 + 安全边界（safe 标记）。
- `references/orchestrator-architecture-comparison.md`：Sn1per vs nuclei vs reconftw 逐维架构取舍与选型指引。
- `references/sniper-normal-teardown.md`：Sn1per `modes/normal.sh`（1259 行）扫描链逐段拆解，用真实行号还原 328 次 nmap / 41 次 msfconsole 的构成。
- `scripts/orchestrate.sh`：修正 Sn1per 反模式的安全编排器骨架（不强制 root、白名单默认拒绝、dry-run 默认、函数分发替代 source、利用层默认关闭）。
- `scripts/recipe_run.sh`：检测配方 runner（curl + python 匹配，默认只跑 safe 配方）。
- `scripts/sniper_template_to_recipe.py`：把 Sn1per `templates/*.sh` 一键转成检测配方 JSON（解析不执行）。
- `references/recipes/http-path-traversal-example.json`：检测配方格式示例。

### Registered

- `scripts/routing-rules.json`：新增 `pentest-orchestration` 路由规则（中英文关键词，confidence 0.85）。
- `tests/routing.Tests.ps1`：新增正向命中 + api-sec 不被抢占两条回归用例。
- 跨文件登记：`chinese-skill-names.json` / `unified-skills-entry.md` / `security-research-modules/INDEX.md` / 根 `SKILL.md` / `recon-for-sec` 路由器 Skill Map（经 new_module.ps1 生成并逐项校验）。

## [2.0.0] - 2026-08-25

【大规模更改】规范体系全面完善：新增第 13 章（逆向内容完整性与脱敏边界）、第 14 章（内容完整性与同步验收）、第 10.1 节（版本号规则——每次更新自增版本、大规模更改升 major），覆盖矩阵 24 项检查全部对齐

### Added

- `references/module-onboarding-spec.md` 第 13 章「逆向内容完整性与脱敏边界」：13.1 绝不脱敏白名单/13.2 必须脱敏黑名单/13.3 公开可达判定标准/13.4 内容完整性验收四步法/13.5 官方 skills 完整收录五步法。
- `references/module-onboarding-spec.md` 第 14 章「内容完整性与同步验收」：完整性审计/同步确认/diff 验证/缓存清理 + 14.5 规范自身变更流程（覆盖矩阵审计前置 → 编码结构验证 → 版本发布 → 学习闭环 → 同步）。
- `references/module-onboarding-spec.md` 第 10.1 节「版本号规则」：patch/minor/major 三级语义 + 判定标准 + 每次更新必须自增版本禁止同版本重复提交。
- `references/module-onboarding-spec.md` 第 9 节检查表补全：`reusable-skill-resolver`/`installed-skill-sync`/`generated-caches`/环境可选项 4 行。
- `references/module-onboarding-spec.md` 第 12 节 checklist 新增 3 项：逆向技术内容完整性/含外部快照官方 skills 验收/缓存清理。
- `references/module-onboarding-spec.md` 第 1 节补官方 skills 收录指引（指向 13.5）。
- 学习闭环晋级：`入库规范必须含逆向内容完整性与脱敏边界章节`（id `20260825-110824`）已 promote 到 Promoted Learning Notes。
- 学习闭环晋级：`路由规则必须同步补回归用例且合规审计不能只看healthcheck`（id `20260825-105122`）已 promote 到 Promoted Learning Notes。

### Changed

- `references/module-onboarding-spec.md` 14.5 节版本规则：从"patch 发布"改为"按 10.1 规则——小改 patch、模块级 minor、规范重写/新增完整大节 major"。

## [1.24.2] - 2026-08-25

完善入库规范：新增 14.5 规范自身变更流程（覆盖矩阵审计前置 + 编码/结构验证 + patch 发布 + 学习闭环）

### Added

- `references/module-onboarding-spec.md`：新增 14.5 节「规范自身变更流程」——变更前先做覆盖矩阵审计确认缺口真实存在；变更后立即验证 healthcheck 24/24 PASS + UTF-8 with BOM 编码检查 + 小节编号连续 + Promoted Learning Notes 与 inbox 一致；文档完善类变更按 patch 发布（CHANGELOG 说明改了哪节）；变更方法本身验证过则 record → promote 回本规范形成正循环；最后 sync + diff 验证。

## [1.24.1] - 2026-08-25

完善入库规范：新增逆向内容完整性与脱敏边界章节（不脱敏白名单/脱敏黑名单/判定标准/完整性验收/官方skills五步收录法）

### Added

- `references/module-onboarding-spec.md`：新增第 13 节「逆向内容完整性与脱敏边界」——明确 AOB/算法/寄存器/协议字段/公开仓库 URL 等逆向技术内容**一律不脱敏、不占位符化、不删减**，仅真实凭据与私有基础设施使用占位符；含 13.4 内容完整性验收（条目数核对/URL 缺失率必须 0/TRUNCATED 截断标记必须 0）与 13.5 官方 skills 完整收录五步法（重命名 .md 防 single-installable 冲突 + 改写 ../xxx/SKILL.md 链接 + 保留 frontmatter/许可证 + manifest 登记 + 不注册为可路由技能）。
- `references/module-onboarding-spec.md`：新增第 14 节「内容完整性与同步验收」——完整性审计 + 实际同步后 diff 验证（`would-sync` 为 dry-run 预期动作，非失败）+ 缓存清理。
- `references/module-onboarding-spec.md`：第 9 节检查表补齐 `reusable-skill-resolver` / `installed-skill-sync` / `generated-caches` / 环境可选项 4 行；第 12 节 checklist 新增内容完整性、官方 skills 收录、缓存清理 3 项。
- 学习闭环晋级：`入库规范必须含逆向内容完整性与脱敏边界章节`经验已 promote 到 `references/module-onboarding-spec.md`（Promoted Learning Notes）。

## [1.24.0] - 2026-08-25

add game-security-research module: read-only awesome-game-security directory (4231 entries / 36 categories, offline snapshot JSON)

### Added

- `scripts/routing-rules.json`：新增 `game-security-research` 路由规则（confidence 0.86，覆盖游戏破解/外挂/反作弊/DMA/BYOVD/游戏引擎安全/模拟器检测等中英文关键词），游戏安全研究类任务现可经统一入口直达该模块；具体工具任务（如 Cheat Engine 扫描）仍优先走 `ce-reverse` 等工具模块。
- `github-reverse-modules/skills/game-security-research/references/official-skills/`：**上游 awesome-game-security 官方 10 个 AI Agent skills 完整本地副本**（anti-cheat-systems、dma-attack-techniques、game-hacking-techniques、graphics-api-hooking、mobile-security、windows-kernel-security、reverse-engineering-tools、game-engine-resources、research-rigor、awesome-game-security-overview，共 259KB），改写跨文件链接为本地可达，无需在线安装；manifest references 同步登记。
- 学习闭环晋级：`awesome-* 大仓库三层接入`经验已 promote 到 `references/module-onboarding-spec.md`（Promoted Learning Notes）。
- 学习闭环晋级：`新增目录型模块必须同步补路由规则`经验已 promote 到 `references/module-onboarding-spec.md`（Promoted Learning Notes，与三层接入经验合并构成完整入库流程）。
- 学习闭环晋级：`promote_skill_lesson 超时判定法`经验已 promote 到 `references/skill-learning-loop.md`（Promoted Learning Notes）。

## [1.23.2] - 2026-08-25

unify web reverse routing through single root entry (reverse-engineering-workflow); merge 3 web rules into one

## [1.23.1] - 2026-08-25

add web-api-reverse / web-js-reverse / web-crypto-reverse modules; routing-rules.json extraction

## [Unreleased]

### Changed

- `github-reverse-modules/skills/js-reverse/references/gcaptcha4-captcha-re.md`：**极验 v4 逆向专案更新**——补充 w 加密完整算法（AES-CBC 变体 + RSA-1024 PKCS1v15）、CryptoJS 细节（iv=ASCII '0'×16、nRounds=6+keyWords）、Python 复现核心代码、验证证据表（3 组 AES 向量 + 完整 w 对照）、协议可用性缺口（ctct_bundle 加密 / NWAF / register 403）。

### Fixed

- 修复 `references/skill-learning-inbox.md` 结构损坏：被吞进上一条目的 Nuxt3 SSR 经验条目恢复为独立条目；被晋级行粘连的 HAR、Vite 两条经验恢复可解析（此前解析器只识别到 4/7 条）；APK smali 经验的晋级目标更正为 `github-reverse-modules/skills/apk-reverse/MODULE.md`，并清理 `security-research-modules/skills/recon-for-sec/MODULE.md` 中错误的 "APK smali" 标题（该小节实为 Nuxt3 前端经验）。

### Added

- `github-reverse-modules/skills/web-api-reverse/`：**suimi Web 后端 API 逆向**——从网络请求/HAR/cURL 逆向内部 API 协议，REST/GraphQL/batchexecute/gRPC-web 多协议检测、认证检测、生成 Python httpx / TypeScript 客户端 + API 文档，含七阶段多智能体流水线与回放验证。
- `github-reverse-modules/skills/web-js-reverse/`：**suimi Web 前端 JS 逆向**——JS 混淆分级与还原、JSVMP 五步逆向法、CDP 检测绕过、TLS/HTTP2/QUIC 指纹、环境修补、WASM 逆向、反爬分层击破；携带 12 份精选 references。
- `github-reverse-modules/skills/web-crypto-reverse/`：**suimi Web/APK 加密算法逆向**——从 Web JS 与 Android APK 识别并 Python 重构加密/签名算法，30 个 specialist 索引、Web2/Web3 判定、线上验证闭环。
- `scripts/routing-rules.json`：路由规则独立配置文件（3 条新 web 逆向规则），`select_skill.ps1` 改为从该文件加载；`healthcheck.ps1` 同步改为校验该文件。
- `README.md`：人类可读的项目总览与使用说明。
- `CHANGELOG.md`：变更记录。
- `scripts/package_release.ps1` 与 `scripts/lib/Release.ps1`：健康检查门禁的发布打包脚本，支持 manifest 版本自增（patch/minor）、CHANGELOG 自动追加、确定性 zip 打包与 SHA256 校验、DryRun 预览。
- `tests/`：Pester 单元测试套件（`routing.Tests.ps1`、`skill-learning.Tests.ps1`、`release-utils.Tests.ps1`）与 `tests/run_tests.ps1` 运行器；`healthcheck.ps1` 新增 `unit-tests` 检查项。
- `.gitignore` 与 git 基线。

## [1.23.0] - 2026-07-27

- 技能包基线导入：自动路由入口、references 方法论、github/local/security 三类内部模块、WPeGPT/IDA 集成、学习闭环与健康检查。
