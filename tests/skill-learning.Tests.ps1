$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Resolve-Path -LiteralPath (Join-Path $here '..')).Path
. (Join-Path $rootDir 'scripts\lib\SkillLearning.ps1')

$inboxPath = Join-Path $rootDir 'references\skill-learning-inbox.md'

Describe 'Skill learning inbox' {
    It 'parses all inbox entries' {
        $inbox = @(suimiRead-LearningInbox -InboxPath $inboxPath)
        # The inbox is an append-only ledger (record_skill_lesson.ps1 keeps adding real
        # candidates over time), so pin parser sanity rather than an exact snapshot count.
        $inbox.Count | Should BeGreaterThan 0
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
        # Same rationale as the parser test above: assert non-empty, not a magic snapshot count.
        $result.count | Should BeGreaterThan 0
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

    It 'suimiSet-LearningInboxEntryStatus does not corrupt the next entry when adding a Promotion note' {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('re_inbox_' + [guid]::NewGuid().ToString('N') + '.md')
        try {
            suimiEnsure-LearningInbox -InboxPath $tmp
            $entries = @'

## 2026-08-01 00:00:00 +08:00 - first lesson

- id: 20260801-000000-first-lesson
- status: candidate
- category: method
- confidence: 3/5
- applies_to: unit tests
- purpose_zh: first
- target_skill_path: references/reverse-engineering-methods.md
- tags: test

### Evidence

first evidence

### Lesson

first lesson body

### Validation

first validation

### Next Action

review

## 2026-08-02 00:00:00 +08:00 - second lesson

- id: 20260802-000000-second-lesson
- status: candidate
- category: method
- confidence: 3/5
- applies_to: unit tests
- purpose_zh: second
- target_skill_path: references/reverse-engineering-methods.md
- tags: test

### Evidence

second evidence

### Lesson

second lesson body

### Validation

second validation

### Next Action

review
'@
            [System.IO.File]::AppendAllText($tmp, ($entries + "`r`n"), [System.Text.UTF8Encoding]::new($false))

            # Promoting the FIRST (non-last) entry is the exact scenario that used to glue
            # its "### Promotion" note onto the second entry's "## " heading line, making
            # the second entry silently stop matching as its own heading.
            suimiSet-LearningInboxEntryStatus -InboxPath $tmp -Id '20260801-000000-first-lesson' -Status promoted -Note 'Promoted to references/reverse-engineering-methods.md by test.'

            $parsed = @(suimiRead-LearningInbox -InboxPath $tmp)
            $parsed.Count | Should Be 2

            $first = @($parsed | Where-Object { $_.id -eq '20260801-000000-first-lesson' })[0]
            $second = @($parsed | Where-Object { $_.id -eq '20260802-000000-second-lesson' })[0]

            $first.status | Should Be 'promoted'
            $first.title | Should Be 'first lesson'
            [bool]$second | Should Be $true
            $second.title | Should Be 'second lesson'
            $second.status | Should Be 'candidate'
            $second.lesson -match 'second lesson body' | Should Be $true
        } finally {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        }
    }
}