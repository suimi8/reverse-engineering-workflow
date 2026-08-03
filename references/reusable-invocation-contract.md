# Reusable Invocation Contract

Use this contract when another agent, script, or wrapper needs to call this single installable skill package without parsing Markdown tables.

For multi-agent distribution, treat this file as the primary external integration document. It defines stable commands, JSON fields, routing behavior, and health gates for callers that should not load the whole skill package into context.

## Stable Commands

Prefer JSON output for machine calls:

```powershell
.\scripts\healthcheck.ps1 -AsJson
.\scripts\invoke_skill.ps1 -TaskText "<goal>" -TargetPath "<target>" -AsJson
.\scripts\list_skills.ps1 -AsJson
.\scripts\resolve_skill.ps1 -Query "mobile-reverse" -AsJson
.\scripts\select_skill.ps1 -TaskText "<goal>" -TargetPath "<target>" -AsJson
.\scripts\re_workflow_entry.ps1 -TargetPath "<target>" -Intent auto -TaskText "<goal>" -NoExecute -AsJson
.\scripts\finish_skill_run.ps1 -NewLessonCount 0 -AsJson
.\scripts\record_skill_lesson.ps1 -Title "<lesson>" -Category method -PurposeZh "<中文作用简述>" -Evidence "<proof>" -Lesson "<rule>"
.\scripts\review_skill_lessons.ps1 -Status candidate
.\scripts\promote_skill_lesson.ps1 -Id "<id>" -DestinationPath "<target.md>"
.\scripts\sync_installed_skill.ps1 -AsJson
```

Use human-readable output only for interactive debugging.

## Fixed Entrypoint

Use `scripts/invoke_skill.ps1` as the stable one-command entrypoint for external callers.

```powershell
.\scripts\invoke_skill.ps1 -TaskText "SQL injection parameter test"
.\scripts\invoke_skill.ps1 -TaskText "mobile frida apk analysis" -TargetPath .
.\scripts\invoke_skill.ps1 -TaskText "firmware unpack and static analysis" -Output path
.\scripts\invoke_skill.ps1 -TaskText "SQL injection parameter test" -Output content
```

Output modes:

- `summary`: human-readable selected skill summary.
- `path`: repository-relative selected root `SKILL.md` or internal `MODULE.md` path.
- `content`: selected root `SKILL.md` or internal `MODULE.md` content for direct agent loading.
- `-AsJson`: machine-readable selection object with repository-relative `skill_path`, selected `skill`, route data, confidence, and optional `skill_content`.

Prefer this command unless the caller specifically needs registry listing, exact-name resolution, or lower-level route diagnostics.

## Skill Registry

`scripts/list_skills.ps1 -AsJson` returns:

- `ok`: true when all returned skills have machine name, display name, path, category, and description.
- `category`: requested category filter: `all`, `root`, `github-reverse`, `local-reverse`, or `security`.
- `count`: number of returned skills.
- `missing_metadata`: count of incomplete skill metadata entries.
- `skills[]`: reusable module records.

Each `skills[]` item contains:

- `name`: machine skill name from YAML frontmatter.
- `display_name`: Chinese human-facing name from `references/chinese-skill-names.json`.
- `category`: module category.
- `path`: repository-relative root `SKILL.md` or internal `MODULE.md` path to load.
- `description`: trigger and capability summary.
- `bytes`, `lines`: size hints for context planning.

## Skill Resolver

`scripts/resolve_skill.ps1 -Query <value> -AsJson` resolves one module from the registry.

Resolution order:

1. Exact `name`, `display_name`, or `path`.
2. Unique partial match across `name`, `display_name`, `path`, or `description`.
3. Otherwise return `ambiguous` or `not-found`.

Return fields:

- `ok`: true only when one skill is selected.
- `status`: `found`, `ambiguous`, or `not-found`.
- `skill`: selected reusable module when `ok` is true.
- `matches[]`: candidate modules for found or ambiguous results.
- `message`: short reason.

Use `-Category` to narrow ambiguous security or reverse-module queries.

## Skill Selector

`scripts/select_skill.ps1 -TaskText <goal> -AsJson` chooses a concrete existing internal `MODULE.md` from task text. Add `-TargetPath <path>` when a local target exists; the selector will consult `re_workflow_entry.ps1` first and then fall back to task-text rules.

Return fields:

- `ok`: true when one concrete skill is selected.
- `status`: `selected` or `not-found`.
- `source`: `target-router`, `task-rule`, or `fallback-root`.
- `confidence`: routing confidence from 0 to 1.
- `skill`: selected reusable module.
- `candidates[]`: matched skill candidates when task rules found more than one direction.
- `route_decision`: target-router decision when `-TargetPath` was provided.
- `reason`: short selection reason.

Mixed security routing:

- When exactly one concrete security topic matches, the selector returns that topic skill directly.
- When multiple concrete security topics match, the selector returns a category router first and keeps the concrete topic skills in `candidates[]`.
- API-oriented mixed matches return `security-research-modules/skills/api-sec/MODULE.md`.
- Other mixed security matches return `security-research-modules/skills/hack/MODULE.md`.

