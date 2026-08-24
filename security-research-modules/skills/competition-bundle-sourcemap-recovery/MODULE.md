---
name: competition-bundle-sourcemap-recovery
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for source maps, build manifests, chunk registries, emitted bundles, obfuscated loader flow, and frontend runtime recovery. Use when the user asks to reconstruct served JavaScript structure, inspect source maps or chunk maps, trace bundle loading, recover hidden routes or APIs from emitted assets, or explain runtime behavior from built frontend artifacts. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi 前端Sourcemap恢复比赛

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition Bundle Sourcemap Recovery

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when runtime truth lives in built assets, source maps, chunk tables, or obfuscated loader flow rather than in checked-in source alone.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Start from the served artifact set: entry HTML, build manifest, bootstrap bundle, chunk map, and source maps.
2. Record chunk ids, route chunks, loader functions, endpoint strings, and config keys before broad manual deobfuscation.
3. Reconstruct the smallest runtime graph that explains which asset executes now.
4. Keep served artifact truth separate from repository source unless parity is proven.
5. Reproduce the smallest asset-to-runtime boundary that proves the decisive behavior.

## Workflow

### 1. Map The Served Artifact Set

- Record entry HTML, script tags, preload hints, manifest files, asset map, chunk registry, and source map URLs.
- Note framework-specific artifacts such as route manifests, client reference manifests, or lazy-loader tables when present.
- Keep emitted filenames, hash suffixes, and route ownership tied together.

### 2. Reconstruct Runtime Structure

- Follow bootstrap code, chunk loaders, module registry, string decoders, and lazy import boundaries.
- Use source maps, manifest files, and stable symbol clusters to recover route names, API calls, feature flags, and hidden panels.
- Distinguish build-time intent from the bundle that is actively served now.

### 3. Reduce To The Decisive Bundle Path

- Compress the result to the smallest sequence: served asset -> loader path -> module or symbol -> runtime effect.
- State clearly whether the decisive weakness lives in manifest drift, chunk loading, hidden route code, string decoding, or stale source assumptions.
- If the task shifts from built assets to SSR or template enforcement, hand back to the tighter template-render skill.

## Read This Reference

- Load `references/bundle-sourcemap-recovery.md` for the artifact checklist, deobfuscation checklist, and evidence packaging.

## What To Preserve

- Served filenames, chunk ids, manifest entries, source map paths, recovered symbols, and endpoint strings
- The exact executing bundle or module that proves the runtime branch
- One minimal asset-to-runtime sequence that reaches the decisive effect