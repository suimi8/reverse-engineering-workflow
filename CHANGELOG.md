# Changelog

本技能包所有值得记录的变更都记录在此文件。格式参考 Keep a Changelog。版本号与 `manifest.json` 保持一致。



## [1.23.2] - 2026-08-25

unify web reverse routing through single root entry (reverse-engineering-workflow); merge 3 web rules into one

## [1.23.1] - 2026-08-25

add web-api-reverse / web-js-reverse / web-crypto-reverse modules; routing-rules.json extraction

## [Unreleased]

### Changed

- `github-reverse-modules/skills/js-reverse/references/gcaptcha4-captcha-re.md`：**极验 v4 逆向专案更新**——补充 w 加密完整算法（AES-CBC 变体 + RSA-1024 PKCS1v15）、CryptoJS 细节（iv=ASCII '0'×16、nRounds=6+keyWords）、Python 复现核心代码、验证证据表（3 组 AES 向量 + 完整 w 对照）、协议可用性缺口（ctct_bundle 加密 / NWAF / register 403）。

### Fixed

- 修复 `references/skill-learning-inbox.md` 结构损坏：被吞进上一条目的 Nuxt3 SSR 经验条目恢复为独立条目；被晋级行粘连的 HAR、Vite 两条经验恢复可解析（此前解析器只识别到 4/7 条）；APK smali 经验的晋级目标更正为 `github-reverse-modules/skills/apk-reverse/MODULE.md`，并清理 `security-research-modules/skills/recon-for-sec/MODULE.md` 中错误的 "APK smali" 标题（该小节实为 Nuxt3 前端经验）。

### Added

- `github-reverse-modules/skills/web-api-reverse/`：**suimi Web 后端 API 逆向**——从网络请求/HAR/cURL 逆向内部 API 协议，REST/GraphQL/batchexecute/gRPC-web 多协议检测、认证检测、生成 Python httpx / TypeScript 客户端 + API 文档，含七阶段多智能体流水线与回放验证。
- `github-reverse-modules/skills/web-js-reverse/`：**suimi Web 前端 JS 逆向**——JS 混淆分级与还原、JSVMP 五步逆向法、CDP 检测绕过、TLS/HTTP2/QUIC 指纹、环境修补、WASM 逆向、反爬分层击破；携带 12 份精选 references。
- `github-reverse-modules/skills/web-crypto-reverse/`：**suimi Web/APK 加密算法逆向**——从 Web JS 与 Android APK 识别并 Python 重构加密/签名算法，30 个 specialist 索引、Web2/Web3 判定、线上验证闭环。
- `scripts/routing-rules.json`：路由规则独立配置文件（3 条新 web 逆向规则），`select_skill.ps1` 改为从该文件加载；`healthcheck.ps1` 同步改为校验该文件。
- `README.md`：人类可读的项目总览与使用说明。
- `CHANGELOG.md`：变更记录。
- `scripts/package_release.ps1` 与 `scripts/lib/Release.ps1`：健康检查门禁的发布打包脚本，支持 manifest 版本自增（patch/minor）、CHANGELOG 自动追加、确定性 zip 打包与 SHA256 校验、DryRun 预览。
- `tests/`：Pester 单元测试套件（`routing.Tests.ps1`、`skill-learning.Tests.ps1`、`release-utils.Tests.ps1`）与 `tests/run_tests.ps1` 运行器；`healthcheck.ps1` 新增 `unit-tests` 检查项。
- `.gitignore` 与 git 基线。

## [1.23.0] - 2026-07-27

- 技能包基线导入：自动路由入口、references 方法论、github/local/security 三类内部模块、WPeGPT/IDA 集成、学习闭环与健康检查。
