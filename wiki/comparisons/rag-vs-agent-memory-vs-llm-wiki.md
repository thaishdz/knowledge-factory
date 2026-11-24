---
title: RAG vs. Agent memory vs. LLM Wiki
type: comparison
tags: [rag, agent-memory, llm-wiki, architecture]
sources:
  - raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md
created: 2026-11-24
updated: 2026-11-24
---

# RAG vs. Agent memory vs. LLM Wiki

The three approaches don't compete on the same axis: they cover different dimensions of the knowledge problem (documents, the user, compiled domain knowledge). What sets them apart is where the heavy reasoning happens.

## Content

### Overview

![[rag-vs-agent-memory-vs-llm-wiki.svg]]

| | [[rag]] | [[agent-memory]] | [[llm-wiki]] |
| --- | --- | --- | --- |
| What it answers | "What does the document say?" | "What has this user told me?" | "What do I know about this topic?" |
| Reasoning at | Query time | Split: write and query | Ingest time |
| Persistence | None by default | Across sessions | Cumulative wiki |
| Infrastructure | Vector DB + embedding pipeline | Memory store + retrieval | Markdown files + index (often with retrieval) |
| Scale | Millions of documents | Per-user state | Bounded, curated sources |
| Blind spot | Synthesis degrades at scale | Knows the user, not the domain | Error amplification + continuous knowledge engineering |
| Write-back | Not by default | Central | Recommended, varies |

See [[reasoning-placement]] for the underlying axis.

### How they fit together
According to the article, production systems increasingly combine all three: RAG for the long tail over large corpora, memory for personalization and an LLM Wiki for compiled domain expertise. Underneath, governance (quality, freshness, access control) is what most teams underestimate: stale or ungoverned inputs degrade all three at once.

### Example: parental leave policy
Query: *"I just found out I'm pregnant. What do I need to do, and when?"*

- **RAG** retrieves the eligibility chunk and the application-deadline chunk. A fragmented, correct answer, with no sequence or view of the full timeline.
- **Agent memory** remembers that the user is in her second year and has already asked about benefits, and personalizes the opening. Without a document layer, the personalization wraps a hollow answer.
- **LLM Wiki** uses a precompiled page with eligibility, the 12-month window, the differences between primary and secondary caregiver and the process in the HR portal. It reads as if written by someone who understands the whole policy — but if ingest misread it, the error is in every answer and the user has no way of knowing.

### What most teams get wrong
Using RAG for everything because it's the lowest-friction option, and never questioning it. It fails silently when synthesis, continuity or depth are needed, because retrieval metrics still look fine.

### When to choose each (summary of the "Best for" sections)
- **RAG**: large volume, frequently changing knowledge, corpora too large to precompile.
- **Agent memory**: returning users, personalization, session continuity.
- **LLM Wiki**: research, personal knowledge bases, bounded domains where synthesis matters.

## Open questions

- The article provides no data or benchmarks: the comparisons are qualitative.
- The parental-leave example is illustrative, not an experiment.
- The article's references (Letta, MindStudio, Atlan, Mem0) haven't been ingested, so their view can't be checked.

## Related
- [[rag]]
- [[agent-memory]]
- [[llm-wiki]]
- [[reasoning-placement]]
- [[andrej-karpathy]]

## Sources
- `raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md` (link-only, see `raw/SOURCES.md`)
