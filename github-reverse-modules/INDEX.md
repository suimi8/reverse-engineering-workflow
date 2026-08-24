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
- `skills/x64dbg-reverse/`
  - Entry: `skills/x64dbg-reverse/MODULE.md`
  - Focus: x64dbg-mcp-server (duty1g) plugin deployment, token/port handling, and the 71-tool runtime debugging workflow.
- `skills/ce-reverse/`
  - Entry: `skills/ce-reverse/MODULE.md`
  - Focus: Cheat Engine MCP (ce_mcp) Lua-bridge deployment and the 127-tool memory scanning/pointer-chain/hook workflow.
- `skills/binary-diff/`
  - Entry: `skills/binary-diff/MODULE.md`
  - Focus: cross-version symbol migration and binary diff workflow.
- `skills/traffic-capture/`
  - Entry: `skills/traffic-capture/MODULE.md`
  - Focus: tshark interface-level capture with SSLKEYLOGFILE and mitmproxy man-in-the-middle capture for recovering HTTP(S) request/response evidence from local binaries, desktop apps, or mobile targets.
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
