# Cheat Engine MCP 工具速查

> 127 个 MCP 工具，按源码 `src/tool-registry.js` 的官方 14 分类整理（核对自源码，非推测）。
> 工具名固定 `ce_` 前缀（`ce_read_memory`、`ce_attach_process` 等）；在 Claude Code 里以 `mcp__<server名>__<工具名>` 形式出现，`<server名>` 是 `claude mcp add` 时起的名字（默认 `cheatengine`）。
> 标"[需要用户配合]"的工具有固定监控窗口（通常 10 秒/层），必须先提醒用户在目标程序里实际触发一次数值变化才有意义。
> 标"⚠️ [DANGEROUS]"的工具会在目标进程里真实执行代码，用前务必和用户说明风险。

---

## System 系统与连接

```
ce_ping()                                          # 测试连接，失败自动返回诊断建议
ce_get_process_info(refresh_symbols=false)          # [INIT] 附加后必须先调这个；refresh_symbols=true 首次可能耗时60-120秒
ce_list_processes(filter="game", max_results=100)   # 找目标进程
ce_attach_process(target="game.exe")                # 或传 PID；附加后清空缓存和扫描会话
ce_execute_lua(code="return getAddress('game.exe')") # 没有专用工具时的逃生舱
ce_auto_assemble(script="...", target_self=false, disable=false, disable_info=null)
ce_get_stats()                                       # 桥接统计：uptime/命令计数/缓存命中率
ce_get_logs(count=50, min_level="INFO")
ce_type_conversion(conversion="dword_to_bytes", value="1337")
```

---

## Memory 内存读写（永远批量优先）

```
ce_read_memory(address="game.exe+1234", type="dword")                     # 单次读
ce_read_memory_batch(requests=[                                            # [性能] 多地址一次读
  {"address":"game.exe+100","type":"dword","id":"hp"},
  {"address":"game.exe+104","type":"float","id":"mp"}
])
ce_write_memory(address="0x123456", type="dword", value="1337")
ce_write_memory_batch(requests=[{"address":"game.exe+100","type":"dword","value":"999"}])
```

`type` 可选: byte/word/dword/qword/float/double/string/bytes；`signed` 用于 word/dword 有符号读；`widechar` 用于 UTF-16 字符串。

---

## Memory Management 内存管理

```
ce_allocate_memory(size=256, protection="rwx")      # 代码洞/hook缓冲区，protection: rwx(执行)/rw(数据)
ce_deallocate_memory(address="0x10000000")
ce_get_memory_protection(address="0x10000000")
ce_set_memory_protection(address="0x10000000", size=64, readable=true, writable=true, executable=false)
ce_full_access(address="0x10000000", size=64)        # 一步到位设为 RWX
ce_copy_memory(source_address="0x1000", size=64, destination_address=null, method=0)  # method: 0=target-target/1=target-CE/2=CE-target/3=CE-CE
ce_compare_memory(address1="0x1000", address2="0x2000", size=64, method=0)
ce_enum_memory_regions()                             # 找可写/可执行区域做注入
```

---

## Scanning 扫描与搜索

### 字节特征扫描
```
ce_aob_scan(aob_string="48 89 5C 24 ?? 48 83 EC 20", module="game.exe", max_results=10)
ce_aob_scan_unique(aob_string="48 89 5C 24 ?? 48 83 EC 20", module="game.exe")   # [快] 只要唯一首个匹配时更快
ce_rip_scan(address="0x140001000", scan_range=50, module="game.exe")            # RIP相对寻址分析
```

### 一次性值扫描（已知目标地址附近，用于指针追踪第二步）
```
ce_value_scan(value="0x255D5E658", type="qword", module="game.exe")
```

### 扫描会话（数值找基址标准流程：首次扫描→再次扫描，最多5个并发会话，5分钟不活动过期）
```
ce_scan_new(value="100", type="dword", scan_type="exact")     # 已知血量=100
ce_scan_next(session_id="...", value="95", scan_type="decreased")  # 血量变少后再筛选
# scan_type 可选: exact/increased/decreased/changed/unchanged/increased_by/decreased_by/bigger_than/smaller_than/between
ce_scan_results(session_id="...", start_index=0, limit=100)
ce_scan_close(session_id="...")
ce_scan_list()
ce_enum_modules()
```

