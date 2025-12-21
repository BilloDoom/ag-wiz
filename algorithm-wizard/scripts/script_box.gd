extends Node

signal action_performed(message: String)

@export var new_script_btn: Button
@export var save_btn: Button
@export var line_edit: LineEdit
@export var open_script_button: Button
@export var code_edit: CodeEdit
@export var menu_btn: MenuButton

var current_script_id: String = ""
var script_manager: Node
var file_dialog: FileDialog
var is_text_changing_internally: bool = false
var scripts_popup: PopupMenu
var save_queue: Array = []  # Queue for saving multiple in-memory scripts

func _ready() -> void:
	# Get ScriptManager autoload
	script_manager = get_node("/root/ScriptManager")
	if not script_manager:
		push_error("ScriptBox: ScriptManager not found!")
		return

	# Get CodeEdit if not exported
	if not code_edit:
		code_edit = get_node("../VBoxContainer/VSplitContainer/CodeEdit")

	# Connect button signals
	new_script_btn.pressed.connect(_on_new_script_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	open_script_button.pressed.connect(_on_open_pressed)
	line_edit.text_changed.connect(_on_script_name_changed)

	# Setup scripts menu
	_setup_scripts_menu()

	# Connect CodeEdit changes to track modifications
	code_edit.text_changed.connect(_on_code_changed)

	# Connect to ScriptManager signals
	script_manager.script_modified.connect(_on_script_modified)
	script_manager.script_saved.connect(_on_script_saved)
	script_manager.script_created.connect(_on_script_created)
	script_manager.script_renamed.connect(_on_script_renamed)
	script_manager.script_deleted.connect(_on_script_deleted)

	# Setup file dialog
	_setup_file_dialog()

	# Connect to window close request
	get_tree().root.close_requested.connect(_on_close_requested)

	# Connect to CodeRunner signals
	var code_runner = get_node("../CodeRunner")
	if code_runner:
		code_runner.script_execution_started.connect(_on_script_execution_started)

	# Start with no script - disable editor
	_set_editor_state(false)

	print("ScriptBox: Initialized (no script loaded)")

func _on_script_execution_started(script_name: String) -> void:
	"""Relay script execution signal to action_performed"""
	action_performed.emit("Running script: %s" % script_name)

func _set_editor_state(enabled: bool) -> void:
	"""Enable or disable the code editor and related UI"""
	code_edit.editable = enabled
	line_edit.editable = enabled
	save_btn.disabled = not enabled

	if not enabled:
		is_text_changing_internally = true
		code_edit.text = ""
		line_edit.text = "No script loaded"
		line_edit.placeholder_text = "Create or open a script to begin"
		is_text_changing_internally = false
		current_script_id = ""
	else:
		line_edit.placeholder_text = "Script name"

func _input(event: InputEvent) -> void:
	"""Handle input events for hotkeys"""
	if event.is_action_pressed("save"):
		_on_save_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("new_script"):
		_on_new_script_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_file"):
		_on_open_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("run_script"):
		# Trigger run button if we have a script
		if current_script_id != "":
			var code_runner = get_node("../CodeRunner")
			if code_runner:
				code_runner._on_run_pressed()
		get_viewport().set_input_as_handled()

func _get_unique_script_name(base_name: String) -> String:
	"""Get a unique script name by adding .001, .002, etc. if name exists"""
	var all_scripts = script_manager.get_all_scripts()
	var existing_names = []

	# Collect all existing script names
	for script_id in all_scripts:
		var script = script_manager.get_script_(script_id)
		if script:
			existing_names.append(script.name)

	# Check if base name exists
	if base_name not in existing_names:
		return base_name

	# Find next available number
	var counter = 1
	while true:
		var numbered_name = base_name + ".%03d" % counter
		if numbered_name not in existing_names:
			return numbered_name
		counter += 1

		# Safety limit
		if counter > 999:
			return base_name + ".999"

	return base_name

func _script_name_exists(name: String, exclude_id: String = "") -> bool:
	"""Check if a script name already exists (excluding a specific script ID)"""
	var all_scripts = script_manager.get_all_scripts()

	for script_id in all_scripts:
		if script_id == exclude_id:
			continue

		var script = script_manager.get_script_(script_id)
		if script and script.name == name:
			return true

	return false

func _setup_scripts_menu() -> void:
	"""Setup the scripts dropdown menu"""
	scripts_popup = menu_btn.get_popup()
	scripts_popup.index_pressed.connect(_on_script_menu_item_selected)
	_update_scripts_menu()

func _on_close_requested() -> void:
	"""Handle window close request - check for unsaved changes"""
	var modified_scripts = script_manager.get_modified_scripts()

	if modified_scripts.size() > 0:
		# Prevent default close
		get_tree().root.set_input_as_handled()

		# Show warning dialog
		var dialog = ConfirmationDialog.new()
		dialog.dialog_text = "You have %d unsaved script(s). Are you sure you want to quit?" % modified_scripts.size()
		dialog.title = "Unsaved Changes"
		dialog.ok_button_text = "Quit Anyway"
		dialog.cancel_button_text = "Cancel"

		dialog.confirmed.connect(func():
			# User confirmed, quit the application
			get_tree().quit()
			dialog.queue_free()
		)

		dialog.canceled.connect(func():
			dialog.queue_free()
		)

		add_child(dialog)
		dialog.popup_centered()

func _setup_file_dialog() -> void:
	"""Setup file dialog for opening/saving scripts"""
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.py", "Python Scripts")
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)

