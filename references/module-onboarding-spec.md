# suimi 模块入库规范（Module Onboarding Spec）

本文件是向 `reverse-engineering-workflow` 技能包**新增/迁移/退役**任何内部模块或参考文档的唯一权威流程。目标：让每一次入库都是**增量、可逆、可被 `scripts/healthcheck.ps1` 全量验证**的操作，杜绝"模块写完但路由接不上 / 索引漏登记 / 中文名不同步 / 计数对不上"这类只能靠人工回查才发现的问题。

适用对象：给本包加新逆向工具模块、新安全研究模块、新本地恢复模块、新方法论参考文档，或把学习闭环里的经验晋级为独立模块时。

> 硬性底线：入库的最后一步永远是 `scripts/healthcheck.ps1` 返回 **0 fail**。任何一项 fail 都说明登记没做全，未完成入库。

---

## 0. 术语与不变量

- **可安装 skill**：只有根 `SKILL.md` 一个。健康检查项 `single-installable-skill` 强制此约束——**永远不要**在子目录新建第二个 `SKILL.md`。
- **内部模块**：`<root>/skills/<name>/MODULE.md`，由根入口路由加载，不单独安装。
- **三棵模块树 + 参考层**：
  | 落点 | 目录 | 收什么 | 有无 INDEX.md |
  |---|---|---|---|
  | 通用逆向 | `github-reverse-modules/skills/<name>/` | 二进制/APK/移动端/调试器/CLI 逆向工具与方法论 | 有 |
  | 本地恢复 | `local-reverse-modules/skills/<name>/` | Windows 打包程序恢复、桌面诊断、本地服务自启动等本机专项 | 有（对齐 github/security，由 cross-reference-completeness 校验） |
  | 安全研究 | `security-research-modules/skills/<name>/` | Web/API/Auth/注入/文件/业务逻辑/侦察等授权安全评估 | 有 |
  | 参考文档 | `references/<name>.md` | 跨模块方法论、契约、下载链接等（**非可路由技能**） | 无（用 SKILL.md "Choose References" 段登记） |
- **命名**：模块目录名与 `MODULE.md` 的 `name:` 必须是同一个 **kebab-case**（只允许 `[a-z0-9-]`）。中文展示名一律以 `suimi` 开头。

---

## 1. 落点判定（先决定放哪棵树）

按下表选择唯一落点；拿不准时按"这个模块最主要的第一使用场景"归类，不要为了覆盖多场景而放进无关既有模块或跨树复制。

1. 目标是**本地二进制 / APK / 固件 / 调试器 / CLI 逆向工具/方法** → `github-reverse-modules/skills/`
2. 目标是**本机 Windows 打包程序运行修复 / 桌面进程窗口诊断 / 本地服务自启动** → `local-reverse-modules/skills/`
3. 目标是**Web/API/认证/注入/文件访问/业务逻辑/OSINT 侦察等授权安全评估** → `security-research-modules/skills/`
4. 目标只是**一份跨模块方法论 / 契约 / 清单**，没有独立的"路由触达 + 中文名"诉求 → `references/<name>.md`（走第 7 节，登记点少很多）

外部第三方仓库接入的额外判定：
- 单一、边界清楚的工具（IDA/x64dbg/CE 类）→ 建对应工具模块，若自带一键安装脚本可登记进 `github-reverse-modules/skills/scripts/bootstrap-manifest.json`（每条 capability 对应单一工具）。
- **体量大、条目多、有稳定分类字段、依赖不稳定外部网络**的工具目录（如 awesome-* 类）→ 走"三层接入"：主入口 `MODULE.md` + 本地全量快照（`references/*-snapshot.json`）+ 正文内嵌完整分类索引表。**禁止**把几百个混有 C2/RAT/钓鱼套件的 meta-installer 写进 `bootstrap-manifest.json` 自动装，只做只读目录记录用法与安全边界。若仓库还自带官方 AI Agent skills（`.claude/skills/`、`SKILL.md` 等），按 13.5 节"官方 skills 完整收录法"一并收录为 `references/official-skills/` 本地副本。

---

## 2. 目录与文件结构

```
<root>/skills/<name>/
├── MODULE.md                 # 必需，入口
├── references/               # 可选，深度方法论/快照数据
│   └── *.md | *.json
├── scripts/                  # 可选，模块专属脚本（ps1/sh/py/js）
│   └── ...
└── SCENARIOS.md              # 可选，安全模块常用，放场景化利用/审查清单
```

约束：
- `<name>` 目录名 == `MODULE.md` 的 `name:` 字段，kebab-case。
- 模块内相对链接指向别的技能时用 `](../<other>/MODULE.md)` 形式——健康检查会验证 `../.../MODULE.md`、`../.../SKILL.md` 链接可达，断链即 fail。
- 模块脚本放模块自己的 `scripts/`；**不要**污染根 `scripts/`（根 `scripts/` 只放路由/探针/补丁模板/学习闭环/发布等全局工具）。

