#!/bin/bash
# PreToolUse hook for the curator: raw/ is the source of truth and is
# read-only. Blocks Write/Edit on raw/ and Bash commands that obviously
# modify it. Exit 2 blocks the tool call.
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

if [ "$tool" = "Bash" ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
  if printf '%s' "$cmd" | grep -Eq '(rm|mv|cp|touch|tee|sed -i|git mv|git rm|>{1,2})[^|;&]*raw/'; then
    echo "Blocked: the curator never modifies raw/ (command: $cmd)." >&2
    exit 2
  fi
  exit 0
fi

path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -z "$path" ] && exit 0
case "$path" in
  /*) abs="$path" ;;
  *)  abs="$root/$path" ;;
esac
rel="${abs#"$root"/}"
case "$rel" in
  raw/*|*/../raw/*|*..*raw/*)
    echo "Blocked: the curator never writes in raw/ (tried: $path). If raw/ lacks a source, mark the flag needs-source." >&2
    exit 2 ;;
esac
exit 0
