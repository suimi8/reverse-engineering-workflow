# ops — reverse-skill 作战契约层

Z3r0 启发、**本包形态**实现：

| 文件 | 用途 |
|------|------|
| [IDENTITY.md](IDENTITY.md) | 我们是谁 / 不做平台 |
| [scope-contract.md](scope-contract.md) | 启动 scope + network_profile |
| [evidence-finding-path.md](evidence-finding-path.md) | 证据链 |
| [role-map.md](role-map.md) | 角色→skill + 交接 |
| [timeline-workitem.md](timeline-workitem.md) | 时间线与覆盖 |
| [sandbox-profile.md](sandbox-profile.md) | 工具对照 |
| [skill-supply-chain.md](skill-supply-chain.md) | Agent Skill/MCP 供应链安全（AST10 精简） |
| [case-review/](../case-review/) | Evidence 图完整性审查与报告交接 |

相关 references（非孤儿，从本 hub / MASTER / SKILL 可达）：

- `../references/community-security-skills.md` — 社区 skill 生态对照  
- `../references/domain-coverage-map.md` — 本包领域覆盖  
- `../attack-chain/references/lifecycle-checklist.md` — 攻击链阶段门闩  
- `../reverse-engineering/references/re-agent-workflow.md` — RE 四阶段  
- `../pentest-tools/references/recon-pipeline.md` — 授权侦察 + Evidence 门  

- 脚本：`../scripts/case-init.ps1`
- 校验：`../scripts/verify-routing-coherence.ps1`（含 ops 契约检查）
- 审查：`../case-review/scripts/review_case.py`（只读 Evidence 图检查）


> 注：此文件由上游 reverse-skill v1.0.1 ops/ 导入，仅供参考。本地路由使用 select_skill.ps1/routing-rules.json。

## Promoted Learning Notes

### 上游 sidecar 参考文件（ops/field-journal）导入落点：references/ 子目录

- source: `20260825-051545-上游-sidecar-参考文件-ops-field-journal-导入落点-reference`
- category: other
- applies_to: upstream skill merge / reference files
- purpose_zh: 上游仓库的 ops 作战契约层与 field-journal 实战日志并非模块，不应注册为 skill，而应整目录导入本地 references/ops/ 与 references/field-journal/，并在 manifest.json references 中登记入口文件，保持与模块树分离。
- confidence: 4/5

**Lesson**

非模块类上游资产（契约文档、实战案例库）用 references/ 子目录整目录导入并登记 manifest，不注册为 skill；实战日志与 seed 案例保留原文件名便于日后检索复用。

**Evidence**

reverse-skill v1.0.1 导入：ops 10 文件 + field-journal 44 文件（17 篇实战日志 + 17 seed 案例）完整复制到 references/ 子目录，manifest-paths 61 项 PASS，healthcheck 24/24 PASS。

**Validation**

manifest-paths 61 项 PASS；healthcheck 24/24 PASS