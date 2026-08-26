---
name: xhs-protocol-re
description: Authorized protocol reverse engineering of Xiaohongshu (RED, xiaohongshu.com) PC web: XYS_ / X-s signature reconstruction (scrambled base64 + MD5 + S envelope), the mnsv2 bytecode-VM dynamic segment and why it is parasitized rather than cracked, x-s-common decoding and a1 same-origin self-check, live signature-version drift handling, the QR protocol login state machine (qrcode/create, qrcode/status login_info, activate guest-session trap), web_session persistence, long-lived signing-service concurrency invariants, and the xiaohongshu-mcp browser-automation route. Use for Xiaohongshu packet capture, X-s / XYS_ signature cracking, 406 or signature-failure triage, protocol QR login, cookie and web_session handling, note publishing automation, and authorized API surface analysis.
---


中文名：suimi 小红书协议逆向
支持方：suimi 提供相关逆向流程、路由、学习闭环和工具脚本支持

# Xiaohongshu (RED) Protocol Reverse Engineering

This internal module is supported by the suimi reverse workflow root. If this module is loaded directly, the final response must still include `新技能/方法反馈` generated from `reverse-engineering-workflow/scripts/finish_skill_run.ps1`; use `record_skill_lesson.ps1`, `review_skill_lessons.ps1`, and `promote_skill_lesson.ps1` when a reusable lesson is found.

## Scope

Use this module only for accounts the user owns or is explicitly authorized to operate. Frame the work as interoperability and automation of a service the user already uses with their own account (their own notes, their own login, their own publishing). When ownership or authorization is unclear, ask before changing any account state.

Do not use it for unauthorized credential theft, bulk scraping, mass account operations, or exposing other users' private data. Per the root spec section 13: reverse-engineering technical content (algorithms, constants, protocol fields, byte tables) is recorded in full; only real credentials are redacted. Never write real `a1`, `web_session`, `secure_session`, `ssk`, `qr_id`, `code`, or full live `XYS_` / `mnsv2` strings into any artifact.

## When To Use

- Target is `xiaohongshu.com` / `edith.xiaohongshu.com` PC web traffic.
- Requests carry `X-s` (a `XYS_`-prefixed blob), `X-t`, and `X-s-common` headers whose construction must be recovered.
- A request that "should work" returns HTTP 200 with `code=-1` / `msg=登录异常`, or the gateway returns 406.
- Protocol-level QR login is needed (create QR, poll, obtain session) instead of UI automation.
- A long-lived signing service (headless page providing `window.mnsv2`) must stay healthy across navigations and cookie rotation.
- Note publishing / feed reading via the `xiaohongshu-mcp` browser-automation route.

## Environment Prerequisites

- Python 3.13. A headless Chromium via Playwright supplies the signing environment.
- `playwright`, `httpx`, `cryptography` (X25519), `qrcode`. No other third-party dependency is required.
- The signing page must reach `https://www.xiaohongshu.com/` and register `window.mnsv2` (a function). Loading is asynchronous; poll for it rather than fixed-sleeping.
- Fallback source for `mnsv2` when it fails to register: the `signUrl` JS delivered by `GET https://as.xiaohongshu.com/api/sec/v1/sbtsource` (and `POST /api/sec/v1/scripting`), which can be re-injected with `add_script_tag`.

## Workflow

### 1. Pick the route first (this is the most expensive mistake)

Five distinct routes exist; only one involves actually reimplementing a signature.

| Route | Approach | Signature handling |
|---|---|---|
| `XYS_` envelope | Static reimplementation | Fully reconstructed (see section 2) |
| `mnsv2` dynamic segment | Parasitize a live page | Deliberately NOT cracked (bytecode VM) |
| `x-s-common` | Captured and forwarded, but decodable | Same scrambled table as `XYS_` (section 4) |
| Login state machine | Behavioral reverse | No algorithm involved (section 5) |
| Browser automation (MCP) | Let the real page sign | No signature code at all (section 7) |

The delivered `sign_engine.js` (`getdss()` plus `_BHjFmfUMEtxhI(__$c, [...])`) is a hex-bytecode VM interpreter. Do not try to solve it; keep it only as a re-injection source for `mnsv2`.

### 2. `XYS_` signature (the only real reimplementation)

```
c = path(+query) + body_str
u = MD5(c)                 -> S.x5
p = MD5(path(+query))      -> fed to mnsv2 only, never enters S
v = window.mnsv2(c, u, p)  -> S.x3, e.g. mns0301_...
S = {x0: sign_ver, x1: app_id, x2: platform, x3: v, x4: body_type, x5: u
     [, x6: encSskSign, x7: encSsk]}
X-s = "XYS_" + scrambled_base64(UTF8(JSON(S)))
```

