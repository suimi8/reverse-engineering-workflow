#Requires -Version 5.0
<#
.SYNOPSIS
Classify a reverse-engineering target and select the first workflow route.

.EXAMPLES
The examples below are route-regression fixtures. Run them with -NoExecute -AsJson
and compare the key route fields when changing this script.

1. Current skill directory
   pwsh -File scripts/re_workflow_entry.ps1 -TargetPath . -Intent auto -TaskText "analyze project" -NoExecute -AsJson
   Expected: target_type=directory, target_profile=generic, route=directory-manual.

2. APK/mobile package
   pwsh -File scripts/re_workflow_entry.ps1 -TargetPath sample.apk -Intent auto -TaskText "analyze network endpoints" -NoExecute -AsJson
   Expected: target_type=apk, route=apk-manual.

3. PE/ELF exploratory analysis
   pwsh -File scripts/re_workflow_entry.ps1 -TargetPath sample.exe -Intent analyze -TaskText "what does this binary do" -NoExecute -AsJson
   Expected: route=wpegpt-ida when config/WPeGPT is ready; otherwise pe-summary for PE with pefile, or manual-triage.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,

    [ValidateSet('auto', 'analyze', 'understand', 'ioc', 'vuln', 'patch', 'runtime', 'gui', 'packaging')]
    [string]$Intent = 'auto',

    [string]$TaskText = '',

    [switch]$NoExecute,
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

function suimiGet-ResolvedPath {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Target path not found: $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function suimiGet-TargetType {
    param([string]$Path)

    $item = Get-Item -LiteralPath $Path
    if ($item.PSIsContainer) {
        return 'directory'
    }

    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    $bytes = [System.IO.File]::ReadAllBytes($Path)

    if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x4D -and $bytes[1] -eq 0x5A) {
        return 'pe'
    }
    if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x7F -and $bytes[1] -eq 0x45 -and $bytes[2] -eq 0x4C -and $bytes[3] -eq 0x46) {
        return 'elf'
    }
    if ($ext -eq '.apk') {
        return 'apk'
    }
    if ($ext -in @('.exe', '.dll', '.sys')) {
        return 'pe'
    }
    if ($ext -in @('.so', '.elf', '.bin')) {
        return 'elf'
    }
    if ($ext -in @('.smali', '.dex', '.jar', '.aar', '.xapk')) {
        return 'apkish'
    }

    return 'other'
}

function suimiGet-TaskTextLower {
    param([string]$PromptText)

    if ($null -eq $PromptText) {
        return ''
    }

    return ([string]$PromptText).ToLowerInvariant()
}

function suimiResolve-TargetProfile {
    param(
        [string]$Path,
        [string]$TargetType,
        [string]$PromptText
    )

    return 'generic'
}

function suimiResolve-Intent {
    param(
        [string]$RequestedIntent,
        [string]$PromptText
    )

    if ($RequestedIntent -ne 'auto') {
        return $RequestedIntent
    }

    $text = ''
    if ($null -ne $PromptText) {
        $text = [string]$PromptText
    }
    $text = $text.ToLowerInvariant()

    if ($text -match 'vuln|漏洞|审计|audit|exp|exploit|security|安全') {
        return 'vuln'
    }
    if ($text -match 'patch|补丁|rva|offset|hook|frida|byte patch|字节') {
        return 'patch'
    }
    if ($text -match 'freeze|crash|startup|runtime|运行时|崩溃|卡死|弹窗|dialog|window|gui|登录') {
        return 'runtime'
    }
    if ($text -match 'package|packaging|打包|分发|发布') {
        return 'packaging'
    }
    if ($text -match 'ioc|域名|ip|url|network|可疑函数|purpose|用途|分析|analyze|understand|what does') {
        return 'analyze'
    }

    return 'analyze'
}

function suimiResolve-WPeMode {
    param(
        [string]$EffectiveIntent,
        [string]$PromptText
    )

    if ($EffectiveIntent -eq 'vuln') {
        return 'vuln'
    }

    $text = ''
    if ($null -ne $PromptText) {
        $text = [string]$PromptText
    }
    $text = $text.ToLowerInvariant()
    if ($text -match 'full|deep|全面|深入|详细|全部') {
        return 'full'
    }

    return 'light'
}

