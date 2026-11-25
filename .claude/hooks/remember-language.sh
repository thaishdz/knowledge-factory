#!/bin/bash
# PostToolUse hook (AskUserQuestion): remember the conversation language in .claude/user-prefs.json.
# Looks for the answer to the 'Idioma / Language?' question anywhere in the hook input.
# Defensive: if not found, does nothing. Never blocks: always exit 0.
input=$(cat 2>/dev/null)
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" 2>/dev/null || exit 0
ans=$(printf '%s' "$input" | jq -r '
  def strs: if type=="string" then . elif type=="array" then (.[]|strs) elif type=="object" then (.[]|strs) else empty end;
  [ (.tool_response, .tool_input) | select(. != null) | .. | objects
    | to_entries[] | select(.key | type=="string" and test("Idioma / Language\\?"))
    | .value | strs ] | first // empty' 2>/dev/null)
if [ -z "$ans" ]; then
  # fallback: the answers may come as text, e.g. "Idioma / Language?"="Español"
  ans=$(printf '%s' "$input" | jq -r '[.tool_response | strings] | first // empty' 2>/dev/null | sed -n 's/.*Idioma \/ Language?"[^"]*"\([^"]*\)".*/\1/p' | head -1)
fi
case "$ans" in
  Espa*) l=es ;;
  English*) l=en ;;
  *) exit 0 ;;
esac
. "$(dirname "$0")/prefs.sh"
prefs_migrate
prefs_set language "\"$l\""
exit 0
