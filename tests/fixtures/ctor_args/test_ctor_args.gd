extends "res://tests/case.gd"
## Broken fixture: _init takes an argument, so script.new() cannot build it.


func _init(_required: int) -> void:
	pass


func test_never_reached() -> bool:
	return true
