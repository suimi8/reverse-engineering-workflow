---
name: traffic-capture
description: |
  抓包与网络流量分析技能。当用户需要抓取一个本地程序/桌面应用/移动端的网络请求、分析 HTTP(S) API、还原接口协议、导出请求响应、排查"这个软件到底往哪发数据/发了什么"、解密 TLS 流量、或在逆向过程中需要用真实流量作为证据时，使用此技能。

  Use this skill when the user wants to capture, inspect, or decrypt the network traffic of a local binary, desktop app, or mobile target — sniffing HTTP(S) APIs, recovering request/response shapes, exporting endpoints, or proving what a program sends over the wire. This includes requests like "帮我抓一下这个软件的包", "看看它调用了哪些接口", "把请求导出来", "这个 HTTPS 能不能解密", "它登录时往服务器发了什么" 等，无论用户是否点名 tshark/Wireshark/mitmproxy。

  Two capture paths are bundled: an OS/interface-level tshark capture (broad coverage, TLS via SSLKEYLOGFILE) and a mitmproxy man-in-the-middle addon (proxy-routed, full decrypted HTTP bodies). Use the bundled scripts (scripts/capture-tshark-run.ps1, scripts/mitm_dump_summary.py) instead of writing ad-hoc capture commands.
---


中文名：suimi抓包与流量分析
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# 抓包与流量分析技能

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，并按需用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 维护学习闭环。

本模块专注于**网络证据**：程序真实发出的连接、SNI/域名、HTTP(S) 请求响应、接口协议与鉴权字段。与静态反编译（`ida-reverse`）或运行时调试（`x64dbg-reverse`）互补——很多"它到底怎么和服务器交互"的问题，抓一次包比读一万行反汇编都快。

## 两条抓包路径（先选对路，再动手）

| 路径 | 脚本 | 覆盖面 | TLS 解密方式 | 什么时候用 |
|------|------|--------|--------------|-----------|
| 接口级抓包 | `scripts/capture-tshark-run.ps1` | 广（OS 网卡层，不管目标走不走代理都能看到） | 依赖目标遵守 `SSLKEYLOGFILE`（Chromium/Electron/OpenSSL/BoringSSL 系多数支持） | 目标不吃 `HTTP(S)_PROXY`、走裸 TCP/UDP、或你还不知道它连了哪些主机 |
| 代理中间人 | `scripts/mitm_dump_summary.py` | 窄（只看路由进代理的流量） | mitmproxy 根证书解密，拿到完整明文 body | 目标遵守系统代理/可配置代理，需要看完整请求响应体、改包重放 |

选择原则：

1. **先判断目标认不认代理**。认代理（多数带"系统代理"开关的桌面/移动 App）优先 mitmproxy，能直接拿明文 body。
2. **不认代理、或自签校验/证书绑定**导致 mitmproxy 连不上时，退回 tshark 接口级抓包，先拿连接元数据（谁、哪个域名、SNI、端口、频率），再决定要不要上 `SSLKEYLOGFILE` 解密。
3. **两条路可以叠加**：tshark 负责"看全貌不漏连接"，mitmproxy 负责"看清楚选定接口的明文"。

## 脚本资源

### capture-tshark-run.ps1 — 接口级抓包 + TLS keylog

路径：`scripts/capture-tshark-run.ps1`

- 带 `SSLKEYLOGFILE` 环境变量启动目标程序，同时用 tshark 在网卡层抓包，输出 `.pcapng` 和对应的 `.sslkeylog.log`
- 接口号缺省时，自动从默认路由（`0.0.0.0/0`）对应网卡反查 tshark 接口，反查失败会提示用 `-ListInterfaces` 手动选
- 抓包时长到 `-DurationSeconds`（默认 60s）自动停止；可用 `-CaptureFilter` 传 BPF 过滤器（如 `host 1.2.3.4`、`tcp port 443`）实时收窄
- 缺 tshark 时输出 `ERR:tshark_missing` 并打印 Wireshark 官方下载页（安装包自带 Npcap，保持勾选），**不会**编造直链或静默安装抓包驱动

