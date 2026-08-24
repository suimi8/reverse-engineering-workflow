---
name: ce-reverse
description: |
  Cheat Engine（CE）动态内存分析与逆向辅助技能。当用户提到 Cheat Engine、CE、内存扫描/找数值基址、指针链追踪、游戏内存修改、函数 Hook 抓参数、断点+寄存器/调用栈捕获、DBVM 反反作弊隐藏、或需要对一个正在运行的进程做内存读写/扫描/反汇编/注入时，务必使用此技能。

  Ensure to use this skill when the user wants to scan process memory for a value, find a pointer chain/static base for a dynamic address, hook a function to capture its arguments, patch memory at runtime, inject code/DLLs into a running process, or reverse-engineer a game/application's runtime behavior — regardless of whether they explicitly say "Cheat Engine" or "CE". This includes requests like "帮我找一下这个数值在内存里的地址", "这个地址的指针链是什么", "帮我hook这个函数看看参数", "这个游戏是不是加了反作弊", "内存里改个数值试试" 等。

  Use the bundled scripts (scripts/install.ps1, scripts/status.ps1) for deterministic Lua-bridge deployment and health checks — do NOT write ad-hoc PowerShell commands for these operations.
---


中文名：suimi Cheat Engine 逆向
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# Cheat Engine 动态内存分析技能

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，并按需用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 维护学习闭环。

本模块基于本地 `ce_mcp` 项目（npm 包名 `cheatengine`，MIT License，作者 richard_wjx，本地已验证版本 6.0.0）。与 `x64dbg-reverse` 的静态断点/反汇编定位不同，本模块的核心优势是**内存扫描与指针链追踪**——CE 的看家本领：从"游戏里血量在扣"到"这个值在内存里的哪个地址、指针链怎么写"的完整闭环。

## 已知问题与反思（必读）

### 架构要点（和 x64dbg-reverse 不一样，先理解再用）

1. **三层架构，不是单进程**：`AI <--MCP/JSON-RPC--> ce_mcp_server.js（Node.js）<--命名管道--> ce_mcp_bridge.lua（跑在 CE 里）`。
   - MCP server 是**独立的 Node.js stdio 进程**（Claude 按需拉起/关闭），不是常驻 HTTP 服务，这点和 x64dbg-reverse 的插件+HTTP 模式完全不同
   - Lua 桥必须先加载进 Cheat Engine（复制到 CE 的 `autorun` 文件夹自动加载，或 `Ctrl+Alt+L` 手动 `dofile(...)`），MCP server 才有对象可连
   - 命名管道固定是 `\\.\pipe\ce_mcp_bridge`；CE 没开 / Lua 桥没加载时，MCP 工具调用会拿到连接失败诊断而不是数据

2. **`ce_get_process_info` 是官方标注的"必须最先调用"**：附加进程前先 `ce_attach_process`，之后立刻 `ce_get_process_info` 确认状态。大型进程首次 `refresh_symbols=true` 可能要 60-120 秒，不要以为卡死了。

3. **需要真人配合操作的工具，AI 必须先提醒用户**：`ce_find_what_accesses`/`ce_find_what_writes`/`ce_find_pointer_path` 监控窗口固定 10 秒/层，期间**必须由用户在游戏里实际触发一次数值变化**（掉血、加分等），工具参数里的 `user_prompted` 字段就是专门设计出来强制这一步的——不提醒用户直接调用等于白等 10 秒。

4. **危险工具明确标了 `[DANGEROUS]`**：`ce_call_function`、`ce_execute_method` 会在目标进程里**真的执行代码**，参数/调用约定错了可能直接把游戏干崩，用之前要向用户说明风险。

5. **Hook 名字有安全校验**：必须匹配 `^[a-zA-Z_][a-zA-Z0-9_]*$`（字母/下划线开头，只含字母数字下划线），防止 Auto Assembler 脚本注入。`"my hook"`、`"hook;inject"` 这类名字会被直接拒绝。

6. **扫描会话有上限**：`ce_scan_new` 开的会话 5 分钟不活动自动过期，最多同时 5 个并发会话，会话满了要先 `ce_scan_close` 老会话。

7. **批量优先**：`ce_read_memory_batch`/`ce_write_memory_batch` 官方文档明确要求"始终优先于多次单次调用"，一次性传多个地址性能差距很大，不要循环调用单次读写工具。

