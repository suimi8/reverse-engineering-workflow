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

## Python Packaged Apps

Hints:

- PyInstaller: `_MEI`, `pyi_`, embedded archive.
- Nuitka: `__compiled__`, many compiled modules, `pythonXY.dll`, Qt/PyQt DLLs.
- PyArmor: `pyarmor_runtime`, obfuscated bytecode loader.

For Python apps, prefer runtime module/method inspection over raw byte patching when possible.