### 脚本与作弊表
```
ce_check_assemble(script="...", enable=true)          # 只验证语法不执行
ce_generate_script(template="alloc", name="myAlloc", size=64)   # template: alloc(推荐)/registersymbol/globalalloc
ce_memory_record_control(record_id="...", active=true)
ce_disassemble_bytes(bytes="48 89 5C 24 08", count=20)          # [离线] 不读进程内存，纯字节反汇编
ce_assemble_instruction(instruction="mov eax, 1337")             # 比 auto_assemble 更可靠，复杂指令优先用这个
ce_get_address_list(include_script=false)
ce_add_address_record(description="HP", address="game.exe+100", value_type="dword")
```

---

## Symbols 符号与地址

```
ce_get_address(expression="[[game.exe+100]+20]+8")    # 支持任意深度嵌套表达式
ce_get_address_safe(expression="...")                  # [安全] 解析失败返回 found:false 而不是抛错，适合批量试探
ce_get_symbol(address="0x140001000", include_module=true)
ce_get_region_info(address="0x140001000")
ce_auto_guess(address="0x140001000")                   # 猜测这个地址的值类型
ce_resolve_pointer(base="game.exe+100", offsets=[0x10, 0x20, 0x8], read_value=true, value_type="dword")
ce_register_symbol(symbol="myHookMem", address="0x10000000")
ce_unregister_symbol(symbol="myHookMem")
ce_pointer_size(size=null)                              # 省略 size 只读当前值；WoW64 32位目标要设为4
ce_get_rtti(address="0x140001000")                      # C++ 对象类名
ce_comment(address="0x140001000", text="血量校验入口")   # 省略 text 只读
ce_enum_symbols(operation="registered")
ce_get_symbol_info(symbol_name="CreateFileW")
ce_add_symbol_module(path="C:\\sym\\game.pdb", base_address="0x140000000")
ce_get_name_from_address(address="0x140001000", include_sections=true)
ce_symbol_control(operation="wait_dotnet")              # 阻塞直到 .NET 符号加载完
```

---

## Debug 调试与断点

```
ce_disassemble(address="0x140001000", count=10, direction="forward")
ce_get_instruction_info(address="0x140001000")
ce_set_breakpoint(address="0x140001000", type="execute", size=1)   # type: execute/write/access
ce_remove_breakpoint(address="0x140001000")
ce_get_breakpoints()
ce_break_and_get_regs(address="0x140001000", timeout=5000, stack_depth=16)   # [单次捕获]
ce_break_and_trace(address="0x140001000", max_steps=100, timeout=10000, stop_on_ret=true)  # [最强大] 逐指令捕获全部寄存器
ce_thread_breakpoint(address="0x140001000", thread_id=1234, type="execute")
```

### 高级调试
```
ce_debug_start(interface=2)     # 0=默认/1=Windows/2=VEH(绕过用户态反调试)/3=Kernel
ce_debug_status()
ce_debug_continue(method="stepinto")   # run/stepinto/stepover
ce_get_set_context(register_values={"RAX":"0x1234"}, include_xmm=false)
ce_thread_no_break(operation="add", thread_id=1234)
ce_debug_break_thread(thread_id=1234)
ce_detach_debugger()
```

---

## Process 进程控制

```
ce_pause_process() / ce_resume_process()
ce_speedhack(speed=0.5)          # 1.0正常，<1减速，>1加速
ce_enum_threads()
ce_enum_handles(filter=2)        # 0=全部/1=目标进程句柄/2=指向目标进程的句柄/3=CE自己的句柄
ce_open_file_as_process(filename="C:\\game\\a.exe")   # [离线] 不运行也能当进程分析
ce_create_process(path="C:\\game\\a.exe", break_on_entry=true)
ce_get_foreground_process()
ce_close_remote_handle(handle=1234)
ce_duplicate_handle(handle=1234, mode=0)
ce_target_info()                 # 架构/ABI/指针位宽
```

---

## Analysis 分析工具

