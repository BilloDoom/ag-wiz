extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", Vector3(5,5,5), 1.0)
	tween.tween_property(self, "position", Vector3(-5,-5,-5), 1.0)
