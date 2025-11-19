extends Camera3D

## Camera3D Setup Script - Applies settings to 3D camera

@export var initial_position: Vector3 = Vector3(10, 10, 10)
@export var look_at_target: Vector3 = Vector3.ZERO

func _ready():
	position = initial_position
	look_at(look_at_target)

func apply_settings(settings: Dictionary):
	"""Apply camera settings from dictionary"""

	# Camera position
	if settings.has("camera_position"):
		var pos = settings["camera_position"]
		if pos is Vector3:
			position = pos
		elif pos is Array and pos.size() == 3:
			position = Vector3(pos[0], pos[1], pos[2])

	# Look at target
	if settings.has("camera_target"):
		var target = settings["camera_target"]
		if target is Vector3:
			look_at(target)
		elif target is Array and target.size() == 3:
			look_at(Vector3(target[0], target[1], target[2]))

	# Field of view
	if settings.has("fov"):
		fov = settings["fov"]

	# Near/far clip planes
	if settings.has("near"):
		near = settings["near"]

	if settings.has("far"):
		far = settings["far"]

	# Camera distance (for orbit controller setup)
	if settings.has("camera_distance"):
		var distance = settings["camera_distance"]
		# Adjust position to be at specified distance from target
		var target_pos = look_at_target
		if settings.has("camera_target"):
			var t = settings["camera_target"]
			if t is Vector3:
				target_pos = t
			elif t is Array and t.size() == 3:
				target_pos = Vector3(t[0], t[1], t[2])

		var direction = (position - target_pos).normalized()
		position = target_pos + direction * distance