func _on_new_script_pressed() -> void:
	"""Create a new script"""
	# Save current script content before creating new one
	if current_script_id != "":
		script_manager.set_script_content(current_script_id, code_edit.text)

	_create_new_script("Untitled")

func _create_new_script(script_name: String) -> void:
	"""Create a new script and load it into the editor"""
	# Get unique name if there's a collision
	var unique_name = _get_unique_script_name(script_name)

	current_script_id = script_manager.create_script(unique_name, "python")
	_load_script_into_editor(current_script_id)

	# Emit action signal
	action_performed.emit("New script created: %s" % unique_name)
	print("ScriptBox: Created new script '%s'" % unique_name)

func _load_script_into_editor(script_id: String) -> void:
	"""Load a script into the editor"""
	var script = script_manager.get_script_(script_id)
	if script:
		current_script_id = script_id
		is_text_changing_internally = true
		code_edit.text = script.content
		line_edit.text = script.name
		is_text_changing_internally = false
		_set_editor_state(true)

func _switch_to_script(script_id: String) -> void:
	"""Switch to a different script"""
	if script_id == current_script_id:
		return  # Already viewing this script

	# Save current script content before switching
	if current_script_id != "":
		script_manager.set_script_content(current_script_id, code_edit.text)

	# Load new script
	_load_script_into_editor(script_id)
	print("ScriptBox: Switched to script '%s'" % script_id)

func _update_scripts_menu() -> void:
	"""Update the scripts dropdown menu with all available scripts"""
	scripts_popup.clear()

	var all_scripts = script_manager.get_all_scripts()

	if all_scripts.size() == 0:
		# No scripts available
		scripts_popup.add_item("(No scripts open)")
		scripts_popup.set_item_disabled(0, true)
		return

	for script_id in all_scripts:
		var script = script_manager.get_script_(script_id)
		if script:
			var display_name = script.name
			if script.is_modified:
				display_name = "*" + display_name

			# Add file path hint if available
			if script.file_path != "":
				display_name += " (" + script.file_path.get_file() + ")"

			scripts_popup.add_item(display_name)
			scripts_popup.set_item_metadata(scripts_popup.get_item_count() - 1, script_id)

			# Mark current script
			if script_id == current_script_id:
				scripts_popup.set_item_checked(scripts_popup.get_item_count() - 1, true)

func _on_script_menu_item_selected(index: int) -> void:
	"""Handle script selection from menu"""
	var script_id = scripts_popup.get_item_metadata(index)
	if script_id:
		_switch_to_script(script_id)

func _on_script_created(script_id: String) -> void:
	"""Called when a new script is created"""
	_update_scripts_menu()

func _on_script_renamed(script_id: String, _new_name: String) -> void:
	"""Called when a script is renamed"""
	_update_scripts_menu()

func _on_script_deleted(script_id: String) -> void:
	"""Called when a script is deleted"""
	_update_scripts_menu()

func _on_save_pressed() -> void:
	"""Save all modified scripts"""
	# Don't do anything if no script is loaded
	if current_script_id == "":
		print("ScriptBox: No script loaded")
		return

	# Update current script content first
	script_manager.set_script_content(current_script_id, code_edit.text)

	var modified_scripts = script_manager.get_modified_scripts()

	if modified_scripts.size() == 0:
		print("ScriptBox: No modified scripts to save")
		return

	# Separate scripts with file paths from in-memory scripts
	var scripts_with_paths = []
	var scripts_without_paths = []

	for script_id in modified_scripts:
		var script = script_manager.get_script_(script_id)
		if script:
			if script.file_path != "":
				scripts_with_paths.append(script_id)
			else:
				scripts_without_paths.append(script_id)

	# Save all scripts that have file paths
	for script_id in scripts_with_paths:
		script_manager.save_script(script_id)
		var script = script_manager.get_script_(script_id)
		if script:
			# Emit action signal
			action_performed.emit("Script saved: %s" % script.name)
			print("ScriptBox: Saved '%s'" % script.name)

	# Prompt for in-memory scripts one by one
	if scripts_without_paths.size() > 0:
		save_queue = scripts_without_paths.duplicate()
		_save_next_in_queue()
	else:
		_update_script_name_display()
		_update_scripts_menu()
		print("ScriptBox: All scripts saved successfully")

