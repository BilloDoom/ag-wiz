extends Control

func _ready() -> void:
	var runtime = ScriptRuntime.new()
	runtime.initialize_python()
	var code = """
for i in range(2):
	print(i)
"""
	runtime.execute_script(code)
	print(runtime.get_last_output())
