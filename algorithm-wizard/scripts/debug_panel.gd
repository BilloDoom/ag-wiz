extends Node

@export var rich_text_output: RichTextLabel

func _ready():
	clear_output()

func clear_output():
	rich_text_output.clear()
	rich_text_output.push_color(Color.WHITE)

func log_message(message: String):
	rich_text_output.push_color(Color.LIGHT_GRAY)
	rich_text_output.append_text(message + "\n")
	rich_text_output.pop()

func log_output(output: String):
	rich_text_output.push_color(Color.GREEN)
	rich_text_output.append_text(output)
	if not output.ends_with("\n"):
		rich_text_output.append_text("\n")
	rich_text_output.pop()

func log_error(error: String):
	rich_text_output.push_color(Color.RED)
	rich_text_output.append_text(error + "\n")
	rich_text_output.pop()
