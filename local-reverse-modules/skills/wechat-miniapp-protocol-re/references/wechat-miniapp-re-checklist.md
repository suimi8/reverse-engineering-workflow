# 微信小程序协议逆向 — 抓包/验证检查清单

## 抓包环境检查（每次用户操作前）

- [ ] mitmweb 进程存活（netstat 8080/8082 LISTENING）
- [ ] 系统代理 `ProxyEnable=1`、`ProxyServer=127.0.0.1:8080`（Clash 会重置！）
- [ ] addon 在纯 ASCII 路径（`C:/Temp/9w9_sniffer/wechat_sniffer.py`），中文路径会编码破坏
- [ ] 用户需完全关闭小程序再重开（容器缓存旧代理）
- [ ] 确认最新 flows 文件 mtime 在用户操作时间之后

## 签名验证

- [ ] `sign = md5(md5(url + "axjalsdjfsfa" + sec_ts + "axjalsdjfsfa" + token))`，ts=秒级
- [ ] 普通 req-id：`md5(md5("tuyang2020" + path + "tuyang2020" + token + ts8))`，ts8=秒[:-2]
- [ ] h5Urls：`md5(md5(O + path + O + d + token + ts8))`，O 固定串，d 大写
- [ ] d 的排序拼接含 `ts/s/f/v/t` 五个附加键（t=token 不是 url！）
- [ ] 用历史样本 3/3 复验后再发新请求

## 完整参与链路

1. `POST /lotteries/{lid}` → 正则提取 `secret`（JWT 24h）
2. 有前置任务 → `getPlayingMultiple {playingType:101, playingId}`
3. `POST /v2/lottery/join`（带 secret/template）→ lottery_code
4. `GET /v5/lotteries/{lid}/realtime/myList` → 中奖
5. `POST /lottery/receiveRedPacket {lid, snowId}` → 领红包

## 常见错误码

| 码 | 含义 | 处理 |
|----|------|------|
| 7005 | 任务已完成 | 用 route 的 status/3 领取 |
| 7006/7007 | 已领取过 | 每日限一次，正常 |
| 7008 | 请先完成任务 | getPlayingMultiple 补任务 |
| 2037 | 今日已抽 | 明日再来 |
| 9527 | 需验证 | 无法协议绕过 |
| 1003 | 手速太快 | 限流，等待后重试 |
