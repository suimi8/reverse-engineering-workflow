---
name: competition-websocket-runtime
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for WebSocket and SSE handshakes, auth material, subscription state, realtime message schemas, reconnect behavior, and frame-driven runtime effects. Use when the user asks to inspect a WebSocket or SSE handshake, decode frames, trace subscriptions, follow reconnect logic, inspect auth material sent during realtime setup, or explain how live frames change rendered or persisted state. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi WebSocket运行时比赛

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition WebSocket Runtime

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the decisive behavior is carried by realtime handshake and frame flow rather than one-shot HTTP alone.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Map the handshake first: origin, path, headers, cookies, query, auth token, and upgrade response.
2. Separate connection setup, subscription messages, keepalives, server pushes, and reconnect logic.
3. Record message schema, topic or channel identity, and state side effects in one chain.
4. Tie frames to rendered, stored, or backend-visible effects.
5. Reproduce the smallest handshake-plus-frame sequence that reaches the decisive state change.

## Workflow

### 1. Map The Realtime Handshake

- Record the initial HTTP or SSE request, upgrade headers, cookies, tokens, query params, origin checks, and negotiated protocol.
- Note whether auth material is carried by headers, cookies, query strings, or initial application frames.
- Keep route, subscription endpoint, and session identity tied together.

### 2. Decode Message Flow

- Separate subscribe, unsubscribe, ack, heartbeat, server push, reconnect, and terminal frames.
- Recover message types, channel IDs, schema fields, and sequencing that matter to behavior.
- Distinguish transport keepalive from application-level business messages.

### 3. Reduce To The Decisive Realtime Path

- Compress the result to the smallest sequence: handshake -> auth or subscribe frame -> pushed or accepted frame -> resulting state change.
- Keep canonical frame order and any replayed minimal order side by side.
- If the hard part is generic protocol reassembly without runtime UI or app-state linkage, switch back to the tighter protocol skill.

## Read This Reference

- Load `references/websocket-runtime.md` for the handshake checklist, frame checklist, and evidence packaging.

## What To Preserve

- Handshake headers, cookies, query params, auth material, negotiated subprotocol, and channel IDs
- Frame schemas, subscription messages, server pushes, reconnect flow, and resulting state changes
- The smallest replayable realtime sequence that proves the decisive branch