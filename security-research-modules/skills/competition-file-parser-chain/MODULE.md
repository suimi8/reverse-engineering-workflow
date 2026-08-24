---
name: competition-file-parser-chain
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for file uploads, imports, previews, archive extraction, format conversion, parser invocation, and deserialization chains. Use when the user asks to inspect an upload or import path, trace archive extraction, preview or converter behavior, explain how a file reaches a parser or deserializer, or connect one uploaded artifact to the decisive backend effect. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi 文件解析链比赛

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition File Parser Chain

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the hard part is following a file from ingress through every parser, extractor, converter, or deserializer boundary that matters.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Preserve the original upload and every derived artifact separately.
2. Map the chain in order: ingress, temp storage, archive extraction, format conversion, parser call, deserialization, and final consumer.
3. Record filenames, MIME guesses, extensions, temp paths, and parser choices before mutating anything.
4. Separate client-visible validation from backend parser behavior.
5. Reproduce the smallest file-processing chain that yields the decisive branch or artifact.

## Workflow

### 1. Map File Ingress And Derivation

- Record request shape, multipart names, content type, filename, temp paths, upload staging, and storage keys.
- Note every derived artifact: extracted archive member, converted preview, generated thumbnail, temp document, or deserialized object.
- Keep original file and each derivative labeled separately.

### 2. Trace Parser And Conversion Boundaries

- Show which parser, converter, extractor, or deserializer runs at each step.
- Record parser-specific decisions driven by extension, MIME, magic bytes, schema, archive member names, or embedded metadata.
- Distinguish parsing success, preview success, conversion success, and business-logic acceptance.

### 3. Reduce To The Decisive File Chain

- Compress the result to the smallest sequence: upload -> derived artifact -> parser boundary -> resulting effect.
- State clearly whether the decisive weakness lives in archive handling, MIME inference, file conversion, path resolution, or deserialization.
- If the chain becomes mostly a generic async worker problem after enqueue, hand off to the tighter queue or worker skill.

## Read This Reference

- Load `references/file-parser-chain.md` for the ingress checklist, parser checklist, and evidence packaging.

## What To Preserve

- Original uploads, derived files, temp paths, storage keys, parser names, and conversion steps
- The exact boundary where backend behavior diverges from user-visible validation
- One minimal replayable file-processing sequence that reaches the decisive effect