extends Node

@onready var rich_text_label: RichTextLabel = $"../Panel/Panel/RichTextLabel"

func _ready():
	clear_output()

func clear_output():
	rich_text_label.clear()
	rich_text_label.push_color(Color.WHITE)

func log_message(message: String):
	rich_text_label.push_color(Color.LIGHT_GRAY)
	rich_text_label.append_text(message + "\n")
	rich_text_label.pop()

func log_output(output: String):
	rich_text_label.push_color(Color.GREEN)
	rich_text_label.append_text(output)
	if not output.ends_with("\n"):
		rich_text_label.append_text("\n")
	rich_text_label.pop()

func log_error(error: String):
	rich_text_label.push_color(Color.RED)
	rich_text_label.append_text(error + "\n")
	rich_text_label.pop()
