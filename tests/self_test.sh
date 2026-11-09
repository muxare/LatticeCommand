#!/bin/sh
# Runs tests/run.gd against the fixtures under tests/fixtures/ (ADR-0019).
# "passing" must exit 0 and report ran=1 failed=0. Every other fixture must
# exit non-zero and print its own failure reason, so that a renamed, emptied
# or accidentally fixed fixture cannot pass by failing for some other reason.
# The runner only discovers tests/test_*.gd directly under tests/, so these
# fixtures never run in the normal suite.
#
# Usage, from the repository root, after "godot --headless --path . --import":
#   sh tests/self_test.sh
set -u
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
status=0

# Each line: fixture directory|text the runner's output must contain.
CASES='passing|ran=1 failed=0
failed_check|check_eq failed: one equals two
runtime_error|engine error: Invalid access to property or key '"'"'missing'"'"'
helper_error|engine error: Invalid access to property or key '"'"'missing'"'"'
parse_error|script did not load
zero_tests|no tests ran
not_to_end|returned false, not true
non_bool_return|returned 1, not true
not_case|does not extend res://tests/case.gd
method_args|test method takes arguments
ctor_args|could not be instantiated
unmet_expectation|expected error was not logged: this error is never logged'

check_case() {
	fixture="$1"
	reason="$2"
	output="$("$GODOT" --headless --path "$ROOT" --script res://tests/run.gd -- "--dir=res://tests/fixtures/$fixture" 2>&1 </dev/null)"
	code=$?
	if [ "$fixture" = passing ]; then
		expected="exit 0"
		[ "$code" -eq 0 ] || verdict=FAIL
	else
		expected="non-zero exit"
		[ "$code" -ne 0 ] || verdict=FAIL
	fi
	case "$output" in
		*"$reason"*) ;;
		*) verdict=FAIL ;;
	esac
	echo "$verdict $fixture: exit $code, expected $expected and \"$reason\""
	if [ "$verdict" != ok ]; then
		status=1
		echo "$output" | sed 's/^/    | /'
	fi
}

while IFS='|' read -r fixture reason; do
	verdict=ok
	check_case "$fixture" "$reason"
done <<EOF
$CASES
EOF

if [ "$status" -eq 0 ]; then echo "self-test passed"; else echo "self-test FAILED"; fi
exit "$status"
