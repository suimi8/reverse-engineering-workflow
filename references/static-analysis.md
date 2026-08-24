# Static Analysis

## First Pass

Run static triage before patching:

- `file` / PE headers / architecture / subsystem / timestamp.
- imports/exports, TLS callbacks, resources, section names, entropy, overlay.
- strings grouped by feature: auth, update, server, dialog, config, file paths, Python/Qt/Nuitka/PyInstaller.
- compare disk imports with live memory modules when the app is packed.

## IDA / Ghidra / Binary Ninja

Workflow:

1. Load with correct arch and image base.
2. Let auto-analysis finish; save database.
3. Rename functions from imports, strings, dialogs, network endpoints, and log messages.
4. Trace xrefs from decisive strings to caller functions.
5. Build a small call graph around the target behavior, not the whole program.
6. Validate every decompiler guess with runtime evidence.

Signals to mark:

- compare/branch around result flags.
- JSON parsing and config keys.
- dialog constructors and message text.
- process exit paths.
- network request wrappers.
- update/version comparison.
- license/session/heartbeat workers.

## x64dbg Static-Dynamic Bridge

Use x64dbg when the exact branch matters:

- Break on `MessageBoxW/A`, `DialogBoxParamW/A`, `CreateWindowExW`, `ExitProcess`, `TerminateProcess`.
- Break on `WinHttpSendRequest`, `InternetOpenUrlW`, `WSASend`, `send`, `recv`.
- Set hardware breakpoints on changed config/global flags after identifying them.
- Patch in memory first. Export a persistent patch only after repeated verification.
- For the full 71-tool x64dbg-mcp-server workflow (breakpoints, memory/register read-write, module/symbol search, OEP detection, dumping) and its install/health scripts, load `github-reverse-modules/skills/x64dbg-reverse/MODULE.md`; tool-call cheatsheet is at its `references/x64dbg-mcp-cheatsheet.md`.

## Python Packaged Apps

Hints:

- PyInstaller: `_MEI`, `pyi_`, embedded archive.
- Nuitka: `__compiled__`, many compiled modules, `pythonXY.dll`, Qt/PyQt DLLs.
- PyArmor: `pyarmor_runtime`, obfuscated bytecode loader.

For Python apps, prefer runtime module/method inspection over raw byte patching when possible.

## Promoted Learning Notes

### x64dbg-reverse 模块需要从 static-analysis.md 交叉引用才能被发现

- source: `20260824-014417-x64dbg-reverse-模块需要从-static-analysis-md-交叉引用才能被发`
- category: tooling
- applies_to: reverse-engineering-workflow 技能包自身的可发现性
- purpose_zh: 让先读 references/static-analysis.md 的用户或 agent 也能发现新增的 x64dbg-reverse 动态调试模块，否则装好了也没人知道去哪找
- confidence: 3/5

**Lesson**

在 references/static-analysis.md 的 "x64dbg Static-Dynamic Bridge" 小节末尾追加一句指引: 需要完整的 x64dbg 动态调试工作流(71 个 MCP 工具: 断点/内存读写/寄存器/模块符号/OEP 检测/内存转储等)时, 加载 github-reverse-modules/skills/x64dbg-reverse/MODULE.md, 工具速查见其 references/x64dbg-mcp-cheatsheet.md, 部署用 scripts/install.ps1。

**Evidence**

static-analysis.md 现有的 x64dbg 小节只列了几条断点技巧(MessageBoxW/WinHttpSendRequest 等), 完全没有提到新增的 x64dbg-reverse 完整模块的存在, 从这条路径进来的读者/agent 发现不了它。

**Validation**

人工核对 static-analysis.md 现有内容确认缺少该指引