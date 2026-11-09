#!/bin/bash
# PostToolUse hook for Edit and Write: validate content as soon as a file under content/ changes.
#
# A PostToolUse hook runs after the edit has happened and cannot undo it. Exit 2 shows
# stderr to Claude, so the validator's errors arrive in the same turn as the edit.
# The validator is run from the checkout that holds the edited file, so an edit in a
# worktree is checked against that worktree's content, tools and schemas. The Python
# environment comes from $CLAUDE_PROJECT_DIR, because worktrees have no .venv of their own.
report() {
  echo "$1" >&2
  exit 2
}

command -v jq >/dev/null || report "validate-content.sh needs jq to read its input. Install it."

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path | strings' 2>/dev/null) ||
  report "validate-content.sh could not parse its input, so content was not validated."
cwd=$(printf '%s' "$input" | jq -r '.cwd | strings')

case "$file_path" in
  /*) ;;
  "") exit 0 ;; # A tool call without a file path edits no content.
  *) file_path=$cwd/$file_path ;;
esac

# The edit succeeded, so the directory exists and can be resolved directly.
dir=$(cd "$(dirname "$file_path")" 2>/dev/null && pwd -P) || exit 0
root=$dir
until [ -z "$root" ] || [ -e "$root/.git" ]; do
  root=${root%/*}
done
[ -n "$root" ] || exit 0 # Outside any checkout.

case "$dir/" in
  "$root"/content/*) ;;
  *) exit 0 ;;
esac

python=$CLAUDE_PROJECT_DIR/.venv/bin/python
[ -x "$python" ] || python=$root/.venv/bin/python
[ -x "$python" ] ||
  report "Content was not validated: no .venv. Run: /usr/bin/python3 -m venv .venv && .venv/bin/python -m pip install -r tools/requirements.txt"

"$python" "$root/tools/validate_content.py" --content-dir "$root/content" --agents-dir "$root/.claude/agents" 1>&2 || exit 2
