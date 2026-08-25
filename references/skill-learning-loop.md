# Skill Learning Loop

Use this reference when a reverse-engineering task produces a reusable method, a surprising pivot, or a tool workflow that should improve future tasks.

## Goal

Capture new reverse-engineering knowledge without polluting core modules with one-off target details. Record candidates automatically, then promote only validated, reusable lessons into the narrowest appropriate internal `MODULE.md` or reference file.

## Automatic Trigger

At the end of every reverse-engineering task, and immediately after any pivot that unblocks a stalled analysis, run this check:

1. Did this task reveal a method, ordering rule, tool command, bypass pattern, failure mode, or validation signal that would change how the next similar task is handled?
2. Is the lesson reusable beyond the current target?
3. Can it be stated as a reusable technique instead of a one-off target note?
4. Is there evidence: runtime behavior, traffic shape, file format, disassembly pattern, log output, or a before/after verification result?

If all four are true, record a candidate lesson.

## Candidate Capture

Use `scripts/record_skill_lesson.ps1` from the skill root:

```powershell
.\scripts\record_skill_lesson.ps1 `
  -Title "Short reusable lesson" `
  -Category method `
  -AppliesTo "packed Windows GUI binaries" `
  -PurposeZh "中文简要说明这个候选技能解决什么问题、什么时候有用。" `
  -TargetSkillPath "references/unpacking.md" `
  -Evidence "What proved the lesson." `
  -Lesson "The reusable rule or workflow." `
  -Validation "How it was verified." `
  -NextAction "Promote to references/unpacking.md after one more matching case." `
  -Tags packer,gui,runtime
```

The script appends to `references/skill-learning-inbox.md`. Use the inbox as a review queue, not as final doctrine.

## Pending Notice

Use `scripts/pending_skill_lessons.ps1` to tell the user which new reverse lessons are waiting to be reviewed or promoted:

```powershell
.\scripts\pending_skill_lessons.ps1
.\scripts\pending_skill_lessons.ps1 -AsJson
```

Run it before closing long reverse-engineering sessions or when the user asks what new methods are waiting to be added.

## Mandatory End-of-Run Report

Every run that used this skill must end with a `新技能/方法反馈` section in the final user response. This report is mandatory even when no new method was found.

Use `scripts/finish_skill_run.ps1` to generate the stable report fields:

```powershell
.\scripts\finish_skill_run.ps1
.\scripts\finish_skill_run.ps1 -NewLessonCount 1 -SuggestedTitle "Short reusable lesson"
.\scripts\finish_skill_run.ps1 -AsJson
```

The final response must include:

- `是否发现新技能/方法`: `是` or `否`.
- `发现的新技能/方法`: list each current-run reusable method title, or `无`.
- `候选技能作用`: for each pending candidate, include a short Chinese description of what the skill/method is for.
- `本次发现数量`: number of current-run reusable methods found.
- `建议加入数量`: number of current-run suggestions.
- `建议是否加入 skills`: `是`, `否`, or `需要审查`, plus a short reason.
- `如何添加到本 skills`: show the record, review, and promote command pattern.
- Current pending lesson count or the relevant pending lesson IDs when there are existing candidates.

`scripts/healthcheck.ps1` enforces this contract across the root entrypoints and every bundled direct internal `MODULE.md`. A missing `新技能/方法反馈`, `finish_skill_run.ps1`, or record/review/promote command reference is a package failure.

If a reusable lesson was found, add it to the inbox first:

```powershell
.\scripts\record_skill_lesson.ps1 `
  -Title "<lesson>" `
  -Category method `
  -AppliesTo "<scope>" `
  -PurposeZh "<中文简要说明这个候选技能的作用>" `
  -TargetSkillPath "<target.md>" `
  -Evidence "<proof>" `
  -Lesson "<reusable rule>" `
  -Validation "<verification>" `
  -NextAction "review"
```

Then review and promote:

```powershell
.\scripts\review_skill_lessons.ps1 -Status candidate
.\scripts\promote_skill_lesson.ps1 -Id "<id>" -DestinationPath "<target.md>"
```

## Candidate Review

Use `scripts/review_skill_lessons.ps1` before promotion or after several tasks:

```powershell
.\scripts\review_skill_lessons.ps1 -AsJson
.\scripts\review_skill_lessons.ps1 -Status candidate
```

The review flags missing evidence, missing validation, unresolved target paths, and duplicate lesson text.

## What To Record

- New triage ordering that saves time or prevents false conclusions.
- A recurring static pattern and the minimum evidence needed to trust it.
- A runtime hook, probe, or dump technique that worked better than static analysis.
- A packaging, signing, ABI, manifest, or integrity failure mode with a narrow fix.
- A tool invocation pattern that is easy to forget and repeatedly useful.
- A negative lesson: a path that looked plausible but wasted time, plus the signal that rules it out next time.

## What Not To Record

- One-off target notes that do not change future workflow.
- A full exploit chain when the reusable lesson is just a detection or validation rule.
- Decompiler guesses without runtime, traffic, binary-format, or repeatable static evidence.
- Broad moral conclusions such as "try dynamic analysis" without a concrete trigger and action.

## Promotion Rules

Promote a candidate into a real skill or reference only when it passes these gates:

1. **Reusable:** It applies to a class of targets, not one file.
2. **Evidence-backed:** The entry names the signal that proves the pattern.
3. **Actionable:** It changes a command, breakpoint, hook, patch point, checklist, or routing decision.
4. **Minimal:** It belongs in the narrowest internal module or reference, not the root skill by default.
5. **Scoped:** It belongs in a durable skill/reference, not only in a task note.
6. **Review-clean:** `scripts/review_skill_lessons.ps1` reports no missing evidence, missing validation, duplicate lesson text, invalid target, or undecided target for the entry.

After promotion, update the inbox entry status to `promoted`, add the destination path in `Next Action` or a short note, and sync the updated source package into the installed Codex skill directory.

Use `scripts/promote_skill_lesson.ps1` for mechanical promotion:

```powershell
.\scripts\promote_skill_lesson.ps1 `
  -Id "20260608-010203-example" `
  -DestinationPath "references/dynamic-hooking.md"
