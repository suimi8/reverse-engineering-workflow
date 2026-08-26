#Requires -Version 5.0
param(
    [Parameter(Mandatory=$true)]
    [string]$TaskText,

    [string]$TargetPath = '',

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

function suimiFind-SkillByName {
    param(
        [object[]]$Skills,
        [string]$Name
    )

    # Use a private variable name here: $matches is a PowerShell automatic variable
    # (populated by -match), so reusing it risks silent clobbering elsewhere. Also
    # take the first hit when >=1 match: under cloud-sync races list_skills can
    # briefly enumerate the same module twice, and the old "exactly 1" test would
    # then drop the rule (returning $null) and let a lower-confidence rule win.
    # Same-named modules are the same skill, so taking the first is safe.
    $found = @($Skills | Where-Object { $_.name -eq $Name })
    if ($found.Count -ge 1) {
        return $found[0]
    }

    return $null
}

function suimiFind-SkillByPath {
    param(
        [object[]]$Skills,
        [string]$Path
    )

    $needle = suimiNormalize -Value $Path
    # Use a private variable name here: $matches is a PowerShell automatic variable
    $found = @($Skills | Where-Object { (suimiNormalize -Value $_.path) -eq $needle })
    if ($found.Count -ge 1) {
        return $found[0]
    }

    return $null
}

function suimiIs-SecurityRouterName {
    param([string]$Name)

    return ($Name -in @(
        'hack',
        'recon-for-sec',
        'api-sec',
        'auth-sec',
        'injection-checking',
        'file-access-vuln',
        'business-logic-vuln'
    ))
}

function suimiShouldUse-ApiSecurityRouter {
    param(
        [object[]]$SecurityDetailCandidates,
        [string]$Text
    )

    if ($Text -match 'api|rest|graphql|endpoint|swagger|openapi|bearer|jwt|token|bola|bfla|idor|\u63a5\u53e3') {
        return $true
    }

    $apiDetailNames = @(
        'api-recon-and-docs',
        'api-authorization-and-bola',
        'api-auth-and-jwt-abuse',
        'graphql-and-hidden-parameters',
        'idor-broken-object-authorization',
        'jwt-oauth-token-attacks',
        'oauth-oidc-misconfiguration',
        'saml-sso-assertion-attacks'
    )

    return (@($SecurityDetailCandidates | Where-Object { $_.skill.name -in $apiDetailNames }).Count -gt 0)
}

function suimiGet-UniqueSkills {
    param([object[]]$Skills)

    $seen = @{}
    $unique = @()
    foreach ($skill in @($Skills)) {
        if (-not $skill) {
            continue
        }

        $key = [string]$skill.path
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $unique += $skill
        }
    }

    return $unique
}

