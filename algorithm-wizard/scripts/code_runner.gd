extends Node
class_name CodeRunner

@export var run_btn: Button
@export var compile_btn: Button
@export var code_edit: CodeEdit
@export var debug_panel: CodeLogger

var script_runtime: ScriptRuntime
var viewport_bridge: ViewportBridge

func _ready():
	# Initialize Python runtime
	script_runtime = ScriptRuntime.new()
	script_runtime.initialize_python()

	# Setup viewport bridge for Python API
	viewport_bridge = ViewportBridge.new()
	viewport_bridge.name = "ViewportBridge"
	add_child(viewport_bridge)
	viewport_bridge.setup_python_bindings()

	# Connect button signals
	run_btn.pressed.connect(_on_run_pressed)
	#compile_btn.pressed.connect(_on_compile_pressed)

	debug_panel.log_message("Python runtime initialized")
	debug_panel.log_message("Viewport API available in Python")

func _on_run_pressed():
	var code = code_edit.text
	debug_panel.clear_output()
	debug_panel.log_message("Running script...")

	# Clean up previous scenes/cameras before running new script
	var viewport_manager = get_node("/root/ViewportManager")
	if viewport_manager:
		viewport_manager.cleanup_all_scenes()

	# Execute the script
	var success = script_runtime.execute_script(code)

	if success:
		var output = script_runtime.get_last_output()
		if output != "":
			debug_panel.log_output(output)
		else:
			debug_panel.log_message("Script executed successfully (no output)")
	else:
		var error = script_runtime.get_last_error()
		debug_panel.log_error(error)

func _on_compile_pressed():
	var code = code_edit.text
	debug_panel.clear_output()
	debug_panel.log_message("Checking syntax...")

	# Try to compile (execute in check mode)
	var success = script_runtime.execute_script("compile('''" + code + "''', '<string>', 'exec')")

	if success:
		debug_panel.log_message("✓ No syntax errors found")
	else:
		var error = script_runtime.get_last_error()
		debug_panel.log_error("Syntax error:\n" + error)
