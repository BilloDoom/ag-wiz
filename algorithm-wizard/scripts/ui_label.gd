extends Label
class_name UILabel

## Simple UI label for 2D visualization
## Displays text at a specified position on the canvas layer

var label_id: String = ""

func setup(id: String, text: String, pos: Vector2, font_size: int = 16, color: Color = Color.WHITE) -> void:
	"""Initialize the label with parameters"""
	label_id = id
	self.text = text
	position = pos
	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_color", color)

	# Enable auto-sizing
	autowrap_mode = TextServer.AUTOWRAP_OFF
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
