#!/bin/bash
# SessionStart hook: report pending flags so the human decides when to curate.
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
[ "$total" -eq 0 ] && exit 0

line() { [ "$2" -gt 0 ] && printf '%s %d (%s)' "$1" "$2" "$3"; }
parts=()
[ ${#open[@]} -gt 0 ]   && parts+=("$(line "open:" ${#open[@]} "run curate")")
[ ${#review[@]} -gt 0 ] && parts+=("$(line "needs-review:" ${#review[@]} "approve with curate <name>")")
[ ${#source[@]} -gt 0 ] && parts+=("$(line "needs-source:" ${#source[@]} "add a source, then ingest")")
summary="Pending flags — $(IFS='; '; echo "${parts[*]}")"
detail=$(printf 'Pending flags in flags/open/:\n'; for n in "${open[@]}"; do echo "- open: $n"; done; for n in "${review[@]}"; do echo "- needs-review: $n"; done; for n in "${source[@]}"; do echo "- needs-source: $n"; done; echo "Tell the human about them at the start of your first reply, in the content language. Do not run curate unless they ask.")
jq -n --arg msg "$summary" --arg ctx "$detail" \
  '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
