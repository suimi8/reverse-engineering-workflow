#Requires -Version 5.0
param(
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

function suimiNew-Check {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Message
    )

    [pscustomobject][ordered]@{
        name = $Name
        status = $Status
        message = $Message
    }
}

function suimiAdd-Check {
    param([object]$Check)

    $script:checks += $Check
}

function suimiTest-PowerShellSyntax {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors -and $errors.Count -gt 0) {
            return "PowerShell syntax failed in ${path}: $($errors[0].Message)"
        }
    }

    return $null
}

function suimiTest-PythonSyntax {
    param([string[]]$Paths)

    $python = Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
    if (-not $python) {
        return @{
            status = 'warn'
            message = 'python.exe not found; skipped Python syntax checks.'
        }
    }

    foreach ($path in $Paths) {
        & $python -c "import ast,pathlib,sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'), filename=sys.argv[1])" $path
        if ($LASTEXITCODE -ne 0) {
            return @{
                status = 'fail'
                message = "Python syntax parse failed in ${path}."
            }
        }
    }

    return @{
        status = 'pass'
        message = "Python syntax OK for $($Paths.Count) file(s)."
    }
}

function suimiTest-BashSyntax {
    param(
        [string]$RootDir,
        [string[]]$Paths
    )

    $bash = Get-Command bash.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
    if (-not $bash) {
        return @{
            status = 'pass'
            message = 'Optional bash.exe not found; skipped Bash syntax checks.'
        }
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $probeOutput = @(& $bash --version 2>&1)
        $probeExitCode = $LASTEXITCODE
    } catch {
        $probeOutput = @($_.Exception.Message)
        $probeExitCode = 1
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($probeExitCode -ne 0) {
        $probeText = (($probeOutput | ForEach-Object { [string]$_ }) -join ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($probeText)) {
            $probeText = 'bash.exe returned a non-zero exit code.'
        }
        return @{
            status = 'pass'
            message = "Optional bash.exe is present but cannot launch; skipped Bash syntax checks: $probeText"
        }
    }

    foreach ($path in $Paths) {
        $normalizedRoot = $RootDir.TrimEnd('\', '/')
        $normalizedPath = (Resolve-Path -LiteralPath $path).Path
        if (-not $normalizedPath.StartsWith($normalizedRoot, [StringComparison]::OrdinalIgnoreCase)) {
            return @{
                status = 'fail'
                message = "Bash syntax path is outside project root: ${normalizedPath}"
            }
        }

        $relativePath = $normalizedPath.Substring($normalizedRoot.Length).TrimStart('\', '/').Replace('\', '/')
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $bashOutput = @(& $bash -n $relativePath 2>&1)
            $bashExitCode = $LASTEXITCODE
        } catch {
            $bashOutput = @($_.Exception.Message)
            $bashExitCode = 1
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        if ($bashExitCode -ne 0) {
            $bashText = (($bashOutput | ForEach-Object { [string]$_ }) -join ' ').Trim()
            if ([string]::IsNullOrWhiteSpace($bashText)) {
                $bashText = 'bash.exe returned a non-zero exit code.'
            }
            if ($bashText -match 'E_ACCESSDENIED|CreateInstance|Access is denied|Permission denied') {
                return @{
                    status = 'pass'
                    message = "Optional bash.exe cannot launch in this environment; skipped Bash syntax checks: $bashText"
                }
            }
            return @{
                status = 'fail'
                message = "Bash syntax failed in ${relativePath}: $bashText"
            }
        }
    }

    return @{
        status = 'pass'
        message = "Bash syntax OK for $($Paths.Count) file(s)."
    }
}

function suimiTest-MarkdownSkillModules {
    param(
        [string]$SkillsRoot,
        [string]$Label,
        [string[]]$ExcludeDirNames = @()
    )

    if (-not (Test-Path -LiteralPath $SkillsRoot)) {
        return @{
            status = 'warn'
            message = "${Label} module root not found; skipped module checks."
        }
    }

    $dirs = Get-ChildItem -LiteralPath $SkillsRoot -Directory
    $issues = @()

    foreach ($dir in $dirs) {
        if ($dir.Name -in $ExcludeDirNames) {
            continue
        }

        $skillPath = Join-Path $dir.FullName 'MODULE.md'
        if (-not (Test-Path -LiteralPath $skillPath)) {
            $issues += "$($dir.Name): missing MODULE.md"
            continue
        }

        $text = Get-Content -LiteralPath $skillPath -Raw
        if ($text -notmatch '^---\s*\r?\nname:\s*[-a-z0-9]+\s*\r?\ndescription:') {
            $issues += "$($dir.Name): invalid basic frontmatter"
        }
    }

    $skillMarkdownFiles = Get-ChildItem -LiteralPath $SkillsRoot -Filter '*.md' -File -Recurse
    foreach ($file in $skillMarkdownFiles) {
        $text = Get-Content -LiteralPath $file.FullName -Raw
        $matches = [regex]::Matches($text, '\]\(\.\./([^\)]+/(?:SKILL|MODULE)\.md)\)')
        foreach ($match in $matches) {
            $targetPath = Join-Path (Split-Path -Parent $file.FullName) ('..\' + $match.Groups[1].Value.Replace('/', '\'))
            if (-not (Test-Path -LiteralPath $targetPath)) {
                $issues += "$($file.Directory.Name)/$($file.Name): broken link ../$($match.Groups[1].Value)"
            }
        }
    }

    if ($issues.Count -gt 0) {
        return @{
            status = 'fail'
            message = ($issues -join '; ')
        }
    }

    return @{
        status = 'pass'
        message = "${Label} internal modules OK for $(($dirs | Where-Object { $_.Name -notin $ExcludeDirNames }).Count) module dir(s)."
    }
}

function suimiTest-FinalFeedbackContract {
    param([string]$RootDir)

    $requiredPatterns = @(
        '新技能/方法反馈',
        'finish_skill_run\.ps1',
        'record_skill_lesson\.ps1',
        'review_skill_lessons\.ps1',
        'promote_skill_lesson\.ps1'
    )

    $paths = @()
    $paths += Join-Path $RootDir 'SKILL.md'
    $paths += Join-Path $RootDir 'CLAUDE.md'
    $paths += Join-Path $RootDir 'AGENTS.md'
    $paths += Join-Path $RootDir 'references\skill-learning-loop.md'
    $paths += Join-Path $RootDir 'references\reusable-invocation-contract.md'

    $skillRoots = @()
    $skillRoots += Join-Path $RootDir 'github-reverse-modules\skills'
    $skillRoots += Join-Path $RootDir 'security-research-modules\skills'
    foreach ($skillRoot in $skillRoots) {
        if (-not (Test-Path -LiteralPath $skillRoot)) {
            continue
        }
        $paths += Get-ChildItem -LiteralPath $skillRoot -Filter 'MODULE.md' -File -Recurse |
            Where-Object { $_.FullName -notmatch '\\scripts\\' } |
            Select-Object -ExpandProperty FullName
    }

    $issues = @()
    $resolvedRoot = (Resolve-Path -LiteralPath $RootDir).Path.TrimEnd('\', '/')
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            $issues += "missing: $path"
            continue
        }

        $text = Get-Content -LiteralPath $path -Raw
        $missing = @()
        foreach ($pattern in $requiredPatterns) {
            if ($text -notmatch $pattern) {
                $missing += $pattern.Replace('\.', '.')
            }
        }
        if ($missing.Count -gt 0) {
            $resolvedPath = (Resolve-Path -LiteralPath $path).Path
            $relativePath = $resolvedPath.Substring($resolvedRoot.Length).TrimStart('\', '/').Replace('\', '/')
            $issues += "$relativePath missing final feedback contract token(s): $($missing -join ', ')"
        }
    }

    if ($issues.Count -gt 0) {
        return @{
            status = 'fail'
            message = ($issues -join '; ')
        }
    }

    return @{
        status = 'pass'
        message = "Mandatory final feedback contract OK for $($paths.Count) file(s)."
    }
}

function suimiTest-SingleInstallableSkill {
    param([string]$RootDir)

    $skillFiles = @(Get-ChildItem -LiteralPath $RootDir -Filter 'SKILL.md' -File -Recurse |
        Where-Object { $_.FullName -notmatch '\\scripts\\' })
    $resolvedRoot = (Resolve-Path -LiteralPath $RootDir).Path.TrimEnd('\', '/')
    $relativeSkillFiles = @($skillFiles | ForEach-Object {
        $resolvedPath = (Resolve-Path -LiteralPath $_.FullName).Path
        $resolvedPath.Substring($resolvedRoot.Length).TrimStart('\', '/').Replace('\', '/')
    })

    if ($relativeSkillFiles.Count -ne 1 -or $relativeSkillFiles[0] -ne 'SKILL.md') {
        return @{
            status = 'fail'
            message = "Expected exactly one installable SKILL.md at root; found: $($relativeSkillFiles -join '; ')"
        }
    }

    $moduleFiles = @(Get-ChildItem -LiteralPath $RootDir -Filter 'MODULE.md' -File -Recurse |
        Where-Object { $_.FullName -match '\\(github-reverse-modules|security-research-modules|local-reverse-modules)\\skills\\' })
    if ($moduleFiles.Count -lt 1) {
        return @{
            status = 'fail'
            message = 'No internal MODULE.md files found.'
        }
    }

    return @{
        status = 'pass'
        message = "Single installable skill OK: root SKILL.md plus $($moduleFiles.Count) internal module file(s)."
    }
}

function suimiTest-ChineseSkillNames {
    param([string]$RootDir)

    $syncScript = Join-Path $RootDir 'scripts\suimi_sync_chinese_skill_names.ps1'
    if (-not (Test-Path -LiteralPath $syncScript)) {
        return @{
            status = 'fail'
            message = 'Chinese skill name sync script is missing.'
        }
    }

    $json = & $syncScript -CheckOnly -AsJson
    $info = $json | ConvertFrom-Json
    if ($info.ok) {
        return @{
            status = 'pass'
            message = "Chinese display names OK for $($info.total) module entry file(s)."
        }
    }

    return @{
        status = 'fail'
        message = "Chinese skill names need sync: missing=$($info.missing), pending=$($info.pending)."
    }
}

function suimiTest-ManifestPaths {
    param(
        [string]$RootDir,
        [object]$Manifest
    )

    $issues = @()
    $checked = 0
    $normalizedRoot = (Resolve-Path -LiteralPath $RootDir).Path.TrimEnd('\', '/')

    $entries = @()
    if ($Manifest.entrypoints) {
        foreach ($prop in $Manifest.entrypoints.PSObject.Properties) {
            if ($prop.Value) {
                $entries += [pscustomobject]@{
                    kind = "entrypoint:$($prop.Name)"
                    path = [string]$prop.Value
                }
            }
        }
    } else {
        $issues += 'manifest.entrypoints is missing'
    }

    foreach ($path in @($Manifest.references)) {
        if ($path) {
            $entries += [pscustomobject]@{
                kind = 'reference'
                path = [string]$path
            }
        }
    }

    foreach ($path in @($Manifest.scripts)) {
        if ($path) {
            $entries += [pscustomobject]@{
                kind = 'script'
                path = [string]$path
            }
        }
    }

    foreach ($entry in $entries) {
        $relativePath = $entry.path
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            $issues += "$($entry.kind): empty path"
            continue
        }
        if ($relativePath -match '(^[A-Za-z]:\\)|(^\\\\)|(^/)') {
            $issues += "$($entry.kind): absolute path is not portable: $relativePath"
            continue
        }

        $fullPath = Join-Path $RootDir $relativePath
        if (-not (Test-Path -LiteralPath $fullPath)) {
            $issues += "$($entry.kind): missing $relativePath"
            continue
        }

        $resolved = (Resolve-Path -LiteralPath $fullPath).Path
        if (-not $resolved.StartsWith($normalizedRoot, [StringComparison]::OrdinalIgnoreCase)) {
            $issues += "$($entry.kind): path escapes project root: $relativePath"
            continue
        }

        $checked += 1
    }

    if ($issues.Count -gt 0) {
        return @{
            status = 'fail'
            message = ($issues -join '; ')
        }
    }

    return @{
        status = 'pass'
        message = "Manifest paths OK for $checked entrypoint/reference/script item(s)."
    }
}

function suimiTest-SkillRegistry {
    param([string]$RootDir)

    $listScript = Join-Path $RootDir 'scripts\list_skills.ps1'
    if (-not (Test-Path -LiteralPath $listScript)) {
        return @{
            status = 'fail'
            message = 'Reusable skill registry script is missing.'
        }
    }

    $json = & $listScript -AsJson
    if ($LASTEXITCODE -ne 0) {
        return @{
            status = 'fail'
            message = 'Reusable skill registry script returned a non-zero exit code.'
        }
    }

    $info = $json | ConvertFrom-Json
    if (-not $info.ok) {
        return @{
            status = 'fail'
            message = "Reusable skill registry has missing metadata: $($info.missing_metadata)."
        }
    }

    $placeholderDescriptions = @($info.skills | Where-Object {
        $description = ([string]$_.description).Trim()
        $description -in @('|', '>', '|-', '>-', '|+', '>+')
    })
    if ($placeholderDescriptions.Count -gt 0) {
        $paths = @($placeholderDescriptions | Select-Object -ExpandProperty path)
        return @{
            status = 'fail'
            message = "Reusable skill registry has placeholder descriptions: $($paths -join '; ')."
        }
    }

    $actualSkillFiles = @()
    $actualSkillFiles += Join-Path $RootDir 'SKILL.md'
    $actualSkillFiles += Get-ChildItem -LiteralPath (Join-Path $RootDir 'github-reverse-modules\skills') -Filter 'MODULE.md' -File -Recurse | Select-Object -ExpandProperty FullName
    $localSkillsRoot = Join-Path $RootDir 'local-reverse-modules\skills'
    if (Test-Path -LiteralPath $localSkillsRoot) {
        $actualSkillFiles += Get-ChildItem -LiteralPath $localSkillsRoot -Filter 'MODULE.md' -File -Recurse | Select-Object -ExpandProperty FullName
    }
    $actualSkillFiles += Get-ChildItem -LiteralPath (Join-Path $RootDir 'security-research-modules\skills') -Filter 'MODULE.md' -File -Recurse | Select-Object -ExpandProperty FullName

    if ($info.count -ne $actualSkillFiles.Count) {
        return @{
            status = 'fail'
            message = "Reusable skill registry count mismatch: registry=$($info.count), files=$($actualSkillFiles.Count)."
        }
    }

    return @{
        status = 'pass'
        message = "Reusable module registry OK for $($info.count) entry file(s)."
    }
}

function suimiTest-CrossReferenceCompleteness {
    param([string]$RootDir)

    $issues = @()

    $listScript = Join-Path $RootDir 'scripts\list_skills.ps1'
    $registryJson = & $listScript -AsJson
    if ($LASTEXITCODE -ne 0) {
        return @{
            status = 'fail'
            message = 'Cross-reference completeness check could not load the skill registry.'
        }
    }
    $registry = $registryJson | ConvertFrom-Json
    $allPaths = @($registry.skills | ForEach-Object { [string]$_.path })
    $allNames = @($registry.skills | ForEach-Object { [string]$_.name })

    $unifiedPath = Join-Path $RootDir 'references\unified-skills-entry.md'
    $unifiedText = Get-Content -LiteralPath $unifiedPath -Raw
    $missingFromUnified = @($allPaths | Where-Object { $_ -ne 'SKILL.md' -and $unifiedText -notmatch [regex]::Escape($_) })
    foreach ($missingPath in $missingFromUnified) {
        $issues += "unified-skills-entry.md missing path: $missingPath"
    }

    $ghSkillsRoot = Join-Path $RootDir 'github-reverse-modules\skills'
    $ghDirs = @(Get-ChildItem -LiteralPath $ghSkillsRoot -Directory | Where-Object { $_.Name -ne 'scripts' } | Select-Object -ExpandProperty Name)
    $ghIndexText = Get-Content -LiteralPath (Join-Path $RootDir 'github-reverse-modules\INDEX.md') -Raw
    foreach ($dirName in $ghDirs) {
        if ($ghIndexText -notmatch [regex]::Escape("skills/$dirName/")) {
            $issues += "github-reverse-modules/INDEX.md missing module dir: $dirName"
        }
    }

    $skillMdText = Get-Content -LiteralPath (Join-Path $RootDir 'SKILL.md') -Raw
    foreach ($dirName in $ghDirs) {
        if ($skillMdText -notmatch [regex]::Escape("skills/$dirName/MODULE.md")) {
            $issues += "SKILL.md Added Reverse Modules list missing: $dirName"
        }
    }

    $secSkillsRoot = Join-Path $RootDir 'security-research-modules\skills'
    $secDirs = @(Get-ChildItem -LiteralPath $secSkillsRoot -Directory | Select-Object -ExpandProperty Name)
    $secIndexText = Get-Content -LiteralPath (Join-Path $RootDir 'security-research-modules\INDEX.md') -Raw
    foreach ($dirName in $secDirs) {
        if ($secIndexText -notmatch ('`' + [regex]::Escape($dirName) + '`')) {
            $issues += "security-research-modules/INDEX.md missing module dir: $dirName"
        }
    }

    $localSkillsRoot = Join-Path $RootDir 'local-reverse-modules\skills'
    if (Test-Path -LiteralPath $localSkillsRoot) {
        $localDirs = @(Get-ChildItem -LiteralPath $localSkillsRoot -Directory | Where-Object { $_.Name -ne 'scripts' } | Select-Object -ExpandProperty Name)
        $localIndexPath = Join-Path $RootDir 'local-reverse-modules\INDEX.md'
        if (-not (Test-Path -LiteralPath $localIndexPath)) {
            $issues += 'local-reverse-modules/INDEX.md is missing'
        } else {
            $localIndexText = Get-Content -LiteralPath $localIndexPath -Raw
            foreach ($dirName in $localDirs) {
                if ($localIndexText -notmatch [regex]::Escape("skills/$dirName/")) {
                    $issues += "local-reverse-modules/INDEX.md missing module dir: $dirName"
                }
            }
        }

        $localSectionMatch = [regex]::Match($skillMdText, '(?ms)^##\s+Added Local Reverse Modules\b.*?(?=^##\s|\z)')
        $localSectionText = if ($localSectionMatch.Success) { $localSectionMatch.Value } else { '' }
        foreach ($dirName in $localDirs) {
            if ($localSectionText -notmatch [regex]::Escape("local-reverse-modules/skills/$dirName/MODULE.md")) {
                $issues += "SKILL.md Added Local Reverse Modules list missing: $dirName"
            }
        }
    }

    $routers = @('hack', 'recon-for-sec', 'api-sec', 'auth-sec', 'injection-checking', 'file-access-vuln', 'business-logic-vuln', 'ctf-sandbox-orchestrator')
    $routerLinkedNames = @()
    foreach ($routerName in $routers) {
        $routerFile = Join-Path $secSkillsRoot "$routerName\MODULE.md"
        if (Test-Path -LiteralPath $routerFile) {
            $routerText = Get-Content -LiteralPath $routerFile -Raw
            $links = [regex]::Matches($routerText, '\]\(\.\./([a-z0-9\-]+)/MODULE\.md\)') | ForEach-Object { $_.Groups[1].Value }
            $routerLinkedNames += $links
        }
    }
    $routerLinkedNames = @($routerLinkedNames | Select-Object -Unique)
    $secDetailDirs = @($secDirs | Where-Object { $_ -notin $routers })
    $orphanSecModules = @($secDetailDirs | Where-Object { $_ -notin $routerLinkedNames })
    foreach ($orphanName in $orphanSecModules) {
        $issues += "security-research-modules module not linked from any P1 router Skill Map: $orphanName"
    }

    $routingRulesPath = Join-Path $RootDir 'scripts\routing-rules.json'
    $ruleNames = @()
    if (-not (Test-Path -LiteralPath $routingRulesPath)) {
        $issues += 'scripts/routing-rules.json is missing'
    } else {
        $routingRulesRaw = [System.IO.File]::ReadAllText($routingRulesPath, [System.Text.Encoding]::UTF8)
        $parsedRoutingRules = $routingRulesRaw | ConvertFrom-Json
        $routingRules = @($parsedRoutingRules)
        $ruleNames = @($routingRules | ForEach-Object { [string]$_.name })
        $deadRuleRefs = @($ruleNames | Where-Object { $_ -notin $allNames } | Select-Object -Unique)
        foreach ($deadName in $deadRuleRefs) {
            $issues += "routing-rules.json rule references unknown skill name: $deadName"
        }
        $incompleteRules = @($routingRules | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.name) -or [string]::IsNullOrWhiteSpace([string]$_.pattern) -or [string]::IsNullOrWhiteSpace([string]$_.reason) -or ($null -eq $_.confidence) })
        foreach ($incompleteRule in $incompleteRules) {
            $issues += "routing-rules.json rule has incomplete fields: $([string]$incompleteRule.name)"
        }
    }

    if ($issues.Count -gt 0) {
        return @{
            status = 'fail'
            message = ($issues -join '; ')
        }
    }

    return @{
        status = 'pass'
        message = "Cross-reference completeness OK: unified-skills-entry.md, INDEX.md (all three trees), SKILL.md module lists, $($secDetailDirs.Count) Skill-Map-linked detail modules, and $($ruleNames.Count) routing-rules.json rule refs are all consistent with the registry."
    }
}

function suimiTest-SkillResolver {
    param([string]$RootDir)

    $resolveScript = Join-Path $RootDir 'scripts\resolve_skill.ps1'
    if (-not (Test-Path -LiteralPath $resolveScript)) {
        return @{
            status = 'fail'
            message = 'Reusable skill resolver script is missing.'
        }
    }

    $cases = @(
        [pscustomobject]@{
            query = 'mobile-reverse'
            category = 'all'
            path = 'github-reverse-modules/skills/mobile-reverse/MODULE.md'
        },
        [pscustomobject]@{
            query = 'radare2'
            category = 'github-reverse'
            path = 'github-reverse-modules/skills/radare2/MODULE.md'
        },
        [pscustomobject]@{
            query = 'security-research-modules/skills/hack/MODULE.md'
            category = 'security'
            path = 'security-research-modules/skills/hack/MODULE.md'
        }
    )

    $issues = @()
    foreach ($case in $cases) {
        $json = & $resolveScript -Query $case.query -Category $case.category -AsJson
        if ($LASTEXITCODE -ne 0) {
            $issues += "$($case.query): resolver returned non-zero exit code"
            continue
        }

        try {
            $result = $json | ConvertFrom-Json
        } catch {
            $issues += "$($case.query): resolver returned invalid JSON"
            continue
        }

        if (-not $result.ok) {
            $issues += "$($case.query): resolver status is $($result.status)"
        } elseif ($result.skill.path -ne $case.path) {
            $issues += "$($case.query): expected $($case.path), got $($result.skill.path)"
        }
    }

    if ($issues.Count -gt 0) {
        return @{
            status = 'fail'
            message = ($issues -join '; ')
        }
    }

    return @{
        status = 'pass'
        message = "Reusable skill resolver OK for $($cases.Count) case(s)."
    }
}

function suimiTest-SkillSelector {
    param([string]$RootDir)

    $selectScript = Join-Path $RootDir 'scripts\select_skill.ps1'
    if (-not (Test-Path -LiteralPath $selectScript)) {
        return @{
            status = 'fail'
            message = 'Reusable skill selector script is missing.'
        }
    }

    $cases = @(
        [pscustomobject]@{
            task = 'mobile frida apk analysis'
            target = $RootDir
            path = 'github-reverse-modules/skills/mobile-reverse/MODULE.md'
        },
        [pscustomobject]@{
            task = 'SQL injection parameter test'
            target = ''
            path = 'security-research-modules/skills/sqli-sql-injection/MODULE.md'
        },
        [pscustomobject]@{
            task = 'REST API BOLA object authorization review'
            target = ''
            path = 'security-research-modules/skills/idor-broken-object-authorization/MODULE.md'
        },
        [pscustomobject]@{
            task = 'REST API BOLA object authorization and JWT token review'
            target = ''
            path = 'security-research-modules/skills/api-sec/MODULE.md'
        },
        [pscustomobject]@{
            task = 'firmware unpack and static analysis'
            target = ''
            path = 'github-reverse-modules/skills/reverse-engineering/MODULE.md'
        },
        [pscustomobject]@{
            task = 'help me attach to this process and set a breakpoint to inspect the arguments'
            target = ''
            path = 'github-reverse-modules/skills/x64dbg-reverse/MODULE.md'
        }
    )

    $issues = @()
    foreach ($case in $cases) {
        if ([string]::IsNullOrWhiteSpace([string]$case.target)) {
            $json = & $selectScript -TaskText $case.task -AsJson
        } else {
            $json = & $selectScript -TaskText $case.task -TargetPath $case.target -AsJson
        }

        if ($LASTEXITCODE -ne 0) {
            $issues += "$($case.task): selector returned non-zero exit code"
            continue
        }

        try {
            $result = $json | ConvertFrom-Json
        } catch {
            $issues += "$($case.task): selector returned invalid JSON"
            continue
        }

        if (-not $result.ok) {
            $issues += "$($case.task): selector status is $($result.status)"
        } elseif ($result.skill.path -ne $case.path) {
            $issues += "$($case.task): expected $($case.path), got $($result.skill.path)"
        }
    }

    if ($issues.Count -gt 0) {
        return @{
            status = 'fail'
            message = ($issues -join '; ')
        }
    }

    return @{
        status = 'pass'
        message = "Reusable skill selector OK for $($cases.Count) case(s)."
    }
}

function suimiTest-FixedEntrypoint {
    param([string]$RootDir)

    $invokeScript = Join-Path $RootDir 'scripts\invoke_skill.ps1'
    if (-not (Test-Path -LiteralPath $invokeScript)) {
        return @{
            status = 'fail'
            message = 'Fixed reusable skill entrypoint script is missing.'
        }
    }

    $cases = @(
        [pscustomobject]@{
            task = 'SQL injection parameter test'
            target = ''
            output = 'path'
            expected = 'security-research-modules/skills/sqli-sql-injection/MODULE.md'
        },
        [pscustomobject]@{
            task = 'mobile frida apk analysis'
            target = $RootDir
            output = 'path'
            expected = 'github-reverse-modules/skills/mobile-reverse/MODULE.md'
        },
        [pscustomobject]@{
            task = 'firmware unpack and static analysis'
            target = ''
            output = 'path'
            expected = 'github-reverse-modules/skills/reverse-engineering/MODULE.md'
        }
    )

    $issues = @()
    foreach ($case in $cases) {
        if ([string]::IsNullOrWhiteSpace([string]$case.target)) {
            $output = & $invokeScript -TaskText $case.task -Output $case.output
        } else {
            $output = & $invokeScript -TaskText $case.task -TargetPath $case.target -Output $case.output
        }

        if ($LASTEXITCODE -ne 0) {
            $issues += "$($case.task): fixed entrypoint returned non-zero exit code"
            continue
        }

        $actual = ([string]$output).Trim().Replace('\', '/')
        if ($actual -ne $case.expected) {
            $issues += "$($case.task): expected $($case.expected), got $actual"
        }
    }

    $json = & $invokeScript -TaskText 'REST API BOLA object authorization review' -AsJson
    if ($LASTEXITCODE -ne 0) {
        $issues += 'fixed entrypoint JSON mode returned non-zero exit code'
    } else {
        try {
            $result = $json | ConvertFrom-Json
            if (-not $result.ok -or $result.skill_path -ne 'security-research-modules/skills/idor-broken-object-authorization/MODULE.md') {
                $issues += "fixed entrypoint JSON mode selected unexpected skill: $($result.skill_path)"
            }
        } catch {
            $issues += 'fixed entrypoint JSON mode returned invalid JSON'
        }
    }

    $mixedJson = & $invokeScript -TaskText 'REST API BOLA object authorization and JWT token review' -AsJson
    if ($LASTEXITCODE -ne 0) {
        $issues += 'fixed entrypoint mixed-security JSON mode returned non-zero exit code'
    } else {
        try {
            $mixedResult = $mixedJson | ConvertFrom-Json
            if (-not $mixedResult.ok -or $mixedResult.skill_path -ne 'security-research-modules/skills/api-sec/MODULE.md') {
                $issues += "fixed entrypoint mixed-security JSON mode selected unexpected skill: $($mixedResult.skill_path)"
            }
            $mixedCandidatePaths = @($mixedResult.candidates | ForEach-Object { $_.path })
            if (
                'security-research-modules/skills/idor-broken-object-authorization/MODULE.md' -notin $mixedCandidatePaths -or
                'security-research-modules/skills/api-auth-and-jwt-abuse/MODULE.md' -notin $mixedCandidatePaths
            ) {
                $issues += 'fixed entrypoint mixed-security JSON mode did not preserve concrete security candidates'
            }
        } catch {
            $issues += 'fixed entrypoint mixed-security JSON mode returned invalid JSON'
        }
    }

    if ($issues.Count -gt 0) {
        return @{
            status = 'fail'
            message = ($issues -join '; ')
        }
    }

    return @{
        status = 'pass'
        message = "Fixed reusable entrypoint OK for $($cases.Count + 2) case(s)."
    }
}

function suimiTest-RouteRegression {
    param([string]$RootDir)

    $entryScript = Join-Path $RootDir 'scripts\re_workflow_entry.ps1'
    if (-not (Test-Path -LiteralPath $entryScript)) {
        return @{
            status = 'fail'
            message = 'Reverse workflow entry script is missing.'
        }
    }

    $cases = @(
        [pscustomobject]@{
            name = 'directory-default'
            target = $RootDir
            intent = 'auto'
            task = 'analyze project'
            route = 'directory-manual'
            module = 'references/reverse-task-recipes.md'
        },
        [pscustomobject]@{
            name = 'mobile-module'
            target = $RootDir
            intent = 'auto'
            task = 'mobile frida apk analysis'
            route = 'mobile-reverse-manual'
            module = 'github-reverse-modules/skills/mobile-reverse/MODULE.md'
        },
        [pscustomobject]@{
            name = 'radare2-module'
            target = $RootDir
            intent = 'auto'
            task = 'radare2 r2 command line reverse'
            route = 'radare2-manual'
            module = 'github-reverse-modules/skills/radare2/MODULE.md'
        }
    )

    $issues = @()
    foreach ($case in $cases) {
        $json = & $entryScript -TargetPath $case.target -Intent $case.intent -TaskText $case.task -NoExecute -AsJson
        if ($LASTEXITCODE -ne 0) {
            $issues += "$($case.name): entry script returned non-zero exit code"
            continue
        }

        try {
            $decision = $json | ConvertFrom-Json
        } catch {
            $issues += "$($case.name): entry script returned invalid JSON"
            continue
        }

        if ($decision.route -ne $case.route) {
            $issues += "$($case.name): expected route $($case.route), got $($decision.route)"
        }
        if ($decision.module_entry -ne $case.module) {
            $issues += "$($case.name): expected module $($case.module), got $($decision.module_entry)"
        }
        if ([string]::IsNullOrWhiteSpace([string]$decision.next_action)) {
            $issues += "$($case.name): next_action is empty"
        }
    }

    if ($issues.Count -gt 0) {
        return @{
            status = 'fail'
            message = ($issues -join '; ')
        }
    }

    return @{
        status = 'pass'
        message = "Reusable route regressions OK for $($cases.Count) case(s)."
    }
}

function suimiTest-SkillLearningLoop {
    param([string]$RootDir)

    $reviewScript = Join-Path $RootDir 'scripts\review_skill_lessons.ps1'
    $recordScript = Join-Path $RootDir 'scripts\record_skill_lesson.ps1'
    $pendingScript = Join-Path $RootDir 'scripts\pending_skill_lessons.ps1'
    $finishScript = Join-Path $RootDir 'scripts\finish_skill_run.ps1'
    $promoteScript = Join-Path $RootDir 'scripts\promote_skill_lesson.ps1'
    $libraryScript = Join-Path $RootDir 'scripts\lib\SkillLearning.ps1'

    foreach ($path in @($reviewScript, $recordScript, $pendingScript, $finishScript, $promoteScript, $libraryScript)) {
        if (-not (Test-Path -LiteralPath $path)) {
            return @{
                status = 'fail'
                message = "Skill learning file is missing: $path"
            }
        }
    }

    $pendingJson = & $pendingScript -AsJson
    if ($LASTEXITCODE -ne 0) {
        return @{
            status = 'fail'
            message = 'Pending skill lessons script returned a non-zero exit code.'
        }
    }
    try {
        $pendingResult = $pendingJson | ConvertFrom-Json
    } catch {
        return @{
            status = 'fail'
            message = 'Pending skill lessons script returned invalid JSON.'
        }
    }
    if (-not $pendingResult.ok) {
        return @{
            status = 'fail'
            message = 'Pending skill lessons script did not report ok=true.'
        }
    }

    $finishJson = & $finishScript -AsJson
    if ($LASTEXITCODE -ne 0) {
        return @{
            status = 'fail'
            message = 'Finish skill run script returned a non-zero exit code.'
        }
    }
    try {
        $finishResult = $finishJson | ConvertFrom-Json
    } catch {
        return @{
            status = 'fail'
            message = 'Finish skill run script returned invalid JSON.'
        }
    }
    if (-not $finishResult.ok -or $finishResult.required_final_section_title -ne '新技能/方法反馈') {
        return @{
            status = 'fail'
            message = 'Finish skill run script did not report the required final feedback contract.'
        }
    }
    if ($null -eq $finishResult.discovered_new_skill_count -or $null -eq $finishResult.discovered_new_skill_titles) {
        return @{
            status = 'fail'
            message = 'Finish skill run script is missing explicit discovered lesson count/list fields.'
        }
    }
    $allowedDefaultRecommendations = @('no', 'review')
    if ($finishResult.discovered_new_skill -or $finishResult.discovered_new_skill_count -ne 0 -or $finishResult.suggested_add_count -ne 0 -or $finishResult.recommendation -notin $allowedDefaultRecommendations) {
        return @{
            status = 'fail'
            message = 'Finish skill run default report should declare zero current-run lessons and recommendation=no or review.'
        }
    }

    $finishPositiveJson = & $finishScript -NewLessonCount 1 -SuggestedTitle 'healthcheck learning contract probe' -AsJson
    if ($LASTEXITCODE -ne 0) {
        return @{
            status = 'fail'
            message = 'Finish skill run positive regression returned a non-zero exit code.'
        }
    }
    try {
        $finishPositiveResult = $finishPositiveJson | ConvertFrom-Json
    } catch {
        return @{
            status = 'fail'
            message = 'Finish skill run positive regression returned invalid JSON.'
        }
    }
    if (-not $finishPositiveResult.discovered_new_skill -or $finishPositiveResult.discovered_new_skill_count -ne 1 -or $finishPositiveResult.suggested_add_count -ne 1 -or $finishPositiveResult.recommendation -ne 'yes') {
        return @{
            status = 'fail'
            message = 'Finish skill run positive regression should declare one new lesson and recommendation=yes.'
        }
    }

    $reviewJson = & $reviewScript -AsJson
    $reviewExitCode = $LASTEXITCODE
    try {
        $reviewResult = $reviewJson | ConvertFrom-Json
    } catch {
        return @{
            status = 'fail'
            message = 'Skill learning inbox review returned invalid JSON.'
        }
    }

    if ($reviewExitCode -ne 0 -or -not $reviewResult.ok) {
        return @{
            status = 'fail'
            message = "Skill learning inbox has blocking issue(s): errors=$($reviewResult.errors), warnings=$($reviewResult.warnings)."
        }
    }

    $message = "Skill learning loop OK: inbox entries=$($reviewResult.count), warnings=$($reviewResult.warnings)."
    if ($reviewResult.warnings -gt 0) {
        return @{
            status = 'warn'
            message = $message
        }
    }

    return @{
        status = 'pass'
        message = $message
    }
}

function suimiTest-InstalledSkillSync {
    param([string]$RootDir)

    $syncScript = Join-Path $RootDir 'scripts\sync_installed_skill.ps1'
    if (-not (Test-Path -LiteralPath $syncScript)) {
        return @{
            status = 'fail'
            message = 'Installed skill sync script is missing.'
        }
    }

    $json = & $syncScript -DryRun -SkipHealthcheck -AsJson
    if ($LASTEXITCODE -ne 0) {
        return @{
            status = 'fail'
            message = 'Installed skill sync dry-run returned a non-zero exit code.'
        }
    }
    try {
        $result = $json | ConvertFrom-Json
    } catch {
        return @{
            status = 'fail'
            message = 'Installed skill sync dry-run returned invalid JSON.'
        }
    }
    if (-not $result.ok -or $result.action -notin @('would-sync', 'no-op')) {
        return @{
            status = 'fail'
            message = "Installed skill sync dry-run reported unexpected action: $($result.action)"
        }
    }

    return @{
        status = 'pass'
        message = "Installed skill sync dry-run OK: action=$($result.action)."
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..')).Path
$checks = @()

Push-Location $rootDir
try {
    $manifestPath = Join-Path $rootDir 'manifest.json'
    try {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        suimiAdd-Check (suimiNew-Check -Name 'manifest' -Status 'pass' -Message "manifest.json OK: $($manifest.name) $($manifest.version)")
        $manifestPathResult = suimiTest-ManifestPaths -RootDir $rootDir -Manifest $manifest
        suimiAdd-Check (suimiNew-Check -Name 'manifest-paths' -Status $manifestPathResult.status -Message $manifestPathResult.message)
    } catch {
        suimiAdd-Check (suimiNew-Check -Name 'manifest' -Status 'fail' -Message "manifest.json invalid: $($_.Exception.Message)")
    }

    $securitySkillResult = suimiTest-MarkdownSkillModules -SkillsRoot (Join-Path $rootDir 'security-research-modules\skills') -Label 'Security research'
    suimiAdd-Check (suimiNew-Check -Name 'security-skill-modules' -Status $securitySkillResult.status -Message $securitySkillResult.message)

    $githubReverseSkillResult = suimiTest-MarkdownSkillModules -SkillsRoot (Join-Path $rootDir 'github-reverse-modules\skills') -Label 'GitHub reverse' -ExcludeDirNames @('scripts')
    suimiAdd-Check (suimiNew-Check -Name 'github-re-workflow-modules' -Status $githubReverseSkillResult.status -Message $githubReverseSkillResult.message)

    $localReverseRoot = Join-Path $rootDir 'local-reverse-modules\skills'
    if (Test-Path -LiteralPath $localReverseRoot) {
        $localReverseSkillResult = suimiTest-MarkdownSkillModules -SkillsRoot $localReverseRoot -Label 'Local reverse'
        suimiAdd-Check (suimiNew-Check -Name 'local-re-workflow-modules' -Status $localReverseSkillResult.status -Message $localReverseSkillResult.message)
    } else {
        suimiAdd-Check (suimiNew-Check -Name 'local-re-workflow-modules' -Status 'pass' -Message 'No local reverse skill modules configured.')
    }

    $skillRegistryResult = suimiTest-SkillRegistry -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'reusable-skill-registry' -Status $skillRegistryResult.status -Message $skillRegistryResult.message)

    $crossReferenceResult = suimiTest-CrossReferenceCompleteness -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'cross-reference-completeness' -Status $crossReferenceResult.status -Message $crossReferenceResult.message)

    $skillResolverResult = suimiTest-SkillResolver -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'reusable-skill-resolver' -Status $skillResolverResult.status -Message $skillResolverResult.message)

    $skillSelectorResult = suimiTest-SkillSelector -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'reusable-skill-selector' -Status $skillSelectorResult.status -Message $skillSelectorResult.message)

    $fixedEntrypointResult = suimiTest-FixedEntrypoint -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'fixed-reusable-entrypoint' -Status $fixedEntrypointResult.status -Message $fixedEntrypointResult.message)

    $routeRegressionResult = suimiTest-RouteRegression -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'reusable-route-regressions' -Status $routeRegressionResult.status -Message $routeRegressionResult.message)

    $skillLearningResult = suimiTest-SkillLearningLoop -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'skill-learning-loop' -Status $skillLearningResult.status -Message $skillLearningResult.message)

    $installedSkillSyncResult = suimiTest-InstalledSkillSync -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'installed-skill-sync' -Status $installedSkillSyncResult.status -Message $installedSkillSyncResult.message)

    $singleInstallableSkillResult = suimiTest-SingleInstallableSkill -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'single-installable-skill' -Status $singleInstallableSkillResult.status -Message $singleInstallableSkillResult.message)

    $finalFeedbackContractResult = suimiTest-FinalFeedbackContract -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'mandatory-final-feedback-contract' -Status $finalFeedbackContractResult.status -Message $finalFeedbackContractResult.message)

    $chineseSkillNameResult = suimiTest-ChineseSkillNames -RootDir $rootDir
    suimiAdd-Check (suimiNew-Check -Name 'chinese-skill-names' -Status $chineseSkillNameResult.status -Message $chineseSkillNameResult.message)

    $psFiles = Get-ChildItem -LiteralPath (Join-Path $rootDir 'scripts') -Filter '*.ps1' -File -Recurse | Select-Object -ExpandProperty FullName
    $psError = suimiTest-PowerShellSyntax -Paths $psFiles
    if ($psError) {
        suimiAdd-Check (suimiNew-Check -Name 'powershell-syntax' -Status 'fail' -Message $psError)
    } else {
        suimiAdd-Check (suimiNew-Check -Name 'powershell-syntax' -Status 'pass' -Message "PowerShell syntax OK for $($psFiles.Count) file(s).")
    }

    $testsRunner = Join-Path $rootDir 'tests\run_tests.ps1'
    if (Test-Path -LiteralPath $testsRunner) {
        $testOutput = & $testsRunner -Quiet
        $testExitCode = $LASTEXITCODE
        if ($testExitCode -eq 0 -and $testOutput -match '^PASS:') {
            suimiAdd-Check (suimiNew-Check -Name 'unit-tests' -Status 'pass' -Message $testOutput)
        } elseif ($testExitCode -eq 0 -and $testOutput -match '^SKIP:') {
            suimiAdd-Check (suimiNew-Check -Name 'unit-tests' -Status 'warn' -Message $testOutput)
        } else {
            suimiAdd-Check (suimiNew-Check -Name 'unit-tests' -Status 'fail' -Message $testOutput)
        }
    } else {
        suimiAdd-Check (suimiNew-Check -Name 'unit-tests' -Status 'skip' -Message 'No tests directory found.')
    }

    $pyFiles = Get-ChildItem -LiteralPath (Join-Path $rootDir 'scripts') -Filter '*.py' -File | Select-Object -ExpandProperty FullName
    $pyResult = suimiTest-PythonSyntax -Paths $pyFiles
    suimiAdd-Check (suimiNew-Check -Name 'python-syntax' -Status $pyResult.status -Message $pyResult.message)

    $bashFiles = @()
    $bashFiles += Get-ChildItem -LiteralPath (Join-Path $rootDir 'scripts') -Filter '*.sh' -File | Select-Object -ExpandProperty FullName
    $localReverseModulesRoot = Join-Path $rootDir 'local-reverse-modules'
    if (Test-Path -LiteralPath $localReverseModulesRoot) {
        $bashFiles += Get-ChildItem -LiteralPath $localReverseModulesRoot -Filter '*.sh' -File -Recurse | Select-Object -ExpandProperty FullName
    }
    $bashResult = suimiTest-BashSyntax -RootDir $rootDir -Paths $bashFiles
    suimiAdd-Check (suimiNew-Check -Name 'bash-syntax' -Status $bashResult.status -Message $bashResult.message)

    $bashCommand = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($bashCommand) {
        suimiAdd-Check (suimiNew-Check -Name 'bash-available' -Status 'pass' -Message "Optional bash.exe found: $($bashCommand.Source)")
    } else {
        suimiAdd-Check (suimiNew-Check -Name 'bash-available' -Status 'pass' -Message 'Optional bash.exe not found on PATH.')
    }

    $wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if ($wslCommand) {
        suimiAdd-Check (suimiNew-Check -Name 'wsl-available' -Status 'pass' -Message "Optional wsl.exe found: $($wslCommand.Source)")
    } else {
        suimiAdd-Check (suimiNew-Check -Name 'wsl-available' -Status 'pass' -Message 'Optional wsl.exe not found on PATH.')
    }

    $wpegptCheck = Join-Path $scriptDir 'check_wpegpt_env.ps1'
    $wpegptJson = & $wpegptCheck -AsJson -NoExitCode
    $wpegptInfo = $wpegptJson | ConvertFrom-Json
    if ($wpegptInfo.ready) {
        suimiAdd-Check (suimiNew-Check -Name 'wpegpt-optional' -Status 'pass' -Message 'Optional WPeGPT/IDA automation is ready.')
    } else {
        $issueText = ($wpegptInfo.issues -join '; ')
        suimiAdd-Check (suimiNew-Check -Name 'wpegpt-optional' -Status 'warn' -Message "Optional WPeGPT/IDA automation is not ready: $issueText")
    }

    $cacheDirs = Get-ChildItem -LiteralPath $rootDir -Directory -Recurse -Force |
        Where-Object { $_.Name -eq '__pycache__' -or $_.Name -eq '.pytest_cache' } |
        Select-Object -ExpandProperty FullName
    if ($cacheDirs.Count -gt 0) {
        suimiAdd-Check (suimiNew-Check -Name 'generated-caches' -Status 'warn' -Message "Generated cache directories present: $($cacheDirs -join '; ')")
    } else {
        suimiAdd-Check (suimiNew-Check -Name 'generated-caches' -Status 'pass' -Message 'No generated cache directories found.')
    }
} finally {
    Pop-Location
}

$allChecks = @($checks)
$failed = @($allChecks | Where-Object { $_.status -eq 'fail' })
$warnings = @($allChecks | Where-Object { $_.status -eq 'warn' })
$result = [ordered]@{
    ok = ($failed.Count -eq 0)
    failed = $failed.Count
    warnings = $warnings.Count
    checks = $allChecks
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host "Reverse engineering workflow healthcheck"
    foreach ($check in $checks) {
        Write-Host ("[{0}] {1}: {2}" -f $check.status.ToUpperInvariant(), $check.name, $check.message)
    }
}

if ($failed.Count -gt 0) {
    exit 1
}

exit 0
