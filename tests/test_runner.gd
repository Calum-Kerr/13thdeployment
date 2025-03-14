extends Node
class_name TestRunner

"""
TestRunner: Automated test framework for the Soulsborne Web Game.
Runs all test scripts and reports results.
"""

# Signal emitted when all tests are complete
signal tests_completed(success_count: int, failure_count: int, skipped_count: int)

# Test result tracking
var _success_count: int = 0
var _failure_count: int = 0
var _skipped_count: int = 0
var _current_test_name: String = ""
var _current_test_script: Object = null
var _test_scripts: Array = []

# Constants
const TEST_SCRIPT_DIR = "res://tests/unit/"
const TEST_SCRIPT_SUFFIX = "_test.gd"
const LOG_PREFIX = "[TestRunner] "

func _ready() -> void:
	"""Initialize the test runner."""
	print(LOG_PREFIX + "Test runner initialized")

func run_all_tests() -> void:
	"""Run all test scripts in the test directory."""
	print(LOG_PREFIX + "Starting test run...")
	
	# Reset counters
	_success_count = 0
	_failure_count = 0
	_skipped_count = 0
	
	# Find all test scripts
	_find_test_scripts()
	
	# Run each test script
	for script_path in _test_scripts:
		_run_test_script(script_path)
	
	# Report results
	_report_results()
	
	# Emit completion signal
	emit_signal("tests_completed", _success_count, _failure_count, _skipped_count)

func _find_test_scripts() -> void:
	"""Find all test scripts in the test directory."""
	var dir = DirAccess.open(TEST_SCRIPT_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(TEST_SCRIPT_SUFFIX):
				_test_scripts.append(TEST_SCRIPT_DIR + file_name)
			file_name = dir.get_next()
	else:
		push_error(LOG_PREFIX + "Error: Could not open test directory: " + TEST_SCRIPT_DIR)

func _run_test_script(script_path: String) -> void:
	"""Run a single test script."""
	print(LOG_PREFIX + "Running test script: " + script_path)
	
	# Load the script
	var script = load(script_path)
	if not script:
		push_error(LOG_PREFIX + "Error: Could not load test script: " + script_path)
		return
	
	# Create an instance of the script
	var test_instance = script.new()
	if not test_instance:
		push_error(LOG_PREFIX + "Error: Could not create instance of test script: " + script_path)
		return
	
	# Store current test script
	_current_test_script = test_instance
	
	# Run setup if available
	if test_instance.has_method("setup"):
		test_instance.setup()
	
	# Find and run all test methods
	for method in test_instance.get_method_list():
		var method_name = method["name"]
		if method_name.begins_with("test_"):
			_current_test_name = method_name
			print(LOG_PREFIX + "  Running test: " + method_name)
			
			# Check if test is marked as skipped
			if test_instance.has_method("is_skipped") and test_instance.is_skipped(method_name):
				print(LOG_PREFIX + "    SKIPPED")
				_skipped_count += 1
				continue
			
			# Run the test
			var success = true
			if test_instance.has_method("before_each"):
				test_instance.before_each()
			
			if test_instance.has_method(method_name):
				try:
					test_instance.call(method_name)
				catch(error):
					print(LOG_PREFIX + "    FAILED: " + error["source"] + " at line " + str(error["line"]))
					success = false
			
			if test_instance.has_method("after_each"):
				test_instance.after_each()
			
			# Record result
			if success:
				print(LOG_PREFIX + "    PASSED")
				_success_count += 1
			else:
				_failure_count += 1
	
	# Run teardown if available
	if test_instance.has_method("teardown"):
		test_instance.teardown()
	
	# Clean up
	test_instance.free()
	_current_test_script = null
	_current_test_name = ""

func _report_results() -> void:
	"""Report the results of all tests."""
	var total = _success_count + _failure_count + _skipped_count
	print(LOG_PREFIX + "Test run completed:")
	print(LOG_PREFIX + "  Total tests: " + str(total))
	print(LOG_PREFIX + "  Passed: " + str(_success_count))
	print(LOG_PREFIX + "  Failed: " + str(_failure_count))
	print(LOG_PREFIX + "  Skipped: " + str(_skipped_count))
	
	if _failure_count == 0:
		print(LOG_PREFIX + "ALL TESTS PASSED!")
	else:
		push_error(LOG_PREFIX + "SOME TESTS FAILED!")

# Helper methods for test scripts

func assert_true(condition: bool, message: String = "") -> void:
	"""Assert that a condition is true."""
	if not condition:
		_report_assertion_failure("Expected true but got false. " + message)

func assert_false(condition: bool, message: String = "") -> void:
	"""Assert that a condition is false."""
	if condition:
		_report_assertion_failure("Expected false but got true. " + message)

func assert_equal(expected, actual, message: String = "") -> void:
	"""Assert that two values are equal."""
	if expected != actual:
		_report_assertion_failure("Expected " + str(expected) + " but got " + str(actual) + ". " + message)

func assert_not_equal(expected, actual, message: String = "") -> void:
	"""Assert that two values are not equal."""
	if expected == actual:
		_report_assertion_failure("Expected value to be different from " + str(expected) + ". " + message)

func assert_null(value, message: String = "") -> void:
	"""Assert that a value is null."""
	if value != null:
		_report_assertion_failure("Expected null but got " + str(value) + ". " + message)

func assert_not_null(value, message: String = "") -> void:
	"""Assert that a value is not null."""
	if value == null:
		_report_assertion_failure("Expected non-null value. " + message)

func _report_assertion_failure(message: String) -> void:
	"""Report an assertion failure."""
	var error_message = "Assertion failed in " + _current_test_name + ": " + message
	push_error(LOG_PREFIX + error_message)
	assert(false, error_message)  # This will trigger the exception to be caught by the try/except block 