func _save_next_in_queue() -> void:
	"""Save the next script in the save queue"""
	if save_queue.size() == 0:
		_update_script_name_display()
		_update_scripts_menu()
		print("ScriptBox: All scripts saved successfully")
		return

	var script_id = save_queue.pop_front()
	var script = script_manager.get_script_(script_id)

	if script:
		# Show save dialog for this script
		file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		file_dialog.current_file = script.name + ".py"
		file_dialog.set_meta("saving_script_id", script_id)
		file_dialog.popup_centered(Vector2i(800, 600))

func _on_open_pressed() -> void:
	"""Open a script file"""
	# Save current script content before opening new one
	if current_script_id != "":
		script_manager.set_script_content(current_script_id, code_edit.text)

	_show_open_dialog()

func _show_open_dialog() -> void:
	"""Show the file dialog for opening scripts"""
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_file_selected(path: String) -> void:
	"""Handle file selection from dialog"""
	if file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		# Load script from file
		var new_script_id = script_manager.load_script_from_file(path)
		_load_script_into_editor(new_script_id)
		_update_scripts_menu()

		# Emit action signal
		var script = script_manager.get_script_(new_script_id)
		if script:
			action_performed.emit("Script opened: %s" % script.name)

		print("ScriptBox: Opened script '%s'" % path)

	elif file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		# Check if we're saving from the queue or a single script
		var script_id_to_save = current_script_id
		if file_dialog.has_meta("saving_script_id"):
			script_id_to_save = file_dialog.get_meta("saving_script_id")
			file_dialog.remove_meta("saving_script_id")

		# Save script to file
		var success = script_manager.save_script(script_id_to_save, path)
		if success:
			var script = script_manager.get_script_(script_id_to_save)
			if script:
				# Emit action signal
				action_performed.emit("Script saved: %s" % script.name)

			print("ScriptBox: Saved '%s' to '%s'" % [script.name if script else "Unknown", path])

			# Continue with save queue if there are more scripts
			if save_queue.size() > 0:
				_save_next_in_queue()
			else:
				_update_script_name_display()
				_update_scripts_menu()

func _on_code_changed() -> void:
	"""Called when code editor content changes"""
	if is_text_changing_internally:
		return

	if current_script_id != "":
		script_manager.set_script_content(current_script_id, code_edit.text)

func _on_script_name_changed(new_name: String) -> void:
	"""Called when script name is edited in line edit"""
	if is_text_changing_internally:
		return

	if current_script_id != "":
		# Remove star prefix if present
		var clean_name = new_name.trim_prefix("*")

		# Check if name already exists
		if _script_name_exists(clean_name, current_script_id):
			# Get unique name with number suffix
			var unique_name = _get_unique_script_name(clean_name)
			script_manager.rename_script(current_script_id, unique_name)

			# Update display with the unique name
			is_text_changing_internally = true
			line_edit.text = unique_name
			is_text_changing_internally = false
		else:
			script_manager.rename_script(current_script_id, clean_name)

func _on_script_modified(script_id: String, _content: String) -> void:
	"""Called when a script is modified"""
	if script_id == current_script_id:
		_update_script_name_display()
	_update_scripts_menu()

func _on_script_saved(script_id: String, _file_path: String) -> void:
	"""Called when a script is saved"""
	if script_id == current_script_id:
		_update_script_name_display()
	_update_scripts_menu()

func _update_script_name_display() -> void:
	"""Update the line edit to show script name (no modification indicator in text field)"""
	if current_script_id == "":
		return

	var script = script_manager.get_script_(current_script_id)
	if not script:
		return

	is_text_changing_internally = true
	line_edit.text = script.name
	is_text_changing_internally = false

func _show_unsaved_warning(on_discard: Callable) -> void:
	"""Show a warning dialog for unsaved changes"""
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "You have unsaved changes. Do you want to discard them?"
	dialog.title = "Unsaved Changes"
	dialog.ok_button_text = "Discard"
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.confirmed.connect(func():
		on_discard.call()
		dialog.queue_free()
	)

	# Add cancel button
	dialog.add_cancel_button("Cancel")

	add_child(dialog)
	dialog.popup_centered()

func has_unsaved_changes() -> bool:
	"""Check if current script has unsaved changes"""
	if current_script_id == "":
		return false

	var script = script_manager.get_script_(current_script_id)
	return script and script.is_modified

func get_modified_scripts_count() -> int:
	"""Get count of all modified scripts"""
	return script_manager.get_modified_scripts().size()