8. **npm 包名是 `cheatengine`**（不是 "cheat-engine-mcp" 之类的名字），已核对本地 `package.json` 与 npm registry 上的 `cheatengine@6.0.0` 版本号一致。**有本地源码时优先直接 `node <本地路径>/ce_mcp_server.js` 而不是 `npx cheatengine@latest`**——npx 拉取的版本无法保证和本地已读过、已验证的源码字节一致。

9. **注册即用还差一步**：`claude mcp add` 完成后要新开一次 Claude Code 会话，工具列表才会刷新（同 x64dbg-reverse 的教训，`claude mcp list` 能验证连接是否成功但不代表当前会话已经能调用工具）。

10. **Cheat Engine 本体这次是本机已装的**（`D:\Cheat Engine`），不代表所有环境都有——见下方"按需自举"的缺依赖处理。

### 工作流程原则

| 步骤 | 做什么 | 用什么 |
|------|--------|--------|
| 1 | 确保 Lua 桥已部署、CE 已运行、MCP 已注册 | `scripts/install.ps1` |
| 2 | 确认连接与进程状态 | `scripts/status.ps1` → `ce_ping` → `ce_get_process_info` |
| 3 | 附加目标进程 | `ce_attach_process` |
| 4 | 找数值/找指针链/反汇编/Hook | 直接调用对应工具（见下方速查） |
| 5 | 需要用户配合操作时先提醒 | `ce_find_what_accesses` / `ce_find_pointer_path` 等 |

## 脚本资源

### install.ps1 — 部署 Lua 桥并注册 MCP

路径：`scripts/install.ps1`

- 自动探测本机 Cheat Engine 安装目录，找不到则打印官方下载页链接并退出，不做静默安装——`cheatengine.org` 没有像 GitHub Releases 那样稳定可脚本化的直链，编一个下载地址硬编到脚本里比手动下载更不可靠
- 把 `ce_mcp_bridge.lua` 复制到 CE 的 `autorun` 目录（自动创建目录不存在的情况）
- 若 CE 未运行则启动一次，让 Lua 桥自动加载
- 检测 Node.js 是否可用，缺失时打印官方下载页
- 用 `claude mcp add --transport stdio` 把 `node <ce_mcp源码路径>/ce_mcp_server.js` 注册为 MCP server（已存在同名 server 先 remove 再 add）
- 成功输出 `OK:<server-name>`，失败输出 `ERR:<reason>` 并附下载/自助指引

**调用方式**：
```powershell
# 全自动：探测/启动 CE、部署 Lua 桥、注册全局 MCP
powershell -File "scripts\install.ps1" -CeMcpSourceDir "E:\1 源码\BaiduSyncdisk\逆向\ce_mcp"

# 显式指定 CE 安装目录（找不到自动探测结果时用）
powershell -File "scripts\install.ps1" -CeMcpSourceDir "..." -CeDir "D:\Cheat Engine"

# 只部署 Lua 桥，不改 Claude 的 MCP 配置
powershell -File "scripts\install.ps1" -CeMcpSourceDir "..." -SkipClaudeRegister
```

**输出约定**：
```
OK:cheatengine                  # 成功注册
ERR:ce_not_found                # 没找到本机 CE 安装，附官方下载页链接（不会自动下载安装）
ERR:node_missing                # 没有 Node.js，附官方下载页链接
ERR:ce_mcp_source_not_found     # -CeMcpSourceDir 指向的目录里没有 ce_mcp_server.js
ERR:claude_cli_missing          # 找不到 claude 命令行，附安装命令
```

### status.ps1 — 健康检查

路径：`scripts/status.ps1`

- 检查 Cheat Engine 进程是否在跑
- 检查 Lua 桥文件是否已部署在 CE 的 `autorun` 目录
- 检查 Node.js 版本
- 调用 `claude mcp get <server-name>` 汇报 Claude 侧注册与连接状态（连接测试会真实拉起一次 `node ce_mcp_server.js` 尝试连接命名管道，能反映 Lua 桥是否真的加载成功）

**调用方式**：
```powershell
powershell -File "scripts\status.ps1"
powershell -File "scripts\status.ps1" -McpServerName "cheatengine"
```

