extends "res://tests/case.gd"
## Broken fixture: the method returns 1, which is truthy but not true.


func test_non_bool_return() -> int:
	return 1
