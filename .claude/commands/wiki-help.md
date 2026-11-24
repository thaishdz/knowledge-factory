---
description: Cheat sheet of the wiki commands and state of pending flags
allowed-tools: Bash(grep:*), Bash(ls:*)
---

Show the human the cheat sheet below exactly as written, without adding
explanations or running any wiki command. Then add a "Status" section with a
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

## Alejandria cheat sheet

**Ask the wiki** → *librarian*
- Type the question as-is. It answers only from the wiki, cites the pages
  and raises a flag if something is missing or doesn't add up.

**Learn** → *mentor*
| Command | What it does |
|---|---|
| `quiz <topic>` | HTML flashcards on a wiki topic (opens in the browser) |
| `review` | HTML flashcards for what's due today |
| *(paste `QUIZ RESULTS`)* | When you finish the cards: click the copy-results button and paste it here. The mentor grades and updates your profile |
- Your profile, traces and cards live in `learner/`; saved answers, in `wiki/qa/`. Both are private and never go into git.
- If a question repeats, the mentor will suggest saving it in `wiki/qa/`.

**Sources and content** → *main session*
| Command | What it does |
|---|---|
| `ingest <name>` | Adds a source from `raw/` to the wiki |
| `video <url> for <name>` | Records a video under an article, no questions asked |
| `video <url>` | Same, but suggests the article |
| `artifact <topic>` | Generates a visual summary in HTML |

**Maintenance** → *auditor* and *curator*
| Command | Who | What it does |
|---|---|---|
| `lint` | auditor | Reviews the whole wiki and raises flags. Fixes nothing |
| `curate` | curator | Processes every open flag: fixes, parks or proposes |
| `curate <name>` | curator | Processes a single flag (e.g. after adding a source or approving a proposal) |
| `promote` | main session | Prod only: brings framework changes from the staging repo, after showing the diff |

**Flag states**
- `open` → run `curate`
- `needs-source` → add a source to `raw/`, run `ingest`, then `curate <name>`
- `needs-review` → read the proposal in the flag and approve it with `curate <name>`
- `closed` → review the commit with `git show`

<name> = part of the file name, no path or extension. Full rules in `AGENTS.md`.
