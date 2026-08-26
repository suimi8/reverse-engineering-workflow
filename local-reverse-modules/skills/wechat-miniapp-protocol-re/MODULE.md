---
name: wechat-miniapp-protocol-re
description: Authorized protocol reverse engineering of WeChat PC mini-programs: mitmproxy upstream sniffing (bypassing TUN), sign/req-id dual-salt nested-MD5 signature cracking, V8 memory module-source extraction (UTF-16), full business API chain (lottery/checkin/tasks/turntable/bless-card/1888-redpacket/help-multiplier), and PySide6 GUI integration. Use for WeChat mini-program packet capture, protocol reverse, signature cracking, mini-program automation, lottery automation, wxapkg reverse, and authorized API surface analysis.
---


中文名：suimi 微信小程序协议逆向
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# WeChat Mini-Program Protocol Reverse Engineering

This internal module is supported by the suimi reverse workflow root. If this module is loaded directly, the final response must still include `新技能/方法反馈` generated from `reverse-engineering-workflow/scripts/finish_skill_run.ps1`; use `record_skill_lesson.ps1`, `review_skill_lessons.ps1`, and `promote_skill_lesson.ps1` when a reusable lesson is found.

## Scope

Use this module only for mini-programs the user owns, operates, or is explicitly authorized to inspect. Keep the work framed as interoperability, automation, and analysis of services the user already uses with their own account. When ownership or authorization is unclear, ask for clarification before changing any account state.

Do not use this module for unauthorized credential theft, bulk scraping, abuse of third-party services, or exposing other users' private data. Redact real tokens, URLs, and credentials in any written output; use placeholders such as `example.com` or `<REDACTED>`.

## When To Use

- Target is a WeChat PC mini-program container (`WeChatAppEx.exe`) or its service traffic.
- The mini-program `.wxapkg` package is encrypted (e.g., `V1MMWX4L` Radium WMPF format) and static unpacking is not viable.
- Network requests carry custom `sign` / `req-id` headers whose algorithm must be recovered.
- The user wants protocol-level automation (participation, check-in, tasks, red packets) for their own account.
- GUI integration (PySide6/PyQt) of the reversed protocol is needed.

## Environment Prerequisites

- `mitmproxy 12.2.2` installed; launch via `mitmweb.exe` directly (`python -m mitmweb` fails).
- Upstream mode to bypass TUN: `--mode upstream:http://127.0.0.1:7897` (loopback, never enters Clash TUN).
- Full launch line:
  ```
  mitmweb.exe --listen-port 8080 --web-port 8082 --mode upstream:http://127.0.0.1:7897 \
    --set dns_server=223.5.5.5 --set ssl_insecure=true -s wechat_sniffer.py
  ```
- System proxy must point at `127.0.0.1:8080` (WeChat mini-program container honors the system proxy). Clash may reset it; check `ProxyEnable` and `ProxyServer` registry values before each capture round.

## Workflow

### 1. Sniffing Environment (get it right first)

1. Kill stale mitmweb processes; start via the exact command above with the addon at a **pure-ASCII path**.
2. Confirm ports 8080/8082 open and the system proxy points at 8080 with `ProxyEnable=1`.
3. Ask the user to fully close the mini-program (close the WeChat mini-program page), then reopen it so the container picks up the new proxy. A running container caches the old proxy and will bypass mitmproxy.
4. After the user's manual operation, read the newest `flows/session_*_all_requests.json`; never rely on the web UI (its content APIs 404 in mitmproxy 12).

### 2. Signature Cracking (the core)

Recover from memory-dumped module source (`request/asd.js`):

