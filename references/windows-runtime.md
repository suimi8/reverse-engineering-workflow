# Windows Runtime Reverse Notes

## Baseline

- Record: absolute target path, PID, parent PID, command line, cwd, env changes, main HWND, thread ID, exit code.
- Use `tasklist`, `Get-Process`, `GetWindowThreadProcessId`, `EnumWindows`, `EnumChildWindows`.
- Clear proxy/env noise only when it affects reproduction.

## PE And Memory Map

- Identify packer/runtime: PE imports, sections, `MZ/PE` in memory, mapped DLLs, Python/Nuitka/PyInstaller hints.
- Compare disk image vs live memory when packed or self-extracting.
- Use `VirtualQueryEx` to enumerate readable committed regions. Avoid writing until an address is proven.
- Resolve exports from the mapped DLL path plus remote base, not from a guessed static base.

## Thread And Process Probing

- Prefer non-invasive observation first: windows, logs, exit codes, file writes, network traffic.
- If a process exits too early during diagnosis, temporarily log/guard `ExitProcess`/`TerminateProcess` only to capture evidence.
- If injecting Python into a Python-hosted app, confirm `python*.dll` is mapped and `Py_IsInitialized` is true.
- For thread hijack probes, save/restore context, run short code, log status, and do not leave sleeping shellcode unless it is intentional.

## Crash/Freeze Triage

- "Crash" checklist: process alive, modal dialog visible, main HWND hidden/minimized, UI thread blocked, worker thread running, subprocess stuck.
- For freezes, sample thread list and worker state before adding patches.
- For GUI apps, a modal `QDialog`/native `#32770` can look like a freeze.

## WAM (Web Account Manager) Token Acquisition

Office desktop apps (Excel, Word, PowerPoint) use Windows WAM to acquire AugLoop/Copilot tokens. Key findings for reverse engineering and token reuse:

### Architecture

1. **JS layer** (`AugLoop/bundle.js`): `getAuthToken()` → `hostCallbacks.requestAuthToken({TokenType})` → host returns `{Token, TokenProperties:{timeToLiveSec}}`
2. **Native layer** (`EXCEL.EXE`): `GetAuthToken` / `GetAuthTokenTicket` → `GetADALAuthorityUrl` → ADAL/WAM API
3. **System layer**: WAM (WinRT `Microsoft.Security.Authentication.OAuth.OAuth2Manager`) → DPAPI-encrypted token cache

### Why HTTP proxy capture misses auth traffic

WAM uses system-level WinHTTP, not application-level proxy settings. `refresh_token` is cached in system-level DPAPI storage (not in Office AppData). Validity: ~90 days. `access_token` TTL: ~1 hour.

### Key strings in EXCEL.EXE

`SilentLogin`, `TokenValue`, `AccessToken`, `GetADALAuthorityUrl`, `GetAuthTokenTicket`, `TicketConditionalAccessError`, `AuthChallenge`, `InteractiveFlowInvoked`, `GetAccessTokenV3Main`, `GetAccessTokenV3Background`, `DELEGATED`, `TokenExpired`

### Token reuse via MSAL.NET WAM broker

Use `PublicClientApplicationBuilder.Create(clientId).WithBroker(new BrokerOptions(BrokerOptions.OperatingSystems.Windows))` + `AcquireTokenSilent()` to reuse the system-cached `refresh_token`. No HTTP proxy needed.

**Important**: MSAL.NET WAM broker requires `Microsoft.Identity.Client.Broker` NuGet package and `net8.0-windows10.0.19041.0` target framework. Interactive login requires `.WithParentActivityOrWindow(hwnd)` — use `GetForegroundWindow()` or `GetDesktopWindow()` when no console window is available.

### OneAuth SDK (not WAM)

