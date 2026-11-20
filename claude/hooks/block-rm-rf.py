#!/usr/bin/env python3
"""PreToolUse hook: deny `rm` with both recursive and force flags; tell the model to use `rm -r`."""
import json, re, sys

command = json.load(sys.stdin).get("tool_input", {}).get("command", "")

def has_rf(args):
    short = ""
    long_ = set()
    for t in args.split():
        if t == "--":
            break
        if t.startswith("--"):
            long_.add(t)
        elif t.startswith("-"):
            short += t[1:]
    recursive = "--recursive" in long_ or bool(set(short) & set("rR"))
    force = "--force" in long_ or "f" in short
    return recursive and force

for segment in re.split(r"[;&|\n]+", command):
    m = re.search(r"(?:^|\s)rm\s+(.*)", segment)
    if m and has_rf(m.group(1)):
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "Use `rm -r` (no -f): an org rule prompts the user on every rm -rf, and your own files don't need -f. Re-run the same command with `rm -r`.",
        }}))
        break