正文小节结构（**推荐、非强制**）：`new_module.ps1` 模板给出的 `## 适用范围 / ## 工作流 / ## 证据与回滚 / ## 参考` 是推荐起步骨架，不是硬性要求。healthcheck 只校验 frontmatter 契约、中文名行与第 4 节反馈契约，**不校验正文标题名**；模块可用更贴合自身领域的标题体系替代这四个小节，只要强制项齐全即可，审计时正文标题与模板不一致不判 fail。

---

## 3. MODULE.md frontmatter 契约（对齐 healthcheck 正则）

健康检查 `*-skill-modules` 用这条正则判定合法：

```
^---\s*\r?\nname:\s*[-a-z0-9]+\s*\r?\ndescription:
```

因此 frontmatter **必须**长这样，且 `name:` 与 `description:` 之间**不能插入任何其它字段**：

```markdown
---
name: your-module-name
description: >-
  一句话说明本模块解决什么问题、何时触发、覆盖哪些子场景。写给路由器和人看，
  要含足够关键词以便 resolve_skill.ps1 按关键词命中。
---
```

- `name:` 只能是小写字母、数字、连字符。
- `description:` 允许 `>-`/`|-` 折叠块，但**不能**是裸的 `|`/`>`/`|-`/`>-` 占位符——`reusable-skill-registry` 检查会因"占位描述"fail。
- 可在 frontmatter 之后追加 `metadata:`、`license:`、`allowed-tools:`、`compatibility:` 等（须在 `description:` 之后）。内部模块建议带 `metadata: { user-invocable: "false" }`。

---

## 4. 正文强制反馈契约段落（对齐 mandatory-final-feedback-contract）

`github-reverse-modules` 与 `security-research-modules` 下**每个** `MODULE.md` 正文都必须包含以下 5 个 token，否则 `mandatory-final-feedback-contract` 检查 fail：

`新技能/方法反馈`、`finish_skill_run.ps1`、`record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1`

标准做法：在 frontmatter 之后、正文标题之前，粘贴这段（照抄现有模块，如 `clickjacking/MODULE.md`）：

```markdown
中文名：suimi<中文展示名去掉前缀的部分>

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到
`reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，
明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用
`record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。
```

> `local-reverse-modules` 目前不在该强制检查范围内，但为一致性建议同样加上。

---

## 5. 必需的跨文件登记（对齐 cross-reference-completeness）

这是最容易漏、也是历史上反复踩坑的一步。健康检查 `cross-reference-completeness` 会逐条核对。**按落点执行对应清单**：

### 5.A 新增 `github-reverse-modules` 模块

1. `github-reverse-modules/INDEX.md`：新增一节，正文出现 `skills/<name>/`。
2. 根 `SKILL.md` 的 "Added Reverse Modules" 列表：新增一行，出现 `skills/<name>/MODULE.md`。
3. `references/unified-skills-entry.md`：在"核心逆向技能"表加一行，**行内必须出现完整注册表路径** `github-reverse-modules/skills/<name>/MODULE.md`。
4. `references/chinese-skill-names.json`：新增 `{"path":"github-reverse-modules/skills/<name>/MODULE.md","display_name":"suimi<中文名>"}`。
5. （可选）`scripts/select_skill.ps1` 的 `$rules`：加一条 `name = '<name>'` 的路由规则（见第 6 节）。

### 5.B 新增 `security-research-modules` 模块

1. `security-research-modules/INDEX.md` 的 "Imported Skill Set"（或 "Locally Added Modules"）：出现被反引号包裹的 `` `<name>` ``。
2. **至少一个 P1 路由器**的 Skill Map 里加 `](../<name>/MODULE.md)` 相对链接。P1 路由器 = `hack / recon-for-sec / api-sec / auth-sec / injection-checking / file-access-vuln / business-logic-vuln`。**没有被任何路由器链接的详情模块会被判为"孤儿模块"直接 fail。**
3. `references/unified-skills-entry.md`：在"Web/API 安全研究专题技能"表加一行，含完整路径。
4. `references/chinese-skill-names.json`：加 `{"path":"security-research-modules/skills/<name>/MODULE.md","display_name":"suimi<中文名>"}`。
5. 若本地新增（非 donor 导入）：在 INDEX.md 的 "Locally Added Modules" 另起一节说明其性质，避免文档失实。
6. （可选）`scripts/select_skill.ps1` 规则。

### 5.C 新增 `local-reverse-modules` 模块

1. `local-reverse-modules/INDEX.md`：新增一节，正文出现 `skills/<name>/`（已纳入 healthcheck 的 cross-reference-completeness 强制校验）。
2. 根 `SKILL.md` 的 "Added Local Reverse Modules" 段：新增一行，出现完整路径 `local-reverse-modules/skills/<name>/MODULE.md`（同样被 cross-reference-completeness 校验）。
3. `references/unified-skills-entry.md`："本地逆向恢复技能"表加一行，含完整路径。
4. `references/chinese-skill-names.json`：加对应条目。
5. 若模块随带 `references/*.md`，且要进 manifest：在 `manifest.json` 的 `references` 数组登记。
6. （可选）`scripts/select_skill.ps1` 规则 + `scripts/re_workflow_entry.ps1` 的目录探测信号（当希望"给一个目录路径就能自动命中该本地模块"时）。