### 找是什么代码在动这个地址（需要用户配合，监控固定约10秒）
```
ce_find_what_accesses(address="0x255D5E758", user_prompted=true, duration_ms=10000)  # F5：读+写都监控
ce_find_what_writes(address="0x255D5E758", user_prompted=true)                        # F6：只监控写
```
调用前必须先对用户说："接下来 10 秒内会监控这个地址，请在程序里触发一次数值变化"，确认后才传 `user_prompted=true`。

### 自动指针链追踪（首选）
```
ce_find_pointer_path(address="0x255D5E758", user_prompted=true, max_depth=7, strategy="hybrid")
# strategy: hybrid(推荐)/f5(纯F5)/value_scan(纯指针搜索)
# 成功返回 {base_address, offsets, ce_pointer_notation} 可直接抄进 CE 地址列表
```

### 静态代码分析
```
ce_analyze_code(address="0x140001000", count=20)              # 反汇编+提取call/jump/内存引用
ce_build_cfg(address="0x140001000", max_blocks=100, detect_loops=true)   # 整函数控制流图
ce_detect_patterns(address="0x140001000")                     # switch表/虚函数调用/字符串引用/加密常量/反调试特征
ce_compare_functions(address1="0x140001000", address2="0x140002000")
ce_trace_dataflow(address="0x140001000", register="rax", direction="both")     # 单寄存器数据流
ce_program_slice(address="0x140001000", criterion="rax", direction="backward") # [进阶] 跨寄存器程序切片
ce_analyze_struct_access(base_address="0x140001000", scan_range=512)          # 静态猜结构体字段
ce_trace_struct_access(address="0x140001000", size=4, duration_ms=1000)       # 动态监控结构体访问
ce_find_references(address="0x140001000", limit=50)
ce_find_call_references(address="0x140001000", module="game.exe")
ce_find_function_boundaries(address="0x140001000")             # 找不到函数起止时先跑这个
ce_checksum_memory(address="0x140001000", size=256)             # MD5，检测代码是否被改
ce_generate_signature(address="0x140001000")                   # 生成版本无关AOB特征码
ce_structure_manage(operation="create", name="Player", size=64)
ce_dissect_code(module="game.exe", analyze_functions=true)      # 整模块分析
ce_cleanup()                                                    # 游戏卡住/断点清不掉时的兜底
```

### 函数 Hook（非阻塞，边跑边抓参数）
```
ce_hook_function(address="0x140001000", name="on_damage", capture_args=4, capture_return=true)
# name 必须匹配 ^[a-zA-Z_][a-zA-Z0-9_]*$
ce_get_hook_log(name="on_damage", limit=20, clear=false)
ce_clear_hook_log(name="on_damage")
ce_unhook_function(name="on_damage")   # 分析完记得清理，恢复原始代码
ce_list_hooks()
```

### 代码模拟
```
ce_symbolic_trace(address="0x140001000", count=30, initial_state={"rcx":"this_ptr"})  # [安全] 不执行代码
ce_call_function(address="0x140001000", args=[1,2], call_method=3, return_type="qword")  # ⚠️ [DANGEROUS] 真实执行
```

---

## Injection 注入

```
ce_inject_dll(dll_path="C:\\mod\\hook.dll")
ce_inject_dotnet_dll(dll_path="C:\\mod\\hook.dll", class_name="Mod.Main", method_name="Run")
ce_compile_c_code(code="int add(int a,int b){return a+b;}")     # CE内置TCC编译器
ce_compile_c_sharp(code="...")                                  # 配合 ce_inject_dotnet_dll 使用
ce_execute_method(address="0x140001000", class_instance="0x255D5E758", args=[1])  # ⚠️ [DANGEROUS]
ce_create_remote_thread(address="0x140001000", parameter=0)
ce_generate_api_hook_script(address="0x140001000", jump_address="0x150000000")   # 生成完整AA hook脚本
ce_dump_memory(address="0x140001000", size=4096, file_path="C:\\dump\\region.bin", mode="dump")  # mode: dump/load/compare
```

---

## DotNet .NET 分析（Unity/Mono 专用）

```
ce_dotnet_analyze(operation="domains")
ce_dotnet_analyze(operation="objects", module_handle=1, typedef_token=100)
# operation: domains/modules/typedefs/methods/fields/objects/address_data
```

---

## FileIO / Window / Kernel / Table

