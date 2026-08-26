---
name: go-rust-reverse
description: Use for reverse engineering stripped Go and Rust binaries including runtime recognition, pclntab/moduel data recovery, panic strings, and idiomatic decompilation recovery.
---


中文名：suimi Go/Rust 逆向

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# Go / Rust Binary Reverse Engineering

## 适用场景

- 剥离符号的 Go 恶意软件/工具
- Rust 发行二进制、panic 字符串驱动分析
- 与通用 ida/ghidra 互补的语言专用方法

## 工作流

### Go

```text
□ 识别 go.buildid、runtime 符号残留、pclntab
□ GoReSym / redress / IDA Go 插件恢复函数名
□ 注意 interface、slice、string 结构在反编译中的形态
□ 网络/加密库路径：crypto/* net/http
```

### Rust

```text
□ panic 字符串、rust_begin_unwind、crate 路径暗示
□ 范型实例化导致的代码膨胀；先定位字符串 xref
□ 异步/tokio 状态机需结合交叉引用
```

### 动态

```text
□ 仍可用 Frida；注意 Go 栈与调度
□ 优先日志与配置字符串驱动断点
```

## Go：符号与元数据恢复

Go 二进制即使 strip 也几乎无法真正「无符号」——运行时反射 / panic 依赖 .gopclntab(PC-line 表)，其中含完整函数名表，是 Go 逆向第一抓手。

```text
□ 识别语言：strings 出现 go:buildid、runtime.、GOROOT、/usr/local/go/src、
  runtime.buildVersion，或节区含 .gopclntab / .go.buildinfo
□ 定位 pclntab（按魔数扫描）：
  0xFFFFFFFB(Go1.2–1.15) / 0xFFFFFFFA(1.16–1.17) / 0xFFFFFFF0(1.18+)
□ 版本与依赖：go version <binary> 与 go version -m <binary>
  （后者打印 module path 与依赖清单，源自 .go.buildinfo）
□ 用 GoReSym(Mandiant) 离线提取函数名 / 源文件 / 类型 / build info → JSON
□ 恢复函数名后再进 IDA / Ghidra，否则满屏 sub_xxxx
```

类型与接口：Go 的 interface 是 iface{tab,data}，tab(itab) 指向具体类型方法表；string / slice 是 {ptr,len} / {ptr,len,cap}。反编译里成对出现「取 +0 指针、+8 长度」多半是 string/slice。用 GoReSym / redress 或 Ghidra 的 Go 分析插件（如 GhidraGolangAnalyzer）回填 moduledata 与类型信息。

字符串定位：Go 字符串**非 NUL 结尾**，常量被拼接成大块，`strings` 会得到超长连体串；正确做法是从代码里「载入指针 + 载入长度」指令对反推边界，或依赖插件按 pclntab / 类型信息切分。

## Rust：panic 字符串与符号 demangle

Rust 无稳定 ABI，泛型单态化(monomorphization) 导致大量近似的函数副本，直接读汇编易迷路——**先靠字符串与 panic 元数据建立骨架**。

```text
□ 识别语言：strings 出现 /rustc/<hash>/library/、src/…/*.rs 路径、
  called `Option::unwrap()` on a `None`、index out of bounds、
  cargo/crate 名、core:: / alloc:: / std:: 前缀
□ panic/unwind 锚点：rust_begin_unwind、core::panicking::panic、panic_fmt、
  断言失败信息 —— 其 xref 直指业务分支
□ demangle：v0(新版,RFC2603) 用 rustfilt / rustc-demangle；
  legacy(带 hash 后缀) 多数工具可解，c++filt 对 v0 无效
□ 泛型膨胀：先按字符串 xref 找入口再局部展开，别试图通读全部实例
```

Rust 的 &str / String 同样是 ptr+len(UTF-8，非 NUL 结尾)；Result / Option 的错误分支常紧跟 panic 字符串，是定位关键逻辑的高价值信号。Ghidra / IDA / Binary Ninja 内置 demangler 对 legacy 支持较好，v0 建议外挂 rustfilt 统一处理。

## 工具链

| 工具 | 用途 |
|------|------|
| GoReSym | Go 元数据 |
| IDA/Ghidra + Go/Rust 插件 | 反编译 |
| radare2 | 快速字符串 |
| strings / rabin2 | 分诊 |

## 常用命令

```bash
# 语言 / 版本 / 依赖识别
strings -a bin | grep -E 'go:buildid|runtime\.|/rustc/|\.rs$|cargo'
go version ./bin              # Go：读嵌入版本
go version -m ./bin           # Go：读 module 与依赖清单

# Go 元数据离线提取（GoReSym 需自行获取）
GoReSym -t -d -p ./bin > goresym.json   # 类型/函数/build info → JSON

# Rust 符号 demangle
rustfilt < mangled_names.txt              # 批量还原 v0/legacy 符号
nm ./bin 2>/dev/null | rustfilt | head    # 结合 nm 提取符号再还原

# 通用分诊
rabin2 -zzq ./bin | head                  # 字符串（含地址）
rabin2 -I ./bin                           # 格式/架构/是否 stripped
```

## 证据与回滚

- 全流程只读：识别、GoReSym 提取、demangle、反编译标注均不修改样本；写模式仅在明确要 patch 时才用。
- 结论留痕：记录 Go 版本与 pclntab 魔数/偏移、恢复的函数名映射、关键 panic/日志字符串及其 xref 地址；Rust 记录 crate 线索与 demangle 前后符号对照。
- 完整性基线：分析前留 sha256；GoReSym / 反编译导出的 JSON、伪代码文本单独存放，不回写样本。
- 常见误区：把拼接的 Go 字符串块当成单一字符串误报；对 Rust v0 用错 demangler(c++filt) 得到空结果——换 rustfilt 复核。

## 参考

- `references/go-rust-notes.md`
- `../reverse-engineering/go-reverse.md` `../ida-reverse/` `../ghidra-reverse/`
- seed: `field-journal/seed-002_go-malware-stripped.md`

## 路由上下文

**上游**: MASTER R33  
**下游**: 恶意样本流程 `malware-analysis`；通用 RE `reverse-engineering`

## 任务完成自检

- [ ] 是否恢复关键函数名或等价映射？
- [ ] 是否标注语言运行时证据？
- [ ] Checklist？