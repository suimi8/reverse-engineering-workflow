---
name: browser-extension-reverse
description: Use for authorized reverse engineering of browser extensions (Chrome/Firefox) including manifest analysis, background workers, and extension-based credential or traffic logic recovery.
---


中文名：suimi 浏览器扩展逆向

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# Browser Extension Reverse Engineering

## 适用场景

- Chrome/Edge MV2/MV3 扩展分析
- Firefox 扩展
- 恶意扩展 IOC、供应链扩展投毒调查
- 扩展实现的签名/加密/代理逻辑还原

## 工作流

### 1. 包体

```text
□ crx 解压 / 从 profile 取扩展目录
□ manifest.json：permissions、host_permissions、background、content_scripts
□ 评估过度权限（<all_urls>、webRequest、debugger）
```

### 2. 逻辑

```text
□ service_worker / background 入口
□ content_script 注入点与世界（isolated）
□ chrome.storage / IndexedDB 密钥
□ 与 `js-reverse` 相同：Observe 网络与消息传递（runtime.sendMessage）
```

### 3. 动态

```text
□ 开发者模式加载解压目录
□ chrome://extensions 检查错误
□ DevTools 附加 service worker
□ 必要时 Frida/浏览器 CDP（jshookmcp）
```

## 工具链

| 工具 | 用途 |
|------|------|
| 解压/jq | manifest |
| Chrome DevTools | worker 调试 |
| js-reverse 工具链 | 深度 JS |
| YARA | 恶意扩展规则 |

## 参考

- `references/extension-analysis.md`
- field-journal 扩展恢复相关条目
- `../js-reverse/` `../malware-analysis/`

## 只读分析原则

- 全程用一次性浏览器 profile 加载与调试，别用日常 profile；分析结束即删除该 profile。
- 分析副本：把扩展目录复制出来再看，保留原始 CRX/XPI 作为证据。
- 不向被分析站点或扩展后端发主动请求，除非在授权范围内；理解阶段以静态阅读 + 被动 DevTools 观测为主。

## 获取与解包扩展

扩展来源与落点：

- Chrome/Edge 已安装：`%LOCALAPPDATA%\Google\Chrome\User Data\Default\Extensions\<id>\<version>\`（Edge 为 `Microsoft\Edge`）。
- Firefox 已安装：profile 目录下 `extensions\<id>.xpi`。
- 独立分发包：`.crx`（Chrome）/ `.xpi`（Firefox）。

```bash
# XPI 就是标准 zip
unzip -o ext.xpi -d ext_src
# CRX3 是 "Cr24" 头 + protobuf 头 + zip；unzip 通常能定位 zip 中央目录直接解出
unzip -o ext.crx -d ext_src 2>/dev/null || echo "如报错：先把 CRX 头剥离到第一个 PK 签名再解"
# 已安装扩展直接复制目录副本
cp -r "$LOCALAPPDATA/Google/Chrome/User Data/Default/Extensions/<id>/<ver>" ext_src
```

若 `unzip` 因 CRX 头报错，用小脚本搜文件里第一个 PK 签名偏移、从该偏移截断为纯 zip 再解。

## manifest 权限梳理

`manifest.json` 是权限与入口的总纲，先把它拆清楚：

```bash
jq "{mv: .manifest_version, name, version}" ext_src/manifest.json
jq ".permissions, .optional_permissions, .host_permissions" ext_src/manifest.json
jq ".background" ext_src/manifest.json          # MV3: service_worker；MV2: scripts/page
jq ".content_scripts" ext_src/manifest.json     # matches / js / run_at / world
jq ".web_accessible_resources, .externally_connectable, .content_security_policy" ext_src/manifest.json
```

高风险信号（对照 `references/extension-analysis.md`）：`<all_urls>` 或过宽 `host_permissions`、`webRequest`+`webRequestBlocking`（MV2 可改写响应）、`declarativeNetRequest`（MV3 改写）、`nativeMessaging`（出浏览器到本机程序）、`debugger`、`cookies`、`scripting`、`externally_connectable`（网页可驱动扩展）。

## 静态阅读 background 与 content script

入口顺序：manifest 指定的 background（service_worker / background page）→ content_scripts → 弹窗与选项页（`action.default_popup` / `options_page`）。

```bash
# 先美化打包脚本再读
npx js-beautify -r "ext_src/**/*.js"
# 盘点 chrome.* API 使用面
grep -rnoE "chrome\.[a-zA-Z]+\.[a-zA-Z]+" ext_src | sort | uniq -c | sort -rn
# 定位端点、存储、动态执行
grep -rniE "https?://|fetch\(|XMLHttpRequest|chrome\.storage|indexedDB|eval\(" ext_src
```

关注：远端拉取的代码/配置 URL、`chrome.storage`/`IndexedDB` 里的密钥或 token、注入页面的脚本、对第三方站点的 `fetch`。

## 打包 JS 反混淆与 source map 还原

现代扩展多为 webpack/rollup 打包，需先还原可读结构：

```bash
# 把 webpack 产物拆回模块（webcrack，开源）
npx webcrack ext_src/background.js -o unpacked/
# 无 source map 时通用美化
npx prettier --write "unpacked/**/*.js"
```

若产物旁带 `//# sourceMappingURL=...` 或 `*.js.map`，用 source map 直接还原到原始文件名与目录（`source-map` npm 库或等价 CLI）；还原后重复上一节的 grep 定位。AST 层深挖（常量折叠、字符串数组解密）用 Babel，或转 `js-reverse` 方法学。

## 消息通道与数据流梳理

扩展的信任边界在"页面 ↔ content script ↔ background ↔ 远端"之间，逐跳画清：

- 页面 ↔ content script：`window.postMessage` +（隔离世界）事件监听；注意 `world: "MAIN"` 会打破隔离。
- content script ↔ background：`chrome.runtime.sendMessage` / `onMessage`，长连接 `chrome.runtime.connect` + `port`。
- 外部页面 → 扩展：`externally_connectable` + `chrome.runtime.onMessageExternal`。
- background ↔ 远端：`fetch` / WebSocket。

```bash
grep -rnE "postMessage|onMessage(External)?|runtime\.(sendMessage|connect)|tabs\.sendMessage|onConnect" ext_src
```

产出一张消息表：发起方 / 通道 / 消息类型（action 字段）/ 处理函数 / 是否校验来源。

## 动态观测（可选）

```text
□ 一次性 profile 开发者模式加载解压目录
□ chrome://extensions 看错误、Service Worker "检查视图"
□ DevTools 附加 service worker / content script，观察 storage 与网络
□ 必要时用 CDP（Chrome DevTools Protocol）脚本化观测；遵守授权范围
```

## 证据与回滚

- 证据：manifest 权限摘录、消息通道表、远端端点清单、还原后的关键源码片段、（做恶意扩展判定时）YARA 命中。
- 回滚：删除一次性 profile 与解压副本；不改动原始 CRX/XPI。
- 脱敏：抓到的真实 token/密钥/私有后端域名占位符；权限字段、API 名、消息结构、公开 CDN/文档 URL 保留原文。

## 路由上下文

**上游**: MASTER R30  
**下游**: 复杂混淆 JS → `js-reverse`；投毒调查 → supply-chain / malware

## 任务完成自检

- [ ] 是否列出权限面与入口脚本？
- [ ] 是否还原关键数据流？
- [ ] Checklist？