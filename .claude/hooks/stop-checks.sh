#!/bin/bash
# Stop hook: Claude may not stop while the headless tests or the content validator fail.
#
# Exit 2 blocks the stop and shows stderr to Claude as the reason to continue. The checks
# run in the checkout that holds the session's cwd, so a session working in a worktree
# is held to that worktree's state.
#
# stop_hook_active is true when Claude is already continuing because of a Stop hook. A
# failing test or invalid content still blocks then, because Claude can fix it. A missing
# tool cannot be fixed from inside the session, so it blocks once and then lets Claude stop,
# as the hooks reference advises for a condition that will never resolve. Claude Code ends
# any loop after eight consecutive blocks with no tool call in between
# (CLAUDE_CODE_STOP_HOOK_BLOCK_CAP raises it), so this hook is not a hard gate.
block() {
  echo "$1" >&2
  exit 2
}

# A problem with the environment rather than the work blocks only on the first attempt;
# after that the check it prevents is skipped and the others still run.
block_once() {
  [ "$active" = true ] || block "$1"
}

GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}

active=false
command -v jq >/dev/null || block "stop-checks.sh needs jq to read its input. Install it."

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd | strings' 2>/dev/null) ||
  block "stop-checks.sh could not parse its input, so the checks did not run."
active=$(printf '%s' "$input" | jq -r '.stop_hook_active == true')
[ -n "$cwd" ] || cwd=$CLAUDE_PROJECT_DIR

root=$(cd "$cwd" 2>/dev/null && pwd -P) || block "stop-checks.sh could not enter $cwd."
until [ -z "$root" ] || [ -e "$root/.git" ]; do
  root=${root%/*}
done
[ -n "$root" ] || exit 0 # Outside any checkout, there is nothing of this project to check.

failures=

if [ ! -x "$GODOT" ]; then
  block_once "Godot is not at $GODOT, so the tests did not run. Install Godot 4.7.2 or set GODOT."
else
  # The import step refreshes the class cache, without which a merged class such as Pcg32
  # does not resolve and every test fails to load. It takes about a second.
  "$GODOT" --headless --path "$root" --import >/dev/null 2>&1
  if ! tests=$("$GODOT" --headless --path "$root" --script res://tests/run.gd 2>&1); then
    failures="$failures
Headless tests failed:
$(printf '%s\n' "$tests" | grep -E '^FAIL|^ran=')"
  fi
fi

python=$CLAUDE_PROJECT_DIR/.venv/bin/python
[ -x "$python" ] || python=$root/.venv/bin/python
if [ ! -x "$python" ]; then
  block_once "Content was not validated: no .venv. Run: /usr/bin/python3 -m venv .venv && .venv/bin/python -m pip install -r tools/requirements.txt"
elif ! content=$("$python" "$root/tools/validate_content.py" --content-dir "$root/content" --agents-dir "$root/.claude/agents" 2>&1); then
  failures="$failures
$content"
fi

[ -z "$failures" ] || block "Do not stop yet; fix these first.$failures"
