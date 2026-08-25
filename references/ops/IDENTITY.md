# reverse-engineering-workflow 身份宣言

> 本文件固定 **我们是谁**，由 suimi 作为本地维护者支持。坚持证据纪律、范围纪律、分工纪律与时间线纪律，但保持形态轻量：`git clone` 即可用，无强制服务端依赖。

## 我们是

| 维度 | reverse-engineering-workflow |
|------|----------------|
| 形态 | **Skill 路由包** — 给任意 AI 客户端（Claude/Cursor/Codex…）用的方法论 + 工具自举 |
| 入口 | `SKILL.md` → `scripts/invoke_skill.ps1` 自动路由 → 内部 `MODULE.md` |
| 工具真相 | `bootstrap-manifest.json` + `tool-index`（本机路径，不猜） |
| 进化 | `field-journal/` 脱敏经验回写 + 学习闭环（`record/review/promote_skill_lesson.ps1`） |
| 产物 | Markdown 报告 + `work/<case>/` 本地作战目录（gitignore） |
| 部署 | `git clone` 即可；无强制 PG/UI/Docker 池 |

## 设计边界（故意不做）

- ❌ 不捆绑重型平台：无 React 作战台、FastAPI 控制面、PostgreSQL 证据库、LightRAG 服务、Docker 主机池
- ❌ 不做多 Agent 进程编排：仅 **角色→skill 映射 + 交接协议**（`ops/role-map.md`）
- ✅ 沙箱工具可用 **文档** 推荐可选 profile（`ops/sandbox-profile.md`），但不强制安装

## 核心纪律（必须保留）

| 思想 | reverse-engineering-workflow 形态 |
|------|-------------------|
| 授权与项目边界 | `scope-contract` → 每案 `scope.md` |
| Evidence→Finding→Path | `ops/evidence-finding-path.md` + 报告模板 |
| 专家分工 | `ops/role-map.md`（Lead/cie/cpe/cre…→ skill） |
| 可回放 | `work/<case>/timeline.md` 追加写 |
| WorkItem/覆盖 | `workitems.md` + coverage 勾选 |
| 沙箱工具齐 | `ops/sandbox-profile.md` vs bootstrap-manifest |
| 出站管控 | `network_profile` 字段（offline/lab/authorized） |

## 特色（必须保留）

1. **三轴路由 + PRIMARY 快路径**（目标类型 / 意图 / 工具链）  
2. **bootstrap 按需装工具**，跨 Windows/Kali/Linux/macOS  
3. **MCP 友好**（IDA/Burp/CE/x64dbg 等本地工具桥接）  
4. **field-journal 脱敏进化**  
5. **服从性工程**：ACTION REQUIRED / 完成自检 / 禁止假停  

## 与外部技能生态的关系

- **不** submodule 巨型 skill 库（投毒面与维护成本，见 `skill-supply-chain.md`）  
- **要** 用 `domain-coverage-map.md` 证明：深度 skill + 路由 > 碎片 skill 堆叠  
- 外部 skill 安装：AST10 思维 + 只信 curated 源；一切外部来源信息不进入本包文档，本包文档仅描述本地能力与本地维护者（suimi）。
