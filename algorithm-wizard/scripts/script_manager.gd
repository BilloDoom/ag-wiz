extends Node

# In-memory script storage
var scripts: Dictionary = {}  # script_id -> ScriptData
var next_script_id: int = 1

signal script_created(script_id: String)
signal script_modified(script_id: String, content: String)
signal script_deleted(script_id: String)
signal script_saved(script_id: String, file_path: String)
signal script_renamed(script_id: String, new_name: String)

class ScriptData:
	var script_id: String
	var name: String
	var content: String
	var language: String  # "python", "gdscript", etc.
	var file_path: String = ""  # Empty if unsaved
	var is_modified: bool = false
	var created_at: float
	var modified_at: float
	
	func _init(id: String, script_name: String, lang: String = "python"):
		script_id = id
		name = script_name
		language = lang
		content = ""
		created_at = Time.get_unix_time_from_system()
		modified_at = created_at

func _ready() -> void:
	print("ScriptManager: Initialized")

func create_script(script_name: String, language: String = "python") -> String:
	"""Create a new script in memory"""
	var script_id = "script_" + str(next_script_id)
	next_script_id += 1
	
	var script_data = ScriptData.new(script_id, script_name, language)
	scripts[script_id] = script_data
	
	script_created.emit(script_id)
	print("ScriptManager: Created script '%s' (ID: %s)" % [script_name, script_id])
	
	return script_id

func get_script_(script_id: String) -> ScriptData:
	"""Get script data by ID"""
	return scripts.get(script_id, null)

func get_script_content(script_id: String) -> String:
	"""Get script content"""
	var script = get_script_(script_id)
	return script.content if script else ""

func set_script_content(script_id: String, content: String) -> void:
	"""Update script content (called by editors)"""
	var script = get_script_(script_id)
	if not script:
		push_error("ScriptManager: Script not found: " + script_id)
		return
	
	if script.content != content:
		script.content = content
		script.is_modified = true
		script.modified_at = Time.get_unix_time_from_system()
		script_modified.emit(script_id, content)

func rename_script(script_id: String, new_name: String) -> void:
	"""Rename a script"""
	var script = get_script_(script_id)
	if not script:
		push_error("ScriptManager: Script not found: " + script_id)
		return
	
	script.name = new_name
	script.is_modified = true
	script_renamed.emit(script_id, new_name)

func delete_script(script_id: String) -> void:
	"""Delete a script from memory"""
	if scripts.has(script_id):
		scripts.erase(script_id)
		script_deleted.emit(script_id)
		print("ScriptManager: Deleted script: " + script_id)

func save_script(script_id: String, file_path: String = "") -> bool:
	"""Save script to disk"""
	var script = get_script_(script_id)
	if not script:
		push_error("ScriptManager: Script not found: " + script_id)
		return false
	
	# Use existing path if not provided
	var save_path = file_path if file_path != "" else script.file_path
	
	if save_path == "":
		push_error("ScriptManager: No file path provided for save")
		return false
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("ScriptManager: Failed to save script to: " + save_path)
		return false
	
	file.store_string(script.content)
	file.close()
	
	script.file_path = save_path
	script.is_modified = false
	script_saved.emit(script_id, save_path)
	
	print("ScriptManager: Saved script '%s' to: %s" % [script.name, save_path])
	return true

func load_script_from_file(file_path: String, script_name: String = "") -> String:
	"""Load a script from disk into memory"""
	if not FileAccess.file_exists(file_path):
		push_error("ScriptManager: File not found: " + file_path)
		return ""
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("ScriptManager: Failed to open file: " + file_path)
		return ""
	
	var content = file.get_as_text()
	file.close()
	
	# Determine language from extension
	var language = "python"
	if file_path.ends_with(".gd"):
		language = "gdscript"
	elif file_path.ends_with(".py"):
		language = "python"
	
	# Create script in memory
	var name = script_name if script_name != "" else file_path.get_file()
	var script_id = create_script(name, language)
	
	var script = get_script_(script_id)
	script.content = content
	script.file_path = file_path
	script.is_modified = false
	
	print("ScriptManager: Loaded script from: " + file_path)
	return script_id

func get_all_scripts() -> Array:
	"""Get list of all script IDs"""
	return scripts.keys()

func get_modified_scripts() -> Array:
	"""Get list of modified script IDs"""
	var modified = []
	for script_id in scripts.keys():
		var script = scripts[script_id]
		if script.is_modified:
			modified.append(script_id)
	return modified

func execute_script(script_id: String) -> void:
	"""Execute a script (send to Python bridge)"""
	var script = get_script_(script_id)
	if not script:
		push_error("ScriptManager: Script not found: " + script_id)
		return
	
	if script.language == "python":
		# Send to Python bridge for execution
		# This is where you'd integrate with your existing godot-python system
		print("ScriptManager: Executing Python script: " + script_id)
		# Example: PythonBridge.execute(script.content)
	else:
		push_warning("ScriptManager: Cannot execute non-Python script: " + script_id)
