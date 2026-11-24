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
flags/          Gaps or errors found in the wiki
  open/ closed/ TEMPLATE.md
learner/        How the human learns. Private: only README.md is tracked
  trace/        L1: raw traces, one file per month (YYYY-MM.md)
  profile.md    L2: facts about how they learn, with evidence
  review.md     Leitner review queue
  quiz.md       Quiz waiting to be graded (only while one is open)
  cards/        HTML flashcards per quiz
.claude/
  agents/       librarian, auditor, curator, mentor
  hooks/        Write limits per subagent
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
question ─► librarian ─┐
                       ├─► flags/open/ ─► curator ─► wiki/ + commit ─► better answers
lint ─────► auditor ───┘                     └─► needs-source ─► the human adds a source

question ─► librarian ─► learner/trace/ ─┐
quiz / review ─► mentor ─────────────────┴─► learner/profile.md + review.md ─► better quizzes
```

### Roles

| | Librarian | Auditor | Curator | Mentor | Main session |
|---|---|---|---|---|---|
| Runs on | Any question | `lint` | `curate` | `quiz`, `review` | `ingest`, `video`, `artifact`, `promote` |
| Looks at | Pages needed to answer | The whole wiki | Flags and `raw/` | `wiki/`, `learner/` | Depends |
| Writes to | `flags/open/`, `learner/trace/` | `flags/open/` | `wiki/`, `index.md`, `log.md`, `flags/` | `learner/`, `flags/open/` | `raw/` (move only), `wiki/`, `artifacts/`, `index.md`, `log.md`, `videos.md`, framework files |
| Commits | No | No | Yes | No | Yes |

- The librarian finds problems in passing (mostly `missing`); the auditor
  reviews everything (mostly structure). The curator closes duplicates.
- The main session delegates to the right subagent and relays its report.
  Operations that need the human's approval halfway (ingest, video,
  artifact, promote) stay in the main session: a subagent can't ask while
  it works.
- Each subagent reads this file and `wiki.config.md` first. Hooks in
  `.claude/hooks/` enforce the "Writes to" row and block the curator from
  `raw/`. The auditor has `Bash` for `git log`, so for it the limit is
  partly an instruction.

### Where to look for what

1. `index.md` first: which pages exist and what they cover.
2. `wiki/`: what answers come from. `wiki/qa/` isn't in the index: use
   Glob/Grep.
3. `raw/`: source of truth. The librarian never answers from it (that's a
   `missing` flag); the curator uses it to fix the wiki.
4. `log.md`, `git log` and each page's `updated`: what changed and when.
5. `videos.md`: never a source for claims.

### Flags

One file per flag: `flags/open/YYYY-MM-DD-<type>-<slug>.md`, from
`flags/TEMPLATE.md`:

```markdown
---
type: missing          # missing | contradiction | stale | broken-link | orphan | structure
page: wiki/topics/example.md   # optional
raised_by: librarian   # librarian | auditor | mentor
raised: 2026-11-24
status: open           # open | needs-source | needs-review | closed
resolution: ""         # only when closing
---
Short description of the gap or problem.
```

- Types: `missing` (the wiki lacks something), `contradiction` (pages, or a
  page and its source, disagree), `stale` (superseded claim, or artifact
  older than its pages), `broken-link`, `orphan` (page without incoming
  links, or unembedded diagram), `structure` (index, log, frontmatter,
  `videos.md` or framework don't match).
- States: `open` (no commit until the curator processes it),
  `needs-source` (`raw/` doesn't cover it; the human must add a source),
  `needs-review` (proposed fix awaiting approval; always for
  `contradiction`), `closed` (moved to `flags/closed/` with a `resolution`).
- Whoever raises a flag doesn't fix it. Check `flags/open/` for duplicates
  first.
- Flags end up in git: they describe the wiki's gap and never quote the
  human's question, say what they asked, or name a `wiki/qa/` page.

### Learner store

`learner/` holds how the human learns, compiled like `raw/` → `wiki/`.

**Privacy.** Everything in it except `README.md` is in `.gitignore`: it
never goes into a commit, `log.md`, a wiki page, an artifact, a flag or an
external service. Never `git add -f` it.

**`trace/YYYY-MM.md`** (L1). Append-only. One entry per event:

```markdown
## 2026-11-24 · question · librarian
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
  least twice; if the human accepts, the main session writes it.
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

Commands are in English; the conversation follows `wiki.config.md`. If the
human types a command another way, run it and remind them of the English
form. `<name>` is part of a file name: the human never gives paths or
extensions.

