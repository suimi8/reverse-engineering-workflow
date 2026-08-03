# Changelog

本技能包所有值得记录的变更都记录在此文件。格式参考 Keep a Changelog。版本号与 `manifest.json` 保持一致。

## [Unreleased]

### Fixed

- 修复 `references/skill-learning-inbox.md` 结构损坏：被吞进上一条目的 Nuxt3 SSR 经验条目恢复为独立条目；被晋级行粘连的 HAR、Vite 两条经验恢复可解析（此前解析器只识别到 4/7 条）；APK smali 经验的晋级目标更正为 `github-reverse-modules/skills/apk-reverse/MODULE.md`，并清理 `security-research-modules/skills/recon-for-sec/MODULE.md` 中错误的 "APK smali" 标题（该小节实为 Nuxt3 前端经验）。

### Added

- `README.md`：人类可读的项目总览与使用说明。
- `CHANGELOG.md`：变更记录。
- `scripts/package_release.ps1` 与 `scripts/lib/Release.ps1`：健康检查门禁的发布打包脚本，支持 manifest 版本自增（patch/minor）、CHANGELOG 自动追加、确定性 zip 打包与 SHA256 校验、DryRun 预览。
- `tests/`：Pester 单元测试套件（`routing.Tests.ps1`、`skill-learning.Tests.ps1`、`release-utils.Tests.ps1`）与 `tests/run_tests.ps1` 运行器；`healthcheck.ps1` 新增 `unit-tests` 检查项。
- `.gitignore` 与 git 基线。

## [1.23.0] - 2026-07-27

- 技能包基线导入：自动路由入口、references 方法论、github/local/security 三类内部模块、WPeGPT/IDA 集成、学习闭环与健康检查。
