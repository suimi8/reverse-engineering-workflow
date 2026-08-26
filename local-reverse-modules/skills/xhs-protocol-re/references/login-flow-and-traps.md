# 协议扫码登录状态机、三个致命陷阱与常驻服务并发不变量

> 本文的每条事实都标注证据源。三类证据不合并：**HAR 静态复核** / **实时链路实测** / **真人扫码实测**。
> 凭据一律不落文：`a1` / `session` / `secure_session` / `ssk` / `qr_id` / `code` 只写形态。

## 一、三步链路

```
① POST /api/sns/web/v1/login/qrcode/create
     body {"qr_type":1}
     -> data {qr_id, code, url, multi_flag}
        url 形如 https://www.xiaohongshu.com/mobile/login?qrId=<REDACTED>&xhs_code=<REDACTED>
        二维码图片必须本地生成，不要发给第三方渲染服务（url 含本次登录握手信息）

② 轮询 POST /api/qrcode/userinfo
     body {"qrId":"<REDACTED>","code":"<REDACTED>"}
     -> data {codeStatus, userId, ...}
   同轮并行 GET /api/sns/web/v1/login/qrcode/status
     ?qr_id=<REDACTED>&code=<REDACTED>&client_public_key_base64=<X25519 公钥 b64>
     -> data {code_status, login_info?}

③ 凭据来自 ②：data.login_info = {user_id, session, secure_session, ssk}
     把 login_info.session 写进 web_session cookie 即完成登录
```

`GET qrcode/status` 不是"备选轮询通道"，它有两个职责：**注册本次会话的客户端 X25519 公钥**（轮询期间每轮都要调），以及**下发 `login_info`**。

## 二、`codeStatus` 状态机

| 值 | 含义 | 证据源 |
|---|---|---|
| `0` | 等待扫码（未扫） | HAR（7 条有响应体的 `userinfo` 全是 0）+ 实时链路（新建二维码立即轮询）+ 真人实测 |
| `1` | 已扫码，等待 APP 端点「确认登录」 | 真人扫码实测 |
| `2` | **已确认——唯一的成功信号** | 真人扫码实测 |
| `3` | 已过期/失效 | 真人扫码实测 |

> ⚠️ 证据源不要混写：这份 HAR 与实时链路**都只能证明 `0`**（因为没人扫码）。`1`/`2`/`3` 至今只有真人扫码能证。
> `qrcode/status` 通道的字段名是 `code_status`（下划线），语义同表。

**被推翻的旧结论**（留档，说明为什么会错）：早期文档写「非 0 = 等待、`0` = 已确认」，实现照此写成 `if codeStatus == 0: 判定确认`。后果是**第一轮轮询就误判成功**，在没人扫码的情况下直冲 `activate`——这正是"步骤③ 从未成功"的真实原因，与网关反爬无关。

## 三、三个致命陷阱

### 陷阱 1：凭据在 `login_info`，不在 `activate`（最致命）

`POST /api/sns/web/v1/login/activate` 是**独立铸发会话**的接口，与本次扫码无关：即使完全没人扫码（`code_status=0`）也会返回 `code:0` 加一个格式正常的 session，但那是**游客会话**。

前缀可直接区分：

- `login_info.session` → `040069…` ✅ 真登录态
- `activate` 的 session → `030037…` ❌ 游客态

HAR 时间线独立复现了这一点：`07:12:50` logout → `07:12:53` 调 `activate`（此时无人扫码）→ 响应体 `data.session` 前缀正是 `030037…`。

旧实现丢掉 `login_info` 去调 `activate` 换凭据，等于**把真凭据扔了换回一个游客 session**，再把它当登录态存进 `cookies.json`，导致登录显示和发布功能（共用同一份 cookies）一起静默失效。

### 陷阱 2：`userId` 不是判据

`data.userId` **任何阶段都可能返回**，未登录时是游客 id。只能展示或与 `login_info.user_id` 比对，绝不可当确认信号。
外层 `code` / `data.result.code` 表示的是"接口调用成功"，与扫码状态无关，同样不能当判据。

### 陷阱 3：必须用 `user/me` 的 `guest` 字段收口

```
GET /api/sns/web/v2/user/me
  未登录 -> {"user_id": "<游客id>", "guest": true}
  已登录 -> guest 为 false 且带 nickname
```

判定登录成功**绝不能**只看 `code==0` 或"有没有 session"，必须确认 `guest === false`。
写盘前也要再确认一次：宁可让用户重扫，也不能把无法证实的 session 写进 `cookies.json`。

同时要区分「**检测失败**」与「**未登录**」：HTTP 406 / 网络异常 / 签名失效都不等于未登录，把它们伪装成"未登录"会让用户永远看到未登录、只能反复重扫。只有服务端明确返回未登录业务码（实测 `-101`）才是确定的未登录。

## 四、其它实测细则

| 事实 | 说明 | 证据源 |
|---|---|---|
| 二维码寿命约 **6.9 分钟**（≈414 秒） | 不是长期以来传的"60 秒"。按 60 秒假设写的自动刷新会把还能用、甚至已到 `codeStatus==2` 的码刷掉 | 真人扫码实测 |
| `qrcode/status` 是**带 query 的 GET** | 签名路径必须 `sign_path = path + query`，漏拼会让 `x5` 与服务端不一致 | 实时链路实测 |
| 每轮轮询都要注册公钥 | 真实前端每轮都带 `client_public_key_base64` | HAR |
| `Cookie` 是硬需求 | `qrcode/create` 缺 Cookie 时 HTTP 200 但 `code=-1 msg=登录异常` | 实时链路受控 A/B |
| `X-s-common` 在 `qrcode/create` 上非必需 | 同一签名、只改头的四组合矩阵；但真实浏览器 82/82 都带，生产实现继续带 | 实时链路受控 A/B |

