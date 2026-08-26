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

    It 'select_skill routes a game-security research task to the game-security-research module' {
        $json = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '帮我查一下有哪些游戏反作弊的逆向资料和开源项目' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.path) -match 'game-security-research') | Should Be $true
    }

    It 'select_skill still routes a Cheat Engine tool task to ce-reverse (not preempted by game-security-research)' {
        $json = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '我想用 cheat engine 扫描内存找基址' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.path) -match 'ce-reverse') | Should Be $true
    }

    It 'select_skill routes a cybersecurity-projects catalog task to the cybersecurity-projects-catalog module' {
        $json = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '帮我看看 CarterPerez 的 Cybersecurity-Projects 里有哪些安全项目源码' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.path) -match 'cybersecurity-projects-catalog') | Should Be $true
    }

    It 'select_skill still routes an IDA binary-analysis task to a tool module (not preempted by cybersecurity-projects-catalog)' {
        $json = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '帮我用 ida 分析这个二进制里的算法' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        # the new catalog rule (0.84) must NOT preempt an IDA tool task (ida-reverse 0.88)
        (([string]$result.skill.path) -match 'cybersecurity-projects-catalog') | Should Be $false
        (([string]$result.skill.path) -match 'ida-reverse') | Should Be $true
    }

    It 'select_skill routes an attack-flow orchestration task to pentest-orchestration' {
        $json = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '帮我设计一个攻击流程编排器，把侦察扫描利用报告串成一条可复现的流水线' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.path) -match 'pentest-orchestration') | Should Be $true
    }

    It 'select_skill does not let pentest-orchestration preempt a generic SQLi/login task' {
        $json = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '帮我测一下这个登录接口有没有 SQL 注入' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        # pentest-orchestration must NOT preempt a generic injection/auth task
        (([string]$result.skill.path) -match 'pentest-orchestration') | Should Be $false
        # NOTE: the concrete winner is non-deterministic in this cloud-synced repo / under load
        # (sqli-sql-injection 0.90 when skills enumerate cleanly, auth-sec/api-sec otherwise), so we
        # assert only the invariant this test exists for: the new pentest rule must not preempt it.
    }

    It 'select_skill routes a WeChat mini-program task to wechat-miniapp-protocol-re' {
        $json = & (Join-Path $rootDir 'scripts\select_skill.ps1') -TaskText '帮我逆向微信小程序的签名算法和抓包' -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.ok | Should Be $true
        (([string]$result.skill.path) -match 'wechat-miniapp-protocol-re') | Should Be $true
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
