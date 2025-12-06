extends Control
class_name TilingManager

## Main tiling manager that handles adding and removing tiles
## Implements a binary space partitioning tiling system similar to i3/bspwm

@export var alternate_split_direction: bool = true ## Alternate between horizontal and vertical splits
@export var default_horizontal: bool = true ## Default split direction

var root_container: TileContainer = null
var placeholder_label: Label = null
var tile_count: int = 0

func _ready() -> void:
	# Set up to fill the entire area
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Create placeholder label
	placeholder_label = Label.new()
	placeholder_label.name = "PlaceholderLabel"
	placeholder_label.text = "No Tiles Present"
	placeholder_label.set_anchors_preset(Control.PRESET_CENTER)
	add_child(placeholder_label)

	# Create root container
	root_container = TileContainer.new()
	root_container.name = "RootContainer"
	root_container.visible = false
	add_child(root_container)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("add_tile"):
		add_tile()
		accept_event()

	# F3 key to print tile structure
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			print_tile_structure()
			accept_event()

## Add a new tile to the tiling system
func add_tile() -> Control:
	tile_count += 1

	# First tile - just create it in the root container
	if tile_count == 1:
		placeholder_label.visible = false
		root_container.visible = true
		var tile = root_container.create_tile()
		update_tile_labels()
		return tile

	# Find a container to split
	var container_to_split = find_container_to_split(root_container)

	if not container_to_split:
		push_error("Could not find a container to split")
		return null

	# Determine split direction
	var horizontal = should_split_horizontal(container_to_split)

	# Split the container
	var new_container = container_to_split.split(horizontal)

	if new_container:
		# Create a tile in the new container
		var tile = new_container.create_tile()
		update_tile_labels()
		return tile

	return null

## Remove a tile (to be implemented with selection system)
func remove_tile(tile: Control) -> void:
	if not tile:
		return

	# Find and remove the tile
	# This is a placeholder implementation
	# Full implementation would need to handle container merging
	var parent = tile.get_parent()
	if parent is TileContainer:
		parent.remove_tile()
		tile_count -= 1

		if tile_count == 0:
			root_container.visible = false
			placeholder_label.visible = true

		update_tile_labels()

## Find the best container to split based on current tile count
func find_container_to_split(container: TileContainer) -> TileContainer:
	if not container:
		return null

	# If container has a tile, we can split it
	if container.has_tile():
		return container

	# If container is split, recurse to find the best container
	if container.is_split() and container.split_container:
		var children = container.split_container.get_children()

		if children.size() >= 2:
			# Use the second container (keeps first tile isolated initially)
			var second_container = children[1]
			if second_container is TileContainer:
				return find_container_to_split(second_container)

	return null

## Determine if we should split horizontally or vertically
func should_split_horizontal(container: TileContainer) -> bool:
	if not alternate_split_direction:
		return default_horizontal

	# Calculate depth to alternate split direction
	var depth = get_container_depth(container)
	return (depth % 2 == 0) == default_horizontal

## Get the depth of a container in the tree
func get_container_depth(container: TileContainer) -> int:
	var depth = 0
	var current = container

	while current and current != root_container:
		current = current.get_parent()
		if current is TileContainer or (current and current.get_parent() is TileContainer):
			depth += 1

	return depth

## Update all tile labels with their numbers
func update_tile_labels() -> void:
	var tiles = get_all_tiles()
	for i in range(tiles.size()):
		var tile = tiles[i]
		var label = tile.get_node_or_null("Label")
		if label and label is Label:
			label.text = "Tile %d" % (i + 1)

## Get all tiles in the system
func get_all_tiles() -> Array[Control]:
	if root_container:
		return root_container.get_all_tiles()
	return []

## Get the current tile count
func get_tile_count() -> int:
	return tile_count

## Remove all tiles
func clear_tiles() -> void:
	if root_container:
		root_container.queue_free()

	root_container = TileContainer.new()
	root_container.name = "RootContainer"
	root_container.visible = false
	add_child(root_container)

	tile_count = 0
	placeholder_label.visible = true
	update_tile_labels()

## Print the current tile structure (F3 key)
func print_tile_structure() -> void:
	print_tree_pretty()
	pass
	
	print("\n" + "=".repeat(60))
	print("TILE STRUCTURE EXPORT")
	print("=".repeat(60))
	print("Total Tiles: %d" % tile_count)
	print("=".repeat(60))

	if tile_count == 0:
		print("No tiles present")
	else:
		_print_container_tree(root_container, 0)

	print("=".repeat(60) + "\n")

## Recursively print container tree structure
func _print_container_tree(container: TileContainer, depth: int) -> void:
	if not container:
		return

	var indent = "  ".repeat(depth)
	var prefix = "├─ " if depth > 0 else ""

	# If container has a tile, print it
	if container.has_tile():
		var tile = container.tile_node
		var label = tile.get_node_or_null("Label")
		var tile_text = label.text if label else "Tile"
		print("%s%s%s [Leaf]" % [indent, prefix, tile_text])

	# If container is split, print the split info and recurse
	elif container.is_split() and container.split_container:
		var split_name = "HSplit" if container.split_type == TileContainer.SplitType.HORIZONTAL else "VSplit"
		var split_offset = container.split_container.split_offset
		print("%s%s%s (offset: %d)" % [indent, prefix, split_name, split_offset])

		var children = container.split_container.get_children()
		for i in range(children.size()):
			var child = children[i]
			if child is TileContainer:
				print("%s  ├─ Container %d:" % [indent, i + 1])
				_print_container_tree(child, depth + 2)

	# Empty container
	else:
		print("%s%s[Empty]" % [indent, prefix])
