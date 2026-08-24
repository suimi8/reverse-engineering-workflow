---
name: osint-recon
description: >-
  OSINT/recon tool catalog lookup with a bundled local snapshot of the external rawfilejson/awesome-osint-arsenal GitHub repo (753 tools across 26 categories: username/email/domain/IP/SOCMINT/GEOINT/dark-web/breach-search/forensics, plus bundled red-team and blue-team installers). Use when a task needs "which OSINT tool covers X" lookups, target/asset reconnaissance tooling choices, or a safety review before running its bundled install.sh/category installers. Single entry point — the 753-tool data file is queried on demand, never loaded in full.
---


中文名：suimi OSINT 侦察工具库

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# OSINT 侦察工具库

本模块把外部仓库 [`rawfilejson/awesome-osint-arsenal`](https://github.com/rawfilejson/awesome-osint-arsenal) 接入 [recon-for-sec](../recon-for-sec/MODULE.md) 的侦察阶段。**唯一入口就是本文件**：753 个工具的完整数据本地打包在 `references/tools-snapshot.json`，正文只放"分类总览表 + 查询命令"，不会把 753 条记录展开成正文或拆成多个子模块——具体某个工具，只在真正要用它的时候才现查那一个分类，不预先摊开。

## 何时用

- 逆向/安全评估进入侦察阶段，需要按用户名、邮箱、域名、IP、证件照片、暗网、数据泄露等方向找具体开源工具
- 想按分类批量了解某类 OSINT 能力有哪些现成实现，而不是逐个凭记忆列举
- 准备执行该仓库的 `install.sh` 或某个分类脚本前，需要先核实它到底装了什么、要不要 root、有没有需要单独隔离评估的攻击性工具

## 数据来源：本地快照优先

`references/tools-snapshot.json` 是 2026-08-24 从上游 `tools.json` 原样落地的完整快照（753 条记录，26 个分类，逐字节比对两次抓取一致）。做这份本地快照是因为原始上游依赖 `raw.githubusercontent.com`，在本机环境下实测会间歇性握手失败（同一批文件里有的成功有的直接 TLS 报错），只写"现查上游"这一条路径不够可靠。

- **默认查本地快照**：不需要网络，不受当天 GitHub 连通性影响，内容与上游一致到快照日期。
- **需要最新数据时**再按下方"刷新快照"命令现查上游，两者命令结构一致，只是换个文件路径/URL。
- 快照是数据文件，不是文档：**不要把它整份读进上下文**，一律用 `jq`/`ConvertFrom-Json` 过滤出需要的几条再看。

**新鲜度自检**（没有自动刷新机制，靠这条命令手动判断要不要刷新）：

```powershell
$snapshot = Get-Item "security-research-modules\skills\osint-recon\references\tools-snapshot.json"
$ageDays = (Get-Date) - $snapshot.LastWriteTime
"快照日期: $($snapshot.LastWriteTime.ToString('yyyy-MM-dd'))  已过去 $([int]$ageDays.TotalDays) 天"
if ($ageDays.TotalDays -gt 60) { "已超过 60 天，若本次任务对工具时效性敏感，建议先跑下方刷新命令" }
```

60 天只是经验阈值，不是强约束——上游是个人维护的 awesome-list，更新节奏不固定；真正要不要刷新，看当前任务是否在意"是否有新工具/工具是否还在维护"，不敏感就不用管。

## 分类总览（26 类，共 753 条，2026-08-24 快照统计）

| category（查询用原始值） | 数量 | 示例工具 |
|---|---|---|
| `domain-ip-network` | 112 | AbuseIPDB, Aircrack-ng, altdns |
| `username-social` | 82 | Arctic Shift, Blackbird, BrandWatch |
| `data-breach` | 39 | BreachDirectory, BreachForums Status, CeWL |
| `people-identity` | 37 | AdvPhishing, Apollo.io, BackgroundChecks.com |
| `image-facial` | 37 | AI or Not, Aletheia (image forensics), BeenVerified |
| `red-team-offensive` | 35 | AD Attack & Defense, Arjun, BloodHound |
| `email-phone` | 35 | CallerIDTest, Email-Checker, EmailAnalyzer |
| `malware-threat-intel` | 31 | abuse.ch Hunting, AlienVault OTX, ANY.RUN |
| `search-dorking` | 29 | Baidu, Brave Search, BrightCloud Threat Intelligence |
| `vpn-privacy` | 26 | Algo VPN, Anon-SMS, Anonsurf |
| `geolocation` | 26 | Canary Tokens, F4map, FIRMS |
| `blue-team-defensive` | 24 | Atomic Red Team, MITRE CALDERA, Chainsaw |
| `document-metadata` | 24 | Archive.today, Autopsy, Binwalk |
| `misc` | 22 | ChatGPT, Claude, DeepSeek |
| `training-ctf` | 21 | BugBountyHunter, CTFtime, Cybrary |
| `learning-resources` | 20 | 0xdf hacks stuff, awesome-hacking-resources, awesome-incident-response |
| `vehicle-aviation-maritime` | 18 | ADS-B Exchange, AutoCheck, Court Listener |
| `crypto-blockchain` | 18 | Arkham Intelligence, Bitquery, Blockchain.com Explorer |
| `iot-devices` | 17 | AhMyth Android RAT, Apktool, BinaryEdge |
| `digital-forensics` | 16 | Binary Ninja, Cutter, Dissect |
| `hardware-hacking` | 16 | Alfa Network Adapters, Attify Badge, Bus Pirate |
| `dark-web` | 15 | Ahmia, Aleph Open Search, Dark.fail |
| `threat-intel-platforms` | 14 | Anomali ThreatStream, CrowdStrike Falcon Intelligence, Digital Shadows SearchLight |
| `frameworks` | 14 | FinalRecon, fsociety, Hackingtool |
| `company-business` | 13 | Aleph (OCCRP), BinCheck, Blockchain.com |
| `bug-bounty` | 12 | Public Bug Bounty Programs (chaos), Bugbase, Bugcrowd |

这张表本身就是"路由用完整目录"——先看这里选对 `category` 取值，再执行下面的查询，不用先跑一次 unique 才知道有哪些分类。

## 查询方法（优先于整仓安装）

不要一上来就跑 `sudo bash install.sh` 装完 753 个工具。按分类查本地快照，拿到具体那一条再单独装：

```powershell
# 查本地快照（相对仓库根目录的默认路径，无需网络）
$tools = Get-Content -Raw "security-research-modules\skills\osint-recon\references\tools-snapshot.json" | ConvertFrom-Json
$tools | Where-Object { $_.category -eq 'domain-ip-network' } |
    Select-Object name, description, url, @{n='install'; e={$_.install.raw}}
```

```bash
# 等价的 jq 版本（本地快照）
jq -r '.[] | select(.category=="domain-ip-network") | "\(.name): \(.description) -> \(.install.raw)"' \
  security-research-modules/skills/osint-recon/references/tools-snapshot.json
```

```bash
# 刷新快照 / 需要最新数据时现查上游（命令结构与本地版一致，只换了来源）
curl -s https://raw.githubusercontent.com/rawfilejson/awesome-osint-arsenal/main/tools.json \
  | jq -r '.[] | select(.category=="domain-ip-network") | "\(.name): \(.description) -> \(.install.raw)"'

# 重新落地本地快照（上游若长期不更新，无需频繁刷新；发现分类总览表与实际有出入时再刷）
curl -s https://raw.githubusercontent.com/rawfilejson/awesome-osint-arsenal/main/tools.json \
  -o security-research-modules/skills/osint-recon/references/tools-snapshot.json
```

找到具体工具后，只执行该条记录 `install.raw` 里的单条命令（通常是一行 `git clone`/`pip install`/`go install`），不要连带跑整个分类脚本，也不要因为"要用一个工具"就把整份 JSON 或整张分类表都贴进对话/文档。

## 仓库结构（供对照，非本模块打包内容）

| 文件 | 作用 |
|---|---|
| `tools.json` | 本模块 `references/tools-snapshot.json` 的上游原始文件；结构化目录，753 条记录，每条含 `id/name/description/category/url/install.{method,kali,raw}/tags/source_versions/aliases/archived` |
| `README.md` | 人读目录，分类前常带授权使用免责声明；分类粒度比 `category` 字段更细，本模块以 `category` 字段的 26 类为准，不额外镜像 README |
| `install.sh` | 总控脚本：要求 root，依次调用下面 7 个分类脚本，日志写到 `~/osint-install-errors.log` |
| `osint.sh` / `redteam.sh` / `blueteam.sh` / `forensics.sh` / `hardware.sh` / `labs.sh` / `extras.sh` | 按分类的实际安装脚本，走 apt/pacman/dnf、pip3、go install、`git clone --depth=1`（落地到 `/opt/osint-arsenal`）、docker pull |

本模块只打包 `tools-snapshot.json` 这一份数据，不打包上述任何安装脚本——单个工具的安装命令已经在快照每条记录的 `install.raw` 里，不需要连带整个分类脚本。

## 安全边界（已核实，2026-08 分析结论）

- `install.sh`/`osint.sh`/`redteam.sh` 均要求 `sudo`/root；逐条审查过没有发现 `curl|bash`、`wget|sh`、base64 解码执行、反弹 shell 等供应链投毒手法，安装全部走包管理器/pip/go install/git clone/docker，来源限定在 github.com、系统源、PyPI、Go module proxy、Docker Hub。
- 但 `redteam.sh` 装的是真实攻防工具链：BloodHound/Rubeus/Certipy/PetitPotam 等域渗透工具、Sliver/Havoc/Mythic/Empire/Merlin/Villain 等 C2 框架、Metasploit；`osint.sh` 里也混了 evilginx2/Modlishka/zphisher/SocialFish 等钓鱼套件和 AhMyth-Android-RAT（对应上表 `red-team-offensive`/`iot-devices` 分类里能查到）。这不是纯被动侦察清单，只应在你拥有授权的隔离测试环境（专用 VM/靶场）里整段执行，不要在主力机器或生产环境跑。
- 所有 pip 安装都带 `--break-system-packages`，会绕过 Debian 的 externally-managed-environment 保护；大量步骤 `2>/dev/null` 吞掉报错，失败需要看 `~/osint-install-errors.log` 才能发现。
- 上游对 750+ 个第三方源均未做哈希/签名校验，完整性完全依赖 GitHub/PyPI/Go proxy/Docker Hub 自身；当"目录"查询没问题，批量执行前按自己的供应链信任标准再审一遍。

## 路由上下文

**上游入口**：`security-research-modules/skills/recon-for-sec/MODULE.md`（P1 侦察路由）、根目录 `SKILL.md`

**下游/联动**：
- 查到目标工具后如果落到 Web/API 攻击面测试 → [Hack 总入口](../hack/MODULE.md) 分流
- 需要通用侦察方法论（而非具体工具）→ [Recon and Methodology](../recon-and-methodology/MODULE.md)
- 涉及 .git/.svn 源码管理泄露专项 → [Insecure Source Code Management](../insecure-source-code-management/MODULE.md)
- 涉及供应链/内部包名探测专项 → [Dependency Confusion](../dependency-confusion/MODULE.md)

## 前置条件

- 查本地快照：任意能解析 JSON 的环境（PowerShell `ConvertFrom-Json` 或 `jq`），无需网络
- 刷新快照 / 查最新上游数据：能发 HTTPS 请求的环境
- 实际执行该仓库脚本：Debian/Ubuntu/Kali 系发行版效果最好，需要 root，且必须是你自己拥有或已获书面授权的隔离环境
