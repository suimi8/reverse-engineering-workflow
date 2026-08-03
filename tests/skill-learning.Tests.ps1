$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Resolve-Path -LiteralPath (Join-Path $here '..')).Path
. (Join-Path $rootDir 'scripts\lib\SkillLearning.ps1')

$inboxPath = Join-Path $rootDir 'references\skill-learning-inbox.md'

Describe 'Skill learning inbox' {
    It 'parses all inbox entries' {
        $inbox = @(suimiRead-LearningInbox -InboxPath $inboxPath)
        $inbox.Count | Should Be 7
    }

    It 'inbox ids are unique' {
        $inbox = @(suimiRead-LearningInbox -InboxPath $inboxPath)
        $ids = @($inbox | ForEach-Object { $_.id })
        @($ids | Select-Object -Unique).Count | Should Be $ids.Count
    }

    It 'every entry has id, status, lesson and a valid target path' {
        $inbox = @(suimiRead-LearningInbox -InboxPath $inboxPath)
        foreach ($entry in $inbox) {
            [bool]$entry.id | Should Be $true
            (@('candidate', 'validated', 'promoted', 'rejected') -contains $entry.status) | Should Be $true
            [bool]$entry.lesson | Should Be $true
            [bool]$entry.target_skill_path | Should Be $true
            $full = suimiResolve-RepoRelativePath -RootDir $rootDir -RelativePath ([string]$entry.target_skill_path)
            (Test-Path -LiteralPath $full) | Should Be $true
        }
    }

    It 'review_skill_lessons reports zero errors' {
        $json = & (Join-Path $rootDir 'scripts\review_skill_lessons.ps1') -AsJson | Out-String
        $result = $json | ConvertFrom-Json
        $result.count | Should Be 7
        $result.errors | Should Be 0
    }

    It 'the record format produces a parseable candidate entry' {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('re_inbox_' + [guid]::NewGuid().ToString('N') + '.md')
        try {
            suimiEnsure-LearningInbox -InboxPath $tmp
            $entry = @'
## 2026-08-03 12:00:00 +08:00 - unit test lesson

- id: 20260803-120000-unit-test-lesson
- status: candidate
- category: method
- confidence: 3/5
- applies_to: unit tests
- purpose_zh: 单测
- target_skill_path: references/reverse-engineering-methods.md
- tags: test

### Evidence

test evidence

### Lesson

test lesson

### Validation

test validation

### Next Action

review
'@
            [System.IO.File]::AppendAllText($tmp, ($entry + "`r`n"), [System.Text.UTF8Encoding]::new($false))
            $parsed = @(suimiRead-LearningInbox -InboxPath $tmp)
            $parsed.Count | Should Be 1
            $parsed[0].id | Should Be '20260803-120000-unit-test-lesson'
            $parsed[0].status | Should Be 'candidate'
            $parsed[0].lesson -match 'test lesson' | Should Be $true
        } finally {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        }
    }
}