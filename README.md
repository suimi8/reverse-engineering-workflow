# suimi 逆向总入口（reverse-engineering-workflow）

由 suimi 支持的本地授权逆向工程技能包：单一可安装入口 + 自动路由 + 分层内部模块 + 学习闭环。适用于 PE/ELF/APK/固件/沙箱应用的静态与动态分析、运行时诊断、Frida/IDA/x64dbg/Ghidra/WPeGPT 工作流、GUI/网络/认证/更新流程分析、补丁与可逆打包，以及逆向暴露出的 Web/API/Auth 安全评估面。

## 安装与使用

本技能包只有一个可安装入口：根目录 `SKILL.md`。内部 `MODULE.md` 均由入口自动路由加载，不单独安装。

```powershell
# 1. 校验技能包完整性
.\scripts\healthcheck.ps1

# 2. 运行自动化单元测试（Pester）
.\tests\run_tests.ps1

# 3. 自动路由：根据任务文本选择最合适的内部模块
.\scripts\invoke_skill.ps1 -TaskText "<目标>" -TargetPath "<目标路径>" -AsJson

# 4. 查看全部内部模块注册表 / 解析单个模块
.\scripts\list_skills.ps1 -AsJson
.\scripts\resolve_skill.ps1 -Query "mobile-reverse" -AsJson
```

Agent 触发逆向任务时自动运行第 3 步，无需用户手动调用。任务结束后按 `references/skill-learning-loop.md` 记录经验并输出 `新技能/方法反馈`。

## 目录结构

| 路径 | 作用 |
|---|---|
| `SKILL.md` | 唯一可安装入口与路由器（先读这里） |
| `references/` | 方法论文档：静态/动态分析、脱壳、Frida、APK、PE 补丁、任务配方等 |
| `scripts/` | PowerShell/Python/Bash/JS 工具脚本（路由、探针、补丁模板、学习闭环） |
| `github-reverse-modules/` | 上游导入的通用逆向模块（radare2/IDA/APK/移动端/binary-diff/方法论） |
| `local-reverse-modules/` | 本地 Windows 专项（Flet 诊断、Python 程序恢复、服务自启动） |
| `security-research-modules/` | 可选 Web/API/Auth 安全研究模块（逆向暴露攻击面时加载） |
| `tests/` | Pester 单元测试（路由、学习闭环、发布工具） |
| `config/config.ini` | WPeGPT/IDA 可选自动化配置（缺省时自动降级为常规分析） |
| `manifest.json` | 技能包元数据（入口、引用、脚本清单、版本） |

## 核心工作纪律

- 证据优先级：运行时 → 流量 → 静态资产 → 配置 → 持久化状态 → 产物 → 源码 → 注释。
- 先基线后补丁；一次只改一个变量；可逆运行时探针优先于持久补丁；保留回滚材料。
- 只处理本地、沙箱、自有或明确授权的目标。

## 发布流程

编辑技能包后，用自动化脚本打包发布（先跑健康检查，可选版本自增与 CHANGELOG 记录）：

```powershell
.\scripts\package_release.ps1 -DryRun                     # 预览
.\scripts\package_release.ps1 -BumpVersion patch          # 打补丁版并重新打包 zip
.\scripts\package_release.ps1 -BumpVersion minor -ReleaseNotes "新模块：..." # 完整发布
```

## 学习闭环

新方法先入候选池（`references/skill-learning-inbox.md`），经审查、验证后晋级到最窄的内部模块：

```powershell
.\scripts\record_skill_lesson.ps1 -Title "<经验>" -PurposeZh "<中文作用>" -Lesson "<规则>" -Evidence "<证据>"
.\scripts\pending_skill_lessons.ps1
.\scripts\review_skill_lessons.ps1 -Status candidate
.\scripts\promote_skill_lesson.ps1 -Id "<id>" -DestinationPath "<目标.md>"
```

详见 `references/unified-skills-entry.md`（统一中文技能目录）与 `references/skill-learning-loop.md`。