Modern Office apps (2024+) use **OneAuth** SDK, not standard WAM, for token management. OneAuth cache is at `%LOCALAPPDATA%\Microsoft\OneAuth\`:

- `accounts/<id>` — plaintext JSON with user info, `wam_account_ids`, `authority`, `realm`
- `blobs/<id>_avatar` — user avatar
- `blobs/<id>_substrate_profile` — profile data
- `blobs/<provider>_hrd` — Home Realm Discovery config (MSA/AAD endpoints)
- `blobs/<email>_identity_provider` — provider type (MSAccount)

Registry: `HKCU\Software\Microsoft\Office\16.0\Common\Identity\ConnectedOneAuthAccountId` links to OneAuth account ID.

**OneAuth `wam_account_ids` field** lists all WAM client_ids associated with the account. For Office user `suimigg2@outlook.com`:
- `0ec893e0-5785-4de6-99da-4ed124e5296c` (Office, associated)
- `82864fa0-ed49-4711-8395-a0e6003dca1f` (OneAuth SDK aud)
- 6 additional WAM account IDs

**WAM standard API cannot enumerate OneAuth accounts** — `WebAuthenticationCoreManager.FindAllAccountsAsync()` returns empty/ProviderError for OneAuth-managed accounts. MSAL.NET WAM broker `GetAccountsAsync()` also returns empty.

**AugLoop scope (`https://augloop.svc.cloud.microsoft/.default`) returns `ApiContractViolation`** for all known public client_ids. AugLoop token (JWE format `eyJhbGciOiJkaXIi...`) is likely obtained via Office's internal SSO API (`GetAccessTokenV3Main`), not standard OAuth2/WAM.

### WAM interactive login works for Graph, not AugLoop

Interactive WAM login with `0ec893e0-5785-4de6-99da-4ed124e5296c` + `https://graph.microsoft.com/.default` succeeds (returns JWT token). But silent refresh fails — MSAL.NET token cache is in-memory and not persisted across process restarts without explicit `ITokenCache` serialization.

**Conclusion**: For AugLoop token acquisition, WAM/OneAuth approach is blocked. AugLoop token requires either:
1. HAR capture from Excel (current method)
2. Frida hook on `GetAuthToken`/`GetAuthTokenTicket` in EXCEL.EXE
3. Office internal SSO API reverse engineering (requires deeper binary analysis)

## Promoted Learning Notes

### Office AugLoop WAM Token Silent Refresh Mechanism

- source: `20260726-101500-office-augloop-wam-token-silent-refresh`
- category: method
- applies_to: Microsoft Office desktop apps (Excel/Word/PPT) using AugLoop/Copilot, Windows WAM-based authentication analysis
- purpose_zh: Office原生应用通过Windows WAM系统级缓存refresh_token实现静默token续期，绕过HTTP代理抓包；直接调用WAM API可实现长效token获取
- confidence: 4/5

**Lesson**

Office桌面应用(Excel等)的AugLoop/Copilot token获取链路为三层架构: (1)JS层AugLoop/bundle.js通过hostCallbacks.requestAuthToken({Tickets:[], DocSessionId, TokenType})向宿主请求token; (2)Excel原生C++通过GetAuthToken/GetAuthTokenTicket调用GetADALAuthorityUrl获取AAD Authority URL; (3)最终通过Windows WAM(Web Account Manager)系统级API获取token。WAM在系统级DPAPI加密存储中缓存refresh_token(有效期约90天)，每次Excel启动时通过SilentLogin静默续期access_token(TTL约1小时)。WAM使用系统级WinHTTP网络栈，不读取应用级代理设置，因此HTTP代理抓包无法捕获认证流量。这就是为什么HAR抓包中看不到login.microsoftonline.com的OAuth登录流量。突破方案: 使用MSAL.NET的WAM broker模式(.WithWindowsBroker())，用相同MSA账户和client_id直接调用AcquireTokenSilent()，可复用系统缓存的refresh_token静默获取新token，实现长效token效果。

**Evidence**

EXCEL.EXE字符串: SilentLogin, TokenValue, AccessToken, GetADALAuthorityUrl, GetAuthTokenTicket, GetAuthTokenTicketRetry, TicketConditionalAccessError, TicketAuthError, InteractiveFlowInvoked, AuthChallenge, StartCopilotOperation, EndCopilotOperation; EXCEL.EXE manifest引用Microsoft.Security.Authentication.OAuth.OAuth2Manager(WinRT OAuth2); AugLoop/bundle.js: hostCallbacks.requestAuthToken()回调机制, getAuthToken()返回{Token, TokenProperties:{timeToLiveSec}}; Office AppData(%LOCALAPPDATA%\Microsoft\Office\16.0)无Token/Auth缓存目录(证实缓存在Windows系统级WAM存储中); services-msa-authentication: OAuth Implicit Flow response_type=token(无refresh_token暴露给应用); OSF.DLL: IsAugloopScenario

**Validation**

静态分析验证: EXCEL.EXE二进制中grep到SilentLogin/GetADALAuthorityUrl等关键函数名字符串; manifest中引用OAuth2Manager WinRT类; Office AppData目录无token缓存子目录; AugLoop/bundle.js中hostCallbacks.requestAuthToken()调用链路完整