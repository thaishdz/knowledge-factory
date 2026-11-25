# Sourced by the hooks: local user preferences in .claude/user-prefs.json
# (gitignored, e.g. {"language":"es","onboarded":true}). Needs jq; never fails.
# Run from the project root.
PREFS=.claude/user-prefs.json

# prefs_get <key>: prints the value, or nothing (missing or invalid file = no preferences).
prefs_get() { jq -r --arg k "$1" '.[$k] // empty' "$PREFS" 2>/dev/null; }

# prefs_set <key> <json value>: merge into the file, keeping the other keys.
# A missing, invalid or non-object file is replaced. Written via a temp file and mv.
prefs_set() {
  local cur tmp
  cur=$(jq -c 'if type=="object" then . else {} end' "$PREFS" 2>/dev/null) || cur='{}'
  [ -n "$cur" ] || cur='{}'
  mkdir -p .claude 2>/dev/null
  tmp=$(mktemp .claude/.user-prefs.XXXXXX 2>/dev/null) || return 0
  if printf '%s' "$cur" | jq --arg k "$1" --argjson v "$2" '.[$k] = $v' > "$tmp" 2>/dev/null; then
    mv "$tmp" "$PREFS" 2>/dev/null
  else
    rm -f "$tmp" 2>/dev/null
  fi
  return 0
}

# prefs_migrate: fold the old marker files (.claude/.onboarded, .claude/.language) into the JSON and delete them.
prefs_migrate() {
  local l
  if [ -e .claude/.language ]; then
    l=$(tr -d '[:space:]' < .claude/.language 2>/dev/null)
    case "$l" in es|en) prefs_set language "\"$l\"" ;; esac
    rm -f .claude/.language 2>/dev/null
  fi
  if [ -e .claude/.onboarded ]; then
    prefs_set onboarded true
    rm -f .claude/.onboarded 2>/dev/null
  fi
  return 0
}
