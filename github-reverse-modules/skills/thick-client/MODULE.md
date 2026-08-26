---
name: thick-client
description: Use for authorized security testing of desktop thick clients including local storage, update channels, IPC, traffic, and client-side trust boundaries.
---


中文名：suimi 厚客户端逆向

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# Thick Client Security Testing

## 适用场景

- C/S 架构客户端、Electron/Qt/.NET WinForms/WPF
- 本地配置/凭证存储、IPC、命名管道
- 客户端强制校验绕过研究（授权）
- 自动更新通道与代码签名验证

## 工作流

### 1. 建边界

```text
□ 进程树、子进程、驱动/服务
□ 监听端口与出站域名
□ 本地敏感路径：%APPDATA%、Keychain、注册表
```

### 2. 本地攻击面

```text
□ 明文配置、硬编码密钥、调试开关
□ DLL 劫持/搜索顺序（Windows）
□ 数据库文件（SQLite）权限与加密
□ IPC：谁可连接？是否鉴权？
```

### 3. 网络面

```text
□ 系统代理 / 应用自定义 TLS
□ 证书钉扎 → 联合 mobile/js 方法学或 Frida
□ API 越权：客户端隐藏的管理接口
```

### 4. 逆向验证

```text
□ .NET → dotnet-reverse；原生 → ida/ghidra；Electron → asar + js-reverse
```

## 工具链

| 工具 | 用途 |
|------|------|
| Process Monitor / API Monitor | 行为 |
| Burp / mitmproxy | 流量 |
| dnSpy / IDA / Ghidra | 逆向 |
| Sysinternals | Windows 面 |
| asar / nexe 检测 | Electron |

## 参考

- `references/thick-client-checklist.md`
- `../dotnet-reverse/` `../ida-reverse/` `../js-reverse/` `../api-security/`

## 只读分析原则

胖客户端分析默认全程只读、可复现、可回滚：

- 先在副本上分析。复制安装目录与用户数据目录到隔离工作区，避免污染原始证据或触发自更新覆盖。
- 记录初始状态。分析前对目标目录做一次哈希清单（见"快速命令速查"），任何改动都能对照回滚。
- 代理与证书类改动必须登记。凡是导入系统信任区的 CA、改过的系统代理，结束时逐项还原。
- 不主动写目标进程内存、不 patch，除非已在报告中说明理由并获授权；理解阶段以静态反编译 + 被动流量观测为主。

## 判定客户端技术栈

先判断可执行体属于哪一类，再选反编译路径：

- .NET（C#/VB）：PE 头含 CLR 目录；`file` 报 "Mono/.Net assembly"，`rabin2 -I` 可见 .NET 相关字段；同目录常伴大量 `*.dll` 与 `*.deps.json` / `*.runtimeconfig.json`。
- Java：存在 `*.jar` / `*.class`，或启动器旁自带 JRE；可执行 jar 用 `unzip -l app.jar` 可见 `META-INF/MANIFEST.MF`。
- 原生 C/C++：无托管运行时特征，导入表为 kernel32/user32/msvcrt 等；深挖交给 `ida-reverse` / `ghidra-reverse` / `radare2`。
- Electron：目录含 `resources/app.asar` 或 `app/` + `node_modules`，主逻辑是打包 JS。
- Qt：依赖 `Qt*Core.dll` / `Qt*Gui.dll`，界面元信息可辅助定位。

## .NET 客户端静态反编译

标准只读工具链（择一或组合）：

- dnSpy / dnSpyEx：图形化反编译 + 可选调试，直接阅读 C# 与 IL。
- ILSpy 及其 CLI `ilspycmd`：批量导出源码，便于全局 grep。
- JetBrains dotPeek：图形化，适合浏览大型解决方案。
- 混淆样本先过 de4dot（开源反混淆）再反编译，可还原控制流与字符串常量。

```bash
# 用 ILSpy CLI 批量反编译一个程序集到源码目录
ilspycmd MyApp.dll -o ./src_out
# 反编译整个目录里的托管 dll
for d in *.dll; do ilspycmd "$d" -o "./src_out/${d%.dll}"; done
# 反编译后按关键词定位敏感逻辑
grep -rniE "password|token|AesManaged|RSA|licen[cs]e|https?://" ./src_out
```

