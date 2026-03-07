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

	# Create environment for the 3D world
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()

	# Configure sky
	var sky_material = environment.sky.sky_material as ProceduralSkyMaterial
	sky_material.sky_top_color = Color(0.385, 0.454, 0.55)  # Light blue
	sky_material.sky_horizon_color = Color(0.646, 0.656, 0.67)  # Horizon
	sky_material.ground_bottom_color = Color(0.2, 0.169, 0.133)  # Dark ground
	sky_material.ground_horizon_color = Color(0.646, 0.656, 0.67)

	# Ambient light
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.5

	world.environment = environment

	# Create a root node for this scene where objects will be added
	var root = Node3D.new()
	root.name = "SceneRoot_" + scene_id

	# Add DirectionalLight3D (sun)
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.0
	sun.light_color = Color.WHITE
	sun.rotation_degrees = Vector3(-45, 45, 0)  # Angle from top-right
	sun.shadow_enabled = true
	root.add_child(sun)

	scenes[scene_id] = {
		"type": "3d",
		"world": world,
		"root": root
	}

	print("ViewportManager: Created 3D scene '%s' with environment and sun" % scene_id)
	return scene_id

func create_scene_2d() -> String:
	"""Create a new 2D scene (World2D) that can be shared across viewports"""
	scene_counter += 1
	var scene_id = "scene_2d_" + str(scene_counter)

	var world = World2D.new()

	# Create a root node for this scene where objects will be added
	var root = Node2D.new()
	root.name = "SceneRoot_" + scene_id

	# Create a CanvasLayer for UI elements (on top of everything)
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 100  # High layer to ensure UI is on top
	root.add_child(ui_layer)

	scenes[scene_id] = {
		"type": "2d",
		"world": world,
		"root": root,
		"ui_layer": ui_layer
	}

	print("ViewportManager: Created 2D scene '%s' with UI layer" % scene_id)
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

# UI Label API for 2D Scenes

func create_ui_label(label_id: String, text: String, position: Vector2, font_size: int = 16, color: Color = Color.WHITE, scene_id: String = "") -> Node:
	"""Create a simple UI label on the canvas layer"""
	var target_scene_id = scene_id if scene_id != "" else current_scene_context

	if target_scene_id == "":
		push_error("ViewportManager: No scene context for UI label creation")
		return null

	if not scenes.has(target_scene_id):
		push_error("ViewportManager: Scene '%s' not found" % target_scene_id)
		return null

	var scene_data = scenes[target_scene_id]
	if scene_data["type"] != "2d":
		push_error("ViewportManager: UI labels only supported for 2D scenes")
		return null

	if not scene_data.has("ui_layer"):
		push_error("ViewportManager: Scene missing UI layer")
		return null

	# Load UILabel class
	var UILabelClass = load("res://scripts/ui_label.gd")
	var label = UILabelClass.new()
	label.setup(label_id, text, position, font_size, color)
	label.name = label_id

	# Add to UI layer
	scene_data["ui_layer"].add_child(label)

	print("ViewportManager: Created UI label '%s' in scene '%s'" % [label_id, target_scene_id])
	return label

func draw_ui_line(line_id: String, from_pos: Vector2, to_pos: Vector2, color: Color = Color.WHITE, width: float = 2.0, scene_id: String = "") -> Node:
	"""Draw a line on the UI canvas layer"""
	var target_scene_id = scene_id if scene_id != "" else current_scene_context

	if target_scene_id == "":
		push_error("ViewportManager: No scene context for UI line")
		return null

	if not scenes.has(target_scene_id):
		push_error("ViewportManager: Scene '%s' not found" % target_scene_id)
		return null

	var scene_data = scenes[target_scene_id]
	if scene_data["type"] != "2d":
		push_error("ViewportManager: UI lines only supported for 2D scenes")
		return null

	if not scene_data.has("ui_layer"):
		push_error("ViewportManager: Scene missing UI layer")
		return null

	# Create a Line2D on the UI layer
	var line = Line2D.new()
	line.name = line_id
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.default_color = color
	line.width = width
	line.z_index = 1

	scene_data["ui_layer"].add_child(line)
	print("ViewportManager: Created UI line '%s' in scene '%s'" % [line_id, target_scene_id])
	return line

func draw_ui_box(box_id: String, rect: Rect2, color: Color = Color.WHITE, width: float = 2.0, scene_id: String = "") -> Node:
	"""Draw a bounding box on the UI canvas layer"""
	var target_scene_id = scene_id if scene_id != "" else current_scene_context

	if target_scene_id == "":
		push_error("ViewportManager: No scene context for UI box")
		return null

	if not scenes.has(target_scene_id):
		push_error("ViewportManager: Scene '%s' not found" % target_scene_id)
		return null

	var scene_data = scenes[target_scene_id]
	if scene_data["type"] != "2d":
		push_error("ViewportManager: UI boxes only supported for 2D scenes")
		return null

	if not scene_data.has("ui_layer"):
		push_error("ViewportManager: Scene missing UI layer")
		return null

	# Create a Line2D to draw the box outline
	var line = Line2D.new()
	line.name = box_id
	line.add_point(rect.position)  # Top-left
	line.add_point(Vector2(rect.position.x + rect.size.x, rect.position.y))  # Top-right
	line.add_point(rect.position + rect.size)  # Bottom-right
	line.add_point(Vector2(rect.position.x, rect.position.y + rect.size.y))  # Bottom-left
	line.add_point(rect.position)  # Back to top-left (close the box)
	line.default_color = color
	line.width = width
	line.closed = true
	line.z_index = 1

	scene_data["ui_layer"].add_child(line)
	print("ViewportManager: Created UI box '%s' in scene '%s'" % [box_id, target_scene_id])
	return line
