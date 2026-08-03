# APK Package Rename and Native Patch Workflow

Use this reference when the task is to rename a decompiled APK package, diagnose failures after package migration, or turn a proven native hook/patch into a reversible test build.

This page distills the local project notes from:

- `agent.md`: APK package rename execution checklist.
- `patch_libappJni_bypass.sh`: fixed-offset AArch64 native patch with `.bak` rollback.

## Required Inputs

- `source_package`: original package, for example `com.old.test`.
- `target_package`: target package, for example `com.new.test`.
- `project_dir`: apktool-decoded APK root.
- `build_mode`: `check_only` or `full_build`.
- Optional: whether `lib/*.so` exists, whether multidex exists, whether the target is only "install and launch" or full feature parity.

Derive all three package forms before touching files:

- dot form: `com.old.test` -> `com.new.test`
- slash form: `com/old/test` -> `com/new/test`
- descriptor form: `Lcom/old/test/...;` -> `Lcom/new/test/...;`

## Core Rule

Do not treat package rename as a single `AndroidManifest.xml` edit. Keep these surfaces synchronized:

- `AndroidManifest.xml`
- all `smali*` directories and class descriptors
- string constants and resource/config files
- `provider` authorities, schemes, permissions, processes, and task affinities
- third-party SDK package/signature bindings
- native literals and native integrity checks
- rebuild, align, sign, install, launch, and logcat verification

## Check-Only Flow

1. Inventory decoded tree:
   - `AndroidManifest.xml`
   - `smali/`, `smali_classes*/`
   - `res/`, `assets/`, `unknown/`
   - `lib/*/*.so`
   - root config files such as XML/JSON/TXT/properties/YAML.
2. Search all package forms before replacing:
   - old dot package
   - old slash path
   - old descriptor prefix
3. Classify each hit:
   - must-change: app classes, manifest components, provider authorities, app-owned config.
   - review: SDK config, whitelist entries, deep links, channel/package binding, integrity checks.
   - likely leave alone: comments, unrelated docs, vendor package names that only share a prefix.
4. Produce a hit report before any bulk replacement.

## Modification Flow

1. Back up the original APK, decoded tree, manifest, native libs, and any scripts.
2. Update `AndroidManifest.xml`:
   - `<manifest package="...">`
   - `android:name`
   - `android:authorities`
   - `android:permission`, `android:readPermission`, `android:writePermission`
   - `android:process`, `taskAffinity`
   - `scheme`, intent filter data.
3. Move app-owned smali package directories across every `smali*` root, not only `smali_classes2` and `smali_classes3`.
4. Replace smali internals:
   - `.class`, `.super`
   - field, method argument, and return descriptors
   - `invoke-*`, `new-instance`, annotations
   - `const-string` package literals.
5. Update resources and config:
   - provider authority strings
   - custom schemes and deep links
   - package_name/applicationId fields
   - H5/channel/push/analytics/ad SDK config where proven app-owned.
6. Re-scan all old package forms after each broad edit.

## High-Risk Manual Review

Prioritize these when install fails, launch exits, or a feature silently stops working:

- `provider` authorities and `FileProvider` paths.
- `Application`, launcher `Activity`, services, receivers, and content providers.
- relative manifest class names after `manifest package` changes.
- hardcoded `getPackageName()` comparisons or `equals("old.package")`.
- signature, installer, channel, and applicationId checks.
- SDKs bound to package/signature/appid/scheme: WeChat, payment SDKs, push, Firebase, Bugly, maps, ads, app links.
- native code using `FindClass`, `RegisterNatives`, package strings, anti-tamper, anti-repack checks.

## Native Audit

For `lib/*.so`, first search printable literals:

```bash
find lib -type f -name "*.so" -print0 | xargs -0 strings | rg "com\.old\.test|com/old/test"
```

A hit does not automatically mean patching is required, but it upgrades native analysis priority. If Java/smali changes look complete and the app still exits quickly, suspect native package or signature validation.

For proven fixed-offset native patches:

- patch only after disassembly or runtime evidence proves the branch/function/offset.
- verify file offset vs virtual address; do not mix them.
- preserve `.bak` before writing.
- print bytes before and after.
- record architecture, library path, offsets, old bytes, new bytes, and why the patch is valid.

Use `scripts/apk_aarch64_patch_template.sh` as the reversible shell template.

## Rebuild and Signing

Typical full-build sequence:

```bash
apktool b "$PROJECT_DIR" -o repacked-unsigned.apk
zipalign -p -f 4 repacked-unsigned.apk repacked-aligned.apk
apksigner sign --ks your.keystore --ks-key-alias your_alias --out repacked-signed.apk repacked-aligned.apk
apksigner verify -v --print-certs repacked-signed.apk
```

If rebuild fails, inspect in this order:

1. smali descriptor mismatch.
2. moved smali path mismatch.
3. malformed XML/resource replacement.
4. missed multidex class references.
5. native library or resource packaging differences.

If rebuilt APK installs but runtime hook version worked and rebuilt version fails, suspect signature/integrity checks, ABI placement, manifest injection, resource packaging, or environment differences before changing business logic.

## Minimal Acceptance Checklist

- Old dot package no longer appears in required app-owned locations.
- Old slash package and `Lold/slash/package` descriptors no longer appear in required app-owned locations.
- Manifest package, component names, providers, schemes, and permissions are consistent.
- Every `smali*` root was checked.
- Native strings were checked or explicitly marked absent.
- APK rebuilds, aligns, signs, and verifies.
- Fresh install launches and reaches the target screen.
- `adb logcat` was checked for `ClassNotFoundException`, provider conflicts, signature/integrity failures, and native aborts.

## Execution Summary Template

```markdown
### APK Package Rename Result

- Source package:
- Target package:
- Project dir:
- Build mode:
- Manifest updated:
- Smali paths updated:
- Smali references updated:
- Resources/config updated:
- Providers/schemes reviewed:
- SDK bindings reviewed:
- Native package residue:
- Native patches applied:
- Rebuild result:
- Signing result:
- Fresh install/launch result:

### Remaining Risks

- Risk 1:
- Risk 2:

### Next Actions

- Action 1:
- Action 2:
```