> 三处信息（INDEX / SKILL.md 列表 / unified-entry 表）是同一事实的多副本，务必同批修改、保持一致。

---

## 6. 路由规则（何时改 select_skill.ps1，怎么改）

**默认不加**。多数 P2 主题模块靠 P1 路由器的 Skill Map、`resolve_skill.ps1`（按 name/中文名/路径/关键词）即可触达。只有当**用户明确要求"确保这个模块被自然语言直接命中"**时才值得为它加一条 `select_skill.ps1` 规则——每加一条都是长期维护成本，且可能与未来模块关键词冲突、或撞上 healthcheck 里 selector 的固定回归用例。

若确需加规则，按此安全顺序：

1. **Unicode 转义独立核对**：正则里的中文一律用 `\uXXXX`（.NET regex 引擎解释，与 PowerShell 字符串转义是两套体系）。先用 `"$([char]0xXXXX)"` 之类打印比对，确认每个 `\uXXXX` 等于目标汉字，再写进 `$rules`。手算 code point 抄错一位不会报错，只会静默匹配失败。
2. **关键词用短词干 + 宽松间隔**，假设自然语言会插字/虚词：用 `附加.{0,6}(进程|process)` 而非精确短语 `附加进程`；通用动词（如"反查"）必须与对象词双向限定：`(用户名|邮箱|手机号|域名).{0,4}反查|反查.{0,4}(用户名|邮箱|手机号|域名)`。
3. **规则名 == 注册表里真实存在的 `name`**（`cross-reference-completeness` 的 dead-rule 检查会抓打错的名字）。
4. **批量自然语言测试**：至少 3-5 条不含关键词的口语提问命中新模块 + 2-3 条既有模块的对照 query 结果不变，用 `select_skill.ps1 -TaskText` 循环测。不能只测最干净那一句。
5. 若新增了会影响选择结果的规则，给 `tests/routing.Tests.ps1` 补一条回归用例锁定。

安全类多主题命中时，`select_skill.ps1` 会自动上抛到 `hack`（通用）或 `api-sec`（API 相关）路由器并保留具体主题为候选——加规则时注意别破坏这个上抛逻辑（对照 healthcheck 的 `fixed-reusable-entrypoint` mixed-security 用例）。

---

## 7. 新增 references 参考文档（轻量路径）

参考文档不是可路由技能，登记点少：

1. 建 `references/<name>.md`。
2. 在根 `SKILL.md` 的 "Choose References" 列表加一行指向它（保证可发现，避免孤儿文档）。
3. 若希望它出现在正式引用清单：在 `manifest.json` 的 `references` 数组加一行（`manifest-paths` 检查只验证路径存在、相对、不越界）。
4. **不要**加入 `chinese-skill-names.json`（那只登记可路由技能模块，加了会让 registry 计数与实际 MODULE.md 数不符而 fail）。
5. references 文档**不**受第 4 节反馈契约强制（除非它是 `skill-learning-loop.md` / `reusable-invocation-contract.md` 这两个已被固定纳入检查的文件）。

---

## 8. 中文名与注册表

- `chinese-skill-names.json` 是 `list_skills.ps1` 注册表和 `chinese-skill-names` 健康检查的事实源。每个 `MODULE.md` 都必须在此有 `display_name`（以 `suimi` 开头）。
- `reusable-skill-registry` 检查会核对"注册表条目数 == 实际 `SKILL.md + 三棵树所有 MODULE.md` 文件数"。**新增模块必忘不得**，漏登即计数不符 fail。
- 同步命令：`scripts/suimi_sync_chinese_skill_names.ps1`（`-CheckOnly` 只检查，不带则写回）。

---

## 9. 入库门禁（最后一步，硬性）

```powershell
# 1. 全量健康检查——必须 0 fail
.\scripts\healthcheck.ps1

# 2. 路由可达性抽验
.\scripts\list_skills.ps1 -AsJson              # 能查到新条目 + display_name
.\scripts\resolve_skill.ps1 -Query "<name>" -AsJson   # 能精确解析到新模块
# 若加了 select_skill 规则，另跑第 6 节的自然语言批量测试
```

24 项检查与新增模块最相关的对照（fail 时先查这些）：

