extends "res://tests/case.gd"
## Broken fixture: a helper the test calls hits a runtime error and returns its
## default, and the test itself still returns true.


func _lookup() -> int:
	var empty: Dictionary = {}
	return empty["missing"]


func test_helper_error() -> bool:
	_lookup()
	return true
