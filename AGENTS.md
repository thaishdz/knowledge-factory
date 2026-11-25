# AGENTS.md — Wiki schema

An LLM Wiki (Karpathy's pattern) run as a knowledge factory. The human
curates `raw/`, asks questions and reviews changes; the agents write
everything else, each in its own area. Read this whole file and
`wiki.config.md` before any operation, then your own file in
`.claude/agents/`, which holds the detailed procedures you run. If the two
disagree, this file wins.

## Structure

```
raw/            Original sources; the root is the inbox
  articles/ papers/ repos/ assets/
  SOURCES.md    Title, author, URL and license of every source; marks link-only ones
wiki/           Pages maintained by the agents
  entities/     Named things: tools, people, companies, projects
  topics/       Concepts and ideas
  comparisons/  X vs Y, with trade-offs
  timelines/    How a topic or entity evolved
  qa/           Answers combining several pages. Private: only README.md is tracked
  assets/       SVG diagrams used by the pages
artifacts/      Visual HTML summaries generated from the wiki
flags/          Gaps or errors found in the wiki. Private: only TEMPLATE.md is tracked
  open/ closed/ TEMPLATE.md
learner/        How the human learns. Private: only README.md is tracked
  trace/        L1: raw traces, one file per month (YYYY-MM.md)
  profile.md    L2: facts about how they learn, with evidence
  review.md     Leitner review queue
  quiz.md       Quiz waiting to be graded (only while one is open)
  cards/        HTML flashcards per quiz
.claude/
  agents/       tutor, auditor, curator, mentor, archivist; Explore
  hooks/        Write limits per subagent; session-start flag report and welcome; first-prompt onboarding; prefs.sh (local preferences helper)
  scripts/      reset-wiki.sh and sample-content.txt (Reset operation)
  commands/     Slash commands for the human (/wiki-help)
  user-prefs.json  Local preferences (language, onboarded). Private: gitignored
wiki.config.md  Repo-specific settings (content language, section titles)
index.md        Catalog of every public wiki page
videos.md       Suggested videos per article
CLAUDE.md       Only imports this file. No rules there
README.md       Onboarding for humans. Not part of the wiki
```

## General rules

1. Never modify or delete anything in `raw/`, except moving a source from
   its root to a category folder during an ingest, unchanged, and the
   sample sources the Reset operation removes with its script.
2. Every claim on a wiki page must trace back to a source in `raw/`. Mark
   your own inferences as such.
3. Don't make things up. If the sources don't cover something, say so in the
   page's open-questions section.
4. If a new source contradicts a page, don't overwrite silently: record the
   contradiction and which source says what.
5. `git log` is the history: one commit per change, Conventional Commit
   subjects; an optional one-line note goes in the commit body.
6. Every page created, renamed or deleted is reflected in `index.md`.
7. The agents make the commits, not the human.
8. A source whose license doesn't allow redistribution is **link-only**:
   `raw/SOURCES.md` lists it with its URL and `link-only`, and its file is
   kept out of git with `.git/info/exclude` (not `.gitignore`, which is
   shared). Pages cite it as usual. If its file isn't on disk, an agent that
   needs the text says so instead of guessing (the curator uses
   `needs-source`).

## Language

- Documentation (`AGENTS.md`, `README.md`, `CLAUDE.md`, `.claude/`): English.
- Wiki content (pages, `index.md` descriptions, flags, `learner/`,
  artifacts, flashcards): the `content_language` in `wiki.config.md`. If
  `wiki.config.md` allows mixing, section titles and set phrases may stay in
  English when the English is correct and idiomatic.
- Conversation: asked once with a menu, not in text. When `language` isn't
  in the local preferences (see "Local preferences"), the main session calls
  `AskUserQuestion` before anything else in its first reply (question
  "Idioma / Language?", options Español and English). A `PostToolUse` hook on
  `AskUserQuestion` (`remember-language.sh`) saves the answer (`es` or `en`),
  whether it came from this menu or from the onboarding menu. From then on
  the `SessionStart` hook (`session-flags.sh`) tells the main session which
  language to use and not to ask; the human can ask to switch at any time
  (the main session shows the menu again and the value is overwritten). The
  main session uses that language for the rest of the session (its replies
  and the agent reports it relays) and passes it to the subagents in its
  request; without one, they report in `content_language`. This is
  independent of `content_language`.
- Tags, commands and commit messages: always English.

## Page conventions

- File name: `kebab-case.md`, English for technical terms
  (`vector-database.md`), no dates.
- One page per entity or concept. Check `index.md` for an existing page
  under another name first.
- Wikilinks (`[[vector-database]]`); link the first mention of anything
  that has a page.
- No videos on pages: they live only in `videos.md`.
- Diagrams: SVG in `wiki/assets/` named after the page
  (`vector-database.svg`, `vector-database-2.svg`), embedded with
  `![[vector-database.svg]]`. A diagram only shows what the text says; if
  the page changes, review it.
- Section titles come from `section_titles` in `wiki.config.md` (content,
  open questions, related, sources), in that order:

```markdown
---
title: Vector database
type: topic            # entity | topic | comparison | timeline | qa
tags: [rag, databases]
sources:
  - raw/articles/file-name.md
created: 2026-11-13
updated: 2026-11-13
---
# Title

A 2–3 sentence summary.

## <content sections>
## <open questions>
## <related>
## <sources>
```

- `index.md`: grouped by type, alphabetical, one line per page, descriptions
  in the content language; `wiki/qa/` is never listed; artifacts have their
  own section with the path:

  ```markdown
  ## Topics
  - [[vector-database]] — Database that indexes embeddings for similarity search

  ## Artifacts
  - `artifacts/rag.html` — Visual summary of RAG
  ```

- `videos.md`: one block per article, alphabetical by path, one line per
  video, duration optional:

  ```markdown
  ## raw/articles/file-name.md
  - [Video title](https://...) — channel, duration
  ```

- `wiki/qa/` answers (`type: qa`) follow the same conventions but are
  private: only its `README.md` is tracked, they are never committed or
  indexed, public pages don't link to them (they may link to public pages),
  and problems inside them are reported, not flagged. The mentor proposes
  them (see `.claude/agents/mentor.md`).

## Knowledge factory

Many agent failures come from missing knowledge, not a bad model. So
whoever uses knowledge doesn't maintain it. When an agent lacks information
or something looks wrong, it raises a flag instead of guessing; a separate
agent, the curator, processes flags and updates the store (this git repo).

```
question ─► tutor ───┐
                     ├─► flags/open/ ─► curator ─► wiki/ + commit ─► better answers
lint ─────► auditor ─┘                     └─► needs-source ─► the human adds a source

question ─► tutor ─► learner/trace/ ─┐
quiz / review ─► mentor ─────────────┴─► learner/profile.md + review.md ─► better quizzes
```

### Roles

| | Tutor | Auditor | Curator | Mentor | Archivist | Main session |
|---|---|---|---|---|---|---|
| Runs on | Any question | `lint` | `curate`; approved plans (ingest pages, artifact, video, qa page) and the end of a reset | `quiz`, `review` | Sources entering or being filed in `raw/` | Every input from the human: it orchestrates |
| Looks at | Pages needed to answer | The whole wiki | Flags or the plan, and `raw/` | `wiki/`, `learner/` | The material and `raw/` | Agents' reports and their commits |
| Writes to | `flags/open/`, `learner/trace/` | `flags/open/` | `wiki/`, `artifacts/`, `index.md`, `videos.md`, `flags/`; framework files for `procedure` flags; `wiki.config.md` at the end of a reset | `learner/`, `flags/open/` | Copies and moves in `raw/`, `raw/SOURCES.md`, `.git/info/exclude` | `flags/open/` (procedure) only |
| Commits | No | No | Yes | No | Yes | No |

- The tutor answers the human's questions; the mentor quizzes them and
  tracks how they learn. Neither edits the wiki.
- The tutor finds problems in passing (mostly `missing`); the auditor
  reviews everything (mostly structure). The curator closes duplicates.
- The main session only orchestrates: it talks to the human, writes the
  plans they approve, hands each task to its agent, reviews what comes back
  (`git show` on each commit) and reports. It doesn't write pages, move
  sources or commit. If a commit is wrong, it sends the fix back to the
  agent that made it. It steps in only when an agent goes in circles or
  can't get past an obstacle, and says so to the human.
- Approvals stay with the main session, because a subagent can't ask while
  it works: it asks the human, then delegates. In Study the human only
  approves the plan.
- Each subagent reads this file, `wiki.config.md` and its own file in
  `.claude/agents/`. Hooks in `.claude/hooks/` enforce the "Writes to" row,
  block the curator from `raw/` and stop the archivist from deleting,
  editing or overwriting sources. The auditor's and archivist's `Bash`
  checks are pattern-based, so for them the limit is partly an instruction.
- No agent runs in the background or on a schedule. Instead, a
  `SessionStart` hook (`session-flags.sh`) reports pending flags when a
  session starts; the main session tells the human at the start of its first
  reply and offers to process them; the curator only runs once they agree.
  On a first run (sample content still present and `onboarded` not set in
  the local preferences) the same hook shows the human a welcome at startup
  (`systemMessage`: "Write anything to start"), because the assistant never
  speaks first. A `UserPromptSubmit` hook (`onboarding.sh`) then adds the
  onboarding instruction to the reply to their first message, even if it is a
  slash command, and only then sets `onboarded`. The instruction is a menu:
  after one or two lines of welcome, the main session calls `AskUserQuestion`
  once with the language and what to do first (explore the sample, start
  their own wiki, or what can I say). The language is asked only there, not
  separately in text, and only if `language` isn't set yet (otherwise the
  menu has just the second question).