| 检查项 | 触发 fail 的典型原因 |
|---|---|
| `*-skill-modules`（`security-skill-modules` / `github-re-workflow-modules` / `local-re-workflow-modules`） | 缺 `MODULE.md` / frontmatter 正则不过（name 与 description 之间插了字段） / 相对链接断链 |
| `reusable-skill-registry` | 漏登 `chinese-skill-names.json`（计数不符） / 描述是占位符 |
| `reusable-skill-resolver` | 模块名/中文名/路径无法被 `resolve_skill.ps1` 解析（通常因注册表漏登或模块名不符 kebab-case） |
| `cross-reference-completeness` | 漏登 INDEX / SKILL.md 列表 / unified-entry / 安全模块没被任何 P1 路由器链接（孤儿） / select 规则名打错 |
| `mandatory-final-feedback-contract` | 正文缺 5 个反馈契约 token 之一 |
| `chinese-skill-names` | 中文名未同步 |
| `reusable-skill-selector` / `fixed-reusable-entrypoint` / `reusable-route-regressions` | 新增/修改路由规则意外改变了固定回归用例的选择结果 |
| `manifest-paths` | 往 manifest 登记了不存在/绝对/越界的路径 |
| `powershell-syntax` / `python-syntax` / `bash-syntax` | 新增脚本语法错 |
| `installed-skill-sync` | 同步脚本缺失 / dry-run 返回非零退出码或非 JSON / 动作不是 `would-sync` 或 `no-op`（注意：`would-sync` 是预期动作，不代表失败） |
| `generated-caches` | warn 级别：提交前请删除 `__pycache__` / `.pytest_cache` |
| `bash-available` / `wsl-available` / `wpegpt-optional` | 环境可选项，缺失仅为 warn 不 fail；`wpegpt-optional` 的 fail 表示配置异常 |

**验证"新检查/新规则本身有效"时做可控阳性破坏测试**：临时删掉一条应触发检查的引用，跑 healthcheck 确认精确 FAIL 且报错点名该项，再改回复跑确认 PASS。只测"改完全绿"不能证明检查真的在正确位置生效。

---

## 10. 版本、发布与安装同步

入库合入后：

```powershell
.\scripts\package_release.ps1 -DryRun                          # 预览
.\scripts\package_release.ps1 -BumpVersion minor -ReleaseNotes "新增模块 <name>：..."
.\scripts\sync_installed_skill.ps1                             # healthcheck 通过后同步到已安装目录
```

### 10.1 版本号规则（必须遵守）

**每次更新完善，版本号必须自增一级，禁止在同版本号下继续提交。**

| 变更规模 | 版本号 | 示例 | 触发场景 |
|---|---|---|---|
| 小修（patch） | `x.y.z` → `x.y.(z+1)` | 1.24.1 → 1.24.2 | 纯修复、文档小改、CHANGELOG 补记 |
| 中改（minor） | `x.y.z` → `x.(y+1).0` | 1.24.2 → 1.25.0 | 新增模块、新增功能、新增路由规则 |
| **大规模更改（major）** | `x.y.z` → `(x+1).0.0` | 1.24.2 → **2.0.0** | **规范重写/新增多章、架构性调整、跨模块系统性变更、破坏性变更** |

判定标准：

- **大规模更改** = 满足以下任一条件：① 修改/新增了本规范（`module-onboarding-spec.md`）的**两个以上章节或一个完整大节**（如第 13/14 章）；② 同时新增/重构多个模块；③ 改变路由选择逻辑或注册表结构；④ 破坏既有模块兼容性的变更。
- 版本号升级后，`manifest.json` 与 `CHANGELOG.md` 必须同步更新（版本号一致），否则 `manifest` 检查 fail。
- 版本号只升不降，禁止回退。

---

## 11. 学习闭环 → 入库的关系（什么时候该建新模块）

不是每条新经验都要建模块。判定：

- **零散的方法/规则/失败模式/校验信号** → 走学习闭环，`record_skill_lesson.ps1` 入候选池 → `review_skill_lessons.ps1` 审查 → `promote_skill_lesson.ps1` 晋级到**最窄的既有模块或 reference**。不新建模块。
- **一个成体系的新工具 / 新平台 / 新方向**（有独立的触发场景、工具链、方法论，且现有模块都不合适容纳）→ 才按本规范建新模块入库。

先入候选池、经验证再晋级/建模块，避免把未验证的一次性技巧固化成模块。

---

## 12. 一页速查清单（Checklist）

新增一个内部模块，逐项打勾：

```text
□ 落点已定（github-reverse / local-reverse / security / references 其一）
□ 目录名 == MODULE.md name（kebab-case，[a-z0-9-]）
□ frontmatter：--- / name / description 三行紧邻，description 非占位符
□ 正文含 5 个反馈契约 token（local-reverse 建议同样加）
□ 跨文件登记按 5.A/5.B/5.C 全部完成（INDEX + SKILL.md 列表 + unified-entry + chinese-names）
□ 安全模块：已被至少一个 P1 路由器 Skill Map 链接（非孤儿）
□ 中文 display_name 以 suimi 开头，已入 chinese-skill-names.json
□ （可选）select_skill 规则：Unicode 核对 + 宽松间隔 + 名字真实 + 自然语言批量测 + 回归用例
□ 模块脚本放模块自己的 scripts/，未污染根 scripts/
□ 逆向技术内容完整性：AOB/算法/寄存器/协议字段/公开 URL 原文保留，仅凭据类脱敏（见 13.1/13.2）
□ 含外部快照/官方 skills 副本：按 13.4 验收（条目数/URL 缺失率/截断标记）+ 13.5 五步收录法
□ 提交前删除 __pycache__ / .pytest_cache（generated-caches warn 清零）
□ healthcheck.ps1 = 0 fail
□ list_skills / resolve_skill 能查到；（加了规则则）select_skill 自然语言命中
□ manifest 版本自增 + CHANGELOG 追加 + sync_installed_skill 实际执行 + diff 验证无差异
```

