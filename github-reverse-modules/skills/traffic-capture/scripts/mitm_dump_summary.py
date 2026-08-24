"""
mitmproxy addon: dump a JSONL summary of every HTTP(S) flow.

Load with: mitmdump -s mitm_dump_summary.py
Output path is controlled by the MITM_SUMMARY_PATH environment variable
(defaults to mitm_summary.jsonl in the current directory).

Each line is one JSON object: time/method/url/host/status_code/headers and a
best-effort decoded, truncated (4000 char) text body for request and response
when the content looks like text (json/text/xml/form). Binary bodies are
recorded by length only, not dumped, to keep the JSONL readable.
"""

import json
import os

from mitmproxy import http

SUMMARY_PATH = os.environ.get("MITM_SUMMARY_PATH", "mitm_summary.jsonl")
MAX_BODY_CHARS = 4000
TEXT_CONTENT_HINTS = ("json", "text", "xml", "form-urlencoded", "javascript")


def _looks_like_text(headers) -> bool:
    content_type = headers.get("content-type", "").lower()
    return any(hint in content_type for hint in TEXT_CONTENT_HINTS)


def _body_summary(message) -> dict:
    if not message or not message.raw_content:
        return {"present": False}

    size = len(message.raw_content)
    if not _looks_like_text(message.headers):
        return {"present": True, "size": size, "text": None, "note": "binary or non-text content-type, not dumped"}

    try:
        text = message.get_text(strict=False) or ""
    except Exception as exc:  # noqa: BLE001 - best-effort decode, never crash the addon
        return {"present": True, "size": size, "text": None, "note": f"decode failed: {exc}"}

    truncated = text[:MAX_BODY_CHARS]
    return {
        "present": True,
        "size": size,
        "text": truncated,
        "truncated": len(text) > MAX_BODY_CHARS,
    }


def response(flow: http.HTTPFlow) -> None:
    try:
        req = flow.request
        resp = flow.response
        entry = {
            "time": req.timestamp_start,
            "method": req.method,
            "url": req.pretty_url,
            "host": req.host,
            "port": req.port,
            "status_code": resp.status_code if resp else None,
            "request_headers": dict(req.headers),
            "response_headers": dict(resp.headers) if resp else {},
            "request_body": _body_summary(req),
            "response_body": _body_summary(resp) if resp else {"present": False},
        }
        with open(SUMMARY_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception:  # noqa: BLE001 - never let a summary error break the proxy
        pass


def error(flow: http.HTTPFlow) -> None:
    try:
        entry = {
            "time": flow.request.timestamp_start if flow.request else None,
            "method": flow.request.method if flow.request else None,
            "url": flow.request.pretty_url if flow.request else None,
            "error": str(flow.error) if flow.error else "unknown error",
        }
        with open(SUMMARY_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception:  # noqa: BLE001
        pass