### Local preferences

`.claude/user-prefs.json` holds the human's preferences for this machine,
e.g. `{"language": "es", "onboarded": true}`. Keys: `language` (`es` or
`en`, the conversation language) and `onboarded` (the first-run menu was
shown). It is gitignored: local only, never committed. The hooks read it with
`jq` (a missing or invalid file means no preferences) and every write merges
with the existing keys through a temp file, so one key never wipes another
and a corrupt file is replaced. The shared helper is
`.claude/hooks/prefs.sh`; it also folds the old marker files
`.claude/.onboarded` and `.claude/.language` into the JSON and deletes them.
It is not `.claude/settings.local.json`, which belongs to Claude Code.

### Models and delegation

The main session is the lead and runs on the session's model. It owns
quality, the conventions in this file and privacy. Reading, exploring and
mechanical filing go to Haiku; writing goes to Sonnet. Models are set in
each agent's `model:` frontmatter.

| Agent | Model | Does |
|---|---|---|
| `Explore` | Haiku | Read-only lookups for the main session: which pages, sources or files cover something. Returns paths and short findings. It must keep that exact name: it replaces Claude Code's built-in `Explore`, which runs on the session's model |
| archivist | Haiku | Brings sources into `raw/`, files them, records them in `raw/SOURCES.md` and commits them, without changing their content |
| curator | Sonnet | Its flags, plus every approved plan that writes (ingest pages, artifact, video, saved qa page): writes, runs the wiki checks and commits |
| tutor, auditor, mentor | Sonnet | Their roles above |

