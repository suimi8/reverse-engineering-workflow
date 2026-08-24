---
name: ctf-sandbox
description: Thin PRIMARY for CTF / AWD / 靶场 multi-type orchestration. Hands off to the sidecar CTF-Sandbox-Orchestrator. Use when the user says CTF, AWD, 靶场, or 比赛题 and no more specific pwn/APK/IDA route already won.
---


中文名：suimi CTF沙箱

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# CTF sandbox entry (sidecar, not a second router)

## 为什么单独一层

`CTF-Sandbox-Orchestrator/` 是 **GPL 旁路包**，授权默认是沙箱内部。核心路由包仍是 MIT + `scope.md` 门禁。本 skill 只做关键词入口，不把竞赛树并进核心。

## 任务完成自检（声称完成前 MUST 通过）

- [ ] 我是否先走了 case-init / scope，而不是把“用户说了 CTF”当成已授权外网？
- [ ] 我是否打开了 sidecar orchestrator，而不是把 40 个子技能当 PRIMARY？
- [ ] 若任务其实是 pwn/APK/IDA，我是否让更具体的 PRIMARY 接手？
