# 加密算法核心模式速查（web-crypto-reverse）

> Web（JS）与 Android（Java/Smali）两侧的加密模式识别信号，供扫描与定位使用。完整 specialist 分工见 `crypto-specialists-map.md`。

## 1. 签名（Signing）— 最高价值目标

规范模式（大量变体）：`nonce + timestamp → 过滤空值 → 按键排序 → JSON 序列化 → 哈希 → 大写/编码`

JS 定位信号：

```
function.*[Ss]ign\(|function.*[Ss]ignature\(|function.*[Gg]enerate.*[Ss]ign
function.*[Bb]uild.*[Ss]ign|function.*[Cc]alc.*[Ss]ign|function.*[Cc]ompute.*[Ss]ign
function.*getSign\(|function.*makeToken\(|function.*buildAuth\(|function.*authHeader\(|function.*apiSign\(
sign\s*[:=]|signature\s*[:=]
```

Java 定位信号：OkHttp `Interceptor` 实现、`addHeader("sign", ...)`、`BuildConfig` 常量、Retrofit `@Header` 注入。

排查清单（401/403 时逐项比对）：参数排序规则、null/空值过滤、大小写、字符编码、nonce 是否复用、时间窗口、密钥来源（硬编码/服务端下发）。

## 2. 哈希（Hash）

| 算法 | JS 信号 | Java 信号 |
|------|---------|----------|
| MD5 | `CryptoJS.MD5`、`md5(` | `MessageDigest.getInstance("MD5")` |
| SHA-1/256/512 | `CryptoJS.SHA256`、`crypto.subtle.digest("SHA-256")`、`createHash('sha256')` | `MessageDigest.getInstance("SHA-256")` |
| Keccak/BLAKE | `keccak256`、`blake2` 库导入 | `org.bouncycastle` 相关类 |

## 3. 对称加密（Symmetric）

| 算法 | JS 信号 | 关注点 |
|------|---------|--------|
| AES | `CryptoJS.AES.encrypt`、`aes-128-cbc`、`crypto.subtle.importKey` | key/iv 常量、mode（CBC/ECB/GCM）、padding、输出编码（Base64/Hex） |
| DES/3DES | `CryptoJS.DES`、`CryptoJS.TripleDES` | 同 AES |
| RC4 | `CryptoJS.RC4` | 流密码无 iv |
| ChaCha20/SM4 | 库调用（`chacha20`、`sm-crypto`） | 国密 SM4 常见于国内站 |

## 4. 非对称加密（Asymmetric）

| 算法 | JS 信号 |
|------|---------|
| RSA | `jsencrypt`、`JSEncrypt`、`crypto.subtle.importKey("rsa")`、PEM 块（`-----BEGIN PUBLIC KEY-----`） |
| ECDSA/Ed25519 | `crypto.subtle.importKey("ec")`、`@noble/curves`、`ed25519` |

## 5. MAC（HMAC 等）

| 算法 | JS 信号 | 关注点 |
|------|---------|--------|
| HMAC-SHA1/256 | `CryptoJS.HmacSHA256`、`createHmac('sha256', key)` | key 与 data 的拼接顺序、编码 |
| CMAC/Poly1305 | 库调用 | 消息填充规则 |

## 6. KDF

| 算法 | JS 信号 | 关注点 |
|------|---------|--------|
| PBKDF2 | `CryptoJS.PBKDF2` | 迭代次数、盐、派生长度 |
| bcrypt | `$2a$`/`$2b$` 前缀 | cost 因子 |
| scrypt/Argon2 | 库调用 | 内存/时间参数 |

## 7. 编码

| 类型 | JS 信号 | 关注点 |
|------|---------|--------|
| Base64 | `btoa`/`atob`、`Buffer.from(..., 'base64')` | 标准 vs URL-safe、padding |
| Base58 | 自定义字母表常量（58 字符） | 顺序 |
| Hex | `toString(16)` 链 | 大小写 |
| 自定义 | 字符替换表/位移 | 整体变换 |

## 8. JWT/OAuth

- 三段式 `header.payload.signature`，`alg` 头决定算法（HS256/RS256/ES256）。
- JS：`jsonwebtoken`、`jose`、手写 `btoa(JSON.stringify(...))`。
- TOTP：时间步 30s + HMAC-SHA1 + 6 位截断。

## 9. 加密库特征（Libraries）

| 库 | 特征 |
|----|------|
| CryptoJS | `CryptoJS.AES`、`CryptoJS.enc.Utf8`、`CryptoJS.lib.WordArray` |
| forge | `forge.cipher`、`forge.util.hexToBytes` |
| sjcl | `sjcl.encrypt`、`sjcl.codec` |
| nacl/tweetnacl | `nacl.secretbox`、`nacl.sign` |
| WebCrypto | `crypto.subtle.*`（现代浏览器原生） |

## 10. WASM / Native

- WASM：导出函数名（`sign`/`encrypt`/`hash`）、内存视图取密钥、导入表找宿主交互。
- Native（JNI/so）：导出符号、字符串常量、硬编码密钥、`System.loadLibrary` 调用点。

## 11. Web3 签名

| 生态 | 特征 |
|------|------|
| 通用 | `eth_signTypedData_v4`、`personal_sign`、`window.ethereum.request` |
| Solana | `ed25519` 签名、`@solana/web3.js` 交易序列化 |
| Cosmos | amino 签名、Bech32 地址 |
| StarkNet | Pedersen hash、Stark 曲线签名 |
