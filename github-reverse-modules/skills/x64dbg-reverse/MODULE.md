---
name: x64dbg-reverse
description: |
  x64dbg 动态调试与逆向辅助技能。当用户提到 x64dbg、Windows PE 可执行文件动态调试、断点跟踪、内存读写/patch、脱壳、找 OEP、注册码/序列号动态验证分析、句柄/线程/调用栈观察，或需要在运行时观察一个 exe/dll 的实际行为时，务必使用此技能。

  Ensure to use this skill when the user wants to dynamically debug, trace, breakpoint, patch-in-memory, attach to a running process, or unpack a local Windows PE binary, regardless of whether they explicitly say "x64dbg". This includes requests like "帮我动态调试这个exe", "这个程序在哪里校验密码", "帮我下个断点看看参数", "这个是不是加壳了/帮我脱个壳", "附加到这个进程看看它在干什么" 等。

  Use the bundled scripts (scripts/install.ps1, scripts/status.ps1) for deterministic plugin installation and health checks — do NOT write ad-hoc PowerShell commands for these operations.
---


中文名：suimi x64dbg 动态调试
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# x64dbg 动态调试技能

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，并按需用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 维护学习闭环。

本模块基于 x64dbg 的 MCP 桥接插件 x64dbg-MCP-Server（Zig 编写，零依赖单文件插件），插件本体由 `scripts/install.ps1` 从官方 Release 自动下载部署。与 `ida-reverse` 的静态反编译定位不同，本模块专注于**运行时**证据：真实断点命中、真实寄存器/内存值、真实调用栈。

## 已知问题与反思（必读）

### 架构要点（不是 bug，是设计，先理解再用）

1. **这不是一个独立进程的 MCP server，而是 x64dbg 的原生插件**
   - `x64dbg-MCP-Server.dp64`/`.dp32` 随 x64dbg/x32dbg 进程启动而启动、随进程退出而消失
   - 没有类似 `start.ps1` 那种"独立拉起服务"的动作——必须先把 x64dbg 本体跑起来
   - 因此本模块的 `scripts/install.ps1` 只负责"部署插件 + 首次启动生成配置 + 注册 MCP"，不负责常驻服务管理

2. **端口固定按位数区分：x64 固定 9094，x32 固定 9095**
   - 与 IDA 的"多开端口递增"不同，x64dbg 是"架构区分端口"，两个不冲突，可以同时注册两个 MCP server（如需同时调试 32/64 位目标）
   - 默认监听地址是 `0.0.0.0` 而不是 `127.0.0.1`——同局域网设备理论上能连上（仍需 token），单机使用建议在插件配置对话框里改成 `127.0.0.1`

3. **鉴权 token 在首次运行后写入 `mcp_config.json`，与 x64dbg.exe 同目录**
   - 文件形如 `{"IpAddress":"0.0.0.0","Port":9094,"AutoStart":true,"AuthToken":"..."}`
   - 重启 x64dbg **不会**更换 token；只有在插件菜单的配置对话框里手动"重新生成"才会变，变更后插件自动重启生效
   - 一旦 token 变了，之前 `claude mcp add` 写入的 `Authorization: Bearer <old-token>` 就会全部 401，需要重新 `claude mcp remove` + `claude mcp add`（`scripts/install.ps1` 重跑一遍即可，脚本会用最新 token 覆盖注册）

4. **大多数工具标了 `debug_only`：必须先有调试会话**
   - 没有 `LoadBinary` 或 `AttachProcess` 建立会话之前，调用 `ReadMemory`/`Disassemble`/`SetBreakpoint` 等会直接报错
   - 判断是否已有会话，先调用不区分状态的 `GetDebugState`

5. **新注册的 MCP server 要新开一次 Claude Code 会话才能用**
   - 当场 `claude mcp add` 完之后，当前对话轮次的工具列表不会立刻刷新，工具还是调用不到
   - 不要在同一次会话里"注册完立刻假设能用"，如需验证请提醒用户开新会话，或用 `scripts/status.ps1` 先做 HTTP 层面的健康检查（不依赖工具是否已加载）

6. **`claude mcp add` 默认 `--scope local`，只在当前项目生效**
   - 想要"全局"（所有项目都能用）必须显式 `--scope user`
   - `scripts/install.ps1` 默认使用 `-Scope user`，按需可传 `-Scope local`

