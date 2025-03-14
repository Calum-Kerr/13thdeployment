extends Node

"""
TestScene: A scene to run automated tests for the Soulsborne Web Game.
"""

@onready var results_label: Label = $ResultsLabel

func _ready() -> void:
	"""Initialize the test scene."""
	print("Test scene initialized")

func _on_tests_completed(success_count: int, failure_count: int, skipped_count: int) -> void:
	"""Handle test completion."""
	var total = success_count + failure_count + skipped_count
	var result_text = "Test Results:\n"
	result_text += "Total: " + str(total) + "\n"
	result_text += "Passed: " + str(success_count) + "\n"
	result_text += "Failed: " + str(failure_count) + "\n"
	result_text += "Skipped: " + str(skipped_count) + "\n"
	
	if failure_count == 0:
		result_text += "\nALL TESTS PASSED!"
	else:
		result_text += "\nSOME TESTS FAILED!"
	
	results_label.text = result_text 