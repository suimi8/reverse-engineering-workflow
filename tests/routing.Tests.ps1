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