extends "res://tests/case.gd"
## Broken fixture: the test declares an expected engine error that never comes.


func test_unmet_expectation() -> bool:
	expect_error("this error is never logged")
	return true
