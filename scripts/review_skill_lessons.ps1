#Requires -Version 5.0
param(
    [ValidateSet('all', 'candidate', 'validated', 'promoted', 'rejected')]
    [string]$Status = 'all',

    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $scriptDir 'lib\SkillLearning.ps1')

$rootDir = suimiGet-SkillLearningRoot
$inboxPath = suimiGet-LearningInboxPath -RootDir $rootDir
suimiEnsure-LearningInbox -InboxPath $inboxPath

$lessons = @(suimiRead-LearningInbox -InboxPath $inboxPath)
if ($Status -ne 'all') {
    $lessons = @($lessons | Where-Object { $_.status -eq $Status })
}

$reviewed = @()
$errorCount = 0
$warningCount = 0
foreach ($lesson in $lessons) {
    $issues = @(suimiFind-LearningLessonIssues -Lesson $lesson -RootDir $rootDir)
    $errorCount += @($issues | Where-Object { $_.severity -eq 'error' }).Count
    $warningCount += @($issues | Where-Object { $_.severity -eq 'warn' }).Count
    $reviewed += [pscustomobject][ordered]@{
        id = $lesson.id
        status = $lesson.status
        title = $lesson.title
        category = $lesson.category
        confidence = $lesson.confidence
        target_skill_path = $lesson.target_skill_path
        issues = $issues
    }
}

$duplicates = @(suimiFind-DuplicateLearningLessons -Lessons $lessons)
if ($duplicates.Count -gt 0) {
    $warningCount += $duplicates.Count
}

$result = [pscustomobject][ordered]@{
    ok = ($errorCount -eq 0)
    inbox_path = (suimiGet-LearningInboxRelativePath)
    status_filter = $Status
    count = $lessons.Count
    errors = $errorCount
    warnings = $warningCount
    duplicates = $duplicates
    lessons = $reviewed
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 8
} else {
    Write-Host 'Skill learning inbox review'
    Write-Host " inbox    : $($result.inbox_path)"
    Write-Host " filter   : $($result.status_filter)"
    Write-Host " entries  : $($result.count)"
    Write-Host " errors   : $($result.errors)"
    Write-Host " warnings : $($result.warnings)"
    foreach ($lesson in $reviewed) {
        Write-Host (" - [{0}] {1} -> {2}" -f $lesson.status, $lesson.id, $lesson.target_skill_path)
        foreach ($issue in @($lesson.issues)) {
            Write-Host ("   [{0}] {1}: {2}" -f $issue.severity, $issue.type, $issue.message)
        }
    }
    foreach ($duplicate in $duplicates) {
        Write-Host ("   [warn] duplicate lesson text: {0}" -f ($duplicate.ids -join ', '))
    }
}

if (-not $result.ok) {
    exit 1
}

exit 0
