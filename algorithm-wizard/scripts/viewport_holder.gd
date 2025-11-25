class_name ViewportHolder extends Control

## ViewportHolder - Reusable wrapper for viewport instances
## This script should be attached to the viewport_holder.tscn root node

# Signals
signal close_requested(holder_id: String)
signal float_requested(holder_id: String)

# Properties
var holder_id: String = ""
var is_floating: bool = false

# Camera tracking (multiple SubViewports, each with a camera)
var camera_subviewports: Dictionary = {}  # camera_name -> {subviewport: SubViewport, camera: Camera3D/Camera2D, controller: Node}

# UI Elements (from scene)
@onready var viewport_container: SubViewportContainer = $PanelContainer/VBoxContainer/SubViewportContainer
@onready var id_label: Label = $PanelContainer/VBoxContainer/TitleBar/HBoxContainer/IDLabel
@onready var float_button: Button = $PanelContainer/VBoxContainer/TitleBar/HBoxContainer/FloatBtn
@onready var close_button: Button = $PanelContainer/VBoxContainer/TitleBar/HBoxContainer/CloseBtn

const CAMERA_CONTROLLER_3D = preload("res://scripts/camera_controller_3d.gd")
const CAMERA_CONTROLLER_2D = preload("res://scripts/camera_controller_2d.gd")

func _ready():
	custom_minimum_size = Vector2(400, 300)

	# Disable stretch to allow manual viewport sizing
	if viewport_container:
		viewport_container.stretch = false

	# Connect button signals
	if float_button:
		float_button.pressed.connect(_on_float_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func set_holder_id(id: String):
	"""Set the holder ID and update label"""
	holder_id = id
	if id_label:
		id_label.text = id

func add_camera_subviewport(camera_name: String, world, scene_type: String, settings: Dictionary) -> Dictionary:
	"""Add a SubViewport with a camera viewing the shared world"""

	# Check if camera already exists in this holder
	if camera_subviewports.has(camera_name):
		push_error("ViewportHolder '%s': Camera '%s' already exists in this holder" % [holder_id, camera_name])
		return {}

	var is_3d = (scene_type == "3d")

	# Create SubViewport
	var subviewport = SubViewport.new()
	subviewport.name = "SubViewport_" + camera_name
	subviewport.size = Vector2i(viewport_container.size)
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Get the scene root from ViewportManager and add it to this subviewport FIRST
	var scene_id = settings.get("scene_id", "")
	if scene_id != "":
		var viewport_manager = get_node("/root/ViewportManager")
		if viewport_manager:
			var scene_root = viewport_manager.get_scene_root(scene_id)
			if scene_root and not scene_root.get_parent():
				subviewport.add_child(scene_root)

	# Assign shared world
	if is_3d:
		subviewport.world_3d = world
		# Configure 3D rendering
		if settings.has("msaa"):
			var msaa_value = settings["msaa"]
			match msaa_value:
				0: subviewport.msaa_3d = Viewport.MSAA_DISABLED
				2: subviewport.msaa_3d = Viewport.MSAA_2X
				4: subviewport.msaa_3d = Viewport.MSAA_4X
				8: subviewport.msaa_3d = Viewport.MSAA_8X
		if settings.get("taa", false):
			subviewport.use_taa = true
	else:
		subviewport.world_2d = world

	viewport_container.add_child(subviewport)

	# Create camera
	var camera: Node = null
	if is_3d:
		camera = Camera3D.new()
		camera.name = camera_name
		# Apply position/rotation
		if settings.has("position"):
			var pos = settings["position"]
			if pos is Vector3:
				camera.position = pos
			elif pos is Array and pos.size() == 3:
				camera.position = Vector3(pos[0], pos[1], pos[2])
		if settings.has("rotation"):
			var rot = settings["rotation"]
			if rot is Vector3:
				camera.rotation = rot
			elif rot is Array and rot.size() == 3:
				camera.rotation = Vector3(rot[0], rot[1], rot[2])
		camera.current = true
	else:
		camera = Camera2D.new()
		camera.name = camera_name
		# Apply position/zoom
		if settings.has("position"):
			var pos = settings["position"]
			if pos is Vector2:
				camera.position = pos
			elif pos is Array and pos.size() == 2:
				camera.position = Vector2(pos[0], pos[1])
		if settings.has("zoom"):
			var zoom_val = settings["zoom"]
			if zoom_val is float or zoom_val is int:
				camera.zoom = Vector2(zoom_val, zoom_val)
		camera.enabled = true

	subviewport.add_child(camera)

	# Setup camera controller if requested
	var camera_controller: Node = null
	if settings.get("orbit_controls", false) or settings.get("pan_controls", false):
		if is_3d:
			camera_controller = Node.new()
			camera_controller.set_script(CAMERA_CONTROLLER_3D)
			camera_controller.name = "CameraController3D_" + camera_name
		else:
			camera_controller = Node.new()
			camera_controller.set_script(CAMERA_CONTROLLER_2D)
			camera_controller.name = "CameraController2D_" + camera_name

		add_child(camera_controller)
		camera_controller.setup(camera, viewport_container)

	# Track this camera
	camera_subviewports[camera_name] = {
		"subviewport": subviewport,
		"camera": camera,
		"controller": camera_controller
	}

	print("ViewportHolder '%s': Added camera '%s' (%s)" % [holder_id, camera_name, scene_type])

	return {
		"subviewport": subviewport,
		"camera": camera
	}

func remove_camera_subviewport(camera_name: String):
	"""Remove a camera's SubViewport from this holder"""
	if not camera_subviewports.has(camera_name):
		return

	var data = camera_subviewports[camera_name]

	# Remove controller if exists
	if data["controller"]:
		data["controller"].queue_free()

	# Remove subviewport (camera is child so will be freed too)
	if data["subviewport"]:
		data["subviewport"].queue_free()

	camera_subviewports.erase(camera_name)
	print("ViewportHolder '%s': Removed camera '%s'" % [holder_id, camera_name])

func get_camera_node(camera_name: String) -> Node:
	"""Get a specific camera node by name"""
	if camera_subviewports.has(camera_name):
		return camera_subviewports[camera_name]["camera"]
	return null

func _process(_delta):
	# Update all subviewport sizes to match container
	if viewport_container:
		var container_size = Vector2i(viewport_container.size)
		for camera_name in camera_subviewports:
			var subviewport = camera_subviewports[camera_name]["subviewport"]
			if subviewport and subviewport.size != container_size:
				subviewport.size = container_size

func _on_float_pressed():
	float_requested.emit(holder_id)

func _on_close_pressed():
	close_requested.emit(holder_id)
