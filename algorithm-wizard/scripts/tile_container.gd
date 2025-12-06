extends Control
class_name TileContainer

## A container that can hold either a single tile or split into two child containers
## Implements binary space partitioning for tiling window manager behavior

enum SplitType { NONE, HORIZONTAL, VERTICAL }

var split_type: SplitType = SplitType.NONE
var split_container: SplitContainer = null
var tile_node: Control = null

func _ready() -> void:
	# Fill the parent area
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

## Create a tile in this container
func create_tile() -> Control:
	# Create a panel that will contain user content
	var tile = Panel.new()
	tile.name = "Tile"
	tile.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Generate random color for the panel
	var random_color = Color(
		randf_range(0.2, 0.8),  # R
		randf_range(0.2, 0.8),  # G
		randf_range(0.2, 0.8),  # B
		1.0                      # A
	)

	# Create and apply StyleBoxFlat with random color
	var style = StyleBoxFlat.new()
	style.bg_color = random_color
	tile.add_theme_stylebox_override("panel", style)

	# Add a label to show tile info (temporary, for testing)
	var label = Label.new()
	label.name = "Label"
	label.text = "Tile " + str(get_instance_id())
	label.set_anchors_preset(Control.PRESET_CENTER)
	tile.add_child(label)

	tile_node = tile
	add_child(tile)
	return tile

## Split this container and return the new empty container
func split(horizontal: bool = true) -> TileContainer:
	if split_type != SplitType.NONE:
		push_error("Container is already split")
		return null

	# Determine split type
	split_type = SplitType.HORIZONTAL if horizontal else SplitType.VERTICAL

	# Create the appropriate split container
	if horizontal:
		split_container = HSplitContainer.new()
	else:
		split_container = VSplitContainer.new()

	split_container.name = "SplitContainer"
	split_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	split_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Remove current tile if it exists
	var existing_tile = tile_node
	if existing_tile:
		remove_child(existing_tile)
		tile_node = null

	# Add split container
	add_child(split_container)

	# Create two new tile containers
	var container1 = TileContainer.new()
	container1.name = "Container1"
	split_container.add_child(container1)

	var container2 = TileContainer.new()
	container2.name = "Container2"
	split_container.add_child(container2)

	# If there was an existing tile, move it to the first container
	if existing_tile:
		container1.tile_node = existing_tile
		container1.add_child(existing_tile)

	# Set equal split
	split_container.split_offset = 0

	return container2

## Remove a tile from this container
func remove_tile() -> bool:
	if tile_node:
		remove_child(tile_node)
		tile_node.queue_free()
		tile_node = null
		return true
	return false

## Check if this container has a tile
func has_tile() -> bool:
	return tile_node != null

## Check if this container is split
func is_split() -> bool:
	return split_type != SplitType.NONE

## Get all tiles in this container and its children
func get_all_tiles() -> Array[Control]:
	var tiles: Array[Control] = []

	if has_tile():
		tiles.append(tile_node)
	elif is_split() and split_container:
		for child in split_container.get_children():
			if child is TileContainer:
				tiles.append_array(child.get_all_tiles())

	return tiles

## Get the number of tiles in this container tree
func get_tile_count() -> int:
	return get_all_tiles().size()