function suimiResolve-DirectoryModuleHint {
    param(
        [string]$Path,
        [string]$EffectiveIntent,
        [string]$PromptText
    )

    $text = suimiGet-TaskTextLower -PromptText $PromptText
    $item = Get-Item -LiteralPath $Path
    if (-not $item.PSIsContainer) {
        return $null
    }

    $hasApkSignals =
        (Get-ChildItem -LiteralPath $Path -Filter 'AndroidManifest.xml' -File -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        (Get-ChildItem -LiteralPath $Path -Filter '*.apk' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        (Get-ChildItem -LiteralPath $Path -Filter '*.ipa' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        (Test-Path -LiteralPath (Join-Path $Path 'smali'))

    if ($hasApkSignals -or $text -match 'android|ios|apk|ipa|mobile|frida|objection|ssl pinning|root detection|jailbreak|移动端|安卓|越狱') {
        return [pscustomobject]@{
            route = 'mobile-reverse-manual'
            module_entry = 'github-reverse-modules/skills/mobile-reverse/MODULE.md'
            next_action = 'Load the mobile reverse module for Android/iOS triage, Frida/Objection, pinning bypass analysis, and mobile API/auth/crypto extraction.'
            reason = 'Directory or task text matches mobile reverse indicators.'
        }
    }

    $hasDiffSignals =
        (Get-ChildItem -LiteralPath $Path -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '(old|new|before|after|v\d+|patched|original)' } |
            Select-Object -First 1)

    if ($hasDiffSignals -and ($text -match 'diff|版本|对比|patch diff|symbol|符号|迁移|变化')) {
        return [pscustomobject]@{
            route = 'binary-diff-manual'
            module_entry = 'github-reverse-modules/skills/binary-diff/MODULE.md'
            next_action = 'Load the binary diff module for version comparison, symbol migration, and patch delta analysis.'
            reason = 'Directory and task text match binary diff indicators.'
        }
    }

    $hasWindowsPythonSignals =
        (Get-ChildItem -LiteralPath $Path -Filter 'python*.dll' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        (Get-ChildItem -LiteralPath $Path -Filter '*.pyd' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        (Get-ChildItem -LiteralPath $Path -Filter 'base_library.zip' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        (Get-ChildItem -LiteralPath $Path -Filter 'flet.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        (Get-ChildItem -LiteralPath $Path -Filter 'app.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        (Get-ChildItem -LiteralPath $Path -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @('_internal', 'runtime', 'resources') } | Select-Object -First 1)

    $hasFletSignals =
        (Get-ChildItem -LiteralPath $Path -Filter 'flet.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        ($text -match 'flet|flet\.exe')

    if ($hasFletSignals -and ($text -match 'flet desktop|blank window|hidden window|mainwindow|ui process|window|gui|窗口|空白窗口|隐藏窗口|桌面诊断')) {
        return [pscustomobject]@{
            route = 'flet-desktop-diagnostics-manual'
            module_entry = 'local-reverse-modules/skills/flet-desktop-diagnostics/MODULE.md'
            next_action = 'Load the Flet desktop diagnostics module for app.exe/flet.exe process pairing, visible window ownership, AppData state, localhost dependency checks, and functional UI verification.'
            reason = 'Directory and task text match Flet desktop diagnostics indicators.'
        }
    }

    if ($text -match 'startup repair|startup folder|scheduled task|schtasks|local helper service|localhost helper|loopback service|127\.0\.0\.1|port no-op|cold.?start|non-ascii path|\.cmd|自启动修复|启动项|计划任务|本地服务|端口|冷启动') {
        return [pscustomobject]@{
            route = 'windows-local-service-persistence-manual'
            module_entry = 'local-reverse-modules/skills/windows-local-service-persistence/MODULE.md'
            next_action = 'Load the Windows local service persistence module for loopback helper startup, Startup-folder/PowerShell launcher repair, duplicate guards, and cold-start validation.'
            reason = 'Task text matches Windows local helper persistence indicators.'
        }
    }

    if ($hasWindowsPythonSignals -and ($text -match 'lost.?source|source code lost|windows python|python desktop|flet|nuitka|pyinstaller|cx.?freeze|cannot enter feature ui|functional ui|localappdata|appdata|localhost helper|local license service|源码丢失|进不去功能界面|本地授权服务|自启动修复')) {
        return [pscustomobject]@{
            route = 'windows-python-app-recovery-manual'
            module_entry = 'local-reverse-modules/skills/windows-python-app-recovery/MODULE.md'
            next_action = 'Load the Windows Python app recovery module for packaged Python desktop triage, AppData state repair, localhost helper restoration, Startup persistence, and cold-start validation.'
            reason = 'Directory and task text match Windows Python packaged app recovery indicators.'
        }
    }

    if ($text -match 'radare2|r2|rizin|命令行逆向') {
        return [pscustomobject]@{
            route = 'radare2-manual'
            module_entry = 'github-reverse-modules/skills/radare2/MODULE.md'
            next_action = 'Load the radare2 module for CLI-first static recon and patch-oriented analysis.'
            reason = 'Task text explicitly requests radare2/r2-style analysis.'
        }
    }

    return $null
}

function suimiResolve-Python {
    $pythonExe = Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
    if ($pythonExe) {
        return $pythonExe
    }

    return $null
}

function suimiTest-PeSummaryReady {
    param([string]$PythonExe)

    if (-not $PythonExe) {
        return $false
    }

    & $PythonExe -c "import pefile" *> $null
    return ($LASTEXITCODE -eq 0)
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$envCheckScript = Join-Path $scriptDir 'check_wpegpt_env.ps1'
$wpegptScript = Join-Path $scriptDir 'wpegpt_analyze.ps1'
$peSummaryScript = Join-Path $scriptDir 'pe_section_summary.py'

$resolvedTarget = suimiGet-ResolvedPath -Path $TargetPath
$targetType = suimiGet-TargetType -Path $resolvedTarget
$targetProfile = suimiResolve-TargetProfile -Path $resolvedTarget -TargetType $targetType -PromptText $TaskText
$effectiveIntent = suimiResolve-Intent -RequestedIntent $Intent -PromptText $TaskText
$wpeMode = suimiResolve-WPeMode -EffectiveIntent $effectiveIntent -PromptText $TaskText

$envJson = & $envCheckScript -AsJson -NoExitCode
$envInfo = $envJson | ConvertFrom-Json
$envReady = [bool]$envInfo.ready

$pythonExe = suimiResolve-Python
$peSummaryReady = $false
if ($targetType -eq 'pe') {
    $peSummaryReady = suimiTest-PeSummaryReady -PythonExe $pythonExe
}

$route = 'manual'
$reason = 'No matching automated route.'
$moduleEntry = $null
$nextAction = $null

if ($targetType -in @('pe', 'elf') -and $effectiveIntent -in @('analyze', 'understand', 'ioc', 'vuln')) {
    if ($envReady) {
        $route = 'wpegpt-ida'
        $moduleEntry = 'references/wpegpt-ida-analysis.md'
        $nextAction = 'Use WPeGPT/IDA automation for exploratory binary analysis; load the WPeGPT reference for report workflow and fallback handling.'
        $reason = 'Exploratory PE/ELF analysis with ready IDA/WPeGPT environment.'
    } elseif ($targetType -eq 'pe' -and $peSummaryReady) {
        $route = 'pe-summary'
        $moduleEntry = 'references/static-analysis.md'
        $nextAction = 'Run the lightweight PE summary first; load static-analysis.md only if imports/strings/sections do not answer the question.'
        $reason = 'PE target, WPeGPT environment not ready, lightweight summary available.'
    } else {
        $route = 'manual-triage'
        $moduleEntry = 'github-reverse-modules/skills/reverse-engineering/MODULE.md'
        $nextAction = 'Load the general reverse-engineering module for manual PE/ELF triage when automated IDA and PE summary routes are unavailable.'
        $reason = 'Exploratory binary analysis requested, but IDA/WPeGPT environment is not ready.'
    }
} elseif ($targetType -eq 'pe' -and $effectiveIntent -in @('patch', 'runtime', 'gui', 'packaging')) {
    if ($peSummaryReady) {
        $route = 'pe-summary'
        $moduleEntry = 'references/static-analysis.md'
        $nextAction = 'Start with lightweight PE import/section triage, then load windows-runtime, pe-patching, or patching-packaging as the observed behavior requires.'
        $reason = 'Narrow PE task; start with lightweight import/section triage.'
    } else {
        $route = 'manual-triage'
        $moduleEntry = 'references/reverse-task-recipes.md'
        $nextAction = 'Load the task recipes and choose the PE runtime, GUI, patch, or packaging recipe.'
        $reason = 'Narrow PE task, but Python pefile support is unavailable.'
    }
} elseif ($targetType -in @('apk', 'apkish')) {
    $route = 'apk-manual'
    $moduleEntry = 'github-reverse-modules/skills/apk-reverse/MODULE.md'
    $nextAction = 'Load the APK reverse module for decode, manifest summary, Frida, rebuild, sign, and install workflow; use mobile-reverse for broader Android/iOS methodology.'
    $reason = 'APK/mobile target; prefer jadx/apktool/Frida path before IDA.'
} elseif ($targetType -eq 'directory') {
    $directoryHint = suimiResolve-DirectoryModuleHint -Path $resolvedTarget -EffectiveIntent $effectiveIntent -PromptText $TaskText
    if ($directoryHint) {
        $route = $directoryHint.route
        $moduleEntry = $directoryHint.module_entry
        $nextAction = $directoryHint.next_action
        $reason = $directoryHint.reason
    } else {
        $route = 'directory-manual'
        $moduleEntry = 'references/reverse-task-recipes.md'
        $nextAction = 'Load the task recipes, inventory the directory, capture one baseline run, then choose APK, PE, runtime, network, or packaging workflow.'
        $reason = 'Directory target requires manual inventory and workflow selection.'
    }
}

$decision = [ordered]@{
    target_path = $resolvedTarget
    target_type = $targetType
    target_profile = $targetProfile
    requested_intent = $Intent
    effective_intent = $effectiveIntent
    wpegpt_mode = $wpeMode
    route = $route
    reason = $reason
    module_entry = $moduleEntry
    next_action = $nextAction
    no_execute = [bool]$NoExecute
    wpegpt_ready = [bool]$envReady
    pe_summary_ready = [bool]$peSummaryReady
}

if ($AsJson) {
    $decision | ConvertTo-Json -Depth 4
} else {
    Write-Host "Reverse engineering workflow entry"
    Write-Host " target      : $($decision.target_path)"
    Write-Host " type        : $($decision.target_type)"
    Write-Host " profile     : $($decision.target_profile)"
    Write-Host " intent      : $($decision.effective_intent)"
    Write-Host " route       : $($decision.route)"
    Write-Host " reason      : $($decision.reason)"
    if ($decision.module_entry) {
        Write-Host " module      : $($decision.module_entry)"
    }
    if ($decision.next_action) {
        Write-Host " next        : $($decision.next_action)"
    }
    Write-Host " wpegpt mode : $($decision.wpegpt_mode)"
}

if ($NoExecute) {
    exit 0
}

switch ($route) {
    'wpegpt-ida' {
        & $wpegptScript -BinaryPath $resolvedTarget -Mode $wpeMode
        exit $LASTEXITCODE
    }
    'pe-summary' {
        & $pythonExe $peSummaryScript $resolvedTarget
        exit $LASTEXITCODE
    }
    'apk-manual' {
        Write-Host ""
        Write-Host "[INFO] Target is APK/mobile-oriented. Load github-reverse-modules/skills/apk-reverse/MODULE.md first."
        Write-Host "[INFO] Load references/apk-frida-gadget.md, references/apk-package-rename.md, or github-reverse-modules/skills/mobile-reverse/MODULE.md as needed."
        exit 0
    }
    'mobile-reverse-manual' {
        Write-Host ""
        Write-Host "[INFO] Load github-reverse-modules/skills/mobile-reverse/MODULE.md."
        exit 0
    }
    'binary-diff-manual' {
        Write-Host ""
        Write-Host "[INFO] Load github-reverse-modules/skills/binary-diff/MODULE.md."
        exit 0
    }
    'radare2-manual' {
        Write-Host ""
        Write-Host "[INFO] Load github-reverse-modules/skills/radare2/MODULE.md."
        exit 0
    }
    'directory-manual' {
        Write-Host ""
        Write-Host "[INFO] Target is a directory. Start with inventory, then choose APK/PE/runtime path manually."
        exit 0
    }
    default {
        Write-Host ""
        Write-Host "[INFO] No automated route executed."
        if (-not $envReady -and $envInfo.issues) {
            Write-Host "[INFO] WPeGPT environment issues:"
            $envInfo.issues | ForEach-Object { Write-Host " - $_" }
        }
        exit 0
    }
}
