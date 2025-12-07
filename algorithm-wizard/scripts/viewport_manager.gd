extends Node

## ViewportManager - Singleton for managing scenes and cameras
## Viewports are managed by tiles, this only tracks scenes and cameras

# Viewport tracking (for camera assignment only)
var holders: Dictionary = {}  # id -> ViewportHolder (registered by tiles)

# Scene tracking (shared World3D/World2D instances)
var scenes: Dictionary = {}  # scene_id -> {type: "3d"/"2d", world: World3D/World2D, root: Node3D/Node2D}
var scene_counter: int = 0

# Camera tracking
var cameras: Dictionary = {}  # camera_name -> {port_id, scene_id, subviewport, camera_node}

# Scene context for Python "with" statement
var current_scene_context: String = ""

func get_holder(id: String) -> ViewportHolder:
	"""Get ViewportHolder by ID"""
	return holders.get(id, null)

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

# Drawing API Wrappers (delegates to DrawingAPI3D and DrawingAPI2D)
# These wrappers allow the Python bridge to continue working without rebuilding

var drawing_api_3d: Node = null
var drawing_api_2d: Node = null

func _ensure_drawing_apis():
	"""Lazy initialization of drawing API instances"""
	if not drawing_api_3d:
		var DrawingAPI3D = load("res://scripts/drawing_api/drawing_api_3d.gd")
		drawing_api_3d = DrawingAPI3D.new()
		add_child(drawing_api_3d)

	if not drawing_api_2d:
		var DrawingAPI2D = load("res://scripts/drawing_api/drawing_api_2d.gd")
		drawing_api_2d = DrawingAPI2D.new()
		add_child(drawing_api_2d)

# 3D Drawing Wrappers

func draw_box(size: Vector3, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	_ensure_drawing_apis()
	return drawing_api_3d.draw_box(size, position, rotation, color)

func draw_sphere(radius: float, position: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	_ensure_drawing_apis()
	return drawing_api_3d.draw_sphere(radius, position, color)

func draw_cylinder(radius: float, height: float, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	_ensure_drawing_apis()
	return drawing_api_3d.draw_cylinder(radius, height, position, rotation, color)

func draw_torus(inner_radius: float, outer_radius: float, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	_ensure_drawing_apis()
	return drawing_api_3d.draw_torus(inner_radius, outer_radius, position, rotation, color)

func create_mesh_builder_3d(position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO) -> Dictionary:
	_ensure_drawing_apis()
	return drawing_api_3d.create_mesh_builder_3d(position, rotation)

func build_mesh_3d(vertices: Array, indices: Array = [], normals: Array = [], colors: Array = [], uvs: Array = [], position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	_ensure_drawing_apis()
	return drawing_api_3d.build_mesh_3d(vertices, indices, normals, colors, uvs, position, rotation, color)

# 2D Drawing Wrappers

func draw_rect_2d(size: Vector2, position: Vector2 = Vector2.ZERO, rotation: float = 0.0, color: Color = Color.WHITE, filled: bool = true) -> Node2D:
	_ensure_drawing_apis()
	return drawing_api_2d.draw_rect_2d(size, position, rotation, color, filled)

func draw_circle_2d(radius: float, position: Vector2 = Vector2.ZERO, color: Color = Color.WHITE, filled: bool = true, segments: int = 32) -> Node2D:
	_ensure_drawing_apis()
	return drawing_api_2d.draw_circle_2d(radius, position, color, filled, segments)

func draw_line_2d(from_pos: Vector2, to_pos: Vector2, color: Color = Color.WHITE, width: float = 1.0) -> Node2D:
	_ensure_drawing_apis()
	return drawing_api_2d.draw_line_2d(from_pos, to_pos, color, width)

func draw_polygon_2d(points: Array, position: Vector2 = Vector2.ZERO, rotation: float = 0.0, color: Color = Color.WHITE, filled: bool = true) -> Node2D:
	_ensure_drawing_apis()
	return drawing_api_2d.draw_polygon_2d(points, position, rotation, color, filled)

func build_mesh_2d(vertices: Array, colors: Array = [], uvs: Array = [], position: Vector2 = Vector2.ZERO, rotation: float = 0.0, color: Color = Color.WHITE) -> Polygon2D:
	_ensure_drawing_apis()
	return drawing_api_2d.build_mesh_2d(vertices, colors, uvs, position, rotation, color)
