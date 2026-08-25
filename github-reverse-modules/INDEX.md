# Added Reverse Modules

This directory preserves reverse-only modules bundled into the reverse-engineering-workflow package as local internal modules.

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
  - Focus: x64dbg-mcp-server plugin deployment, token/port handling, and the 71-tool runtime debugging workflow.
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
- `skills/dotnet-reverse/`
  - Entry: `skills/dotnet-reverse/MODULE.md`
  - Focus: .NET / C# assembly reverse, dnSpyEx + de4dot, obfuscators, NativeAOT, Sharp* tooling, AI-assisted .NET analysis.
- `skills/js-reverse/`
  - Entry: `skills/js-reverse/MODULE.md`
  - Focus: JavaScript/Web frontend reverse, webpack/IIFE deobfuscation, AST rewriting, browser runtime capture.
- `skills/ghidra-reverse/`
  - Entry: `skills/ghidra-reverse/MODULE.md`
  - Focus: Ghidra headless/scripting reverse workflow, decompiler API, Sleigh, plugins.
- `skills/go-rust-reverse/`
  - Entry: `skills/go-rust-reverse/MODULE.md`
  - Focus: Go and Rust binary reverse: symbol recovery, type info, goroutine/Rust stdlib patterns, string recovery.
- `skills/malware-analysis/`
  - Entry: `skills/malware-analysis/MODULE.md`
  - Focus: malware triage, sandbox analysis, unpacking, persistence, IOC extraction.
- `skills/firmware-pentest/`
  - Entry: `skills/firmware-pentest/MODULE.md`
  - Focus: firmware extraction, filesystem carving, bootloader/secure-boot review, device emulation.
- `skills/protocol-reverse/`
  - Entry: `skills/protocol-reverse/MODULE.md`
  - Focus: network protocol reverse, traffic replay, field mapping, custom protocol documentation.
- `skills/thick-client/`
  - Entry: `skills/thick-client/MODULE.md`
  - Focus: thick/thin client (desktop app) reverse: API interception, process memory, config extraction.
- `skills/patch-diff-exploit/`
  - Entry: `skills/patch-diff-exploit/MODULE.md`
  - Focus: patch diffing to locate fixed vulnerabilities, exploit development from version deltas.
- `skills/pwn-chain/`
  - Entry: `skills/pwn-chain/MODULE.md`
  - Focus: exploit chain assembly, mitigation bypass (ASLR/DEP/CFG), debugger-driven exploit dev.
- `skills/edr-bypass-re/`
  - Entry: `skills/edr-bypass-re/MODULE.md`
  - Focus: EDR/AV evasion research for red-team scenarios, API unhooking, syscall analysis.
- `skills/macos-reverse/`
  - Entry: `skills/macos-reverse/MODULE.md`
  - Focus: macOS/iOS binary reverse: Mach-O, Objective-C runtime, entitlements, codesigning.
- `skills/browser-extension-reverse/`
  - Entry: `skills/browser-extension-reverse/MODULE.md`
  - Focus: browser extension reverse: unpack CRX, analyze manifest/permissions, intercept messaging.
- `skills/reverse-engineering/dsl-vm-reverse/`
  - Entry: `skills/reverse-engineering/dsl-vm-reverse/MODULE.md`
  - Focus: JavaScript-based custom DSL/VM interpreters, opcode dispatch tables, bytecode semantics recovery, risk-control engine reverse.
- `skills/web-api-reverse/`
  - Entry: `skills/web-api-reverse/MODULE.md`
  - Focus: web backend API reverse: recover internal API protocol from traffic/HAR/cURL, REST/GraphQL/batchexecute/gRPC-web detection, auth detection, generate Python httpx / TypeScript client + API docs.
- `skills/web-js-reverse/`
  - Entry: `skills/web-js-reverse/MODULE.md`
  - Focus: web frontend JS reverse: obfuscation grading and deobfuscation, JSVMP 5-step methodology, CDP detection bypass, TLS/HTTP2/QUIC fingerprint, env patching, WASM reverse, layered anti-crawler bypass.
- `skills/web-crypto-reverse/`
  - Entry: `skills/web-crypto-reverse/MODULE.md`
  - Focus: web/APK crypto reverse: identify and rebuild encryption/signing algorithms in Python from Web JS and Android APK, 30-specialist index, Web2/Web3 determination, online verification loop.

## New References

- `skills/reverse-engineering/references/nonpe-format-cookbook.md` — non-PE binary formats cookbook
- `skills/reverse-engineering/references/ollvm-deobfuscation.md` — OLLVM deobfuscation
- `skills/reverse-engineering/references/re-agent-workflow.md` — reverse-agent workflow notes
- `skills/ida-reverse/scripts/watchdog.ps1` — minute-level IDA MCP health check
- `skills/ida-reverse/scripts/install-autostart.ps1` — login autostart task registration
- `skills/ida-reverse/scripts/start-gui.ps1` — GUI-plugin start fallback
- `skills/ida-reverse/scripts/run-supervisor.py` — Python supervisor equivalent
- `skills/ida-reverse/scripts/IdaOpenHelpers.ps1` — shared open-lock policy
- `skills/ida-reverse/LOCAL-SETUP.md` — IDA ↔ reverse-engineering-workflow install/configure notes

## Shared Support Scripts

- `skills/scripts/bootstrap-manifest.json`
- `skills/scripts/bootstrap-reverse.ps1`
- `skills/scripts/refresh-tool-index.ps1`
- `skills/scripts/lib/ToolDiscovery.ps1`

These files are bundled together because several modules depend on the same relative layout under `skills/scripts/`.
