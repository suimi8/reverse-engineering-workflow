---
name: protocol-reverse
description: Use for authorized reverse engineering of custom binary protocols, Protobuf/gRPC, WebSocket frames, and PCAP-driven protocol recovery.
---


中文名：suimi 协议逆向

本 skill 由 suimi 逆向总入口支持。即使用户直接触发本子技能，任务结束也必须回到 `reverse-engineering-workflow/scripts/finish_skill_run.ps1` 生成 `新技能/方法反馈`，明确输出是否发现新技能/方法、建议加入数量、是否建议加入 skills，以及如何用 `record_skill_lesson.ps1`、`review_skill_lessons.ps1`、`promote_skill_lesson.ps1` 加入本 skills。

# Protocol Reverse Engineering

## 适用场景

- 自定义 TCP/UDP 二进制协议
- Protobuf / gRPC / FlatBuffers / MessagePack
- WebSocket / MQTT / 私有 RPC
- PCAP / PCAPNG 还原字段与状态机
- 客户端-服务端校验、序列号、加密帧头

## 不走本 skill

| 情况 | 去哪 |
|------|------|
| 仅 HTTP 参数签名 / JS 加密 | `js-reverse/` |
| 仅 TLS 证书问题 | `pentest-tools/` 或浏览器代理 |
| 固件内协议栈深挖 + 仿真 | `firmware-pentest/` 后再回本 skill |

## 工作流

### Phase 1 — 采集与分诊

```text
□ 拿到样本：PCAP / 代理导出 / 客户端日志 / 二进制
□ 标记方向：C→S / S→C；是否有握手、心跳、重连
□ 固定头？魔数？长度字段？TLV？定长？
□ 是否压缩（zlib/gzip/lz4）或加密（AES/ChaCha 帧内）
□ tshark -r cap.pcap -T fields -e frame.number -e ip.src -e tcp.payload
```

### Phase 2 — 帧布局还原

```text
□ 对齐多个同类消息，找不变字节 / 自增序列号
□ 长度字段：大端/小端、含头/不含头
□ 校验：CRC16/32、checksum、HMAC 位置
□ 画出状态机：Connect → Auth → Ready → Request/Response → Close
□ 工具：Wireshark 自定义 dissector 草稿 / ImHex / 010 Editor 模板 / Kaitai Struct
```

### Phase 3 — 序列化与加密

```text
□ Protobuf：.proto 恢复（blackboxprotobuf / pbtk / protoc --decode_raw）
□ gRPC：HTTP/2 headers + protobuf body
□ 加密：找密钥派生（客户端 so/dll/JS）→ 联合 ida-reverse / js-reverse / apk-reverse
□ 重放：仅在授权 scope 内；先无害字段再敏感操作
```

### Phase 4 — 产物

```text
MUST 产出：
- 消息类型表（name / opcode / fields）
- 至少 1 条可复现的解码命令或脚本
- Evidence：原始 hex 摘录 + 解码结果（脱敏）
```

## 工具链

| 工具 | 必需 | 用途 | 自举 |
|------|------|------|------|
| tshark / Wireshark | 强烈建议 | PCAP 解析 | 手动 / winget |
| Python3 | 是 | 解码脚本 | 系统 |
| blackboxprotobuf | 可选 | 未知 protobuf | pip |
| ImHex / 010 | 可选 | 结构模板 | 手动 |
| IDA / r2 / Ghidra | 按需 | 客户端序列化函数 | 见对应 skill |

## 参考

- `references/protocol-workflow.md` — 帧布局与 Protobuf 速查
- 相关：`../ida-reverse/` `../js-reverse/` `../firmware-pentest/` `../pentest-tools/`

## 抓包与采集详解

按传输层与是否加密选采集手段：

```bash
# 明文 TCP/UDP：先落 PCAP
tcpdump -i any -w cap.pcap host 203.0.113.10 and port 4433
# 从 PCAP 提取某条流的 payload（十六进制）
tshark -r cap.pcap -Y "tcp.port==4433" -T fields -e tcp.stream -e tcp.payload | head
# 跟单条 TCP 流看原始字节
tshark -r cap.pcap -q -z follow,tcp,raw,0
```

- HTTP(S) / WebSocket：用 mitmproxy 被动观测，`mitmdump -w flows.mitm` 存流、`mitmweb` 看 WebSocket 帧。
- 明文私有 TCP 需中间人转发观测：`socat -v TCP-LISTEN:4433,fork TCP:realhost:4433` 打印双向字节（仅授权环境）。
- TLS 但客户端可控：设 `SSLKEYLOGFILE` 环境变量导出会话密钥，Wireshark 里载入 keylog 即可解密，无需私钥。

## 字段切分方法

