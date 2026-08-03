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

    $matches = @($Skills | Where-Object { $_.name -eq $Name })
    if ($matches.Count -eq 1) {
        return $matches[0]
    }

    return $null
}

function suimiFind-SkillByPath {
    param(
        [object[]]$Skills,
        [string]$Path
    )

    $needle = suimiNormalize -Value $Path
    $matches = @($Skills | Where-Object { (suimiNormalize -Value $_.path) -eq $needle })
    if ($matches.Count -eq 1) {
        return $matches[0]
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

$rules = @(
    [pscustomobject]@{ name = 'flet-desktop-diagnostics'; pattern = 'flet desktop|flet\.exe|app\.exe.*flet|flet.*app\.exe|blank window|hidden window|mainwindowtitle|mainwindowhandle|ui process|desktop window|\u7a97\u53e3\u8bca\u65ad|\u684c\u9762\u8bca\u65ad|\u7a7a\u767d\u7a97\u53e3|\u9690\u85cf\u7a97\u53e3'; confidence = 0.93; reason = 'Task text matches packaged Flet desktop process/window diagnostics.' },
    [pscustomobject]@{ name = 'windows-local-service-persistence'; pattern = 'startup repair|startup folder|scheduled task|schtasks|start-process|local helper service|localhost helper|loopback service|127\.0\.0\.1|port no-op|cold.?start|non-ascii path|\.cmd|\u81ea\u542f\u52a8\u4fee\u590d|\u542f\u52a8\u9879|\u8ba1\u5212\u4efb\u52a1|\u672c\u5730\u670d\u52a1|\u7aef\u53e3|\u51b7\u542f\u52a8'; confidence = 0.93; reason = 'Task text matches Windows localhost helper persistence or startup repair.' },
    [pscustomobject]@{ name = 'windows-python-app-recovery'; pattern = 'lost.?source|source code lost|windows python|python desktop|flet|nuitka|pyinstaller|cx.?freeze|app\.exe|flet\.exe|localappdata|appdata|\.env|machine_id|localhost helper|local license service|cannot enter feature ui|functional ui|startup repair|\u6e90\u7801\u4e22\u5931|\u6253\u5305\u7a0b\u5e8f\u6062\u590d|\u8fdb\u4e0d\u53bb\u529f\u80fd\u754c\u9762|\u672c\u5730\u6388\u6743\u670d\u52a1|\u81ea\u542f\u52a8\u4fee\u590d'; confidence = 0.92; reason = 'Task text matches lost-source Windows Python packaged app recovery or local helper/state repair.' },
    [pscustomobject]@{ name = 'radare2'; pattern = 'radare2|(^|[^a-z0-9])r2([^a-z0-9]|$)|rizin|\u547d\u4ee4\u884c\u9006\u5411'; confidence = 0.90; reason = 'Task text explicitly requests radare2/r2-style analysis.' },
    [pscustomobject]@{ name = 'ida-reverse'; pattern = 'ida|idapro|ida pro|mcp|\u4f2a\u4ee3\u7801|\u4ea4\u53c9\u5f15\u7528|xref'; confidence = 0.88; reason = 'Task text matches IDA or IDA-MCP reverse workflow.' },
    [pscustomobject]@{ name = 'binary-diff'; pattern = 'binary diff|bindiff|diff|\u7248\u672c\u5bf9\u6bd4|\u8865\u4e01\u5dee\u5f02|\u7b26\u53f7\u8fc1\u79fb|patch diff'; confidence = 0.88; reason = 'Task text matches binary diff or version comparison.' },
    [pscustomobject]@{ name = 'apk-reverse'; pattern = 'apk|smali|jadx|apktool|dex|androidmanifest|\u5b89\u5353\u5305|\u91cd\u6253\u5305|\u7b7e\u540d\u5b89\u88c5'; confidence = 0.90; reason = 'Task text matches APK decode, smali, rebuild, or signing workflow.' },
    [pscustomobject]@{ name = 'mobile-reverse'; pattern = 'android|ios|ipa|mobile|frida|objection|ssl pinning|root detection|jailbreak|\u79fb\u52a8\u7aef|\u8d8a\u72f1'; confidence = 0.88; reason = 'Task text matches Android/iOS mobile reverse workflow.' },
    [pscustomobject]@{ name = 'sqli-sql-injection'; pattern = 'sqli|sql injection|sql\u6ce8\u5165|\u6570\u636e\u5e93\u6ce8\u5165'; confidence = 0.90; reason = 'Task text matches SQL injection.' },
    [pscustomobject]@{ name = 'xss-cross-site-scripting'; pattern = 'xss|cross.?site|\u8de8\u7ad9|\u811a\u672c\u6ce8\u5165|html.*\u53cd\u5c04|js.*\u53cd\u5c04'; confidence = 0.90; reason = 'Task text matches XSS.' },
    [pscustomobject]@{ name = 'ssrf-server-side-request-forgery'; pattern = 'ssrf|server.?side request|\u670d\u52a1\u7aef\u8bf7\u6c42|\u5185\u7f51\u63a2\u6d4b|url.*\u56de\u8fde'; confidence = 0.90; reason = 'Task text matches SSRF.' },
    [pscustomobject]@{ name = 'xxe-xml-external-entity'; pattern = 'xxe|xml external|\u5916\u90e8\u5b9e\u4f53|doctype|dtd'; confidence = 0.90; reason = 'Task text matches XXE.' },
    [pscustomobject]@{ name = 'ssti-server-side-template-injection'; pattern = 'ssti|template injection|\u6a21\u677f\u6ce8\u5165|jinja|freemarker|velocity|twig'; confidence = 0.90; reason = 'Task text matches SSTI.' },
    [pscustomobject]@{ name = 'cmdi-command-injection'; pattern = 'cmdi|command injection|\u547d\u4ee4\u6ce8\u5165|shell\u6ce8\u5165|\u7cfb\u7edf\u547d\u4ee4'; confidence = 0.90; reason = 'Task text matches command injection.' },
    [pscustomobject]@{ name = 'nosql-injection'; pattern = 'nosql|mongodb|mongo injection|json\u67e5\u8be2'; confidence = 0.88; reason = 'Task text matches NoSQL injection.' },
    [pscustomobject]@{ name = 'path-traversal-lfi'; pattern = 'path traversal|lfi|\u76ee\u5f55\u7a7f\u8d8a|\u8def\u5f84\u7a7f\u8d8a|\u4efb\u610f\u6587\u4ef6|\u6587\u4ef6\u8bfb\u53d6'; confidence = 0.90; reason = 'Task text matches path traversal or LFI.' },
    [pscustomobject]@{ name = 'upload-insecure-files'; pattern = 'file upload|upload|\u4e0a\u4f20|webshell|\u6587\u4ef6\u4e0a\u4f20'; confidence = 0.88; reason = 'Task text matches insecure file upload.' },
    [pscustomobject]@{ name = 'idor-broken-object-authorization'; pattern = 'idor|bola|bfla|object authorization|\u5bf9\u8c61\u6388\u6743|\u8d8a\u6743|\u6a2a\u5411\u8d8a\u6743'; confidence = 0.90; reason = 'Task text matches IDOR/BOLA/object authorization.' },
    [pscustomobject]@{ name = 'api-auth-and-jwt-abuse'; pattern = 'api.*jwt|jwt.*api|bearer|api token|claim|kid'; confidence = 0.88; reason = 'Task text matches API token or JWT abuse.' },
    [pscustomobject]@{ name = 'jwt-oauth-token-attacks'; pattern = 'jwt|oauth token|jwks|token\u653b\u51fb|alg.*none'; confidence = 0.86; reason = 'Task text matches JWT/OAuth token attacks.' },
    [pscustomobject]@{ name = 'oauth-oidc-misconfiguration'; pattern = 'oauth|oidc|openid|redirect_uri|pkce|nonce'; confidence = 0.86; reason = 'Task text matches OAuth/OIDC.' },
    [pscustomobject]@{ name = 'saml-sso-assertion-attacks'; pattern = 'saml|sso|assertion|acs|\u65ad\u8a00'; confidence = 0.86; reason = 'Task text matches SAML/SSO.' },
    [pscustomobject]@{ name = 'cors-cross-origin-misconfiguration'; pattern = 'cors|origin|\u8de8\u57df|access-control'; confidence = 0.86; reason = 'Task text matches CORS.' },
    [pscustomobject]@{ name = 'csrf-cross-site-request-forgery'; pattern = 'csrf|cross.?site request|samesite|\u8de8\u7ad9\u8bf7\u6c42'; confidence = 0.86; reason = 'Task text matches CSRF.' },
    [pscustomobject]@{ name = 'graphql-and-hidden-parameters'; pattern = 'graphql|introspection|\u9690\u85cf\u53c2\u6570|hidden parameter|\u6279\u91cf\u67e5\u8be2'; confidence = 0.86; reason = 'Task text matches GraphQL or hidden parameters.' },
    [pscustomobject]@{ name = 'api-sec'; pattern = 'api|rest|\u63a5\u53e3|endpoint|swagger|openapi|bola|bfla'; confidence = 0.78; reason = 'Task text matches generic API security routing.' },
    [pscustomobject]@{ name = 'auth-sec'; pattern = 'auth|login|session|\u8ba4\u8bc1|\u767b\u5f55|\u4f1a\u8bdd|\u627e\u56de\u5bc6\u7801|mfa|2fa|\u6388\u6743'; confidence = 0.78; reason = 'Task text matches generic auth/security routing.' },
    [pscustomobject]@{ name = 'injection-checking'; pattern = 'injection|\u6ce8\u5165|\u53c2\u6570\u6c61\u67d3|\u89e3\u91ca\u5668'; confidence = 0.74; reason = 'Task text matches generic injection routing.' },
    [pscustomobject]@{ name = 'hack'; pattern = 'web security|bug bounty|\u6f0f\u6d1e\u8d4f\u91d1|\u6f0f\u6d1e|\u5b89\u5168\u6d4b\u8bd5|\u6e17\u900f|security assessment|\u6f0f\u6d1e\u6316\u6398'; confidence = 0.70; reason = 'Task text matches generic authorized Web/API security research.' },
    [pscustomobject]@{ name = 'reverse-engineering'; pattern = 'reverse|\u9006\u5411|\u8131\u58f3|unpack|binary|\u4e8c\u8fdb\u5236|elf|pe|dll|exe|so|firmware|\u56fa\u4ef6'; confidence = 0.68; reason = 'Task text matches generic reverse-engineering methodology.' }
)

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
            $selected = @($candidates | Sort-Object confidence -Descending | Select-Object -First 1)[0]
            $result = suimiNew-Selection -Skill $selected.skill -Source $selected.source -Confidence $selected.confidence -Reason $selected.reason -RouteDecision $routeDecision -Candidates (@($candidates | ForEach-Object { $_.skill }))
        }
    } else {
        $selected = @($candidates | Sort-Object confidence -Descending | Select-Object -First 1)[0]
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
