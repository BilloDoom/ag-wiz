extends Node
class_name DrawingAPI3D

## DrawingAPI3D - 3D primitive drawing and mesh building functions
## Handles all 3D drawing operations for scenes

var viewport_manager: Node = null

func _ready():
	# Get reference to ViewportManager
	viewport_manager = get_node("/root/ViewportManager")
	if not viewport_manager:
		push_error("DrawingAPI3D: ViewportManager not found!")

# Primitive drawing functions

func draw_box(size: Vector3, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	"""Draw a box primitive in the current scene context"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI3D: No scene context active. Use 'with scene:' in Python")
		return null

	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size

	mesh_instance.mesh = box_mesh
	mesh_instance.position = position
	mesh_instance.rotation = rotation

	# Create material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)

	root.add_child(mesh_instance)
	print("DrawingAPI3D: Added box to scene '%s'" % viewport_manager.current_scene_context)
	return mesh_instance

func draw_sphere(radius: float, position: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	"""Draw a sphere primitive in the current scene context"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI3D: No scene context active. Use 'with scene:' in Python")
		return null

	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0

	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = position

	# Create material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)

	root.add_child(mesh_instance)
	print("DrawingAPI3D: Added sphere to scene '%s'" % viewport_manager.current_scene_context)
	return mesh_instance

func draw_cylinder(radius: float, height: float, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	"""Draw a cylinder primitive in the current scene context"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI3D: No scene context active. Use 'with scene:' in Python")
		return null

	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height

	mesh_instance.mesh = cylinder_mesh
	mesh_instance.position = position
	mesh_instance.rotation = rotation

	# Create material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)

	root.add_child(mesh_instance)
	print("DrawingAPI3D: Added cylinder to scene '%s'" % viewport_manager.current_scene_context)
	return mesh_instance

func draw_torus(inner_radius: float, outer_radius: float, position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	"""Draw a torus primitive in the current scene context"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI3D: No scene context active. Use 'with scene:' in Python")
		return null

	var mesh_instance = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = inner_radius
	torus_mesh.outer_radius = outer_radius

	mesh_instance.mesh = torus_mesh
	mesh_instance.position = position
	mesh_instance.rotation = rotation

	# Create material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)

	root.add_child(mesh_instance)
	print("DrawingAPI3D: Added torus to scene '%s'" % viewport_manager.current_scene_context)
	return mesh_instance

# 3D Immediate Mesh Building

func create_mesh_builder_3d(position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO) -> Dictionary:
	"""Create a 3D mesh builder using ImmediateMesh. Returns a dictionary with the mesh instance and builder functions."""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI3D: No scene context active. Use 'with scene:' in Python")
		return {}

	var immediate_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.position = position
	mesh_instance.rotation = rotation

	root.add_child(mesh_instance)

	# Return mesh builder interface
	var builder = {
		"mesh_instance": mesh_instance,
		"immediate_mesh": immediate_mesh
	}

	builder["begin"] = func(primitive_type: int, material: Material = null):
		if material:
			immediate_mesh.surface_begin(primitive_type, material)
		else:
			immediate_mesh.surface_begin(primitive_type)

	builder["set_normal"] = func(normal: Vector3):
		immediate_mesh.surface_set_normal(normal)

	builder["set_tangent"] = func(tangent: Plane):
		immediate_mesh.surface_set_tangent(tangent)

	builder["set_color"] = func(color: Color):
		immediate_mesh.surface_set_color(color)

	builder["set_uv"] = func(uv: Vector2):
		immediate_mesh.surface_set_uv(uv)

	builder["set_uv2"] = func(uv2: Vector2):
		immediate_mesh.surface_set_uv2(uv2)

	builder["add_vertex"] = func(vertex: Vector3):
		immediate_mesh.surface_add_vertex(vertex)

	builder["end"] = func():
		immediate_mesh.surface_end()

	builder["clear"] = func():
		immediate_mesh.clear_surfaces()

	return builder

func build_mesh_3d(vertices: Array, indices: Array = [], normals: Array = [], colors: Array = [], uvs: Array = [], position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, color: Color = Color.WHITE) -> Node3D:
	"""Build a custom 3D mesh from vertices.
	vertices: Array of Vector3
	indices: Optional array of indices for indexed rendering
	normals: Optional array of Vector3 normals
	colors: Optional array of Color per vertex
	uvs: Optional array of Vector2 UVs
	"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI3D: No scene context active. Use 'with scene:' in Python")
		return null

	var immediate_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.position = position
	mesh_instance.rotation = rotation

	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.vertex_color_use_as_albedo = colors.size() > 0

	# Begin surface
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)

	# Add vertices
	if indices.size() > 0:
		# Indexed rendering
		for i in indices:
			if i < vertices.size():
				if normals.size() > i:
					immediate_mesh.surface_set_normal(normals[i])
				if colors.size() > i:
					immediate_mesh.surface_set_color(colors[i])
				if uvs.size() > i:
					immediate_mesh.surface_set_uv(uvs[i])
				immediate_mesh.surface_add_vertex(vertices[i])
	else:
		# Sequential rendering
		for i in range(vertices.size()):
			if normals.size() > i:
				immediate_mesh.surface_set_normal(normals[i])
			if colors.size() > i:
				immediate_mesh.surface_set_color(colors[i])
			if uvs.size() > i:
				immediate_mesh.surface_set_uv(uvs[i])
			immediate_mesh.surface_add_vertex(vertices[i])

	immediate_mesh.surface_end()

	root.add_child(mesh_instance)
	print("DrawingAPI3D: Added custom 3D mesh to scene '%s'" % viewport_manager.current_scene_context)
	return mesh_instance