**关键参数**：

| 参数 | 作用 |
|------|------|
| `-TargetExe` | 要启动并抓包的目标程序路径（必填，除非只 `-ListInterfaces`） |
| `-TargetArgs` | 传给目标的命令行参数（单个字符串，原样传入） |
| `-DurationSeconds` | tshark 抓包时长，默认 60 秒后自动停 |
| `-Interface` | tshark 接口号/名（来自 `tshark -D`），缺省自动探测 |
| `-CaptureFilter` | 实时 BPF 抓包过滤器，留空则全量抓、分析时再过滤 |
| `-OutDir` | `.pcapng` 与 keylog 输出目录，默认 `.\captures` |
| `-NoSslKeyLog` | 不设 `SSLKEYLOGFILE`，只抓加密流量（只要连接元数据/SNI 时用） |
| `-ListInterfaces` | 打印 `tshark -D` 后退出，自动探测失败时先用它选接口号 |

**调用方式**：
```powershell
# 先列接口（自动探测失败时）
powershell -File "github-reverse-modules\skills\traffic-capture\scripts\capture-tshark-run.ps1" -ListInterfaces

# 启动目标并抓 90 秒，自动选网卡，输出到默认 .\captures
powershell -File "github-reverse-modules\skills\traffic-capture\scripts\capture-tshark-run.ps1" -TargetExe "C:\目标.exe" -DurationSeconds 90

# 只关心某台服务器，实时 BPF 过滤 + 指定接口
powershell -File "github-reverse-modules\skills\traffic-capture\scripts\capture-tshark-run.ps1" -TargetExe "C:\目标.exe" -Interface 5 -CaptureFilter "host 203.0.113.10"
```

**输出约定**：
```
OK:pcap=<路径>            # 抓包文件
OK:sslkeylog=<路径>       # TLS 密钥日志（未加 -NoSslKeyLog 时）
INFO:capturing:...        # 目标 PID / 接口 / 时长
INFO:decrypt_hint:...     # 在 Wireshark 里挂 keylog 解密的操作提示
ERR:tshark_missing        # 没装 tshark/Wireshark，紧跟 INFO 下载页
ERR:interface_autodetect_failed   # 网卡反查失败，改用 -ListInterfaces
```

> 解密提示：pcap 用 Wireshark 打开，Edit → Preferences → Protocols → TLS →(Pre)-Master-Secret log filename 填上面那个 `sslkeylog` 路径即可解密 TLS。部分 App 用 OS 级凭据缓存自解析鉴权、绕过 `SSLKEYLOGFILE`，这类目标解不出明文属正常，退回 mitmproxy 或运行时 hook。

### mitm_dump_summary.py — mitmproxy 明文流量落盘

路径：`scripts/mitm_dump_summary.py`

- mitmproxy 插件（addon），用 `mitmdump -s mitm_dump_summary.py` 加载
- 每条 HTTP(S) flow 落一行 JSON 到 JSONL：`time/method/url/host/port/status_code`、完整请求/响应头，以及尽力解码后**截断到 4000 字**的文本 body
- 只 dump 文本类 body（content-type 命中 `json/text/xml/form-urlencoded/javascript`）；二进制 body 只记长度不落内容，保证 JSONL 可读
- 输出路径由环境变量 `MITM_SUMMARY_PATH` 控制，缺省 `mitm_summary.jsonl`（当前目录）
- 单条 flow 解码/写盘异常都被吞掉，绝不因为记日志把代理本身搞挂

**调用方式**：
```powershell
# 1) 启动带该 addon 的 mitmproxy（默认监听 127.0.0.1:8080）
$env:MITM_SUMMARY_PATH = "C:\captures\mitm_summary.jsonl"
mitmdump -s "github-reverse-modules\skills\traffic-capture\scripts\mitm_dump_summary.py"

# 2) 让目标走代理：系统代理设 127.0.0.1:8080，或给目标传 HTTP(S)_PROXY
#    首次需在目标上信任 mitmproxy 根证书（http://mitm.it 下载安装）

# 3) 分析产出的 JSONL：每行一个请求响应摘要，可直接 grep/jq 过滤接口
```

