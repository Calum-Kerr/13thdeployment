# Testing Framework for Soulsborne Web Game

This directory contains the automated testing framework for the Soulsborne Web Game project. The framework is designed to help ensure code quality and prevent regressions as the project evolves.

## Overview

The testing framework consists of:

- `test_runner.gd`: The main test runner that discovers and executes tests
- `test_scene.tscn` and `test_scene.gd`: A scene and script for running tests in the Godot editor
- `unit/`: Directory containing unit tests for individual components

## Running Tests

To run the tests:

1. Open the Godot project
2. Open the `tests/test_scene.tscn` scene
3. Run the scene
4. Click the "Run Tests" button

The test results will be displayed in the scene and in the Godot console.

## Writing Tests

To write a new test:

1. Create a new script in the `tests/unit/` directory with a name ending in `_test.gd`
2. Extend the script from `Node`
3. Implement test methods that start with `test_`
4. Use the assertion methods provided by the test runner

Example:

```gdscript
extends Node
class_name MyTest

func setup():
    # Called before any tests are run
    pass

func teardown():
    # Called after all tests are run
    pass

func before_each():
    # Called before each test
    pass

func after_each():
    # Called after each test
    pass

func test_something():
    # This is a test method
    var test_runner = get_node("/root/TestRunner")
    test_runner.assert_true(true, "This should pass")
    test_runner.assert_equal(2 + 2, 4, "Addition should work")
```

## Available Assertions

The test runner provides the following assertion methods:

- `assert_true(condition, message)`: Assert that a condition is true
- `assert_false(condition, message)`: Assert that a condition is false
- `assert_equal(expected, actual, message)`: Assert that two values are equal
- `assert_not_equal(expected, actual, message)`: Assert that two values are not equal
- `assert_null(value, message)`: Assert that a value is null
- `assert_not_null(value, message)`: Assert that a value is not null

## Skipping Tests

To skip a test, implement the `is_skipped` method in your test script:

```gdscript
func is_skipped(method_name: String) -> bool:
    # Return true if the test should be skipped
    return method_name == "test_to_skip"
```

## NASA Coding Guidelines Compliance

The testing framework follows NASA's coding guidelines for safety and robustness:

- Simple control flow
- Fixed upper bounds for loops
- Limited function size
- Consistent error handling
- Clear documentation
- Thorough testing

For more details, see the [NASA Coding Guidelines](../docs/nasa_coding_guidelines.md) document. 