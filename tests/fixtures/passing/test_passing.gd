extends "res://tests/case.gd"
## Control fixture: must exit 0 with ran=1, so the self-test proves the runner
## can pass and that an error the test declares with expect_error is accepted.


func test_passes() -> bool:
	check(true, "true holds")
	check_eq(2 + 2, 4, "integer sum")
	expect_error("declared fixture error")
	push_error("declared fixture error")
	return true
