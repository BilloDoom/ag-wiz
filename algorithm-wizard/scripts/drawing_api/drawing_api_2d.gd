extends Node
class_name DrawingAPI2D

## DrawingAPI2D - 2D primitive drawing and mesh building functions
## Handles all 2D drawing operations for scenes

var viewport_manager: Node = null

func _ready():
	# Get reference to ViewportManager
	viewport_manager = get_node("/root/ViewportManager")
	if not viewport_manager:
		push_error("DrawingAPI2D: ViewportManager not found!")

# 2D Drawing Primitives

func draw_rect_2d(size: Vector2, position: Vector2 = Vector2.ZERO, rotation: float = 0.0, color: Color = Color.WHITE, filled: bool = true) -> Node2D:
	"""Draw a 2D rectangle"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI2D: No scene context active. Use 'with scene:' in Python")
		return null

	if filled:
		var polygon = Polygon2D.new()
		polygon.polygon = PackedVector2Array([
			Vector2(-size.x/2, -size.y/2),
			Vector2(size.x/2, -size.y/2),
			Vector2(size.x/2, size.y/2),
			Vector2(-size.x/2, size.y/2)
		])
		polygon.color = color
		polygon.position = position
		polygon.rotation = rotation
		root.add_child(polygon)
		print("DrawingAPI2D: Added filled rect to 2D scene '%s'" % viewport_manager.current_scene_context)
		return polygon
	else:
		var line = Line2D.new()
		line.add_point(Vector2(-size.x/2, -size.y/2))
		line.add_point(Vector2(size.x/2, -size.y/2))
		line.add_point(Vector2(size.x/2, size.y/2))
		line.add_point(Vector2(-size.x/2, size.y/2))
		line.add_point(Vector2(-size.x/2, -size.y/2))
		line.default_color = color
		line.position = position
		line.rotation = rotation
		root.add_child(line)
		print("DrawingAPI2D: Added rect outline to 2D scene '%s'" % viewport_manager.current_scene_context)
		return line

func draw_circle_2d(radius: float, position: Vector2 = Vector2.ZERO, color: Color = Color.WHITE, filled: bool = true, segments: int = 32) -> Node2D:
	"""Draw a 2D circle"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI2D: No scene context active. Use 'with scene:' in Python")
		return null

	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))

	if filled:
		var polygon = Polygon2D.new()
		polygon.polygon = points
		polygon.color = color
		polygon.position = position
		root.add_child(polygon)
		print("DrawingAPI2D: Added filled circle to 2D scene '%s'" % viewport_manager.current_scene_context)
		return polygon
	else:
		var line = Line2D.new()
		for point in points:
			line.add_point(point)
		line.add_point(points[0])  # Close the circle
		line.default_color = color
		line.position = position
		root.add_child(line)
		print("DrawingAPI2D: Added circle outline to 2D scene '%s'" % viewport_manager.current_scene_context)
		return line

func draw_line_2d(from_pos: Vector2, to_pos: Vector2, color: Color = Color.WHITE, width: float = 1.0) -> Line2D:
	"""Draw a 2D line"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI2D: No scene context active. Use 'with scene:' in Python")
		return null

	var line = Line2D.new()
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.default_color = color
	line.width = width
	root.add_child(line)
	print("DrawingAPI2D: Added line to 2D scene '%s'" % viewport_manager.current_scene_context)
	return line

func draw_polygon_2d(points: Array, position: Vector2 = Vector2.ZERO, rotation: float = 0.0, color: Color = Color.WHITE, filled: bool = true) -> Node2D:
	"""Draw a 2D polygon from points (Array of Vector2)"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI2D: No scene context active. Use 'with scene:' in Python")
		return null

	var packed_points = PackedVector2Array()
	for point in points:
		if point is Vector2:
			packed_points.append(point)
		elif point is Array and point.size() >= 2:
			packed_points.append(Vector2(point[0], point[1]))

	if filled:
		var polygon = Polygon2D.new()
		polygon.polygon = packed_points
		polygon.color = color
		polygon.position = position
		polygon.rotation = rotation
		root.add_child(polygon)
		print("DrawingAPI2D: Added filled polygon to 2D scene '%s'" % viewport_manager.current_scene_context)
		return polygon
	else:
		var line = Line2D.new()
		for point in packed_points:
			line.add_point(point)
		line.add_point(packed_points[0])  # Close the polygon
		line.default_color = color
		line.position = position
		line.rotation = rotation
		root.add_child(line)
		print("DrawingAPI2D: Added polygon outline to 2D scene '%s'" % viewport_manager.current_scene_context)
		return line

# 2D Mesh Building

func build_mesh_2d(vertices: Array, colors: Array = [], uvs: Array = [], position: Vector2 = Vector2.ZERO, rotation: float = 0.0, color: Color = Color.WHITE) -> Polygon2D:
	"""Build a custom 2D mesh from vertices.
	vertices: Array of Vector2
	colors: Optional array of Color per vertex
	uvs: Optional array of Vector2 UVs
	"""
	var root = viewport_manager.get_current_scene_root()
	if not root:
		push_error("DrawingAPI2D: No scene context active. Use 'with scene:' in Python")
		return null

	var packed_points = PackedVector2Array()
	for vertex in vertices:
		if vertex is Vector2:
			packed_points.append(vertex)
		elif vertex is Array and vertex.size() >= 2:
			packed_points.append(Vector2(vertex[0], vertex[1]))

	var polygon = Polygon2D.new()
	polygon.polygon = packed_points
	polygon.position = position
	polygon.rotation = rotation

	# Set colors if provided
	if colors.size() > 0:
		var packed_colors = PackedColorArray()
		for c in colors:
			if c is Color:
				packed_colors.append(c)
		polygon.vertex_colors = packed_colors
	else:
		polygon.color = color

	# Set UVs if provided
	if uvs.size() > 0:
		var packed_uvs = PackedVector2Array()
		for uv in uvs:
			if uv is Vector2:
				packed_uvs.append(uv)
			elif uv is Array and uv.size() >= 2:
				packed_uvs.append(Vector2(uv[0], uv[1]))
		polygon.uv = packed_uvs

	root.add_child(polygon)
	print("DrawingAPI2D: Added custom 2D mesh to scene '%s'" % viewport_manager.current_scene_context)
	return polygon