退役模块：反向执行 5.x 的每一处登记 + 删 chinese-names 条目 + 删 select 规则（若有），再跑 healthcheck 确认计数与交叉引用重新一致。

---

## 13. 逆向内容完整性与脱敏边界（必须遵守）

**总原则：逆向技术内容一律不脱敏、不占位符化、不删减。** 本包是逆向工程技能库，其价值就在技术细节的完整性；脱敏只适用于真实凭据与私有基础设施，绝不适用于逆向分析成果本身。

### 13.1 绝不脱敏的逆向内容（白名单）

以下内容必须**原文完整保留**，任何情况下不得替换为占位符、不得删减、不得改写为泛化描述：

- **字节与代码**：AOB/字节序列、opcode、指令、shellcode、反汇编、汇编片段、patch 字节。
- **算法与结构**：加密/哈希/校验算法实现、寄存器使用、函数签名、结构体偏移、RTTI/虚表布局、内存布局。
- **协议与接口**：协议字段名、API 名、消息格式、请求/响应结构、字段偏移与长度。
- **公开资源引用**：公开仓库 URL、公开工具名、公开论文/文档链接、开源项目名（用户已确认的公开快照中的 URL 一律保留原文）。
- **方法与流程**：逆向步骤、hook 点、断点位置、绕过思路、工具链用法、失败模式。

### 13.2 必须脱敏的内容（黑名单，遵循根目录 AGENTS.md 的 PI-MANAGER-SENSITIVE）

仅以下内容使用占位符（如 `example.com`、`<REDACTED>`）：

- 真实凭据：API Key、Token、密码、私钥、Session、Cookie。
- 私有基础设施：私有服务器地址/域名、内网 IP、个人/企业私有 URL、云平台真实 endpoint。
- 个人数据：用户真实姓名、邮箱、手机号、身份证等。

### 13.3 判定标准（拿不准时用这条）

> **公开可达、为分析目标服务的技术事实 → 保留原文；非公开、可用于直接访问私有系统的凭据类信息 → 占位符。**

- 快照/索引中的 URL：属于公开仓库、公开工具、公开论文 → 保留；属于私有基础设施 → 占位符。
- 逆向出的算法/字节/结构 → 永远保留（即使目标本身是私有系统，其技术事实也必须完整记录）。
- 分析过程中抓到的真实 token/密钥 → 占位符（技术方法保留，凭据值替换）。

### 13.4 内容完整性验收（入库前必做）

每次从外部仓库接入内容（快照、官方 skills 副本、文档全文）后，跑一遍完整性验收：

1. **条目数核对**：快照条目数 == 解析时统计数（如 4231 条），缺失即失败。
2. **URL 缺失率**：快照中 URL 缺失数必须为 0（`desc` 缺失允许，URL 缺失不允许）。
3. **截断标记检查**：全文 grep `TRUNCATED` / `[...省略...]` 等截断标记，必须为 0（代码示例中的 `...` 省略号除外）。
4. **文件规模对比**：收录副本行数/字节数与源文件一致（±2% 以内视为正常）。
5. **frontmatter 保留**：外部内容若自带 frontmatter（name/description），保留原文（许可证/来源标注不得删除）。

### 13.5 官方 skills 完整收录法（外部仓库自带 AI Agent skills）

当外部仓库自带 `.claude/skills/`、`SKILL.md` 等官方 AI Agent 技能时，按以下五步完整收录为所属模块的 `references/official-skills/` 本地副本（见 `game-security-research` 模块范例，10 个官方技能全量收录）：

1. **重命名**：`<skill-name>.md`（**禁止保留 `SKILL.md` 文件名**——`single-installable-skill` 强制全仓只允许根目录一个 SKILL.md，保留会 fail）。
2. **改写跨文件链接**：文档内的 `](../xxx/SKILL.md)` 改为指向本地同目录文件的相对链接（如 `research-rigor.md`）——healthcheck 会校验所有 `.md` 的 `../.../SKILL.md` 链接可达，不改会断链 fail。
3. **保留元数据**：frontmatter、许可证声明、来源标注原样保留。
4. **manifest 登记**：在 `manifest.json` 的 `references` 数组逐一登记（`manifest-paths` 检查只验证路径存在）。
5. **不注册为可路由技能**：不进 `chinese-skill-names.json`、不建 select 规则、不复制为模块——只经所属模块的 `MODULE.md` 索引表触达（避免重复建模块与计数不符）。

---

## 14. 内容完整性与同步验收（入库收尾）

除第 9 节门禁外，入库收尾还应完成：