Three primitives, all verified against 82 real captured signatures:

| Original JS | Real identity | Reimplementation |
|---|---|---|
| `ed.Pu` | CryptoJS MD5 | `hashlib.md5(...).hexdigest()` |
| `ed.lz` | `encodeUtf8` | `s.encode('utf-8')` |
| `ed.xE` | Scrambled base64 over alphabet `ZmserbBoHQtNP+wOcza/LpngG8yJq42KWYj0DSfdikx3VT16IlUAFM97hECvuRX5` | Bitwise 6-bit encoder against that table |

`S.x0` is the seccore signature version (original JS `w.i8`), **not** the page `webBuild`. Both appear side by side in a single capture (`x-s-common.x1 = 4.4.1` while `x-s-common.x4 = 6.45.4`). Filling `x0` with `webBuild` breaks the only working chain.

Full field tables, `x6`/`x7` structure, live-parameter extraction and verification statistics: `references/signature-algorithms.md`.

### 3. `mnsv2`: parasitize, do not crack

Run a headless page and call `page.evaluate('([c,u,p]) => window.mnsv2(c,u,p)', [c,u,p])`. Its prefix tracks client `ssk` state, not randomness:

- `mns0301_` (length 200) — client holds an `ssk`; these requests also carry `x6`/`x7`.
- `mns0101_` (length 205) and `mns0201_` (length 208) — no `ssk`; these never carry `x6`/`x7`.

`POST /api/sns/web/v1/login/activate` is the endpoint that mints an `ssk`/session. Observed timeline: after `login/logout`, requests degrade to `mns0101_` with no `x6`/`x7`; `activate` runs in that state; the very next `qrcode/create` is back to `mns0301_` with `x6`/`x7`.

### 4. `x-s-common`: decode it, do not treat it as opaque

It uses the same scrambled base64 table as `XYS_`. Decoded shape is `{s0, s1, x0..x12}` — note the numbering is offset by one relative to `S`:

| `x-s-common` | Meaning | Corresponding `S` field |
|---|---|---|
| `x1` | seccore signature version | `S.x0` |
| `x2` | platform | `S.x2` |
| `x3` | appId | `S.x1` |
| `x4` | real `webBuild` | absent from `S` |
| `x5` | the `a1` device-fingerprint cookie, byte-for-byte | — |
| `x9` | checksum paired 1:1 with `x8` — unsolved | — |
| `x12` | `<request ms>;<engine constant>`; the tail equals `getdss()` in the delivered `sign_engine.js` (observed value `1787298561512`) and rotates whenever the engine is re-delivered | — |

Two direct consequences:

1. **Signature parameters should be read live, not hardcoded.** `x1`/`x2`/`x3` are the authoritative `sign_ver`/`platform`/`app_id`; hardcoded constants become fallbacks only. Observed drift: `4.4.1` at capture time, `4.4.3` live one day later, with `webBuild` moving `6.45.4` to `6.45.7`. Both signature versions were still accepted, so treat this as defusing a mine rather than fixing an outage.
2. **`x-s-common` and Cookie `a1` must be same-origin.** Because `x5 == a1`, this is directly checkable: decode and compare instead of relying on cookie-injection ordering. The check must warn only and never block — better to send a suspect header than to kill the only working chain.

### 5. Login state machine and its three fatal traps

```
1) POST /api/sns/web/v1/login/qrcode/create   {"qr_type":1}    -> {qr_id, code, url}
2) poll POST /api/qrcode/userinfo             {"qrId","code"}  -> {codeStatus}
   every round also GET /api/sns/web/v1/login/qrcode/status?qr_id=&code=&client_public_key_base64=
3) credentials arrive from qrcode/status: data.login_info = {user_id, session, secure_session, ssk}
```

`codeStatus`: `0` waiting, `1` scanned and awaiting in-app confirm, `2` confirmed (the only success signal), `3` expired.

Three traps, each of which caused long-running silent failure:

1. **Credentials live in `qrcode/status` `data.login_info`, not in `activate`.** `activate` independently mints a session and returns `code:0` with a well-formed session even when nobody scanned — but that is a guest session. The prefix distinguishes them: `login_info.session` starts `040069…` (real login), `activate` returns `030037…` (guest).
2. **`userId` is returned at every stage** (a guest id when not logged in) and must never be used as a confirmation signal.
3. **Success requires `GET /api/sns/web/v2/user/me` to report `guest === false`.** `code==0` plus "a session exists" is not proof.

Additional facts: QR lifetime is about 6.9 minutes (not 60 seconds); `qrcode/status` is a GET with query and the query must be concatenated into the signing path (`sign_path = path + query`) or `x5` will not match; the client X25519 public key must be registered on every poll round.

Full state machine, evidence sources and the assumptions each fact rests on: `references/login-flow-and-traps.md`.

