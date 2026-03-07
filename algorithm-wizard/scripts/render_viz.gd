class_name RenderViz extends Control

## RenderViz - Visualizes rendering passes of an existing World3D
## Connects to a ViewportHolder by ID and displays vertex/rasterization passes

enum RenderPass {
	NONE,
	VERTEX,         # Wireframe visualization (no shadows, blank sky)
	RASTERIZATION,  # Pure color data (no shadows, no lighting, blank sky)
	POST_PROCESSING # Full rendering with lighting and effects
}

# Current state
var current_pass: RenderPass = RenderPass.NONE
var connected_port_id: String = ""
var source_world_3d: World3D = null

# Internal viewport for rendering
var subviewport: SubViewport = null
var camera: Camera3D = null

# Source camera reference (for syncing transforms)
var source_camera: Camera3D = null
var source_camera_controller: Node = null
var source_holder: Node = null  # ViewportHolder reference

# Wireframe material for vertex pass
var wireframe_material: ShaderMaterial = null

# Original materials storage (for restoring after wireframe)
var original_materials: Dictionary = {}  # node_path -> material

# UI Controls - to be connected manually in editor
@export var button_vertex: Button
@export var button_rasterization: Button
@export var button_post_processing: Button
@export var port_name_input: LineEdit
@export var button_connect: Button
@export var subviewport_container: SubViewportContainer
@export var explanation_label: RichTextLabel

# Preload wireframe shader
const WIREFRAME_SHADER = preload("res://shaders/wireframe.gdshader")

# Explanation text file paths
const EXPLANATION_VERTEX = "res://assets/text/vertex_pass.txt"
const EXPLANATION_RASTERIZATION = "res://assets/text/rasterization_pass.txt"
const EXPLANATION_POST_PROCESSING = "res://assets/text/post_processing_pass.txt"
const EXPLANATION_NONE = "res://assets/text/no_pass.txt"

# Cached explanation texts
var _explanation_cache: Dictionary = {}

func _ready():
	# Create wireframe material
	wireframe_material = ShaderMaterial.new()
	wireframe_material.shader = WIREFRAME_SHADER
	
	# Connect button signals if exports are set
	if button_vertex:
		button_vertex.pressed.connect(_on_vertex_pass_pressed)
	if button_rasterization:
		button_rasterization.pressed.connect(_on_rasterization_pass_pressed)
	if button_post_processing:
		button_post_processing.pressed.connect(_on_post_processing_pass_pressed)
	if button_connect:
		button_connect.pressed.connect(_on_connect_pressed)
	
	# Load and cache explanation texts
	_load_explanation_texts()
	
	# Show initial explanation
	_update_explanation_display()

func _process(_delta: float):
	# Continuously sync camera transform from source
	_sync_camera_from_source()

func _sync_camera_from_source():
	"""Sync our camera's transform to match the source camera"""
	if camera and source_camera and is_instance_valid(source_camera):
		camera.global_transform = source_camera.global_transform
		# Also sync camera properties
		camera.fov = source_camera.fov
		camera.near = source_camera.near
		camera.far = source_camera.far

func _on_connect_pressed():
	"""Connect to viewport by ID from input field"""
	if not port_name_input:
		push_error("RenderViz: port_name_input not assigned")
		return
	
	var port_id = port_name_input.text.strip_edges()
	if port_id == "":
		push_error("RenderViz: Port name is empty")
		return
	
	connect_to_viewport(port_id)

func connect_to_viewport(port_id: String) -> bool:
	"""Connect to a viewport holder and share its World3D"""
	var viewport_manager = get_node_or_null("/root/ViewportManager")
	if not viewport_manager:
		push_error("RenderViz: ViewportManager not found")
		return false
	
	var holder = viewport_manager.get_holder(port_id)
	if not holder:
		push_error("RenderViz: Viewport holder '%s' not found" % port_id)
		return false
	
	# Find the World3D and camera from the holder's subviewports
	var world: World3D = null
	var found_camera: Camera3D = null
	var found_controller: Node = null
	
	for camera_name in holder.camera_subviewports:
		var data = holder.camera_subviewports[camera_name]
		var sv: SubViewport = data["subviewport"]
		if sv and sv.world_3d:
			world = sv.world_3d
			# Get the camera and controller
			if data.has("camera") and data["camera"] is Camera3D:
				found_camera = data["camera"]
			if data.has("controller") and data["controller"]:
				found_controller = data["controller"]
			break
	
	if not world:
		push_error("RenderViz: No World3D found in viewport '%s'" % port_id)
		return false
	
	# Disconnect from previous if any
	if connected_port_id != "":
		disconnect_from_viewport()
	
	source_world_3d = world
	source_camera = found_camera
	source_camera_controller = found_controller
	source_holder = holder
	connected_port_id = port_id
	
	# Setup our own SubViewport to view this world
	_setup_subviewport()
	
	print("RenderViz: Connected to viewport '%s'" % port_id)
	return true

