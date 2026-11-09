extends "res://tests/case.gd"
## Broken fixture: a check fails but the method still returns true.


func test_failed_check() -> bool:
	check_eq(1, 2, "one equals two")
	return true
