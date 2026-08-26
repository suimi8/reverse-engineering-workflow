#Requires -Version 5.0
param(
    [string]$DestRoot = '',

    [string]$SkillName = 'reverse-engineering-workflow',

    [switch]$SkipHealthcheck,

    [switch]$DryRun,

    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
}

function suimiResolve-OrCreateDirectory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Directory path is empty.'
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function suimiAssert-ChildPath {
    param(
        [string]$Parent,
        [string]$Child
    )

    $normalizedParent = (Resolve-Path -LiteralPath $Parent).Path.TrimEnd('\', '/')
    $candidate = [System.IO.Path]::GetFullPath($Child)
    $expectedPrefix = $normalizedParent + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside destination root: $candidate"
    }
    return $candidate
}

function suimiGet-PackageShape {
    param([string]$RootDir)

    $skillFiles = @(Get-ChildItem -LiteralPath $RootDir -Filter 'SKILL.md' -File -Recurse)
    $moduleFiles = @(Get-ChildItem -LiteralPath $RootDir -Filter 'MODULE.md' -File -Recurse)
    return [pscustomobject][ordered]@{
        skill_md = $skillFiles.Count
        module_md = $moduleFiles.Count
    }
}

function suimiAssert-PackageShape {
    param(
        [string]$RootDir,
        [string]$Label
    )

    $shape = suimiGet-PackageShape -RootDir $RootDir
    if ($shape.skill_md -ne 1) {
        throw "$Label must contain exactly one SKILL.md; found $($shape.skill_md)."
    }
    if ($shape.module_md -lt 1) {
        throw "$Label must contain at least one internal MODULE.md; found $($shape.module_md)."
    }
    return $shape
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sourceRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..')).Path
if ([string]::IsNullOrWhiteSpace($DestRoot)) {
    $DestRoot = Join-Path $env:USERPROFILE '.codex\skills'
}

$resolvedDestRoot = suimiResolve-OrCreateDirectory -Path $DestRoot
$destinationPath = suimiAssert-ChildPath -Parent $resolvedDestRoot -Child (Join-Path $resolvedDestRoot $SkillName)
$sourceShape = suimiAssert-PackageShape -RootDir $sourceRoot -Label 'Source package'
$sourceEqualsDestination = $false
if (Test-Path -LiteralPath $destinationPath) {
    $resolvedDestination = (Resolve-Path -LiteralPath $destinationPath).Path
    $sourceEqualsDestination = $sourceRoot.Equals($resolvedDestination, [StringComparison]::OrdinalIgnoreCase)
}

$healthcheck = $null
if (-not $SkipHealthcheck -and -not $sourceEqualsDestination) {
    $healthcheckScript = Join-Path $sourceRoot 'scripts\healthcheck.ps1'
    if (-not (Test-Path -LiteralPath $healthcheckScript)) {
        throw "Healthcheck script not found: $healthcheckScript"
    }
    $healthcheckJson = & $healthcheckScript -AsJson
    if ($LASTEXITCODE -ne 0) {
        throw 'Source healthcheck returned a non-zero exit code.'
    }
    $healthcheck = $healthcheckJson | ConvertFrom-Json
    if (-not $healthcheck.ok) {
        throw "Source healthcheck failed: failed=$($healthcheck.failed), warnings=$($healthcheck.warnings)."
    }
}

if ($sourceEqualsDestination) {
    $result = [pscustomobject][ordered]@{
        ok = $true
        dry_run = [bool]$DryRun
        action = 'no-op'
        reason = 'Source package is already the installed package path.'
        source = $sourceRoot
        destination = $destinationPath
        installed_skill_md = $sourceShape.skill_md
        installed_module_md = $sourceShape.module_md
        healthcheck_ok = if ($healthcheck) { [bool]$healthcheck.ok } else { $null }
    }
    if ($AsJson) {
        $result | ConvertTo-Json -Depth 5
    } else {
        Write-Host 'Installed skill sync'
        Write-Host " action      : $($result.action)"
        Write-Host " reason      : $($result.reason)"
        Write-Host " destination : $($result.destination)"
    }
    exit 0
}

if ($DryRun) {
    $result = [pscustomobject][ordered]@{
        ok = $true
        dry_run = $true
        action = 'would-sync'
        source = $sourceRoot
        destination = $destinationPath
        source_skill_md = $sourceShape.skill_md
        source_module_md = $sourceShape.module_md
        healthcheck_ok = if ($healthcheck) { [bool]$healthcheck.ok } else { $null }
    }
    if ($AsJson) {
        $result | ConvertTo-Json -Depth 5
    } else {
        Write-Host 'Installed skill sync dry run'
        Write-Host " source      : $($result.source)"
        Write-Host " destination : $($result.destination)"
    }
    exit 0
}

$stageName = "$SkillName.__sync_tmp_$PID"
$stagePath = suimiAssert-ChildPath -Parent $resolvedDestRoot -Child (Join-Path $resolvedDestRoot $stageName)
if (Test-Path -LiteralPath $stagePath) {
    Remove-Item -LiteralPath $stagePath -Recurse -Force
}

try {
    Copy-Item -LiteralPath $sourceRoot -Destination $stagePath -Recurse -Force
    # Do not propagate VCS/build/install artifacts into the installed copy (keeps installs lean)
    foreach ($junk in @('.git', 'local-installed')) {
        $junkPath = Join-Path $stagePath $junk
        if (Test-Path -LiteralPath $junkPath) { Remove-Item -LiteralPath $junkPath -Recurse -Force }
    }
    Get-ChildItem -LiteralPath $stagePath -Recurse -File -Include *.zip, *.bak -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $stageShape = suimiAssert-PackageShape -RootDir $stagePath -Label 'Staged package'

    if (Test-Path -LiteralPath $destinationPath) {
        $resolvedDestination = (Resolve-Path -LiteralPath $destinationPath).Path
        if (-not $resolvedDestination.Equals($destinationPath, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unexpected destination: $resolvedDestination"
        }
        Remove-Item -LiteralPath $resolvedDestination -Recurse -Force
    }

    Move-Item -LiteralPath $stagePath -Destination $destinationPath
    $installedShape = suimiAssert-PackageShape -RootDir $destinationPath -Label 'Installed package'

    $result = [pscustomobject][ordered]@{
        ok = $true
        dry_run = $false
        action = 'synced'
        source = $sourceRoot
        destination = $destinationPath
        installed_skill_md = $installedShape.skill_md
        installed_module_md = $installedShape.module_md
        healthcheck_ok = if ($healthcheck) { [bool]$healthcheck.ok } else { $null }
        staged_skill_md = $stageShape.skill_md
        staged_module_md = $stageShape.module_md
    }
} finally {
    if (Test-Path -LiteralPath $stagePath) {
        Remove-Item -LiteralPath $stagePath -Recurse -Force
    }
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host 'Installed skill sync'
    Write-Host " action      : $($result.action)"
    Write-Host " source      : $($result.source)"
    Write-Host " destination : $($result.destination)"
    Write-Host " SKILL.md    : $($result.installed_skill_md)"
    Write-Host " MODULE.md   : $($result.installed_module_md)"
}

exit 0
