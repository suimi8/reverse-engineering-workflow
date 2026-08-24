---
name: competition-pcap-protocol
description: Internal downstream skill for ctf-sandbox-orchestrator. CTF-sandbox workflow for packet capture analysis, session reconstruction, application-protocol decoding, stream reassembly, beacon timing, and packet-to-process correlation. Use when the user asks to analyze a PCAP, rebuild TCP or UDP sessions, decode HTTP, WebSocket, DNS, custom C2, or binary protocols, extract transferred artifacts, or tie packet sequences to host or malware behavior. Use only after `$ctf-sandbox-orchestrator` has already established sandbox assumptions and routed here.
---

中文名：suimi PCAP协议比赛

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

新技能/方法反馈：无/有（请保留并更新此项）
finish_skill_run.ps1：完成时调用
record_skill_lesson.ps1：有新方法时调用
review_skill_lessons.ps1：定期审查
promote_skill_lesson.ps1：成熟后推广

# Competition PCAP Protocol

Use this skill only as a downstream specialization after `$ctf-sandbox-orchestrator` is already active and has established sandbox assumptions, node ownership, and evidence priorities. If that has not happened yet, return to `$ctf-sandbox-orchestrator` first.

Use this skill when the decisive evidence sits inside packet order, protocol framing, or stream reconstruction rather than a single IOC or host log.

Reply in Simplified Chinese unless the user explicitly requests English.


## Core Skill Map

如果你拥有完整仓库，优先结合这些专题文档一起使用：

- [Ctf Sandbox Orchestrator](../ctf-sandbox-orchestrator/MODULE.md)


## Quick Start

1. Establish the capture boundaries first: hosts, time span, interfaces, missing packets, retransmits, and stream count.
2. Group traffic into sessions before decoding payload semantics.
3. Record protocol framing, sequence, timing, and transferred artifacts together instead of as isolated packets.
4. Correlate packet evidence with host, malware, or app behavior only after the session is reconstructed.
5. Reproduce the smallest decoded stream or transferred artifact that proves the challenge path.

## Workflow

### 1. Build The Session Map

- Identify endpoints, protocols, ports, TLS handshakes, DNS lookups, websocket upgrades, and long-lived streams.
- Note missing capture coverage, asymmetric routing, packet loss, or reassembly issues before drawing conclusions.
- Separate control channels, bulk transfers, keepalives, and noise.

### 2. Decode The Protocol Boundary

- Reassemble TCP streams or UDP conversations before interpreting fields.
- Recover framing, message order, custom headers, binary fields, compression, encryption boundaries, and object transfers.
- Keep payload direction, timing, and session state aligned with each decoded message.

### 3. Tie Packets To Behavior

- Show which packet sequence maps to which host event, malware branch, login flow, upload, exfiltration step, or command channel.
- Distinguish protocol recognition from artifact recovery: naming HTTP, DNS, or a custom C2 is not enough without decoded content or proven downstream effect.
- If the task becomes mostly a host timeline problem after decode, switch to the tighter forensic timeline skill.

## Read This Reference

- Load `references/pcap-protocol.md` for the session checklist, decode checklist, and evidence packaging.
- If the hard part is a WebSocket or SSE handshake, subscription flow, realtime frames, or frame-driven state, prefer `$competition-websocket-runtime`.
- If the hard part is a custom handshake, framing, checksum, sequence dependency, or deterministic replay harness, prefer `$competition-custom-protocol-replay`.

## What To Preserve

- Stream IDs, endpoint pairs, packet ranges, timestamps, protocol framing, and object boundaries
- Decoded requests, responses, commands, transferred files, and the session that carried them
- The exact packet sequence or reconstructed stream that proves the challenge behavior