1. **完整性审计**（针对含快照/外部副本的模块）：按第 13.4 节跑验收脚本。
2. **同步确认**：`sync_installed_skill.ps1` 实际执行（不是 dry-run），然后 `diff -rq` 对比源与已安装目录确认无差异；healthcheck 的 `installed-skill-sync` 项 dry-run 输出 `would-sync` 是**预期动作**（表示"检测到可同步"），不是失败；真正的验收是实际同步后 diff 为零。
3. **缓存清理**：提交前删除 `__pycache__` / `.pytest_cache`（`generated-caches` 检查为 warn 级别，但应清零以保持仓库干净）。

### 14.5 规范自身变更流程（本文件怎么改）

本规范（`module-onboarding-spec.md`）本身也是仓库的一部分，改它同样要走门禁，防止"规范与检查脱节"：

1. **变更前**：先做覆盖矩阵审计——拉出 `scripts/healthcheck.ps1` 全部检查项（`grep -oE "suimiNew-Check -Name '[a-z-]+'"`），与规范逐项对比，确认这次变更要补的缺口确实存在（不重复补已有内容）。
2. **变更后立即验证**：
   - `powershell -ExecutionPolicy Bypass -File scripts/healthcheck.ps1` 必须 24/24 PASS、0 FAIL；若新增了会影响选择结果的条款，同时跑 `tests/routing.Tests.ps1` 确认回归用例仍通过。
   - **编码检查**：中文规范文件必须是 UTF-8 with BOM（`python -c "open('references/module-onboarding-spec.md','rb').read(3)"` 应返回 `b'\xef\xbb\xbf'`）——编辑器/脚本改写后 BOM 可能丢失，丢失会导致 PowerShell 5.1 读取中文乱码。
   - **结构检查**：新增小节编号连续、`## Promoted Learning Notes` 区在文末且引用行（`- source: ...`）与 inbox 的 promoted 状态一致。
3. **版本与发布**：按第 10.1 节版本号规则——文档小改为 `patch`，新增功能/模块为 `minor`，**规范重写/新增完整大节（两个以上章节）为 `major`**；`CHANGELOG.md` 追加条目说明改了哪一节、补了什么缺口。
4. **学习闭环**：若变更本身是验证过的方法，按第 11 节 record → promote 到本规范的 Promoted Learning Notes 区（形成"经验 → 规范 → 新经验"的正循环）。
5. **同步**：`sync_installed_skill.ps1` 实际执行 + `diff -rq` 验证。

## Promoted Learning Notes

### 把新增模块的多处跨文件登记固化成入库规范并与 healthcheck 逐项对齐

- source: `20260824-195226-把新增模块的多处跨文件登记固化成入库规范并与-healthcheck-逐项对齐`
- category: tooling
- applies_to: 给 reverse-engineering-workflow 新增或退役内部模块及 references 文档时
- purpose_zh: 用单一权威入库规范替代每次靠人工回查跨文件登记，杜绝孤儿模块、注册表计数不符、中文名不同步
- confidence: 4/5

**Lesson**

当一个 skill 包反复踩新增模块要同步多处登记的坑时，正解不是每次人工回查，而是先读 healthcheck 的 cross-reference-completeness 等检查把它强制的所有登记点列全，按落点 github/local/security/references 分别写死登记清单，固化成一份 references 入库规范文档并与每一项 healthcheck 检查逐条对齐附一页 checklist；规范文档本身也要按规范登记到 SKILL.md 与 manifest 但不能进 chinese-skill-names 以免 registry 计数不符，最后用 healthcheck 0 fail 验证

**Evidence**

本包 inbox 已有 4 条关于新增模块需同步 select_skill 规则与跨文件审计的经验；cross-reference-completeness 检查精确定义了 5 类登记点；落地 references/module-onboarding-spec.md 并加 SKILL.md Choose References 与 manifest.references 两处登记后，healthcheck 24 项 0 fail，reusable-skill-registry 仍为 61 证明 references 文档未被误计为技能，manifest-paths 由 57 增至 58

**Validation**

scripts/healthcheck.ps1 全量 24 项零 fail；list_skills 注册表计数未变仍为 61

### sidecar orchestrator 模块族导入法：orchestrator 注册为 P1 路由器

- source: `20260825-051530-sidecar-orchestrator-模块族导入法-orchestrator-注册为-p1`
- category: method
- applies_to: module merge / module family import
- purpose_zh: 侧车模块族（orchestrator + 41 个 downstream 专精）导入本地时，把 orchestrator 注册为 P1 路由器（加入 healthcheck.ps1 的 routers 与 new_module.ps1 的 routerNames），并在其 MODULE.md 加 Core Skill Map 链接全部下游模块，即可让整族通过 orphan 检查，无需逐个链接旧 P1。
- confidence: 4/5

**Lesson**

导入外部 sidecar 模块族时，先识别族内默认入口（orchestrator），将其注册为本地 P1 路由器并链接全部 downstream 模块，整族一次通过 orphan 与 cross-reference 检查。

**Evidence**

