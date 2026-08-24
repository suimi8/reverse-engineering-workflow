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
- **体量大、条目多、有稳定分类字段、依赖不稳定外部网络**的工具目录（如 awesome-* 类）→ 走"三层接入"：主入口 `MODULE.md` + 本地全量快照（`references/*-snapshot.json`）+ 正文内嵌完整分类索引表。**禁止**把几百个混有 C2/RAT/钓鱼套件的 meta-installer 写进 `bootstrap-manifest.json` 自动装，只做只读目录记录用法与安全边界。

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
| `*-skill-modules` | 缺 `MODULE.md` / frontmatter 正则不过（name 与 description 之间插了字段） / 相对链接断链 |
| `reusable-skill-registry` | 漏登 `chinese-skill-names.json`（计数不符） / 描述是占位符 |
| `cross-reference-completeness` | 漏登 INDEX / SKILL.md 列表 / unified-entry / 安全模块没被任何 P1 路由器链接（孤儿） / select 规则名打错 |
| `mandatory-final-feedback-contract` | 正文缺 5 个反馈契约 token 之一 |
| `chinese-skill-names` | 中文名未同步 |
| `reusable-skill-selector` / `fixed-reusable-entrypoint` / `reusable-route-regressions` | 新增/修改路由规则意外改变了固定回归用例的选择结果 |
| `manifest-paths` | 往 manifest 登记了不存在/绝对/越界的路径 |
| `powershell-syntax` / `python-syntax` / `bash-syntax` | 新增脚本语法错 |

**验证"新检查/新规则本身有效"时做可控阳性破坏测试**：临时删掉一条应触发检查的引用，跑 healthcheck 确认精确 FAIL 且报错点名该项，再改回复跑确认 PASS。只测"改完全绿"不能证明检查真的在正确位置生效。

---

## 10. 版本、发布与安装同步

入库合入后：

```powershell
.\scripts\package_release.ps1 -DryRun                          # 预览
.\scripts\package_release.ps1 -BumpVersion minor -ReleaseNotes "新增模块 <name>：..."
.\scripts\sync_installed_skill.ps1                             # healthcheck 通过后同步到已安装目录
```

- 破坏性/新增模块用 `minor`，纯修复用 `patch`；版本号与 `manifest.json` 保持一致。
- `CHANGELOG.md` 追加条目（`package_release.ps1` 可自动追加）。

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
□ healthcheck.ps1 = 0 fail
□ list_skills / resolve_skill 能查到；（加了规则则）select_skill 自然语言命中
□ manifest 版本自增 + CHANGELOG 追加 + sync_installed_skill
```

退役模块：反向执行 5.x 的每一处登记 + 删 chinese-names 条目 + 删 select 规则（若有），再跑 healthcheck 确认计数与交叉引用重新一致。

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
- applies_to: upstream skill merge / module family import
- purpose_zh: 上游仓库的侧车模块族（orchestrator + 41 个 downstream 专精）导入本地时，把 orchestrator 注册为 P1 路由器（加入 healthcheck.ps1 的 routers 与 new_module.ps1 的 routerNames），并在其 MODULE.md 加 Core Skill Map 链接全部下游模块，即可让整族通过 orphan 检查，无需逐个链接旧 P1。
- confidence: 4/5

**Lesson**

导入 upstream sidecar 模块族时，先识别族内默认入口（orchestrator），将其注册为本地 P1 路由器并链接全部 downstream 模块，整族一次通过 orphan 与 cross-reference 检查。

**Evidence**

reverse-skill v1.0.1 CTF-Sandbox-Orchestrator 42 模块导入：ctf-sandbox-orchestrator 加入 routers 后 healthcheck 24/24 PASS，chinese-skill-names 138 条 0 missing，select_skill 实测 CTF 任务正确路由 conf=0.9。

**Validation**

healthcheck 24/24 PASS；unit-tests 22/22 PASS；select_skill CTF 路由 conf=0.9

### 双基准diff验证法-上游本地文件树对比

- source: `20260825-063345-双基准diff验证法-上游本地文件树对比`
- category: method
- applies_to: upstream skill merge / file integrity verification
- purpose_zh: 上游模块导入后，用 find | sort | diff 双基准对比文件树，确保零丢失导入
- confidence: 4/5

**Lesson**

导入上游模块后，用 diff <(find REPO -type f | sort) <(find LOCAL -type f | sort) 对比文件树，精确确认迁移零丢失（114=114），比目录数对比可靠得多。

**Evidence**

在上游 pentest-tools 导入验证中，用 find | sort | diff 对比上游 114 文件和本地 114 文件，差异仅为 2 个合规改名（SKILL.md→MODULE.md, src-hunter/SKILL.md→src-hunter.md），确认零丢失。

**Validation**

文件数 114=114 一致，healthcheck 24/24 PASS，unit-tests 22/22 PASS。