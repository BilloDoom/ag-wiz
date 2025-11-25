extends Node

## ViewportManager - Singleton for managing viewport instances
## Handles creation, floating/docking, and closing of viewports

const MAX_VIEWPORTS = 9
const ViewportHolderScene = preload("res://viewports/viewport_holder.tscn")

# Viewport tracking
var holders: Dictionary = {}  # id -> ViewportHolder
var floating_windows: Dictionary = {}  # id -> Window

# Scene tracking (shared World3D/World2D instances)
var scenes: Dictionary = {}  # scene_id -> {type: "3d"/"2d", world: World3D/World2D, root: Node3D/Node2D}
var scene_counter: int = 0

# Camera tracking
var cameras: Dictionary = {}  # camera_name -> {port_id, scene_id, subviewport, camera_node}

# Scene context for Python "with" statement
var current_scene_context: String = ""

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

func cleanup_all_scenes() -> void:
	"""Clean up all scenes, cameras, and reset counters - called before each script execution"""
	print("ViewportManager: Cleaning up all scenes and cameras")

	# Remove all cameras from holders
	for camera_name in cameras.keys():
		var camera_data = cameras[camera_name]
		var holder = holders.get(camera_data["port_id"])
		if holder:
			holder.remove_camera_subviewport(camera_name)

	# Clear camera tracking
	cameras.clear()

	# Clean up all scene roots
	for scene_id in scenes.keys():
		var scene_data = scenes[scene_id]
		if scene_data.has("root") and scene_data["root"]:
			var root = scene_data["root"]
			# Remove all children from root
			for child in root.get_children():
				child.queue_free()
			# Queue free the root itself if it has a parent
			if root.get_parent():
				root.get_parent().remove_child(root)
			root.queue_free()

	# Clear scene tracking
	scenes.clear()

	# Reset counters
	scene_counter = 0

	# Clear scene context
	current_scene_context = ""

	print("ViewportManager: Cleanup complete")

func create_scene_3d() -> String:
	"""Create a new 3D scene (World3D) that can be shared across viewports"""
	scene_counter += 1
	var scene_id = "scene_3d_" + str(scene_counter)

	var world = World3D.new()

	# Create a root node for this scene where objects will be added
	var root = Node3D.new()
	root.name = "SceneRoot_" + scene_id

	scenes[scene_id] = {
		"type": "3d",
		"world": world,
		"root": root
	}

	print("ViewportManager: Created 3D scene '%s'" % scene_id)
	return scene_id

func create_scene_2d() -> String:
	"""Create a new 2D scene (World2D) that can be shared across viewports"""
	scene_counter += 1
	var scene_id = "scene_2d_" + str(scene_counter)

	var world = World2D.new()

	# Create a root node for this scene where objects will be added
	var root = Node2D.new()
	root.name = "SceneRoot_" + scene_id

	scenes[scene_id] = {
		"type": "2d",
		"world": world,
		"root": root
	}

	print("ViewportManager: Created 2D scene '%s'" % scene_id)
	return scene_id

func add_camera_to_viewport(camera_name: String, port_id: String, scene_id: String, settings: Dictionary = {}) -> bool:
	"""Add a camera to a viewport, viewing the specified scene"""

	# Check if camera name already exists
	if cameras.has(camera_name):
		push_error("ViewportManager: Camera '%s' already exists" % camera_name)
		return false

	# Check if viewport exists
	if not holders.has(port_id):
		push_error("ViewportManager: Viewport '%s' not found" % port_id)
		return false

	# Check if scene exists
	if not scenes.has(scene_id):
		push_error("ViewportManager: Scene '%s' not found" % scene_id)
		return false

	var holder = holders[port_id]
	var scene_data = scenes[scene_id]

	# Pass scene_id in settings so holder can get the scene root
	var holder_settings = settings.duplicate()
	holder_settings["scene_id"] = scene_id

	# Create SubViewport + Camera in the holder
	var result = holder.add_camera_subviewport(camera_name, scene_data["world"], scene_data["type"], holder_settings)

	if result:
		# Track camera
		cameras[camera_name] = {
			"port_id": port_id,
			"scene_id": scene_id,
			"subviewport": result["subviewport"],
			"camera_node": result["camera"]
		}

		print("ViewportManager: Added camera '%s' to viewport '%s' viewing scene '%s'" % [camera_name, port_id, scene_id])
		return true
	else:
		push_error("ViewportManager: Failed to add camera '%s' to viewport '%s'" % [camera_name, port_id])
		return false