> 证书绑定（certificate pinning）会让 mitmproxy 握手失败。移动端可配合 `mobile-reverse`/`apk-reverse` 的 Frida unpinning；桌面端优先退回 tshark 接口级抓包看连接元数据。

## 抓包分析完整工作流

1. **明确目标与范围**：哪个进程、关心哪些域名/接口、要元数据还是明文 body、是否需要重放。
2. **选路**：认代理→mitmproxy 拿明文；不认代理/走裸协议→tshark 接口级抓包。
3. **建立基线抓包**：先抓一段"什么都不点"的空跑流量，再抓一段"执行目标操作"的流量，两者对比，噪声连接一眼可分。
4. **定位关键接口**：从 JSONL/pcap 里按 host、路径、状态码收敛到承载目标功能的那几个请求。
5. **还原协议**：固定 URL、方法、鉴权字段（token/签名/时间戳）、请求体结构、响应关键字段。
6. **验证假设**：改包重放（mitmproxy）或对照多次抓包，确认哪个字段真正驱动服务端行为，一次只改一个变量。
7. **留存证据**：保存 `.pcapng`、`sslkeylog.log`、`mitm_summary.jsonl`、关键请求样本和还原笔记，供后续 patch/复现使用。

## Prompt 工程准则

1. **先看连接再看内容** — 拿不到明文时不要卡死，先用 tshark 看"连了谁、SNI 是什么、多频繁"，元数据本身就是强证据。
2. **抓包要有对照** — 空跑基线 vs 触发操作，两段流量做差，才能从一堆遥测/更新检查里挑出目标接口。
3. **解密失败先归因** — 分清是"目标不吃 `SSLKEYLOGFILE`"、"证书绑定挡了 mitmproxy"、还是"根本没走代理"，三种原因对应三种退路，别盲目重试。
4. **实时过滤 vs 事后过滤** — 已知目标主机就用 `-CaptureFilter` 实时收窄；不确定就全量抓、分析时再用 host/端口过滤，避免漏掉意外连接。
5. **改包重放前留原始样本** — 重放/改字段前先存一份原始请求响应，验证失败可对照回滚。
6. **别把遥测当业务** — 崩溃上报、更新检查、广告 SDK 会淹没真正的业务接口，按域名归类后先排除已知第三方。

## 路由上下文

**上游入口**：根目录 `SKILL.md`（总控）、`references/reverse-task-recipes.md`

**同级/相关模块**（按需加载，均在 `github-reverse-modules/skills/` 或 `security-research-modules/skills/` 下）：
- 移动端抓包 + 证书 unpinning → `mobile-reverse`、`apk-reverse`
- 抓到明文接口后要做授权/注入/BOLA 等安全评估 → `security-research-modules/skills/hack`（先到总入口再分流到 `api-sec`、`auth-sec` 等）
- 需要静态确认加密/签名算法出处 → `ida-reverse`
- 需要运行时 hook 交叉验证请求构造 → `x64dbg-reverse`、`references/dynamic-hooking.md`

**下游出口**：
- 还原出接口后要持久化改行为 → `references/patching-packaging.md`
- 反调试/反抓包/流量混淆 → `references/anti-analysis.md`

## 前置条件

- 接口级抓包：Windows + Wireshark/tshark（安装包自带 Npcap，保持勾选）；`capture-tshark-run.ps1` 缺 tshark 会打印官方下载页而不是裸报错
- 代理中间人：已安装 mitmproxy（`mitmdump` 在 PATH 上），且目标已信任 mitmproxy 根证书
- PowerShell 5+（接口级抓包脚本）；Python 3 + mitmproxy 运行环境（addon 脚本）
