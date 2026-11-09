extends SceneTree
## Headless test runner (ADR-0019).
##
##   godot --headless --path . --import
##   godot --headless --path . --script res://tests/run.gd
##
## It runs every method named test_* in every tests/test_*.gd file directly
## under the test directory, in sorted order, each on a fresh instance. Pass
## "-- --dir=res://some/dir" to run another directory; tests/self_test.sh uses
## that to run the broken fixtures under tests/fixtures/.
##
## The exit code is 0 only when at least one test ran and every test returned
## true with no failed check. It is 1 for a failed check, a script that does not
## load, a test that did not run to its end (a runtime error ends the method and
## makes it return its default, false for "-> bool"), and a run of zero tests.

const DEFAULT_DIR: String = "res://tests"
const TEST_CASE_PATH: String = "res://tests/case.gd"


func _initialize() -> void:
	var dir: String = DEFAULT_DIR
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir = arg.trim_prefix("--dir=")
	quit(_run_dir(dir))


func _run_dir(dir: String) -> int:
	var ran: int = 0
	var failed: int = 0
	var files: PackedStringArray = _test_files(dir)
	for path: String in files:
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			printerr("FAIL %s: script did not load" % path)
			failed += 1
			continue
		if not _is_test_case(script):
			printerr("FAIL %s: does not extend %s" % [path, TEST_CASE_PATH])
			failed += 1
			continue
		for method: String in _test_methods(script):
			ran += 1
			var instance: Object = script.new()
			var result: Variant = instance.call(method)
			var failures: PackedStringArray = instance.get("failures")
			if typeof(result) != TYPE_BOOL or result != true:
				failures.append("did not run to its end (returned %s, not true)" % var_to_str(result))
			if failures.is_empty():
				print("ok   %s::%s" % [path.get_file(), method])
			else:
				failed += 1
				for failure: String in failures:
					printerr("FAIL %s::%s: %s" % [path.get_file(), method, failure])
	if ran == 0:
		printerr("FAIL no tests ran in %s" % dir)
		failed += 1
	print("ran=%d failed=%d" % [ran, failed])
	return 0 if failed == 0 else 1


func _test_files(dir: String) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var access: DirAccess = DirAccess.open(dir)
	if access == null:
		printerr("FAIL cannot open %s" % dir)
		return found
	for file: String in access.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			found.append(dir.path_join(file))
	found.sort()
	return found


func _test_methods(script: GDScript) -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for info: Dictionary in script.get_script_method_list():
		var method_name: String = info["name"]
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	names.sort()
	return names


func _is_test_case(script: Script) -> bool:
	var base: Script = script
	while base != null:
		if base.resource_path == TEST_CASE_PATH:
			return true
		base = base.get_base_script()
	return false