func disconnect_from_viewport():
	"""Disconnect from current viewport"""
	# Restore any modified materials
	_restore_original_materials()
	
	# Clean up subviewport
	if subviewport:
		subviewport.queue_free()
		subviewport = null
		camera = null
	
	source_world_3d = null
	source_camera = null
	source_camera_controller = null
	source_holder = null
	connected_port_id = ""
	current_pass = RenderPass.NONE
	
	print("RenderViz: Disconnected")

func _setup_subviewport():
	"""Create SubViewport to render the connected World3D"""
	if not subviewport_container:
		push_error("RenderViz: subviewport_container not assigned")
		return
	
	# Remove existing subviewport if any
	for child in subviewport_container.get_children():
		child.queue_free()
	
	# Create new SubViewport
	subviewport = SubViewport.new()
	subviewport.name = "RenderVizSubViewport"
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subviewport.world_3d = source_world_3d
	
	# Disable post-processing for raw visualization
	subviewport.use_debanding = false
	
	subviewport_container.add_child(subviewport)
	
	# Create camera
	camera = Camera3D.new()
	camera.name = "RenderVizCamera"
	camera.current = true
	subviewport.add_child(camera)
	
	# Sync initial camera transform from source
	_sync_camera_from_source()
	
	print("RenderViz: SubViewport setup complete")

func _on_vertex_pass_pressed():
	"""Switch to vertex/wireframe pass visualization"""
	if not source_world_3d:
		push_error("RenderViz: Not connected to any viewport")
		return
	
	set_render_pass(RenderPass.VERTEX)

func _on_rasterization_pass_pressed():
	"""Switch to rasterization pass (raw colors)"""
	if not source_world_3d:
		push_error("RenderViz: Not connected to any viewport")
		return
	
	set_render_pass(RenderPass.RASTERIZATION)

func _on_post_processing_pass_pressed():
	"""Switch to post-processing pass (full lighting and effects)"""
	if not source_world_3d:
		push_error("RenderViz: Not connected to any viewport")
		return
	
	set_render_pass(RenderPass.POST_PROCESSING)

func set_render_pass(pass_type: RenderPass):
	"""Set the current render pass visualization mode"""
	if current_pass == pass_type:
		return
	
	# Always restore before applying new pass
	_restore_original_materials()
	
	current_pass = pass_type
	
	match pass_type:
		RenderPass.VERTEX:
			_apply_vertex_pass()
		RenderPass.RASTERIZATION:
			_apply_rasterization_pass()
		RenderPass.POST_PROCESSING:
			_apply_post_processing_pass()
		RenderPass.NONE:
			_restore_original_materials()
	
	# Update explanation text
	_update_explanation_display()
	
	print("RenderViz: Set render pass to %s" % RenderPass.keys()[pass_type])

func _create_blank_environment() -> Environment:
	"""Create a blank environment with solid color background (no sky)"""
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.1, 1.0)  # Dark gray background
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	env.ssr_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.adjustment_enabled = false
	return env

func _apply_vertex_pass():
	"""Apply vertex/wireframe pass - wireframe with blank sky, no shadows"""
	if not subviewport or not camera:
		return
	
	# Enable debug wireframe rendering on the viewport
	subviewport.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	
	# Use blank environment (no sky)
	camera.environment = _create_blank_environment()
	
	# Disable camera effects
	var cam_attrs = CameraAttributesPractical.new()
	cam_attrs.auto_exposure_enabled = false
	cam_attrs.dof_blur_far_enabled = false
	cam_attrs.dof_blur_near_enabled = false
	camera.attributes = cam_attrs
	
	print("RenderViz: Vertex pass applied (wireframe, no shadows, blank sky)")

func _apply_rasterization_pass():
	"""Apply rasterization pass - pure color, no lighting, no shadows, blank sky"""
	if not subviewport or not camera:
		return
	
	# Disable debug draw (show normal rendering)
	subviewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
	
	# Use blank environment (no sky, no lighting)
	camera.environment = _create_blank_environment()
	
	# Disable camera effects
	var cam_attrs = CameraAttributesPractical.new()
	cam_attrs.auto_exposure_enabled = false
	cam_attrs.dof_blur_far_enabled = false
	cam_attrs.dof_blur_near_enabled = false
	camera.attributes = cam_attrs
	
	print("RenderViz: Rasterization pass applied (pure color, no lighting, no shadows, blank sky)")

