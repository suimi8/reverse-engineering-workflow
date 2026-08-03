# External Tool Official Downloads

Use this reference when setting up the reverse-engineering workflow environment. Prefer official vendor/project pages over third-party mirrors, cracked builds, repacks, or search-result download sites. Versioned direct download URLs change often; use the stable landing pages below unless a script needs a pinned version.

This is a coverage map, not a mandatory one-shot install list. Install the baseline runtime plus the tool family needed by the current task. The advanced and security sections cover optional branches referenced by bundled skills.

## Baseline Runtime

| Tool | Official download / install page | Notes |
|---|---|---|
| Python | https://www.python.org/downloads/ | Required by bundled Python scripts, Frida tooling, WPeGPT checks, and many optional security tools. |
| PowerShell | https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows | Required for the bundled `.ps1` scripts. Windows PowerShell 5 works for most scripts; PowerShell 7+ is preferred. |
| WSL | https://learn.microsoft.com/en-us/windows/wsl/install | Useful for Linux-first tools, Bash scripts, and Android/iOS/security workflows. |
| Git | https://git-scm.com/downloads | Useful for GitHub-hosted tools and plugin installs. |
| Eclipse Temurin JDK | https://adoptium.net/temurin/releases/ | Required by apktool, Android SDK tools, Ghidra, ZAP, and some Java decompilers. |
| Node.js | https://nodejs.org/en/download | Provides `node`, `npm`, and `npx` for JS reverse workflows, Playwright, and MCP helper packages. |
| Go | https://go.dev/doc/install | Needed for Go-based security/recon tools when using `go install`. |
| Docker Desktop | https://docs.docker.com/desktop/setup/install/windows-install/ | Useful for isolated malware/ransomware reproduction, labs, and tools that publish container images. |
| MSYS2 | https://www.msys2.org/ | Windows package environment for Unix-style CLI tools and QEMU packages. |

## Browser / JS / MCP Automation

| Tool | Official download / install page | Notes |
|---|---|---|
| pnpm | https://pnpm.io/installation | Used by `anything-analyzer` and some Node-based helper projects. |
| Playwright | https://playwright.dev/docs/intro | Browser automation and screenshots; install browser engines with `npx playwright install`. |
| agent-browser | https://github.com/nicepkg/agent-browser | Browser automation helper referenced by the imported reverse tool bootstrap. |
| jshookmcp | https://github.com/vmoranv/jshookmcp | JS hook MCP helper launched through `npx @jshookmcp/jshook@latest`. |
| anything-analyzer | https://github.com/Mouseww/anything-analyzer | Local HTTP MCP helper; uses Node/pnpm. |
| GhidraMCP | https://github.com/LaurieWired/GhidraMCP | Ghidra MCP extension referenced by the imported tool bootstrap. |
| Burp Suite MCP extension | https://github.com/PortSwigger/bambdas-mcp | Burp MCP integration option; Burp itself must be installed separately. |

## PE / ELF / Native Reverse Engineering