CTF-Sandbox-Orchestrator 42 模块导入：ctf-sandbox-orchestrator 加入 routers 后 healthcheck 24/24 PASS，chinese-skill-names 138 条 0 missing，select_skill 实测 CTF 任务正确路由 conf=0.9。

**Validation**

healthcheck 24/24 PASS；unit-tests 22/22 PASS；select_skill CTF 路由 conf=0.9

### 双基准diff验证法-外部本地文件树对比

- source: `20260825-063345-双基准diff验证法-外部本地文件树对比`
- category: method
- applies_to: module merge / file integrity verification
- purpose_zh: 外部模块导入后，用 find | sort | diff 双基准对比文件树，确保零丢失导入
- confidence: 4/5

**Lesson**

导入外部模块后，用 diff <(find REPO -type f | sort) <(find LOCAL -type f | sort) 对比文件树，精确确认迁移零丢失（114=114），比目录数对比可靠得多。

**Evidence**

在外部 pentest-tools 导入验证中，用 find | sort | diff 对比外部 114 文件和本地 114 文件，差异仅为 2 个合规改名（SKILL.md→MODULE.md, src-hunter/SKILL.md→src-hunter.md），确认零丢失。

**Validation**

文件数 114=114 一致，healthcheck 24/24 PASS，unit-tests 22/22 PASS。

### new_module.ps1 的 [appended] 输出不可信，注册必须经 healthcheck 交叉验证

- source: `20260825-074942-new-module-ps1-的-appended-输出不可信-注册必须经-healthchec`
- category: tooling
- applies_to: module-onboarding, healthcheck, registry
- purpose_zh: new_module.ps1 宣称已追加注册（unified-skills-entry.md/INDEX.md/SKILL.md/chinese-skill-names.json），实际多次未写入；必须以 healthcheck 的 cross-reference-completeness 与 chinese-skill-names 检查为准，缺了就手动补齐
- confidence: 3/5

**Lesson**

规则：任何 new_module.ps1 执行后，先跑 scripts/healthcheck.ps1 确认 cross-reference-completeness PASS 再继续；若 FAIL 按报告逐文件补注册行，补完重跑至 PASS 才可发布

**Evidence**

3 个新模块经 new_module.ps1 创建后均报 [appended]，但 package_release 健康门禁 FAIL 列出 3 处缺失（unified-skills-entry.md/INDEX.md/SKILL.md），手动补齐 4 文件后 PASS

**Validation**

手动补齐 chinese-skill-names.json 3 条 + unified-skills-entry.md 3 行 + INDEX.md 3 块 + SKILL.md 3 行后，healthcheck 25/25 PASS，manifest 1.23.2 发布成功

### awesome-* 大仓库三层接入：主入口MODULE+离线快照JSON+分类索引表

- source: `20260825-094952-awesome-大仓库三层接入-主入口module-离线快照json-分类索引表`
- category: method
- applies_to: general reverse workflow
- purpose_zh: 外部 awesome-* 类大目录仓库接入本地 skills 时的固定做法
- confidence: 3/5

**Lesson**