- `sign = md5( md5( fullURL + "axjalsdjfsfa" + sec_ts + "axjalsdjfsfa" + token ) )`
- Normal `req-id = md5( md5( "tuyang2020" + path + "tuyang2020" + token + ts8 ) )`, `ts8 = str(sec_ts)[:-2]`
- h5Urls special `req-id = md5( md5( O + path + O + d + token + ts8 ) )` where
  - `O = "function(a){return function(b){return c}}"` (fixed pseudo-random string; not guessable by brute force)
  - `d = md5( O + sorted_concat + O ).toUpperCase()` (uppercase!)
  - `sorted_concat` = keys of `{...body, ts:ts8, s:O, f:"json", v:"1.0", t:token}` sorted lexicographically, `key+value`, arrays/objects via `JSON.stringify`
  - **`t` is the token, not the URL** (classic pitfall)
- `p = (Date.parse(new Date)/1e3 + interval + "").slice(0,-2)` = integer seconds truncated to ts8
- h5Urls whitelist (hardcoded in asd.js): `/v2/lottery/join`, `/api/v2/stat/userProfile`, `/v2/user/authCaptcha/post`, `/v2/user/authCaptcha/get`, `/v2/lotteries/getPlayingMultiple` (plus 30 `/h5/`-prefixed variants that need H5 login state; avoid them)

### 3. V8 Memory Source Extraction

- Static `.wxapkg` unpacking is a dead end for `V1MMWX4L` (Radium WMPF). Scan process memory instead.
- Main process (e.g., PID 39752): UTF-8 V8 string tables (paths, salts, constants).
- Business JS process (e.g., PID 38980): **UTF-16 full module source** with 49 `define("module")` blocks.
- V8 GC relocates objects; PIDs are unstable — rescan as needed.
- **VirtualQueryEx pitfall**: the first region (address 0) may return `BaseAddress=None`; always use `base = mbi.BaseAddress or addr`.
- Extract modules by locating `define("request/asd.js"` and slicing to the next `define(`.

### 4. Full API Chain (all verified over protocol)

Domains:
- `BASE` = `https://api-hdcjgo.9w9.com` (login/lotteries/v2)
- `BASE_V5` = `https://api-hdcj.9w9.com` (tasks/sign/turntables/bless_card)
- `STAT` = `https://statapi.9w9.com` (statistics)

Complete lottery participation chain:
1. `POST /lotteries/{lid}` detail body `{qrcode_id:"",snow_id:"",qrcode_scene:"",pid:"",push_type:0,poolSort:0,isCycle:0,lotterySource:1,isPushReturn:0}` → returns `secret` (JWT, 24h) + `joinTypes` (pre-tasks) + `prizeList[0].awardId`
2. If pre-task present: `POST /v2/lotteries/getPlayingMultiple {lid, playingType:101, playingId:task_id}` completes it (mini-program experience / article browsing both work)
3. `POST /v2/lottery/join {lid, secret, isAllowAuthorizePhone:1, template, awardId?...}` → `data.lottery_code`
4. `GET /v5/lotteries/{lid}/realtime/myList` → win check
5. `POST /lottery/receiveRedPacket {lid, snowId}` → claim red packet

Pre-task types (joinTypes):
- `joinAppletsTaskNew` (experience mini-program 10s): ✅ protocol-completable via getPlayingMultiple playingType:101
- `joinArticleInfo` (browse WeChat article 15s): ✅ same
- `joinMiniProgramInfo` (watch video): does not block join
- upload-credential review (`userReviewTask`): ❌ manual only

Daily tasks:
- `GET /v5/tasks/taskList/lucky` (get_status: 0=not done, 2=claimable, 3=claimed)
- `GET /v5/tasks/taskList/card` / `me_interstitial`
- `POST /v5/tasks/{id}/status/{n}/{scene}` n=2 claim / n=3 watch-report; scene=card/condition/help/lucky5
- `POST /v5/tasks/218` → +60 lucky coins (sign video double)
- `POST /getTaskList {taskScene:"special"}` + `POST /completeTask {id}` + `POST /receiveTask {id}` (watch-full-video +20 coins x10)
- **get_status=2 means "completed, claimable"** — claim via the route's status/3
- **Unconditional tasks** (empty condition_count): claim directly with status/2 or status/3
- Already-claimed (7006/7007) is normal daily-one-time behavior

