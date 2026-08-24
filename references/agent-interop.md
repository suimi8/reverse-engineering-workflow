# Agent Interoperability

## Entrypoints

- Codex: `SKILL.md`
- Claude Code: `CLAUDE.md`
- OpenClaw Agent: `AGENTS.md` or `SKILL.md`
- Hermes Agent: `AGENTS.md` or `SKILL.md`
- Other agents: `AGENTS.md` plus references on demand

## Expected Agent Behavior

- Read only the entrypoint first.
- Load references only when the task needs that area.
- Use scripts as templates; adapt paths and logging names to the current workspace.
- Use `scripts/invoke_skill.ps1 -TaskText <goal> [-TargetPath <path>]` as the fixed reusable entrypoint when a caller wants automatic concrete internal-module selection.
- Use `scripts/list_skills.ps1 -AsJson` when a machine-readable internal-module registry is better than parsing Markdown.
- Use `scripts/resolve_skill.ps1 -Query <name-or-display-name-or-path> -AsJson` when a single reusable module must be selected deterministically.
- Use `scripts/select_skill.ps1 -TaskText <goal> [-TargetPath <path>] -AsJson` when the agent should automatically choose an existing concrete internal module from the task.
- Prefer `scripts/re_workflow_entry.ps1` for unknown target routing and `scripts/healthcheck.ps1` after editing the skill package.
- Load `references/reusable-invocation-contract.md` when integrating this package into another agent, wrapper, or automation layer.
- Prefer local repo patterns and small diffs.
- Report decisive evidence, not full noisy dumps.

## Trigger Phrases

Use this skill for:
- "逆向", "脱壳", "源码丢失", "恢复功能"
- "点击后崩溃/卡死/闪退"
- "窗口/弹窗/Qt/PyQt/Nuitka"
- "自动更新/强制更新/停用弹窗分析"
- "打包逆向包/分发包/运行包"

## Task Recipes

Load `references/reverse-task-recipes.md` when the agent needs a short command-first route for PE/ELF, APK/mobile, GUI/runtime, auth/update/network, or packaging tasks without loading broad methodology references.
