class_name ViewportHolder extends Control

## ViewportHolder - Reusable wrapper for viewport instances
## This script should be attached to the viewport_holder.tscn root node

# Signals
signal close_requested(holder_id: String)
signal float_requested(holder_id: String)

# Properties
var holder_id: String = ""
var viewport_scene: SubViewport = null
var render_root: Node = null
var camera: Node = null
var camera_controller: Node = null
var is_3d: bool = false
var is_floating: bool = false

# UI Elements (from scene)
@onready var viewport_container: SubViewportContainer = $PanelContainer/VBoxContainer/SubViewportContainer
@onready var id_label: Label = $PanelContainer/VBoxContainer/TitleBar/HBoxContainer/IDLabel
@onready var float_button: Button = $PanelContainer/VBoxContainer/TitleBar/HBoxContainer/FloatBtn
@onready var close_button: Button = $PanelContainer/VBoxContainer/TitleBar/HBoxContainer/CloseBtn

const VIEWPORT_3D_PATH = "res://viewports/3d_viewport.tscn"
const VIEWPORT_2D_PATH = "res://viewports/2d_viewport.tscn"
const CAMERA_CONTROLLER_3D = preload("res://scripts/camera_controller_3d.gd")
const CAMERA_CONTROLLER_2D = preload("res://scripts/camera_controller_2d.gd")

func _ready():
	custom_minimum_size = Vector2(400, 300)

	# Connect button signals
	if float_button:
		float_button.pressed.connect(_on_float_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func setup(id: String, viewport_type: String, settings: Dictionary):
	"""Initialize viewport with given ID, type ('3d' or '2d'), and settings"""
	holder_id = id
	is_3d = (viewport_type == "3d")

	if id_label:
		id_label.text = id

	# Load viewport template
	var template_path = VIEWPORT_3D_PATH if is_3d else VIEWPORT_2D_PATH
	var template = load(template_path)
	if not template:
		push_error("ViewportHolder: Failed to load template: " + template_path)
		return

	viewport_scene = template.instantiate()
	if not viewport_scene:
		push_error("ViewportHolder: Failed to instantiate viewport template")
		return

	viewport_container.add_child(viewport_scene)

	# Find render root
	render_root = viewport_scene.get_node_or_null("RenderRoot")
	if not render_root:
		push_warning("ViewportHolder: RenderRoot not found in template")

	# Find camera
	camera = viewport_scene.get_node_or_null("Camera3D" if is_3d else "Camera2D")
	if not camera:
		push_warning("ViewportHolder: Camera not found in template")

	# Apply settings
	_apply_settings(settings)

	# Setup camera controller if requested
	if settings.get("orbit_controls", false):
		_setup_camera_controller()

func _apply_settings(settings: Dictionary):
	"""Apply viewport settings (MSAA, TAA, camera, etc.)"""
	if not viewport_scene:
		return

	# Anti-aliasing
	if settings.has("msaa"):
		var msaa_value = settings["msaa"]
		match msaa_value:
			0: viewport_scene.msaa_3d = Viewport.MSAA_DISABLED
			2: viewport_scene.msaa_3d = Viewport.MSAA_2X
			4: viewport_scene.msaa_3d = Viewport.MSAA_4X
			8: viewport_scene.msaa_3d = Viewport.MSAA_8X

	if settings.get("taa", false):
		viewport_scene.use_taa = true

	# Camera settings
	if camera and camera.has_method("apply_settings"):
		camera.apply_settings(settings)

	# Background color (for 2D or override)
	if settings.has("background_color"):
		var env = viewport_scene.get_node_or_null("WorldEnvironment")
		if env and env.environment:
			env.environment.background_color = settings["background_color"]

	# Store floating preference
	is_floating = settings.get("floating", false)

func _setup_camera_controller():
	"""Attach camera controller to viewport"""
	if not camera:
		return

	if camera_controller:
		camera_controller.queue_free()
		camera_controller = null

	if is_3d:
		camera_controller = Node.new()
		camera_controller.set_script(CAMERA_CONTROLLER_3D)
		camera_controller.name = "CameraController3D"
	else:
		camera_controller = Node.new()
		camera_controller.set_script(CAMERA_CONTROLLER_2D)
		camera_controller.name = "CameraController2D"

	add_child(camera_controller)
	camera_controller.setup(camera, viewport_container)

func get_render_root() -> Node:
	"""Get the RenderRoot node where objects should be added"""
	return render_root

func get_sub_viewport() -> SubViewport:
	"""Get the SubViewport instance"""
	return viewport_scene

func get_camera() -> Node:
	"""Get the Camera node (Camera3D or Camera2D)"""
	return camera

func clear_scene():
	"""Remove all children from render root"""
	if render_root:
		for child in render_root.get_children():
			child.queue_free()

func _process(_delta):
	# Update viewport size to match container
	if viewport_scene and viewport_container:
		var container_size = viewport_container.size
		if viewport_scene.size != container_size:
			viewport_scene.size = container_size

func _on_float_pressed():
	float_requested.emit(holder_id)

func _on_close_pressed():
	close_requested.emit(holder_id)