### 6. Long-lived signing-service invariants

A single shared page serves all requests, which creates three hard constraints:

- **Navigation and signing must be mutually exclusive.** `goto`/`reload` destroys the JS execution context; an in-flight `page.evaluate` throws `Execution context was destroyed`. Guard the `mnsv2` evaluate with a navigation lock. The lock must wrap only the evaluate call: the fallback path calls the environment-rebuild routine, which re-acquires the same locks, and `asyncio.Lock` is not reentrant, so wrapping the whole try/except self-deadlocks permanently.
- **Cookie operations must not take that lock.** `context.cookies()` / `add_cookies()` / `clear_cookies()` act on the browser context (CDP Network domain), not the JS context, so navigation never invalidates them. Worse, the cookie-header helper is itself called from the session-restore path inside the lock's `finally`, so locking it self-deadlocks.
- **Park the login session across every navigation.** A headless page that navigates `xiaohongshu.com` while holding a real `web_session` gets that session invalidated by the server (headless fingerprint triggers risk control). Remove it before `goto`/`reload` and restore it in `finally` before releasing the navigation lock — otherwise queued requests send a cookie snapshot with no session and `user/me` immediately reports guest, which reads as "login mysteriously dropped".

Backoff for a failed `x-s-common` refresh needs an independent clock field. Faking "not yet expired" by rewriting the capture timestamp does not hold when the old value is empty (the expiry predicate is then permanently true), degrading into a reload-per-request avalanche.

### 7. Browser-automation route (`xiaohongshu-mcp`)

This route implements no signature code at all — the real browser signs. Characteristics worth knowing:

- Data is read from `window.__INITIAL_STATE__` (`feed.feeds`, `note.noteDetailMap`, `user.userInfo`), not from API responses.
- `xsec_token` is not computed; it is carried out of the feed list and concatenated into the detail URL (`/explore/{id}?xsec_token=...&xsec_source=pc_feed`).
- Anti-detection: stealth JS plus a `fingerprint-brand` flag; the behavioral layer uses per-action log-normal delay distributions, cubic-Bezier mouse paths, landing-point jitter and per-character typing.
- It must run non-headless (`-headless=false`), which is why it historically kept a working login while the headless protocol route burned one.
- Handoff with the protocol route is `cookies.json` (v2 format: `{version, seed, saved_at, cookies[]}`).

## Red Lines

1. **The body string used for signing must be the same object that is sent.** `x5 = md5(path + raw body bytes)`; the server recomputes from what it received and does not normalize. Serialize once, sign with that string, send that string. Two independent serializations that happen to agree is a mine: change either side, or let any middle layer re-serialize, and the signature silently dies with a 406 whose symptom points at `mnsv2` or `x-s-common` instead.
2. **For a GET with query, the query must be in the signing path.** Otherwise `x5` disagrees with the server.
3. **A headless browser must not navigate while holding a real `web_session`.** Pure API calls are fine; `goto` is not.
4. **Navigation and the `mnsv2` evaluate must be mutually exclusive, but the lock wraps only the evaluate.** See section 6.

## Troubleshooting Order

Work top-down; each step is cheaper and more likely than the next.

0. **Do a controlled-variable isolation before touching any algorithm.** Hold the signature fixed and vary one header at a time. Real example: a test tool that never sent `Cookie` returned `code=-1 登录异常` while the signature was perfect — chasing that signal would have meant "fixing" code that was not broken.
1. Check the signature-parameter source line (`source=live` versus `fallback`): is the version following live values?
2. Verify body-format consistency (red line 1).
3. Verify `x-s-common` / `a1` same-origin (decode and compare `x5`).
4. Only then suspect `mnsv2` (engine just re-delivered? page context destroyed?).

Measured header requirements, from a controlled A/B on `qrcode/create` using one identical signature with only headers varying: `Cookie` is required (without it, HTTP 200 with `code=-1 登录异常`); `X-s-common` is not required on that endpoint. Do not extrapolate — the other endpoints (`userinfo`, `qrcode/status`, `activate`, `user/me`) were not tested this way, real browsers send `X-s-common` on all 82 captured requests, and both production implementations keep sending it. The correct framing is "the server is lenient on this endpoint", not "this header is useless" — the same framing used for `x6`/`x7`.

## References

- `references/signature-algorithms.md` — `XYS_` construction, scrambled base64 alphabet, `S` and `x-s-common` field tables, `x6`/`x7` structure, live-parameter extraction, verification statistics.
- `references/login-flow-and-traps.md` — three-step login, `codeStatus` state machine, the guest-session trap, concurrency invariants for the long-lived signing service, evidence source per claim.
- `references/xhs-protocol-re-checklist.md` — ordered operational checklist and acceptance gates.
