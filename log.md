# Log

One entry per commit, append-only. See "log.md format" in `AGENTS.md`.

## [2026-11-24] schema | docs(schema): add knowledge factory schema
- agent: Claude (Opus 5.5)
- files: AGENTS.md, CLAUDE.md
- notes: schema shared by staging and prod; language and labels live in wiki.config.md

## [2026-11-24] config | chore(config): add agents, hooks and commands
- agent: Claude (Opus 5.5)
- files: 4 agents, 2 hooks, 2 commands, settings.json in .claude/

## [2026-11-24] config | chore(config): add repo skeleton and staging config
- agent: Claude (Opus 5.5)
- files: wiki.config.md, framework.txt, .gitignore, .obsidian/, flags/, learner/README.md, wiki/qa/README.md, index.md, videos.md, raw/SOURCES.md, empty folders

## [2026-11-24] config | docs(license): add mit and cc by-sa 4.0 licenses
- agent: Claude (Opus 5.5)
- files: LICENSE, LICENSE-content
- notes: MIT for the framework; CC BY-SA 4.0 for the sample content

## [2026-11-24] config | chore(config): ignore obsidian folder
- agent: Claude (Opus 5.5)
- files: .gitignore, .obsidian/ (untracked)
- notes: editor settings are personal; the folder stays on disk but leaves the repo

## [2026-11-24] schema | docs(schema): add link-only sources
- agent: Claude (Opus 5.5)
- files: AGENTS.md
- notes: sources that cannot be redistributed are listed in raw/SOURCES.md and kept out of git

## [2026-11-24] config | docs(license): switch content license to cc by 4.0
- agent: Claude (Opus 5.5)
- files: LICENSE-content
- notes: no share-alike source left; covers wiki/ and artifacts/, not third-party sources in raw/

## [2026-11-24] ingest | docs(raw): list rag vs agent memory vs llm wiki comparison as link-only
- agent: Claude (Opus 5.5)
- files: raw/SOURCES.md
- notes: the article text is not redistributable; it stays on disk, excluded from git

## [2026-11-24] ingest | docs(wiki): ingest rag vs agent memory vs llm wiki comparison
- agent: Claude (Opus 5.5)
- files: 6 pages in wiki/ (4 topics, 1 entity, 1 comparison), 4 diagrams in wiki/assets/, index.md
- notes: English translation of the pages built from this source in a private wiki; content unchanged

## [2026-11-24] config | chore(config): make agent prompts repo-agnostic
- agent: Claude (Opus 5.5)
- files: 4 agents in .claude/agents/, .claude/commands/wiki-help.md
- notes: prompts no longer name a specific wiki, so the framework fits any repo

## [2026-11-24] schema | docs(readme): add public readme with loop diagram and flashcard screenshot
- agent: Claude (Opus 5.5)
- files: README.md, docs/loop.svg, docs/flashcards.png

## [2026-11-24] ingest | docs(raw): list how to build a knowledge factory as link-only
- agent: Claude (Opus 5.5)
- files: raw/SOURCES.md
- notes: LangChain blog post by Harrison Chase; no open license, so the text stays on disk, excluded from git

## [2026-11-24] schema | docs(schema): report pending flags at session start instead of background curation
- agent: Claude (Opus 5.5)
- files: AGENTS.md
- notes: no agent runs on a schedule; the human decides when to curate

## [2026-11-24] config | chore(config): add session-start hook that reports pending flags
- agent: Claude (Opus 5.5)
- files: .claude/hooks/session-flags.sh, .claude/settings.json, framework.txt
- notes: read-only; prints a summary and asks the main session to mention it

## [2026-11-24] ingest | docs(wiki): ingest how to build a knowledge factory
- agent: Claude (Opus 5.5)
- files: wiki/topics/knowledge-factory.md, wiki/entities/harrison-chase.md, wiki/entities/langchain.md, wiki/topics/llm-wiki.md, index.md
- notes: 3 new pages; llm-wiki gains a related link

## [2026-11-24] schema | docs(readme): link the knowledge factory source and page
- agent: Claude (Opus 5.5)
- files: README.md

## [2026-11-24] schema | docs(schema): add optional suggestion to flags
- agent: Claude (Opus 5.5)
- files: AGENTS.md
- notes: whoever raises a flag may propose the fix; the curator treats it as a lead and still checks raw/

## [2026-11-24] config | chore(config): add suggestion to flag template and agents
- agent: Claude (Opus 5.5)
- files: flags/TEMPLATE.md, 4 agents in .claude/agents/

## [2026-11-24] schema | docs(schema): add procedure flags for the human's corrections
- agent: Claude (Opus 5.5)
- files: AGENTS.md
- notes: corrections on how agents work become flags in staging; the curator proposes the framework change and applies it once approved
