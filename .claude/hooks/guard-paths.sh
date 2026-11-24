#!/bin/bash
# PreToolUse hook: only allow file writes to the paths given as arguments,
# relative to the project root.
#   "flags/open/*.md"  -> a .md file directly in flags/open/ (no subfolders)
#   "learner/**"       -> anything under learner/
# TEMPLATE.md is never writable. Exit 2 blocks the tool call.
input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
allowed="$*"

block() { echo "Blocked: this agent may only write in: $allowed (tried: ${path:-<no path>}). $1" >&2; exit 2; }

[ -z "$path" ] && block "No file path in tool call."
case "$path" in
  /*) abs="$path" ;;
  *)  abs="$root/$path" ;;
esac
case "$abs" in *..*) block "'..' is not allowed in paths." ;; esac
case "$abs" in "$root"/*) ;; *) block "Path is outside the project." ;; esac
rel="${abs#"$root"/}"
[ "$(basename "$rel")" = "TEMPLATE.md" ] && block "TEMPLATE.md is read-only."

for pat in "$@"; do
  case "$pat" in
    */\*\*)
      prefix="${pat%\*\*}"
      case "$rel" in "$prefix"?*) exit 0 ;; esac ;;
    *)
      [ "$(dirname "$rel")" = "$(dirname "$pat")" ] || continue
      # shellcheck disable=SC2254
      case "$(basename "$rel")" in $(basename "$pat")) exit 0 ;; esac ;;
  esac
done
block "Raise a flag instead of editing."