| Tool | Official download / install page | Notes |
|---|---|---|
| IDA / Hex-Rays | https://docs.hex-rays.com/getting-started/install-ida | Commercial/free IDA installers are obtained through Hex-Rays/My Hex-Rays flows. |
| WPeGPT | https://github.com/WPeace-HcH/WPeGPT | IDA AI analysis plugin expected by the WPeGPT workflow. Install `WPeGPT.py` and `WPeGPT_Config/` into the IDA plugins directory. |
| ida-pro-mcp | https://github.com/mrexodia/ida-pro-mcp | IDA MCP bridge used by the appended `ida-reverse` module. |
| Ghidra | https://github.com/NationalSecurityAgency/ghidra/releases | Official NSA GitHub releases. Requires a supported JDK. |
| radare2 | https://github.com/radareorg/radare2/releases | Provides `r2`, `rabin2`, `rasm2`, `radiff2`, `rahash2`, and related CLI tools. |
| x64dbg | https://x64dbg.com/ | Windows x86/x64 debugger. |
| Binary Ninja | https://binary.ninja/ | Commercial reverse-engineering suite. |
| GDB | https://sourceware.org/gdb/ | GNU debugger for ELF/native runtime analysis. |
| GNU Binutils | https://www.gnu.org/software/binutils/ | Provides `objdump`, `readelf`, `strings`, and related native binary utilities. |
| LLVM / LLDB | https://llvm.org/Download/ | Provides LLVM tools and LLDB debugger. |
| QEMU | https://www.qemu.org/download/ | User-mode and system emulation for ARM/MIPS/RISC-V/other targets. |
| UPX | https://upx.github.io/ | Common executable packer/unpacker. |
| binwalk | https://github.com/ReFirmLabs/binwalk | Firmware extraction and recursive analysis. |
| Rizin / Cutter | https://github.com/rizinorg/cutter/releases | GUI/CLI reverse suite related to the radare2 ecosystem. |
| RetDec | https://github.com/avast/retdec | Retargetable decompiler for optional native analysis paths. |
| GoReSym | https://github.com/mandiant/GoReSym | Go symbol recovery for stripped Go binaries. |
| rustfilt | https://github.com/luser/rustfilt | Rust symbol demangler. |
| Scylla | https://github.com/NtQuery/Scylla | Windows import reconstruction and dump fixing helper. |
| ScyllaHide | https://github.com/x64dbg/ScyllaHide | Anti-anti-debug plugin for x64dbg/IDA/OllyDbg workflows. |
| BinDiff | https://github.com/google/bindiff | Binary diffing suite. Works with BinExport inputs. |
| BinExport | https://github.com/google/binexport | IDA/Ghidra/Binary Ninja export plugin used by BinDiff-style workflows. |
| Diaphora | https://github.com/joxeankoret/diaphora | Open-source binary diffing plugin for IDA and Ghidra workflows. |
| D-810 | https://github.com/joydo/d810 | IDA deobfuscation plugin for MBA and opaque-predicate simplification. |
| GOOMBA | https://github.com/HexRaysSA/goomba | Hex-Rays plugin for MBA simplification. |

## APK / Android

| Tool | Official download / install page | Notes |
|---|---|---|
| Android SDK Platform-Tools | https://developer.android.com/studio/releases/platform-tools | Provides `adb` and `fastboot`. |
| Android SDK Command-line Tools | https://developer.android.com/studio#command-line-tools-only | Provides `sdkmanager`; use it to install platform/build tools without Android Studio. |
| Android SDK Build-Tools | https://developer.android.com/tools/releases/build-tools | Provides build utilities including `zipalign`; install with `sdkmanager "build-tools;<version>"`. |
| apksigner | https://developer.android.com/tools/apksigner | Android SDK Build-Tools signing/verification tool. Run `zipalign` before `apksigner`. |
| JADX | https://github.com/skylot/jadx/releases | Java/Kotlin/Dalvik decompiler for APK/Dex analysis. |
| apktool | https://apktool.org/docs/install | APK resource/smali decode and rebuild tool. Requires Java. |
| Frida | https://frida.re/docs/installation/ | Dynamic instrumentation toolkit. CLI tools are normally installed with `pip install frida-tools`. |
| Objection | https://github.com/sensepost/objection/wiki/Installation | Frida-based mobile runtime exploration toolkit. |
| smali / baksmali | https://github.com/JesusFreke/smali | Dalvik bytecode assembler/disassembler. |
| dex2jar | https://github.com/pxb1988/dex2jar | Converts DEX to JAR for Java decompiler workflows. |
| JD-GUI | https://github.com/java-decompiler/jd-gui/releases | Java bytecode decompiler GUI. |
| Androguard | https://github.com/androguard/androguard | Python Android reverse-engineering and analysis framework. |
| APKID | https://github.com/rednaga/APKiD | Android packer/compiler/obfuscator fingerprinting. |
| Blutter | https://github.com/worawit/blutter | Flutter APK/Dart symbol reconstruction helper for authorized analysis. |
| abc-decompiler | https://github.com/ohos-decompiler/abc-decompiler | HarmonyOS HAP/ABC analysis path referenced by the reverse methodology. |

