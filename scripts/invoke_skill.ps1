#Requires -Version 5.0
param(
    [Parameter(Mandatory=$true)]
    [string]$TaskText,

    [string]$TargetPath = '',

    [ValidateSet('summary', 'path', 'content')]
    [string]$Output = 'summary',

    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
}

function suimiGet-RelativePath {
    param(
        [string]$RootDir,
        [string]$Path
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $RootDir).Path.TrimEnd('\', '/')
    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    if (-not $resolvedPath.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes root: $resolvedPath"
    }

    return $resolvedPath.Substring($resolvedRoot.Length).TrimStart('\', '/').Replace('\', '/')
}

function suimiResolve-RepoPath {
    param(
        [string]$RootDir,
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw 'Selected skill path is empty.'
    }
    if ($RelativePath -match '(^[A-Za-z]:\\)|(^\\\\)|(^/)') {
        throw "Selected skill path must be repository-relative: $RelativePath"
    }

    $fullPath = Join-Path $RootDir $RelativePath.Replace('/', '\')
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Selected skill file not found: $RelativePath"
    }

    $resolvedRoot = (Resolve-Path -LiteralPath $RootDir).Path.TrimEnd('\', '/')
    $resolvedPath = (Resolve-Path -LiteralPath $fullPath).Path
    if (-not $resolvedPath.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Selected skill path escapes root: $RelativePath"
    }

    return $resolvedPath
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..')).Path
$selectScript = Join-Path $scriptDir 'select_skill.ps1'

if (-not (Test-Path -LiteralPath $selectScript)) {
    throw "Skill selector script not found: $selectScript"
}

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $selectionJson = & $selectScript -TaskText $TaskText -AsJson
} else {
    $selectionJson = & $selectScript -TaskText $TaskText -TargetPath $TargetPath -AsJson
}

if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine('Skill selector returned a non-zero exit code.')
    exit 1
}

$selection = $selectionJson | ConvertFrom-Json
if (-not $selection.ok) {
    throw "Skill selector failed: $($selection.status) $($selection.reason)"
}

$skillRelativePath = [string]$selection.skill.path
$skillFullPath = suimiResolve-RepoPath -RootDir $rootDir -RelativePath $skillRelativePath
$skillContent = $null
if ($Output -eq 'content') {
    $skillContent = [System.IO.File]::ReadAllText($skillFullPath, [System.Text.Encoding]::UTF8)
}

$result = [pscustomobject][ordered]@{
    ok = $true
    status = 'ready'
    task_text = $TaskText
    target_path = $TargetPath
    output = $Output
    skill = $selection.skill
    skill_path = $skillRelativePath
    selection_source = $selection.source
    confidence = $selection.confidence
    reason = $selection.reason
    route_decision = $selection.route_decision
    candidates = $selection.candidates
    skill_content = $skillContent
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 10
    exit 0
}

switch ($Output) {
    'path' {
        Write-Output $skillRelativePath
    }
    'content' {
        Write-Output $skillContent
    }
    default {
        Write-Host 'Reusable reverse skill fixed entry'
        Write-Host " status     : $($result.status)"
        Write-Host " skill      : $($result.skill_path)"
        Write-Host " source     : $($result.selection_source)"
        Write-Host " confidence : $($result.confidence)"
        Write-Host " reason     : $($result.reason)"
        Write-Host ''
        Write-Host 'Load this internal MODULE.md next, or run with -Output content to print it directly.'
    }
}

exit 0
