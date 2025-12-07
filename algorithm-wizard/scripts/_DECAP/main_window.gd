extends Control

## MainWindow - Main application window script
## Handles adding viewports to the grid

@export var add_viewport_btn: Button
@export var viewport_grid: GridContainer

var viewport_counter: int = 0

func _ready():
	# Connect the add viewport button
	if add_viewport_btn:
		add_viewport_btn.pressed.connect(_on_add_viewport_pressed)
	else:
		push_error("MainWindow: AddViewportBtn not found. Check scene structure.")

	# Set the viewport grid in ViewportManager
	if viewport_grid:
		ViewportManager.set_embedded_container(viewport_grid)
	else:
		push_error("MainWindow: ViewportGrid not found. Check scene structure.")

	print("MainWindow initialized")

func _on_add_viewport_pressed():
	# Generate unique viewport ID
	viewport_counter += 1
	var viewport_id = "viewport_" + str(viewport_counter)

	# Create empty viewport holder (no 3D/2D assigned yet)
	# Python code will configure it later
	var holder = ViewportManager.create_empty_viewport(viewport_id)

	if holder:
		print("Added empty viewport holder: ", viewport_id)
	else:
		print("Failed to add viewport (limit reached or error)")
