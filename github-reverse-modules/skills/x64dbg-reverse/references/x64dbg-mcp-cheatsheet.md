# x64dbg MCP 工具速查

> 71 个 MCP 工具，按功能分类，附真实参数（核对自 `duty1g/x64dbg-mcp-server` 源码 `src/mcp/tools.zig`，非推测）。
> 工具名是原始 PascalCase（`LoadBinary`、`ReadMemory` 等），服务器本身不加前缀；在 Claude Code 里会以 `mcp__<server名>__<工具名>` 形式出现，`<server名>` 就是 `claude mcp add` 时起的名字（默认 `x64dbg`）。
> 分类是本模块按功能整理的，不是服务器内部的 `ListCommandsByCategory` 原始分类字符串。
> 标注"只读"的工具不会改变调试目标状态，可以放心地反复调用做侦察；未标注的会修改内存/寄存器/断点/执行状态。

---

## 会话与状态

### GetDebugState — 只读，随时可用
判断当前是否已加载目标、是否在跑、PID、当前指令指针、当前模块。**任何其他 debug_only 工具报错前，先调用这个确认状态。**
```
GetDebugState()
```

### LoadBinary — 随时可用
新建调试会话，相当于 File > Open。如果已有会话会先终止旧的，加载后停在系统断点。
```
LoadBinary(filePath="C:\target.exe")
LoadBinary(filePath="C:\target.exe", arguments="--verbose")
```

### AttachProcess — 随时可用
附加到一个已运行的进程。
```
AttachProcess(pid=1234)
```

### Echo — 只读，随时可用
把输入原样返回，用于连通性测试。
```
Echo(message="ping")
```

### WaitForPause — 只读，debug_only
阻塞直到目标暂停（命中断点/异常/退出），返回暂停原因和当前地址。**`run()` 之后必须跟这个**，不要假设 run 完就已经停下。
```
WaitForPause(timeoutMs=30000)
```

### GetEventLog / ClearEventLog — debug_only
环形缓冲区保存最近 64 条调试器事件（异常、断点、DLL 加载、线程事件）。
```
GetEventLog(count=20)
ClearEventLog()
```

### ListCommandsByCategory — 只读，随时可用
列出所有可用 MCP 工具，可选按分类过滤。
```
ListCommandsByCategory()
ListCommandsByCategory(category="breakpoints")
```

---

## 执行控制（均需 debug_only）

```
run()                              # F9 继续执行，无参数
StepInto()                         # F7 单步进入调用
StepOver()                         # F8 单步跳过调用
StepOut()                          # Ctrl+F9 运行到当前函数返回
PauseDebug()                       # F12 暂停
StopDebug()                        # 终止调试会话，关闭目标进程
RestartDebug()                     # 从头重新开始
RunToAddress(address="0x00401234", timeoutMs=30000)   # 临时断点跑到指定地址
TraceInto(count=20)                # 连续单步 N 条并记录每一条的反汇编（最多 100）
```

**标准节奏**：`run()` → `WaitForPause(timeoutMs=...)` → 读状态 → 再 `run()`/`StepOver()`……不要在没有 `WaitForPause` 的情况下连续发多个执行控制指令。

---

## 断点管理（均需 debug_only）

```
SetBreakpoint(target="0x00401234")               # target 支持地址或 API 符号
SetBreakpoint(target="kernel32:CreateFileW")
DeleteBreakpoint(target="0x00401234")
EnableBreakpoint(address="0x00401234")
DisableBreakpoint(address="0x00401234")           # 禁用但不删除
ToggleBreakpoint(address="0x00401234")
DeleteAllBreakpoints()
ResetHitCount(address="0x00401234")
ListBreakpoints()                                 # 只读：列出软件/硬件/内存断点
SetConditionalBreakpoint(address="0x00401234", condition="eax==0", log="eax为0时命中: {rax}")
SetHardwareBreakpoint(address="0x00401234", type="w", size=4)   # type: r/w/x(默认)，size: 1/2/4/8
```

---

## 内存读写与脱壳（均需 debug_only）