## 核心工具列表

完整参数与调用示例见 `references/ce-mcp-cheatsheet.md`（核对自源码 `src/tool-registry.js`，非推测）。这里只列官方自带的 14 个分类概况，共 127 个工具：

### System 系统与连接（9）
`ce_ping`、`ce_get_process_info`（**永远先调用**）、`ce_execute_lua`、`ce_list_processes`、`ce_attach_process`、`ce_auto_assemble`、`ce_get_stats`、`ce_get_logs`、`ce_type_conversion`

### Memory 内存读写（3）
`ce_read_memory`、`ce_read_memory_batch`（**批量优先**）、`ce_write_memory`、`ce_write_memory_batch`

### Memory Management 内存管理（8）
`ce_allocate_memory`、`ce_deallocate_memory`、`ce_get_memory_protection`、`ce_set_memory_protection`、`ce_copy_memory`、`ce_compare_memory`、`ce_enum_memory_regions`、`ce_full_access`

### Scanning 扫描与搜索（14）
`ce_aob_scan`、`ce_aob_scan_unique`、`ce_value_scan`、`ce_scan_new`、`ce_scan_next`、`ce_scan_results`、`ce_scan_close`、`ce_scan_list`、`ce_enum_modules`、`ce_check_assemble`、`ce_generate_script`、`ce_memory_record_control`、`ce_rip_scan`、`ce_disassemble_bytes`、`ce_assemble_instruction`

### Table 作弊表（3）
`ce_get_address_list`、`ce_add_address_record`、`ce_load_table`、`ce_save_table`

### Symbols 符号与地址（12）
`ce_get_address`、`ce_get_symbol`、`ce_get_region_info`、`ce_auto_guess`、`ce_resolve_pointer`、`ce_register_symbol`、`ce_unregister_symbol`、`ce_pointer_size`、`ce_symbol_control`、`ce_get_rtti`、`ce_comment`、`ce_enum_symbols`、`ce_get_address_safe`、`ce_get_symbol_info`、`ce_add_symbol_module`、`ce_get_name_from_address`

### Debug 调试与断点（6）
`ce_disassemble`、`ce_get_instruction_info`、`ce_set_breakpoint`、`ce_remove_breakpoint`、`ce_get_breakpoints`、`ce_break_and_get_regs`、`ce_break_and_trace`（**最强大的调试工具**）、`ce_thread_breakpoint`

### Debug Advanced 高级调试（6）
`ce_debug_start`、`ce_debug_status`、`ce_debug_continue`、`ce_get_set_context`、`ce_thread_no_break`、`ce_debug_break_thread`、`ce_detach_debugger`

### Process 进程控制/信息（9）
`ce_pause_process`、`ce_resume_process`、`ce_speedhack`、`ce_enum_threads`、`ce_enum_handles`、`ce_open_file_as_process`、`ce_create_process`、`ce_get_foreground_process`、`ce_close_remote_handle`、`ce_duplicate_handle`、`ce_target_info`

### Analysis 分析工具（20）
`ce_find_what_accesses`（**需要用户配合**）、`ce_find_what_writes`（**需要用户配合**）、`ce_analyze_code`、`ce_build_cfg`、`ce_detect_patterns`、`ce_compare_functions`、`ce_trace_dataflow`、`ce_program_slice`、`ce_analyze_struct_access`、`ce_trace_struct_access`、`ce_cleanup`、`ce_find_pointer_path`（**需要用户配合，自动指针链追踪**）、`ce_find_references`、`ce_find_call_references`、`ce_find_function_boundaries`、`ce_checksum_memory`、`ce_generate_signature`、`ce_structure_manage`、`ce_dissect_code`

### 函数 Hook（4，属于 Analysis 分类）
`ce_hook_function`、`ce_unhook_function`、`ce_list_hooks`、`ce_get_hook_log`、`ce_clear_hook_log`

### 代码模拟（2，属于 Analysis 分类）
`ce_call_function`（⚠️ `[DANGEROUS]`）、`ce_symbolic_trace`（安全的符号执行替代方案）

### Injection 注入（8）
`ce_inject_dll`、`ce_inject_dotnet_dll`、`ce_compile_c_code`、`ce_compile_c_sharp`、`ce_execute_method`（⚠️ `[DANGEROUS]`）、`ce_create_remote_thread`、`ce_generate_api_hook_script`、`ce_dump_memory`

