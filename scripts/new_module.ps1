#Requires -Version 5.0
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('github-reverse', 'local-reverse', 'security')]
    [string]$Root,

    [Parameter(Mandatory=$true)]
    [string]$Name,

    [Parameter(Mandatory=$true)]
    [string]$DisplayNameZh,

    [Parameter(Mandatory=$true)]
    [string]$Description,

    [string]$Category = '',

    [switch]$AddRoutingRule,

    [switch]$WhatIf,

    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
}

# ---------------------------------------------------------------------------
# This script is intentionally 100% ASCII. All Chinese content flows in at
# runtime through -DisplayNameZh / -Description parameter values and through
# the external UTF-8 template scripts/templates/module.md.tmpl. Never embed a
# Chinese literal here: a no-BOM .ps1 is decoded as system ANSI on Windows
# PowerShell 5.1, which would corrupt any embedded multi-byte characters.
# ---------------------------------------------------------------------------

function suimiRead-TextFileInfo {
    param([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hadBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    if ($text.Contains("`r`n")) {
        $eol = "`r`n"
    } else {
        $eol = "`n"
    }

    return [pscustomobject][ordered]@{
        text = $text
        hadBom = $hadBom
        eol = $eol
    }
}

function suimiWrite-TextFile {
    param(
        [string]$Path,
        [string]$Text,
        [bool]$HadBom
    )

    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($HadBom))
}

function suimiConvertTo-JsonScalar {
    param([string]$Value)

    return $Value.Replace('\', '\\').Replace('"', '\"')
}

function suimiInsert-AfterLastMatch {
    param(
        [string]$Text,
        [string]$Eol,
        [string]$AnchorRegex,
        [string]$NewLine,
        [string]$PresenceToken
    )

    if ($Text.Contains($PresenceToken)) {
        return [pscustomobject]@{ status = 'already-present'; text = $Text }
    }

    $lines = $Text -split "`r?`n"
    $lastIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $AnchorRegex) {
            $lastIdx = $i
        }
    }

    if ($lastIdx -lt 0) {
        return [pscustomobject]@{ status = 'anchor-not-found'; text = $Text }
    }

    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        $list.Add($line)
    }
    $list.Insert($lastIdx + 1, $NewLine)
    $newText = [string]::Join($Eol, $list)

    return [pscustomobject]@{ status = 'insert'; text = $newText }
}

function suimiInsert-BeforeHeading {
    param(
        [string]$Text,
        [string]$Eol,
        [string]$HeadingRegex,
        [string[]]$NewBlockLines,
        [string]$PresenceToken
    )

    if ($Text.Contains($PresenceToken)) {
        return [pscustomobject]@{ status = 'already-present'; text = $Text }
    }

    $lines = $Text -split "`r?`n"
    $headingIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $HeadingRegex) {
            $headingIdx = $i
            break
        }
    }

    if ($headingIdx -lt 0) {
        return [pscustomobject]@{ status = 'anchor-not-found'; text = $Text }
    }

    $prevIdx = $headingIdx - 1
    while ($prevIdx -ge 0 -and [string]::IsNullOrWhiteSpace($lines[$prevIdx])) {
        $prevIdx--
    }

    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        $list.Add($line)
    }

    $insertAt = $prevIdx + 1
    for ($j = $NewBlockLines.Count - 1; $j -ge 0; $j--) {
        $list.Insert($insertAt, $NewBlockLines[$j])
    }
    $newText = [string]::Join($Eol, $list)

    return [pscustomobject]@{ status = 'insert'; text = $newText }
}

function suimiAdd-JsonEntry {
    param(
        [string]$Text,
        [string]$Eol,
        [string]$RelPath,
        [string]$DisplayName
    )

    $escapedRel = [regex]::Escape($RelPath)
    if ($Text -match ('"path"\s*:\s*"' + $escapedRel + '"')) {
        return [pscustomobject]@{ status = 'already-present'; text = $Text }
    }

    $lines = $Text -split "`r?`n"
    $lastObjEndIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd().EndsWith('}')) {
            $lastObjEndIdx = $i
        }
    }

    if ($lastObjEndIdx -lt 0) {
        return [pscustomobject]@{ status = 'anchor-not-found'; text = $Text }
    }

    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        $list.Add($line)
    }

    $prevTrimEnd = $list[$lastObjEndIdx].TrimEnd()
    if (-not $prevTrimEnd.EndsWith(',')) {
        $list[$lastObjEndIdx] = $prevTrimEnd + ','
    }

    $newEntry = '  {"path":"' + $RelPath + '","display_name":"' + (suimiConvertTo-JsonScalar -Value $DisplayName) + '"}'
    $list.Insert($lastObjEndIdx + 1, $newEntry)
    $newText = [string]::Join($Eol, $list)

    try {
        $null = $newText | ConvertFrom-Json
    } catch {
        throw "chinese-skill-names.json edit would produce invalid JSON: $($_.Exception.Message)"
    }

    return [pscustomobject]@{ status = 'insert'; text = $newText }
}

