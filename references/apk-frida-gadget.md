# APK / Frida Gadget Reverse Engineering Notes

Use for authorized APK analysis, mobile sandbox testing, ad/network component isolation, no-root Frida Gadget builds, and runtime hook-to-persistent-patch migration.

## Transferable Flow

1. Run the original APK first: record package/activity, launch path, homepage, target feature path, ad entry points, network errors, and crashes.
2. Capture runtime evidence before static patching: logcat, Frida logs, traffic, loaded classes, URLs, request/response shapes, and UI transitions.
3. Start with runtime hooks to preserve original signature: attach/spawn on rooted emulator or test device, then prove the narrow hook path.
4. Separate ad/control traffic from business traffic: block only proven ad SDK domains, ad endpoints, ad activities, and ad request builders; preserve account, config, content, risk-control, CDN, Gecko/resource, and feature APIs.
5. Hook by layer, not by guess: splash/opening ad, landing pages, immersive ads, banner/native flow, rewarded-video availability/request/reporting, and WebView ad landings are separate surfaces.
6. If target content breaks after patching, compare original+runtime-hook vs rebuilt APK. If only rebuilt APK fails, inspect signature, integrity checks, ABI placement, resource packaging, and manifest/application injection.
7. Keep every step reversible: original APK, unpacked tree, hook script, patched dex/classes, unsigned/aligned/signed APK, install logs, logcat, hashes.
8. Verify fresh: signature schemes -> ZIP entries -> install -> launch -> hook/Gadget loaded -> homepage -> target feature -> ads blocked -> no unrelated network breakage.

## Frida Modes

- Root/emulator: use external Frida server and attach/spawn to preserve original signature.
- No-root test APK: embed Frida Gadget, then rebuild and sign; expect app signature/integrity behavior to change.
- Magisk/LSPosed/Zygisk: useful when available, but treat as a different environment from stock no-root devices.

## Gadget Embedding Pattern

- Add `libfrida-gadget.so` under the needed ABI directories, usually `lib/arm64-v8a/` and any ABI used for testing.
- Add Gadget config and script files according to the chosen Gadget mode.
- Inject `System.loadLibrary("frida-gadget")` in the earliest stable Application or bootstrap class initializer.
- For script mode, combine the Frida Java bridge and the verified hook script only after the external hook path is proven.
- Rebuild, zipalign, sign, and verify v1/v2/v3/v4 as appropriate for the target Android version.

## Patch Strategy

- Prefer exact class/method hooks over deleting whole SDK trees.
- Prefer returning empty/disabled ad data at request or availability boundaries over corrupting shared networking.
- Avoid global URL blocking unless the domain/path is proven ad-only.
- Do not remove manifest components until runtime proves no app code expects their existence.
- For network rewrite hooks, preserve URL builders and clients used by normal feature traffic.

## Common Failure Signals

- Original works, external hook works, rebuilt APK fails: likely signature/integrity, manifest, dex, ABI, resource, or packager issue.
- Homepage works but target content is empty: likely overblocked content/config/risk/CDN traffic or removed shared UI/data component.
- Startup crash after static removal: likely missing class/resource/native lib referenced by reflection, manifest, service, receiver, or provider.
- Frida log says detached without crash: app may exit intentionally, restart into another process, or fail signature/environment checks.
- Emulator works but real device fails: check ABI, Android version, signature scheme, network security config, and device integrity checks.

## Packaging Notes

- apktool full rebuild is convenient but can be fragile with unusual paths, resources, packed assets, or build metadata.
- Zip-level injection can be safer: compile only patched dex/classes, then replace/append entries in the original APK before align/sign.
- Keep final artifact names versioned and record SHA256 plus the exact script used to build them.