Turntable:
- `GET /v5/turntables/home` (is_turn/surplus_number/free_admission_number/lucky)
- `PUT /v5/turntables/start` (**PUT method!** body={} scene=1256 → prize)
- `GET /v5/turntable/get_records?type=1&page=1&limit=20`

Bless card (lucky-dial page draw):
- `POST /v5/bless_card/bless_card_window` (status: 1=task running, 2=card claimable)
- `POST /v5/bless_card/open_bless_card` `{index:1, sceneType:1}`
- `POST /v5/bless_card/draw_money` (**empty body works**)
- `POST /blessCard/list` (5 red-packet tasks: ¥0.15/¥0.07/¥0.18/+19 coins/+21 coins)

1888 red-packet events (2 chances/day):
- `POST /lottery/homeCarveRed` → awardCount=2, joinButtonText="已参与1/2"; run the full lottery chain per lid

Help multiplier (watch video boosts win rate):
- `POST /v5/stat/advert_action_record` `{ad_type:1, lid, ad_id:"", scene_type:1, action_type:1/2}` (1=start 2=end)
- `POST /v2/lotteries/getPlayingMultiple {lid, playingType:100, helpTimer:1, playingId:video_task_id}` (**helpTimer=1 settles; 0 does not**)
- Each settle: finished+1, multiple+20~30, per-activity cap helpCompleteNum=3
- Ad-task lottery codes: `POST /v5/tasks/3B9GAX8|6DXEQYB|280GGT0/status/3/condition` (once/day each)

Check-in & wallet:
- `GET /v5/sign`, `GET /v5/sign/sign` (do check-in)
- `POST /user/withdrawal` (**must use BASE domain**) → money/countMoney

**★ Real lucky-coin balance**: `sign_info.first_lucky_count` is NOT the balance (it is the "first check-in bonus", e.g. 379). The real balance is `turntable_info.lucky` from the turntable endpoint (e.g. 1280).

### 5. GUI Integration (PySide6)

1. **Never do network I/O on the UI thread**: every slow operation (draw/boost/batch tasks) must run in `threading.Thread` and return via `Signal`.
2. Batch operations (1888 participation/boost) show one summary dialog, not one per activity.
3. Local history cache: when the server stops returning completed tasks, persist them to `task_history.json` for display.
4. Merge activity lists: `homeRecommend` (3) + `homeSelfHelp` (10), deduplicated by lid.
5. h5Urls req-id includes the body: `make_reqid(path, body=body)`.
6. Tolerant JSON: parse concatenated JSON frames with `raw_decode` in a loop (mitmproxy upstream occasionally glues two response frames).

### 6. Request Header Template

```python
headers = {
    'uid': uid, 'content-type': 'application/json',
    'app-version': '9.2.49', 'req-id': make_reqid(path, ts, body),
    'client-info': '', 'scene': '1044',  # turntable uses 1256
    'sign': make_sign(url, ts), 'appid': '0', 'token': token,
    'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 '
                  'MicroMessenger/7.0.20.1781(0x6700143B) NetType/WIFI '
                  'MiniProgramEnv/Windows WindowsWechat/WMPF',
    'xweb_xhr': '1', 'accept': '*/*',
    'referer': 'https://servicewechat.com/wx4692f08fa6ad3bc2/1689/page-frame.html',
}
```
- scene values: 1000/1001/1027/1044 (business), 1256 (turntable/bless card)
- Two response shapes: `{code:0,...}` or `{success:true,message:{code:0,...}}`
- Error codes: 7005=done, 7006/7007=already claimed, 7008=pre-task not done, 2037=already drawn today, 9527=verification required

## References

- `references/wechat-miniapp-re-checklist.md` — quick capture/verify checklist
- `references/signature-algorithms.md` — sign/req-id formulas with worked samples
