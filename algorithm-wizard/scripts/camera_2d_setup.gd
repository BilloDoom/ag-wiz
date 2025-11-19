extends Camera2D

## Camera2D Setup Script - Applies settings to 2D camera

@export var initial_position: Vector2 = Vector2.ZERO
@export var initial_zoom: Vector2 = Vector2.ONE

func _ready():
	position = initial_position
	zoom = initial_zoom

func apply_settings(settings: Dictionary):
	"""Apply camera settings from dictionary"""

	# Camera position
	if settings.has("camera_position"):
		var pos = settings["camera_position"]
		if pos is Vector2:
			position = pos
		elif pos is Array and pos.size() == 2:
			position = Vector2(pos[0], pos[1])

	# Zoom level
	if settings.has("zoom"):
		var zoom_value = settings["zoom"]
		if zoom_value is float or zoom_value is int:
			zoom = Vector2(zoom_value, zoom_value)
		elif zoom_value is Vector2:
			zoom = zoom_value
