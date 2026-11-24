---
title: Agent memory
type: topic
tags: [agent-memory, personalization, agents]
sources:
  - raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md
created: 2026-11-24
updated: 2026-11-24
---

# Agent memory

A system that gives continuity across sessions: it extracts facts from conversations (preferences, history, constraints), stores them outside the model and retrieves them when needed. It answers "What has this user told me?", not "What does the document say?".

## Content

### Overview

![[agent-memory.svg]]

Unlike [[rag]], it has two phases:

- **Write phase (during the conversation)**: the system extracts facts from what the user says and writes them to the memory store. Deciding what is worth storing, and how, is itself a reasoning operation.
- **Read phase (query time)**: the stored context is retrieved and injected alongside the query to personalize the answer.

Modern systems go further: they summarize memory across sessions, cluster related facts, derive preferences and build structured models of the user. The write phase gets more sophisticated as the system matures. See [[reasoning-placement]].

### Where it works well
Personalization, user-centric agents, support bots that must remember past interactions, and long agentic workflows where the same user comes back.

### Where it fails silently
- Memory is sparse and noisy: it only knows what the user has said explicitly.
- It knows the user but not the domain, unless combined with RAG or a structured knowledge layer. An agent that remembers you prefer Python but can't access your documentation is useless for technical support.
- Memory and domain knowledge are orthogonal problems, with separate solutions.

**Best for**: agents with returning users, personalization layers, session continuity in long tasks.

## Open questions

- The article doesn't name concrete memory implementations in its text. Its references cite Letta and Mem0, but they haven't been ingested.
- It doesn't explain how to keep the write phase from storing wrong facts.

## Related
- [[rag-vs-agent-memory-vs-llm-wiki]]
- [[reasoning-placement]]
- [[rag]]
- [[llm-wiki]]

## Sources
- `raw/articles/RAG vs. Agent Memory vs. LLM Wiki_ A Practical Comparison.md` (link-only, see `raw/SOURCES.md`)
