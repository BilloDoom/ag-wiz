extends MarginContainer
class_name Tile

signal window_type_changed(tile: Tile, window_type: String)
signal viewport_requested(tile: Tile)

# Button 1
@export var button_1: BaseButton
@export var button_1_scene: PackedScene

# Button 2
@export var button_2: BaseButton
@export var button_2_scene: PackedScene

# Button 3
@export var button_3: BaseButton
@export var button_3_scene: PackedScene

@export var content_container: Control  # Container where window is loaded

var current_window_type: String = ""
var current_window_instance: Node = null

func _ready() -> void:
	# Connect button 1
	if button_1:
		button_1.pressed.connect(_on_button_1_pressed)
	
	# Connect button 2
	if button_2:
		button_2.pressed.connect(_on_button_2_pressed)
	
	# Connect button 3
	if button_3:
		button_3.pressed.connect(_on_button_3_pressed)
	
	# Load initial window type if set
	if has_meta("window_type"):
		var initial_type = get_meta("window_type")
		set_window_type(initial_type)

func _on_button_1_pressed() -> void:
	"""Handle button 1 press (Viewport)"""
	# Emit signal for viewport creation
	viewport_requested.emit(self)

	if button_1_scene:
		load_window(button_1.name, button_1_scene)
	else:
		push_warning("Tile: button_1_scene not assigned")

func _on_button_2_pressed() -> void:
	"""Handle button 2 press"""
	if button_2_scene:
		load_window(button_2.name, button_2_scene)
	else:
		push_warning("Tile: button_2_scene not assigned")

func _on_button_3_pressed() -> void:
	"""Handle button 3 press"""
	if button_3_scene:
		load_window(button_3.name, button_3_scene)
	else:
		push_warning("Tile: button_3_scene not assigned")

func load_window(window_type: String, scene: PackedScene) -> void:
	"""Load a window scene, removing any existing window"""
	# Remove current window instance
	if current_window_instance:
		if content_container:
			content_container.remove_child(current_window_instance)
		current_window_instance.queue_free()
		current_window_instance = null
	
	current_window_type = window_type
	set_meta("window_type", window_type)
	
	# Instantiate new window
	current_window_instance = scene.instantiate()
	
	if not content_container:
		push_error("Tile: content_container not assigned!")
		return
	
	content_container.add_child(current_window_instance)
	
	print("Tile: Loaded window '%s'" % window_type)
	window_type_changed.emit(self, window_type)

func set_window_type(window_type: String) -> void:
	"""Set window type programmatically (for loading from layouts)"""
	if window_type == current_window_type:
		return
	
	# Match window type to button names
	if button_1 and button_1.name == window_type and button_1_scene:
		load_window(window_type, button_1_scene)
	elif button_2 and button_2.name == window_type and button_2_scene:
		load_window(window_type, button_2_scene)
	elif button_3 and button_3.name == window_type and button_3_scene:
		load_window(window_type, button_3_scene)
	else:
		# Window type not found, clear the window
		if current_window_instance:
			if content_container:
				content_container.remove_child(current_window_instance)
			current_window_instance.queue_free()
			current_window_instance = null
		
		current_window_type = ""
		set_meta("window_type", "")
		push_warning("Tile: Window type '%s' not found in buttons" % window_type)

func get_window_type() -> String:
	"""Get the current window type"""
	return current_window_type

func get_window_instance() -> Node:
	"""Get the current window instance"""
	return current_window_instance

func clear_window() -> void:
	"""Remove current window and leave tile empty"""
	if current_window_instance:
		if content_container:
			content_container.remove_child(current_window_instance)
		current_window_instance.queue_free()
		current_window_instance = null
	
	current_window_type = ""
	set_meta("window_type", "")
	window_type_changed.emit(self, "")
	print("Tile: Cleared window")
