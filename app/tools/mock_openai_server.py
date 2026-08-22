#!/usr/bin/env python3
"""极简 OpenAI 兼容 mock 服务器，用于云端链路集成测试。

用法：python3 tools/mock_openai_server.py [port]
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length) or b"{}")
        print(f"[mock] POST {self.path} model={body.get('model')} auth={self.headers.get('Authorization')}")
        if not self.path.endswith("/chat/completions"):
            self.send_response(404)
            self.end_headers()
            return
        resp = {
            "id": "mock-1",
            "object": "chat.completion",
            "choices": [
                {
                    "index": 0,
                    "message": {"role": "assistant", "content": "云端回复：测试通过"},
                    "finish_reason": "stop",
                }
            ],
        }
        data = json.dumps(resp).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    print(f"[mock] listening on :{port}")
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()
