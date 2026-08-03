#Requires -Version 5.0
param(
    [Parameter(Mandatory=$true)]
    [string]$Id,

    [string]$DestinationPath = '',

    [string]$SectionTitle = 'Promoted Learning Notes',

    [switch]$AllowCandidate,

    [switch]$SkipInstalledSync,

    [switch]$DryRun,

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

$lesson = @(suimiRead-LearningInbox -InboxPath $inboxPath | Where-Object { $_.id -eq $Id }) | Select-Object -First 1
if (-not $lesson) {
    throw "Lesson id not found: $Id"
}

if ($lesson.status -eq 'rejected') {
    throw "Lesson is rejected and cannot be promoted: $Id"
}
if ($lesson.status -eq 'promoted') {
    throw "Lesson is already promoted: $Id"
}
if ($lesson.status -eq 'candidate' -and -not $AllowCandidate) {
    throw "Lesson is still candidate. Mark it validated first or pass -AllowCandidate for a deliberate low-risk promotion."
}

$issues = @(suimiFind-LearningLessonIssues -Lesson $lesson -RootDir $rootDir)
if ($issues.Count -gt 0) {
    $issueText = ($issues | ForEach-Object { "$($_.type): $($_.message)" }) -join '; '
    throw "Lesson cannot be promoted until all review issues are fixed: $issueText"
}

$destinationRelativePath = $DestinationPath
if ([string]::IsNullOrWhiteSpace($destinationRelativePath)) {
    $destinationRelativePath = [string]$lesson.target_skill_path
}
if ([string]::IsNullOrWhiteSpace($destinationRelativePath) -or $destinationRelativePath -eq 'undecided') {
    throw 'DestinationPath is required because the lesson target_skill_path is undecided.'
}
if ($destinationRelativePath.Replace('\', '/') -eq (suimiGet-LearningInboxRelativePath)) {
    throw 'Cannot promote a lesson into the learning inbox itself.'
}
if ($destinationRelativePath -notmatch '\.md$') {
    throw "Promotion destination must be a Markdown file: $destinationRelativePath"
}

$destinationFullPath = suimiResolve-RepoRelativePath -RootDir $rootDir -RelativePath $destinationRelativePath
$destinationText = [System.IO.File]::ReadAllText($destinationFullPath, [System.Text.Encoding]::UTF8)
$sourceId = [string]$lesson.id
$lessonTitle = [string]$lesson.title

$block = @"

### $lessonTitle

- source: ``$sourceId``
- category: $($lesson.category)
- applies_to: $($lesson.applies_to)
- purpose_zh: $($lesson.purpose_zh)
- confidence: $($lesson.confidence)/5

**Lesson**

$(suimiFormat-MarkdownBlock -Text $lesson.lesson)

**Evidence**

$(suimiFormat-MarkdownBlock -Text $lesson.evidence)

**Validation**

$(suimiFormat-MarkdownBlock -Text $lesson.validation)
"@

$sectionPattern = '(?m)^##\s+' + [regex]::Escape($SectionTitle) + '\s*$'
$newDestinationText = $destinationText
if ($destinationText -notmatch $sectionPattern) {
    $newDestinationText = $destinationText.TrimEnd() + "`r`n`r`n## $SectionTitle`r`n" + $block
} else {
    $newDestinationText = $destinationText.TrimEnd() + "`r`n" + $block
}

$promotionNote = "Promoted to ``$($destinationRelativePath.Replace('\', '/'))`` by ``scripts/promote_skill_lesson.ps1`` on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')."

$result = [pscustomobject][ordered]@{
    ok = $true
    dry_run = [bool]$DryRun
    id = $lesson.id
    title = $lesson.title
    destination_path = $destinationRelativePath.Replace('\', '/')
    installed_sync = $null
    promoted_block = if ($DryRun) { $block.Trim() } else { $null }
}

if (-not $DryRun) {
    [System.IO.File]::WriteAllText($destinationFullPath, $newDestinationText, [System.Text.Encoding]::UTF8)
    suimiSet-LearningInboxEntryStatus -InboxPath $inboxPath -Id $Id -Status promoted -Note $promotionNote

    if (-not $SkipInstalledSync) {
        $syncScript = Join-Path $scriptDir 'sync_installed_skill.ps1'
        if (-not (Test-Path -LiteralPath $syncScript)) {
            throw "Installed sync script not found after promotion: $syncScript"
        }
        $syncJson = & $syncScript -AsJson
        if ($LASTEXITCODE -ne 0) {
            throw 'Installed sync failed after lesson promotion.'
        }
        $result.installed_sync = $syncJson | ConvertFrom-Json
    }
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host 'Promoted skill lesson'
    Write-Host " id          : $($result.id)"
    Write-Host " destination : $($result.destination_path)"
    Write-Host " dry_run     : $($result.dry_run)"
    if ($result.installed_sync) {
        Write-Host " sync        : $($result.installed_sync.action) -> $($result.installed_sync.destination)"
    }
}

exit 0
