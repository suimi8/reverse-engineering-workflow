---
name: web-crypto-reverse
description: 从 Web JS 与 Android APK 中识别并重构加密算法。覆盖哈希（MD5/SHA/BLAKE）、对称（AES/DES/RC4/ChaCha20/SM4）、非对称（RSA/ECDSA/Ed25519/SM2）、MAC（HMAC/CMAC/Poly1305）、KDF（PBKDF2/bcrypt/scrypt/Argon2）、编码、API 签名、JWT/OAuth、CryptoJS/forge/sjcl 等加密库识别、WASM 加密、Web3 签名；输出 Python 重构代码并对线上 API 验证。当用户需要找出目标网站/App 请求加密与签名算法、还原签名生成逻辑、在 Python 中复现请求签名时使用。
---


中文名：suimi Web/APK 加密算法逆向

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# suimi Web/APK 加密算法逆向

> 面向「加密算法识别与重构」的逆向产出型技能：从 Web JS 或 Android APK 中找出每个加密/签名模式 → Python 重构 → 对线上 API 验证。与 `web-js-reverse`（JS 保护破解）和 `web-api-reverse`（API 客户端生成）互补。

## 与相邻模块的边界

| 场景 | 用哪个模块 |
|------|-----------|
| 目标请求带加密/签名参数，需要找出算法并 Python 重构签名 | **本模块（web-crypto-reverse）** |
| 目标是破解 JS 混淆/JSVMP/反爬检测本身 | `web-js-reverse` |
| 目标是逆向整个 API 协议并生成客户端 | `web-api-reverse` |
| 目标是找接口安全漏洞 | `security-research-modules/skills/api-sec` |

## 触发场景

- 网站/App 请求带 `sign` / `signature` / `token` / `nonce` 等签名参数，需还原生成逻辑
- 请求 body 或参数经过加密（AES/自定义异或/编码变换），需还原加解密
- 给一个 URL：下载其 JS/WASM 资产，扫描全部加密模式
- 给一个 `.apk` / `.apkm` / `.xapk`：jadx+apktool 反编译，扫描 Java/Smali 加密模式
- 给一个 `.har` 文件：从已捕获请求反推加密/签名
- 需要把还原出的算法写成可独立运行的 Python 函数（`reconstruct_*.py`），并构建完整 API flow 脚本

## 核心原则

1. **全自动流水线**：用户给目标（URL / APK / HAR），流水线自动跑到底，中途不反复询问"你想要哪个发现"——按目标自动选最高价值产出（签名重构 > 加密还原 > 报告）。
2. **并行扫描**：detector 判定 Web2/Web3/Hybrid 后，10+ 个 specialist 并行扫描各自算法族。
3. **签名优先**：请求签名（sign/signature/token/nonce 生成）是最高价值目标——重构它即可完整复刻 API。
4. **先复现再验证**：Python 重构代码必须对线上 API 实测（401/403 说明签名不对，进入 debugging 迭代）。

## 流水线（两条输入路径）

```
/thefound <target>
   │
   ├─ URL ──→ plans(定目标) → fetch(下载全部 JS/WASM) → deobf(美化+sourcemap+解码)
   │             → detector(判定 web2/web3/hybrid) → [并行] 10+ specialists
   │             → report(写报告) → reconstruct(重构最优发现为 Python) → building(可选完整 flow 脚本)
   │
   └─ APK ──→ 解包（.apkm/.xapk 先抽 base.apk）→ jadx → java/ + apktool → smali/
                → [并行] 15 agents（java 分析 + 10 crypto specialists + 3 flow 映射）
                → report → reconstruct → building
```

**完成定义**：所有 specialist 扫完 + 最终报告 `output/[target]/final/[target].md` + 目标产物存在（签名→`reconstruct_signing.py`；完整流程→`flow_*.py`；仅分析→报告即可）。

## 30 个 specialist 索引（按需加载）

完整分类索引与每个 specialist 的职责/输出见 `references/crypto-specialists-map.md`。快速定位：

