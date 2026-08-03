#Requires -Version 5.0
param(
    [ValidateSet('pending', 'candidate', 'validated', 'all')]
    [string]$Status = 'pending',

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

$allLessons = @(suimiRead-LearningInbox -InboxPath $inboxPath)
switch ($Status) {
    'candidate' { $lessons = @($allLessons | Where-Object { $_.status -eq 'candidate' }) }
    'validated' { $lessons = @($allLessons | Where-Object { $_.status -eq 'validated' }) }
    'all' { $lessons = $allLessons }
    default { $lessons = @($allLessons | Where-Object { $_.status -in @('candidate', 'validated') }) }
}

$items = @()
$candidateCount = 0
$validatedCount = 0
foreach ($lesson in $lessons) {
    if ($lesson.status -eq 'candidate') {
        $candidateCount += 1
    }
    if ($lesson.status -eq 'validated') {
        $validatedCount += 1
    }

    $issues = @(suimiFind-LearningLessonIssues -Lesson $lesson -RootDir $rootDir)
    $target = [string]$lesson.target_skill_path
    $promoteCommand = if ($target -and $target -ne 'undecided') {
        ".\scripts\promote_skill_lesson.ps1 -Id `"$($lesson.id)`" -DestinationPath `"$target`""
    } else {
        ".\scripts\promote_skill_lesson.ps1 -Id `"$($lesson.id)`" -DestinationPath `"<target.md>`""
    }

    $items += [pscustomobject][ordered]@{
        id = $lesson.id
        status = $lesson.status
        title = $lesson.title
        category = $lesson.category
        confidence = $lesson.confidence
        applies_to = $lesson.applies_to
        purpose_zh = $lesson.purpose_zh
        target_skill_path = $target
        issue_count = $issues.Count
        warning_count = @($issues | Where-Object { $_.severity -eq 'warn' }).Count
        error_count = @($issues | Where-Object { $_.severity -eq 'error' }).Count
        lesson = $lesson.lesson
        next_action = $lesson.next_action
        review_command = ".\scripts\review_skill_lessons.ps1 -Status $($lesson.status)"
        promote_command = $promoteCommand
    }
}

$result = [pscustomobject][ordered]@{
    ok = $true
    inbox_path = (suimiGet-LearningInboxRelativePath)
    status_filter = $Status
    pending_count = $items.Count
    candidate_count = $candidateCount
    validated_count = $validatedCount
    items = $items
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 8
} else {
    Write-Host 'Pending reverse skill lessons'
    Write-Host " inbox     : $($result.inbox_path)"
    Write-Host " filter    : $($result.status_filter)"
    Write-Host " pending   : $($result.pending_count)"
    Write-Host " candidate : $($result.candidate_count)"
    Write-Host " validated : $($result.validated_count)"
    if ($items.Count -eq 0) {
        Write-Host ' No pending reverse skill lessons.'
    } else {
        foreach ($item in $items) {
            Write-Host ''
            Write-Host (" - [{0}] {1}" -f $item.status, $item.title)
            Write-Host "   id      : $($item.id)"
            Write-Host "   category: $($item.category)"
            Write-Host "   作用    : $($item.purpose_zh)"
            Write-Host "   applies : $($item.applies_to)"
            Write-Host "   target  : $($item.target_skill_path)"
            Write-Host "   issues  : errors=$($item.error_count), warnings=$($item.warning_count)"
            Write-Host "   review  : $($item.review_command)"
            Write-Host "   promote : $($item.promote_command)"
        }
    }
}

exit 0
