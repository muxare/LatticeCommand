extends RefCounted
## Base class for every test script that tests/run.gd discovers (ADR-0019).
##
## A test is a method whose name starts with "test_" and that returns true as
## its last statement. GDScript has no exceptions, so a runtime error ends the
## method early and makes it return its default value (false for "-> bool",
## as observed on Godot 4.7.2); the runner counts anything other than true as a
## test that did not run to its end. A base class is used instead of
## class_name helpers so that test files depend only on res:// paths. Keep these helpers thin so that a
## later move to a framework stays a mechanical rewrite.

var failures: PackedStringArray = PackedStringArray()


## Records a failure unless the condition holds, and returns the condition.
func check(condition: bool, message: String = "") -> bool:
	if not condition:
		failures.append("check failed: %s" % message)
	return condition


## Records a failure unless got equals want by type and value, and returns
## whether they matched. The type is compared as well, because 1 == 1.0 holds
## in GDScript and the simulation must hold ints only (ADR-0020).
func check_eq(got: Variant, want: Variant, message: String = "") -> bool:
	var same: bool = typeof(got) == typeof(want) and got == want
	if not same:
		failures.append("check_eq failed: %s: got %s (%s), want %s (%s)" % [
			message, var_to_str(got), type_string(typeof(got)),
			var_to_str(want), type_string(typeof(want))])
	return same
