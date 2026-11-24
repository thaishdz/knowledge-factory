---
title: Reasoning placement
type: topic
tags: [architecture, rag, llm-wiki, agent-memory]
sources:
  - raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md
created: 2026-11-24
updated: 2026-11-24
---

# Reasoning placement

The architectural question the article puts at the center: at what moment does the heavy reasoning happen (at ingest, when writing memory, or at query time), and what follows from that choice? According to the source, treating it as a technical detail is the most precise mistake teams make.

*Note: "reasoning placement" is this wiki's label; the article lays out the idea but doesn't name it.*

## Content

| | [[rag]] | [[agent-memory]] | [[llm-wiki]] |
| --- | --- | --- | --- |
| Reasoning concentrated at | Query time | Split: extraction on write, retrieval on query | Ingest time |
| Default state | Stateless (can be engineered otherwise) | Stateful by design | Stateful by design |
| Write-back | Not by default | Central to the pattern | Recommended design; implementations vary |

### Consequences, according to the article
Where reasoning happens determines, all at once, the maintenance load, the failure modes, the scale ceiling and the ability to personalize.

- **Query time ([[rag]])**: reasoning is repeated on every call, with no memory. Interpretation errors don't compound, because the source is reread.
- **Ingest time ([[llm-wiki]])**: synthesis is paid for once and queries reuse what was compiled. But errors get embedded and spread.
- **Split ([[agent-memory]])**: extraction during the conversation decides what gets stored; reading personalizes.

### Questions for deciding
The most capable teams, the article says, ask what kind of knowledge the system needs, how often it changes, who asks for it and how much engineering they can sustain. The answers determine the architecture, not the other way round.

## Open questions

- The article gives no quantitative criteria for choosing (rate of change, corpus size).
- It's unclear whether the wiki's "lighter" query-time reasoning is measurable against RAG; the text only says it is "generally" lighter.

## Related
- [[rag-vs-agent-memory-vs-llm-wiki]]
- [[rag]]
- [[agent-memory]]
- [[llm-wiki]]

## Sources
- `raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md` (link-only, see `raw/SOURCES.md`)
