# API 协议检测信号速查（web-api-reverse）

> 本表用于「抓到请求后快速判定协议与认证形态，再选生成模板」。

## 1. 协议检测表

| 信号 | 协议 | 生成模板要点 |
|------|------|-------------|
| body 含 `f.req=`，URL 含 `batchexecute` | Google batchexecute | 构造 `f.req`（`[[[rpc_id, params_json, null, "generic"]]]`），`at=` CSRF；响应剥 `)]}'\n` 前缀 |
| URL 含 `/graphql`，或 body 有 `query` + `variables` | GraphQL | `{"query": ..., "variables": ...}` 封装；`errors` 字段处理 |
| 资源路径上 REST 动词（`GET /api/v1/users/123`） | REST | 标准 get/post/put/delete；ID 换 `{id}` 占位 |
| `content-type: application/grpc-web+proto` | gRPC-web | protobuf 编码；需要 proto 定义或抓字节流分析 |
| `application/x-www-form-urlencoded` 且结构自定义 | Form-encoded RPC | 保持原始字段顺序与编码方式 |
| headers 出现 WebSocket upgrade | WebSocket | 连接建立 + 帧协议分析 |

## 2. 认证检测表

| 信号 | 认证类型 | 客户端处理 |
|------|---------|-----------|
| `Cookie:` 头带会话 token | Cookie 会话 | cookie jar；注意响应 Set-Cookie 旋转 |
| `Authorization: Bearer <token>` | Bearer token | 存 token，过期刷新 |
| `X-CSRF-Token` / `X-CSRFToken` 头 | CSRF（通常配 cookie） | 每次请求带，失效刷新 |
| body 里 `at=` 参数 | Google 风格 CSRF | 从页面/接口获取 |
| `X-API-Key` / `api_key` 参数 | API Key | 常量配置 |
| 无认证头 | 公开端点 | 无 |

## 3. 响应格式检测表

| 信号 | 格式 | 解析方式 |
|------|------|---------|
| 以 `)]}'\n` 开头 | XSSI 前缀 JSON（Google 系） | 剥离前缀再 json.loads |
| 直接是合法 JSON | 标准 JSON | `response.json()` |
| JSON 数组之间带字节数分块 | Google batchexecute 响应 | 按块长切分，取第二行 JSON |
| `data:` 前缀行 | Server-Sent Events (SSE) | 按 `data:` 行解析事件流 |
| 二进制内容 | Protobuf / gRPC | 需要 proto 或字节级分析 |

## 4. 每个端点要提取的字段

1. Endpoint —— URL 模板（ID 换 `{id}` 占位）
2. Method —— HTTP 方法
3. Auth —— 认证机制（见第 2 表）
4. Request params —— body 结构、字段名与类型
5. Response structure —— 字段名、类型、嵌套
6. Pagination —— cursor / offset / page 方式
7. Rate limiting —— 限流响应头（如 `X-RateLimit-*`、`Retry-After`）

## 5. 协议特化代码模板

### Google batchexecute

```python
def _call_rpc(self, rpc_id: str, params) -> dict:
    params_json = json.dumps(params, separators=(',', ':'))
    f_req = [[[rpc_id, params_json, None, "generic"]]]
    body = f"f.req={urllib.parse.quote(json.dumps(f_req))}"
    if self._auth.get("csrf_token"):
        body += f"&at={urllib.parse.quote(self._auth['csrf_token'])}"
    response = self._get_client().post(self.BATCHEXECUTE_URL, content=body)
    text = response.text
    if text.startswith(")]}'"):
        text = text[4:]
    return json.loads(text.strip().split('\n')[1])
```

### GraphQL

```python
def _query(self, query: str, variables: dict | None = None):
    payload = {"query": query}
    if variables:
        payload["variables"] = variables
    response = self._get_client().post(f"{self.BASE_URL}/graphql", json=payload)
    response.raise_for_status()
    data = response.json()
    if "errors" in data:
        raise APIError(data["errors"])
    return data["data"]
```

### BaseClient 基础设施（httpx）

```python
class BaseClient:
    BASE_URL = "<target_url>"

    def __init__(self, cookies: dict[str, str], **auth_kwargs):
        self.cookies = cookies
        self._client = None
        self._auth = auth_kwargs  # csrf_token, api_key 等

    def _get_client(self) -> httpx.Client:
        if self._client is None:
            self._client = httpx.Client(
                cookies=self.cookies,
                headers={
                    "User-Agent": "Mozilla/5.0 (compatible; reverse-api)",
                    "Origin": self.BASE_URL,
                    "Referer": f"{self.BASE_URL}/",
                },
                timeout=30.0,
            )
        return self._client

    def close(self):
        if self._client:
            self._client.close()
            self._client = None
```

### 每个端点方法模板

```python
def list_applications(self, page: int = 1, per_page: int = 50) -> list[Application]:
    """List all applications. Discovered: <date>. Endpoint: GET /api/v1/applications"""
    response = self._get_client().get(
        f"{self.BASE_URL}/api/v1/applications",
        params={"page": page, "per_page": per_page},
    )
    response.raise_for_status()
    return [Application(**item) for item in response.json()["results"]]
```

## 6. 捕获卫生红线

- 敏感字段（token、cookie、密钥）只留本地工作区，不进 Git/文档/对话。
- 记录捕获来源、时间、对应 UI 操作。
- 保存 sanitized 原始交换，供变异/验证复用。
