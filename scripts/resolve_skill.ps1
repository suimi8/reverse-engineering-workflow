#Requires -Version 5.0
param(
    [Parameter(Mandatory=$true)]
    [string]$Query,

    [ValidateSet('all', 'root', 'github-reverse', 'local-reverse', 'security')]
    [string]$Category = 'all',

    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
}

function suimiNormalize {
    param([string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return ([string]$Value).Trim().ToLowerInvariant().Replace('\', '/')
}

function suimiNew-Result {
    param(
        [string]$Status,
        [string]$Message,
        [object[]]$Matches
    )

    $matchList = @($Matches)
    [pscustomobject][ordered]@{
        ok = ($Status -eq 'found')
        status = $Status
        query = $Query
        category = $Category
        count = $matchList.Count
        skill = if ($Status -eq 'found') { $matchList[0] } else { $null }
        matches = $matchList
        message = $Message
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$listScript = Join-Path $scriptDir 'list_skills.ps1'
if (-not (Test-Path -LiteralPath $listScript)) {
    throw "Skill registry script not found: $listScript"
}

$registryJson = & $listScript -Category $Category -AsJson
if ($LASTEXITCODE -ne 0) {
    throw 'Skill registry script returned a non-zero exit code.'
}

$registry = $registryJson | ConvertFrom-Json
$skills = @($registry.skills)
$needle = suimiNormalize -Value $Query

$exactMatches = @($skills | Where-Object {
    (suimiNormalize -Value $_.name) -eq $needle -or
    (suimiNormalize -Value $_.display_name) -eq $needle -or
    (suimiNormalize -Value $_.path) -eq $needle
})

if ($exactMatches.Count -eq 1) {
    $result = suimiNew-Result -Status 'found' -Message 'Resolved by exact name, display_name, or path.' -Matches $exactMatches
} elseif ($exactMatches.Count -gt 1) {
    $result = suimiNew-Result -Status 'ambiguous' -Message 'Exact query matched multiple skills.' -Matches $exactMatches
} else {
    $partialMatches = @($skills | Where-Object {
        (suimiNormalize -Value $_.name).Contains($needle) -or
        (suimiNormalize -Value $_.display_name).Contains($needle) -or
        (suimiNormalize -Value $_.path).Contains($needle) -or
        (suimiNormalize -Value $_.description).Contains($needle)
    })

    if ($partialMatches.Count -eq 1) {
        $result = suimiNew-Result -Status 'found' -Message 'Resolved by unique partial match.' -Matches $partialMatches
    } elseif ($partialMatches.Count -gt 1) {
        $result = suimiNew-Result -Status 'ambiguous' -Message 'Query matched multiple skills; use a machine name, exact Chinese display name, path, or narrower category.' -Matches $partialMatches
    } else {
        $result = suimiNew-Result -Status 'not-found' -Message 'No matching reusable skill found.' -Matches @()
    }
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 6
} else {
    Write-Host "Reusable reverse skill resolver"
    Write-Host " status   : $($result.status)"
    Write-Host " query    : $($result.query)"
    Write-Host " category : $($result.category)"
    Write-Host " count    : $($result.count)"
    Write-Host " message  : $($result.message)"
    foreach ($skill in @($result.matches)) {
        Write-Host (" - [{0}] {1} ({2}) -> {3}" -f $skill.category, $skill.display_name, $skill.name, $skill.path)
    }
}

if (-not $result.ok) {
    exit 1
}

exit 0
