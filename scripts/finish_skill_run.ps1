#Requires -Version 5.0
param(
    [ValidateRange(0, 100)]
    [int]$NewLessonCount = 0,

    [string[]]$SuggestedTitle = @(),

    [ValidateSet('auto', 'yes', 'no', 'review')]
    [string]$RecommendAdd = 'auto',

    [string]$Reason = '',

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
$pendingLessons = @($allLessons | Where-Object { $_.status -in @('candidate', 'validated') })
$candidateLessons = @($pendingLessons | Where-Object { $_.status -eq 'candidate' })
$validatedLessons = @($pendingLessons | Where-Object { $_.status -eq 'validated' })

$effectiveNewLessonCount = $NewLessonCount
if ($SuggestedTitle.Count -gt $effectiveNewLessonCount) {
    $effectiveNewLessonCount = $SuggestedTitle.Count
}

$recommendationKind = $RecommendAdd
if ($recommendationKind -eq 'auto') {
    if ($effectiveNewLessonCount -gt 0) {
        $recommendationKind = 'yes'
    } elseif ($pendingLessons.Count -gt 0) {
        $recommendationKind = 'review'
    } else {
        $recommendationKind = 'no'
    }
}

if ([string]::IsNullOrWhiteSpace($Reason)) {
    switch ($recommendationKind) {
        'yes' {
            $Reason = '将可复用方法先记录为候选经验，再审查并在验证后晋级到目标 skill 或引用文件。'
        }
        'review' {
            $Reason = '本次未声明新的经验，但候选池已有待审查或待晋级条目。'
        }
        default {
            $Reason = '本次未识别出有证据支撑的可复用新方法。'
        }
    }
}

$pendingItems = @()
foreach ($lesson in $pendingLessons) {
    $target = [string]$lesson.target_skill_path
    if ([string]::IsNullOrWhiteSpace($target)) {
        $target = 'undecided'
    }
    $pendingItems += [pscustomobject][ordered]@{
        id = $lesson.id
        status = $lesson.status
        title = $lesson.title
        purpose_zh = $lesson.purpose_zh
        target_skill_path = $target
        promote_command = if ($target -ne 'undecided') {
            ".\scripts\promote_skill_lesson.ps1 -Id `"$($lesson.id)`" -DestinationPath `"$target`""
        } else {
            ".\scripts\promote_skill_lesson.ps1 -Id `"$($lesson.id)`" -DestinationPath `"<target.md>`""
        }
    }
}

$howToAdd = @(
    '.\scripts\record_skill_lesson.ps1 -Title "<lesson>" -Category method -AppliesTo "<scope>" -PurposeZh "<中文作用简述>" -TargetSkillPath "<target.md>" -Evidence "<proof>" -Lesson "<reusable rule>" -Validation "<verification>" -NextAction "review"',
    '.\scripts\review_skill_lessons.ps1 -Status candidate',
    '.\scripts\promote_skill_lesson.ps1 -Id "<id>" -DestinationPath "<target.md>"'
)

$result = [pscustomobject][ordered]@{
    ok = $true
    required_final_section_title = '新技能/方法反馈'
    discovered_new_skill = ($effectiveNewLessonCount -gt 0)
    discovered_new_skill_count = $effectiveNewLessonCount
    discovered_new_skill_titles = @($SuggestedTitle)
    suggested_add_count = $effectiveNewLessonCount
    recommended_to_add = ($recommendationKind -eq 'yes')
    recommendation = $recommendationKind
    reason = $Reason
    inbox_path = (suimiGet-LearningInboxRelativePath)
    current_pending_count = $pendingLessons.Count
    candidate_count = $candidateLessons.Count
    validated_count = $validatedLessons.Count
    suggested_titles = @($SuggestedTitle)
    pending_items = $pendingItems
    how_to_add = $howToAdd
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 8
} else {
    Write-Host '新技能/方法反馈'
    Write-Host (" 是否发现新技能/方法 : {0}" -f $(if ($result.discovered_new_skill) { '是' } else { '否' }))
    Write-Host (" 本次发现数量       : {0}" -f $result.discovered_new_skill_count)
    Write-Host ' 发现的新技能/方法 :'
    if ($result.discovered_new_skill_titles.Count -gt 0) {
        foreach ($title in $result.discovered_new_skill_titles) {
            Write-Host ("  - {0}" -f $title)
        }
    } else {
        Write-Host '  - 无'
    }
    Write-Host (" 本次建议加入数量   : {0}" -f $result.suggested_add_count)
    Write-Host (" 建议是否加入 skills : {0} - {1}" -f $(if ($result.recommendation -eq 'yes') { '是' } elseif ($result.recommendation -eq 'review') { '需要审查现有候选' } else { '否' }), $result.reason)
    Write-Host (" 当前待处理候选     : {0} (candidate={1}, validated={2})" -f $result.current_pending_count, $result.candidate_count, $result.validated_count)
    Write-Host ' 如何添加到本 skills:'
    foreach ($command in $result.how_to_add) {
        Write-Host ("  - {0}" -f $command)
    }
    if ($result.pending_items.Count -gt 0) {
        Write-Host ' 当前候选晋级命令   :'
        foreach ($item in $result.pending_items) {
            Write-Host ("  - [{0}] {1}: {2}" -f $item.status, $item.title, $item.promote_command)
            if (-not [string]::IsNullOrWhiteSpace([string]$item.purpose_zh)) {
                Write-Host ("    作用: {0}" -f $item.purpose_zh)
            }
        }
    }
}

exit 0
