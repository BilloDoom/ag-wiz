extends Node

## ViewportManager - Singleton for managing viewport instances
## Handles creation, floating/docking, and closing of viewports

const MAX_VIEWPORTS = 9
const ViewportHolderScene = preload("res://viewports/viewport_holder.tscn")

# Viewport tracking
var holders: Dictionary = {}  # id -> ViewportHolder
var floating_windows: Dictionary = {}  # id -> Window

# Embedded grid container
var embedded_grid: GridContainer = null
var embedded_container: Control = null

func _ready():
	_create_embedded_grid()

func _create_embedded_grid():
	"""Create the embedded grid container for viewports"""
	if not embedded_container:
		push_warning("ViewportManager: No embedded container set, grid not created")
		return

	embedded_grid = GridContainer.new()
	embedded_grid.columns = 3
	embedded_grid.add_theme_constant_override("h_separation", 4)
	embedded_grid.add_theme_constant_override("v_separation", 4)
	embedded_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	embedded_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	embedded_container.add_child(embedded_grid)

func set_embedded_container(container: Control):
	"""Set the container where embedded viewports will be displayed"""
	embedded_container = container
	_create_embedded_grid()

func create_viewport(id: String, viewport_type: String, settings: Dictionary = {}) -> ViewportHolder:
	"""Create a new viewport with given ID and type ('3d' or '2d')"""

	# Check if ID already exists
	if holders.has(id):
		push_error("ViewportManager: Viewport with ID '%s' already exists" % id)
		return holders[id]

	# Check viewport limit
	if holders.size() >= MAX_VIEWPORTS:
		push_error("ViewportManager: Maximum of %d viewports reached" % MAX_VIEWPORTS)
		return null

	# Validate viewport type
	if viewport_type != "3d" and viewport_type != "2d":
		push_error("ViewportManager: Invalid viewport type '%s'. Use '3d' or '2d'" % viewport_type)
		return null

	# Instantiate holder from scene
	var holder = ViewportHolderScene.instantiate()
	holder.name = "ViewportHolder_" + id
	holders[id] = holder

	# Connect signals
	holder.close_requested.connect(_on_holder_close_requested)
	holder.float_requested.connect(_on_holder_float_requested)

	# Setup viewport
	holder.setup(id, viewport_type, settings)

	# Add to appropriate parent
	var should_float = settings.get("floating", false)
	if should_float:
		_make_floating(id)
	else:
		_make_embedded(id)

	print("ViewportManager: Created viewport '%s' (%s)" % [id, viewport_type])
	return holder

func create_empty_viewport(id: String) -> ViewportHolder:
	"""Create an empty viewport holder without configuring 3D/2D yet"""

	# Check if ID already exists
	if holders.has(id):
		push_error("ViewportManager: Viewport with ID '%s' already exists" % id)
		return holders[id]

	# Check viewport limit
	if holders.size() >= MAX_VIEWPORTS:
		push_error("ViewportManager: Maximum of %d viewports reached" % MAX_VIEWPORTS)
		return null

	# Instantiate holder from scene
	var holder = ViewportHolderScene.instantiate()
	holder.name = "ViewportHolder_" + id
	holders[id] = holder

	# Add to grid (always embedded initially) - this triggers _ready()
	embedded_grid.add_child(holder)

	# Connect signals (after adding to tree)
	holder.close_requested.connect(_on_holder_close_requested)
	holder.float_requested.connect(_on_holder_float_requested)

	# Set the ID (after _ready() has been called)
	holder.set_holder_id(id)

	print("ViewportManager: Created empty viewport holder '%s'" % id)
	return holder

func configure_viewport(id: String, viewport_type: String, settings: Dictionary = {}) -> bool:
	"""Configure an existing empty viewport with 3D/2D settings"""

	if not holders.has(id):
		push_error("ViewportManager: Viewport '%s' not found" % id)
		return false

	# Validate viewport type
	if viewport_type != "3d" and viewport_type != "2d":
		push_error("ViewportManager: Invalid viewport type '%s'. Use '3d' or '2d'" % viewport_type)
		return false

	var holder = holders[id]

	# Setup viewport with type and settings (automatically decouples existing scene)
	holder.setup(id, viewport_type, settings)

	# Handle floating if requested
	var should_float = settings.get("floating", false)
	if should_float and not holder.is_floating:
		_make_floating(id)

	print("ViewportManager: Configured viewport '%s' as %s" % [id, viewport_type])
	return true

