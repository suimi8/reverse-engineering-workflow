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

## Shared Upstream Support

These local modules are authored by suimi and depend only on the root package scripts (`scripts/`) and references; they bundle no upstream donor tooling.

## Registration

These modules are also registered in the root `SKILL.md` "Added Local Reverse Modules" section, in `references/unified-skills-entry.md` (the "本地逆向恢复技能" table), and in `references/chinese-skill-names.json`. See `references/module-onboarding-spec.md` section 5.C for the full local-module onboarding checklist.
