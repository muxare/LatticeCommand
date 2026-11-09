extends "res://tests/case.gd"
## Broken fixture: a runtime error (a missing Dictionary key) ends the method
## before it returns true.


func test_runtime_error() -> bool:
	var empty: Dictionary = {}
	var missing: int = empty["missing"]
	check_eq(missing, 0, "unreachable")
	return true