拿到多条同类消息后做纵向对齐，逐列判定"不变 / 单调 / 随机"：

```bash
# 把若干消息各存一个 .bin，并排看十六进制
for f in msg_*.bin; do echo "== $f =="; xxd "$f" | head; done
# 两条消息按字节对比，定位差异列
cmp -l a.bin b.bin | head
# 或用 radiff2 做字节级差异
radiff2 a.bin b.bin
```

判定经验：全程不变的多为魔数/版本/opcode；每包 +1 的是序列号；单调增大的可能是时间戳；高熵且无明文的段疑似加密体或哈希。ImHex / 010 Editor 结构模板、Kaitai Struct 的 `.ksy` 适合把猜测固化成可复用解析。

## 长度、类型与校验位识别

- 长度字段：把候选字节按大端/小端解释，与"实际剩余字节数"做相关；分别验证"含头/不含头"；一次对齐十几条消息即可锁定位置与字节序。
- 类型/opcode：把疑似类型字节在所有消息里取值域，枚举值约等于消息字典（对应 TLV 的 type）。
- 校验位：常见 CRC16/CRC32（多种多项式）、单字节和、XOR、Adler-32；对"覆盖范围 + 算法"做小规模爆破：

```python
import binascii, zlib
frame = bytes.fromhex("....")            # 一条完整帧
body, trailer = frame[:-4], frame[-4:]   # 假设尾部 4 字节为校验
cands = {
    "crc32": binascii.crc32(body) & 0xffffffff,
    "adler32": zlib.adler32(body) & 0xffffffff,
}
print({k: hex(v) for k, v in cands.items()}, "trailer=", trailer.hex())
# 更多多项式用 crcmod：crcmod.mkCrcFun(poly, initCrc, rev, xorOut)
```

命中不了就换"覆盖范围"（是否含长度字段、是否含头）再试；仍不中考虑带密钥的 HMAC，转客户端算法定位。

## 状态机重建

把一整个会话按时间排出"方向 + 消息类型"序列，归纳状态与迁移：

```text
C->S HELLO(0x01)      -> 握手开始
S->C CHALLENGE(0x02)
C->S AUTH(0x03)
S->C AUTH_OK(0x04)    -> Ready
C->S PING(0x10) / S->C PONG(0x11)   (keepalive, 周期性)
C->S REQ(0x20)  -> S->C RESP(0x21)  (Ready 态可重复)
任一方 BYE(0x7f) -> Closed
```

用文字表或 Graphviz DOT 固化；标出哪些消息只在特定状态合法、哪些字段跨消息关联（如 challenge -> auth 的派生）。

## 编写解析器与重放脚本

解析器优先用声明式，减少手写偏移错误：

```python
# construct 库：声明式二进制解析（开源）
from construct import Struct, Int16ub, Int32ub, Bytes, this
Frame = Struct("magic" / Int16ub, "length" / Int32ub,
               "opcode" / Int16ub, "body" / Bytes(this.length))
obj = Frame.parse(open("msg_0.bin", "rb").read())
print(obj.opcode, obj.length, obj.body[:16].hex())
```

也可写 Kaitai `.ksy` 后用 `kaitai-struct-compiler -t python proto.ksy` 生成多语言解析器。重放遵守授权 scope、先无害后敏感：

```python
import socket
s = socket.create_connection(("203.0.113.10", 4433), timeout=5)
s.sendall(bytes.fromhex("....一条已解析确认无害的帧...."))
print(s.recv(4096).hex())
```

WebSocket 重放用 `websocket-client`，gRPC/HTTP2 用 `protoc --decode_raw` + `grpcurl`。所有重放必须可开关、可日志、可回滚。

## 证据与回滚

- 证据：消息类型表（name/opcode/字段）、字段布局图、状态机、至少 1 条可复现的解码命令或脚本、原始 hex 摘录 + 解码结果（脱敏）。
- 回滚：重放仅在隔离/授权环境；不对生产发敏感操作；`socat`/代理转发结束即拆除。
- 脱敏：真实 token/密钥/私有 IP 与域名占位符；opcode、字段名、长度/字节序、校验算法、公开协议文档 URL 保留原文。

## 路由上下文

**上游**: `MASTER-ROUTING` R21 · `routing.md`  
**下游**: 需客户端算法 → `ida-reverse`/`js-reverse`；需利用重放 → `pentest-tools`/`api-security`  
**同级**: `malware-analysis`（C2 协议）、`digital-forensics`（流量取证）

## 任务完成自检

- [ ] 是否还原了消息布局或状态机（而非只贴 hex）？
- [ ] 是否有可复现解码命令？
- [ ] 是否遵守 scope / 脱敏？
- [ ] 是否回写 field-journal / 报告 Checklist？