### 读写
```
ReadMemory(address="eax", size=64)                          # size 上限 4096，返回十六进制+ASCII
WriteMemToAddress(address="0x00401234", byteString="90 90 90 90 90")   # ⚠️ 直接改活动进程内存
GetMemoryMap()                                              # 只读：所有内存区域+保护属性+所属模块
AllocateMemory(size=4096, protection="rwx")                 # protection: rwx/rw/rx/r，默认 rw
FreeMemory(address="0x00500000")
FollowPointer(address="eax", depth=3)                       # 只读：多级指针解引用
```

### Patch 追踪与回滚
```
GetPatches()          # 只读：列出当前所有已应用的内存 patch
RestorePatches()       # 把所有 patch 过的字节还原为原始值——改内存前先记基线，验证失败随时回滚
```

### 脱壳/转储
```
GetDumpableRegions()                                              # 只读：哪些区域可以安全 dump
DumpMemory(address="0x00400000", size=0x10000, filePath="C:\dump\region.bin")
DumpModule(module="target.exe", filePath="C:\dump\target_unpacked.exe")
```

---

## 寄存器与调用栈（均需 debug_only）

```
GetAllRegisters()                       # 只读：全部通用寄存器
SetRegister(register="eax", value="0x1")
GetCallStack()                          # 只读
GetArguments(count=4)                   # 只读：x32 从栈 [ESP+4].. 读，x64 从 RCX/RDX/R8/R9.. 读，上限 16
GetCurrentAddress()                     # 只读：当前 EIP/RIP + 所属模块 + 标签/注释
GetSEHChain()                           # 只读：仅 x32 有效，遍历 SEH 链
GetPEB()                                # 只读：镜像基址/被调试标志/堆/NtGlobalFlag/镜像路径/命令行
```

---

## 反汇编与汇编（均需 debug_only）

```
Disassemble(address="cip", count=10)             # 默认从当前 IP 开始 10 条，count 上限 100
DisassembleFunction(address="0x00401234")        # 从分析数据库找函数边界后整函数反汇编
Assemble(address="0x00401234", instruction="nop")
Assemble(address="0x00401234", instruction="jmp 0x00401080")
CommentOrLabelAtAddress(address="0x00401234", value="解密循环", mode="Comment")   # mode: Comment/Label
```

---

## 模块与符号（均需 debug_only）

```
ListModules()                            # 只读：所有已加载模块+基址+大小
GetImports(module="target.exe")          # 只读
GetExports(module="kernel32")            # 只读
GetFunctions(module="target.exe")        # 只读：需要先在 x64dbg 里 Ctrl+A 做过分析
SearchSymbols(pattern="Create", module="kernel32")   # 只读：子串匹配，module 可省略搜全部
ListSymbols(module="kernel32")           # 只读：模块导出符号
AnalyzeModule(module="target.exe")       # 只读：PE 结构——节区/入口点/镜像大小/特征位
DetectOEP(module="target.exe")           # 只读：按节区特征猜测加壳程序的真实 OEP
```

---

## 搜索（均需 debug_only）

```
SearchForStrings(searchText="密码错误", encoding="UTF-8")   # 只读：encoding 可选 UTF-8/UTF-16
FindPattern(pattern="E8 ?? ?? ?? ?? 85 C0 74", module="target.exe", maxResults=10)   # 只读：?? 通配符
GetStrings(module="target.exe", minLength=6)                # 只读：扫模块内存里的 ASCII 字符串
GetReferences(address="0x00401234", module="target.exe")    # 只读：谁 CALL/JMP 到这个地址
```

---

## 线程（均需 debug_only）

```
GetThreads()                    # 只读
SwitchThread(threadId=5820)
SuspendThread(threadId=5820)
ResumeThread(threadId=5820)
```

---

## 书签与表达式（均需 debug_only）

```
SetBookmark(address="0x00401234")
DeleteBookmark(address="0x00401234")
ListBookmarks()                                       # 只读
EvalExpression(expression="eax+4")                    # 只读：地址/寄存器/算术/符号都能算，永远用这个而不是手算
EvalExpression(expression="kernel32:CreateFileA")
WatchExpressions(expressions="eax,ebx,[esp+4],cip")   # 只读：逗号分隔，一次算多个
```

---

## 原生命令通道

### ExecuteDebuggerCommand — 随时可用（是否改状态取决于命令本身）
没有专用工具覆盖的操作，直接执行任意 x64dbg 命令字符串，语法和 GUI 命令行完全一致。
```
ExecuteDebuggerCommand(command="run")
ExecuteDebuggerCommand(command="bp kernel32:CreateFileW")
ExecuteDebuggerCommand(command="dump eax")
```

