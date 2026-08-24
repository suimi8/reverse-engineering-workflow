# Anti-Analysis

## Detection Surface

Look for:

- debugger checks: `IsDebuggerPresent`, `CheckRemoteDebuggerPresent`, `NtQueryInformationProcess`.
- timing checks: `QueryPerformanceCounter`, `GetTickCount`, `Sleep` anomalies.
- thread hiding: `NtSetInformationThread(ThreadHideFromDebugger)`.
- process/window checks: debugger process names, class names, loaded modules.
- VM checks: registry, device names, MAC prefixes, CPUID.
- integrity checks: hashes of code sections, import table, config files.

## Handling Order

1. Observe the exact failing branch or exit point.
2. Patch or hook only that check.
3. Preserve normal return shape and side effects.
4. Verify with and without debugger where possible.

## Safer Bypasses

- Return "not debugged" from APIs rather than NOP-ing large blocks.
- Normalize timing deltas instead of disabling timers globally.
- Disable only the specific exit/dialog path blocking analysis.
- Prefer debugger configuration first: hide debugger plugin, break on TLS, ignore noisy exceptions.

## Integrity Checks

If byte patches trigger integrity failures:

- patch after integrity check at runtime.
- patch the expected hash only if fully understood.
- move to method-level/runtime hooks when available.
