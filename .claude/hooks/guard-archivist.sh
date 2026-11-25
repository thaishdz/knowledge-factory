#!/bin/bash
# PreToolUse hook for the archivist: it brings sources into raw/ and files
# them, but never changes their content.
#   Write/Edit: only raw/SOURCES.md and .git/info/exclude.
#   Bash: no deleting, no in-place edits, no redirections, no overwriting
#   copies or moves (cp/mv need -n), no history rewrites or pushes.
# Exit 2 blocks the tool call. The Bash check is pattern-based, so for Bash
# the limit is partly an instruction.
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

if [ "$tool" = "Bash" ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
  block() { echo "Blocked: the archivist never deletes, edits or overwrites sources ($1). Command: $cmd" >&2; exit 2; }
  printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_-])(rm|rmdir|unlink|truncate|shred|tee|dd)([[:space:]]|$)' && block "destructive command"
  printf '%s' "$cmd" | grep -Eq '(sed|perl|ruby)[[:space:]]+(-[[:alnum:]]*[[:space:]]+)*-[[:alnum:]]*i' && block "in-place edit"
  printf '%s' "$cmd" | sed 's#[0-9]*>[[:space:]]*/dev/null##g; s#2>&1##g' | grep -q '>' && block "redirection"
  printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(rm|reset|restore|checkout|clean|push|rebase|commit[^|;&]*--amend|mv[^|;&]*[[:space:]]-f)' && block "git history or deletion"
  # cp and mv (not git mv) must use -n so nothing is overwritten.
  for w in cp mv; do
    printf '%s' "$cmd" | grep -Eo "(^|[;&|][[:space:]]*|^[[:space:]]*)$w([[:space:]]+-[[:alnum:]]+)*" | while read -r m; do
      printf '%s' "$m" | grep -Eq -- '-[[:alnum:]]*n' || exit 1
    done || block "$w without -n"
  done
  exit 0
fi

path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -z "$path" ] && { echo "Blocked: no file path in tool call." >&2; exit 2; }
case "$path" in
  /*) abs="$path" ;;
  *)  abs="$root/$path" ;;
esac
case "$abs" in *..*) echo "Blocked: '..' is not allowed in paths." >&2; exit 2 ;; esac
case "${abs#"$root"/}" in
  raw/SOURCES.md|.git/info/exclude) exit 0 ;;
esac
echo "Blocked: the archivist may only edit raw/SOURCES.md and .git/info/exclude (tried: $path). Sources are copied or moved with cp -n / mv -n / git mv, never edited." >&2
exit 2
