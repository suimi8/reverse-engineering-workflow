# Unpacking

## Goal

Do not "脱壳" blindly. The goal is a stable analysis point:

- original entry point or post-loader entry.
- imports resolved enough to run or analyze.
- code/data sections dumped after decryption/decompression.
- runtime behavior reproduced from the dumped image or documented injection path.

## Triage

Packer hints:

- high entropy executable section.
- few imports, suspicious loader APIs, custom section names.
- OEP jumps from small stub to large region.
- code executes from `VirtualAlloc` / `VirtualProtect` memory.
- disk image strings missing but live memory strings present.

## Dynamic Unpack Flow

1. Launch under debugger or controlled launcher.
2. Break on `VirtualAlloc`, `VirtualProtect`, `WriteProcessMemory`, `LoadLibrary`, `GetProcAddress`.
3. Watch for transition from stub to stable code region.
4. Dump memory region containing `MZ/PE` or decrypted code.
5. Rebuild imports if needed.
6. Compare dumped code strings/imports with runtime behavior.

## OEP Hints

Likely OEP when:

- stack/registers stabilize after unpacking loop.
- imports are resolved.
- program initializes runtime/library (`pythonXY.dll`, Qt, CRT, MFC, .NET).
- control transfers from high-entropy loader to normal code section.

## Python/Nuitka Special Case

For Nuitka-style apps, a full runnable dump may not be necessary. Often the better path is:

- reach initialized Python runtime.
- inject small `PyRun_SimpleString` probes.
- inspect `sys.modules`, Qt widgets, compiled method names, runtime state.
- patch Python-level methods instead of PE bytes.