关注点：硬编码密钥/连接串、`HttpClient`/`WebRequest` 端点、`Aes`/`RijndaelManaged`/`ProtectedData`(DPAPI) 调用、`#if DEBUG` 调试开关、反射动态加载。

## Java 客户端静态反编译

```bash
# 解包可执行 jar
mkdir app_src && (cd app_src && jar xf ../app.jar)   # 或 unzip app.jar -d app_src
# CFR 反编译整个 jar 到源码目录（开源）
java -jar cfr.jar app.jar --outputdir ./cfr_out
# Procyon 反编译单个 class
java -jar procyon-decompiler.jar app_src/com/x/Main.class > Main.java
```

图形化可用 JD-GUI / Recaf；`META-INF/MANIFEST.MF` 的 `Main-Class` 是入口；`*.properties` / `application.yml` 常含端点与开关。关注 `javax.crypto`、`KeyStore`、可能全信任的 `TrustManager`、`ProcessBuilder`。

## 本地配置、存储与依赖审查

```bash
# 敏感文件与配置（Windows 常见落点）
ls -la "$APPDATA" "$LOCALAPPDATA"
# SQLite 本地库结构与内容（只读打开）
sqlite3 -readonly local.db ".tables"
sqlite3 -readonly local.db ".schema"
# 注册表键（PowerShell）
reg query "HKCU\Software\Vendor\App"
# 原生依赖梳理
dumpbin /dependents App.exe          # MSVC 工具链
objdump -p App.exe | grep "DLL Name" # binutils
```

补充工具：Sysinternals `Procmon`（文件/注册表/网络行为）、`Autoruns`（自启动/服务）、`Process Explorer`（句柄/子进程/加载模块）、`sigcheck`（签名与版本）、`strings`。凭证若走 Windows DPAPI（`CryptProtectData`/`ProtectedData`），只记录调用位置与作用域，不导出明文。

## Electron 客户端

```bash
# 提取 asar 包（@electron/asar，开源）
npx @electron/asar extract resources/app.asar ./asar_out
grep -rniE "https?://|ipcMain|ipcRenderer|nodeIntegration|contextIsolation" ./asar_out
```

打包 JS 的反混淆 / source map 还原转 `js-reverse` / `browser-extension-reverse` 的方法学。`ipcMain`/`ipcRenderer` 通道与 `preload.js` 暴露面是 Electron 的信任边界重点。

## 流量代理与 TLS 观测配置

```bash
# 启动被动代理
mitmdump -p 8080            # mitmproxy，便于脚本化
# 让不同栈走代理
netsh winhttp set proxy 127.0.0.1:8080                                 # WinHTTP 系
java -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=8080 -jar app.jar   # Java 系统属性
```

TLS 拦截需把代理 CA 导入信任区（mitmproxy 首访 `http://mitm.it` 取证书）；分析结束用 `netsh winhttp reset proxy` 还原代理，并从证书存储移除临时 CA。遇到证书钉扎（pinning）时被动观测失效，改用运行时 hook（参见 `traffic-capture` 与 Frida 思路），仅在授权范围内进行。

## 证据与回滚

- 证据：反编译源码摘录（端点/密钥调用/信任边界代码）、`Procmon` 过滤后的行为轨迹、脱敏流量样本、依赖清单、配置项原文。
- 回滚：还原系统代理与 WinHTTP、移除临时 CA、删除工作副本；对照分析前的哈希清单确认原始目录零改动。
- 脱敏：抓到的真实 token/密钥/私有域名按黑名单占位符；算法、字段、调用点、公开端点结构一律保留原文。

## 快速命令速查

```bash
# 分析前建立哈希基线（回滚对照）
find . -type f -exec sha256sum {} \; > baseline.sha256
# 结束后核对是否有改动
sha256sum -c baseline.sha256 | grep -v ": OK$"
```

## 路由上下文

**上游**: MASTER R32  
**下游**: 纯协议 `protocol-reverse`；供应链更新 `supply-chain-security`

## 任务完成自检

- [ ] 是否画出信任边界？
- [ ] 本地+网络面是否都覆盖？
- [ ] Checklist？