### DotNet .NET 分析（1）
`ce_dotnet_analyze`（Unity/Mono 游戏专用）

### FileIO 文件操作（5）
`ce_md5_file`、`ce_file_version`、`ce_file_ops`、`ce_write_region_to_file`、`ce_read_region_from_file`

### Window 窗口操作（2）
`ce_find_window`、`ce_enum_windows`

### Kernel 内核操作（3）
`ce_allocate_shared_memory`、`ce_get_physical_address`、`ce_dbvm_cloak`（DBVM 隐藏内存 patch 绕过反作弊完整性校验）

## 推荐工作流

### 找数值地址（最常见场景）
```
ce_attach_process(target="game.exe") → ce_get_process_info()
ce_scan_new(value="100", type="dword")          # 血量=100 时扫描
# 提醒用户：去游戏里让血量变化
ce_scan_next(session_id=..., value="95", scan_type="exact")   # 或 scan_type="decreased"
ce_scan_results(session_id=...)                  # 收敛到少量结果后拿地址
```

### 找指针链（自动优先，失败再手动）
```
ce_find_pointer_path(address="0x255D5E758", user_prompted=true)   # 提醒用户先操作游戏！
# 自动失败时手动三步：
ce_find_what_accesses(address="0x255D5E758", user_prompted=true)  # 提醒用户！
ce_value_scan(value="<上一步拿到的寄存器值>", type="qword")
# 重复直到落到 game.exe+固定偏移
```

### Hook 函数抓参数
```
ce_hook_function(address="0x14001234", name="on_damage", capture_args=4)
# 让游戏运行一段时间触发调用
ce_get_hook_log(name="on_damage", limit=20)
ce_unhook_function(name="on_damage")   # 分析完清理
```

详细分类工具参数、更多工作流示例（函数分析、逆向未知代码）见 `references/ce-mcp-cheatsheet.md`。

## Prompt 工程准则

1. **附加进程后立刻 `ce_get_process_info`** — 官方标注 `[INIT]`，其它工具的可靠性依赖这一步已完成
2. **批量读写优先** — `ce_read_memory_batch`/`ce_write_memory_batch` 永远优先于循环调用单次版本
3. **需要用户操作游戏的工具，先说后调** — `ce_find_what_accesses`/`ce_find_what_writes`/`ce_find_pointer_path` 调用前必须明确告诉用户"接下来 10 秒内请在游戏里触发一次变化"，再传 `user_prompted=true`，不打招呼直接调用等于浪费一次 10 秒窗口
4. **危险工具先声明风险** — `ce_call_function`/`ce_execute_method` 会真的执行目标进程代码，调用前提示用户"这会真实执行代码，可能导致目标进程崩溃"
5. **扫描会话及时关闭** — 最多 5 个并发、5 分钟过期，用完 `ce_scan_close`，别让老会话占满配额
6. **Hook 名字用合法标识符** — 只能字母/下划线开头 + 字母数字下划线，起名参考变量命名规则
7. **地址表达式支持嵌套** — `"[[game.exe+100]+20]+8"` 这类可以直接传给 `ce_get_address`/`ce_resolve_pointer`，不用自己算
8. **没有专用工具时用 `ce_execute_lua`** — 可以执行任意 CE Lua API，是逃生舱，但要小心可能崩游戏
9. **`ce_generate_signature`** 在确认关键地址后随手生成一次，方便游戏更新后用 `ce_aob_scan` 重新定位
10. **DBVM 相关工具（`ce_dbvm_cloak`）需要 CE 已启用 DBVM 驱动**，普通安装默认不带，报错时不要当成 bug，先确认 DBVM 是否已启用

## 路由上下文

**上游入口**: 根目录 `SKILL.md`（总控）、routing.md
**上游备选**:
- 目标是纯 PE 可执行文件的断点/脱壳/OEP，不涉及内存扫描找基址 → `x64dbg-reverse/`
- 只需要静态反编译/伪代码 → `ida-reverse/`

