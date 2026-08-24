#Requires -Version 5.0
param(
    [Parameter(Mandatory=$true)]
    [string]$Title,

    [ValidateSet('method', 'pivot', 'tooling', 'patching', 'triage', 'runtime', 'static', 'mobile', 'security', 'packaging', 'other')]
    [string]$Category = 'method',

    [string]$AppliesTo = '',

    [string]$PurposeZh = '',

    [string]$TargetSkillPath = '',

    [string]$Evidence = '',

    [Parameter(Mandatory=$true)]
    [string]$Lesson,

    [string]$Validation = '',

    [string]$NextAction = 'review',

    [ValidateSet('candidate', 'validated', 'promoted', 'rejected')]
    [string]$Status = 'candidate',

    [ValidateRange(1, 5)]
    [int]$Confidence = 3,

    [string[]]$Tags = @(),

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
$inboxRelativePath = suimiGet-LearningInboxRelativePath
$inboxPath = suimiGet-LearningInboxPath -RootDir $rootDir

if (-not [string]::IsNullOrWhiteSpace($TargetSkillPath)) {
    suimiResolve-RepoRelativePath -RootDir $rootDir -RelativePath $TargetSkillPath | Out-Null
}

suimiEnsure-LearningInbox -InboxPath $inboxPath

$now = Get-Date
$slug = suimiNew-LessonSlug -Value $Title
$id = '{0}-{1}' -f $now.ToString('yyyyMMdd-HHmmss'), $slug
$tagText = if ($Tags.Count -gt 0) { ($Tags -join ', ') } else { 'none' }
$targetText = if ([string]::IsNullOrWhiteSpace($TargetSkillPath)) { 'undecided' } else { $TargetSkillPath.Replace('\', '/') }
$appliesText = if ([string]::IsNullOrWhiteSpace($AppliesTo)) { 'general reverse workflow' } else { $AppliesTo.Trim() }
$purposeZhText = if ([string]::IsNullOrWhiteSpace($PurposeZh)) { '未填写。' } else { $PurposeZh.Trim() }

$entry = @"

## $($now.ToString('yyyy-MM-dd HH:mm:ss zzz')) - $($Title.Trim())

- id: $id
- status: $Status
- category: $Category
- confidence: $Confidence/5
- applies_to: $appliesText
- purpose_zh: $purposeZhText
- target_skill_path: $targetText
- tags: $tagText

### Evidence

$(suimiFormat-MarkdownBlock -Text $Evidence)

### Lesson

$(suimiFormat-MarkdownBlock -Text $Lesson)

### Validation

$(suimiFormat-MarkdownBlock -Text $Validation)

### Next Action

$(suimiFormat-MarkdownBlock -Text $NextAction)
"@

[System.IO.File]::AppendAllText($inboxPath, $entry, [System.Text.Encoding]::UTF8)

$result = [pscustomobject][ordered]@{
    ok = $true
    id = $id
    status = $Status
    category = $Category
    confidence = $Confidence
    inbox_path = $inboxRelativePath
    target_skill_path = $targetText
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 4
} else {
    Write-Host "Recorded reusable lesson candidate"
    Write-Host " id     : $($result.id)"
    Write-Host " inbox  : $($result.inbox_path)"
    Write-Host " target : $($result.target_skill_path)"
}

exit 0
