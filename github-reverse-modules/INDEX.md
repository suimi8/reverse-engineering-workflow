# Added Reverse Modules

This directory preserves reverse-only modules copied from the upstream `reverse-skill` repository without overwriting local files in the main skill.

## Included Modules

- `skills/reverse-engineering/`
  - Entry: `skills/reverse-engineering/MODULE.md`
  - Focus: cross-language reverse methodology, anti-analysis, patterns, tool notes, platforms, and field notes.
- `skills/radare2/`
  - Entry: `skills/radare2/MODULE.md`
  - Focus: radare2 CLI workflow, recon, strings/imports, patching, and cheatsheet.
- `skills/ida-reverse/`
  - Entry: `skills/ida-reverse/MODULE.md`
  - Focus: IDA MCP workflow, server startup, and binary open helpers.
- `skills/binary-diff/`
  - Entry: `skills/binary-diff/MODULE.md`
  - Focus: cross-version symbol migration and binary diff workflow.
- `skills/apk-reverse/`
  - Entry: `skills/apk-reverse/MODULE.md`
  - Focus: JADX/apktool decode, manifest summary, Frida run, rebuild-sign-install.
- `skills/mobile-reverse/`
  - Entry: `skills/mobile-reverse/MODULE.md`
  - Focus: Android+iOS mobile reverse methodology.

## Shared Upstream Support

- `skills/scripts/bootstrap-manifest.json`
- `skills/scripts/bootstrap-reverse.ps1`
- `skills/scripts/refresh-tool-index.ps1`
- `skills/scripts/lib/ToolDiscovery.ps1`

These files were copied together because several upstream module scripts depend on the same relative layout under `skills/scripts/`.
