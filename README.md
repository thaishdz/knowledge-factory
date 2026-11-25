# knowledge-factory

A personal wiki that maintains itself. Claude Code agents compile your
sources into linked markdown pages, flag what's missing instead of guessing,
fix the wiki from the sources, and quiz you on it with flashcards that adapt
to how you learn.

It combines Andrej Karpathy's
[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
pattern with the "knowledge factory" idea from Harrison Chase's post
[How to build a knowledge factory](https://www.langchain.com/blog/knowledge-factory)
(summarized in [`wiki/topics/knowledge-factory.md`](wiki/topics/knowledge-factory.md)):
the agents that **use** knowledge never **maintain** it.

![The knowledge loop and the learning loop](docs/loop.svg)

## Why

Most agent failures come from missing knowledge, not a bad model. A RAG
pipeline rereads your documents on every query and forgets; a wiki compiles
them once and keeps the synthesis. But a wiki rots unless something notices
the gaps and fixes them. Here, every gap becomes a **flag**, and one agent's
only job is to close flags using your sources.

## The agents

| | Tutor | Auditor | Curator | Mentor |
|---|---|---|---|---|
| Runs when | You ask a question | You run `lint` | You run `curate` | You run `quiz` or `review` |
| Looks at | The pages it needs | The whole wiki | Open flags and `raw/` | The wiki and your profile |
| Produces | An answer that cites pages, plus a flag if something's off | Only flags | Fixes, a commit, a log entry | Flashcards, grading, an updated profile |
| Edits the wiki | No | No | Yes | No |

Hooks in `.claude/hooks/` enforce these limits: the tutor, auditor and
mentor physically can't write outside their folders, and the curator can't
touch your sources. Every change is an unsigned Conventional Commit with a
matching entry in `log.md`.

Models are split by job: the main session leads (plans, reviews every
change, commits), `Explore` searches on Haiku, and the `implementer` and the
four agents above write on Sonnet. See "Models and delegation" in
`AGENTS.md`.

## Learning with the mentor

![A flashcard after revealing the answer](docs/flashcards.png)

1. `quiz rag` (or `review` for what's due today) builds 4–8 cards from the
   wiki pages only, and opens them in your browser.
2. You answer, reveal, and grade yourself.
3. At the end you copy the results and paste them in the chat.
4. The mentor grades your free-text answers, updates your profile
   (interests, strengths, struggles, how you learn best — each fact backed
   by evidence) and schedules the next review with Leitner boxes (1, 3, 7,
   14 and 30 days).

If a card trips you up because the page itself is unclear, the mentor
raises a flag about the page and the curator fixes it.

**Your learning data stays on your machine.** Everything in `learner/` and
`wiki/qa/` except their README is in `.gitignore`. Flags are private too:
they're the factory's own working notes, describe gaps in the wiki (never
your questions) and stay out of git.

## Quick start

**Requirements:** [Claude Code](https://docs.anthropic.com/en/docs/claude-code).
[Obsidian](https://obsidian.md) is optional but recommended for browsing the
wiki and its graph.

1. Click **Use this template** (or clone the repo).
2. Edit `wiki.config.md`: set `content_language`, the page section titles
   and the flashcard labels. Set `role: prod` and `staging_repo` if you also
   keep a copy of this repo as staging (see below).
3. Empty the sample content if you want a blank wiki: `wiki/`, `index.md`,
   `log.md`, `raw/SOURCES.md`.
4. Drop a source in `raw/` and run `claude` in the repo:

   ```
   ingest <part of the file name>
   ```

5. Ask questions, run `lint` now and then, `curate` to close flags, and
   `quiz <topic>` to practice. `/wiki-help` shows every command.

**Obsidian setup (optional):** open the folder as a vault, set *Settings →
Files and links → Default location for new attachments* to `raw/assets`, and
bind *Download attachments for current file* to a hotkey (e.g. `Cmd+Shift+D`)
so web clippings keep their images locally.

## Commands

| Command | What it does |
|---|---|
| *(a question)* | The tutor answers from the wiki and cites pages |
| `ingest <name>` | Adds a source from `raw/` to the wiki, after your approval |
| `video <url> for <name>` | Records a suggested video under an article |
| `artifact <topic>` | Builds a visual HTML summary of a topic |
| `lint` | The auditor checks the whole wiki and raises flags |
| `curate` / `curate <name>` | The curator processes all flags / one flag |
| `quiz <topic>` / `review` | Flashcards on a topic / what's due today |
| *(paste `QUIZ RESULTS`)* | The mentor grades the quiz |
| `promote` | In a prod repo: pulls framework changes from staging |

## Staging and prod

Use this repo as **staging** for the framework and keep your real wiki as
**prod**. Framework changes (schema, agents, hooks, commands — listed in
`framework.txt`) are made and tested here against the sample content, then
`promote` copies them into prod after showing you the diff. Changes flow one
way only, so your wiki never gets a half-finished rule.

## Structure

```
raw/          Sources (articles/ papers/ repos/ assets/) + SOURCES.md
wiki/         entities/ topics/ comparisons/ timelines/ qa/ (private) assets/
artifacts/    Visual HTML summaries
flags/        open/ closed/ (private) TEMPLATE.md
learner/      Your learning profile (private)
.claude/      agents/ hooks/ commands/
AGENTS.md     The schema every agent follows
wiki.config.md  Settings for this repo (language, role)
framework.txt   Files shared between staging and prod
index.md · log.md · videos.md
```

## Sample content

The wiki ships with nine pages and four diagrams compiled from two articles:

- [RAG vs. Agent Memory vs. LLM Wiki: A Practical Comparison](https://dev.to/vishalmysore/rag-vs-agent-memory-vs-llm-wiki-a-practical-comparison-1oo6) by vishalmysore
- [How to build a knowledge factory](https://www.langchain.com/blog/knowledge-factory) by Harrison Chase

The articles themselves aren't included, because their licenses don't allow
redistribution: they're listed as **link-only** sources in `raw/SOURCES.md`.
Download them into `raw/articles/` if you want the agents to work with them.

## License

- Framework (schema, agents, hooks, commands, docs): [MIT](LICENSE).
- Sample wiki content (`wiki/`, `artifacts/`, `docs/`): [CC BY 4.0](LICENSE-content).
- Sources in `raw/` keep their own licenses, listed in `raw/SOURCES.md`.

Artifact visual style inspired by
[html-effectiveness](https://thariqs.github.io/html-effectiveness/).
