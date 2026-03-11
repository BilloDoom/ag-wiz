extends Node
class_name CodeRunner

signal script_execution_started(script_name: String)

@export var run_btn: Button
@export var continue_btn: Button
@export var compile_btn: Button
@export var code_edit: CodeEdit
@export var debug_panel: CodeLogger

var script_runtime: ScriptRuntime
var viewport_bridge: ViewportBridge
var async_runner: AsyncScriptRunner

func _ready():
	# Do not initialise anything when running inside the Godot editor.
	# The GDExtension C++ classes (ScriptRuntime, ViewportBridge) are not
	# safe to instantiate at editor-time and will crash the editor on scene
	# preview / open.
	if Engine.is_editor_hint():
		return

	# Initialize Python runtime
	script_runtime = ScriptRuntime.new()
	script_runtime.initialize_python()

	# Setup viewport bridge for Python API
	viewport_bridge = ViewportBridge.new()
	viewport_bridge.name = "ViewportBridge"
	add_child(viewport_bridge)
	viewport_bridge.setup_python_bindings()

	# Setup async script runner
	async_runner = AsyncScriptRunner.new()
	async_runner.name = "AsyncScriptRunner"
	add_child(async_runner)

	# Give async runner reference to continue button
	async_runner.continue_button = continue_btn

	# Connect button signals
	run_btn.pressed.connect(_on_run_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	#compile_btn.pressed.connect(_on_compile_pressed)

	debug_panel.log_message("Python runtime initialized")
	debug_panel.log_message("Viewport API available in Python")
	debug_panel.log_message("Async execution system ready")

func _flush_output(output: String) -> void:
	"""Split raw Python stdout into normal lines and SANDBOX_WARN lines."""
	if output == "":
		return
	var clean_lines: PackedStringArray = []
	for line in output.split("\n"):
		if line.begins_with("SANDBOX_WARN:"):
			var msg = line.substr(len("SANDBOX_WARN:"))
			debug_panel.log_warning(msg)
			push_warning("[SANDBOX] " + msg)
			print_rich("[color=magenta][SANDBOX] " + msg + "[/color]")
		else:
			clean_lines.append(line)
	var clean = "\n".join(clean_lines).strip_edges()
	if clean != "":
		debug_panel.log_output(clean + "\n")

func _on_run_pressed():
	var code = code_edit.text
	debug_panel.clear_output()
	debug_panel.log_message("Running script...")

	# Get script name from parent ScriptBox
	var script_box = get_parent().get_node("ScriptBox")
	var script_name = "Unknown"
	if script_box and script_box.current_script_id != "":
		var script_manager = get_node("/root/ScriptManager")
		if script_manager:
			var script = script_manager.get_script_(script_box.current_script_id)
			if script:
				script_name = script.name

	# Emit signal that script execution is starting
	script_execution_started.emit(script_name)

	# Clean up previous scenes/cameras before running new script
	var viewport_manager = get_node("/root/ViewportManager")
	if viewport_manager:
		viewport_manager.cleanup_all_scenes()

	# Reset Python globals so the new script starts with a clean namespace.
	script_runtime.reset_globals()

	# Execute the script
	var success = script_runtime.execute_script(code)

	if success:
		_flush_output(script_runtime.get_last_output())
	else:
		_flush_output(script_runtime.get_last_output())
		debug_panel.log_error(script_runtime.get_last_error())

func _on_continue_pressed():
	# User pressed continue during async execution
	if async_runner:
		async_runner.on_continue_pressed()

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
