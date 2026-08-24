# Dynamic Hooking

## Hooking Principles

- Hook the narrowest API that proves the question.
- Log args, return value, caller if available, and timestamp.
- Keep hooks read-only until the branch and payload shape are known.
- Prefer structured payload mutation over string keyword blocking.

## Frida Targets

Common Windows APIs:

- dialogs: `MessageBoxW`, `DialogBoxParamW`, `CreateWindowExW`, `SetWindowTextW`
- process exit: `ExitProcess`, `TerminateProcess`
- network: `WinHttpSendRequest`, `WinHttpReadData`, `InternetOpenUrlW`, `send`, `recv`
- files/config: `CreateFileW`, `ReadFile`, `WriteFile`
- crypto/signatures: `CryptHashData`, `BCrypt*`, OpenSSL exports

Python-hosted apps:

- hook native APIs only for bootstrap.
- once `pythonXY.dll` is initialized, prefer Python injection/probes.

## PyQt Runtime Hooking

Useful hooks:

- wrap `append_log` to rewrite noisy status only after exact message source is known.
- wrap `QMessageBox` / custom message box only for observed dialog classes.
- wrap target slot methods: `show_*_panel`, `open_*_dialog`, `start_*`.
- dump visible widgets before and after every click path.

## Traffic Hooks

For HTTP JSON:

- record URL, method, status, JSON keys, caller feature.
- preserve exact original response in a local log when safe.
- mutate response dictionaries by key after proving the caller.

Avoid broad "any text containing update/auth" logic; it often causes false positives and crashes.
