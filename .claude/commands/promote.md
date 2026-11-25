---
description: Promote framework changes from the staging repo into this prod repo
---

Run the "Promote" operation from `AGENTS.md`:

1. Read `wiki.config.md`. If `role` is not `prod`, stop and say that
   `promote` only runs in a prod repo.
2. Read `framework.txt` from `staging_repo`. Check that staging has no
   uncommitted changes (`git -C <staging_repo> status --porcelain`) and note
   its `HEAD` short hash.
3. For every listed path, compare staging and this repo (new, changed and
   removed files) and show the human a short summary plus the diff.
4. If nothing differs, say so and stop. Otherwise wait for approval.
5. Hand the copy to the curator: it copies the files, keeping executable
   bits, and commits
   `chore(config): promote framework from staging @<hash>` with its
   `log.md` entry (type `config`, `notes:` the staging commit subjects since
   the last promote). Review its commit and report.
