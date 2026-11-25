# AGENTS.md — Wiki schema

An LLM Wiki (Karpathy's pattern) run as a knowledge factory. The human curates
`raw/`, asks questions and reviews; the agents write everything else, each in
its own area. Read this file and `wiki.config.md` before any operation, then
your own file in `.claude/agents/` (detailed procedures). This file wins.

## Structure

```
raw/            Sources; root = inbox (articles/ papers/ repos/ assets/); SOURCES.md
wiki/           entities/ topics/ comparisons/ timelines/ assets/ (SVG); qa/ (private)
artifacts/      Visual HTML summaries generated from the wiki
flags/          open/ closed/ TEMPLATE.md. Private: only TEMPLATE.md tracked
learner/        trace/YYYY-MM.md, profile.md, review.md, quiz.md, cards/. Private
.claude/        agents/ hooks/ scripts/ (reset) commands/ (/wiki-help) user-prefs.json
wiki.config.md  Repo settings        index.md  Page catalog      videos.md  Videos
CLAUDE.md       Only imports this file       README.md  Human onboarding
```

## General rules

1. Never modify or delete anything in `raw/`, except moving a source from the
   root to a category folder during an ingest, unchanged, and the sample
   sources Reset removes with its script.
2. Every claim on a wiki page traces to a source in `raw/`; mark your own
   inferences. Don't make things up: gaps go in the open-questions section.
3. A contradicting source is recorded (which says what), never silently
   overwritten.
4. Every page created, renamed or deleted is reflected in `index.md`.
5. The agents commit, not the human (see "Commits").
6. A source that can't be redistributed is **link-only**: `raw/SOURCES.md`
   lists it with URL and `link-only`, its file stays out of git via
   `.git/info/exclude` (not `.gitignore`), pages cite it as usual. If the file
   isn't on disk, say so instead of guessing (curator: `needs-source`).

## Language and local preferences

- Documentation, tags, commands, commits: English. Wiki content (pages,
  `index.md`, flags, `learner/`, artifacts, flashcards): `content_language`
  (`mixing` allows English section titles and set phrases).
- Conversation language is separate: asked once with a menu, remembered,
  passed to subagents (default for them: `content_language`). A first-run
  welcome and onboarding menu show while the sample content exists.
- Both live in the gitignored `.claude/user-prefs.json`, written only by the
  hooks (`session-flags.sh`, `onboarding.sh`, `remember-language.sh`), which
  inject the exact instructions at runtime.

## Page conventions

- Files `kebab-case.md`, no dates; one page per concept (check `index.md`).
  Link the first mention of anything with a page (`[[vector-database]]`).
  No videos on pages. Diagrams: SVG in `wiki/assets/` named after the page
  (`name.svg`, `name-2.svg`), embedded `![[name.svg]]`; review on changes.
- Section titles from `section_titles` in `wiki.config.md`, in order:

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

- `index.md`: by type, alphabetical, `- [[page]] — description`; artifacts
  under "Artifacts" as ``- `artifacts/rag.html` — description``; no `wiki/qa/`.
- `videos.md`: per article, alphabetical by path: `## raw/articles/file.md`,
  then `- [Title](https://...) — channel, duration` (duration optional).
- `wiki/qa/` pages (`type: qa`): never committed or indexed, not linked from
  public pages; problems in them are reported, not flagged.

## Knowledge factory

Whoever uses knowledge doesn't maintain it: an agent lacking information or
seeing something wrong raises a flag instead of guessing; the curator
processes flags and updates this repo.

| | Tutor | Auditor | Curator | Mentor | Archivist | Main session |
|---|---|---|---|---|---|---|
| Runs on | Any question | `lint` | `curate`; approved plans (ingest, artifact, video, qa page, reset end) | `quiz`, `review` | Sources entering `raw/` | Every human input |
| Writes to | `flags/open/`, `learner/trace/` | `flags/open/` | `wiki/`, `artifacts/`, `index.md`, `videos.md`, `flags/`; framework files for `procedure` flags; `wiki.config.md` at reset | `learner/`, `flags/open/` | `raw/` copies and moves, `SOURCES.md`, `.git/info/exclude` | `flags/open/` (procedure) |
| Commits | No | No | Yes | No | Yes | No |
| Model | Sonnet | Sonnet | Sonnet | Sonnet | Haiku | Session's |

- `Explore` (Haiku; keep that exact name, it replaces the built-in) does
  read-only lookups. Tutor and mentor never edit the wiki.
- The main session only orchestrates: talks to the human, writes the plans
  they approve (subagents can't ask), delegates, reviews every commit
  (`git show`), reports. It never writes pages, moves sources or commits; a
  wrong commit goes back to its agent. It steps in only if an agent loops or
  is blocked, and says so.
- Hooks enforce the "Writes to" row, block the curator from `raw/` and stop
  the archivist editing sources (auditor and archivist `Bash` checks are
  partly an instruction). Nothing runs in the background: the `SessionStart`
  hook reports pending flags, the main session offers to process them, and
  the curator runs only on agreement.

### Flags

`flags/open/YYYY-MM-DD-<type>-<slug>.md` from `flags/TEMPLATE.md` (`raised_by`:
tutor | auditor | mentor | main); check duplicates first.

- Types: `missing`; `contradiction` (pages, or page and source, disagree);
  `stale` (superseded claim, artifact older than its pages); `broken-link`;
  `orphan` (no incoming links, unembedded diagram); `structure` (index,
  frontmatter, `videos.md`, framework); `procedure` (see below).
- Status: `open` (no commit until processed); `needs-source` (human must add
  a source); `needs-review` (fix awaiting approval, always for
  `contradiction`); `closed` (moved to `flags/closed/` with `resolution`).
- The raiser never fixes; `suggestion:` is a lead the curator verifies in
  `raw/`, never a source. Flags are gitignored, never committed (never
  `git add -f`), and never quote the human's question or name a `wiki/qa/` page.
- **Procedure flags**: when the human corrects *how* something is done, the
  main session raises one (`raised_by: main`) at once, says so in one line and
  follows the corrected behavior; general terms only, rule change in
  `suggestion:`. A direct request for a framework change counts as approval:
  the curator applies and commits it (`needs-review` if ambiguous). One-off
  preferences aren't flagged.

## Operations

The human writes in plain words; the main session picks the operation (if a
name is typed, just run it). Ambiguous: one short question. Offer pending
flags and due reviews in plain words.

| What the human writes | Operation | Who | Detail in |
|---|---|---|---|
| A topic to learn, or material (file, folder, course) | Study | Main session orchestrating the rest | below |
| Wants their own wiki, or to clear the sample | Reset | Main session + curator | below |
| A question about what they're learning | Query | Tutor | `tutor.md` |
| A pasted `QUIZ RESULTS` block | Quiz grading | Mentor | `mentor.md` |
| A video link, with or without its article | Video | Main session + curator | below |
| Asks to be quizzed, or what's due | Quiz / review | Mentor | `mentor.md` |
| Asks for a visual summary of a topic | Artifact | Main session + curator | below; `curator.md` |
| Asks to add one specific source from `raw/` | Ingest | Main session + archivist + curator | below; `archivist.md`, `curator.md` |
| Asks to check the wiki | Lint, then Curate | Auditor, curator | `auditor.md`, `curator.md` |
| Agrees to process flags, or approves a proposal | Curate (all, or one) | Curator | `curator.md` |

Query: pass the question as-is; a saved `wiki/qa/` page is written by the
curator. Quiz: the main session runs `open` on `learner/cards/<slug>.html`.
If operations, roles or flag states change, update `/wiki-help`.

### Study

One approval, at the plan; then run to the end, stopping only if something
blocks the whole topic.

1. Scope: archivist copies handed-over material to the root of `raw/` (URLs:
   ask the human to save them); `Explore` finds sources with no ingest commit
   and what the wiki covers. Nothing: name the source needed, stop.
2. Plan: sources (category, link-only?), pages, artifact, quiz size, gaps.
3. Build, per source: archivist files, records, commits; curator (plan mode)
   writes and commits the ingest; main session reviews.
4. Check: auditor `lint`, then curator on its flags; `needs-source` and
   `needs-review` are listed, not blocking.
5. Material: curator commits the artifact if planned; mentor builds the quiz;
   the main session opens the cards.
6. Report: pages, commits, gaps and the source to fill them, pending
   decisions, unforeseen items, remote images needing Obsidian.

### Ingest

`ingest <name>`, one source at a time.

1. Match `<name>` in `raw/`: several, ask; none, list sources with no ingest
   commit. In the root, ask the category (`article`, `paper`, `repo`); the
   archivist files it, lists it in `SOURCES.md` and commits.
2. Read it whole and its images (remote ones: ask for `Cmd+Shift+D` in
   Obsidian); after a move, check image links.
3. Summarize, list pages to touch, wait for approval; the curator gets the
   summary as plan; main session reviews the commit.

### Video

Goes with an article; not a source; only in `videos.md`; always from the
human, never searched. Find the article as in Ingest (none given: suggest up
to three). Title and channel from the human or YouTube oEmbed
(`youtube.com/oembed?url=<url>&format=json`, generic `User-Agent`), else ask;
never invent; duration only if given. Curator adds it and commits.

### Artifact

`artifact <topic>`: read `index.md` and the topic's pages (not covered: say
so, stop); state pages and sections, wait for approval; curator writes,
indexes and commits (rules in `curator.md`); main session reviews.

### Reset

Only on explicit request, never part of Study.

1. Run `.claude/scripts/reset-wiki.sh --dry-run`, show what goes (none:
   stop); ask `content_language`, `mixing`, `section_titles`,
   `flashcard_labels` and one confirmation in the same message.
2. Run the script (the only thing allowed to delete from `raw/`): it removes
   the paths in `sample-content.txt`, empties `index.md`, `videos.md`,
   `SOURCES.md`, refuses on a dirty `git status`, spares `learner/`, `flags/`,
   `wiki/qa/`.
3. Curator writes the config, checks dangling links, commits
   `docs(wiki): reset sample content`; main session reviews, reminds the
   human to check `LICENSE-content`.

## Privacy

- Never send the human's email to external services (`User-Agent`, `mailto=`,
  forms, searches) or write it in pages or commits; use a generic
  `User-Agent`; if one is required, stop and ask.
- Nothing from `learner/` or `wiki/qa/` leaves the machine (searches,
  commits, artifacts, flashcards, flags); never `git add -f` it.

## Commits

By the curator and archivist at the end of each task; the main session
reviews and never commits.

- `type(scope): description`: English, imperative, lowercase; unsigned (no
  `Co-Authored-By`, `Signed-off-by`, agent mentions); atomic (never mix
  operations, or schema with wiki content); no `git push` unless asked.
  `git status` first: only this task's files, warn about others.
- Schema changes (this file) are proposed, never edited alone; each accepted
  one is `docs(schema): …`.

| Case | Example |
|---|---|
| Source / Ingest | `docs(raw): add karpathy llm wiki gist` / `docs(wiki): ingest karpathy llm wiki gist` |
| Video / Artifact | `docs(videos): add suggested video for <article>` / `docs(artifacts): add visual summary for rag` |
| Flag fixed | `fix(wiki): resolve missing flag on embeddings` |
| Schema / README / config | `docs(schema): …` / `docs(readme): …` / `chore(config): …` |
| Reset | `docs(wiki): reset sample content` |
| Flag closed or parked, qa answer | No commit (private) |
