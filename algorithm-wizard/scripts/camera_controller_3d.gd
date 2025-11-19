extends Node

## CameraController3D - Orbit camera controls for 3D viewports
## Right-click drag to rotate, scroll wheel to zoom

var camera: Camera3D = null
var viewport_container: SubViewportContainer = null

# Orbit settings
var target: Vector3 = Vector3.ZERO
var distance: float = 10.0
var yaw: float = 0.0  # Horizontal rotation (degrees)
var pitch: float = -30.0  # Vertical rotation (degrees)

# Control settings
@export var rotate_sensitivity: float = 0.3
@export var zoom_sensitivity: float = 0.5
@export var min_distance: float = 2.0
@export var max_distance: float = 50.0
@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0

# State
var is_rotating: bool = false
var mouse_inside: bool = false

func setup(cam: Camera3D, container: SubViewportContainer):
	"""Initialize controller with camera and viewport container"""
	camera = cam
	viewport_container = container

	if camera:
		# Calculate initial orbit parameters from camera position
		var cam_pos = camera.global_position
		target = Vector3.ZERO  # Default target

		# Try to find target from camera's look direction
		if camera.global_transform.basis.z != Vector3.ZERO:
			var forward = -camera.global_transform.basis.z.normalized()
			# Estimate distance
			distance = cam_pos.length()

		# Calculate yaw and pitch from camera position
		var rel_pos = cam_pos - target
		distance = rel_pos.length()
		yaw = rad_to_deg(atan2(rel_pos.x, rel_pos.z))
		pitch = rad_to_deg(asin(-rel_pos.y / distance)) if distance > 0 else -30.0

		_update_camera_position()

	# Connect viewport container signals
	if viewport_container:
		viewport_container.mouse_entered.connect(_on_mouse_entered)
		viewport_container.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	mouse_inside = true

func _on_mouse_exited():
	mouse_inside = false
	is_rotating = false

func _input(event: InputEvent):
	if not camera or not mouse_inside:
		return

	# Right-click drag to rotate
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
			if is_rotating:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		# Scroll wheel to zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - zoom_sensitivity, min_distance, max_distance)
			_update_camera_position()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + zoom_sensitivity, min_distance, max_distance)
			_update_camera_position()

	# Mouse motion for rotation
	elif event is InputEventMouseMotion and is_rotating:
		yaw -= event.relative.x * rotate_sensitivity
		pitch -= event.relative.y * rotate_sensitivity
		pitch = clamp(pitch, min_pitch, max_pitch)
		_update_camera_position()

func _update_camera_position():
	"""Update camera position based on orbit parameters"""
	if not camera:
		return

	# Convert to radians
	var yaw_rad = deg_to_rad(yaw)
	var pitch_rad = deg_to_rad(pitch)

	# Calculate position on sphere
	var x = distance * cos(pitch_rad) * sin(yaw_rad)
	var y = distance * -sin(pitch_rad)
	var z = distance * cos(pitch_rad) * cos(yaw_rad)

	camera.global_position = target + Vector3(x, y, z)
	camera.look_at(target, Vector3.UP)

func set_target(new_target: Vector3):
	"""Set orbit target position"""
	target = new_target
	_update_camera_position()

func set_distance(new_distance: float):
	"""Set camera distance from target"""
	distance = clamp(new_distance, min_distance, max_distance)
	_update_camera_position()

func reset_to_defaults():
	"""Reset camera to default orbit position"""
	yaw = 45.0
	pitch = -30.0
	distance = 10.0
	target = Vector3.ZERO
	_update_camera_position()
