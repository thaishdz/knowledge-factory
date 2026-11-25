#!/bin/bash
# UserPromptSubmit hook: first-run onboarding, shown once in the reply to the human's first message.
# Only while sample content is on disk and .claude/.onboarded is absent; then it creates the marker.
# Fast and never fails: valid JSON or no output, always exit 0.
cat >/dev/null 2>&1
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" 2>/dev/null || exit 0
[ -e .claude/.onboarded ] && exit 0
[ -f .claude/scripts/sample-content.txt ] || exit 0
while IFS= read -r p; do
  case "$p" in ''|'#'*) continue ;; esac
  if [ -e "$p" ]; then
    ctx="ONBOARDING (first run, show it once, in this reply, even if the human's message is a slash command such as /wiki-help or just a greeting): after asking the conversation language (if not asked yet), welcome the human in a few lines: this is a wiki that agents build from their sources, and they only write in plain words. Then offer two paths: explore the sample first (e.g. ask something about RAG, or ask to be quizzed), or start their own wiki (the Reset operation). Then carry on with what they wrote."
    jq -n --arg ctx "$ctx" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}' 2>/dev/null && touch .claude/.onboarded 2>/dev/null
    exit 0
  fi
done < .claude/scripts/sample-content.txt
exit 0
