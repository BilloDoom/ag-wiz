extends Node

@export var new_script_btn: Button
@export var save_btn: Button
@export var line_edit: LineEdit
@export var open_script_button: Button
@export var code_edit: CodeEdit

var current_script_id: String = ""
var script_manager: Node
var file_dialog: FileDialog
var is_text_changing_internally: bool = false

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

	# Connect CodeEdit changes to track modifications
	code_edit.text_changed.connect(_on_code_changed)

	# Connect to ScriptManager signals
	script_manager.script_modified.connect(_on_script_modified)
	script_manager.script_saved.connect(_on_script_saved)

	# Setup file dialog
	_setup_file_dialog()

	# Connect to window close request
	get_tree().root.close_requested.connect(_on_close_requested)

	# Create initial script
	_create_new_script("Untitled")

	print("ScriptBox: Initialized")

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
	# Check if current script has unsaved changes
	if current_script_id != "":
		var script = script_manager.get_script_(current_script_id)
		if script and script.is_modified:
			_show_unsaved_warning(func(): _create_new_script("Untitled"))
			return

	_create_new_script("Untitled")

func _create_new_script(script_name: String) -> void:
	"""Create a new script and load it into the editor"""
	current_script_id = script_manager.create_script(script_name, "python")
	var script = script_manager.get_script_(current_script_id)

	if script:
		is_text_changing_internally = true
		code_edit.text = script.content
		line_edit.text = script.name
		is_text_changing_internally = false
		print("ScriptBox: Created new script '%s'" % script_name)

func _on_save_pressed() -> void:
	"""Save the current script"""
	if current_script_id == "":
		push_warning("ScriptBox: No script to save")
		return

	var script = script_manager.get_script_(current_script_id)
	if not script:
		push_error("ScriptBox: Current script not found")
		return

	# Update script content before saving
	script_manager.set_script_content(current_script_id, code_edit.text)

	# If script has a file path, save directly
	if script.file_path != "":
		script_manager.save_script(current_script_id)
		_update_script_name_display()
	else:
		# Show save dialog
		file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		file_dialog.current_file = script.name + ".py"
		file_dialog.popup_centered(Vector2i(800, 600))

func _on_open_pressed() -> void:
	"""Open a script file"""
	# Check if current script has unsaved changes
	if current_script_id != "":
		var script = script_manager.get_script_(current_script_id)
		if script and script.is_modified:
			_show_unsaved_warning(func(): _show_open_dialog())
			return

	_show_open_dialog()

func _show_open_dialog() -> void:
	"""Show the file dialog for opening scripts"""
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_file_selected(path: String) -> void:
	"""Handle file selection from dialog"""
	if file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		# Load script from file
		current_script_id = script_manager.load_script_from_file(path)
		var script = script_manager.get_script_(current_script_id)

		if script:
			is_text_changing_internally = true
			code_edit.text = script.content
			line_edit.text = script.name
			is_text_changing_internally = false
			print("ScriptBox: Opened script '%s'" % path)

	elif file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		# Save script to file
		var success = script_manager.save_script(current_script_id, path)
		if success:
			_update_script_name_display()

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
		script_manager.rename_script(current_script_id, clean_name)

func _on_script_modified(script_id: String, _content: String) -> void:
	"""Called when a script is modified"""
	if script_id == current_script_id:
		_update_script_name_display()

func _on_script_saved(script_id: String, _file_path: String) -> void:
	"""Called when a script is saved"""
	if script_id == current_script_id:
		_update_script_name_display()

func _update_script_name_display() -> void:
	"""Update the line edit to show script name with modification indicator"""
	if current_script_id == "":
		return

	var script = script_manager.get_script_(current_script_id)
	if not script:
		return

	is_text_changing_internally = true
	if script.is_modified:
		line_edit.text = "*" + script.name
	else:
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
