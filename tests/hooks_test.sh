#!/bin/sh
# Pipes sample hook input into the PostToolUse and Stop hooks in .claude/hooks/
# and checks their exit codes and messages. Each case runs against a scratch
# copy of the repository, so a broken fact sheet or a failing test can be
# planted without touching the checkout.
#
# Usage, from the repository root, after the import step and the .venv setup:
#   sh tests/hooks_test.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$ROOT/.claude/hooks"
status=0
scratch=$(mktemp -d) || exit 1
trap 'rm -rf "$scratch"' EXIT

# A copy of the checkout with its own .git marker, so the hooks find its root.
# .venv stays in the original and is reached through CLAUDE_PROJECT_DIR, and the
# Stop hook's import step builds each copy's .godot.
make_copy() {
  copy="$scratch/$1"
  mkdir -p "$copy"
  (cd "$ROOT" && git ls-files -z -co --exclude-standard | tar --null -T - -cf -) | (cd "$copy" && tar -xf -)
  mkdir "$copy/.git"
  printf '%s\n' "$copy"
}

# run_case NAME HOOK INPUT EXPECTED_EXIT EXPECTED_TEXT
run_case() {
  out=$(printf '%s' "$3" | GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}" CLAUDE_PROJECT_DIR="$ROOT" bash "$HOOKS/$2" 2>&1)
  code=$?
  if [ "$code" -ne "$4" ]; then
    echo "FAIL $1: exit $code, expected $4"
    printf '%s\n' "$out" | sed 's/^/     /' | tail -5
    status=1
    return
  fi
  case "$out" in
    *"$5"*) echo "ok   $1" ;;
    *)
      echo "FAIL $1: output lacks '$5'"
      printf '%s\n' "$out" | sed 's/^/     /' | tail -5
      status=1
      ;;
  esac
}

post_input() { # FILE_PATH CWD
  printf '{"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"%s"},"cwd":"%s"}' "$1" "$2"
}
stop_input() { # CWD STOP_HOOK_ACTIVE
  printf '{"hook_event_name":"Stop","stop_hook_active":%s,"cwd":"%s"}' "$2" "$1"
}

good=$(make_copy good)
bad=$(make_copy bad)
printf '[{"id":"broken"}]\n' >"$bad/content/facts.json"
failing=$(make_copy failing)
cat >"$failing/tests/test_planted.gd" <<'EOF'
extends "res://tests/case.gd"


func test_planted_failure() -> bool:
	check_eq(1, 2, "planted failure")
	return true
EOF

# PostToolUse: only files under content/ run the validator.
run_case "post: edit outside content/ passes silently" validate-content.sh \
  "$(post_input "$bad/docs/next.md" "$bad")" 0 ""
run_case "post: valid content passes" validate-content.sh \
  "$(post_input "$good/content/facts.json" "$good")" 0 ""
run_case "post: invalid content reports to Claude with exit 2" validate-content.sh \
  "$(post_input "$bad/content/facts.json" "$bad")" 2 "content validation failed"
run_case "post: relative path is resolved against cwd" validate-content.sh \
  "$(post_input "content/facts.json" "$bad")" 2 "content validation failed"
run_case "post: worktree content is validated in the worktree" validate-content.sh \
  "$(post_input "$bad/content/facts.json" "$good")" 2 "content validation failed"
run_case "post: unparsable input is reported" validate-content.sh \
  "not json" 2 "could not parse"

# Stop: tests and validator run in the checkout that holds cwd.
run_case "stop: passing checkout may stop" stop-checks.sh \
  "$(stop_input "$good" false)" 0 ""
run_case "stop: invalid content blocks" stop-checks.sh \
  "$(stop_input "$bad" false)" 2 "content validation failed"
run_case "stop: failing test blocks" stop-checks.sh \
  "$(stop_input "$failing" false)" 2 "planted failure"
run_case "stop: still blocks when already continuing" stop-checks.sh \
  "$(stop_input "$failing" true)" 2 "planted failure"
run_case "stop: unparsable input blocks" stop-checks.sh \
  "not json" 2 "could not parse"

# A missing tool blocks once, then lets Claude stop.
GODOT=/nonexistent/Godot run_case "stop: missing Godot blocks the first attempt" stop-checks.sh \
  "$(stop_input "$good" false)" 2 "Godot is not at"
GODOT=/nonexistent/Godot run_case "stop: missing Godot lets a continuing Claude stop" stop-checks.sh \
  "$(stop_input "$good" true)" 0 ""
GODOT=/nonexistent/Godot run_case "stop: missing Godot still validates content" stop-checks.sh \
  "$(stop_input "$bad" true)" 2 "content validation failed"

exit $status