7. **x64dbg 本体不是这个仓库自带的，需要单独获取**
   - 官方快照下载在 `github-reverse-modules/skills/scripts/bootstrap-manifest.json` 的 `x64dbg` capability 里登记（`x64dbg/x64dbg` GitHub Release 的 `snapshot_*.zip`）
   - 官方快照 zip 解压后结构是 `release/x32/`、`release/x64/`，`release` 这一层文件夹本身才是插件 README 所说的"x64dbg 根目录"——`scripts/install.ps1` 会自动识别这层嵌套，也兼容已经手动拍平成 `<root>/x32/`、`<root>/x64/` 的布局
   - 本地找不到 x64dbg 时，`install.ps1` **不会静默安装**，默认只打印官方下载页/Releases 直链；只有显式传 `-AutoInstallX64dbg` 才会自动下载解压到 `-X64dbgInstallDir`（默认 `%USERPROFILE%\Tools\x64dbg`）——装一个完整 GUI 调试器比装插件动作更大，需要明确选择

8. **调用链上任何一环缺软件，脚本都不会只报错就退出**
   - x64dbg 本体缺失 → 打印 `https://x64dbg.com/` 官方页 + GitHub Releases 直链 + `-AutoInstallX64dbg` 自助安装提示
   - 插件 zip 下载失败（断网/限流）→ 打印 x64dbg-mcp-server 官方 Releases 页，可手动下载后把 `.dp32`/`.dp64` 直接放进 `plugins` 目录
   - `claude` 命令行缺失 → 打印 Windows 原生安装命令 `irm https://claude.ai/install.ps1 | iex`（免管理员、免 Node.js）和 `winget install Anthropic.ClaudeCode` 备选
   - 统一约定：`ERR:*` 之后紧跟的 `INFO:*_download_page`/`INFO:*_download_command` 行就是可执行的下一步，不用去翻文档

### 工作流程原则

| 步骤 | 做什么 | 用什么 |
|------|--------|--------|
| 1 | 确保 x64dbg 本体存在，插件已部署，MCP 已注册 | `scripts/install.ps1` |
| 2 | 确认端口在监听、token 有效、Claude 侧注册状态 | `scripts/status.ps1` |
| 3 | 建立调试会话（新开或附加） | `LoadBinary` / `AttachProcess` |
| 4 | 使用全部 71 个 MCP 工具做断点/内存/寄存器/模块分析 | 直接调用对应工具（见下方速查） |
| 5 | 分析完毕，需要时导出 dump/报告 | `DumpMemory` / `DumpModule` + 手写 `report.md` |

## 脚本资源

### install.ps1 — 部署插件并注册 MCP

路径：`scripts/install.ps1`

- 自动探测本机已安装的 x64dbg 根目录（兼容官方快照 `release/x32|x64` 嵌套布局与拍平布局），找不到则报错退出，不会静默瞎猜路径
- 从 x64dbg-mcp-server 官方 Release 下载插件 zip，解压后把 `x64dbg-MCP-Server.dp32`/`.dp64` 分别复制到 `x32\plugins\`、`x64\plugins\`（会自动创建 `plugins` 目录）
- 若 `mcp_config.json` 尚不存在，后台启动一次 x64dbg 触发插件生成配置，轮询等待文件出现（有超时，不会无限挂起）
- 读取生成的端口与 token，调用 `claude mcp add --transport http` 完成注册（已存在同名 server 会先 remove 再 add，保证 token 更新后能覆盖旧配置）
- 成功输出 `OK:<server-name>:<port>`，失败输出 `ERR:<reason>`

**调用方式**：
```powershell
# 全自动：自动探测 x64dbg、部署插件、注册为全局 MCP（server 名默认 x64dbg）
powershell -File "scripts\install.ps1"

# 显式指定 x64dbg 根目录（含 x32/x64 子目录，或含 release\x32/x64 的官方快照根）
powershell -File "scripts\install.ps1" -X64dbgDir "D:\x64dbg\release"

# 只想处理 32 位目标，注册到 x32 端口（9095），server 名自定义避免和 x64 冲突
powershell -File "scripts\install.ps1" -Arch x32 -McpServerName "x64dbg-x32"

