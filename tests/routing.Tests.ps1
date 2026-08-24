$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Resolve-Path -LiteralPath (Join-Path $here '..')).Path

Describe 'Skill routing scripts' {
    It 'list_skills emits a valid registry with enough entries' {
        $json = & (Join-Path $rootDir 'scripts\list_skills.ps1') -AsJson | Out-String
        $registry = $json | ConvertFrom-Json
        ($registry.count -gt 50) | Should Be $true
        [bool]$registry.skills[0].path | Should Be $true
    }

    It 'resolve_skill resolves mobile-reverse to a module path' {
        $json = & (Join-Path $rootDir 'scripts\resolve_skill.ps1') -Query 'mobile-reverse' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.path) -match 'mobile-reverse') | Should Be $true
    }

    It 'invoke_skill routes an APK task to an existing internal module' {
        $json = & (Join-Path $rootDir 'scripts\invoke_skill.ps1') -TaskText 'APK frida hook 抓包分析' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        [bool]$result.skill_path | Should Be $true
        $modulePath = Join-Path $rootDir ([string]$result.skill_path).Replace('/', '\')
        (Test-Path -LiteralPath $modulePath) | Should Be $true
    }

    It 'select_skill returns a module for a GUI diagnosis task' {
        $json = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText 'Flet 桌面应用窗口诊断' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.path) -match 'flet') | Should Be $true
    }

    It 'select_skill routes an x64dbg dynamic-debugging task to the x64dbg module' {
        $json = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '帮我附加到这个进程,下个断点看看参数' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.path) -match 'x64dbg-reverse') | Should Be $true
    }
}

Describe 'Learning loop scripts' {
    It 'finish_skill_run emits the mandatory feedback contract' {
        $json = & (Join-Path $rootDir 'scripts\finish_skill_run.ps1') -NewLessonCount 0 -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.discovered_new_skill | Should Be $false
        $result.discovered_new_skill_count | Should Be 0
        [bool]$result.required_final_section_title | Should Be $true
    }

    It 'pending_skill_lessons parses the inbox without errors' {
        $json = & (Join-Path $rootDir 'scripts\pending_skill_lessons.ps1') -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        ($null -ne $result.pending_count) | Should Be $true
    }
}

Describe 'new_module scaffold' {
    It 'previews a github module without writing on WhatIf' {
        $json = & (Join-Path $rootDir 'scripts\new_module.ps1') -Root github-reverse -Name zzz-scaffold-selftest -DisplayNameZh 'suimiScaffoldSelftest' -Description 'pester whatif probe' -WhatIf -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        $result.applied | Should Be $false
        (Test-Path -LiteralPath (Join-Path $rootDir 'github-reverse-modules\skills\zzz-scaffold-selftest')) | Should Be $false
    }

    It 'stays idempotent for an already-registered module on WhatIf' {
        $json = & (Join-Path $rootDir 'scripts\new_module.ps1') -Root github-reverse -Name radare2 -DisplayNameZh 'suimiIdempotencyProbe' -Description 'pester idempotency probe' -WhatIf -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        $statuses = @($result.actions | ForEach-Object { $_.status } | Sort-Object -Unique)
        ($statuses -contains 'would-append') | Should Be $false
        ($statuses -contains 'anchor-not-found') | Should Be $false
    }

    It 'chooses a P1 router for a security module on WhatIf' {
        $json = & (Join-Path $rootDir 'scripts\new_module.ps1') -Root security -Name zzz-scaffold-selftest -DisplayNameZh 'suimiSecuritySelftest' -Description 'pester security whatif probe' -WhatIf -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        $result.chosen_router | Should Be 'hack'
        (Test-Path -LiteralPath (Join-Path $rootDir 'security-research-modules\skills\zzz-scaffold-selftest')) | Should Be $false
    }

    It 'select_skill routes an API-reverse task through the unified root entry' {
        $result = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '帮我逆向这个网站的API接口，生成Python客户端' -AsJson | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.name) -eq 'reverse-engineering-workflow') | Should Be $true
        ($result.confidence -ge 0.8) | Should Be $true
    }

    It 'select_skill routes a JSVMP task through the unified root entry' {
        $result = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '这个网站有JSVMP保护，帮我破解混淆还原签名算法' -AsJson | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.name) -eq 'reverse-engineering-workflow') | Should Be $true
        ($result.confidence -ge 0.8) | Should Be $true
    }

    It 'select_skill routes a crypto-reverse task through the unified root entry' {
        $result = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '帮我识别这个网站请求的加密算法并用Python重构签名' -AsJson | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.name) -eq 'reverse-engineering-workflow') | Should Be $true
        ($result.confidence -ge 0.8) | Should Be $true
    }
}
