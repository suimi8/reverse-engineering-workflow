---
name: web-api-reverse
description: 从网络请求/HAR/cURL 逆向 Web 应用内部 API 协议，生成 Python httpx / TypeScript 客户端 + API 文档。支持 REST、GraphQL、Google batchexecute、gRPC-web、form-RPC 多协议检测，认证检测（Cookie/Bearer/CSRF/API key），多智能体流水线（Classify-PayloadDiff/Trace/Model-Workflow-Verify-CodeGen），回放验证。当用户需要把 Web 后端 API 逆向为可编程客户端、构建非官方 SDK、从 HAR 或 cURL 恢复接口协议、或把抓到的请求还原成代码时使用。
---


中文名：suimi Web 后端 API 逆向

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# suimi Web 后端 API 逆向

> 面向「Web 后端内部 API」的逆向产出型技能：捕获真实请求 → 理解协议 → 生成能模拟浏览器的客户端代码。与 `traffic-capture`（只取证不产出）和 `api-sec` 等安全模块（只测漏洞不产出）互补。

## 与相邻模块的边界（先对号入座）

| 场景 | 用哪个模块 |
|------|-----------|
| 只是抓包取证、看目标发了什么请求 | `traffic-capture` |
| 抓包后要把接口逆向成可编程客户端/SDK | **本模块（web-api-reverse）** |
| 目标有 JS 混淆/JSVMP/反爬保护，需要还原前端签名算法 | `web-js-reverse` |
| 目标是找接口的安全漏洞（鉴权/BOLA/注入） | `security-research-modules/skills/api-sec` |
| 目标是识别请求加密算法并 Python 重构签名 | `web-crypto-reverse` |

## 触发场景

- 逆向 Web 应用**内部 API**（无官方 API 或官方 API 不够用），构建非官方客户端
- 从浏览器网络流量 / HAR 文件 / cURL 命令恢复接口协议，生成可复现的请求代码
- 把一个接口的请求链（登录 → 取数 → 分页）还原成最小可运行脚本
- 分析已捕获的 HTTP 请求，理解协议形态（REST / GraphQL / batchexecute / gRPC-web / form-RPC / WebSocket）

**核心原则**：捕获真实请求，理解协议，生成与浏览器完全一致的代码。只保留必要的 Header（User-Agent、Origin、Referer、认证字段），不整包复制。

## 三条捕获路径（先选源，再动手）

| 路径 | 输入 | 适用 |
|------|------|------|
| 实时捕获（Chrome DevTools MCP） | 会话里有 `navigate_page` / `get_network_request` / `list_network_requests` 工具 | 目标可交互，需要现场操作触发请求 |
| HAR 导入 | `.har` 文件（DevTools / Burp / mitmproxy 导出） | 已有现成抓包文件，或离线分析 |
| cURL 粘贴 | 用户从 DevTools Network 右键 Copy as cURL | 用户只给单个请求 |

### 实时捕获步骤

1. `navigate_page(url=目标URL)` 打开目标。
2. 让用户执行要捕获的操作（如"点击查看列表"），等待确认。
3. `list_network_requests` 列出请求，逐个 `get_network_request` 取详情。
4. 过滤静态资源（.js、.css、图片、字体），只留 XHR/fetch。
5. 提取：URL、方法、headers（重点 Cookie / Content-Type / Authorization / X-CSRF-Token）、body、response。

### cURL 解析要点

从 cURL 提取：`-X`/method、URL、`-H` 头、`--data`/`--data-raw` body、`-b` cookie、`-u` 认证。多给几条不同请求的 cURL 便于做变异分析。

### 捕获卫生

- 敏感字段（token、cookie、密钥）只保留在本地工作区，不写入 Git、文档或对话。
- 记录捕获来源、时间、对应 UI 操作，保证可回溯。
- 保存 sanitized 原始交换（如 `captures/<run-id>/raw.har`），后续变异/验证复用。

## 协议检测（先定协议，再定生成模板）

| 信号 | 协议 |
|------|------|
| body 含 `f.req=`，URL 含 `batchexecute` | Google batchexecute |
| URL 含 `/graphql`，或 body 有 `query` + `variables` | GraphQL |
| 资源路径上 REST 动词（`GET /api/v1/users/123`） | REST |
| `content-type: application/grpc-web+proto` | gRPC-web |
| `application/x-www-form-urlencoded` 且结构自定义 | Form-encoded RPC |
| headers 出现 WebSocket upgrade | WebSocket |

完整检测信号速查表见 `references/api-protocol-signatures.md`。

## 认证检测

