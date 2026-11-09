extends "res://tests/case.gd"
## Broken fixture: the method ends without returning true.


func test_not_to_end() -> bool:
	check(true, "true holds")
	return false