| 阶段 | Specialists |
|------|-------------|
| 入口 | `thefound`（总入口）、`crypto-recon-plans`（目标理解）、`crypto-recon-orchestrator`（总协调） |
| 采集 | `crypto-recon-fetch`（下载 JS/WASM）、`crypto-recon-har`（HAR 输入）、`crypto-recon-apk`（APK 反编译） |
| 预处理 | `crypto-recon-deobf`（美化/sourcemap/字符串解码/AST）、`crypto-recon-detector`（web2/web3/hybrid 判定） |
| 算法族 | `crypto-recon-hash`、`crypto-recon-symmetric`、`crypto-recon-asymmetric`、`crypto-recon-mac`、`crypto-recon-kdf`、`crypto-recon-encoding` |
| 协议层 | `crypto-recon-signing`（API 签名，最高优先）、`crypto-recon-jwt-oauth`（JWT/OAuth/Bearer/TOTP）、`crypto-recon-libraries`（CryptoJS/forge/sjcl/nacl/WebCrypto） |
| 特殊载体 | `crypto-recon-wasm`、`crypto-recon-native`（JNI/so）、`crypto-recon-custom`（自定义混淆/硬编码密钥） |
| 重构与验证 | `crypto-recon-reconstruct`（→Python）、`crypto-recon-building`（完整 flow 脚本）、`crypto-recon-debugging`（401/403 排查） |
| Web3 | `crypto-recon-web3`、`crypto-recon-web3-cosmos`、`crypto-recon-web3-solana`、`crypto-recon-web3-starknet` |
| APK 专项 | `crypto-recon-apk-java`（Java/Smali 模式）、`crypto-recon-apk-debug`（adb 捕获/Frida hook） |
| 其他 | `crypto-recon-report`（报告）、`crypto-recon-pentest`（漏洞测试，需先有 flow 脚本） |

## 签名逆向的典型模式（最高价值目标）

```js
// 规范签名模式（大量变体）：
function generateSign(params) {
  const nonce = uuid()                            // 1. 随机 nonce
  const ts = Date.now()                           // 2. 时间戳
  const filtered = filterNull(params)             // 3. 过滤空值
  const sorted = sortKeys(filtered)               // 4. 按键排序
  const canonical = JSON.stringify(sorted)        // 5. 序列化
  const signature = md5(canonical).toUpperCase()  // 6. 哈希
  return { nonce, ts, signature }                 // 7. 返回
}
```

**搜索定位信号**：函数名 `function.*[Ss]ign\(` / `[Gg]enerate.*[Ss]ign` / `buildAuth` / `authHeader` 等；变量赋值 `sign\s*[:=]` / `signature\s*[:=]`；以及 Java 侧 OkHttp Interceptor 注入签名头的模式。

**验证闭环**：`reconstruct_signing.py` 跑通 → 对线上 API 实测。401/403 → 进入 debugging（比对浏览器请求头逐一差异：排序规则、null 过滤、大小写、编码、nonce 复用、时间窗口）。

## 工作流

1. 建立基线：目标 URL/APK/HAR、可复现的请求、签名参数样本。
2. 输入分流：URL → web 流水线；APK → APK 流水线；HAR → har 分析 → building。
3. 并行扫描：detector 定类型后按 specialist 分工，一次扫一类算法族。
4. 先重构单点（签名/加密）验证假设，再补完整 flow。
5. 端到端复验：全新会话跑 flow 脚本，签名与浏览器一致，成功率达标。
6. 记录：算法族、定位证据、重构代码、验证结果。

## 证据与回滚

- 记录命令、目标、发现的算法族、定位证据（源码片段）、重构代码、验证结果。
- 保留原始 JS/Java 样本、反混淆输出、重构脚本、测试日志。
- 签名/密钥等敏感值只留本地工作区，不进 Git/文档/对话。
- 绝不绕过 Auth/Captcha/Rate-Limit 的合法边界；权限责任在用户侧。

## 参考

- `references/crypto-specialists-map.md`：30 个 specialist 完整分类索引与职责。
- `references/crypto-signatures.md`：各算法族核心模式速查（Web 与 Java 两侧）。
- 相邻模块：`web-js-reverse`（JS 保护破解）、`web-api-reverse`（API 客户端）。
- 统一技能目录与中文名映射见 `references/unified-skills-entry.md`。
- 通用可复用方法清单见 `references/reverse-engineering-methods.md`。