### Flags

One file per flag: `flags/open/YYYY-MM-DD-<type>-<slug>.md`, from
`flags/TEMPLATE.md`:

```markdown
---
type: missing          # missing | contradiction | stale | broken-link | orphan | structure | procedure
page: wiki/topics/example.md   # optional
raised_by: tutor       # tutor | auditor | mentor | main
raised: 2026-11-24
status: open           # open | needs-source | needs-review | closed
suggestion: ""         # optional: the fix the raiser proposes
resolution: ""         # only when closing
---
Short description of the gap or problem.
```

- Types: `missing` (the wiki lacks something), `contradiction` (pages, or a
  page and its source, disagree), `stale` (superseded claim, or artifact
  older than its pages), `broken-link`, `orphan` (page without incoming
  links, or unembedded diagram), `structure` (index, frontmatter,
  `videos.md` or framework don't match), `procedure` (the human corrected
  how the agents work; see below).
- States: `open` (no commit until the curator processes it),
  `needs-source` (`raw/` doesn't cover it; the human must add a source),
  `needs-review` (proposed fix awaiting approval; always for
  `contradiction`), `closed` (moved to `flags/closed/` with a `resolution`).
- Whoever raises a flag doesn't fix it, but may propose the fix in
  `suggestion:` (e.g. the right page, the missing fact, the corrected name).
  The curator treats it as a lead, never as a source: it still checks
  `raw/`.
- Check `flags/open/` for duplicates first.
- Flags are the factory's own working knowledge, not the wiki's: everything
  in `flags/open/` and `flags/closed/` is in `.gitignore` and never goes
  into a commit. Never `git add -f` them. Only `flags/TEMPLATE.md` (and the
  folders' `.gitkeep`) is tracked.
- A flag describes the wiki's gap and never quotes the human's question,
  says what they asked, or names a `wiki/qa/` page: its content feeds wiki
  fixes and commit messages.

**Procedure flags.** When the human corrects *how* something is done — a
convention, a step, a format, something to stop doing — the main session
raises a `procedure` flag (`raised_by: main`) right away, says so in one
line and carries on with the corrected behavior. The flag states the
procedure in general terms, never the conversation or personal details, and
puts the proposed rule change in `suggestion:`. When the human asks
directly for a framework change, the main session also raises a
`procedure` flag with the change in `suggestion:` and hands it to the
curator; the request counts as approval, so the curator applies and commits
it, unless it's ambiguous (then `needs-review`). The flag goes in this repo's
`flags/open/`. One-off preferences that don't generalize aren't flagged.

## Operations

The human never types commands and never calls an agent. They write in
plain words (a topic, some material, a question, a link, a yes) and the
main session works out the operation and orchestrates the agents. The
operation names below (`study`, `ingest`, `curate`…) are internal: they
name the procedures in this file and the agents' instructions. If the human
does type one, run it, with no reminder.

| What the human writes | Operation | Who | Detail in |
|---|---|---|---|
| A topic to learn, or material (a file, a folder, a course) | Study | Main session orchestrating Explore, archivist, curator, auditor, mentor | below |
| Wants to start their own wiki, or to clear the sample content | Reset | Main session + curator | below |
| A question about what they're learning | Query | Tutor | `tutor.md` |
| A pasted `QUIZ RESULTS` block | Quiz grading | Mentor | `mentor.md` |
| A video link, with or without the article it goes with | Video | Main session + curator | below |
| Asks to be quizzed, or what's due for review | Quiz / review | Mentor | `mentor.md` |
| Asks for a visual summary of a topic | Artifact | Main session + curator | below; `curator.md` |
| Asks to add one specific source from `raw/` | Ingest | Main session + archivist + curator | below; `archivist.md`, `curator.md` |
| Asks to check the wiki | Lint, then Curate on the new flags | Auditor, curator | `auditor.md`, `curator.md` |
| Agrees to process pending flags, or approves a proposal in one | Curate (all, or that flag) | Curator | `curator.md` |

- If the input fits more than one operation, ask one short question.
- `<name>` is part of a file name: the human never gives paths or
  extensions.
- Pending flags and reviews due today are offered in plain words ("there
  are 2 gaps I can fix, shall I?"), never as a command to type.
- Query: the main session passes the question as-is and relays the answer.
  For a comparison with lasting value the tutor suggests saving it in
  `wiki/comparisons/`; for a broad topic, it offers an artifact; `wiki/qa/`
  pages are the mentor's call (and, if accepted, the main session has the
  curator write them: no commit, they're private).
- Quiz: the mentor writes `learner/cards/<slug>.html`; the main session
  runs `open learner/cards/<slug>.html`.
- `/wiki-help` (`.claude/commands/wiki-help.md`) shows the human what they
  can say and what's pending. If operations, roles or flag states change,
  update it too.

### Study

The human writes "I want to learn RAG" or "here's a RAG course". One
approval, at the plan; after that the main session runs to the end without
asking, and only stops if something blocks the whole topic.

1. **Scope.** If the human hands over material (a file or folder), the
   archivist copies it unchanged into the root of `raw/`; a URL can't be
   saved as-is, so ask the human to save it in `raw/` (e.g. with Obsidian's
   web clipper). Then use `Explore` to find the sources in `raw/` on the
   topic, which of them have no ingest commit in `git log` (e.g.
   `git log --oneline --grep ingest`), and what `index.md` and `wiki/`
   already cover. If `raw/` has nothing on the topic and the wiki doesn't
   cover it, say which kind of source would be needed and stop.
2. **Plan (the only approval).** Show in a few lines: the sources to ingest
   (with the category for those in the root and whether each is link-only),
   the pages each one creates or updates, the artifact and its sections,
   the size of the quiz, and what the sources won't cover. Wait for the
   human's approval; changes to the plan are made now.
3. **Build.** For each source, in order: the archivist files it in its
   category, records it in `raw/SOURCES.md` and commits it; the curator
   (plan mode) writes its part of the plan and commits the ingest. The main
   session reviews each commit and sends fixes back. This replaces the
   questions and the approval of Ingest steps 1–4. Remote images that need
   Obsidian go to the final report; don't stop for them.
4. **Check.** Run the auditor (`lint`), then the curator (`curate`) on the
   flags it raised. `needs-source` and `needs-review` flags wait for the
   human: list them in the final report, don't stop.
5. **Study material.** If the plan includes an artifact, the curator writes
   and commits it (plan mode); the main session reviews it. Then the mentor
   builds the quiz on the topic and the main session opens the cards.
6. **Report.** In a few lines: what the wiki learned (pages and commits),
   what's still missing and which source would fill it, anything waiting
   for the human's decision, and what to do next: ask anything, and paste
   the results when the cards are done.

Anything the plan didn't foresee and that doesn't block the topic goes to
the final report instead of a question.

### Ingest

`ingest <name>`, one source at a time.

1. Find files in `raw/` (root and category folders, not `assets/`) whose
   name contains `<name>`, case-insensitive. One: say which. Several: ask.
   None: say so and list the sources with no ingest commit in `git log`
   (e.g. `git log --oneline --grep ingest`).
2. If it's in the root of `raw/`, ask its category (`article`, `paper`,
   `repo`), suggesting the likeliest. If it's already in a category folder,
   don't ask. The archivist files it, makes sure `raw/SOURCES.md` lists it
   with its license (link-only if it can't be redistributed, rule 8) and
   commits that.
3. Read it whole, then any images in `raw/assets/` it references. If images
   are still remote URLs, ask the human to press `Cmd+Shift+D` in Obsidian
   ("Download attachments for current file"); you can't. After a move,
   check the image links still work.
4. Summarize the key points and the pages you'll create or touch. Wait for
   approval.
5. Read `index.md` and the related pages.
6. Delegate to the curator, passing the approved summary as its plan (what
   it does with it is in `curator.md`).
7. Review the commit (`git show`) and send any fix back to the curator.

### Video

A video goes with an article. It's not a source: don't watch or transcribe
it, and take no claims from it. It's recorded only in `videos.md`. Videos
always come from the human; don't search for others.

`video <url> for <name>` (no questions):

1. Find the article in `raw/articles/` as in ingest step 1.
2. Title and channel: from the human or, for YouTube, the public oEmbed
   (`https://www.youtube.com/oembed?url=<url>&format=json`: `title`,
   `author_name`) with a generic `User-Agent`. Otherwise ask. Never invent.
   Duration only if the human gives it.
3. The curator adds it under the article in `videos.md` and commits.

`video <url>`: get title and channel, suggest up to three articles (most
likely first, one line why each), wait for the choice, then step 3.

### Artifact

`artifact <topic>`: an HTML page that summarizes a topic visually,
generated from the wiki and regenerable at any time; not a source or a wiki
page.

1. Read `index.md` and the topic's pages. If the wiki doesn't cover it, say
   so and stop.
2. Say which pages you'll use and which sections it'll have. Wait for
   approval.
3. Delegate to the curator with the approved pages and sections (the rules
   and visual style are in `curator.md`).
4. Review the artifact against those rules; send fixes back.

### Reset

The human says they want to start their own wiki or clear the sample
content that ships with the template. Only on explicit request, never as
part of Study. It is usually reached from the one-time welcome that the
onboarding hook asks for on a first run.

1. The main session runs `.claude/scripts/reset-wiki.sh --dry-run` and shows
   the human what will be deleted: sample pages, diagrams, artifacts and
   sources in `raw/`. If it reports no sample content, say so and stop.
2. In the same message it asks for `content_language`, `mixing`,
   `section_titles` and `flashcard_labels` (proposing the current values)
   and for one confirmation. Nothing is deleted before it.
3. The main session runs `.claude/scripts/reset-wiki.sh`. The script is the
   only thing allowed to delete from `raw/` (rule 1): it removes only the
   paths in `.claude/scripts/sample-content.txt`, keeps every folder (with
   `.gitkeep`) and rewrites `index.md`, `videos.md` and `raw/SOURCES.md` as
   empty skeletons. It stops if `git status` isn't clean. Private data
   (`learner/`, `flags/`, `wiki/qa/`) is never touched.
4. The curator (plan mode) writes the values the human gave into
   `wiki.config.md`, checks no link or index entry points to a deleted page
   and commits `docs(wiki): reset sample content`.
5. The main session reviews the commit and tells the human the wiki is
   empty and they can say what they want to learn. It reminds them to check
   `LICENSE-content`, which covered the sample content.

## Privacy

- Never send the human's personal email to an external service (`User-Agent`,
  `mailto=`/`email=` parameters, forms, search text). Use a generic
  `User-Agent`. If a service requires an email, stop and ask.
- Never write their email in wiki pages or commit messages.
  Public repos commit with the GitHub `noreply` address.
- Nothing from `learner/` or `wiki/qa/` leaves the machine: not in
  searches, commits, artifacts, flashcards or flags. Everything in
  `learner/` except `README.md` is in `.gitignore`; never `git add -f` it.
- Flags stay on the machine too: they're never committed or pushed.

## Commits

Made by the curator and the archivist at the end of each task; the main
session reviews each one with `git show`, and so can the human. The main
session doesn't commit.

- Conventional Commits, `type(scope): description`, English, imperative,
  lowercase.
- Unsigned: no `Co-Authored-By`, `Signed-off-by`, agent or model mentions,
  no GPG.
- Atomic: one logical change per commit; never mix operations, or schema
  with wiki content.
- No `git push` unless the human asks.
- Before committing, `git status`: include only what this operation
  touched, and warn about anyone else's changes. Flags are ignored by git
  and never go into a commit.

| Case | Example |
|---|---|
| New source | `docs(raw): add karpathy llm wiki gist` |
| Ingest | `docs(wiki): ingest karpathy llm wiki gist` |
| Video | `docs(videos): add suggested video for karpathy llm wiki gist` |
| Artifact | `docs(artifacts): add visual summary for rag` |
| Flag fixed | `fix(wiki): resolve missing flag on embeddings` |
| Flag closed without a fix, parked or proposed | No commit (flags are private) |
| `AGENTS.md` / `README.md` | `docs(schema): …`, `docs(readme): …` |
| Config (`.claude/`, `.obsidian/`, `.gitignore`) | `chore(config): …` |
| Procedure flag applied | `docs(schema): resolve procedure flag on gitignore comments` |
| Reset (sample content removed) | `docs(wiki): reset sample content` |
| Saved qa answer | No commit (private) |

## Changes to this schema

If a convention isn't working, propose the change; don't edit this file on
your own. Each accepted change is committed as `docs(schema): …`.