func decouple_viewport(id: String) -> bool:
	"""Remove the 3D/2D scene from a viewport, keeping the holder alive"""

	if not holders.has(id):
		push_error("ViewportManager: Viewport '%s' not found" % id)
		return false

	var holder = holders[id]
	holder.decouple_viewport()

	print("ViewportManager: Decoupled viewport '%s'" % id)
	return true

func toggle_floating(id: String):
	"""Toggle viewport between embedded and floating"""
	if not holders.has(id):
		push_error("ViewportManager: Viewport '%s' not found" % id)
		return

	if floating_windows.has(id):
		# Currently floating, dock it
		_make_embedded(id)
	else:
		# Currently embedded, float it
		_make_floating(id)

func close_viewport(id: String):
	"""Close and remove viewport"""
	if not holders.has(id):
		push_error("ViewportManager: Viewport '%s' not found" % id)
		return

	var holder = holders[id]

	# Remove from floating window if needed
	if floating_windows.has(id):
		var window = floating_windows[id]
		window.queue_free()
		floating_windows.erase(id)

	# Remove from grid if embedded
	if holder.get_parent() == embedded_grid:
		embedded_grid.remove_child(holder)

	# Clean up holder
	holder.queue_free()
	holders.erase(id)

	print("ViewportManager: Closed viewport '%s'" % id)

func get_holder(id: String) -> ViewportHolder:
	"""Get ViewportHolder by ID"""
	return holders.get(id, null)

func get_render_root(id: String) -> Node:
	"""Get the RenderRoot node of a viewport by ID"""
	var holder = get_holder(id)
	if holder:
		return holder.get_render_root()
	push_error("ViewportManager: Viewport '%s' not found" % id)
	return null

func get_sub_viewport(id: String) -> SubViewport:
	"""Get the SubViewport of a viewport by ID"""
	var holder = get_holder(id)
	if holder:
		return holder.get_sub_viewport()
	return null

func get_camera(id: String) -> Node:
	"""Get the Camera node of a viewport by ID"""
	var holder = get_holder(id)
	if holder:
		return holder.get_camera()
	return null

func clear_viewport(id: String):
	"""Clear all objects from viewport's render root"""
	var holder = get_holder(id)
	if holder:
		holder.clear_scene()

func get_all_viewport_ids() -> Array:
	"""Get list of all viewport IDs"""
	return holders.keys()

# Internal methods

func _make_embedded(id: String):
	"""Move viewport to embedded grid"""
	if not holders.has(id):
		return

	var holder = holders[id]

	# Remove from floating window if exists
	if floating_windows.has(id):
		var window = floating_windows[id]
		window.remove_child(holder)
		window.queue_free()
		floating_windows.erase(id)

	# Add to grid if not already there
	if holder.get_parent() != embedded_grid:
		if holder.get_parent():
			holder.get_parent().remove_child(holder)
		embedded_grid.add_child(holder)

	holder.is_floating = false
	if holder.float_button:
		holder.float_button.text = "Float"

	print("ViewportManager: Docked viewport '%s'" % id)

func _make_floating(id: String):
	"""Move viewport to floating window"""
	if not holders.has(id):
		return

	var holder = holders[id]

	# Remove from grid
	if holder.get_parent() == embedded_grid:
		embedded_grid.remove_child(holder)

	# Create floating window
	var window = Window.new()
	window.title = "Viewport: " + id
	window.size = Vector2i(800, 600)
	window.close_requested.connect(func(): _on_window_close_requested(id))

	# Add window to scene tree
	get_tree().root.add_child(window)

	# Add holder to window
	window.add_child(holder)

	# Make holder fill the entire window
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Track window
	floating_windows[id] = window

	holder.is_floating = true
	if holder.float_button:
		holder.float_button.text = "Dock"

	# Show window
	window.show()

	print("ViewportManager: Floated viewport '%s'" % id)

# Signal handlers

func _on_holder_close_requested(holder_id: String):
	close_viewport(holder_id)

func _on_holder_float_requested(holder_id: String):
	toggle_floating(holder_id)

func _on_window_close_requested(holder_id: String):
	# Dock the viewport back when window is closed
	_make_embedded(holder_id)
