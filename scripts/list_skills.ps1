#Requires -Version 5.0
param(
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

function suimiGet-ChineseSkillNameMap {
    param([string]$RootDir)

    $mapPath = Join-Path $RootDir 'references\chinese-skill-names.json'
    if (-not (Test-Path -LiteralPath $mapPath)) {
        throw "Chinese skill name map not found: $mapPath"
    }

    $json = [System.IO.File]::ReadAllText($mapPath, [System.Text.Encoding]::UTF8)
    $items = $json | ConvertFrom-Json
    $map = @{}
    foreach ($item in $items) {
        $map[[string]$item.path] = [string]$item.display_name
    }

    return $map
}

function suimiGet-SkillCategory {
    param([string]$RelativePath)

    if ($RelativePath -eq 'SKILL.md') {
        return 'root'
    }
    if ($RelativePath.StartsWith('github-reverse-modules/skills/', [StringComparison]::OrdinalIgnoreCase)) {
        return 'github-reverse'
    }
    if ($RelativePath.StartsWith('local-reverse-modules/skills/', [StringComparison]::OrdinalIgnoreCase)) {
        return 'local-reverse'
    }
    if ($RelativePath.StartsWith('security-research-modules/skills/', [StringComparison]::OrdinalIgnoreCase)) {
        return 'security'
    }

    return 'other'
}

function suimiNormalize-FrontmatterScalar {
    param([string]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $result = $Value.Trim()
    if ($result.Length -ge 2) {
        $first = $result.Substring(0, 1)
        $last = $result.Substring($result.Length - 1, 1)
        if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
            return $result.Substring(1, $result.Length - 2)
        }
    }

    return $result
}

function suimiFold-FrontmatterBlock {
    param(
        [string[]]$Lines,
        [string]$Style
    )

    $lineList = @($Lines)
    if ($lineList.Count -eq 0) {
        return ''
    }

    $nonEmptyLines = @($lineList | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $minIndent = 0
    if ($nonEmptyLines.Count -gt 0) {
        $minIndent = @($nonEmptyLines | ForEach-Object {
            if ($_ -match '^(?<indent>\s*)') {
                $Matches.indent.Length
            }
        } | Measure-Object -Minimum).Minimum
    }

    $normalizedLines = @()
    foreach ($line in $lineList) {
        if ($line.Length -ge $minIndent) {
            $normalizedLines += $line.Substring($minIndent)
        } else {
            $normalizedLines += $line.TrimStart()
        }
    }

    if ($Style -eq '|') {
        return (($normalizedLines -join "`n").Trim())
    }

    $paragraphs = @()
    $current = @()
    foreach ($line in $normalizedLines) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '') {
            if ($current.Count -gt 0) {
                $paragraphs += ($current -join ' ')
                $current = @()
            }
        } else {
            $current += $trimmed
        }
    }
    if ($current.Count -gt 0) {
        $paragraphs += ($current -join ' ')
    }

    return (($paragraphs -join "`n").Trim())
}

function suimiRead-FrontmatterField {
    param(
        [string]$Frontmatter,
        [string]$Name
    )

    $lines = @($Frontmatter -split "`r?`n")
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match ('^' + [regex]::Escape($Name) + ':\s*(?<value>.*)$')) {
            $value = $Matches.value.TrimEnd()
            if ($value -match '^(?<style>[>|])[-+]?\s*$') {
                $style = $Matches.style
                $blockLines = @()
                for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                    $nextLine = $lines[$j]
                    if ($nextLine -match '^\S[^:]*:\s*') {
                        break
                    }
                    $blockLines += $nextLine
                }

                return suimiFold-FrontmatterBlock -Lines $blockLines -Style $style
            }

            return suimiNormalize-FrontmatterScalar -Value $value
        }
    }

    return $null
}

function suimiRead-SkillMetadata {
    param(
        [string]$RootDir,
        [string]$Path,
        [hashtable]$ChineseNameMap
    )

    $relativePath = suimiGet-RelativePath -RootDir $RootDir -Path $Path
    $text = Get-Content -LiteralPath $Path -Raw
    $name = $null
    $description = $null

    if ($text -match '(?s)^---\s*\r?\n(?<frontmatter>.*?)\r?\n---') {
        $frontmatter = $Matches.frontmatter
        $name = suimiRead-FrontmatterField -Frontmatter $frontmatter -Name 'name'
        $description = suimiRead-FrontmatterField -Frontmatter $frontmatter -Name 'description'
    }

    $displayName = $null
    if ($ChineseNameMap.ContainsKey($relativePath)) {
        $displayName = $ChineseNameMap[$relativePath]
    }
    if (-not $displayName -and $text -match '(?m)^中文名：(?<display>[^\r\n]+)') {
        $displayName = $Matches.display
    }

    $item = Get-Item -LiteralPath $Path
    [pscustomobject][ordered]@{
        name = $name
        display_name = $displayName
        category = suimiGet-SkillCategory -RelativePath $relativePath
        path = $relativePath
        description = $description
        bytes = $item.Length
        lines = ($text -split "`r?`n").Count
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..')).Path
$nameMap = suimiGet-ChineseSkillNameMap -RootDir $rootDir

$skillFiles = @()
$skillFiles += Join-Path $rootDir 'SKILL.md'
$skillFiles += Get-ChildItem -LiteralPath (Join-Path $rootDir 'github-reverse-modules\skills') -Filter 'MODULE.md' -File -Recurse | Select-Object -ExpandProperty FullName
$localSkillsRoot = Join-Path $rootDir 'local-reverse-modules\skills'
if (Test-Path -LiteralPath $localSkillsRoot) {
    $skillFiles += Get-ChildItem -LiteralPath $localSkillsRoot -Filter 'MODULE.md' -File -Recurse | Select-Object -ExpandProperty FullName
}
$skillFiles += Get-ChildItem -LiteralPath (Join-Path $rootDir 'security-research-modules\skills') -Filter 'MODULE.md' -File -Recurse | Select-Object -ExpandProperty FullName

$skills = @()
foreach ($path in $skillFiles) {
    $skill = suimiRead-SkillMetadata -RootDir $rootDir -Path $path -ChineseNameMap $nameMap
    if ($Category -eq 'all' -or $skill.category -eq $Category) {
        $skills += $skill
    }
}

$skills = @($skills | Sort-Object category, name, path)
$missingMetadata = @($skills | Where-Object { -not $_.name -or -not $_.description -or -not $_.display_name })
$summary = [ordered]@{
    ok = ($missingMetadata.Count -eq 0)
    category = $Category
    count = $skills.Count
    missing_metadata = $missingMetadata.Count
    skills = $skills
}

if ($AsJson) {
    $summary | ConvertTo-Json -Depth 5
} else {
    Write-Host "Reusable reverse skill registry"
    Write-Host " category         : $($summary.category)"
    Write-Host " count            : $($summary.count)"
    Write-Host " missing metadata : $($summary.missing_metadata)"
    foreach ($skill in $skills) {
        Write-Host (" - [{0}] {1} ({2}) -> {3}" -f $skill.category, $skill.display_name, $skill.name, $skill.path)
    }
}

if (-not $summary.ok) {
    exit 1
}

exit 0