| 信号 | 认证类型 | 客户端处理 |
|------|---------|-----------|
| `Cookie:` 头带会话 token | Cookie 会话 | cookie jar，注意响应里旋转 cookie |
| `Authorization: Bearer <token>` | Bearer | 存 token，过期需刷新 |
| `X-CSRF-Token` / `X-CSRFToken` | CSRF（通常配 cookie） | 每次请求带，注意刷新 |
| body 里 `at=` 参数 | Google 风格 CSRF | 从页面/接口取 |
| `X-API-Key` / `api_key` 参数 | API Key | 常量配置 |
| 无认证头 | 公开端点 | 无 |

## 分析→产出的两条路线

### 路线 A：轻量（提示词驱动，Python httpx 客户端）

抓一个请求 → 分析协议 → 直接生成代码：

- `client.py`：`BaseClient`（httpx，带 cookie/headers 基础设施、`_get_client()` 懒加载、`close()`/上下文管理器）
- `types.py`：响应 dataclass（按 response 字段生成）
- `constants.py`：端点路径常量、状态码映射
- `docs/api_reference.md`：每个端点记录 URL 模板（ID 换 `{id}` 占位）、方法、认证、参数表、响应示例、发现日期、分页方式

**每个端点生成一个方法**：签名用参数而非硬编码 ID；`response.raise_for_status()`；返回 dataclass 列表。协议特化模板（batchexecute 的 `f.req` 构造 + XSSI 前缀剥离、GraphQL 的 query/variables 封装）见 `references/api-protocol-signatures.md`。

### 路线 B：工程化（多智能体流水线，TypeScript 客户端）

适合接口多、需要稳定产出和回归验证的场景，七阶段：

```
Scope → Capture → Classify → 并行分析(PayloadDiff/Trace/Model) → Workflow 编排 → Replay 验证 → CodeGen
```

1. **Scope**：确定一个 UI 动作建模（如"创建候选人并关联职位"）、目标 Base URL、捕获来源；写 `scope/<run-id>.md`。
2. **Capture**：按上文三路径捕获；同一动作采集多次以获得变异样本。
3. **Classify**：识别每个 exchange 的协议/端点/是否含动态值；未知的交 classifier 子代理。
4. **并行分析**：对每个 mutation 并行做——payload-differ（同一动作两次请求的字段差异）、value-tracer（动态值来源：时间戳/随机数/签名）、response-modeler（响应结构建模）。
5. **Workflow**：把多个 mutation 串成请求链（登录 → 携带 token → 后续请求），输出 `WORKFLOW.md`。
6. **Replay 验证**：用 Playwright storage-state 回放每个 mutation，比对 `matchesOriginal`；drift 时如实报告并迭代。
7. **CodeGen**：生成 `client.ts` + `types.ts` + `errors.ts` + `api-map.md` + `tests/client.spec.ts`，最后 codegen 子代理做 review pass。

子代理提示词要点（classifier / payload-differ / value-tracer / response-modeler / workflow / codegen 六个角色）见 `references/multi-agent-pipeline.md`。

## 常见错误与修法

| 错误 | 修法 |
|------|------|
| 硬编码会话 ID | 从 URL 提取 ID 为方法参数 |
| 忽略响应 cookie 更新 | 部分站点每次请求旋转 cookie，更新 cookie jar |
| CSRF token 过期 | 加刷新逻辑 |
| body 参数不 URL 编码 | `urllib.parse.quote()` |
| 假设全是 JSON | 检查 Content-Type 与响应前缀（XSSI/SSE/protobuf） |
| 整包复制所有 Header | 只保留 UA/Origin/Referer/认证必需头 |
| 不处理分页 | 检查响应是否指示更多页（cursor/offset/page） |

## 工作流

1. 建立基线：目标 URL、登录态、可复现的 UI 操作路径。
2. 分类目标协议：REST/GraphQL/batchexecute/gRPC-web/form-RPC/WebSocket。
3. 窄范围捕获：一次只逆向一个端点/一条链路，先跑通再扩展。
4. 先出最小可运行代码验证假设，再补全类型/文档/测试。
5. 端到端复验：新会话、全新环境跑客户端，确认请求形态与浏览器一致。
6. 记录：捕获来源、请求形态、认证方式、输出产物、验证结果。

## 证据与回滚

- 记录命令、请求 URL/方法/头/body、响应形态、生成代码版本、验证结果。
- 保留原始捕获（HAR/cURL）、sanitized 交换、生成代码、测试输出。
- 绝不绕过 Auth/Captcha/Rate-Limit；权限责任在用户侧。

## 参考

- `references/api-protocol-signatures.md`：协议/认证/响应格式检测信号速查 + 协议特化代码模板。
- `references/multi-agent-pipeline.md`：七阶段多智能体流水线详情与子代理提示词要点。
- 抓包上游证据：`github-reverse-modules/skills/traffic-capture/MODULE.md`。
- 统一技能目录与中文名映射见 `references/unified-skills-entry.md`。
- 通用可复用方法清单见 `references/reverse-engineering-methods.md`。
