extends Node
class_name AsyncScriptRunner

signal continue_pressed

var is_waiting: bool = false
var wait_type: String = ""  # "time" or "input"
var wait_timer: Timer = null

# Reference to continue button (set externally)
var continue_button: Button = null

func _ready():
	# Create a timer for time-based waits
	wait_timer = Timer.new()
	wait_timer.one_shot = true
	wait_timer.timeout.connect(_on_wait_timer_timeout)
	add_child(wait_timer)

func start_wait(duration: float) -> void:
	"""Start a time-based wait"""
	print("AsyncScriptRunner: Starting wait for ", duration, " seconds")
	is_waiting = true
	wait_type = "time"
	wait_timer.start(duration)

	# Hide continue button during time wait
	if continue_button:
		continue_button.visible = false

func start_input_wait() -> void:
	"""Start waiting for user input"""
	print("AsyncScriptRunner: Waiting for user input")
	is_waiting = true
	wait_type = "input"

	# Show continue button
	if continue_button:
		continue_button.visible = true

func _on_wait_timer_timeout() -> void:
	"""Timer finished, resume execution"""
	if wait_type == "time":
		print("AsyncScriptRunner: Wait time elapsed, resuming")
		is_waiting = false
		wait_type = ""
		_resume_generator()

func on_continue_pressed() -> void:
	"""User pressed continue button"""
	if wait_type == "input":
		print("AsyncScriptRunner: User pressed continue, resuming")
		is_waiting = false
		wait_type = ""

		# Hide continue button
		if continue_button:
			continue_button.visible = false

		_resume_generator()

func on_generator_complete() -> void:
	"""Generator finished execution"""
	print("AsyncScriptRunner: Generator execution completed")
	is_waiting = false
	wait_type = ""

	# Hide continue button
	if continue_button:
		continue_button.visible = false

func _resume_generator() -> void:
	"""Resume the Python generator by calling resume_async()"""
	# Get the script runtime to execute Python code
	var code_runner = get_parent()
	if !code_runner:
		printerr("AsyncScriptRunner: No parent CodeRunner found")
		return

	var script_runtime = code_runner.script_runtime
	if !script_runtime:
		printerr("AsyncScriptRunner: No ScriptRuntime found")
		return

	# Call the Python resume_async() function
	var success = script_runtime.execute_script("from godot import resume_async; result = resume_async()")

	if success:
		# Check what the result was (wait, input, complete, error)
		var check_code = """
import sys
from io import StringIO
from godot import resume_async

result = resume_async()
if result and isinstance(result, dict):
    result_type = result.get('type', '')
    if result_type == 'wait':
        print('ASYNC_RESULT:wait:' + str(result.get('duration', 0)))
    elif result_type == 'input':
        print('ASYNC_RESULT:input')
    elif result_type == 'complete':
        print('ASYNC_RESULT:complete')
    elif result_type == 'error':
        print('ASYNC_ERROR:' + result.get('message', 'Unknown error'))
"""

		success = script_runtime.execute_script(check_code)
		if success:
			var output = script_runtime.get_last_output()

			# Parse the output to determine next action
			if "ASYNC_RESULT:wait:" in output:
				var parts = output.split("ASYNC_RESULT:wait:")
				if parts.size() > 1:
					var duration = float(parts[1].strip_edges())
					start_wait(duration)
			elif "ASYNC_RESULT:input" in output:
				start_input_wait()
			elif "ASYNC_RESULT:complete" in output:
				on_generator_complete()
			elif "ASYNC_ERROR:" in output:
				var parts = output.split("ASYNC_ERROR:")
				if parts.size() > 1:
					printerr("AsyncScriptRunner: Python error: ", parts[1])
				on_generator_complete()
	else:
		var error = script_runtime.get_last_error()
		printerr("AsyncScriptRunner: Failed to resume: ", error)
		on_generator_complete()
