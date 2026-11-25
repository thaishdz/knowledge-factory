#!/bin/bash
# Reset operation: removes the template's sample content.
# Run by the main session only, after the human confirms.
# Usage: reset-wiki.sh [--dry-run]
set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"

manifest=.claude/scripts/sample-content.txt
dry=0
[ "${1:-}" = "--dry-run" ] && dry=1

# Manifest paths that still exist on disk or in git (link-only sources may
# be absent from git but present on disk, or the other way round).
files=()
while IFS= read -r f; do
  case "$f" in ''|'#'*) continue ;; esac
  if [ -e "$f" ] || git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    files+=("$f")
  fi
done < "$manifest"

if [ ${#files[@]} -eq 0 ]; then
  echo "No sample content left."
  exit 0
fi

printf '%s\n' "${files[@]}"
echo "${#files[@]} file(s)."
[ $dry -eq 1 ] && exit 0

if [ -n "$(git status --porcelain)" ]; then
  echo "git status is not clean: commit or stash first." >&2
  exit 1
fi

exclude=.git/info/exclude
for f in "${files[@]}"; do
  git rm -q --ignore-unmatch -- "$f"
  rm -f -- "$f"
  if [ -f "$exclude" ]; then
    grep -vxF -- "$f" "$exclude" > "$exclude.tmp" || true
    mv "$exclude.tmp" "$exclude"
  fi
done

for d in wiki/entities wiki/topics wiki/comparisons wiki/timelines wiki/assets \
         artifacts raw/articles raw/papers raw/repos raw/assets; do
  mkdir -p "$d"
  touch "$d/.gitkeep"
done

cat > index.md <<'EOT'
# Index

Catalog of the wiki's public pages. Maintained by the agents (see `AGENTS.md`).

## Entities

## Topics

## Comparisons

## Timelines

## QA
Private: pages in `wiki/qa/` are not listed here and never committed.

## Artifacts
EOT

cat > videos.md <<'EOT'
# Videos

Suggested videos for the articles in `raw/articles/`. Not sources. Maintained by the agents (see `AGENTS.md`).
EOT

cat > raw/SOURCES.md <<'EOT'
# Sources

Every source in `raw/`, with its origin and license. Sources are added by the
human; the agents only move them into their category folder during ingest.

| File | Title | Author | URL | License |
|---|---|---|---|---|
EOT

git add -A
echo "Sample content removed and staged. Next: the curator writes wiki.config.md and commits."
