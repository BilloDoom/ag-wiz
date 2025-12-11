extends Node

## AnimationManager - Singleton for managing Manim-like animations
## Handles animation queue and playback

# Animation queue - array of animation dictionaries
var animation_queue: Array = []

# Active tweens
var active_tweens: Array = []

# Playback state
var is_playing: bool = false
var playback_complete: bool = false

func _ready():
	print("AnimationManager: Initialized")

func queue_animation(object: Node, property: String, end_value: Variant, duration: float = 1.0, delay: float = 0.0, easing: String = "linear") -> void:
	"""Queue an animation for later playback"""
	if not object:
		push_error("AnimationManager: Cannot animate null object")
		return

	var anim_data = {
		"object": object,
		"property": property,
		"end_value": end_value,
		"duration": duration,
		"delay": delay,
		"easing": easing
	}

	animation_queue.append(anim_data)
	print("AnimationManager: Queued animation for %s.%s" % [object.name, property])

func play_animations() -> void:
	"""Execute all queued animations and wait for completion"""
	if animation_queue.is_empty():
		print("AnimationManager: No animations to play")
		playback_complete = true
		return

	print("AnimationManager: Playing %d animations" % animation_queue.size())

	is_playing = true
	playback_complete = false
	active_tweens.clear()

	# Create a single tween - chaining properties sequentially on same object
	# Godot plays them in sequence automatically when using same tween
	var tween = create_tween()
	active_tweens.append(tween)

	# Add all animations to the tween (they'll chain sequentially)
	for anim_data in animation_queue:
		var obj = anim_data["object"]
		var prop = anim_data["property"]
		var end_val = anim_data["end_value"]
		var duration = anim_data["duration"]
		var delay = anim_data["delay"]
		var easing_name = anim_data["easing"]

		# Convert property name to Godot format
		var godot_property = _get_godot_property(prop)

		# Get start value at the time of playback
		var start_value = obj.get(godot_property)

		# Convert end value to proper type (with radian conversion for rotation)
		var typed_end_value = _convert_value_type(end_val, start_value, prop)

		if godot_property == "rotation":
			if typed_end_value is Vector3:
				typed_end_value.x = deg_to_rad(typed_end_value.x)
				typed_end_value.y = deg_to_rad(typed_end_value.y)
				typed_end_value.z = deg_to_rad(typed_end_value.z)

		# Apply delay if specified
		if delay > 0:
			tween.tween_interval(delay)

		# Get easing function
		var easing_type = _get_easing_type(easing_name)

		# Tween the property (chained sequentially on same tween)
		tween.tween_property(obj, godot_property, typed_end_value, duration).set_ease(easing_type).set_trans(Tween.TRANS_CUBIC)

	# Clear queue
	animation_queue.clear()

	# Wait for the last tween to finish (all chained animations)
	await tween.finished

	# Clean up
	active_tweens.clear()
	is_playing = false
	playback_complete = true

	print("AnimationManager: Playback complete")

func is_playback_complete() -> bool:
	"""Check if animation playback has completed"""
	return playback_complete

func clear_queue() -> void:
	"""Clear all queued animations"""
	animation_queue.clear()
	print("AnimationManager: Queue cleared")

func _get_godot_property(prop: String) -> String:
	"""Convert Python property name to Godot property name"""
	match prop:
		"position":
			return "global_position"
		"rotation":
			return "rotation"
		"scale":
			return "scale"
		_:
			push_error("AnimationManager: Unknown property '%s'" % prop)
			return prop

func _convert_value_type(value: Variant, reference: Variant, property: String) -> Variant:
	"""Convert value to match reference type"""
	# Handle array/tuple to Vector conversion
	if value is Array:
		if reference is Vector3:
			if value.size() >= 3:
				var vec = Vector3(value[0], value[1], value[2])
				# For rotation, Python values are expected in radians already
				# Godot rotation property uses radians, so no conversion needed
				return vec
		elif reference is Vector2:
			if value.size() >= 2:
				return Vector2(value[0], value[1])

	return value

func _get_easing_type(easing_name: String) -> Tween.EaseType:
	"""Get Godot easing type from string"""
	match easing_name:
		"linear":
			return Tween.EASE_IN_OUT  # Linear is default
		"ease_in":
			return Tween.EASE_IN
		"ease_out":
			return Tween.EASE_OUT
		"ease_in_out":
			return Tween.EASE_IN_OUT
		_:
			push_warning("AnimationManager: Unknown easing '%s', using linear" % easing_name)
			return Tween.EASE_IN_OUT
