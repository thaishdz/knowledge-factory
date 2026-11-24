---
title: RAG
type: topic
tags: [rag, retrieval, vector-search]
sources:
  - raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md
created: 2026-11-24
updated: 2026-11-24
---

# RAG

RAG (Retrieval-Augmented Generation) splits documents into chunks, indexes them as embeddings and, on every query, retrieves the most similar chunks for the LLM to synthesize. It is the default starting point, and it is stateless unless engineered otherwise.

## Content

### Overview

![[rag.svg]]

- **Pipeline**: chunking and embeddings into a vector store at ingest time; retrieval of the top-K semantically similar chunks at query time, injected into the LLM's context.
- **Where the reasoning happens**: embeddings are generated at ingest time, but the heavy reasoning (synthesis, answer generation, multi-hop inference) happens at query time, on every call, with no memory of having done it before. See [[reasoning-placement]].
- **What it answers**: "What does the document say?"
- **Scale**: millions of documents.

### Where it works well
Large, changing corpora, single-turn factual queries, and enterprise search where breadth matters more than depth.

### Where it fails silently
- It is stateless by default: every query starts from zero, and synthesis quality drops as questions get harder.
- Chunking destroys document structure: relationships between entities, contradictions between sources and synthesized insights disappear when text is cut into 512-token pieces.
- The failure is invisible: retrieval metrics keep looking good.

### Production mitigations
Query rewriting, feedback loops, cached answers, hybrid search (BM25 + vector), re-ranking models and GraphRAG-style knowledge-graph layers. It can also be designed to write back: storing query–answer pairs, updating rankings with feedback, or feeding query patterns back into the index. Every step towards state takes deliberate work on top of the base pattern; in [[agent-memory]] and [[llm-wiki]], state is the point of the design.

**Best for**: retrieval over large volumes, knowledge bases that change often, enterprise Q&A, any corpus too large to precompile.

## Open questions

- The article doesn't quantify at what scale or question complexity synthesis starts to degrade.
- It doesn't explain how GraphRAG is implemented or how far it solves multi-hop questions.

## Related
- [[rag-vs-agent-memory-vs-llm-wiki]]
- [[reasoning-placement]]
- [[agent-memory]]
- [[llm-wiki]]

## Sources
- `raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md` (link-only, see `raw/SOURCES.md`)
