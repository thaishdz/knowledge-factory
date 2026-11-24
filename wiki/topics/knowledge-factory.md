---
title: Knowledge factory
type: topic
tags: [knowledge-management, agents, curation]
sources:
  - raw/articles/how-to-build-a-knowledge-factory.md
created: 2026-11-24
updated: 2026-11-24
---

# Knowledge factory

A system for collecting, curating and maintaining a company's knowledge so it can be passed to agents as context. [[harrison-chase]] argues that what's missing to make AI work for a company is not better models or just more context, but better knowledge: how the company works, its operating standards, and where data lives and how to access it.

## Content

### Context vs. knowledge
- **Context** is what an agent has available when doing a task.
- **Knowledge** is the reusable understanding maintained so the agent can do the task correctly: what a metric means, which source to trust, how a situation is handled. Sometimes written down, often not.
- A knowledge factory turns scattered documents and experience into knowledge that becomes context for future work. Knowledge is one kind of context, but shouldn't be the only one: data that is already stored reliably can be given to the agent directly.

### From software factory to knowledge factory
In a software factory, the best engineers build the systems that help everyone build software, and agents do the building. The post says general knowledge work is following the same path: agents can make presentations, launch videos or do outbound, but they need the tacit, implicit, scattered knowledge that efficient employees carry in their heads. That is where resources should go: into the knowledge, and above all into a factory that keeps it up to date.

### Three kinds of knowledge
- **Skills — how to do the work**: procedures, instructions and scripts for doing tasks the way the company expects. Often never written down, passed from coworker to coworker.
- **Domain knowledge — how the business works**: definitions, policies and facts about products, customers, competitors and the organization. It doesn't go stale often, and when written down it's usually incomplete or incorrect.
- **Data access guidance — where to get current information**: which sources to use, what data lives where and how to query it. If the source of truth is complete and up to date, there's no need to keep a copy; what needs maintaining is the guidance.

### Three pieces of the factory
- **Flags**: the best way to learn what's missing is to let agents flag it while they work — when they can't find information, or find information that's wrong. Give them a tool to report what's wrong and, optionally, suggest the correct update.
- **A curator agent**: knowledge shouldn't be kept up to date manually (too much work) nor only by the agents that use it. Those agents are good at flagging but are focused on their own goals; asking them to maintain knowledge makes it unruly and full of contradictions. A curator runs in the background on some cadence, with access to the raw sources (Notion, Slack, etc.), to agent traces (to see how people use agents and codify that into skills) and to the flags.
- **Storage**: in some ways the least important piece — skills in GitHub, a single file in Notion, OKF format in LangSmith Context Hub, a knowledge graph in Neo4j. In other ways the least explored: the industry has converged on skills for "procedural memory", but no standard exists yet for semantic memory (OKF is mentioned as a candidate). The advice is not to be too prescriptive about the format.

### End-to-end example: a revenue report
- Base context: raw revenue numbers in BigQuery and Salesforce.
- Knowledge: a skill for writing reports in the company's style (GitHub, skills format); long-lived knowledge such as how ARR is calculated (a company wiki); and skills on how to access the fast-changing data (Context Hub).
- The agent notices a renamed column in BigQuery, works out the right one on the fly and flags it, suggesting the new name. Afterwards, the finance lead corrects some formatting with the agent, including a new header for all documents.
- That night, the curator sees the flag, reads the agent's traces with the finance lead's corrections, and updates the skills: the new column for fetching data and the new header for drafting reports.

### Conclusion
The goal isn't to document everything before agents start working, but to build a system where doing the work reveals what's missing and closing those gaps improves future work. Start with one recurring workflow, see where agents struggle, and close the loop.

## Open questions

- The post doesn't say how the curator decides between conflicting sources or what it does when a flag is wrong.
- It doesn't define the OKF format or how it would represent semantic memory.
- It doesn't specify the curator's cadence or how its changes are reviewed by a human.
- *Inference, not from the source:* this repository applies the pattern to a personal [[llm-wiki]], with the wiki as domain knowledge and its schema as the skills.

## Related
- [[llm-wiki]]
- [[langchain]]
- [[harrison-chase]]
- [[rag-vs-agent-memory-vs-llm-wiki]]

## Sources
- `raw/articles/how-to-build-a-knowledge-factory.md` (link-only, see `raw/SOURCES.md`)