```

The script refuses rejected, already promoted, unresolved, or review-unclean entries. Candidate entries require `-AllowCandidate`; this only bypasses the candidate status gate, not the evidence, validation, duplicate, or target-quality gates. Prefer validating first.

By default, promotion runs `scripts/sync_installed_skill.ps1` after writing the destination file, so the installed skill directory is updated immediately. Use `-SkipInstalledSync` only for offline editing or when a caller will run installation sync separately.

## Placement Map

- General task ordering, routing, or escalation: root `SKILL.md` or `references/reverse-task-recipes.md`.
- PE/ELF static triage, IDA/Ghidra/x64dbg: `references/static-analysis.md`.
- Packers, OEP, dumps, imports: `references/unpacking.md`.
- Runtime hooks, Frida, probes: `references/dynamic-hooking.md`.
- PE byte patching and rollback: `references/pe-patching.md`.
- APK decode, smali, rebuild, signing: `github-reverse-modules/skills/apk-reverse/MODULE.md` or its references.
- APK package migration and residue audits: `references/apk-package-rename.md`.
- Mobile root/jailbreak/pinning/detection bypass: `github-reverse-modules/skills/mobile-reverse/references/`.
- Broad cross-platform RE patterns: `github-reverse-modules/skills/reverse-engineering/field-notes.md`.
- Reverse-discovered Web/API/Auth surfaces: the narrow `security-research-modules/skills/*/MODULE.md`.

## End-of-Task Learning Check

Before closing a reverse-engineering task:

1. Review the final working path and the wrong turns.
2. Extract at most one or two lessons that would help the next task.
3. Prefer a candidate inbox entry over editing a core skill immediately.
4. Promote only after validation or when the lesson is obviously generic and low-risk.
5. Run `scripts/healthcheck.ps1` after editing any skill package file.
6. Include the mandatory `新技能/方法反馈` section in the final user response.

## Promoted Learning Notes

### 触发词闸门检查法-验证skill自动调用链路

- source: `20260825-063349-触发词闸门检查法-验证skill自动调用链路`
- category: method
- applies_to: skill auto-invocation / pi skills routing verification
- purpose_zh: 验证自动调用链路时，先检查根 SKILL.md description 覆盖目标场景触发词，再测 invoke_skill 路由
- confidence: 4/5

**Lesson**

验证 skill 自动调用时，不能只测 invoke_skill 路由，必须先检查根 SKILL.md 的 description 是否覆盖目标场景触发词。Pi 启动时提取 name+description 注入系统提示，模型据此判断是否加载 skill——description 漏了触发词（nmap/sqlmap/src挖洞等），后面路由全白搭。

**Evidence**

在 pentest-tools 导入完成后，检查根 SKILL.md description 发现无渗透测试触发词（nmap/sqlmap/src/bounty 全为 0），导致自动调用链路断裂。添加后 description 覆盖 nmap/sqlmap/src挖洞/bug bounty 等，新会话后可触发。

**Validation**

YAML 校验通过，healthcheck 24/24 PASS，invoke_skill 实测路由 pentest-tools 0.94。

### promote_skill_lesson 超时判定法

- source: `20260825-103459-promote-skill-lesson-超时判定法`
- category: method
- applies_to: general reverse workflow
- purpose_zh: promote 脚本输出超时但实际成功时的正确判定与处理
- confidence: 3/5

**Lesson**

promote_skill_lesson.ps1 在 Windows PowerShell 5.1 下常出现命令输出超时（60s 未返回）但实际已成功写入的现象；判定依据是目标文件（如 references/module-onboarding-spec.md）中是否出现 '- source: <id>' 且 inbox 条目状态变为 promoted，而非命令退出码；确认成功后不要重跑（会报 already promoted 错误），直接继续验证（healthcheck + sync_installed_skill）

**Evidence**

两次实践（20260825-094952 三层接入、20260825-101848 路由规则补全）均出现 60s 超时后实际成功：grep 确认 module-onboarding-spec.md 已含 source 行、inbox status=promoted，healthcheck 24/24 PASS

**Validation**

2026-08-25 第三次实践验证：本次 promote 20260825-103459 再次出现 60s 超时，grep 确认目标文件已含 source 行、inbox status=promoted；与前两次（094952、101848）行为一致，判定法可靠。