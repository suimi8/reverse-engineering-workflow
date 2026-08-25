# 七阶段多智能体流水线（web-api-reverse）

> 适用于接口多、需要稳定产出与回归验证的 Web 后端 API 逆向任务。路线 A（轻量）见主 MODULE.md。

## 流水线总览

```
Scope → Capture → Classify → 并行分析(PayloadDiff || Trace || Model) → Workflow 编排 → Replay 验证 → CodeGen
```

## Phase 1 — Scope（定范围）

向用户确认三件事，写入 `scope/<run-id>.md`：

1. **一个** UI 动作建模（例如"创建候选人并关联职位"）——一次只做一个动作，别贪多。
2. **Target Base URL**。
3. **Capture 来源**：Live（Chrome MCP）/ HAR 文件路径 / cURL 粘贴。

`runId = <timestamp>-<slug>`，后续所有产物按 runId 归档。

## Phase 2 — Capture（捕获）

| 来源 | 步骤 |
|------|------|
| Live（Chrome MCP） | `new_page` 打开目标 → 用户执行动作 → `list_network_requests` + 逐个 `get_network_request`；同一动作多次运行取变异样本 |
| HAR | 读文件 → 解析 entries（request/response） |
| cURL | 用户粘贴多条 cURL（不同请求） |

**保存前卫生**：所有 exchange 过 sanitizer（剥离 token/cookie/敏感头），存 `captures/<run-id>/raw.har`。

## Phase 3 — Classify（分类）

对每个 exchange 判定：协议类型、端点、认证、是否含动态值。判定为 unknown 的，spawn `classifier-agent` 子代理分析并合并回。

## Phase 4 — 并行分析（并行子代理）

发现 mutation（同一动作多次请求的字段差异）后，一条消息内并行 spawn 三个子代理：

| 子代理 | 输入 | 输出 |
|--------|------|------|
| payload-differ | 每个 mutation 的 payload | 字段差异：哪些字段是常量、哪些随请求变化 |
| value-tracer | 动态值（origin.kind == unknown） | 动态值来源：时间戳/随机数/签名/服务端下发 |
| response-modeler | mutation 的 responseType + 样本响应 | 响应结构模型（字段/类型/嵌套） |

## Phase 5 — Workflow 编排（请求链）

把多个 mutation 串成请求链：登录 → 取 token → 携带 token 后续请求 → 分页。输出 `WORKFLOW.md`。

## Phase 6 — Replay 验证（回放比对）

对每个 mutation 用 Playwright storage-state 回放，比对 `matchesOriginal`：

- `true` → 通过，进入生成。
- `false` → 展示 `driftReasons`（header 缺失/cookie 旋转/动态值没对上），问用户是否重复 Phase 4。

**红线**：每次 drift 必须如实报告，不能掩盖。storage-state 只存 `captures/<run-id>/auth.private.json`（gitignored）。

## Phase 7 — CodeGen（生成 + review）

生成产物：

- `out/<run-id>/client.ts` —— 客户端类（方法 = 端点）
- `out/<run-id>/types.ts` —— 类型定义
- `out/<run-id>/errors.ts` —— 错误类型
- `out/<run-id>/api-map.md` —— 端点映射文档
- `out/<run-id>/tests/client.spec.ts` —— 回归测试

最后 spawn `codegen-agent` 做 review pass，输出 `out/<run-id>/REVIEW.md`。

## 子代理提示词要点

| 角色 | 职责 | 关键提示 |
|------|------|---------|
| classifier | 判定 unknown exchange 的协议/端点 | 依据协议检测表，给证据 |
| payload-differ | 比对同一动作多次请求的 payload 差异 | 区分常量字段与动态字段，标注候选参数化点 |
| value-tracer | 追踪动态值来源 | 时间戳/随机数/签名/服务端下发四类；unknown 继续标记 |
| response-modeler | 从样本响应建结构模型 | 字段名/类型/嵌套/可选性，用 TypeScript 或 dataclass 表达 |
| workflow | 串请求链 | 依赖顺序：先 auth 再业务，token 传递明确 |
| codegen | 生成与 review | 一致性：命名/错误处理/返回类型风格统一，不重构既有方法 |

## 规则

- 绝不绕过 Auth/Captcha/Rate-Limit；权限责任在用户侧。
- 绝不写未 sanitize 的捕获。
- 私有数据只放 `captures/`、`out/`、`scope/` 目录。
- 用户要 Python 时：v1 只出 TypeScript（或按路线 A 出 Python httpx，二选一，不混用）。