# 只部署插件文件，不改 Claude 的 MCP 配置（比如已经手动注册过）
powershell -File "scripts\install.ps1" -SkipClaudeRegister

# 注册到项目级而不是全局
powershell -File "scripts\install.ps1" -Scope local
```

**输出约定**：
```
OK:x64dbg:9094          # 成功，server 名 x64dbg，监听 9094（x64）
ERR:x64dbg_not_found    # 没找到本机 x64dbg 安装，需要先装或显式传 -X64dbgDir
ERR:config_timeout      # 启动 x64dbg 后等不到 mcp_config.json 生成
ERR:claude_cli_missing  # 找不到 claude 命令行（跳过注册，仍会打印插件部署结果）
```

### status.ps1 — 健康检查

路径：`scripts/status.ps1`

- 检查 x32dbg.exe / x64dbg.exe 进程是否在跑
- 对 9094（x64）与 9095（x32）分别探测 HTTP 层连通性（拿到 401 也算"在监听"，因为说明服务已起来只是没带 token）
- 读取各自 `mcp_config.json` 里的 token/端口/绑定地址
- 调用 `claude mcp get <server-name>` 汇报 Claude 侧的注册与连接状态
- 不依赖任何一步失败就整体报错，逐项打印，方便定位卡在哪一步

**调用方式**：
```powershell
powershell -File "scripts\status.ps1"
powershell -File "scripts\status.ps1" -McpServerName "x64dbg-x32"
```

## 核心工具列表

完整参数与示例见 `references/x64dbg-mcp-cheatsheet.md`（按真实源码 `src/mcp/tools.zig` 核对，非推测）。这里只列分类概况，共 71 个工具：

### 会话与状态（8）
`GetDebugState`（随时可用，判断是否已有会话）、`LoadBinary`、`AttachProcess`、`Echo`、`WaitForPause`、`GetEventLog`、`ClearEventLog`、`ListCommandsByCategory`

### 执行控制（9，均需已有会话）
`run`、`StepInto`、`StepOver`、`StepOut`、`PauseDebug`、`StopDebug`、`RestartDebug`、`RunToAddress`、`TraceInto`

### 断点管理（10，均需已有会话）
`SetBreakpoint`、`DeleteBreakpoint`、`EnableBreakpoint`、`DisableBreakpoint`、`ToggleBreakpoint`、`DeleteAllBreakpoints`、`ResetHitCount`、`ListBreakpoints`、`SetConditionalBreakpoint`、`SetHardwareBreakpoint`

### 内存读写与脱壳（11，均需已有会话）
`ReadMemory`、`WriteMemToAddress`、`GetMemoryMap`、`AllocateMemory`、`FreeMemory`、`FollowPointer`、`GetDumpableRegions`、`DumpMemory`、`DumpModule`、`RestorePatches`、`GetPatches`

### 寄存器与调用栈（7，均需已有会话）
`GetAllRegisters`、`SetRegister`、`GetCallStack`、`GetArguments`、`GetCurrentAddress`、`GetSEHChain`（仅 x32）、`GetPEB`

### 反汇编与汇编（4，均需已有会话）
`Disassemble`、`DisassembleFunction`、`Assemble`、`CommentOrLabelAtAddress`

### 模块与符号（8，均需已有会话）
`ListModules`、`GetImports`、`GetExports`、`GetFunctions`（需先 Ctrl+A 分析过）、`SearchSymbols`、`ListSymbols`、`AnalyzeModule`、`DetectOEP`

### 搜索（4，均需已有会话）
`SearchForStrings`、`FindPattern`、`GetStrings`、`GetReferences`

### 线程（4，均需已有会话）
`GetThreads`、`SwitchThread`、`SuspendThread`、`ResumeThread`

### 书签与表达式（5，均需已有会话）
`SetBookmark`、`DeleteBookmark`、`ListBookmarks`、`EvalExpression`、`WatchExpressions`

### 原生命令通道（1）
`ExecuteDebuggerCommand` — 没有专用工具覆盖的场景，直接执行任意 x64dbg 命令字符串（例如 `bp kernel32:CreateFileW`、`dump eax`），是逃生舱，优先用专用工具

## 逆向分析完整工作流

### Step 0：确保插件就绪
```powershell
powershell -File "scripts/status.ps1"
```
看到 `OK` 且端口在监听再继续；没起来先跑 `scripts/install.ps1`，跑完记得提醒用户新开一次 Claude Code 会话让工具列表刷新。

### Step 1：建立调试会话
```
LoadBinary(filePath="C:\目标.exe")
```
或附加到已运行进程：
```
AttachProcess(pid=1234)
```

### Step 2：确认当前状态
```
GetDebugState()
GetCurrentAddress()
ListModules()
```

### Step 3：静态先行（不跑起来也能看的信息）
```
AnalyzeModule(module="target.exe")   # PE 结构：节区、入口点、大小
DetectOEP(module="target.exe")       # 疑似加壳时先猜 OEP
GetImports(module="target.exe")
GetStrings(module="target.exe", minLength=6)
```

### Step 4：定位关键点并下断点
```
SearchForStrings(searchText="密码错误")
GetReferences(address="0x00401234")       # 谁引用了这个地址/字符串
SetBreakpoint(target="0x00401234")
SetConditionalBreakpoint(address="kernel32:CreateFileW", condition="1==1", log="打开文件: {arg1}")
```

### Step 5：运行并观察真实状态
```
run()
WaitForPause(timeoutMs=30000)
GetAllRegisters()
GetCallStack()
GetArguments(count=4)
Disassemble(address="cip", count=20)
```

### Step 6：内存/patch/脱壳
```
ReadMemory(address="eax", size=64)
WriteMemToAddress(address="0x00401234", byteString="90 90 90 90 90")   # 先用 GetPatches 记基线，方便 RestorePatches 回滚
GetDumpableRegions()
DumpModule(module="target.exe", filePath="C:\dump\target_unpacked.exe")
```

### Step 7：记录与报告
```
CommentOrLabelAtAddress(address="0x00401234", value="密码校验入口", mode="Label")
```
分析完成后，生成 `report.md` 记录发现和步骤（时间线、命中的断点、关键地址、patch 记录）。

## Prompt 工程准则

1. **先判断有没有会话** — 任何 `debug_only` 工具报错前，先 `GetDebugState()`，没有会话就先 `LoadBinary`/`AttachProcess`
2. **下断点不等于命中** — `SetBreakpoint` 之后必须 `run()` + `WaitForPause()` 确认真的停下来了，不要假设断点已命中就去读寄存器
3. **写内存前先留退路** — `WriteMemToAddress`/`Assemble` 之前用 `GetPatches` 记录当前已 patch 状态，验证失败时 `RestorePatches` 一键回滚，不要靠人工记哪些字节改过
4. **地址一律用表达式，不要手算** — 支持 `cip`、`eax+4`、`kernel32:CreateFileA` 等 x64dbg 表达式语法，算不准就用 `EvalExpression` 现算，不要自己心算偏移
5. **脱壳先看结构再跑** — `AnalyzeModule` + `DetectOEP` 先过一遍拿到疑似 OEP，再决定用 `DumpModule` 直接转储还是需要 `RunToAddress` 跑到 OEP 后再转储
6. **大范围搜索限定 module** — `FindPattern`/`GetStrings`/`SearchSymbols`/`GetFunctions` 都支持按模块过滤，扫全进程会很慢，优先只扫主模块或目标 DLL
7. **没有专用工具时不要卡住** — 用 `ExecuteDebuggerCommand` 直接执行原生 x64dbg 命令（和在 GUI 命令行里敲的语法完全一致），比等一个不存在的专用工具更快
8. **遇到 "not attached" / "no active session" 类报错** — 先 `GetDebugState()` 确认会话状态，多半是漏了 `LoadBinary`/`AttachProcess`，或调试目标已经 `StopDebug`/进程已退出
9. **32 位目标注意 `GetSEHChain` 只在 x32 有效**，x64 用 `GetCallStack` + `GetPEB` 交叉验证异常处理路径
10. **32/64 位目标混合调试** — x32/x64 是两个独立端口（9095/9094），需要分别 `scripts/install.ps1 -Arch x32` 和默认 x64 各注册一次，用不同 server 名区分

## 路由上下文

**上游入口**: 根目录 `SKILL.md`（总控）、routing.md
**上游备选**:
- 只需要静态反编译/伪代码，不需要真实运行 → `ida-reverse/`
- 只想快速 CLI 侦察，不想开 GUI → `radare2/`

**下游出口**:
- 需要持久化二进制 patch（而不是内存态 patch）→ `references/pe-patching.md`
- 需要 Frida 做用户态 hook 交叉验证 → `reverse-engineering/tools-dynamic.md`
- 发现是加壳/反调试保护 → `references/anti-analysis.md`、`references/unpacking.md`
- 转储脱壳产物后要修复导入表 → 参考 `references/external-tool-downloads.md` 里的 Scylla / ScyllaHide

**同级关联模块**: `ida-reverse/`（静态深入分析同一目标时交叉验证）、`radare2/`（不想开 GUI 时的轻量替代）

## 按需自举（On-Demand Bootstrap）

本 skill 的入口脚本已接入统一自举系统（`github-reverse-modules/skills/scripts/bootstrap-manifest.json`）。

### 自动化能力边界

| 工具 | 可自动安装 | 安装方式 | 说明 |
|------|-----------|---------|------|
| x64dbg 本体 | ✓（需显式开关） | GitHub Release zip（`x64dbg/x64dbg` 官方快照） | 默认只打印官方下载页/Releases 直链；传 `install.ps1 -AutoInstallX64dbg` 才会真正下载解压到 `-X64dbgInstallDir` |
| x64dbg-MCP-Server 插件 | ✓（默认自动） | 官方 Release zip（x64dbg-mcp-server） | `install.ps1` 自动下载、解压、复制到 plugins 目录；下载失败会打印手动下载链接而不是裸异常 |
| MCP 注册 | ✓（默认自动） | `claude mcp add --transport http` | `install.ps1` 读取 token 后自动完成，`--scope user` 为全局；`claude` 命令行缺失时打印官方安装命令 |

### 安装步骤（已验证，2026-08-24 实测）

```powershell
# 0. 没有 x64dbg？可以让脚本自己下载官方快照，而不是手动去官网点下载
#    （不加 -AutoInstallX64dbg 时，缺 x64dbg 只会打印下载页链接，不会自作主张安装）
powershell -File "github-reverse-modules\skills\x64dbg-reverse\scripts\install.ps1" -AutoInstallX64dbg