function suimiNew-Selection {
    param(
        [object]$Skill,
        [string]$Source,
        [double]$Confidence,
        [string]$Reason,
        [object]$RouteDecision = $null,
        [object[]]$Candidates = @()
    )

    $candidateList = @($Candidates)
    if ($candidateList.Count -eq 0 -and $Skill) {
        $candidateList = @($Skill)
    }

    [pscustomobject][ordered]@{
        ok = ($null -ne $Skill)
        status = if ($Skill) { 'selected' } else { 'not-found' }
        task_text = $TaskText
        target_path = $TargetPath
        source = $Source
        confidence = $Confidence
        skill = $Skill
        candidates = $candidateList
        route_decision = $RouteDecision
        reason = $Reason
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$listScript = Join-Path $scriptDir 'list_skills.ps1'
$entryScript = Join-Path $scriptDir 're_workflow_entry.ps1'

if (-not (Test-Path -LiteralPath $listScript)) {
    throw "Skill registry script not found: $listScript"
}

$registryJson = & $listScript -AsJson
if ($LASTEXITCODE -ne 0) {
    throw 'Skill registry script returned a non-zero exit code.'
}

$registry = $registryJson | ConvertFrom-Json
$skills = @($registry.skills)
$text = suimiNormalize -Value $TaskText
$routeDecision = $null

if (-not [string]::IsNullOrWhiteSpace($TargetPath)) {
    if (-not (Test-Path -LiteralPath $TargetPath)) {
        throw "Target path not found: $TargetPath"
    }

    $routeJson = & $entryScript -TargetPath $TargetPath -Intent auto -TaskText $TaskText -NoExecute -AsJson
    if ($LASTEXITCODE -ne 0) {
        throw 'Reverse workflow entry script returned a non-zero exit code.'
    }
    $routeDecision = $routeJson | ConvertFrom-Json

    if ($routeDecision.module_entry -and ([string]$routeDecision.module_entry).EndsWith('/MODULE.md')) {
        $routedSkill = suimiFind-SkillByPath -Skills $skills -Path $routeDecision.module_entry
        if ($routedSkill) {
            $result = suimiNew-Selection -Skill $routedSkill -Source 'target-router' -Confidence 0.95 -Reason "Selected concrete internal module from re_workflow_entry route '$($routeDecision.route)'." -RouteDecision $routeDecision
            if ($AsJson) {
                $result | ConvertTo-Json -Depth 8
            } else {
                Write-Host "Reusable reverse skill selector"
                Write-Host " status     : $($result.status)"
                Write-Host " source     : $($result.source)"
                Write-Host " confidence : $($result.confidence)"
                Write-Host " skill      : $($result.skill.path)"
                Write-Host " reason     : $($result.reason)"
            }
            exit 0
        }
    }
}

$rulesPath = Join-Path $scriptDir 'routing-rules.json'
if (-not (Test-Path -LiteralPath $rulesPath)) {
    [Console]::Error.WriteLine("Routing rules file not found: $rulesPath")
    exit 1
}
$rulesRaw = [System.IO.File]::ReadAllText($rulesPath, [System.Text.Encoding]::UTF8)
$parsedRules = $rulesRaw | ConvertFrom-Json
$rules = @($parsedRules)

$candidates = @()
foreach ($rule in $rules) {
    if ($text -match $rule.pattern) {
        $skill = suimiFind-SkillByName -Skills $skills -Name $rule.name
        if ($skill) {
            $candidates += [pscustomobject][ordered]@{
                skill = $skill
                source = 'task-rule'
                confidence = [double]$rule.confidence
                reason = $rule.reason
            }
        }
    }
}

if ($candidates.Count -gt 0) {
    $securityCandidates = @($candidates | Where-Object { $_.skill.category -eq 'security' })
    $securityDetailCandidates = @($securityCandidates | Where-Object { -not (suimiIs-SecurityRouterName -Name $_.skill.name) })

    if ($securityDetailCandidates.Count -gt 1) {
        $routerName = if (suimiShouldUse-ApiSecurityRouter -SecurityDetailCandidates $securityDetailCandidates -Text $text) { 'api-sec' } else { 'hack' }
        $routerSkill = suimiFind-SkillByName -Skills $skills -Name $routerName
        if ($routerSkill) {
            $candidateSkills = suimiGet-UniqueSkills -Skills (@($routerSkill) + @($candidates | ForEach-Object { $_.skill }))
            $routerReason = if ($routerName -eq 'api-sec') {
                'Multiple concrete security topics matched an API-oriented task; select the API security router and keep topic skills as candidates.'
            } else {
                'Multiple concrete security topics matched; select the primary security router and keep topic skills as candidates.'
            }
            $result = suimiNew-Selection -Skill $routerSkill -Source 'mixed-security-router' -Confidence 0.84 -Reason $routerReason -RouteDecision $routeDecision -Candidates $candidateSkills
        } else {
            $selected = @($candidates | Sort-Object confidence -Descending -Stable | Select-Object -First 1)[0]
            $result = suimiNew-Selection -Skill $selected.skill -Source $selected.source -Confidence $selected.confidence -Reason $selected.reason -RouteDecision $routeDecision -Candidates (@($candidates | ForEach-Object { $_.skill }))
        }
    } else {
        $selected = @($candidates | Sort-Object confidence -Descending -Stable | Select-Object -First 1)[0]
        $result = suimiNew-Selection -Skill $selected.skill -Source $selected.source -Confidence $selected.confidence -Reason $selected.reason -RouteDecision $routeDecision -Candidates (@($candidates | ForEach-Object { $_.skill }))
    }
} else {
    $fallbackSkill = suimiFind-SkillByName -Skills $skills -Name 'reverse-engineering-workflow'
    $result = suimiNew-Selection -Skill $fallbackSkill -Source 'fallback-root' -Confidence 0.40 -Reason 'No specific rule matched; use the root workflow to establish baseline and route manually.' -RouteDecision $routeDecision
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 8
} else {
    Write-Host "Reusable reverse skill selector"
    Write-Host " status     : $($result.status)"
    Write-Host " source     : $($result.source)"
    Write-Host " confidence : $($result.confidence)"
    if ($result.skill) {
        Write-Host " skill      : $($result.skill.path)"
    }
    Write-Host " reason     : $($result.reason)"
}

if (-not $result.ok) {
    exit 1
}

exit 0
