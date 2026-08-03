#Requires -Version 5.0
param(
    [ValidateSet('none', 'patch', 'minor')]
    [string]$BumpVersion = 'none',

    [string]$ReleaseNotes = '',

    [string]$ZipName = 'reverse-engineering-workflow.zip',

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

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $scriptDir 'lib\Release.ps1')

$rootDir = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..')).Path
$manifestPath = Join-Path $rootDir 'manifest.json'
$changelogPath = Join-Path $rootDir 'CHANGELOG.md'
$zipPath = Join-Path $rootDir $ZipName

if (-not $SkipHealthcheck) {
    $healthcheckScript = Join-Path $scriptDir 'healthcheck.ps1'
    & $healthcheckScript | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Healthcheck failed; refusing to package the release.'
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$oldVersion = [string]$manifest.version
$newVersion = $oldVersion
$versionAction = 'no-bump'

if ($BumpVersion -ne 'none') {
    $newVersion = suimiBump-Version -Version $oldVersion -Bump $BumpVersion
    $versionAction = "$oldVersion->$newVersion"

    if (-not $DryRun) {
        $backupPath = "$manifestPath.bak"
        Copy-Item -LiteralPath $manifestPath -Destination $backupPath -Force
        $manifest.version = $newVersion
        $manifestJson = $manifest | ConvertTo-Json -Depth 8
        [System.IO.File]::WriteAllText($manifestPath, $manifestJson, [System.Text.UTF8Encoding]::new($false))
    }
}

$changelogAction = 'no-notes'
if (-not [string]::IsNullOrWhiteSpace($ReleaseNotes)) {
    $changelogAction = "append [$newVersion]"
    if (-not $DryRun -and (Test-Path -LiteralPath $changelogPath)) {
        $date = Get-Date -Format 'yyyy-MM-dd'
        $text = [System.IO.File]::ReadAllText($changelogPath, [System.Text.Encoding]::UTF8)
        $lines = @($text -split "`r?`n")
        $insertAt = $lines.Count
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^##\s') {
                $insertAt = $i
                break
            }
        }
        $entry = @("## [$newVersion] - $date", '') + @($ReleaseNotes -split "`r?`n")
        $newLines = @($lines[0..([Math]::Max(0, $insertAt - 1))]) + @('') + $entry + @('') + @($lines[$insertAt..($lines.Count - 1)])
        [System.IO.File]::WriteAllText($changelogPath, ($newLines -join "`r`n"), [System.Text.UTF8Encoding]::new($false))
    }
}

$zipResult = $null
if ($DryRun) {
    $dryFiles = @(suimiCollect-PackageFiles -RootDir $rootDir -ExcludeNames @($ZipName))
    $result = [ordered]@{
        ok             = $true
        dry_run        = $true
        version_action = $versionAction
        old_version    = $oldVersion
        version        = $newVersion
        changelog      = $changelogAction
        zip_path       = $ZipName
        file_count     = $dryFiles.Count
        healthcheck    = if ($SkipHealthcheck) { 'skipped' } else { 'passed' }
    }
} else {
    $zipResult = suimiNew-ReleaseZip -RootDir $rootDir -ZipPath $zipPath -ExcludeNames @($ZipName)
    $result = [ordered]@{
        ok             = $true
        dry_run        = $false
        version_action = $versionAction
        old_version    = $oldVersion
        version        = $newVersion
        changelog      = $changelogAction
        zip_path       = $ZipName
        file_count     = $zipResult.file_count
        bytes          = $zipResult.bytes
        sha256         = $zipResult.sha256
        healthcheck    = if ($SkipHealthcheck) { 'skipped' } else { 'passed' }
    }
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host "Release packaging result"
    Write-Host " version     : $($result.version) ($($result.version_action))"
    Write-Host " changelog   : $($result.changelog)"
    Write-Host " zip         : $($result.zip_path) ($($result.file_count) files)"
    if (-not $DryRun) {
        Write-Host " bytes       : $($result.bytes)"
        Write-Host " sha256      : $($result.sha256)"
    }
    Write-Host " healthcheck : $($result.healthcheck)"
}

exit 0
