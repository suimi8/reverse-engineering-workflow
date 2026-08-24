# Patching And Packaging Notes

## Patch Strategy

- Prefer runtime monkey patches/probes for diagnosis.
- Make persistent binary patches only after the exact byte/function/path is proven.
- Keep patches scoped to exact modules/classes/methods. Avoid broad `sys.modules` sweeps and keyword-only dialog blockers.
- Make every patch idempotent and logged.
- Keep originals available for call-through and rollback.

## Auth / Update / Service Flow Analysis

For owned or sandbox software:
- Map validation/update calls by runtime traffic and response payloads first.
- Record endpoint, method, status, JSON shape, caller method, and UI effect.
- Prefer local test stubs/proxy responses for reproduction.
- Patch structured payload fields, not random strings:
  - update flags: `need_update`, `force_update`, `must_update`, `disabled`
  - version fields: `current_version`, `latest_version`, `min_version`
  - entitlement fields: `success`, `ok`, `expire_time`, `session_id`
- Treat webhooks/payment/license provider data as high-impact; use sandbox/test data.

## Distribution Package

Minimal package contents:
- launcher script
- runtime patch/probe scripts actually used
- local service/proxy if required
- close/cleanup script
- short usage file
- checksum or file list

Avoid shipping:
- raw credentials, tokens, unrelated logs, screenshots with private data
- exploratory dumps not needed for the final path
- duplicate old drafts

## Verification Checklist

- Fresh launch from package.
- Main UI visible and title/state expected.
- Target feature path runs or fails with clear actionable prompt.
- Update/stop dialogs do not block the verified path.
- Close script terminates target and helper processes.
- Package unpacks to the intended directory layout.