**下游出口**:
- 找到指针链/关键地址后需要做持久化字节 patch → `references/pe-patching.md`
- 目标疑似有反调试/反作弊完整性校验 → `references/anti-analysis.md`（`ce_dbvm_cloak` 是应对手段之一）
- Unity/Mono 游戏的 .NET 层分析 → 本模块的 `ce_dotnet_analyze` 已覆盖，不需要跳出去

**同级关联模块**: `x64dbg-reverse/`（同为动态调试工具，PE 断点/脱壳场景优先用它）

## 按需自举（On-Demand Bootstrap）

本 skill 的入口脚本已接入统一自举系统（`github-reverse-modules/skills/scripts/bootstrap-manifest.json`）。

### 自动化能力边界

| 工具 | 可自动安装 | 安装方式 | 说明 |
|------|-----------|---------|------|
| Node.js | ✗ | 官方安装包 | `install.ps1` 缺失时打印 `https://nodejs.org/en/download` 下载页，不做静默安装 |
| Cheat Engine 本体 | ✗ | 官方安装包（`cheatengine.org`） | `install.ps1` 缺失时打印官方下载页并退出；`cheatengine.org` 没有稳定可脚本化的直链，不编造下载地址去自动装 |
| ce_mcp（Lua 桥 + Node server） | ✓（默认自动，需本地源码路径） | 复制 Lua 桥到 `autorun`，注册 `node <path>/ce_mcp_server.js` | 需要传 `-CeMcpSourceDir` 指向已有的本地源码（未内置自动下载，因为该项目未确认有稳定公开的源码仓库，见下方前置条件） |

### 安装步骤（已验证，2026-08-24 实测）

```powershell
# 0. 若本机还没有 Cheat Engine，先手动从官方下载页装好（没有可自动化的直链，install.ps1 缺失时会提示这个地址）
#    官方下载页: https://cheatengine.org/

# 1. 一键部署 Lua 桥 + 注册全局 MCP（本地已有 ce_mcp 源码时）
powershell -File "github-reverse-modules\skills\ce-reverse\scripts\install.ps1" `
  -CeMcpSourceDir "E:\1 源码\BaiduSyncdisk\逆向\ce_mcp"

# 2. 验证
powershell -File "github-reverse-modules\skills\ce-reverse\scripts\status.ps1"
claude mcp get cheatengine

# 3. 新开一次 Claude Code 会话，让新注册的工具列表生效
```

> ⚠️ **`ce_call_function`/`ce_execute_method` 会真实执行目标进程代码**，用之前务必向用户说明风险，参数错误可能导致目标进程崩溃。
> ⚠️ CE 的 EULA 要求用户为成年人且仅用于私人/教育用途，附加到网络游戏前请自行确认未违反目标游戏的 EULA/TOS——本模块只提供工具能力，不判断具体用途是否合规。

### 自举触发点

- `scripts/install.ps1`：缺 Node.js 时打印官方下载页并退出，不做自动安装（跨版本兼容风险较高，交给用户手动选择合适版本）
- `scripts/install.ps1`：缺 Cheat Engine 本体时打印官方下载页并退出，不做静默安装（`cheatengine.org` 没有可脚本化的稳定直链，不像 x64dbg/Ghidra/radare2 有 GitHub Releases API 可用）
- `scripts/install.ps1`：Lua 桥文件通过 `-CeMcpSourceDir` 指向的本地源码复制部署，不做网络下载（该 npm 包虽名为 `cheatengine`，但未确认有稳定的公开源码仓库地址，避免引用未核实的下载源）
- MCP 注册：`install.ps1` 自动把 `cheatengine`（或自定义 server 名）写入 Claude MCP 配置

### 前置条件

- Windows（Cheat Engine 主要面向 Windows；Mac/Linux 版本存在但本模块脚本按 Windows 路径编写）
- Node.js 14+（`ce_mcp_server.js` 运行依赖）
- 已获取 `ce_mcp` 项目源码（本地路径或 `npm install -g cheatengine` / `npx -y cheatengine@latest`——**注意验证 npx 拉取版本与预期一致**，官方 npm 包名确认为 `cheatengine`，当前已知版本 `6.0.0`）
- 可选 `claude` 命令行在 PATH 上（缺失时 `install.ps1` 仍会完成 Lua 桥部署，只是跳过 MCP 注册并报 `ERR:claude_cli_missing`）
