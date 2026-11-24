---
title: LLM Wiki
type: topic
tags: [llm-wiki, knowledge-base, markdown]
sources:
  - raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md
created: 2026-11-24
updated: 2026-11-24
---

# LLM Wiki

A pattern in which the LLM compiles the knowledge in the sources into a persistent set of linked markdown pages, and queries run against that compiled artifact instead of raw text. [[andrej-karpathy]] described it in a Gist; it is an idea, not a specification.

## Content

### Overview

![[llm-wiki.svg]]

- **Core idea**: instead of re-deriving knowledge on every query, the LLM writes and maintains the wiki layer. The sources stay immutable and the human reads.
- **Where the reasoning happens**: mostly at ingest time. See [[reasoning-placement]].
- **What it answers**: "What do I know about this topic?"
- **Scale**: bounded, curated sources.

### An idea, not a spec
The Gist calls itself an "idea file" and closes by saying it is intentionally abstract and that everything in it is optional and modular. According to the article, much of what gets discussed (formal ingest/lint/query operations, strict architectural boundaries, governance layers) comes from community implementations, not from the original idea.

### Implementation variants
- Plain markdown with a flat index file, no retrieval layer.
- Embeddings and hybrid search over the pages.
- Obsidian integration for navigation and graph views.
- MCP servers that give the agent direct access to the wiki.
- Formal or ad hoc linting.

For larger wikis, Karpathy suggests a local search engine with hybrid BM25/vector search. It doesn't replace retrieval: it is an alternative organizational layer that can sit next to [[rag]] or on top of it.

### What happens at each moment
- **Ingest**: the LLM reads the source, extracts what matters, writes or updates pages and cross-links them with existing content. This is the expensive, reasoning-heavy operation.
- **Query**: the LLM reads the index, finds pages and synthesizes. It is lighter than RAG's synthesis, but not free of reasoning.

### Compounding, and its risk
A wiki that has ingested 50 papers can answer in more depth than RAG over the same 50, because relationships, contradictions and synthesis are already compiled — but only if ingest quality is high. Unlike RAG, which rereads the source on every query, the wiki bakes in the LLM's interpretation: errors compound instead of staying isolated.

### The real limit: continuous knowledge engineering
- Keeping pages consistent and free of contradictions as new sources arrive.
- Avoiding schema drift as the domain evolves.
- Detecting silent degradation from LLM edits.
- Checking that ingest errors haven't spread through linked pages.

There is also a structural gap: the wiki knows the domain but not who is reading or why. The same page reads the same for a surgeon and for a patient. It is a great library without a librarian.

**Best for**: research compilation, personal knowledge bases, bounded domains, and cases where cross-source synthesis matters more than retrieval at scale.

## Open questions

- The article doesn't measure how much depth improves over RAG; the 50-papers comparison is presented as a possibility, without data.
- It doesn't propose a concrete method for detecting propagated ingest errors.
- The original Gist hasn't been ingested; what is known about it is what this article quotes.

## Related
- [[rag-vs-agent-memory-vs-llm-wiki]]
- [[reasoning-placement]]
- [[andrej-karpathy]]
- [[rag]]
- [[agent-memory]]

## Sources
- `raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md` (link-only, see `raw/SOURCES.md`)