function suimiFinalize-Edit {
    param(
        [string]$Path,
        [string]$TargetLabel,
        [object]$Info,
        [object]$Result,
        [bool]$WhatIfMode
    )

    $status = $Result.status
    if ($status -eq 'insert') {
        if ($WhatIfMode) {
            $status = 'would-append'
        } else {
            suimiWrite-TextFile -Path $Path -Text $Result.text -HadBom $Info.hadBom
            $status = 'appended'
        }
    }

    return [pscustomobject][ordered]@{
        target = $TargetLabel
        status = $status
    }
}

# --- validate inputs -------------------------------------------------------

if (-not ($Name -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$')) {
    throw "Name must be kebab-case (lowercase letters, digits, single hyphens): $Name"
}

if (-not $DisplayNameZh.StartsWith('suimi')) {
    throw "DisplayNameZh must start with 'suimi': $DisplayNameZh"
}

if ($Description.Contains("`n") -or $Description.Contains("`r")) {
    throw 'Description must be a single line (no line breaks).'
}

$descTrimmed = $Description.Trim()
if ($descTrimmed.Length -eq 0) {
    throw 'Description must not be empty.'
}
if ($descTrimmed -in @('|', '>', '|-', '>-', '|+', '>+')) {
    throw "Description must not be a bare YAML block-scalar placeholder: $Description"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..')).Path
$templatePath = Join-Path $scriptDir 'templates\module.md.tmpl'
if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Module template not found: $templatePath"
}

# --- resolve landing zone --------------------------------------------------

$baseMap = @{
    'github-reverse' = 'github-reverse-modules/skills'
    'local-reverse'  = 'local-reverse-modules/skills'
    'security'       = 'security-research-modules/skills'
}
$base = $baseMap[$Root]
$relPath = "$base/$Name/MODULE.md"
$moduleDir = Join-Path $rootDir (($base + "/$Name").Replace('/', '\'))
$modulePath = Join-Path $moduleDir 'MODULE.md'

$routerNames = @('hack', 'recon-for-sec', 'api-sec', 'auth-sec', 'injection-checking', 'file-access-vuln', 'business-logic-vuln', 'ctf-sandbox-orchestrator')
$chosenRouter = $null
if ($Root -eq 'security') {
    if ($Category -and ($Category -in $routerNames)) {
        $chosenRouter = $Category
    } else {
        $chosenRouter = 'hack'
    }
}

$tick = [char]0x60
$whatIfMode = [bool]$WhatIf
$actions = @()

# --- 1. MODULE.md skeleton -------------------------------------------------

if (Test-Path -LiteralPath $modulePath) {
    $moduleStatus = 'already-present'
} elseif ($whatIfMode) {
    $moduleStatus = 'would-create'
} else {
    if (-not (Test-Path -LiteralPath $moduleDir)) {
        New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null
    }
    $tmpl = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
    $content = $tmpl.Replace('{{NAME}}', $Name).Replace('{{DESCRIPTION}}', $Description).Replace('{{DISPLAY_NAME_ZH}}', $DisplayNameZh).Replace('{{TITLE}}', $DisplayNameZh)
    suimiWrite-TextFile -Path $modulePath -Text $content -HadBom $false
    $moduleStatus = 'created'
}
$actions += [pscustomobject][ordered]@{ target = $relPath; status = $moduleStatus }

# --- 2. references/chinese-skill-names.json (all landings) ------------------

$jsonPath = Join-Path $rootDir 'references\chinese-skill-names.json'
$info = suimiRead-TextFileInfo -Path $jsonPath
$res = suimiAdd-JsonEntry -Text $info.text -Eol $info.eol -RelPath $relPath -DisplayName $DisplayNameZh
$actions += suimiFinalize-Edit -Path $jsonPath -TargetLabel 'references/chinese-skill-names.json' -Info $info -Result $res -WhatIfMode $whatIfMode

# --- 3. references/unified-skills-entry.md (all landings) -------------------

$unifiedPath = Join-Path $rootDir 'references\unified-skills-entry.md'
$info = suimiRead-TextFileInfo -Path $unifiedPath
$treeAnchorMap = @{
    'github-reverse' = 'github-reverse-modules/skills/[a-z0-9\-]+/MODULE\.md'
    'local-reverse'  = 'local-reverse-modules/skills/[a-z0-9\-]+/MODULE\.md'
    'security'       = 'security-research-modules/skills/[a-z0-9\-]+/MODULE\.md'
}
if ($Root -eq 'security') {
    $unifiedRow = '| ' + $DisplayNameZh + ' | ' + $tick + $relPath + $tick + ' |'
} else {
    $unifiedRow = '| ' + $DisplayNameZh + ' | ' + $tick + $relPath + $tick + ' | ' + $Description + ' |'
}
$res = suimiInsert-AfterLastMatch -Text $info.text -Eol $info.eol -AnchorRegex $treeAnchorMap[$Root] -NewLine $unifiedRow -PresenceToken $relPath
$actions += suimiFinalize-Edit -Path $unifiedPath -TargetLabel 'references/unified-skills-entry.md' -Info $info -Result $res -WhatIfMode $whatIfMode

# --- 4. INDEX.md / SKILL.md lists (per landing) ----------------------------

$skillPath = Join-Path $rootDir 'SKILL.md'

if ($Root -eq 'github-reverse') {
    $ghIndexPath = Join-Path $rootDir 'github-reverse-modules\INDEX.md'
    $info = suimiRead-TextFileInfo -Path $ghIndexPath
    $block = @(
        '- ' + $tick + "skills/$Name/" + $tick,
        '  - Entry: ' + $tick + "skills/$Name/MODULE.md" + $tick,
        '  - Focus: ' + $Description
    )
    $res = suimiInsert-BeforeHeading -Text $info.text -Eol $info.eol -HeadingRegex '^## Shared Support Scripts' -NewBlockLines $block -PresenceToken "skills/$Name/"
    $actions += suimiFinalize-Edit -Path $ghIndexPath -TargetLabel 'github-reverse-modules/INDEX.md' -Info $info -Result $res -WhatIfMode $whatIfMode

    $info = suimiRead-TextFileInfo -Path $skillPath
    $skillLine = '- ' + $tick + $relPath + $tick + ': ' + $Description
    $res = suimiInsert-AfterLastMatch -Text $info.text -Eol $info.eol -AnchorRegex 'github-reverse-modules/skills/[a-z0-9\-]+/MODULE\.md' -NewLine $skillLine -PresenceToken $relPath
    $actions += suimiFinalize-Edit -Path $skillPath -TargetLabel 'SKILL.md (Added Reverse Modules)' -Info $info -Result $res -WhatIfMode $whatIfMode
} elseif ($Root -eq 'security') {
    $secIndexPath = Join-Path $rootDir 'security-research-modules\INDEX.md'
    $info = suimiRead-TextFileInfo -Path $secIndexPath
    $secIndexLine = '- ' + $tick + $Name + $tick + ': ' + $Description
    $res = suimiInsert-BeforeHeading -Text $info.text -Eol $info.eol -HeadingRegex '^## Compatibility Notes' -NewBlockLines @($secIndexLine) -PresenceToken ($tick + $Name + $tick)
    $actions += suimiFinalize-Edit -Path $secIndexPath -TargetLabel 'security-research-modules/INDEX.md' -Info $info -Result $res -WhatIfMode $whatIfMode

    $info = suimiRead-TextFileInfo -Path $skillPath
    $skillLine = '- ' + $tick + $relPath + $tick + ': ' + $Description
    $res = suimiInsert-AfterLastMatch -Text $info.text -Eol $info.eol -AnchorRegex 'security-research-modules/skills/[a-z0-9\-]+/MODULE\.md' -NewLine $skillLine -PresenceToken $relPath
    $actions += suimiFinalize-Edit -Path $skillPath -TargetLabel 'SKILL.md (Added Security Research Modules)' -Info $info -Result $res -WhatIfMode $whatIfMode
} else {
    # local-reverse: register in root SKILL.md "Added Local Reverse Modules". A local
    # INDEX.md is optional per module-onboarding-spec 5.C, so register in it only when
    # it exists (some healthcheck revisions enforce it once present). Test-Path keeps
    # the tool correct whether or not the local INDEX is part of the tree.
    $localIndexPath = Join-Path $rootDir 'local-reverse-modules\INDEX.md'
    if (Test-Path -LiteralPath $localIndexPath) {
        $info = suimiRead-TextFileInfo -Path $localIndexPath
        $block = @(
            '- ' + $tick + "skills/$Name/" + $tick,
            '  - Entry: ' + $tick + "skills/$Name/MODULE.md" + $tick,
            '  - Focus: ' + $Description
        )
        $res = suimiInsert-BeforeHeading -Text $info.text -Eol $info.eol -HeadingRegex '^## Shared Support Scripts' -NewBlockLines $block -PresenceToken "skills/$Name/"
        $actions += suimiFinalize-Edit -Path $localIndexPath -TargetLabel 'local-reverse-modules/INDEX.md' -Info $info -Result $res -WhatIfMode $whatIfMode
    }

    $info = suimiRead-TextFileInfo -Path $skillPath
    $skillLine = '- ' + $tick + $relPath + $tick + ': ' + $Description
    $res = suimiInsert-AfterLastMatch -Text $info.text -Eol $info.eol -AnchorRegex 'local-reverse-modules/skills/[a-z0-9\-]+/MODULE\.md' -NewLine $skillLine -PresenceToken $relPath
    $actions += suimiFinalize-Edit -Path $skillPath -TargetLabel 'SKILL.md (Added Local Reverse Modules)' -Info $info -Result $res -WhatIfMode $whatIfMode
}

# --- 5. P1 router Skill Map link (security only, avoids orphan fail) --------

if ($Root -eq 'security') {
    $routerPath = Join-Path $rootDir ("security-research-modules\skills\$chosenRouter\MODULE.md")
    $info = suimiRead-TextFileInfo -Path $routerPath
    $routerLine = '- [' + $DisplayNameZh + '](../' + $Name + '/MODULE.md): ' + $Description
    $routerPresence = '](../' + $Name + '/MODULE.md)'
    $routerAnchor = '^\s*-\s*\[[^\]]*\]\(\.\./[a-z0-9\-]+/MODULE\.md\)'
    $res = suimiInsert-AfterLastMatch -Text $info.text -Eol $info.eol -AnchorRegex $routerAnchor -NewLine $routerLine -PresenceToken $routerPresence
    $actions += suimiFinalize-Edit -Path $routerPath -TargetLabel ("security-research-modules/skills/$chosenRouter/MODULE.md (Skill Map)") -Info $info -Result $res -WhatIfMode $whatIfMode
}

# --- 6. optional select_skill.ps1 routing rule -----------------------------

$routingWarning = $null
if ($AddRoutingRule) {
    $selectPath = Join-Path $rootDir 'scripts\select_skill.ps1'
    $info = suimiRead-TextFileInfo -Path $selectPath
    $rulePresence = "name = '" + $Name + "'"
    if ($info.text.Contains($rulePresence)) {
        $actions += [pscustomobject][ordered]@{ target = 'scripts/select_skill.ps1 (rule)'; status = 'already-present' }
    } else {
        $lines = $info.text -split "`r?`n"
        $anchorIdx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\$rules = @\(') {
                $anchorIdx = $i
                break
            }
        }
        if ($anchorIdx -lt 0) {
            $actions += [pscustomobject][ordered]@{ target = 'scripts/select_skill.ps1 (rule)'; status = 'anchor-not-found' }
        } else {
            $patternWords = ($Name -split '-') -join '|'
            $ruleLine = "    [pscustomobject]@{ name = '" + $Name + "'; pattern = '" + $patternWords + "'; confidence = 0.75; reason = 'Task text matches " + $Name + " module.' },"
            $list = [System.Collections.Generic.List[string]]::new()
            foreach ($line in $lines) {
                $list.Add($line)
            }
            $list.Insert($anchorIdx + 1, $ruleLine)
            $newText = [string]::Join($info.eol, $list)
            if ($whatIfMode) {
                $actions += [pscustomobject][ordered]@{ target = 'scripts/select_skill.ps1 (rule)'; status = 'would-append' }
            } else {
                suimiWrite-TextFile -Path $selectPath -Text $newText -HadBom $info.hadBom
                $actions += [pscustomobject][ordered]@{ target = 'scripts/select_skill.ps1 (rule)'; status = 'appended' }
            }
        }
    }
    $routingWarning = 'A select_skill.ps1 rule was staged. Per module-onboarding-spec section 6 you MUST run the natural-language batch test and add a tests/routing.Tests.ps1 regression before relying on it.'
}

# --- aggregate + report ----------------------------------------------------

$failedActions = @($actions | Where-Object { $_.status -in @('anchor-not-found', 'file-not-found') })
$ok = ($failedActions.Count -eq 0)

$result = [ordered]@{
    ok = $ok
    applied = (-not $whatIfMode)
    what_if = $whatIfMode
    root = $Root
    name = $Name
    module_path = $relPath
    chosen_router = $chosenRouter
    actions = @($actions)
}
if ($routingWarning) {
    $result['routing_warning'] = $routingWarning
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 6
} else {
    Write-Host 'suimi new module scaffold'
    Write-Host " ok            : $ok"
    Write-Host " applied       : $(-not $whatIfMode)"
    Write-Host " root          : $Root"
    Write-Host " module_path   : $relPath"
    if ($chosenRouter) {
        Write-Host " chosen_router : $chosenRouter (move to a more precise P1 router if needed)"
    }
    foreach ($action in $actions) {
        Write-Host ("  - [{0}] {1}" -f $action.status, $action.target)
    }
    if ($routingWarning) {
        Write-Host " warning       : $routingWarning"
    }
}

if (-not $ok) {
    exit 1
}

exit 0
