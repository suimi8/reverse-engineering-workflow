---
name: ghidra-reverse
description: Use for free/open reverse engineering with Ghidra (headless or GUI), including decompile, cross-refs, and optional Ghidra MCP workflows when IDA is unavailable.
---


中文名：suimi Ghidra 逆向

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# Ghidra Reverse Engineering

## 适用场景

- 无 IDA 许可证时的主逆向入口
- 批量 headless 分析 / CI 中反编译
- Ghidra 脚本（Java/Python Jython/PyGhidra）自动化
- 与 `binary-diff` / `patch-diff-exploit` 的 ghidriff 联动

## 与 IDA 分工

| 需求 | 优先 |
|------|------|
| 已有 IDA MCP 深挖 | `ida-reverse/` |
| 开源 / 批量 / 教学 | **本 skill** |
| 仅 CLI 快速侦察 | `radare2/` |

## 工作流

### 1. 项目与自动分析

```text
□ 新建 Project → Import 文件 → Analyze（默认分析器）
□ 记录语言/编译器识别结果与基址
□ 标记入口、导出表、字符串 xref
```

### 2. 关键函数

```text
□ 从字符串 / 导入 API 反查
□ Decompile 窗口还原算法
□ 重命名函数/变量；写 Plate comment
□ 需要动态时交接 Frida/GDB（reverse-engineering 动态章）
```

### 3. Headless（批量）

```bash
# 示例：analyzeHeadless 路径因安装而异，MUST 从 tool-index 取
analyzeHeadless /path/to/project Proj -import sample.bin -postScript ExportDecomp.py
```

### 4. MCP（若已配置）

```text
□ 确认 ghidra MCP 端口（常见 8765，以 tool-index 为准）
□ 用 MCP 工具拉反编译 / xrefs，禁止猜端口
```

## 装载与自动分析详解

Ghidra 以「Project(.gpr) + CodeBrowser」为核心：建工程 → 导入文件 → Auto Analyzer。

```text
□ File → New Project(Non-Shared)；File → Import File 加载样本
□ 导入对话框确认 Format / Language(processor:endian:size:variant) / 编译器规范；
  识别不准时手动指定（如 x86:LE:64:default、gcc/windows）
□ 双击进入 CodeBrowser，接受默认 Analyzers 或按需勾选：
  Decompiler Parameter ID（恢复参数）、Stack、Data Reference、ASCII Strings；
  Aggressive Instruction Finder 噪声大，慎用
□ 记录 Image Base、入口（Symbol Tree → Exports/entry）
□ Window → Memory Map 看段/权限/基址；Window → Bytes 看原始字节
```

分析幂等：改选项后 Analysis → One Shot / Re-analyze 可局部重跑，无需重导。

## 反编译窗口工作流

Decompiler 是 Ghidra 相对 IDA 的核心免费能力，双击函数即出 C 伪代码，伪代码与反汇编联动高亮（同色=同变量/同址）。

```text
□ 起点：Symbol Tree/Functions 或 Window → Defined Strings 的字符串 xref
□ 重命名符号 L；改变量类型(retype) Ctrl+L；编辑函数签名 F
□ 反汇编视图：F 强制成函数，C 清除，D 反汇编纠错
□ 交叉引用：右键 → References → Show References to
□ 用 ; 写行注释、Plate Comment 写函数级说明，边读边固化结论
```

判读：undefined8 / uVar 是未定型占位，恢复正确类型后可读性大幅提升。

## 数据类型与结构体

复杂样本的收益点是恢复结构体，让反编译「说人话」。

```text
□ Data Type Manager(DTM) 管理内置 / 样本自带 / 导入(.gdt) 类型
□ 新建结构体：DTM 右键 New → Structure，按偏移填字段
□ Auto Create Structure：在反编译变量上右键，依访问模式([reg+off]) 自动推断字段
□ 变量上 Ctrl+L 应用结构体指针，字段随即显示为 ->field
□ File → Parse C Source 批量导入头文件里的 struct/typedef
```

## 脚本与无头（analyzeHeadless）

GUI 之外支持 Java、Python(Jython) 脚本与 PyGhidra(CPython3)。脚本 API 常用入口对象：currentProgram / getFunctionManager / DecompInterface。

```bash
# 导入并分析，跑后处理脚本导出反编译
analyzeHeadless /proj ProjName -import ./sample.bin -postScript ExportDecomp.py
# 处理已存在程序（不重导），只跑脚本
analyzeHeadless /proj ProjName -process 'sample.bin' -noanalysis -postScript Dump.py
# 递归导入目录 + 自定义脚本目录 + 覆盖同名
analyzeHeadless /proj ProjName -import /samples -recursive -scriptPath /my/scripts -overwrite -postScript Batch.java
```

常用参数：-import / -process / -preScript / -postScript / -scriptPath / -noanalysis / -overwrite / -recursive / -readOnly / -max-cpu。Windows 用 analyzeHeadless.bat，路径取自 tool-index。

## 版本追踪与函数比对

跨版本/补丁分析用自带能力，无需商业工具：

```text
□ Version Tracking：对两个已分析程序建 Session，用 Exact Bytes /
  Function Instructions / Symbol Name 等 correlator 配对函数，
  再把旧版本的符号名、注释迁移到新版本
□ BSim：基于反编译特征的相似函数搜索，可跨样本找同源函数
□ 需成品差分报告 → 交接 ghidriff（无头驱动 Ghidra 产出 md/HTML diff）
```

## 工具链

| 工具 | 用途 | 自举 |
|------|------|------|
| Ghidra | 反编译主工具 | 手动 release / 包管理器 |
| ghidra-mcp | AI 桥 | bootstrap 能力名 `ghidra-mcp` |
| ghidriff | 补丁差分 | 见 `patch-diff-exploit` |

## 常用命令与快捷键速查

| 目的 | 操作（默认） |
|------|--------------|
| 反编译函数 | 双击 / Decompile 窗口 |
| 重命名符号 | L |
| 变量 retype | Ctrl+L |
| 编辑函数签名 | F |
| 定义 / 清除代码 | D / C |
| 行注释 / 函数注释 | ; / Plate Comment |
| 交叉引用 | 右键 → References |
| 跳转地址 / 标签 | G |
| 搜索字符串 | Search → For Strings |
| 搜索字节 / 指令模式 | Search → Memory / For Instruction Patterns |
| 脚本管理器 | Window → Script Manager |
| 内存布局 / 段权限 | Window → Memory Map |

## 证据与回滚

- 分析只写工程库：重命名 / 注释 / 类型全部保存在 .gpr，**不修改原始二进制**。
- 导出成果用 File → Export Program 另存，或用脚本导出反编译文本 / C，不覆盖样本。
- 完整性基线：导入前留样本 sha256（`rahash2 -a sha256` 或 `shasum -a 256`）。
- 若 Export 生成打补丁二进制，另存新文件名并配合 `radiff2` / ghidriff 记录 diff。
- 结论留痕：语言/编译器识别、Image Base、关键函数地址与重命名映射、字符串→调用点引用链，保证可复现。

## 参考

- `references/ghidra-cheatsheet.md`
- `../ida-reverse/` `../radare2/` `../binary-diff/`

## 路由上下文

**上游**: MASTER R22  
**下游**: 动态验证 → Frida/GDB；利用 → `pwn-chain`  
**同级**: `ida-reverse`（商业深挖）

## 任务完成自检

- [ ] 是否基于真实 Ghidra/tool-index 路径？
- [ ] 是否标注函数地址与重命名？
- [ ] 是否有可复现步骤？
- [ ] Checklist / journal？