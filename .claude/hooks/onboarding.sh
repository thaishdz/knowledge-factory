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
    if [ -s .claude/.language ]; then
      menu="with one question: header 'Start', question"
      after="the human already chose the conversation language (see the session context): keep using it, never ask it again."
    else
      menu="with two questions. Question 1: header 'Language', question 'Idioma / Language?', options 'Español' and 'English'. Question 2: header 'Start', question"
      after="only after the answer, use the chosen language for the rest of the session (your replies and the agent reports you relay; pass it to subagents)."
    fi
    ctx="ONBOARDING (first run, show it once, in this reply, even if the human's message is a slash command such as /wiki-help, a greeting or a concrete request): do NOT ask anything in plain text. Start with one or two lines of welcome (this is a wiki that agents build from your sources; you only write in plain words), then call the AskUserQuestion tool once ${menu} 'What do you want to do first?', options 'Explore the sample' (description: ask something about RAG or take a quiz), 'Start my own wiki' (description: clears the sample and asks for language and titles: the Reset operation), 'What can I say' (description: shows /wiki-help). Keep the menu text in English; ${after} Then: 'Explore the sample' -> suggest one concrete question about the sample and offer a quiz; 'Start my own wiki' -> run the Reset operation from its step 1 (dry run, then ask the config values and the single confirmation); 'What can I say' -> show the /wiki-help guide; Other -> act on what they wrote. If their first message already asked for something concrete, show the menu first, then carry on with it."
    jq -n --arg ctx "$ctx" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}' 2>/dev/null && touch .claude/.onboarded 2>/dev/null
    exit 0
  fi
done < .claude/scripts/sample-content.txt
exit 0
