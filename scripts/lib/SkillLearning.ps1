#Requires -Version 5.0

function suimiGet-SkillLearningRoot {
    $scriptsDir = Split-Path -Parent $PSScriptRoot
    return (Resolve-Path -LiteralPath (Join-Path $scriptsDir '..')).Path
}

function suimiGet-LearningInboxPath {
    param([string]$RootDir)

    return Join-Path $RootDir 'references\skill-learning-inbox.md'
}

function suimiGet-LearningInboxRelativePath {
    return 'references/skill-learning-inbox.md'
}

function suimiNew-LessonSlug {
    param([string]$Value)

    $slug = $Value.ToLowerInvariant() -replace '[^\p{L}\p{Nd}]+', '-'
    $slug = $slug.Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return 'lesson'
    }
    if ($slug.Length -gt 48) {
        return $slug.Substring(0, 48).Trim('-')
    }
    return $slug
}

function suimiFormat-MarkdownBlock {
    param(
        [string]$Text,
        [string]$Fallback = 'Not recorded.'
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Fallback
    }

    $normalized = $Text.Trim() -replace "`r`n", "`n" -replace "`r", "`n"
    return (($normalized -split "`n") | ForEach-Object { $_.TrimEnd() }) -join "`r`n"
}

function suimiResolve-RepoRelativePath {
    param(
        [string]$RootDir,
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $null
    }
    if ($RelativePath -match '(^[A-Za-z]:\\)|(^\\\\)|(^/)') {
        throw "Path must be repository-relative: $RelativePath"
    }

    $fullPath = Join-Path $RootDir $RelativePath.Replace('/', '\')
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Path does not exist: $RelativePath"
    }

    $resolvedRoot = (Resolve-Path -LiteralPath $RootDir).Path.TrimEnd('\', '/')
    $resolvedPath = (Resolve-Path -LiteralPath $fullPath).Path
    if (-not $resolvedPath.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes project root: $RelativePath"
    }

    return $resolvedPath
}

function suimiEnsure-LearningInbox {
    param([string]$InboxPath)

    if (Test-Path -LiteralPath $InboxPath) {
        return
    }

    $header = @'
# Skill Learning Inbox

This file stores reusable reverse-engineering lesson candidates before they are promoted into a concrete skill or reference. Keep entries evidence-based and reviewable.

'@
    [System.IO.File]::WriteAllText($InboxPath, $header, [System.Text.Encoding]::UTF8)
}

function suimiRead-LearningInbox {
    param([string]$InboxPath)

    if (-not (Test-Path -LiteralPath $InboxPath)) {
        return @()
    }

    $text = [System.IO.File]::ReadAllText($InboxPath, [System.Text.Encoding]::UTF8)
    $matches = [regex]::Matches($text, '(?ms)^##\s+(?<heading>[^\r\n]+)\r?\n(?<body>.*?)(?=^##\s+|\z)')
    $lessons = @()
    $index = 0

    foreach ($match in $matches) {
        $index += 1
        $heading = $match.Groups['heading'].Value.Trim()
        $body = $match.Groups['body'].Value
        $metadata = @{}
        foreach ($metaMatch in [regex]::Matches($body, '(?m)^-\s+(?<key>[a-z_]+):\s*(?<value>.*)$')) {
            $metadata[$metaMatch.Groups['key'].Value] = $metaMatch.Groups['value'].Value.Trim()
        }

        $sections = @{}
        foreach ($sectionMatch in [regex]::Matches($body, '(?ms)^###\s+(?<name>[^\r\n]+)\r?\n(?<content>.*?)(?=^###\s+|\z)')) {
            $sections[$sectionMatch.Groups['name'].Value.Trim().ToLowerInvariant()] = $sectionMatch.Groups['content'].Value.Trim()
        }

        $title = $heading
        if ($heading -match '^\d{4}-\d{2}-\d{2}.*?\s+-\s+(?<title>.+)$') {
            $title = $Matches.title.Trim()
        }

        $confidence = $null
        if ($metadata.ContainsKey('confidence') -and $metadata['confidence'] -match '(?<value>\d+)') {
            $confidence = [int]$Matches.value
        }

        $lessons += [pscustomobject][ordered]@{
            index = $index
            heading = $heading
            title = $title
            id = if ($metadata.ContainsKey('id')) { $metadata['id'] } else { '' }
            status = if ($metadata.ContainsKey('status')) { $metadata['status'] } else { '' }
            category = if ($metadata.ContainsKey('category')) { $metadata['category'] } else { '' }
            confidence = $confidence
            applies_to = if ($metadata.ContainsKey('applies_to')) { $metadata['applies_to'] } else { '' }
            purpose_zh = if ($metadata.ContainsKey('purpose_zh')) { $metadata['purpose_zh'] } else { '' }
            target_skill_path = if ($metadata.ContainsKey('target_skill_path')) { $metadata['target_skill_path'] } else { '' }
            tags = if ($metadata.ContainsKey('tags')) { $metadata['tags'] } else { '' }
            evidence = if ($sections.ContainsKey('evidence')) { $sections['evidence'] } else { '' }
            lesson = if ($sections.ContainsKey('lesson')) { $sections['lesson'] } else { '' }
            validation = if ($sections.ContainsKey('validation')) { $sections['validation'] } else { '' }
            next_action = if ($sections.ContainsKey('next action')) { $sections['next action'] } else { '' }
            raw_text = $match.Value
            start_index = $match.Index
            length = $match.Length
        }
    }

    return @($lessons)
}

function suimiNormalize-LearningText {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    $normalized = $Value.ToLowerInvariant() -replace '[^\p{L}\p{Nd}]+', ' '
    $normalized = $normalized.Trim()
    if ($normalized.Length -gt 180) {
        return $normalized.Substring(0, 180)
    }

    return $normalized
}

function suimiFind-LearningLessonIssues {
    param(
        [object]$Lesson,
        [string]$RootDir
    )

    $issues = @()
    $allowedStatuses = @('candidate', 'validated', 'promoted', 'rejected')
    if ([string]::IsNullOrWhiteSpace([string]$Lesson.id)) {
        $issues += [pscustomobject]@{ severity = 'error'; type = 'missing-id'; message = 'Entry is missing id metadata.' }
    }
    if ([string]::IsNullOrWhiteSpace([string]$Lesson.status) -or [string]$Lesson.status -notin $allowedStatuses) {
        $issues += [pscustomobject]@{ severity = 'error'; type = 'invalid-status'; message = "Entry has invalid status: $($Lesson.status)" }
    }
    if ([string]::IsNullOrWhiteSpace([string]$Lesson.lesson) -or [string]$Lesson.lesson -eq 'Not recorded.') {
        $issues += [pscustomobject]@{ severity = 'error'; type = 'missing-lesson'; message = 'Entry is missing the Lesson section.' }
    }
    if ([string]::IsNullOrWhiteSpace([string]$Lesson.purpose_zh) -or [string]$Lesson.purpose_zh -eq '未填写。') {
        $issues += [pscustomobject]@{ severity = 'warn'; type = 'missing-purpose-zh'; message = 'Entry should include a short Chinese purpose_zh summary for user-facing pending notices.' }
    }
    if ([string]::IsNullOrWhiteSpace([string]$Lesson.evidence) -or [string]$Lesson.evidence -eq 'Not recorded.') {
        $issues += [pscustomobject]@{ severity = 'warn'; type = 'missing-evidence'; message = 'Entry has no recorded evidence.' }
    }
    if ([string]::IsNullOrWhiteSpace([string]$Lesson.validation) -or [string]$Lesson.validation -eq 'Not recorded.') {
        $issues += [pscustomobject]@{ severity = 'warn'; type = 'missing-validation'; message = 'Entry has no recorded validation.' }
    }
    if ([string]::IsNullOrWhiteSpace([string]$Lesson.target_skill_path) -or [string]$Lesson.target_skill_path -eq 'undecided') {
        $issues += [pscustomobject]@{ severity = 'warn'; type = 'undecided-target'; message = 'Entry has no target skill/reference path.' }
    } else {
        try {
            suimiResolve-RepoRelativePath -RootDir $RootDir -RelativePath ([string]$Lesson.target_skill_path) | Out-Null
        } catch {
            $issues += [pscustomobject]@{ severity = 'warn'; type = 'missing-target'; message = $_.Exception.Message }
        }
    }

    return @($issues)
}

function suimiFind-DuplicateLearningLessons {
    param([object[]]$Lessons)

    $groups = @{}
    foreach ($lesson in $Lessons) {
        $key = suimiNormalize-LearningText -Value ([string]$lesson.lesson)
        if ([string]::IsNullOrWhiteSpace($key)) {
            continue
        }
        if (-not $groups.ContainsKey($key)) {
            $groups[$key] = @()
        }
        $groups[$key] += $lesson
    }

    $duplicates = @()
    foreach ($key in $groups.Keys) {
        if ($groups[$key].Count -gt 1) {
            $duplicates += [pscustomobject][ordered]@{
                key = $key
                count = $groups[$key].Count
                ids = @($groups[$key] | ForEach-Object { $_.id })
                titles = @($groups[$key] | ForEach-Object { $_.title })
            }
        }
    }

    return @($duplicates)
}

function suimiSet-LearningInboxEntryStatus {
    param(
        [string]$InboxPath,
        [string]$Id,
        [ValidateSet('candidate', 'validated', 'promoted', 'rejected')]
        [string]$Status,
        [string]$Note = ''
    )

    $text = [System.IO.File]::ReadAllText($InboxPath, [System.Text.Encoding]::UTF8)
    $entries = @(suimiRead-LearningInbox -InboxPath $InboxPath)
    $entry = @($entries | Where-Object { $_.id -eq $Id }) | Select-Object -First 1
    if (-not $entry) {
        throw "Lesson id not found: $Id"
    }

    $updated = [string]$entry.raw_text
    if ($updated -match '(?m)^-\s+status:\s*.*$') {
        $updated = [regex]::Replace($updated, '(?m)^-\s+status:\s*.*$', "- status: $Status", 1)
    } else {
        # Insert exactly ONE status line, right after the heading (first newline).
        # A plain -replace "(\r?\n)" is GLOBAL and injects a status line after every
        # newline in the record, shredding it; cap the substitution at the first match.
        $firstNewlineRe = [regex]::new('(\r?\n)')
        $updated = $firstNewlineRe.Replace($updated, "`$1- status: $Status`$1", 1)
    }

    if (-not [string]::IsNullOrWhiteSpace($Note)) {
        $noteBlock = @"

### Promotion

$Note
"@
        if ($updated -match '(?m)^###\s+Promotion\s*$') {
            # Splice the note in literally. $Note is user-controlled, and as a
            # [regex]::Replace replacement string any $1 / $& / $$ inside it would be
            # expanded as a backreference/substitution. Locate the existing Promotion
            # section span and rebuild by substring concatenation so -Note lands verbatim.
            # (IgnoreCase mirrors the original call's RegexOptions=1 fourth argument.)
            $promoRe = [regex]::new('(?ms)^###\s+Promotion\s*\r?\n.*?(?=^###\s+|\z)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $promoMatch = $promoRe.Match($updated)
            if ($promoMatch.Success) {
                $updated = $updated.Substring(0, $promoMatch.Index) + $noteBlock.TrimStart() + $updated.Substring($promoMatch.Index + $promoMatch.Length)
            } else {
                $updated = $updated.TrimEnd() + "`r`n" + $noteBlock
            }
        } else {
            $updated = $updated.TrimEnd() + "`r`n" + $noteBlock
        }
    }

    # suimiRead-LearningInbox splits entries on "^##" at the start of a line, and the
    # lazy body match for this entry originally extended through the blank-line
    # separator before the next entry's heading (or end of file). Every branch above
    # ends with .TrimEnd(), which strips that separator. Restore it unconditionally so
    # the next "## " heading is not glued onto this entry's last line — otherwise the
    # next entry silently stops matching as its own heading and its fields get
    # misattributed to this entry (a real data-corruption bug, not hypothetical).
    $updated = $updated.TrimEnd() + "`r`n`r`n"

    $newText = $text.Remove($entry.start_index, $entry.length).Insert($entry.start_index, $updated)
    [System.IO.File]::WriteAllText($InboxPath, $newText, [System.Text.Encoding]::UTF8)
}