## iOS / Mobile Optional

| Tool | Official download / install page | Notes |
|---|---|---|
| Apple Configurator | https://apps.apple.com/us/app/apple-configurator/id1037126344 | Apple utility useful for device/app management on macOS. |
| ipatool | https://github.com/majd/ipatool | CLI for downloading iOS apps from the App Store with an Apple account. |
| frida-ios-dump | https://github.com/AloneMonkey/frida-ios-dump | IPA dumping helper for authorized iOS testing. |
| class-dump | https://github.com/nygard/class-dump | Objective-C class interface dumper. |
| Hopper | https://www.hopperapp.com/ | Commercial disassembler/decompiler commonly used for Mach-O/iOS analysis. |
| jtool2 | http://newosxbook.com/tools/jtool.html | Mach-O analysis utility by NewOSXBook. |

## Python / .NET / Language-Specific Reverse

| Tool | Official download / install page | Notes |
|---|---|---|
| uncompyle6 | https://github.com/rocky/python-uncompyle6 | Python bytecode decompiler for older Python versions. |
| pycdc | https://github.com/zrax/pycdc | Python bytecode decompiler for newer bytecode paths. |
| pyinstxtractor | https://github.com/extremecoders-re/pyinstxtractor | PyInstaller archive extractor. |
| Pyarmor Static Unpack 1shot | https://github.com/Lil-House/Pyarmor-Static-Unpack-1shot | PyArmor static unpack helper referenced by the Python reverse notes. |
| dnSpyEx | https://github.com/dnSpyEx/dnSpy | .NET debugger/decompiler successor fork. |
| ILSpy | https://github.com/icsharpcode/ILSpy | .NET decompiler. |
| de4dot | https://github.com/de4dot/de4dot | .NET deobfuscator; useful for legacy obfuscators. |

## Emulation / Symbolic Execution / Binary Libraries

| Tool | Official download / install page | Notes |
|---|---|---|
| angr | https://angr.io/ | Python binary analysis and symbolic execution framework. |
| Unicorn | https://www.unicorn-engine.org/ | CPU emulation engine. |
| Qiling | https://qiling.io/ | OS-aware emulation framework built on Unicorn. |
| Triton | https://github.com/JonathanSalwan/Triton | Dynamic binary analysis and symbolic execution library. |
| Manticore | https://github.com/trailofbits/manticore | Symbolic execution tool. |
| Miasm | https://github.com/cea-sec/miasm | Reverse engineering framework with IR and symbolic execution support. |
| LIEF | https://github.com/lief-project/LIEF | Library for parsing and modifying executable formats. |
| pwntools | https://github.com/Gallopsled/pwntools | CTF/native automation helper; useful for quick patching and process IO. |
| r2pipe | https://github.com/radareorg/radare2-r2pipe | Python bindings for radare2 automation. |
| Capstone | https://www.capstone-engine.org/ | Disassembly framework used by several emulation/disassembly workflows. |

## Web / API Security Testing

