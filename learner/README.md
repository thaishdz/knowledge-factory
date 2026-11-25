# learner/

Your private learning profile, kept by the **mentor** agent. Everything in
this folder except this README is in `.gitignore`: it stays on your machine
and is never committed.

```
trace/YYYY-MM.md   L1: every question you ask and every quiz answer (append-only)
profile.md         L2: how you learn (Interests, Strengths, Struggles, Learns best with),
                   each fact citing its evidence in the trace
review.md          Leitner review queue: 1, 3, 7, 14 and 30 days
quiz.md            The quiz waiting to be graded, if any
cards/<slug>.html  Flashcards to practice in the browser
```

The files are created as you use `quiz <topic>`, `review` and ask the
consultant questions. Back this folder up yourself if you want to keep it.
See "Learner store" and "Quiz" in `AGENTS.md`.
