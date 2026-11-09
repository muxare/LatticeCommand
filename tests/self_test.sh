#!/bin/sh
# Runs tests/run.gd against the fixtures under tests/fixtures/ (ADR-0019) and
# fails unless "passing" exits 0 and every broken fixture exits non-zero.
# The runner only discovers tests/test_*.gd directly under tests/, so these
# fixtures never run in the normal suite.
#
# Usage, from the repository root, after "godot --headless --path . --import":
#   sh tests/self_test.sh
set -u
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
status=0

for fixture in passing failed_check runtime_error parse_error zero_tests not_to_end; do
	"$GODOT" --headless --path "$ROOT" --script res://tests/run.gd -- "--dir=res://tests/fixtures/$fixture" >/dev/null 2>&1
	code=$?
	if [ "$fixture" = passing ]; then
		expected="0"
		if [ "$code" -eq 0 ]; then verdict=ok; else verdict=FAIL; fi
	else
		expected="non-zero"
		if [ "$code" -ne 0 ]; then verdict=ok; else verdict=FAIL; fi
	fi
	[ "$verdict" = ok ] || status=1
	echo "$verdict $fixture: exit $code, expected $expected"
done

if [ "$status" -eq 0 ]; then echo "self-test passed"; else echo "self-test FAILED"; fi
exit "$status"