| Tool | Official download / install page | Notes |
|---|---|---|
| Burp Suite | https://portswigger.net/burp/downloads | Community/Professional web proxy and testing suite. |
| mitmproxy | https://mitmproxy.org/downloads/ | Scriptable intercepting proxy. |
| Wireshark | https://www.wireshark.org/download.html | Network packet capture and analysis. |
| ZAP | https://www.zaproxy.org/download/ | Web proxy/scanner; recent Windows/Linux packages may require Java 17+. |
| Nmap | https://nmap.org/download.html | Network discovery and service/version scanning. |
| sqlmap | https://github.com/sqlmapproject/sqlmap/releases | SQL injection testing framework. |
| jwt_tool | https://github.com/ticarpi/jwt_tool | JWT testing, mutation, and cracking helper. |
| Turbo Intruder | https://github.com/PortSwigger/turbo-intruder | Burp extension for race condition and high-concurrency request testing. |
| ffuf | https://github.com/ffuf/ffuf | Web fuzzing and directory/vhost/parameter discovery. |
| feroxbuster | https://github.com/epi052/feroxbuster | Recursive content discovery. |
| gobuster | https://github.com/OJ/gobuster | Directory, DNS, and vhost brute forcing. |
| httpx | https://github.com/projectdiscovery/httpx | HTTP probing and technology detection. |
| subfinder | https://github.com/projectdiscovery/subfinder | Passive subdomain enumeration. |
| Amass | https://github.com/owasp-amass/amass | Attack surface mapping and subdomain enumeration. |
| massdns | https://github.com/blechschmidt/massdns | High-performance DNS resolver for brute-force enumeration. |
| masscan | https://github.com/robertdavidgraham/masscan | High-speed port scanner for large ranges. |
| nuclei | https://github.com/projectdiscovery/nuclei | Template-based vulnerability scanner. |
| SecLists | https://github.com/danielmiessler/SecLists | Wordlists for recon, fuzzing, and payload discovery. |
| trufflehog | https://github.com/trufflesecurity/trufflehog | Secret scanning in source repositories and artifacts. |
| gitleaks | https://github.com/gitleaks/gitleaks | Secret scanning in Git repositories. |
| gau | https://github.com/lc/gau | Historical URL collection. |
| waybackurls | https://github.com/tomnomnom/waybackurls | Wayback Machine URL collection. |
| LinkFinder | https://github.com/GerbenJavado/LinkFinder | JavaScript endpoint discovery. |
| arjun | https://github.com/s0md3v/Arjun | Hidden parameter discovery. |
| x8 | https://github.com/Sh1Yo/x8 | Hidden parameter discovery. |
| dalfox | https://github.com/hahwul/dalfox | XSS testing helper. |
| XSStrike | https://github.com/s0md3v/XSStrike | XSS testing helper. |
| SSRFmap | https://github.com/swisskyrepo/SSRFmap | SSRF exploitation helper for lab/authorized testing. |
| Gopherus | https://github.com/tarunkant/Gopherus | Gopher payload generator for SSRF labs and authorized testing. |
| interactsh | https://github.com/projectdiscovery/interactsh | Out-of-band interaction server/client. |
| Raceocat | https://github.com/JavanXD/Raceocat | Race-condition HTTP testing helper. |
| h2spacex | https://github.com/nxenon/h2spacex | HTTP/2 race/single-packet experimentation helper. |
| ProxyCat | https://github.com/honmashironeko/ProxyCat | Proxy helper referenced by the imported bootstrap manifest. |
| Pentest Swarm AI | https://github.com/Armur-Ai/Pentest-Swarm-AI | Optional MCP-enabled pentest orchestration helper; requires Go or Docker. |
| ExifTool | https://exiftool.org/ | Metadata editing/extraction; useful for upload/XSS test samples. |

## Python Packages Commonly Needed

Install from PyPI in a task-specific virtual environment when possible.

```powershell
python -m pip install --upgrade pip
python -m pip install pefile frida-tools objection androguard sqlmap wsrepl
python -m pip install angr unicorn qiling miasm lief pwntools r2pipe capstone
```

For WPeGPT, use the plugin repository's own `requirements.txt` after downloading or cloning the official repository.

For Go-based security tools, prefer the official repository's current `go install ...@latest` command. For Node-based tools, prefer `npm`, `npx`, `corepack`, or `pnpm` instructions from the official project page.