接入体量大、条目多、分类稳定的 awesome-* 仓库时，不要克隆全文或把条目塞进 bootstrap-manifest 自动安装；按三层接入：建主入口 MODULE.md（含安全边界+完整分类索引表）+ 本地离线快照 references/*-snapshot.json（解析 README 的 ## 分类 / > 子分类 / - url [desc] 结构为 JSON）+ 官方 skills 主题映射表；写中文 MODULE.md 后必须转 UTF-8 with BOM，否则 PowerShell 5.1 Get-Content 读取乱码导致 mandatory-final-feedback-contract 中文 token 检查 FAIL

**Evidence**

gmh5225/awesome-game-security 54091 文件/4231 条目接入：README 358KB 解析为 550KB 快照 JSON，官方 10 技能主题对照本地既有模块避免重复建模块；healthcheck 24/24 PASS，registry 143 条，resolve_skill 按机器名和中文名均命中

**Validation**

2026-08-25 实践验证：game-security-research 模块按三层接入成功入库，healthcheck 24/24 PASS（含 BOM 修复前后对比：无 BOM 时 mandatory-final-feedback-contract FAIL，加 BOM 后 PASS），resolve_skill 按机器名与中文名均命中，sync_installed_skill 同步成功。

### 新增目录型模块必须同步补路由规则

- source: `20260825-101848-新增目录型模块必须同步补路由规则`
- category: method
- applies_to: general reverse workflow
- purpose_zh: 防止新增模块入库后统一入口无法命中
- confidence: 3/5

**Lesson**

新增模块入库（MODULE.md + 4 处登记 + healthcheck）后，必须同步在 scripts/routing-rules.json 登记路由规则：pattern 需同时含中英文关键词，confidence 应低于具体工具类规则（如 ce-reverse 0.89、x64dbg 0.89）且高于 generic 规则（reverse-engineering 0.68），保证工具任务优先走工具模块、研究/目录任务走新模块；登记后必须回归 select_skill 多组测试用例并重跑 healthcheck（cross-reference-completeness 校验规则 refs 与 registry 一致性）

**Evidence**

game-security-research 模块初入库时未加规则，'游戏反作弊资料'任务回落到 generic reverse-engineering；补规则（confidence 0.86，37 条规则）后 3 组研究任务命中 game-security-research，'cheat engine 扫描内存'仍正确命中 ce-reverse，healthcheck 24/24 PASS

**Validation**

2026-08-25 实践验证：game-security-research 模块补路由规则前后对比——无规则时 select_skill 对'游戏反作弊资料'回落到 generic reverse-engineering（confidence 0.68），补规则后命中 game-security-research（0.86）；4 组回归用例全部符合预期，healthcheck 24/24 PASS（cross-reference-completeness 确认 37 条规则 refs 与 registry 一致），sync_installed_skill 同步成功。

### 路由规则必须同步补回归用例且合规审计不能只看healthcheck

- source: `20260825-105122-路由规则必须同步补回归用例且合规审计不能只看healthcheck`
- category: method
- applies_to: general reverse workflow
- purpose_zh: 新增路由规则后补 tests 回归用例，以及健康检查 0 fail 不等于完全合规
- confidence: 3/5

**Lesson**

1) 新增/修改 routing-rules.json 规则后，必须同步给 tests/routing.Tests.ps1 补回归用例（正向命中 + 既有工具模块对照不抢占各一条），否则规范第 6 节不达标，healthcheck 不会自动发现（它只跑既有用例）；2) 用户询问是否符合规范时，healthcheck 0 fail 是必要条件但不是完备证据，需按 module-onboarding-spec.md 第 12 节 checklist 逐项人工核验 + 抽查快照/官方副本/安全边界，才能发现 healthcheck 覆盖不到的缺口

**Evidence**

game-security-research 入库后 healthcheck 24/24 PASS 但 tests/routing.Tests.ps1 无该模块用例；按规范补齐 2 条用例后 Pester 15/15 通过，healthcheck unit-tests 25→27；规范符合性审计据此发现并修复了唯一缺口

**Validation**

2026-08-25 实践验证：game-security-research 模块规范符合性审计中发现 tests/routing.Tests.ps1 缺失回归用例（healthcheck 当时 24/24 PASS 未报）；补齐 2 条用例（正向 game-security-research + 对照 ce-reverse 不抢占）后 Pester 15/15 通过、healthcheck unit-tests 25→27、24/24 PASS；证明"healthcheck 0 fail ≠ 完全合规"，需按 checklist 人工核验。

### 入库规范必须含逆向内容完整性与脱敏边界章节

- source: `20260825-110824-入库规范必须含逆向内容完整性与脱敏边界章节`
- category: method
- applies_to: general reverse workflow
- purpose_zh: 规范健康检查覆盖不等于规范完整；逆向内容不脱敏、仅凭据脱敏；官方skills五步收录法
- confidence: 3/5

**Lesson**

1) 入库规范完整性审计方法：拉出 healthcheck 全部检查项做覆盖矩阵，找 0 覆盖项（本次发现 generated-caches/installed-sync/resolver 未入表）与主题缺口（脱敏边界完全缺失）；2) 逆向内容完整性原则：AOB/算法/寄存器/协议字段/公开仓库 URL 一律原文保留，只有真实凭据（API Key/Token/私钥/私有域名/内网IP）用占位符，判定标准是'公开可达的技术事实保留、非公开凭据脱敏'；3) 外部仓库自带官方 AI skills 的完整收录法：重命名 .md（禁保留 SKILL.md 防 single-installable 冲突）+ 改写 ../xxx/SKILL.md 相对链接 + 保留 frontmatter/许可证 + manifest 登记 + 不注册为可路由技能；4) 内容完整性验收：条目数核对、URL 缺失率必须 0、TRUNCATED 截断标记必须 0（代码示例省略号除外）

**Evidence**

规范审计发现 24 项检查中 4 项（reusable-skill-resolver/installed-skill-sync/generated-caches/环境可选）在规范第 9 节检查表无对应行，且全文无'脱敏/内容完整性'主题；本次新增规范第 13 节（逆向内容完整性与脱敏边界，白名单/黑名单/判定标准/完整性验收/官方skills五步收录法）与第 14 节（内容完整性与同步验收）；game-security-research 快照 4231 条目 0 缺 URL、官方 10 skills 完整无损（TRUNCATED=0）验证了验收方法

**Validation**

2026-08-25 实践验证：对 module-onboarding-spec.md 做覆盖矩阵审计，发现 4 项检查未入表 + 脱敏边界主题完全缺失；新增第 13/14 节后 healthcheck 24/24 PASS、0 FAIL；对照 game-security-research 快照（4231 条目 0 缺 URL）与官方 10 skills（无 TRUNCATED 标记）验证验收方法可行；该审计法此前已两次发现 healthcheck 覆盖不到的缺口（路由回归用例缺失），证明"healthcheck 全绿 ≠ 规范完整"。