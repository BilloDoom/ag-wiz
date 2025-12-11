extends Node

## CameraController2D - Pan and zoom controls for 2D viewports
## Left-click drag to pan, scroll wheel to zoom
## Mouse wraps around viewport edges like Blender

var camera: Camera2D = null
var viewport_container: SubViewportContainer = null

# Pan/zoom settings
@export var pan_sensitivity: float = 1.0
@export var zoom_sensitivity: float = 0.1
@export var min_zoom: float = 0.1
@export var max_zoom: float = 10.0
@export var edge_wrap_margin: float = 10.0  # Pixels from edge to wrap

# State
var is_panning: bool = false
var mouse_inside: bool = false

func setup(cam: Camera2D, container: SubViewportContainer):
	"""Initialize controller with camera and viewport container"""
	camera = cam
	viewport_container = container

	# Connect viewport container signals
	if viewport_container:
		viewport_container.mouse_entered.connect(_on_mouse_entered)
		viewport_container.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	mouse_inside = true

func _on_mouse_exited():
	mouse_inside = false
	is_panning = false

func _input(event: InputEvent):
	if not camera or not mouse_inside:
		return

	# Left-click to pan
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_panning = event.pressed

		# Scroll wheel to zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.0 + zoom_sensitivity)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0 - zoom_sensitivity)

	# Mouse motion for panning
	elif event is InputEventMouseMotion and is_panning:
		var delta = -event.relative * pan_sensitivity / camera.zoom.x
		camera.global_position += delta

		# Edge wrapping (like Blender)
		_wrap_mouse_at_edges()

func _zoom_camera(factor: float):
	"""Zoom camera by given factor"""
	if not camera:
		return

	var new_zoom = camera.zoom * factor
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	camera.zoom = new_zoom

func reset_camera():
	"""Reset camera to default position and zoom"""
	if camera:
		camera.global_position = Vector2.ZERO
		camera.zoom = Vector2.ONE

func _wrap_mouse_at_edges():
	"""Wrap mouse position when it reaches viewport edges (Blender-style)"""
	if not viewport_container or not is_panning:
		return

	var mouse_pos = viewport_container.get_local_mouse_position()
	var container_size = viewport_container.size
	var new_pos = mouse_pos
	var wrapped = false

	# Check horizontal edges
	if mouse_pos.x < edge_wrap_margin:
		new_pos.x = container_size.x - edge_wrap_margin - 1
		wrapped = true
	elif mouse_pos.x > container_size.x - edge_wrap_margin:
		new_pos.x = edge_wrap_margin + 1
		wrapped = true

	# Check vertical edges
	if mouse_pos.y < edge_wrap_margin:
		new_pos.y = container_size.y - edge_wrap_margin - 1
		wrapped = true
	elif mouse_pos.y > container_size.y - edge_wrap_margin:
		new_pos.y = edge_wrap_margin + 1
		wrapped = true

	# Warp mouse if needed
	if wrapped:
		var global_pos = viewport_container.global_position + new_pos
		viewport_container.warp_mouse(new_pos)
