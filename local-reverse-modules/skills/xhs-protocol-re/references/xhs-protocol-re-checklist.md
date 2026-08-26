# 小红书协议逆向 — 操作与验收检查清单

## 签名环境检查（每次跑协议链路前）

- [ ] 页面能打开 `https://www.xiaohongshu.com/` 且 `typeof window.mnsv2 === "function"`（**轮询等待**，不要固定 sleep）
- [ ] 已捕获到 `x-s-common`（从页面自己发出的 `edith.xiaohongshu.com` 请求头里拿）
- [ ] Cookie 现读、不用冻结快照（`acw_tc` 约 30 分钟过期、`websectiga` 会轮换）
- [ ] `mnsv2` 迟迟不注册时的兜底：注入 `sbtsource` 下发的 signUrl JS 后重试
- [ ] **导航发生在注入 `web_session` 之前**（无头带 session 导航会被服务端作废）

## 签名构造检查

- [ ] `sign_path = path + query`（GET 带 query 必须一起签，漏了 `x5` 与服务端不一致）
- [ ] body **只序列化一次**，同一个字符串既参与签名又原样发出（第一红线）
- [ ] `x5 = md5(sign_path + body_str)`，紧凑格式；自测锚点 `md5('/api/sns/web/v1/login/qrcode/create{"qr_type":1}') == f6a462b6b0226d11b4c461e220029951`
- [ ] 自测断言**走真实代码路径**，不是手写字面量（否则实现偏离时自测仍全绿）
- [ ] `sign_ver` / `platform` / `app_id` 取自实时 `x-s-common.x1/x2/x3`，硬编码只当回退
- [ ] 启动/变化时打印一行来源（`source=live` / `fallback`），去重键用 `(sign_ver, source)`
- [ ] `X-t` 毫秒时间戳与 `X-s` 配对；`X-b3-Traceid` 16 位 hex 随机
- [ ] `Origin` / `Referer` = `https://www.xiaohongshu.com`，UA 为 Chrome 系

## 请求头必需性（实测边界）

- [ ] `Cookie` **必带**（`qrcode/create` 缺它 → HTTP 200 但 `code=-1 登录异常`）
- [ ] `X-s-common` 在 `qrcode/create` 上非必需，但**继续带**（浏览器 82/82 都带；其它端点未测）
- [ ] `x-s-common.x5` 与 Cookie `a1` **同源**（解开比对；只告警不拦截）

## 协议登录链路

1. `POST /api/sns/web/v1/login/qrcode/create` body `{"qr_type":1}` → `qr_id` / `code` / `url`
2. 二维码图片**本地生成**（`url` 含本次登录握手信息，不要发给第三方渲染服务）
3. 轮询 `POST /api/qrcode/userinfo`；**同轮**调 `GET /api/sns/web/v1/login/qrcode/status?...&client_public_key_base64=` 注册 X25519 公钥
4. 从 `qrcode/status` 的 `data.login_info` 取 `{user_id, session, secure_session, ssk}`
5. `login_info.session` 写进 `web_session` cookie
6. `GET /api/sns/web/v2/user/me` 确认 `guest === false` 才算成功

- [ ] 确认信号**只认 `codeStatus == 2`**
- [ ] `userId` 不作判据（任何阶段都返回，未登录时是游客 id）
- [ ] **不要**用 `activate` 换凭据（它铸的是游客会话，前缀 `030037…`；真登录是 `040069…`）
- [ ] 二维码刷新周期按**约 6.9 分钟**寿命设计，不要按 60 秒刷（会丢弃已确认的码）
- [ ] 写盘前二次确认 `guest === false`，宁可重扫也不把无法证实的 session 写进 `cookies.json`
- [ ] 区分「检测失败」与「未登录」：406 / 网络异常 / 签名失效 ≠ 未登录（只有业务码 `-101` 是确定未登录）

## 常驻签名服务检查

- [ ] `mnsv2` 的 evaluate 受导航锁保护
- [ ] 导航锁**只包住那一行 evaluate**，兜底 `ensure_ready()` 在锁释放之后才调（`asyncio.Lock` 不可重入）
- [ ] 加锁顺序恒为 `_lock → _nav_lock`，无反序
- [ ] cookie 操作**不加**导航锁（打的是 CDP Network 域；且 cookie 头函数在锁的 `finally` 里被调）
- [ ] 每次 `goto`/`reload` 前 park `web_session`，`finally` 里 restore，且**在释放导航锁之前**
- [ ] `x-s-common` 刷新失败的退避用**独立时钟字段**，不要改捕获时间戳伪造未过期

## 端到端验收门

- [ ] `POST qrcode/create` → HTTP 200 且 `code == 0`
- [ ] `GET qrcode/status?...` → HTTP 200 且 `code == 0`（验 query 参与签名）
- [ ] 常驻服务 `user/me` → `guest == false` 且能取到昵称（同时证明导航没烧掉登录态）
- [ ] `x-s-common` 自检 `ok == true`
- [ ] 验收脚本退出码 0/1（可当 CI 门）；失败时自动跑请求头四组合矩阵定位
- [ ] `cookies.json` 未被意外改写（比对大小 / mtime / `web_session` 前缀）

## 排查顺序（自上而下，越靠前越便宜）

0. **先做受控变量隔离**：保持签名不变，只改一个请求头，从结果矩阵反推
1. 看签名参数来源行：`source=live` 还是 `fallback`
2. 验 body 格式一致性（签名侧与发送侧是不是同一个字符串）
3. 验 `x-s-common` / `a1` 同源
4. 最后才怀疑 `mnsv2`（引擎刚被重新下发？页面上下文被销毁？）

## 症状对照

| 症状 | 首查 |
|---|---|
| HTTP 406 | body 格式分叉；GET 的 query 没进签名路径 |
| HTTP 200 + `code=-1 登录异常` | 漏发 `Cookie` |
| 明明登录了却 guest | 注入 session 后没刷新 cookie 快照；或导航时没 park |
| 登录莫名掉了 | 无头带 session 导航；或 restore 在释放锁之后 |
| `Execution context was destroyed` | `mnsv2` evaluate 没受导航锁保护 |
| 请求永久卡死 | 导航锁套在 try/except 外层；或给 cookie 操作加了锁 |
| 每个请求都在 reload | 退避用了改时间戳的写法 |
| 扫码永远扫不完 | 二维码刷新周期按 60 秒设计 |

## 脱敏纪律（写任何产物前自查）

- [ ] 无真实 `a1`（52 字符）、`web_session` / `secure_session` / `ssk`、`qr_id` / `code`
- [ ] 无完整 live `XYS_` / `mnsv2` 串
- [ ] 算法内容**完整保留**：乱序码表、MD5 公式、字段表、协议路径、常量——按根规范 13.1 这些一律不脱敏