func remove_camera(camera_name: String) -> bool:
	"""Remove a camera from its viewport"""
	if not cameras.has(camera_name):
		push_error("ViewportManager: Camera '%s' not found" % camera_name)
		return false

	var camera_data = cameras[camera_name]
	var holder = holders.get(camera_data["port_id"])

	if holder:
		holder.remove_camera_subviewport(camera_name)

	cameras.erase(camera_name)
	print("ViewportManager: Removed camera '%s'" % camera_name)
	return true

func get_camera_node(camera_name: String) -> Node:
	"""Get the Camera node by name"""
	if cameras.has(camera_name):
		return cameras[camera_name]["camera_node"]
	return null

# Scene context management (for Python "with" statement)

func enter_scene_context(scene_id: String) -> bool:
	"""Enter a scene context for drawing operations"""
	if not scenes.has(scene_id):
		push_error("ViewportManager: Scene '%s' not found" % scene_id)
		return false

	current_scene_context = scene_id
	return true

func exit_scene_context():
	"""Exit the current scene context"""
	current_scene_context = ""

func get_scene_root(scene_id: String) -> Node:
	"""Get the root node of a scene where objects should be added"""
	if scenes.has(scene_id):
		return scenes[scene_id]["root"]
	return null

func get_current_scene_root() -> Node:
	"""Get the root node of the current context scene"""
	if current_scene_context != "":
		return get_scene_root(current_scene_context)
	return null

# Primitive drawing functions

func draw_box(size: Vector3, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	"""Draw a box primitive in the current scene context"""
	var root = get_current_scene_root()
	if not root:
		push_error("ViewportManager: No scene context active. Use 'with scene:' in Python")
		return null

	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size

	mesh_instance.mesh = box_mesh
	mesh_instance.position = position
	mesh_instance.rotation = rotation

	# Create material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)

	root.add_child(mesh_instance)
	print("ViewportManager: Added box to scene '%s'" % current_scene_context)
	return mesh_instance

func draw_sphere(radius: float, position: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	"""Draw a sphere primitive in the current scene context"""
	var root = get_current_scene_root()
	if not root:
		push_error("ViewportManager: No scene context active. Use 'with scene:' in Python")
		return null

	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0

	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = position

	# Create material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)

	root.add_child(mesh_instance)
	print("ViewportManager: Added sphere to scene '%s'" % current_scene_context)
	return mesh_instance

func draw_cylinder(radius: float, height: float, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	"""Draw a cylinder primitive in the current scene context"""
	var root = get_current_scene_root()
	if not root:
		push_error("ViewportManager: No scene context active. Use 'with scene:' in Python")
		return null

	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height

	mesh_instance.mesh = cylinder_mesh
	mesh_instance.position = position
	mesh_instance.rotation = rotation

	# Create material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)

	root.add_child(mesh_instance)
	print("ViewportManager: Added cylinder to scene '%s'" % current_scene_context)
	return mesh_instance

func draw_torus(inner_radius: float, outer_radius: float, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	"""Draw a torus primitive in the current scene context"""
	var root = get_current_scene_root()
	if not root:
		push_error("ViewportManager: No scene context active. Use 'with scene:' in Python")
		return null

	var mesh_instance = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = inner_radius
	torus_mesh.outer_radius = outer_radius

	mesh_instance.mesh = torus_mesh
	mesh_instance.position = position
	mesh_instance.rotation = rotation

	# Create material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)

	root.add_child(mesh_instance)
	print("ViewportManager: Added torus to scene '%s'" % current_scene_context)
	return mesh_instance

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