# 1. 已经有 x64dbg 了：一键部署插件 + 注册全局 MCP
powershell -File "github-reverse-modules\skills\x64dbg-reverse\scripts\install.ps1" -X64dbgDir "D:\x64dbg\release"

# 2. 验证
powershell -File "github-reverse-modules\skills\x64dbg-reverse\scripts\status.ps1"
claude mcp get x64dbg

# 3. 新开一次 Claude Code 会话，让新注册的工具列表生效
```

> 缺 `claude` 命令行本身也会被脚本发现并给出安装方法（`irm https://claude.ai/install.ps1 | iex`），不需要单独去查文档。

> ⚠️ **注意**：默认监听地址是 `0.0.0.0`。如果只在本机使用，建议启动 x64dbg 后在插件菜单的配置对话框里把绑定地址改成 `127.0.0.1`，减小被局域网内其他设备探测到的面。

### 自举触发点

- `scripts/install.ps1`：缺 x64dbg 本体时默认报 `ERR:x64dbg_not_found` 并打印官方下载页/Releases 直链，不做静默安装（涉及安装一个完整 GUI 调试器，交给用户确认更安全）；传 `-AutoInstallX64dbg` 则自动下载解压
- `scripts/install.ps1`：x64dbg 本体存在但插件缺失时，全自动下载 x64dbg-mcp-server 官方最新 Release 并部署；下载失败会打印手动下载链接而不是抛异常
- `scripts/install.ps1`：`claude` 命令行缺失时打印官方安装命令（`irm https://claude.ai/install.ps1 | iex`，备选 `winget install Anthropic.ClaudeCode`）
- MCP 注册：`install.ps1` 自动把 `x64dbg`（或自定义 server 名）写入 Claude MCP 配置

### 前置条件

- Windows（x64dbg 是 Windows-only 调试器）
- PowerShell 5+
- 可选 `claude` 命令行在 PATH 上（缺失时 `install.ps1` 仍会完成插件部署，只是跳过 MCP 注册并报 `ERR:claude_cli_missing`）