Use the selector when the caller wants automatic task-to-skill selection. Use the resolver when the caller already knows the machine name, Chinese display name, or path.

## Target Router

`scripts/re_workflow_entry.ps1` classifies a target and returns the first reusable route.

Stable fields for callers:

- `target_type`: `directory`, `pe`, `elf`, `apk`, `apkish`, or `other`.
- `target_profile`: target specialization; currently `generic` unless future local modules add profiles.
- `effective_intent`: normalized intent.
- `route`: first workflow route.
- `module_entry`: repository-relative module/reference path to load next.
- `next_action`: concise instruction for the caller.
- `wpegpt_ready`, `pe_summary_ready`: environment capability flags.

Always use `-NoExecute -AsJson` when the caller only wants routing. Omit `-NoExecute` only when it should run the selected automated route.

## End-of-Run Skill Feedback

`scripts/finish_skill_run.ps1 -AsJson` is the stable contract for the mandatory final `新技能/方法反馈` section. Call it before closing any run that used the root workflow or a bundled reverse internal module.

Examples:

```powershell
.\scripts\finish_skill_run.ps1 -AsJson
.\scripts\finish_skill_run.ps1 -NewLessonCount 1 -SuggestedTitle "Runtime hook before static patch" -AsJson
.\scripts\finish_skill_run.ps1 -RecommendAdd review -Reason "Existing validated lessons are waiting." -AsJson
```

Return fields:

- `ok`: true when the report contract is usable.
- `required_final_section_title`: always `新技能/方法反馈`; callers should include this section title in the final response.
- `discovered_new_skill`: true when the current run declared at least one new reusable method.
- `discovered_new_skill_count`: number of current-run reusable methods found.
- `discovered_new_skill_titles[]`: current-run reusable method titles; empty when none were found.
- `suggested_add_count`: number of current-run methods recommended for candidate capture.
- `recommended_to_add`: true only when the recommendation is to add current-run lessons to the learning inbox.
- `recommendation`: `yes`, `no`, or `review`.
- `reason`: short user-facing reason for the recommendation.
- `inbox_path`: repository-relative learning inbox path.
- `current_pending_count`, `candidate_count`, `validated_count`: pending lesson totals.
- `suggested_titles[]`: current-run suggestion titles passed by the caller.
- `pending_items[]`: existing candidate or validated lessons with id, status, title, Chinese purpose summary, target path, and promotion command.
- `how_to_add[]`: stable command patterns for record, review, and promotion.

Callers must still make the final judgment about whether the current run produced a reusable lesson. Use `record_skill_lesson.ps1` first when `suggested_add_count` is greater than zero and the lesson has concrete evidence.
Then run `review_skill_lessons.ps1` and promote validated lessons with `promote_skill_lesson.ps1`.
Promotion automatically calls `sync_installed_skill.ps1` unless `-SkipInstalledSync` is passed, so adding a candidate to skills updates the installed Codex skill copy as part of the same command.

## Health Check

`scripts/healthcheck.ps1 -AsJson` is the package gate for reusable invocation. It validates:

- Manifest and manifest paths.
- Root, GitHub reverse, optional local reverse, and security skill frontmatter.
- Parsed descriptions, including rejection of unresolved YAML block-scalar placeholders such as `|` or `>-`.
- Skill registry and resolver.
- Automatic concrete skill selector.
- Reusable route regressions.
- Single installable skill packaging: exactly one discoverable `SKILL.md` at package root, with bundled internal modules stored as `MODULE.md`.
- Mandatory final-feedback contract coverage across root entrypoints and bundled direct internal `MODULE.md` files.
- Chinese display-name synchronization.
- PowerShell, Python, and Bash syntax.
- Optional WPeGPT readiness.
- Generated cache absence.

Treat any `fail` as blocking for package reuse. `warn` entries are environment-dependent unless the current task requires that dependency.

## Installed Skill Sync

`scripts/sync_installed_skill.ps1` is the local installation updater for this single installable package. Run it from the source package after edits; it validates package shape, runs `healthcheck.ps1` unless `-SkipHealthcheck` is passed, stages a copy under `$HOME\.codex\skills`, then replaces only the destination skill directory.

Stable fields:

- `ok`: true when sync or dry-run completed.
- `action`: `synced`, `would-sync`, or `no-op`.
- `source`: source package path.
- `destination`: installed package path.
- `installed_skill_md`, `installed_module_md`: post-sync package shape.
- `healthcheck_ok`: source healthcheck result when run.

Use `-DryRun -AsJson` to inspect the action without changing the installed copy. Use `-DestRoot <path>` only when installing into a non-default skills root.

## Compatibility Rules

- Keep machine names and folder names stable.
- Add new reusable modules to `references/chinese-skill-names.json`.
- Keep only the root `SKILL.md` installable. Store bundled internal modules as `MODULE.md` with YAML frontmatter containing `name` and `description`.
- Prefer adding deterministic scripts or references over expecting callers to parse prose.
- After any change, run `.\scripts\healthcheck.ps1`.
