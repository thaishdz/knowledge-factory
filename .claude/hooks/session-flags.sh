#!/bin/bash
# SessionStart hook: report pending flags so the main session can offer to process them.
# Read-only: it never runs an agent or changes a file.
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$root" 2>/dev/null || exit 0
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
lang="FIRST, before anything else in your first reply, ask the human whether to talk in Spanish or English this session, and use that language for the rest of the session (your replies and the agent reports you relay). Pass that language to subagents in your request."
# First-run onboarding: only while sample content is on disk and the marker is absent.
onboard=""
if [ ! -e .claude/.onboarded ] && [ -f .claude/scripts/sample-content.txt ]; then
  while IFS= read -r p; do
    case "$p" in ''|'#'*) continue ;; esac
    if [ -e "$p" ]; then
      onboard="ONBOARDING (first run, show it once): right after asking the conversation language, welcome the human in a few lines: this is a wiki that agents build from their sources, and they only write in plain words. Then offer two paths: explore the sample first (e.g. ask something about RAG, or ask to be quizzed), or start their own wiki (the Reset operation)."
      touch .claude/.onboarded 2>/dev/null
      break
    fi
  done < .claude/scripts/sample-content.txt
fi
[ -n "$onboard" ] && lang="$lang $onboard"
if [ "$total" -eq 0 ]; then
  jq -n --arg ctx "$lang" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
  exit 0
fi

line() { [ "$2" -gt 0 ] && printf '%s %d (%s)' "$1" "$2" "$3"; }
parts=()
[ ${#open[@]} -gt 0 ]   && parts+=("$(line "open:" ${#open[@]} "I can fix them")")
[ ${#review[@]} -gt 0 ] && parts+=("$(line "needs-review:" ${#review[@]} "waiting for your approval")")
[ ${#source[@]} -gt 0 ] && parts+=("$(line "needs-source:" ${#source[@]} "need a source in raw/")")
joined=$(printf '%s; ' "${parts[@]}"); summary="Pending flags — ${joined%; }"
detail=$(printf 'Pending flags in flags/open/:\n'; for n in "${open[@]}"; do echo "- open: $n"; done; for n in "${review[@]}"; do echo "- needs-review: $n"; done; for n in "${source[@]}"; do echo "- needs-source: $n"; done; echo "$lang"; echo "Then tell the human about the flags, in plain words and without commands, and offer to process them. Do not run the curator until they agree.")
jq -n --arg msg "$summary" --arg ctx "$detail" \
  '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
