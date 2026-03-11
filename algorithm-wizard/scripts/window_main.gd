extends Control

## Test Scene - Integrates TileEngine with ViewportManager

@onready var tile_engine: TileEngine = $MarginContainer/TileEngine

var next_viewport_id: int = 1
var tile_to_viewport_map: Dictionary = {}  # tile -> viewport_id

signal viewport_created(viewport_id: String, tile: Tile)

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Connect to all tiles in the tile engine
	if tile_engine:
		_connect_to_tiles(tile_engine)

		# Monitor for new tiles when splits occur
		tile_engine.child_entered_tree.connect(_on_tile_engine_child_added)

		print("Test: Connected to TileEngine")
	else:
		push_error("Test: Missing TileEngine")

func _connect_to_tiles(node: Node) -> void:
	"""Recursively connect to all Tile nodes"""
	if node is Tile:
		if not node.viewport_requested.is_connected(_on_viewport_requested):
			node.viewport_requested.connect(_on_viewport_requested)
			print("Test: Connected to tile")

	for child in node.get_children():
		_connect_to_tiles(child)

func _on_tile_engine_child_added(_child: Node) -> void:
	"""When new nodes are added to tile engine (e.g., split containers), connect to new tiles"""
	await get_tree().process_frame  # Wait for children to be ready
	_connect_to_tiles(tile_engine)

func _on_viewport_requested(tile: Tile) -> void:
	"""Handle viewport creation request from a tile"""
	# Check if this tile already has a viewport
	if tile_to_viewport_map.has(tile):
		var existing_id = tile_to_viewport_map[tile]
		print("Test: Tile already has viewport '%s'" % existing_id)
		return

	# Generate unique viewport ID
	var viewport_id = "viewport_" + str(next_viewport_id)
	next_viewport_id += 1

	# Wait for the viewport holder to be instantiated by the tile
	await get_tree().process_frame

	var viewport_holder = tile.get_window_instance()
	if not viewport_holder:
		push_error("Test: Failed to get viewport holder from tile")
		return

	# Ensure the viewport holder is fully ready before proceeding
	if not viewport_holder.is_node_ready():
		await viewport_holder.ready

	# Store the viewport_id in the viewport holder for later reference
	viewport_holder.set_meta("viewport_id", viewport_id)

	# Register the viewport with the global ViewportManager
	var viewport_manager = get_node("/root/ViewportManager")
	if viewport_manager:
		# Add the holder to ViewportManager's tracking dictionary
		viewport_manager.holders[viewport_id] = viewport_holder

		# Set the holder ID (needed for ViewportHolder to function properly)
		viewport_holder.set_holder_id(viewport_id)

		print("Test: Registered viewport '%s' with ViewportManager" % viewport_id)
	else:
		push_error("Test: ViewportManager not found!")

	# Track the mapping
	tile_to_viewport_map[tile] = viewport_id

	# Emit signal so other systems can hook into the creation
	viewport_created.emit(viewport_id, tile)

	print("Test: Created viewport '%s' for tile" % viewport_id)