| Command | Operation | Who |
|---|---|---|
| `ingest <name>` | Ingest | Main session |
| `video <url> for <name>` | Video (normal form) | Main session |
| `video <url>` | Video, suggesting an article | Main session |
| `artifact <topic>` | Artifact | Main session |
| *(a question)* | Query | Librarian |
| `lint` | Lint | Auditor |
| `curate` / `curate <name>` | Curate all open flags / one flag | Curator |
| `quiz <topic>` / `review` | Quiz on a topic / on what's due today | Mentor |
| *(paste `QUIZ RESULTS`)* | Quiz grading | Mentor |
| `promote` | Promote framework from staging (prod only) | Main session |

`/wiki-help` (`.claude/commands/wiki-help.md`) is a cheat sheet of this
table. If commands, roles or flag states change, update it too.

### Ingest

`ingest <name>`, one source at a time.

1. Find files in `raw/` (root and category folders, not `assets/`) whose
   name contains `<name>`, case-insensitive. One: say which. Several: ask.
   None: say so and list the sources without an ingest in `log.md`.
2. If it's in the root of `raw/`, ask its category (`article`, `paper`,
   `repo`), suggesting the likeliest, and move it. If it's already in a
   category folder, don't ask. Make sure `raw/SOURCES.md` lists it, with
   its license; if it can't be redistributed, mark it link-only (rule 8).
3. Read it whole, then any images in `raw/assets/` it references. If images
   are still remote URLs, ask the human to press `Cmd+Shift+D` in Obsidian
   ("Download attachments for current file"); you can't. After a move,
   check the image links still work.
4. Summarize the key points and the pages you'll create or touch. Wait for
   approval.
5. Read `index.md` and the related pages.
6. Create the new pages the source justifies; update affected pages (info,
   `sources`, `updated`); add cross-links both ways; update `index.md`.
7. Commit (source first, then pages), each commit with its `log.md` entry.

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
3. Add it under the article in `videos.md` and commit.

`video <url>`: get title and channel, suggest up to three articles (most
likely first, one line why each), wait for the choice, then step 3.

### Artifact

`artifact <topic>`. An HTML page that summarizes a topic visually, generated
from the wiki and regenerable at any time. Not a source or a wiki page.

1. Read `index.md` and the topic's pages. If the wiki doesn't cover it, say
   so and stop.
2. Say which pages you'll use and which sections it'll have. Wait for
   approval.
3. Write `artifacts/<topic-in-kebab-case>.html` (overwrite if it exists).
4. Add it to the "Artifacts" section of `index.md` and commit.

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

Done by the librarian; the main session passes the question as-is and
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
flag, any state). One flag = one fix = one commit = one `log.md` entry.

1. Read the flag, the affected page and related pages.
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
4. Closing: `status: closed`, one-line `resolution:`, move to `flags/closed/`.
5. Commit (type `curate`), including the flag in its new state.
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

`promote`, in a prod repo only, run by the main session.

1. Read `staging_repo` from `wiki.config.md` and `framework.txt` from it.
   Check staging has no uncommitted changes; note its `HEAD` short hash.
2. Show the human the diff between each listed file in staging and in prod
   (new, changed and removed files). If nothing differs, say so and stop.
3. Wait for approval. Then copy the files, keeping executable bits.
4. Commit `chore(config): promote framework from staging @<hash>` with its
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

## Commits

Made by the main session and the curator at the end of each operation; the
human reviews with `git show`.

- Conventional Commits, `type(scope): description`, English, imperative,
  lowercase.
- Unsigned: no `Co-Authored-By`, `Signed-off-by`, agent or model mentions,
  no GPG.
- Atomic: one logical change per commit; never mix operations, or schema
  with wiki content.
- No `git push` unless the human asks.
- Before committing, `git status`: include only what this operation
  touched, and warn about anyone else's changes. Uncommitted flags in
  `flags/open/` are normal and only go into the curator's commit for them.

| Case | Example |
|---|---|
| New source | `docs(raw): add karpathy llm wiki gist` |
| Ingest | `docs(wiki): ingest karpathy llm wiki gist` |
| Video | `docs(videos): add suggested video for karpathy llm wiki gist` |
| Artifact | `docs(artifacts): add visual summary for rag` |
| Flag fixed / closed / parked | `fix(wiki): resolve missing flag on embeddings`, `docs(flags): close duplicate flag on rag`, `docs(flags): park flag on langgraph as needs-source` |
| `AGENTS.md` / `README.md` | `docs(schema): …`, `docs(readme): …` |
| Config (`.claude/`, `.obsidian/`, `.gitignore`) | `chore(config): …` |
| Promote (prod) | `chore(config): promote framework from staging @abc1234` |
| Saved qa answer | No commit (private) |

## Changes to this schema

If a convention isn't working, propose the change; don't edit this file on
your own. In a prod repo, accepted changes are made in staging and promoted.
Each accepted change is logged with type `schema`.
