extends "res://tests/case.gd"
## Broken fixture: a test method that takes an argument the runner cannot pass.


func test_method_args(_value: int) -> bool:
	return true