```
ce_md5_file(file_path="C:\\game\\a.exe")
ce_file_version(file_path="C:\\game\\a.exe")
ce_file_ops(operation="list_files", path="C:\\game", search_mask="*.dll")
ce_write_region_to_file(address="0x140001000", size=4096, file_path="C:\\dump\\a.bin")
ce_read_region_from_file(address="0x10000000", file_path="C:\\shellcode.bin")

ce_find_window(caption="游戏窗口标题")
ce_enum_windows()

ce_allocate_shared_memory(name="myshare", size=4096)
ce_get_physical_address(address="0x140001000")
ce_dbvm_cloak(operation="activate", address="0x140001000")   # 需要 CE 已启用 DBVM 驱动

ce_load_table(filename="C:\\table.ct", merge=false)
ce_save_table(filename="C:\\table.ct")
```

---

## 典型分析流程

### 数值找基址（最常见）

```text
1. ce_attach_process(target="game.exe") → ce_get_process_info()
2. ce_scan_new(value="当前值", type="dword")
3. 提醒用户在游戏里改变这个值 → ce_scan_next(session_id, value="新值", scan_type="decreased")
4. 重复直到 ce_scan_results 收敛到个位数结果
5. ce_find_pointer_path(address=找到的地址, user_prompted=true) 拿静态指针链
6. ce_add_address_record 存进作弊表，ce_save_table 落盘
```

### 函数 Hook 抓调用参数

```text
1. ce_aob_scan_unique 或 ce_find_function_boundaries 定位函数
2. ce_hook_function(address, name="my_hook", capture_args=4)
3. 提醒用户运行一段时间触发调用
4. ce_get_hook_log(name="my_hook") 看捕获的参数
5. ce_unhook_function 清理
```

### 反调试/反作弊分析

```text
1. ce_detect_patterns(address=可疑函数) → 看 has_anti_debug
2. ce_debug_start(interface=2) 用 VEH 模式绕过用户态反调试探测
3. 需要隐藏内存 patch 时用 ce_dbvm_cloak(operation="activate")（前提 DBVM 已启用）
4. ce_find_call_references 找谁调用了检测函数，评估能否 hook 掉
```

### 逆向未知代码

```text
1. ce_disassemble(address, count=20)
2. ce_symbolic_trace(address, initial_state={"rcx":"this"}) 理解逻辑（安全，不执行）
3. ce_build_cfg(address) 复杂函数上控制流图
4. ce_detect_patterns(address) 检测特征
```

---

## 常见错误与解决

| 错误/现象 | 原因 | 解决 |
|------|------|------|
| `ce_ping` 返回连接失败 | CE 没开，或 Lua 桥没加载 | 打开 CE，在 CE 里 `Ctrl+Alt+L` 手动 `dofile([[...ce_mcp_bridge.lua]])`，或把它放进 `autorun` 目录重开 CE |
| 大部分工具报错/空结果 | 还没附加进程 | 先 `ce_attach_process`，再 `ce_get_process_info` |
| `find_what_accesses`/`find_pointer_path` 空手而归 | 监控窗口内用户没有实际触发变化 | 明确提醒用户"接下来10秒请操作程序"再调用 |
| Hook 名字报错 | 名字不满足 `^[a-zA-Z_][a-zA-Z0-9_]*$` | 换成合法标识符，如 `"my_hook"` 而不是 `"my hook"` |
| 扫描新会话失败 | 已有5个并发会话 | `ce_scan_list` 看现有会话，`ce_scan_close` 关掉不用的 |
| `ce_call_function`/`ce_execute_method` 把目标进程搞崩 | 调用约定/参数类型/参数个数不对 | 先用 `ce_symbolic_trace` 或 `ce_disassemble` 确认函数签名，参数上限4个（fastcall） |
| `ce_dbvm_cloak` 报错 | DBVM 驱动没启用 | 普通安装默认不带 DBVM，需要在 CE 里额外启用，不是 bug |
| 首次 `ce_get_process_info(refresh_symbols=true)` 卡很久 | 大型进程符号刷新本来就慢 | 属于正常现象，60-120秒量级，不要当成挂了 |
| CE 重启后连不上 | 桥接进程随 CE 一起没了 | 重开 CE（自动加载 autorun 里的桥），MCP server 会自动重连，无需重新 `claude mcp add` |
