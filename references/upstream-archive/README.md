# upstream-archive：上游 reverse-skill v1.0.1 完整归档

> 本目录是上游仓库（`reverse-skill` v1.0.1）**除技能模块外**的全部剩余内容的只读归档。
> 技能模块本体已转换并入 `github-reverse-modules/` 与 `security-research-modules/`；
> 本目录仅保留**外围框架资产**，供查阅、对照、按需借鉴，**不参与本地路由与注册**。

## 目录说明

| 路径 | 内容 | 用途 |
|------|------|------|
| `scripts/` | 上游案例工作流脚本（master-route / case-init / case-guard / append-evidence / consolidate-evidence / extract-summaries / scan-leaks / bootstrap-reverse / refresh-tool-index 等 33 个 + lib/ 5 个） | 上游"案例驱动"工作流参考；本地路由以 `scripts/select_skill.ps1` + `routing-rules.json` 为准 |
| `config/routing.json` | 上游路由表（单一事实源） | 对照本地 `scripts/routing-rules.json` |
| `tests/routing-benchmark.json` | 上游路由基准测试数据 | 对照本地 `tests/routing.Tests.ps1` |
| `docs/` | 架构 / OVERVIEW / 平台支持 / 安全审计 / 发布检查单 / PR 评审 17 文件 | 设计理念与安全实践参考 |
| `examples/ctf-demo/` | CTF 案例包（scope / timeline / workitems / evidence E-001..003 / report） | 案例包结构范例 |
| `reports/` | 上游渗透测试报告样例 | 报告格式参考 |
| `kali/` | Kali 部署脚本（bootstrap / quick-setup / tool-discovery / ida-start / refresh-tool-index） | Linux 平台部署参考 |
| `burp-mcp-full/` | Burp MCP 桥接项目（Gradle 构建，mcp-bridge.js） | 工具集成参考 |
| 顶层 *.md | README（中/英/AI 版）、RULES、CHANGELOG、CLAUDE、AGENTS、VERSION | 项目元信息 |
| `MASTER-ROUTING.md` / `routing.md` / `routing_zh.md` / `CONTRIBUTING.md` / `INDEX.md` / `tool-index.md.template` | 上游路由契约与导航 | 方法论对照 |

## 使用约定

- **只读**：本目录内容由上游原样复制（仅补 UTF-8 BOM），修改不影响本地任何功能。
- **不注册**：不进入 `chinese-skill-names.json`、`unified-skills-entry.md`、`manifest.json` 的模块注册（manifest 仅登记本 README 作入口）。
- **不执行**：`scripts/` 下的 .ps1 未经过本地测试，不保证 PS 5.1 兼容，勿直接当作本地脚本运行。
- **参考优先**：需要借鉴时，以本地 `references/` 同主题文档（`ops/`、`field-journal/`、`reverse-task-recipes.md` 等）为准。

## 未归档内容

以下上游内容已并入本地技能体系（不在本目录）：

- 34 个技能模块 → `github-reverse-modules/skills/`、`security-research-modules/skills/`
- CTF-Sandbox-Orchestrator 42 模块 → `security-research-modules/skills/`
- `skills/references/community-security-skills.md`、`domain-coverage-map.md` → `references/`
- `skills/ops/` → `references/ops/`，`skills/field-journal/` → `references/field-journal/`
