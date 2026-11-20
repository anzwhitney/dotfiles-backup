#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DST="$HOME/.claude"

mkdir -p "$DST/hooks"
for f in CLAUDE.md RTK.md statusline-command.sh hooks/block-rm-rf.py; do
  ln -sfn "$ROOT/claude/$f" "$DST/$f"
  echo "Linked: $DST/$f -> $ROOT/claude/$f"
done
