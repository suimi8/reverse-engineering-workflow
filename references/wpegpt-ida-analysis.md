# WPeGPT IDA Analysis

Use this reference when the user asks for automated AI-assisted analysis of an authorized PE or ELF binary, wants a quick program-purpose report, asks for network IoCs or suspicious functions, or requests vulnerability-focused binary analysis through IDA and WPeGPT.

## Scope

- Supported targets: PE and ELF executables or libraries such as `.exe`, `.dll`, `.so`, and `.elf`.
- Do not use for ordinary text/static file review or non-binary source analysis.
- Require a local IDA install with the WPeGPT plugin available under the IDA `plugins` directory.
- Treat WPeGPT output as analysis evidence, not ground truth; cross-check important claims against strings, imports, xrefs, runtime behavior, or traffic.

## When To Launch IDA

Launch IDA automatically when the current request is exploratory binary analysis rather than a narrow known patch:

- The user asks what the program does, wants a full or quick binary report, asks for network IoCs, suspicious functions, or vulnerability-oriented binary review.
- The target is a PE or ELF file and there is no already-available source tree or prior decompilation that answers the question faster.
- A baseline execution pass does not already resolve the task.

Do not launch IDA yet when:

- The task is mainly config repair, runtime liveness, crash/freeze diagnosis, request replay, or packaging.
- The target is better handled first with APK tooling, Frida, logs, strings/imports, or a small patch template.
- The exact hook point or byte patch is already known and static whole-program analysis is unnecessary.

If unsure, do one cheap pass first: classify the file, inspect imports/strings/sections, then launch IDA if the question is still about whole-binary understanding or report generation.

## Modes

| Mode | Use For | Expected Time |
| --- | --- | --- |
| `light` | Default quick analysis: purpose, behavior, network addresses, suspicious functions | 2-5 minutes |
| `full` | Deep or comprehensive analysis of key paths and many/all functions | 10-30 minutes |
| `vuln` | Vulnerability/security review, exploitability hints, risky functions | 5-20 minutes |

Select the mode from the user's wording. Use `light` for generic "analyze this binary" requests, `full` for deep/detailed/comprehensive requests, and `vuln` for vulnerability, security audit, exploit, or bug-hunting requests.

## Required Layout

The skill folder provides:

```text
config/config.ini.example
scripts/check_wpegpt_env.ps1
scripts/re_workflow_entry.ps1
scripts/wpegpt_analyze.ps1
scripts/wpegpt_analyze.bat
```

The runtime config file must be:

```ini
[paths]
ida_dir=auto
python_path=auto
```

Use `auto` by default. The scripts resolve IDA from `IDA_DIR`/`IDA_PATH`, `PATH`, registry entries, or drive-root discovery, and resolve Python from `PATH`. Set explicit local paths only for a private machine-specific override that should not be redistributed.

The IDA installation must contain:

```text
<ida_dir>/plugins/WPeGPT.py
<ida_dir>/plugins/WPeGPT_Config/config.py
<ida_dir>/plugins/WPeGPT_Config/wpe_ai_controller.py
```

WPeGPT model and API credentials live in `<ida_dir>/plugins/WPeGPT_Config/config.py`; do not copy secrets into logs, reports, or packaged artifacts.

## Setup Check

1. Confirm the target binary path exists.
2. Check whether `config/config.ini` exists next to the script resources.
3. If missing, copy `config/config.ini.example` to `config/config.ini` and keep `auto` unless the machine requires a private override.
4. Verify `ida.exe`, `WPeGPT.py`, `config.py`, and `wpe_ai_controller.py` exist.
5. Verify Python is available from `python_path` or `PATH`.

Stop and report exact missing paths if any dependency is absent.

Prefer the bundled self-check before launching IDA:

```powershell
powershell -NoProfile -File ".\scripts\check_wpegpt_env.ps1"
```

## Run

Prefer the unified entry script when the workflow still needs to decide whether IDA should be launched:

```powershell
powershell -NoProfile -File ".\scripts\re_workflow_entry.ps1" -TargetPath "<target_path>" -TaskText "<user request>"
```

It will classify the target, infer intent, check WPeGPT readiness, and then route to WPeGPT/IDA, lightweight PE summary, or APK/manual flow.

Prefer PowerShell:

```powershell
powershell -NoProfile -File ".\scripts\wpegpt_analyze.ps1" -BinaryPath "<binary_path>" -Mode "<light|full|vuln>"
```

Avoid invoking the batch file from agent shells because output can be truncated. Keep `wpegpt_analyze.bat` as a local terminal fallback only.

The PowerShell script:

1. Parses `config/config.ini`.
2. Detects PE/ELF architecture and chooses `ida.exe` or `ida64.exe`.
3. Cleans old `%TEMP%\.wpe_server_port_*` files.
4. Starts IDA in analysis mode with `-A`.
5. Waits for the WPeServer port file created by WPeGPT.
6. Runs `wpe_ai_controller.py --mode <mode>`.
7. Prints the report directory and expected JSON/Markdown paths.

## Output Handling

Reports are written next to the binary:

```text
<binary_dir>/<binary_name>_WPeAI_Results/
```

Read the generated Markdown report first, then the JSON if precise fields are needed. Summarize:

- Program purpose and likely category.
- Network IoCs: IPs, domains, URLs, ports, and protocols.
- Suspicious functions and why they matter.
- In `vuln` mode: vulnerability class, risk level, affected functions, and practical exploitability caveats.
- Full report paths for `.md` and `.json`.

If the controller fails or times out, collect the script output, confirm IDA is still running, check the IDA output window when possible, and verify the WPeGPT plugin installation before changing scripts or config.
