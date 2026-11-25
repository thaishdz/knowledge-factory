#!/bin/bash
# SessionStart hook: report pending flags so the main session can offer to process them.
# It never runs an agent; its only write is folding the old marker files into .claude/user-prefs.json.
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$root" 2>/dev/null || exit 0
. "$(dirname "$0")/prefs.sh"
prefs_migrate
shopt -s nullglob
open=(); review=(); source=()
for f in flags/open/*.md; do
  name=$(basename "$f" .md)
  case "$(sed -n 's/^status:[[:space:]]*//p' "$f" | head -1 | tr -d '"[:space:]')" in
    needs-review) review+=("$name") ;;
    needs-source) source+=("$name") ;;
    *)            open+=("$name") ;;
  esac
done
total=$(( ${#open[@]} + ${#review[@]} + ${#source[@]} ))
saved=$(prefs_get language)
case "$saved" in es) savedname="Spanish" ;; en) savedname="English" ;; *) saved="" ;; esac
if [ -n "$saved" ]; then
  lang="The human already chose the conversation language: $savedname. Do not ask it again: talk in $savedname for the whole session (your replies and the agent reports you relay) and pass it to subagents in your request. If the human says they want to switch language, ask again with the language menu described below and use the new choice. Language menu: call the AskUserQuestion tool once with header 'Language', question 'Idioma / Language?', options 'Español' and 'English'."
else
  lang="FIRST, before anything else in your first reply, ask the conversation language by calling the AskUserQuestion tool once (a menu, not plain text): header 'Language', question 'Idioma / Language?', options 'Español' and 'English'. Then use the chosen language for the rest of the session (your replies and the agent reports you relay) and pass it to subagents in your request."
fi
langmenu="On this first run do NOT ask the language in plain text: it is asked in the onboarding menu (AskUserQuestion) that you show in your reply to the human's first message. Use the chosen language for the rest of the session and pass it to subagents."
# First-run welcome: only while sample content is on disk and onboarded isn't set.
# The assistant never speaks first, so the welcome goes in a visible systemMessage;
# the preference is set later by the UserPromptSubmit hook (onboarding.sh).
welcome=""
if [ "$(prefs_get onboarded)" != true ] && [ -f .claude/scripts/sample-content.txt ]; then
  while IFS= read -r p; do
    case "$p" in ''|'#'*) continue ;; esac
    if [ -e "$p" ]; then
      welcome="Welcome! This is a wiki that agents build from your sources; you only write in plain words. Write anything to start (e.g. hello): I'll show you the sample or help you start your own wiki."
      [ -z "$saved" ] && lang="$langmenu"
      break
    fi
  done < .claude/scripts/sample-content.txt
fi
if [ "$total" -eq 0 ]; then
  if [ -n "$welcome" ]; then
    jq -n --arg msg "$welcome" --arg ctx "$lang" '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
  else
    jq -n --arg ctx "$lang" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
  fi
  exit 0
fi

line() { [ "$2" -gt 0 ] && printf '%s %d (%s)' "$1" "$2" "$3"; }
parts=()
[ ${#open[@]} -gt 0 ]   && parts+=("$(line "open:" ${#open[@]} "I can fix them")")
[ ${#review[@]} -gt 0 ] && parts+=("$(line "needs-review:" ${#review[@]} "waiting for your approval")")
[ ${#source[@]} -gt 0 ] && parts+=("$(line "needs-source:" ${#source[@]} "need a source in raw/")")
joined=$(printf '%s; ' "${parts[@]}"); summary="Pending flags — ${joined%; }"
[ -n "$welcome" ] && summary="$welcome"$'\n'"$summary"
detail=$(printf 'Pending flags in flags/open/:\n'; for n in "${open[@]}"; do echo "- open: $n"; done; for n in "${review[@]}"; do echo "- needs-review: $n"; done; for n in "${source[@]}"; do echo "- needs-source: $n"; done; echo "$lang"; echo "Then tell the human about the flags, in plain words and without commands, and offer to process them. Do not run the curator until they agree.")
jq -n --arg msg "$summary" --arg ctx "$detail" \
  '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
