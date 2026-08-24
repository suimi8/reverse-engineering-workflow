#Requires -Version 5.0
param(
    [switch]$CheckOnly,
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

function suimiGet-DisplayNamePrefix {
    return ([string]([char]0x4E2D) + [string]([char]0x6587) + [string]([char]0x540D) + [string]([char]0xFF1A))
}

function suimiGet-ChineseSkillNameMap {
    param([string]$RootDir)

    $mapPath = Join-Path $RootDir 'references\chinese-skill-names.json'
    if (-not (Test-Path -LiteralPath $mapPath)) {
        throw "Chinese skill name map not found: $mapPath"
    }

    $json = [System.IO.File]::ReadAllText($mapPath, [System.Text.Encoding]::UTF8)
    $items = $json | ConvertFrom-Json
    $map = [ordered]@{}
    foreach ($item in $items) {
        $map[[string]$item.path] = [string]$item.display_name
    }

    return $map
}

function suimiSet-ChineseSkillName {
    param(
        [string]$Path,
        [string]$ChineseName,
        [switch]$CheckOnly
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject][ordered]@{
            path = $Path
            status = 'missing'
            changed = $false
            expected = $ChineseName
        }
    }

    $prefix = suimiGet-DisplayNamePrefix
    $linePattern = '(?m)^' + [regex]::Escape($prefix) + '[^\r\n]+'
    $expectedLine = $prefix + $ChineseName
    $text = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path, [System.Text.Encoding]::UTF8)
    $changed = $false
    $status = 'ok'

    if ([regex]::IsMatch($text, $linePattern)) {
        $currentLine = [regex]::Match($text, $linePattern).Value
        if ($currentLine -ne $expectedLine) {
            $text = [regex]::Replace($text, $linePattern, $expectedLine, 1)
            $changed = $true
            $status = 'updated'
        }
    } elseif ($text -match '(?s)^(---\s*\r?\n.*?\r?\n---\s*\r?\n)') {
        $frontmatter = $Matches[1]
        $rest = $text.Substring($frontmatter.Length)
        $text = $frontmatter + "`r`n" + $expectedLine + "`r`n`r`n" + $rest
        $changed = $true
        $status = 'inserted'
    } else {
        $text = $expectedLine + "`r`n`r`n" + $text
        $changed = $true
        $status = 'inserted'
    }

    if ($changed -and -not $CheckOnly) {
        [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $Path).Path, $text, [System.Text.UTF8Encoding]::new($false))
    }

    if ($changed -and $CheckOnly) {
        $status = 'would-change'
    }

    return [pscustomobject][ordered]@{
        path = $Path
        status = $status
        changed = $changed
        expected = $ChineseName
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..')).Path
$map = suimiGet-ChineseSkillNameMap -RootDir $rootDir
$results = @()

Push-Location $rootDir
try {
    foreach ($entry in $map.GetEnumerator()) {
        $results += suimiSet-ChineseSkillName -Path $entry.Key -ChineseName $entry.Value -CheckOnly:$CheckOnly
    }
} finally {
    Pop-Location
}

$missing = @($results | Where-Object { $_.status -eq 'missing' })
$pending = @($results | Where-Object { $_.status -eq 'would-change' })
$changed = @($results | Where-Object { $_.changed -and $_.status -ne 'would-change' })
$summary = [ordered]@{
    ok = ($missing.Count -eq 0 -and $pending.Count -eq 0)
    total = $results.Count
    changed = $changed.Count
    missing = $missing.Count
    pending = $pending.Count
    results = $results
}

if ($AsJson) {
    $summary | ConvertTo-Json -Depth 5
} else {
    Write-Host 'Chinese skill name sync'
    Write-Host " total   : $($summary.total)"
    Write-Host " changed : $($summary.changed)"
    Write-Host " missing : $($summary.missing)"
    Write-Host " pending : $($summary.pending)"
}

if (-not $summary.ok) {
    exit 1
}

exit 0
