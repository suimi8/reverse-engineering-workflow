# Crypto Specialists 完整索引（web-crypto-reverse）

> 30 个 specialist 分类，用于快速定位：给目标后该跑哪些 specialist、各自找什么、输出什么。

## A. 入口与编排

| Specialist | 职责 | 输出 |
|-----------|------|------|
| `thefound` | 总入口：URL/APK/HAR 自动分流，全自动跑到目标完成 | 报告 + 重构脚本 + flow 脚本 |
| `crypto-recon-plans` | 理解用户目标，先写计划再分析（不阻塞提问） | 分析计划 |
| `crypto-recon-orchestrator` | 总协调：调度全流水线（web 与 APK 共用） | 全流水线结果 |

## B. 采集与输入

| Specialist | 职责 | 输出 |
|-----------|------|------|
| `crypto-recon-fetch` | 下载目标域全部 JS/WASM 资产到 `output/[domain]/` | 本地资产快照 |
| `crypto-recon-har` | 接受 `.har` 文件（DevTools/Burp/mitmproxy）作为输入 | 从请求反推加密/签名候选 |
| `crypto-recon-apk` | APK 反编译：解包 → jadx(Java) + apktool(Smali)，只做一次 | `output/[name]/java/` + `smali/` |

## C. 预处理与类型判定

| Specialist | 职责 | 输出 |
|-----------|------|------|
| `crypto-recon-deobf` | 美化 + source map + 字符串解码 + AST 分析 | 可读 JS 源码 |
| `crypto-recon-detector` | 扫描 JS 判定 Web2 / Web3 / Hybrid，路由到对应 specialist 集 | 类型判定（必须先跑） |

Web3 高置信信号示例：`window.ethereum`、`eth_requestAccounts`、`eth_sendTransaction`、`eth_signTypedData_v[134]`、`personal_sign`、`wallet_switchEthereumChain`。

## D. 算法族 Specialist（Web 扫 JS / APK 扫 java/ 同一套团队）

| Specialist | 找什么 | 关键模式 |
|-----------|--------|---------|
| `crypto-recon-hash` | MD5/SHA*/BLAKE/RIPEMD/Keccak | `md5(`、`sha256(`、CryptoJS 的 `CryptoJS.MD5`、`createHash` |
| `crypto-recon-symmetric` | AES/DES/RC4/ChaCha20/SM4 | `CryptoJS.AES.encrypt`、`aes-128-cbc`、key/iv 常量、mode/padding |
| `crypto-recon-asymmetric` | RSA/ECDSA/Ed25519/SM2 | `jsencrypt`、`crypto.subtle.importKey`、公钥常量、PEM 块 |
| `crypto-recon-mac` | HMAC/CMAC/Poly1305 | `CryptoJS.HmacSHA256`、`createHmac`、密钥与 data 拼接顺序 |
| `crypto-recon-kdf` | PBKDF2/bcrypt/scrypt/Argon2 | `CryptoJS.PBKDF2`、`$2a$`/`$2b$` 前缀、迭代次数/盐 |
| `crypto-recon-encoding` | Base64/Base58/Hex/ROT/自定义 | `btoa`/`atob`、Base58 字母表常量、字符替换表 |
| `crypto-recon-signing` | API 请求签名（最高优先） | `function.*[Ss]ign\(`、`sign\s*[:=]`、sort+hash 链（见主 MODULE.md 规范模式） |
| `crypto-recon-jwt-oauth` | JWT/OAuth/Bearer/TOTP | `jsonwebtoken`、header/payload/signature 三段、`alg` 头、OTP 时间步 |
| `crypto-recon-libraries` | CryptoJS/forge/sjcl/nacl/WebCrypto | 库特征名与版本、`crypto.subtle` 调用点 |

## E. 特殊载体

| Specialist | 找什么 |
|-----------|--------|
| `crypto-recon-wasm` | WASM 内的加密：导出函数名、内存布局、导入表、密钥/中间值 |
| `crypto-recon-native` | JNI/so 内加密：导出符号、字符串、硬编码密钥 |
| `crypto-recon-custom` | 自定义混淆：异或流、自写编码、硬编码密钥/secret |

## F. 重构与验证

| Specialist | 职责 | 输出 |
|-----------|------|------|
| `crypto-recon-reconstruct` | 把最优发现重构为 Python 函数 | `reconstruct_*.py`（含签名函数） |
| `crypto-recon-building` | 把多个函数串成完整 API flow | `flow_*.py`（注册/登录/请求链） |
| `crypto-recon-debugging` | 401/403/签名错误排查：浏览器请求逐项比对 | 差异清单 + 修复 |
| `crypto-recon-report` | 汇总发现写最终报告 | `output/[target]/final/[target].md` |
| `crypto-recon-pentest` | flow 脚本就绪后的漏洞测试（RCE/SQLi/IDOR/SSRF） | 漏洞报告（联动 security-research-modules） |

## G. Web3 专项

| Specialist | 聚焦 |
|-----------|------|
| `crypto-recon-web3` | 通用 Web3/DeFi/NFT：钱包连接、交易签名、TypedData |
| `crypto-recon-web3-cosmos` | Cosmos 生态：amino 签名、Bech32 地址 |
| `crypto-recon-web3-solana` | Solana：Ed25519、程序指令、交易序列化 |
| `crypto-recon-web3-starknet` | StarkNet：Pedersen hash、Stark 签名 |

## H. APK 专项

| Specialist | 聚焦 |
|-----------|------|
| `crypto-recon-apk-java` | Java/Smali 加密模式：OkHttp Interceptor、Retrofit、BuildConfig、JNI 调用 |
| `crypto-recon-apk-debug` | adb 捕获 + Frida hook + Java 调试清单 |

## 使用建议

1. 永远先跑 detector（或人工判定 web2/web3），再选 specialist 集。
2. signing 是最高价值目标：先还原签名，再还原加密。
3. 所有 specialist 并行跑；结果合流到 report → reconstruct → building。
4. 401/403 优先 debugging：逐项比对请求（参数顺序、null 过滤、大小写、编码、nonce、时间窗口）。
