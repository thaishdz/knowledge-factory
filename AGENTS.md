# AGENTS.md — Wiki schema

An LLM Wiki (Karpathy's pattern) run as a knowledge factory. The human
curates `raw/`, asks questions and reviews changes; the agents write
everything else, each in its own area. Read this whole file and
`wiki.config.md` before any operation.

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
  hooks/        Write limits per subagent; session-start flag report
  commands/     Slash commands for the human (/wiki-help, /promote)
wiki.config.md  Repo-specific settings (role, content language). Never synced
framework.txt   Staging only: the files that make up the framework
index.md        Catalog of every public wiki page
log.md          One entry per commit, append-only
videos.md       Suggested videos per article
CLAUDE.md       Only imports this file. No rules there
README.md       Onboarding for humans. Not part of the wiki
```

## General rules

1. Never modify or delete anything in `raw/`, except moving a source from
   its root to a category folder during an ingest, unchanged.
2. Every claim on a wiki page must trace back to a source in `raw/`. Mark
   your own inferences as such.
3. Don't make things up. If the sources don't cover something, say so in the
   page's open-questions section.
4. If a new source contradicts a page, don't overwrite silently: record the
   contradiction and which source says what.
5. `log.md` mirrors git: one entry per commit, nothing else.
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
  artifacts, flashcards): the `content_language` in `wiki.config.md`. Agents
  also talk to the human in that language. If `wiki.config.md` allows
  mixing, section titles and set phrases may stay in English when the
  English is correct and idiomatic.
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
| Runs on | Any question | `lint` | `curate`; approved plans (ingest pages, artifact, video, qa page, promote) | `quiz`, `review` | Sources entering or being filed in `raw/` | Every input from the human: it orchestrates |
| Looks at | Pages needed to answer | The whole wiki | Flags or the plan, and `raw/` | `wiki/`, `learner/` | The material and `raw/` | Agents' reports and their commits |
| Writes to | `flags/open/`, `learner/trace/` | `flags/open/` | `wiki/`, `artifacts/`, `index.md`, `log.md`, `videos.md`, `flags/`; framework files for `procedure` flags and promote | `learner/`, `flags/open/` | Copies and moves in `raw/`, `raw/SOURCES.md`, `log.md`, `.git/info/exclude` | `flags/open/` (procedure) only |
| Commits | No | No | Yes | No | Yes | No |

- The tutor answers the human's questions; the mentor quizzes them and
  tracks how they learn. Neither edits the wiki.
- The tutor finds problems in passing (mostly `missing`); the auditor
  reviews everything (mostly structure). The curator closes duplicates.
- The main session only orchestrates: it talks to the human, writes the
  plans they approve, hands each task to its agent, reviews what comes back
  (`git show` on each commit) and reports. It doesn't write pages, move
  sources or commit. If a commit is wrong, it sends the fix back to the
  agent that made it.
- Approvals stay with the main session, because a subagent can't ask while
  it works: it asks the human, then delegates. In Study the human only
  approves the plan.
- Each subagent reads this file and `wiki.config.md` first. Hooks in
  `.claude/hooks/` enforce the "Writes to" row, block the curator from
  `raw/` and stop the archivist from deleting, editing or overwriting
  sources. The auditor's and archivist's `Bash` checks are pattern-based,
  so for them the limit is partly an instruction.
- No agent runs in the background or on a schedule. Instead, a
  `SessionStart` hook (`session-flags.sh`) reports pending flags when a
  session starts; the main session tells the human at the start of its first
  reply and offers to process them; the curator only runs once they agree. In a prod repo it also
  reports pending `procedure` flags in staging.

### Models and delegation

The main session is the lead and runs on the session's model. It owns
quality, the conventions in this file and privacy, and only orchestrates:
plans, delegates, reviews every commit and reports. Reading, exploring and
mechanical filing go to Haiku; writing goes to Sonnet:

| Agent | Model | Does |
|---|---|---|
| `Explore` | Haiku | Read-only lookups for the main session: which pages, sources or files cover something. Returns paths and short findings |
| archivist | Haiku | Brings sources into `raw/`, files them, records them in `raw/SOURCES.md` and commits them, without changing their content |
| curator | Sonnet | Its flags, plus every approved plan that writes (ingest pages, artifact, video, saved qa page, promote): writes, runs the wiki checks and commits |
| tutor, auditor, mentor | Sonnet | Their roles above |

- `Explore` must keep that exact name: it replaces Claude Code's built-in
  `Explore`, which runs on the session's model.
- Models are set in each agent's `model:` frontmatter.
- The main session doesn't do what an agent can. It steps in only when an
  agent goes in circles or can't get past an obstacle, and says so to the
  human.

### Where to look for what

1. `index.md` first: which pages exist and what they cover.
2. `wiki/`: what answers come from. `wiki/qa/` isn't in the index: use
   Glob/Grep.
3. `raw/`: source of truth. The tutor never answers from it (that's a
   `missing` flag); the curator uses it to fix the wiki.
4. `log.md`, `git log` and each page's `updated`: what changed and when.
5. `videos.md`: never a source for claims.

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
  links, or unembedded diagram), `structure` (index, log, frontmatter,
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

**Procedure flags.** When the human corrects *how* something is done — a
convention, a step, a format, something to stop doing — the main session
raises a `procedure` flag (`raised_by: main`) right away, says so in one
line and carries on with the corrected behavior. The flag states the
procedure in general terms, never the conversation or personal details, and
puts the proposed rule change in `suggestion:`. When the human asks
directly for a framework change, the main session also raises a
`procedure` flag with the change in `suggestion:` and hands it to the
curator; the request counts as approval, so the curator applies and commits
it, unless it's ambiguous (then `needs-review`). Procedures belong to the
framework, so the flag goes where the framework is made: in a prod repo, in
`staging_repo`'s `flags/open/`; otherwise, in this repo. One-off preferences
that don't generalize aren't flagged.
- Flags are the factory's own working knowledge, not the wiki's: everything
  in `flags/open/` and `flags/closed/` is in `.gitignore` and never goes
  into a commit. Never `git add -f` them. Only `flags/TEMPLATE.md` (and the
  folders' `.gitkeep`) is tracked.
- Even so, a flag describes the wiki's gap and never quotes the human's
  question, says what they asked, or names a `wiki/qa/` page: its content
  feeds wiki fixes, commit messages and `log.md`.

### Learner store

`learner/` holds how the human learns, compiled like `raw/` → `wiki/`.

**Privacy.** Everything in it except `README.md` is in `.gitignore`: it
never goes into a commit, `log.md`, a wiki page, an artifact, a flag or an
external service. Never `git add -f` it.

**`trace/YYYY-MM.md`** (L1). Append-only. One entry per event:

```markdown
## 2026-11-24 · question · tutor
- q: "How is an LLM Wiki different from RAG?"
- pages: [[rag]], [[llm-wiki]]
- gap: missing (flags/open/2026-11-24-missing-example.md)

## 2026-11-24 · quiz · mentor
- concept: [[rag]]
- q: "When are the embeddings generated in RAG?"
- a: "at query time"
- result: wrong       # right | partial | wrong | skipped
- note: mixes up ingest time and query time
```

**`profile.md`** (L2). Facts under "Interests", "Strengths", "Struggles"
and "Learns best with". Each cites its trace entries (date and type); a fact
with one piece of evidence is marked as a hypothesis. Contradicted facts are
corrected and the change recorded.

**`review.md`**. One row per concept (wiki page):

```markdown
| Concept | Box | Next review | Last result |
|---|---|---|---|
| [[rag]] | 1 | 2026-11-25 | wrong |
```

Leitner intervals: box 1 → 1 day, 2 → 3, 3 → 7, 4 → 14, 5 → 30. `right`
moves up a box (max 5), `partial` stays, `wrong` goes back to box 1. This is
a convention of this wiki, not from any source.

**`quiz.md`**: the pending quiz's cards (id, type, question, expected
answer, page); deleted after grading. **`cards/<slug>.html`**: the
flashcards (see "Quiz").

### Private QA

`wiki/qa/` holds answers that combine several pages and aren't fully in any
one. Same page conventions (`type: qa`, sources from `raw/`, nothing made
up), but private because they reveal what the human asks:

- Only `README.md` is tracked: no commit, no `log.md` entry, not in
  `index.md`. Public pages don't link to them; they may link to public pages.
- The mentor proposes one when the trace shows the same question or gap at
  least twice; if the human accepts, the main session has the curator
  write it (no commit: it's private).
- If the answer needs something the wiki lacks, a `missing` flag comes first.
- Problems inside `wiki/qa/` are reported, not flagged; the main session
  fixes them if the human wants.

## Framework: staging and prod

The framework (schema, agents, hooks, commands) is shared by several repos.
Each repo says its `role` in `wiki.config.md`:

- **staging** (the public `knowledge-factory` repo): where framework changes
  are made and tested against its sample content. It holds `framework.txt`,
  the list of framework files.
- **prod** (a personal wiki): receives framework changes only through
  `promote`. Its `wiki.config.md` gives `staging_repo`, the path to staging.

Changes flow one way, staging → prod. In a prod repo, never edit a framework
file directly: make the change in staging (add it to the session's working
directories if needed), commit it there, then promote. Everything not listed
in `framework.txt` (wiki content, `raw/`, `index.md`, `log.md`,
`videos.md`, flags, `README.md`, `wiki.config.md`, licenses) belongs to each
repo and is never synced.

## Operations

The human never types commands and never calls an agent. They write in
plain words (a topic, some material, a question, a link, a yes) and the
main session works out the operation and orchestrates the agents. The
operation names below (`study`, `ingest`, `curate`…) are internal: they
name the procedures in this file and the agents' instructions. If the human
does type one, run it, with no reminder.

| What the human writes | Operation | Who |
|---|---|---|
| A topic to learn, or material (a file, a folder, a course) | Study | Main session orchestrating Explore, archivist, curator, auditor, mentor |
| A question about what they're learning | Query | Tutor |
| A pasted `QUIZ RESULTS` block | Quiz grading | Mentor |
| A video link, with or without the article it goes with | Video | Main session + curator |
| Asks to be quizzed, or what's due for review | Quiz / review | Mentor |
| Asks for a visual summary of a topic | Artifact | Main session + curator |
| Asks to add one specific source from `raw/` | Ingest | Main session + archivist + curator |
| Asks to check the wiki | Lint, then Curate on the new flags | Auditor, curator |
| Agrees to process pending flags, or approves a proposal in one | Curate (all, or that flag) | Curator |
| Asks to bring framework changes from staging (prod only) | Promote | Main session + curator |

- If the input fits more than one operation, ask one short question.
- `<name>` is part of a file name: the human never gives paths or
  extensions.
- Pending flags and reviews due today are offered in plain words ("there
  are 2 gaps I can fix, shall I?"), never as a command to type.

`/wiki-help` (`.claude/commands/wiki-help.md`) shows the human what they can
say and what's pending. If operations, roles or flag states change, update
it too.

### Study

The human writes "I want to learn RAG" or "here's a RAG course". One
approval, at the plan; after that the main session runs to the end without
asking, and only stops if something blocks the whole topic.

1. **Scope.** If the human hands over material (a file or folder), the
   archivist copies it unchanged into the root of `raw/`; a URL can't be saved as-is, so ask the
   human to save it in `raw/` (e.g. with Obsidian's web clipper). Then use
   `Explore` to find the sources in `raw/` on the topic, which of them have
   no ingest in `log.md`, and what `index.md` and `wiki/` already cover.
   If `raw/` has nothing on the topic and the wiki doesn't cover it, say
   which kind of source would be needed and stop.
2. **Plan (the only approval).** Show in a few lines: the sources to ingest
   (with the category for those in the root and whether each is link-only),
   the pages each one creates or updates, the artifact and its sections,
   the size of the quiz, and what the sources won't cover. Wait for the
   human's approval; changes to the plan are made now.
3. **Build.** For each source, in order: the archivist files it in its
   category, records it in `raw/SOURCES.md` and commits it; the curator
   (plan mode) writes its part of the plan and commits the ingest. The main
   session reviews each commit and sends fixes back. This replaces the questions and the approval of
   Ingest steps 1–4. Remote images that need Obsidian go to the final
   report; don't stop for them.
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
   None: say so and list the sources without an ingest in `log.md`.
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
6. Delegate to the curator, passing the approved summary as its plan:
   create the new pages the source justifies; update affected pages (info,
   `sources`, `updated`); add cross-links both ways; update `index.md`;
   run the checks and commit with the `log.md` entry.
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

`artifact <topic>`. An HTML page that summarizes a topic visually, generated
from the wiki and regenerable at any time. Not a source or a wiki page.

1. Read `index.md` and the topic's pages. If the wiki doesn't cover it, say
   so and stop.
2. Say which pages you'll use and which sections it'll have. Wait for
   approval.
3. Delegate to the curator with the approved pages and sections: it
   writes `artifacts/<topic-in-kebab-case>.html` (overwrite if it exists),
   adds it to the "Artifacts" section of `index.md` and commits.
4. Review the artifact against the rules below; send fixes back.

#### Artifact rules

- One file, CSS and JS inline. No CDNs, external fonts or requests, except
  embedded videos.
- Diagrams in inline SVG.
- Content only from wiki pages. Missing info goes into the wiki first.
- Videos: embed those `videos.md` lists for the articles in the used pages'
  `sources`, no others. YouTube via
  `<iframe src="https://www.youtube-nocookie.com/embed/<id>">` with the
  regular link below; other sites, link only.
- End with a list of the wiki pages used. No generation date or other
  timestamp: git keeps it.
- Same language conventions as pages.

#### Artifact visual style

Reference: https://thariqs.github.io/html-effectiveness/ (warm paper, serif
headlines, monospace details, one accent color). Follow these rules, not
its content or exact layout.

```css
:root {
  --ivory:  #FAF9F5;  /* page background */
  --paper:  #FFFFFF;  /* card background */
  --slate:  #141413;  /* main text */
  --clay:   #D97757;  /* accent: links, numbers, emphasis */
  --clay-d: #B85C3E;  /* dark accent */
  --oat:    #E3DACC;  /* soft fill */
  --olive:  #788C5D;  /* second color, diagrams and states only */
  --g100:   #F0EEE6;
  --g200:   #E6E3DA;
  --g300:   #D1CFC5;  /* borders */
  --g500:   #87867F;  /* secondary text */
  --g700:   #3D3D3A;  /* paragraph text */
  --serif: ui-serif, Georgia, "Times New Roman", Times, serif;
  --sans: system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  --mono: ui-monospace, "SF Mono", Menlo, Monaco, Consolas, monospace;
}
```

- Only these colors, via the variables. System fonts only.
- Type: serif headlines, weight 500, slightly negative tracking; sans body,
  line height 1.55; small mono for labels, counters, dates and file names.
- Header: small uppercase spaced mono label with a short clay dash; large
  serif title with the key word in clay italics; lede in `--g700`.
- Navigation: rounded bordered pills linking to sections, if several.
- Sections: mono clay number (01, 02…) next to the serif title.
- Cards: `--paper`, 1.5px `--g300` border, 14px radius, no shadow at rest;
  on hover they lift, gain a soft shadow and the border turns `--slate`.
- Layout: centered column up to 1120px, generous spacing, responsive card
  grid, good on mobile.
- SVG: 2.5px round-cap strokes in `--g500`; fills `--g300`, `--oat`,
  `--paper`; `--clay` only for emphasis.
- Embedded videos: inside a card, 16:9, rounded corners.
- No dark mode, loud gradients or emoji icons.

### Query

Done by the tutor; the main session passes the question as-is and
relays the answer.

1. Read `index.md` and the relevant pages (including `wiki/qa/`).
2. Answer citing the pages used. Never from memory or from `raw/`.
3. If the wiki lacks the answer, say so and raise a `missing` flag that
   describes the gap.
4. If something looks off (contradiction, broken link, outdated claim),
   raise the matching flag and warn that that part isn't reliable.
5. For a comparison with lasting value, suggest saving it in
   `wiki/comparisons/` (the main session does it, with a commit). For a
   broad topic, offer an artifact. `wiki/qa/` pages are the mentor's call.
6. Append the question, pages used and any flag to `learner/trace/`.
   Facts only; interpreting is the mentor's job.

### Lint

Done by the auditor, which fixes nothing: one flag per finding (no
duplicates), then a report grouped by type. It checks:

- Contradictions between pages; claims superseded by newer sources
- Orphan pages (except `wiki/qa/`); broken wikilinks; unembedded diagrams
- Concepts mentioned several times without a page
- Pages missing from `index.md` or index entries without a page
  (`wiki/qa/` is never indexed); public pages linking to `wiki/qa/`
- Pages without `sources`; sources missing from `raw/SOURCES.md`
- `log.md` out of sync with `git log`
- `videos.md` entries whose article no longer exists
- Artifacts whose pages have an `updated` later than the artifact's last
  commit (`git log -1 --format=%cs -- artifacts/<topic>.html`)
- Prod only: framework files that differ from staging (`promote` pending)

### Curate

Done by the curator: `curate` (every `open` flag) or `curate <name>` (one
flag, any state). One flag = one fix. A fix that changes tracked files is
one commit with one `log.md` entry; closing, parking or proposing without
changing tracked files makes no commit (flags are private).

1. Read the flag (including any `suggestion:`), the affected page and
   related pages.
2. If the problem is gone or duplicated, close it explaining why.
3. Look in `raw/` (read-only) for what's needed:
   - Covered: fix the wiki following the page conventions (pages, sources,
     `updated`, cross-links, `index.md`, diagrams) and close the flag.
   - Not covered: `status: needs-source`, explain what source is needed,
     invent nothing.
   - `contradiction`, or a fix that deletes or rewrites content: write the
     proposal in the flag, `status: needs-review`; apply it only after the
     human approves (`curate <name>`).
   - A framework mismatch in prod: don't fix it; tell the human to run
     `promote`.
   - `procedure` (staging only): write the concrete change (files and
     diff) in the flag and set `needs-review`. Once the human approves
     (`curate <name>`), apply it to the framework files, commit them, close
     the flag, and remind the human to `promote` into prod.
4. Closing: `status: closed`, one-line `resolution:`, move to `flags/closed/`.
5. If tracked files changed, commit them (type `curate`). The flag itself
   is never committed.
6. Report: closed flags, `needs-source` with the source needed,
   `needs-review` with the proposal.

### Quiz

Done by the mentor. A subagent can't converse and a local page can't write
to disk, so the loop closes by copy and paste:

```
quiz / review ─► mentor ─► learner/cards/<slug>.html ─► the human practices
learner/ updated ◄── mentor grades ◄── the human pastes "QUIZ RESULTS"
```

**Step 1: generate** (`quiz <topic>` or `review`).

1. Read `learner/profile.md` and `learner/review.md` (may not exist yet).
2. Pick concepts: for `quiz <topic>`, the wiki pages on it (including
   `wiki/qa/`; if none, say so and stop); for `review`, concepts due today or
   earlier (if none, say so).
3. Write 4–8 cards from those pages' text only, choosing formats by page and
   profile (focus on "Struggles", favor "Learns best with"):
   `flashcard` (front/back, self-graded), `cloze` (sentence with a gap,
   typed then self-graded), `explain` (own words, graded by the mentor),
   `compare` (X vs Y, self-graded).
4. Write `learner/cards/<slug>.html` (topic in kebab-case, or `review`) and
   the cards in `learner/quiz.md`. A new quiz replaces a pending one (warn).
5. Return the path; the main session runs `open learner/cards/<slug>.html`.

#### Flashcard HTML rules

Same as "Artifact rules" and "Artifact visual style", but in
`learner/cards/`, not indexed and without videos. Labels come from
`flashcard_labels` in `wiki.config.md`. Also:

- One card at a time with a counter (`3/6`). After revealing, the answer
  cites its page. Three self-grade buttons map to `right`, `partial` and
  `wrong`.
- The copy reminder appears only in a final step after the last card: the
  copy-results button plus a line saying to paste the results in the
  Claude Code chat, or the mentor learns nothing from the session. No fixed
  notice or bar. Keep a `beforeunload` warning if nothing was copied.
- Copy via clipboard; if it fails (e.g. on `file://`), show the text
  selected in a box.
- No profile data in the page. Exact copied format, keywords always in
  English (unanswered = `skipped`):

  ```
  QUIZ RESULTS · <slug> · YYYY-MM-DD
  1 | flashcard | [[rag]] | right
  2 | explain | [[rag]] | answer: "what the human wrote"
  3 | cloze | [[llm-wiki]] | partial | answer: "what they wrote"
  ```

**Step 2: grade** (the human pastes `QUIZ RESULTS`, or skips: all `skipped`).

1. Match against `learner/quiz.md`. Keep self-grades; grade `explain` (and
   `cloze` whose self-grade doesn't fit the answer) against the page:
   `right`, `partial` or `wrong`, briefly explained.
2. Append one trace entry per card; update `review.md` (a concept's worst
   card counts) and `profile.md` (only what the trace supports).
3. If a page caused the mistake (confusing, incomplete, contradictory), raise
   a flag about the page, never the human.
4. If the same question or gap appears at least twice, propose a `wiki/qa/`
   page.
5. Delete `learner/quiz.md` (the HTML stays) and report: grading, next
   review dates, one line on what changed in the profile.

### Promote

`promote`, in a prod repo only: the main session gets the approval, the
curator copies and commits.

1. Read `staging_repo` from `wiki.config.md` and `framework.txt` from it.
   Check staging has no uncommitted changes; note its `HEAD` short hash.
2. Show the human the diff between each listed file in staging and in prod
   (new, changed and removed files). If nothing differs, say so and stop.
3. Wait for approval. Then the curator copies the files, keeping
   executable bits, and commits.
4. The commit is `chore(config): promote framework from staging @<hash>` with its
   `log.md` entry (type `config`, `notes:` the staging commit subjects since
   the last promote).

## index.md format

Grouped by type, alphabetical, one line per page, descriptions in the
content language. `wiki/qa/` is never listed. Artifacts get their own
section with the path:

```markdown
## Topics
- [[vector-database]] — Database that indexes embeddings for similarity search

## Artifacts
- `artifacts/rag.html` — Visual summary of RAG
```

## videos.md format

One block per article, alphabetical by path, one line per video, duration
optional:

```markdown
## raw/articles/file-name.md
- [Video title](https://...) — channel, duration
```

## log.md format

The readable mirror of `git log`: each commit carries its own new entry,
whose title is the commit subject verbatim. Nothing else goes in (no
decisions or conversations; operations without commits write nothing).
Append-only; a revert is a new commit with its own entry.

```markdown
## [2026-11-13] ingest | docs(wiki): ingest karpathy llm wiki gist
- agent: agent name and model, e.g. curator (Claude Opus 5.5)
- files: wiki/topics/a.md, index.md       # without log.md; summarize if >10
- notes: optional, one line, max 200 characters
```

Types: `ingest`, `video`, `artifact`, `query`, `lint` (older entries only;
lint fixes use `curate`), `curate`, `schema`, `config`. Keep the
`## [date] type |` prefix exact for grep. In sync when these match:

```bash
git log --oneline | wc -l
grep -c "^## \[" log.md
```

Use `tail` or `grep` on `log.md`; don't read it whole.

## Privacy

- Never send the human's personal email to an external service (`User-Agent`,
  `mailto=`/`email=` parameters, forms, search text). Use a generic
  `User-Agent`. If a service requires an email, stop and ask.
- Never write their email in wiki pages, `log.md` or commit messages.
  Public repos commit with the GitHub `noreply` address.
- Nothing from `learner/` or `wiki/qa/` leaves the machine: not in
  searches, commits, artifacts or flags.
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
| Procedure flag applied (staging) | `docs(schema): resolve procedure flag on gitignore comments` |
| Promote (prod) | `chore(config): promote framework from staging @abc1234` |
| Saved qa answer | No commit (private) |

## Changes to this schema

If a convention isn't working, propose the change; don't edit this file on
your own. In a prod repo, accepted changes are made in staging and promoted.
Each accepted change is logged with type `schema`.
