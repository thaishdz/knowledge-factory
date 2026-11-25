---
description: What you can say to the wiki, and what's pending
allowed-tools: Bash(grep:*), Bash(ls:*)
---

If this listing is not empty, start with this line: "This is the sample
wiki; say 'I want to start my own wiki' to clear it."

```
!`ls wiki/topics/rag.md wiki/topics/llm-wiki.md wiki/topics/knowledge-factory.md 2>/dev/null || true`
```

Show the human the guide below exactly as written, without adding
explanations or running any operation. Then add a "Status" section with a
one-line summary per pending flag, based on this listing (if it's empty, say
"No pending flags"):

```
!`grep -H "^status:" flags/open/*.md 2>/dev/null || true`
```

Also add a line for the quiz: if this listing is not empty, say "You have a
pending quiz: practice the cards and paste the QUIZ RESULTS block here"; if
it's empty, say nothing.

```
!`ls learner/quiz.md 2>/dev/null || true`
```

---

## How to use the wiki

Just write. No commands, no agents to call: I work out what you need and
run the agents myself.

| You write | What happens |
|---|---|
| "I want to learn RAG", "here's a RAG course" | I show you one plan. Once you approve it, I build the wiki pages, check them, make a visual summary and open a quiz |
| Any question | Answered only from the wiki, citing the pages. If something's missing, I note the gap |
| The `QUIZ RESULTS` you copied from the cards | Graded; your next reviews are scheduled |
| "Quiz me on X", "what's due today?" | New flashcards |
| A video link | Saved under the article it goes with |
| "Check the wiki" | Reviewed for errors; I fix what the sources allow |
| "I want to start my own wiki", "clear the sample content" | I show you what the template's sample content is, ask you for the language and titles, and after your yes I empty the wiki |
| "Yes" to a pending proposal | Applied and committed |

**Pending items** (I tell you when a session starts)
- Gaps I can fix → I'll offer; say yes.
- Waiting for your approval → I'll show the proposal; say yes or no.
- Needs a source → add one to `raw/` (or hand it to me) and tell me.

Your profile, quiz cards, saved answers and flags stay on your machine and
never go into git. Full rules in `AGENTS.md`.
