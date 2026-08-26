# Added Local Reverse Modules

This directory preserves suimi local reverse recovery modules for authorized Windows packaged desktop apps. The root `SKILL.md` router loads them on demand when the target is a local Windows Python/Flet packaged app or a localhost helper service rather than a generic PE/APK/mobile target. They are not installed as separate skills.

## Included Modules

- `skills/flet-desktop-diagnostics/`
  - Entry: `skills/flet-desktop-diagnostics/MODULE.md`
  - Focus: Flet packaged desktop app.exe/flet.exe process-pair relationship, hidden or blank window response, AppData resource/config discovery, localhost API dependency checks, and functional UI verification.
- `skills/windows-python-app-recovery/`
  - Entry: `skills/windows-python-app-recovery/MODULE.md`
  - Focus: lost-source Windows Python/Flet/Nuitka/PyInstaller packaged app recovery, LOCALAPPDATA/APPDATA state repair, localhost helper service restoration, Startup persistence, and cold-start validation.
- `skills/windows-local-service-persistence/`
  - Entry: `skills/windows-local-service-persistence/MODULE.md`
  - Focus: Windows loopback (127.0.0.1) helper service startup repair, Startup-folder/PowerShell launcher patterns, scheduled-task fallback, port no-op duplicate guards, and cold-start verification.
- `skills/mirasim-godmode-re/`
  - Entry: `skills/mirasim-godmode-re/MODULE.md`
  - Focus: Mirasim 桌面单机德州扑克机台（Electron）的 renderer 多副本发现、版本升级失效诊断、补丁串多版本适配、多目标打补丁与 asar 重打包，含 godmode_bot / gui_server 状态读取兼容性。
- `skills/wechat-miniapp-protocol-re/`
  - Entry: `skills/wechat-miniapp-protocol-re/MODULE.md`
  - Focus: 微信 PC 小程序协议逆向与自动化（mitmproxy 抓包、sign/req-id 双盐双层 MD5、V8 内存源码提取、业务接口链路、PySide6 GUI 集成）。
- `skills/xhs-protocol-re/`
  - Entry: `skills/xhs-protocol-re/MODULE.md`
  - Focus: 小红书 PC web 协议逆向（XYS_/X-s 签名复刻、mnsv2 字节码 VM 寄生、x-s-common 解码与 a1 同源自检、签名版本漂移实时取参、扫码登录 login_info 与 activate 游客陷阱、常驻签名服务导航互斥、xiaohongshu-mcp 浏览器路线）。

## Shared Support Scripts

These local modules are authored by suimi and depend only on the root package scripts (`scripts/`) and references; they bundle no external tooling.

## Registration

These modules are also registered in the root `SKILL.md` "Added Local Reverse Modules" section, in `references/unified-skills-entry.md` (the "本地逆向恢复技能" table), and in `references/chinese-skill-names.json`. See `references/module-onboarding-spec.md` section 5.C for the full local-module onboarding checklist.