---

## 典型分析流程

### 注册验证 / 序列号破解

```text
1. GetDebugState() → 确认会话状态
2. LoadBinary(filePath="target.exe")
3. SearchForStrings(searchText="注册码错误") / GetStrings(module="target.exe")
4. GetReferences(address=命中字符串地址) → 定位判断函数
5. SetBreakpoint(target=判断函数地址) → run() → WaitForPause()
6. GetAllRegisters() + Disassemble(address="cip", count=20) → 理解校验逻辑
7. Assemble(address=条件跳转地址, instruction="jmp 目标") → 验证 patch
8. GetPatches() 确认改动范围，验证不通过就 RestorePatches()
```

### 脱壳

```text
1. AnalyzeModule(module="target.exe") → 看节区是不是典型加壳特征（少节区/高熵/异常特征位）
2. DetectOEP(module="target.exe") → 拿到疑似 OEP
3. RunToAddress(address=疑似OEP, timeoutMs=30000) → WaitForPause()
4. GetDumpableRegions() → DumpModule(module="target.exe", filePath="C:\dump\unpacked.exe")
5. 用 references/external-tool-downloads.md 里的 Scylla/ScyllaHide 修复导入表（IAT 一般会被壳破坏，纯 dump 还跑不起来）
```

### 恶意样本行为分析（防御性分析场景）

```text
1. AttachProcess(pid=可疑进程PID)（优先附加而不是直接双击运行，避免样本立刻发作）
2. SetBreakpoint(target="kernel32:CreateFileW") / SetBreakpoint(target="ws2_32:connect")
3. run() → WaitForPause() → GetArguments(count=4) → 看它在读写什么文件/连接哪个地址
4. GetCallStack() → 定位是谁调用的，回溯到样本自身代码
5. GetStrings(module=样本模块) → 找解密后的 C2 地址/配置字符串
6. DumpMemory 保存关键内存区域留证据，而不是只看一遍就放行继续执行
```

### CTF 逆向

```text
1. LoadBinary(filePath="chall.exe")
2. GetImports(module="chall.exe") → 看有没有 scanf/strcmp 等关键函数
3. SetBreakpoint(target=strcmp地址或输入校验函数) → run() → 输入任意值触发断点
4. GetArguments() / ReadMemory(address=参数指针) → 看比较的目标值
5. WatchExpressions(expressions="[esp+4],[esp+8]") 在循环校验里连续观察
6. 用 Python 现算/还原变换 → 得到 flag
```

---

## 常见错误与解决

| 错误/现象 | 原因 | 解决 |
|------|------|------|
| 调用 debug_only 工具直接报错 | 还没有调试会话 | 先 `GetDebugState()` 确认，再 `LoadBinary`/`AttachProcess` |
| `SetBreakpoint` 后读寄存器发现根本没停 | 断点还没命中，`run()` 是异步的 | `run()` 之后必须 `WaitForPause(timeoutMs=...)` |
| 新注册的 MCP server 工具调用不到 | Claude Code 当前会话没刷新工具列表 | 新开一次会话；先用 `scripts/status.ps1` 做 HTTP 层验证 |
| HTTP 请求返回 401 | token 不对，或插件重新生成过 token | 重跑 `scripts/install.ps1`，会用最新 token 覆盖 `claude mcp add` |
| `GetFunctions` 返回空 | 目标还没做过分析 | 先在 x64dbg GUI 按 `Ctrl+A` 跑一次分析，或 `ExecuteDebuggerCommand(command="analyse")` |
| `GetSEHChain` 报错/无意义 | 目标是 x64 | x64 没有传统 SEH 链，改用 `GetCallStack` + `GetPEB` |
| `WriteMemToAddress`/`Assemble` 改完程序崩了 | 覆盖字节长度算错，或改到了别的指令中间 | 改之前 `Disassemble` 确认指令边界和长度，改完 `RestorePatches` 可整体回滚 |
| dump 出来的脱壳程序打不开 | 壳破坏了导入表，纯内存 dump 不等于能跑的 PE | 用 Scylla/ScyllaHide 修复 IAT（见 `references/external-tool-downloads.md`） |
