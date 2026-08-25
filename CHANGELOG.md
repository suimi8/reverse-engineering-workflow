# Changelog

本技能包所有值得记录的变更都记录在此文件。格式参考 Keep a Changelog。版本号与 `manifest.json` 保持一致。



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
