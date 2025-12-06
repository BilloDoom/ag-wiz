extends Control
class_name TileEngine
@export var max_depth := 10
@export var tile_template: PackedScene

const TILE_GROUP := "tile_leaf"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Check if template is assigned
	if not tile_template:
		push_error("TileEngine: tile_template is not assigned! Assign a PackedScene in the inspector.")
		return
	
	# Add initial tile
	var initial_tile = create_tile()
	if initial_tile:
		add_child(initial_tile)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("add_tile"):
		add_tile_bfs()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			print_tree_pretty()

func create_tile() -> Control:
	"""Create a tile from template"""
	if not tile_template:
		push_warning("TileEngine: Cannot create tile, tile_template is missing!")
		return null
	
	var tile = tile_template.instantiate()
	tile.add_to_group(TILE_GROUP)
	return tile

func add_tile_bfs() -> void:
	"""Add tile using breadth-first search to fill each level completely"""
	if not tile_template:
		push_warning("TileEngine: Cannot add tile, tile_template is missing!")
		return
	
	var queue: Array = []
	
	# Start with root's children
	for child in get_children():
		queue.append([child, 1])  # [node, depth]
	
	# BFS to find first insertable tile
	while not queue.is_empty():
		var data = queue.pop_front()
		var node: Node = data[0]
		var depth: int = data[1]
		
		# Check if this is a tile leaf
		if node.is_in_group(TILE_GROUP):
			# Check if we can split (not at max depth)
			if depth < max_depth:
				split_tile(node)
				return
			# At max depth, continue searching for shallower tiles
		
		# Add children to queue for next level
		for child in node.get_children():
			queue.append([child, depth + 1])
	
	push_warning("No available space to add tile (max depth reached)")

func split_tile(tile_node: Node) -> void:
	"""Split a tile node into two"""
	var parent = tile_node.get_parent()
	var node_index = tile_node.get_index()
	
	# Determine split direction based on size
	var container: SplitContainer
	if tile_node.size.x > tile_node.size.y:
		container = HSplitContainer.new()
	else:
		container = VSplitContainer.new()
	
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
	
	# Remove tile from parent
	parent.remove_child(tile_node)
	
	# Add container to parent at same position
	parent.add_child(container)
	parent.move_child(container, node_index)
	
	# Add existing tile back to container
	container.add_child(tile_node)
	
	# Create new tile from template
	var new_tile = create_tile()
	if new_tile:
		container.add_child(new_tile)
	else:
		push_error("Failed to create new tile")
		return
	
	# Set split offset
	await get_tree().process_frame
	if container is HSplitContainer:
		container.split_offset = int(container.size.x / 2)
	else:
		container.split_offset = int(container.size.y / 2)
	
	print("Split tile at depth, created new tile")