> ⚠️ 「非必需」说的是"可以不带"，「同源」说的是"带了就必须对"，两码事。不要从前者推出后者不用管。
> 也不要外推到其它端点：`userinfo` / `qrcode/status` / `activate` / `user/me` **都没做过这个 A/B**。

## 五、常驻签名服务的并发不变量

page 是单例、被所有 HTTP 请求共用，由此产生三条硬约束。

### 5.1 导航与签名必须互斥

`goto`/`reload` 会销毁 JS 执行上下文，此刻正在跑的 `page.evaluate`（`mnsv2` 签名）会当场抛 `Execution context was destroyed`。

代价不是崩溃（有兜底）而是**整页重新 goto**（最多 4 轮 × ~8s），白白啃掉用户的扫码窗口。所以 `mnsv2` 的 evaluate 要放在导航锁里。

### 5.2 ⚠️ 自死锁陷阱

`asyncio.Lock` **不可重入**。签名的兜底路径是 `except → 标记未就绪 → await 重建环境`，而重建流程内部还要拿同样那两把锁。

**锁必须只包住那一行 evaluate**：

```python
async def _eval_mnsv2(self, c, u, p):
    async with self._nav_lock:                 # 只包这一行
        return await self._page.evaluate(...)

try:
    v = await self._eval_mnsv2(c, u, p)
except Exception:
    # 此处 _nav_lock 已释放，才可以安全回调重建
    self._ready = False
    await self.ensure_ready()
    v = await self._eval_mnsv2(c, u, p)
```

把 `async with` 套在整个 try/except 外层 → **永久卡死**。加锁顺序全局恒为 `_lock → _nav_lock`，不得反序。

### 5.3 ⚠️ 反向陷阱：cookie 操作绝不能加这把锁

`context.cookies()` / `add_cookies()` / `clear_cookies()` 打的是 **browser context（CDP Network 域）**，不是页面的 JS 执行上下文，导航不会让它们失效——加锁属于纯粹的过度同步，会把主链路每个请求都串行化到导航后面。

更硬的理由：cookie 头读取函数被 `_restore_web_session()` 调用，而后者又在导航锁的 `finally` 里被调，**本来就存在"持锁运行"的合法路径**，给它加锁会当场自死锁。

判断标准：**只有"会被导航打断、且被打断后代价大"的调用才值得加锁；实测符合的只有 `mnsv2` 签名这一条。**

### 5.4 每次导航都要 park 登录 session

无头页面带着真 `web_session` 导航 `xiaohongshu.com`，服务端会下发删除指令把它作废（无头指纹触发风控）。纯 API 调用不受影响。

对策：`goto`/`reload` **之前**把 `web_session` 从 context 摘下来，导航完在 `finally` 里放回去，且**必须在释放导航锁之前放回**——否则等锁的请求会带着"没有 web_session"的 cookie 快照发出去，`user/me` 立刻变 guest，看起来就是"登录莫名掉了"。

> 这也解释了为什么浏览器自动化路线（`xiaohongshu-mcp`）历史上能保住登录：它以 `-headless=false` 运行。

### 5.5 退避只能用独立时钟

`x-s-common` 刷新失败时的退避，**不能**用"改捕获时间戳伪造成还没过期"来实现：旧值为空时过期判定恒为真，那种写法压根压不住，会退化成**每个请求 reload 一次的雪崩**。必须用独立的退避截止时刻字段。

### 5.6 Cookie 快照不要缓存

`acw_tc` 约 30 分钟过期、`websectiga` 会轮换。常驻进程冻结快照跑久了必然 406；`context.cookies()` 很便宜，每次请求前现读最稳。

## 六、排查方法论

**怀疑签名坏了的时候，先做受控变量隔离，别急着改算法。**

真实案例：一个长期不发 `Cookie` 的验收脚本跑出 `code=-1 登录异常`，而它的签名完全正确（`x5` 对、`XYS_` 回解一致、紧凑格式生效、版本 live）。照这个信号去改签名实现，改的是没坏的东西。

隔离做法：**保持签名不变**（同一个 `XYS_`、同一次 `mnsv2` 输出），四发请求只改请求头，从结果矩阵反推是哪个头的问题：

```
① 无 Cookie 无 X-s-common   -> code=-1  ❌
② 有 Cookie 无 X-s-common   -> code=0   ✅
③ 无 Cookie 有 X-s-common   -> code=-1  ❌
④ 有 Cookie 有 X-s-common   -> code=0   ✅
```

归因规则：固定一个头、只翻另一个，若结果由败转成则该头必需。

## 七、症状对照表

| 症状 | 首查 |
|---|---|
| HTTP 406 / 网关拒 | 签名侧与发送侧 body 是否同一字符串；GET 的 query 是否进了签名路径 |
| HTTP 200 但 `code=-1 登录异常` | 是否漏发 `Cookie` |
| 明明登录了却显示 guest | 是否在注入 `web_session` 后忘了刷新 cookie 快照就自查；或导航时没 park session |
| 登录莫名掉了 | 无头浏览器带着 session 导航过；或 restore 发生在释放导航锁之后 |
| `Execution context was destroyed` | `mnsv2` evaluate 未受导航锁保护 |
| 请求永久卡死 | 导航锁套在了整个 try/except 外层（自死锁）；或给 cookie 操作加了锁 |
| 每个请求都在 reload | `x-s-common` 退避用了改时间戳的写法而非独立时钟 |
| 扫码永远扫不完 | 二维码刷新周期按"60 秒"设计，实际寿命约 6.9 分钟，刷太勤会丢弃已确认的码 |
