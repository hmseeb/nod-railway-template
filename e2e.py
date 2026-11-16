#!/usr/bin/env python3
"""Drive a real Nod agent turn through the public API, as the web app does.

Proves the relay end to end: the task needs a workspace command (python3), a
workspace file write, and a browser visit. Prints the assistant's replies.

Usage: e2e.py <base-url> <auth-token-file> [--connect <anthropic-key-env-var>]
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

base, tokfile = sys.argv[1].rstrip("/"), sys.argv[2]
token = open(tokfile).read().strip()


def call(method, path, body=None):
    req = urllib.request.Request(base + path, method=method,
                                 data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Authorization": "Bearer " + token, "Content-Type": "application/json"})
    try:
        return json.loads(urllib.request.urlopen(req, timeout=60).read() or b"null")
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> {e.code} {e.read().decode()[:400]}")


if "--connect" in sys.argv:
    key = os.environ[sys.argv[sys.argv.index("--connect") + 1]]
    call("POST", "/api/models/keys", {"provider": "anthropic", "key": key})
view = call("GET", "/api/models")
conn = next(c for c in view["connections"] if c["provider"] == "anthropic")
call("PUT", "/api/models/selection", {"connectionId": conn["id"], "modelId": "claude-haiku-5-5", "effort": "low"})

task = ("Two quick checks, no need to ask me first. 1) In your Linux workspace run "
        "python3 -c 'import platform; print(6*7, platform.system())' and save its output to answer.txt, "
        "then show me the file contents. 2) Open https://example.com in your browser and tell me the page's main heading.")
sent = call("POST", "/api/messages", {"text": task})
print("sent", json.dumps(sent)[:200])
seen = set()
deadline = time.time() + 420
while time.time() < deadline:
    time.sleep(10)
    msgs = call("GET", "/api/messages")
    items = msgs.get("messages", msgs) if isinstance(msgs, dict) else msgs
    for m in items:
        if m.get("role") == "assistant" and m["id"] not in seen and (m.get("text") or m.get("content")):
            seen.add(m["id"])
            print("\nASSISTANT:", (m.get("text") or json.dumps(m.get("content")))[:1500])
    text = json.dumps(items)
    if "42 Linux" in text and ("Example Domain" in text or "documentation examples" in text):
        print("\nE2E PASS: workspace (42 Linux) and browser (Example Domain) both answered")
        sys.exit(0)
print("\nE2E INCOMPLETE")
sys.exit(1)
