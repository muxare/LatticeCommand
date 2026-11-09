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
## The exit code fails closed: it is 1 unless the run reaches the end of
## _run_dir with at least one test run and nothing failed. A test fails on a
## failed check, a return value other than true, a method that takes arguments,
## an instance that cannot be built, and any engine error logged while it runs,
## including script errors, failed asserts and push_error in code it calls.
## GDScript has no exceptions, so a runtime error only ends the function it
## happens in and returns that function's default; the engine Logger hook below
## is what makes an error in a callee visible. A test that means to provoke an
## error declares it first with expect_error() in case.gd. Engine errors logged
## outside any test, such as while a script loads, fail the run too.

const DEFAULT_DIR: String = "res://tests"
const TEST_CASE_PATH: String = "res://tests/case.gd"


## Records every engine error (not warnings) logged while the runner is active.
class ErrorLog extends Logger:
	var entries: PackedStringArray = PackedStringArray()
	var _mutex: Mutex = Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String,
			rationale: String, _editor_notify: bool, error_type: int,
			_script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var text: String = code if rationale.is_empty() else "%s: %s" % [code, rationale]
		_mutex.lock()
		entries.append("%s (%s:%d in %s)" % [text, file, line, function])
		_mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

	func take() -> PackedStringArray:
		_mutex.lock()
		var taken: PackedStringArray = entries
		entries = PackedStringArray()
		_mutex.unlock()
		return taken


var _errors: ErrorLog = ErrorLog.new()


func _initialize() -> void:
	var exit_code: int = 1
	var dir: String = DEFAULT_DIR
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir = arg.trim_prefix("--dir=")
	OS.add_logger(_errors)
	if _run_dir(dir) == true:
		exit_code = 0
	OS.remove_logger(_errors)
	quit(exit_code)


func _run_dir(dir: String) -> bool:
	var ran: int = 0
	var failed: int = 0
	for path: String in _test_files(dir):
		var script: GDScript = load(path) as GDScript
		failed += _report_stray_errors("loading %s" % path)
		if script == null or not script.can_instantiate():
			printerr("FAIL %s: script did not load" % path)
			failed += 1
			continue
		if not _is_test_case(script):
			printerr("FAIL %s: does not extend %s" % [path, TEST_CASE_PATH])
			failed += 1
			continue
		var methods: Dictionary = _test_methods(script)
		var names: Array = methods.keys()
		names.sort()
		for method: String in names:
			ran += 1
			var failures: Array[String] = []
			# _run_test returns true only from its last line; a runtime error in
			# the runner itself returns the default false.
			if _run_test(script, method, methods[method], failures) != true:
				failures.append("the runner did not finish this test")
			if failures.is_empty():
				print("ok   %s::%s" % [path.get_file(), method])
			else:
				failed += 1
				for failure: String in failures:
					printerr("FAIL %s::%s: %s" % [path.get_file(), method, failure])
	failed += _report_stray_errors("the runner")
	if ran == 0:
		printerr("FAIL no tests ran in %s" % dir)
		failed += 1
	print("ran=%d failed=%d" % [ran, failed])
	if ran > 0 and failed == 0:
		return true
	return false


## Runs one test, appends its failures, and returns true when it got to the end.
func _run_test(script: GDScript, method: String, arg_count: int, failures: Array[String]) -> bool:
	if arg_count != 0:
		failures.append("test method takes arguments (%d)" % arg_count)
		return true
	# Calling new() on a script whose _init needs arguments is a runtime error
	# in this function, so it is checked first; the null check covers the rest.
	if _init_needs_arguments(script):
		failures.append("could not be instantiated (_init takes arguments)")
		return true
	var instance: Object = script.new()
	if instance == null:
		failures.append("could not be instantiated")
		for error: String in _errors.take():
			failures.append("engine error: %s" % error)
		return true
	var result: Variant = instance.call(method)
	var logged: PackedStringArray = _errors.take()
	failures.append_array(Array(instance.get("failures")))
	if typeof(result) != TYPE_BOOL or result != true:
		failures.append("did not run to its end (returned %s, not true)" % var_to_str(result))
	var expected: PackedStringArray = instance.get("expected_errors")
	for error: String in logged:
		var matched: int = -1
		for i: int in expected.size():
			if error.contains(expected[i]):
				matched = i
				break
		if matched == -1:
			failures.append("engine error: %s" % error)
		else:
			expected.remove_at(matched)
	for text: String in expected:
		failures.append("expected error was not logged: %s" % text)
	return true


func _init_needs_arguments(script: GDScript) -> bool:
	for info: Dictionary in script.get_script_method_list():
		if info["name"] == "_init":
			var args: Array = info["args"]
			var defaults: Array = info["default_args"]
			if args.size() > defaults.size():
				return true
	return false


## Reports engine errors logged outside any test and returns how many failures
## that adds to the run (0 or 1).
func _report_stray_errors(context: String) -> int:
	var stray: PackedStringArray = _errors.take()
	for error: String in stray:
		printerr("FAIL engine error while %s: %s" % [context, error])
	return 0 if stray.is_empty() else 1


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


## Returns each test_ method name mapped to its argument count.
func _test_methods(script: GDScript) -> Dictionary:
	var methods: Dictionary = {}
	for info: Dictionary in script.get_script_method_list():
		var method_name: String = info["name"]
		if method_name.begins_with("test_") and not methods.has(method_name):
			var args: Array = info["args"]
			methods[method_name] = args.size()
	return methods


func _is_test_case(script: Script) -> bool:
	var base: Script = script
	while base != null:
		if base.resource_path == TEST_CASE_PATH:
			return true
		base = base.get_base_script()
	return false