func _apply_post_processing_pass():
	"""Apply post-processing pass - full lighting and effects (normal rendering)"""
	if not subviewport or not camera:
		return
	
	# Disable debug draw (show normal rendering)
	subviewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
	
	# Use the original environment from the source world (includes sky and lighting)
	if source_world_3d and source_world_3d.environment:
		camera.environment = source_world_3d.environment.duplicate()
	else:
		camera.environment = null
	
	# Clear camera attributes to use defaults
	camera.attributes = null
	
	print("RenderViz: Post-processing pass applied (full lighting and effects)")

func _restore_original_materials():
	"""Restore original materials to all meshes"""
	if subviewport:
		subviewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
	
	if camera:
		camera.environment = null
		camera.attributes = null
	
	original_materials.clear()
	print("RenderViz: Original materials restored")

func _find_mesh_instances(node: Node, mesh_list: Array):
	"""Recursively find all MeshInstance3D nodes"""
	if node is MeshInstance3D:
		mesh_list.append(node)
	
	for child in node.get_children():
		_find_mesh_instances(child, mesh_list)

# Camera controls for the visualization viewport
# When we have a source camera controller, we forward input to it
# This allows controlling the camera from either viewport
func _input(event: InputEvent):
	if not subviewport_container:
		return
	
	# Only handle input when mouse is over this control
	if not get_global_rect().has_point(get_global_mouse_position()):
		return
	
	# If we have a source camera controller, forward input to it
	# The controller will update the source camera, and _process will sync to us
	if source_camera_controller and is_instance_valid(source_camera_controller):
		_forward_input_to_controller(event)
	elif camera:
		# Fallback: direct camera control if no controller exists
		_handle_direct_camera_control(event)

func _forward_input_to_controller(event: InputEvent):
	"""Forward input events to the source camera controller"""
	# Temporarily set the controller's mouse_inside flag to true
	# so it processes our input
	if source_camera_controller.has_method("_input"):
		# Store original state
		var original_mouse_inside = source_camera_controller.get("mouse_inside")
		
		# Set mouse_inside to true so controller accepts input
		source_camera_controller.set("mouse_inside", true)
		
		# Forward the event
		source_camera_controller._input(event)
		
		# Restore original state
		source_camera_controller.set("mouse_inside", original_mouse_inside)

func _handle_direct_camera_control(event: InputEvent):
	"""Direct camera control when no controller is available"""
	if not camera:
		return
	
	# Simple orbit camera control
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var motion = event.relative
		var pivot = Vector3.ZERO
		var distance = camera.position.length()
		
		# Rotate around pivot
		camera.rotate_y(-motion.x * 0.01)
		camera.rotate_object_local(Vector3.RIGHT, -motion.y * 0.01)
		
		# Keep distance constant
		camera.position = camera.position.normalized() * distance
		camera.look_at(pivot)
	
	# Zoom with scroll
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position *= 0.9
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position *= 1.1

# Explanation text handling

func _load_explanation_texts():
	"""Load all explanation texts from files and cache them"""
	_explanation_cache[RenderPass.NONE] = _load_text_file(EXPLANATION_NONE)
	_explanation_cache[RenderPass.VERTEX] = _load_text_file(EXPLANATION_VERTEX)
	_explanation_cache[RenderPass.RASTERIZATION] = _load_text_file(EXPLANATION_RASTERIZATION)
	_explanation_cache[RenderPass.POST_PROCESSING] = _load_text_file(EXPLANATION_POST_PROCESSING)

func _load_text_file(path: String) -> String:
	"""Load text content from a file"""
	if not FileAccess.file_exists(path):
		push_warning("RenderViz: Explanation file not found: %s" % path)
		return "[color=red]Explanation file not found.[/color]"
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("RenderViz: Failed to open file: %s" % path)
		return "[color=red]Failed to load explanation.[/color]"
	
	var content = file.get_as_text()
	file.close()
	return content

func _update_explanation_display():
	"""Update the RichTextLabel with the current pass explanation"""
	if not explanation_label:
		return
	
	var text = _explanation_cache.get(current_pass, "")
	if text == "":
		text = "[color=gray]No explanation available.[/color]"
	
	explanation_label.clear()
	explanation_label.bbcode_enabled = true
	explanation_label.text = text
