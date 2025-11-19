extends Node

## CameraController2D - Pan and zoom controls for 2D viewports
## Right-click or middle-click drag to pan, scroll wheel to zoom

var camera: Camera2D = null
var viewport_container: SubViewportContainer = null

# Pan/zoom settings
@export var pan_sensitivity: float = 1.0
@export var zoom_sensitivity: float = 0.1
@export var min_zoom: float = 0.1
@export var max_zoom: float = 10.0

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

	# Right-click or middle-click to pan
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			if is_panning:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		# Scroll wheel to zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.0 + zoom_sensitivity)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0 - zoom_sensitivity)

	# Mouse motion for panning
	elif event is InputEventMouseMotion and is_panning:
		var delta = -event.relative * pan_sensitivity / camera.zoom.x
		camera.global_position += delta

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
