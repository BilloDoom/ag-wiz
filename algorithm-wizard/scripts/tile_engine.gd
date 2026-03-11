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

func split_tile(tile_node: Node, direction: String = "") -> void:
	"""Split a tile node into two.
	direction: "h" = HSplitContainer (side by side),
	           "v" = VSplitContainer (top / bottom),
	           ""  = auto (choose by tile aspect ratio)"""
	var parent = tile_node.get_parent()
	var node_index = tile_node.get_index()
	
	# Determine split container type
	var container: SplitContainer
	if direction == "h":
		container = HSplitContainer.new()
	elif direction == "v":
		container = VSplitContainer.new()
	else:
		# Auto: split along the longer axis
		if tile_node.size.x >= tile_node.size.y:
			container = HSplitContainer.new()
		else:
			container = VSplitContainer.new()
	
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	
	# split_offset = 0 means the divider sits exactly in the centre.
	await get_tree().process_frame
	container.split_offset = 0
	
	print("Split tile (%s)" % ["auto" if direction == "" else direction])

func close_tile(tile_node: Node) -> void:
	"""Remove a tile. The sibling takes over the parent SplitContainer's slot.
	Does nothing if this is the only tile (parent is TileEngine, not a SplitContainer)."""
	var split = tile_node.get_parent()
	
	# Only act when the immediate parent is a SplitContainer (i.e. there IS a sibling)
	if not (split is SplitContainer):
		print("TileEngine: tile is the only tile, nothing to close")
		return
	
	# Find the sibling (the other child of the SplitContainer)
	var sibling: Node = null
	for child in split.get_children():
		if child != tile_node:
			sibling = child
			break
	
	if sibling == null:
		push_error("TileEngine: SplitContainer has no sibling")
		return
	
	var grandparent = split.get_parent()
	var split_index = split.get_index()
	
	# Detach sibling before the container is freed
	split.remove_child(sibling)
	grandparent.add_child(sibling)
	grandparent.move_child(sibling, split_index)
	
	# Restore expand flags so sibling fills the freed space
	if sibling is Control:
		sibling.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sibling.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# When promoted directly into TileEngine (not another SplitContainer),
		# switch to anchored layout so it fills the whole area.
		if grandparent == self:
			sibling.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Free the split container (tile_node is still inside it and freed with it)
	split.queue_free()
	
	print("TileEngine: closed tile, sibling promoted")
