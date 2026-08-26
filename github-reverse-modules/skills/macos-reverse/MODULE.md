---
name: macos-reverse
description: Use for authorized macOS and Mach-O reverse engineering including codesign, Objective-C/Swift recovery, endpoint security surfaces, and Apple platform malware analysis.
---


中文名：suimi macOS 逆向

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# macOS / Mach-O Reverse Engineering

## 适用场景

- Mach-O 可执行文件 / dylib / framework
- .app bundle、LaunchAgent/Daemon
- Objective-C / Swift 符号与 runtime
- 公证/签名、Hardened Runtime、TCC 相关行为分析
- macOS 恶意软件静态/动态分析（联合 malware-analysis）

## 工作流

### 1. 包体与签名

```bash
file target
codesign -dv --verbose=4 target
spctl -a -vv target 2>&1
otool -L target
```

### 2. 静态

```text
□ class-dump / swift-demangle / Hopper / Ghidra / IDA
□ 字符串与 XPC 服务名、TCC 敏感 API
□ LC_LOAD_dylib 依赖与 rpath
```

### 3. 动态

```text
□ lldb / Frida
□ fs_usage / log stream 观察
□ 网络：联合 protocol-reverse 或代理
```

## Mach-O 结构速读

Mach-O 是苹果平台可执行文件 / 库 / 内核扩展的原生格式，逆向前先看清 header 与 load commands。

```text
□ 魔数：0xFEEDFACF(64位 MH_MAGIC_64) / 0xFEEDFACE(32位) /
  0xCAFEBABE(FAT/通用二进制头，含多架构切片)
□ 通用二进制：lipo -info 看架构；lipo bin -thin arm64 -output bin.arm64 拆单架构
□ Header：otool -hv（cputype / filetype / flags，如 PIE、含加密标志）
□ Load commands：otool -l —— 关注
  LC_SEGMENT_64(__TEXT/__DATA/__LINKEDIT)、LC_MAIN(入口)、LC_LOAD_DYLIB(依赖)、
  LC_RPATH、LC_CODE_SIGNATURE、LC_ENCRYPTION_INFO_64(加密段)、LC_UUID、LC_BUILD_VERSION
□ 关键节区：__TEXT.__text(代码)、__TEXT.__cstring(C 串)、
  __DATA.__objc_classlist/__objc_data(ObjC 元数据)、__TEXT.__swift5_*(Swift 元数据)
```

## 静态分析工作流

系统自带 otool / nm 足以完成第一轮静态分诊，再上反编译器。

```bash
otool -hv ./app            # header：架构、文件类型、标志
otool -l ./app             # 全部 load commands（依赖、段、签名、加密）
otool -L ./app             # 依赖 dylib 及版本
otool -tv ./app            # 反汇编 __text（-V 解析符号）
otool -oV ./app            # ObjC 段：类 / 方法 / 协议
nm -m ./app                # 符号表（-m 显示段/属性），-arch 指定架构
```

Objective-C / Swift 符号恢复：

```text
□ ObjC：class-dump 还原 @interface 头（方法/属性/ivar）；dyld 缓存里的类用
  dsdump / classdump-dyld
□ ObjC 方法名本就在 __objc_methname 明文可见，是极好的语义线索
□ Swift：符号以 $s / _$s 前缀 mangling，用 xcrun swift-demangle 还原；
  Ghidra / IDA 也内置 Swift/ObjC demangler
□ 反编译主力：Ghidra(免费) / Hopper / IDA / Binary Ninja，结合字符串 xref 定位逻辑
```

## 代码签名与 entitlements（只读查看）

签名与授权(entitlements) 决定进程能力边界，静态阶段**只读查看**即可获得大量行为线索，不需要也不应破坏签名。

```bash
codesign -dv --verbose=4 ./app          # 签名信息：TeamID、CDHash、签名标志
codesign -d --entitlements :- ./app     # dump entitlements（旧格式）
codesign -d --entitlements - --xml ./app 2>/dev/null   # XML 形式
spctl -a -vv ./app 2>&1                 # Gatekeeper 评估（是否被公证/信任）
```

关注 `com.apple.security.*`（沙盒、网络、文件访问）、`get-task-allow`（可被调试）、Hardened Runtime 与 Library Validation 标志——它们直接对应样本的权限与可注入性。

## 动态分析工作流

```text
□ lldb ./app：image list（模块基址/UUID）、image dump sections、
  breakpoint set -n symbol、disassemble、register read
□ Frida：附加进程 hook ObjC/Swift/C 方法；ObjC 用 ObjC.classes 枚举
□ 系统可观测性（只读）：fs_usage 看文件访问、log stream --predicate 看日志、
  dtruss/ktrace 看系统调用、nettop/代理看网络
□ SIP/公证限制下，调试第三方进程需在受控测试机与授权范围内进行
```

## dyld 共享缓存（标准提取做法）

现代 macOS/iOS 的系统库不再以独立 dylib 存在磁盘，而是合并进 dyld shared cache；要分析某个 framework 需先从缓存提取。

```text
□ 缓存位置（随系统版本）：/System/Library/dyld/ 或
  /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/
□ 提取标准工具：
  - dyld_shared_cache_util -extract <out_dir> <cache>（dyld 开源工具集）
  - blacktop/ipsw：ipsw dyld extract <cache> <dylib_path>
  - jtool2 / 反编译器（IDA、Ghidra 均可直接加载缓存并选目标 dylib）
□ 提取后按普通 Mach-O 走静态流程；记录来源系统版本与 UUID 以便复现
```

## 工具链

| 工具 | 用途 |
|------|------|
| otool / nm / codesign | 系统自带 |
| Hopper / Ghidra / IDA | 反编译 |
| class-dump / dsdump | ObjC |
| Frida / lldb | 动态 |
| jtool2 | Mach-O |

## 证据与回滚

- 全程只读优先：otool / nm / codesign -d / class-dump / lldb（只读读取）都不修改样本；`codesign -d` 只查看签名，绝不重签或剥签。
- 完整性基线：分析前 `shasum -a 256 ./app` 留底；从 dyld 缓存提取的 dylib 单独存放并记录来源系统版本 / UUID。
- 结论留痕：架构与 UUID、LC_MAIN 入口、依赖 dylib 与 rpath、entitlements 关键项、恢复的 ObjC/Swift 符号与关键字符串 xref 地址。
- 回滚：静态分析无副作用；动态调试在受控测试机进行，结束后清理断点与注入，不残留对系统进程的改动。
- 边界：仅在授权范围与合规前提下分析；涉及 SIP / 公证 / 沙盒的绕过属受限操作，非必要不触碰。

## 参考

- `references/macho-triage.md`
- `../mobile-reverse/`（iOS） `../ghidra-reverse/` `../malware-analysis/`

## 路由上下文

**上游**: MASTER R31  
**下游**: iOS → mobile-reverse；通用样本 → malware-analysis

## 任务完成自检

- [ ] 是否记录签名/Hardened Runtime 状态？
- [ ] 是否有地址级/符号级结论？
- [ ] Checklist？