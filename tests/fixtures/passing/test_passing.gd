extends "res://tests/case.gd"
## Control fixture: must exit 0, so the self-test proves the runner can pass.


func test_passes() -> bool:
	check(true, "true holds")
	check_eq(2 + 2, 4, "integer sum")
	return true
