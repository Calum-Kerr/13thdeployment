extends Node
class_name ExampleTest

"""
ExampleTest: A sample test script to demonstrate the testing framework.
"""

# Test setup and teardown
func setup() -> void:
	"""Called before any tests are run."""
	print("Setting up ExampleTest")

func teardown() -> void:
	"""Called after all tests are run."""
	print("Tearing down ExampleTest")

func before_each() -> void:
	"""Called before each test."""
	print("Before test")

func after_each() -> void:
	"""Called after each test."""
	print("After test")

# Test methods
func test_assert_true() -> void:
	"""Test that assert_true works."""
	var test_runner = get_node("/root/TestRunner")
	test_runner.assert_true(true, "This should pass")
	# Uncomment to see a failure:
	# test_runner.assert_true(false, "This should fail")

func test_assert_equal() -> void:
	"""Test that assert_equal works."""
	var test_runner = get_node("/root/TestRunner")
	test_runner.assert_equal(5, 5, "This should pass")
	test_runner.assert_equal("hello", "hello", "This should pass")
	# Uncomment to see a failure:
	# test_runner.assert_equal(5, 10, "This should fail")

func test_math_operations() -> void:
	"""Test basic math operations."""
	var test_runner = get_node("/root/TestRunner")
	test_runner.assert_equal(2 + 2, 4, "Addition should work")
	test_runner.assert_equal(5 - 3, 2, "Subtraction should work")
	test_runner.assert_equal(3 * 4, 12, "Multiplication should work")
	test_runner.assert_equal(10 / 2, 5, "Division should work")

# Example of a skipped test
func is_skipped(method_name: String) -> bool:
	"""Return true if the test should be skipped."""
	return method_name == "test_skipped"

func test_skipped() -> void:
	"""This test will be skipped."""
	var test_runner = get_node("/root/TestRunner")
	test_runner.assert_true(false, "This should not be executed") 