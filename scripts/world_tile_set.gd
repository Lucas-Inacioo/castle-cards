extends Node2D

signal building_created(building_type: GameData.BuildingType, place_cell: Vector2i)

const MIN_DIST_CELLS = 32
const SAFEZONE_DIST_CELLS = 64

#region Children Nodes
@export var tile_map_ground: TileMapLayer
#endregion

# Used as cache for already existent layers
var world_layer_by_z_index: Dictionary = {}

# To avoid placing buildings on the same spot
var placed_centers: Array[Vector2i] = []

func _ready() -> void:
	# Register the ground layer as the layer for its z_index
	world_layer_by_z_index[tile_map_ground.z_index] = tile_map_ground

	# Defer initial spawning to allow other nodes to initialize first
	call_deferred("_spawn_initial")

func _spawn_initial() -> void:
	# Spawn player castle at origin
	stamp_building_scene(GameData.BuildingType.PLAYER_CASTLE, Vector2i(0, 0))

	# Initial enemy bases
	for i in range(16):
		spawn_enemy_base_random()

func spawn_enemy_base_random() -> void:
	var max_attempts = 2000

	for i in range(max_attempts):
		# Get random candidate position
		var candidate = Vector2i(
			randi_range(-125, 125),
			randi_range(-125, 125)
		)

		if not can_place_center(candidate):
			continue

		# Valid location → place building
		var random_variant = randi() % 2
		if random_variant == 0:
			stamp_building_scene(GameData.BuildingType.ENEMY_BASE_VARIANT_1, candidate)
			break
		else:
			stamp_building_scene(GameData.BuildingType.ENEMY_BASE_VARIANT_2, candidate)
			break

func stamp_building_scene(
	building: GameData.BuildingType,
	place_cell: Vector2i,
) -> void:
	var building_data = GameData.building_data.get(building)
	var building_scene = load(building_data.get("scene"))

	var building_instance = building_scene.instantiate()
	var building_tile_map = building_instance.get_node("Tilemap")

	# Collect all TileMapLayers from the building's TileMap node
	var building_layers: Array[TileMapLayer] = []
	for layer in building_tile_map.get_children():
		building_layers.append(layer)

	# Compute one common anchor for ALL layers so they align together
	# This uses the minimum used_rect.position across layers (top-left in map coords)
	var anchor_cell = _compute_anchor_cell(building_layers)

	for layer in building_layers:
		var target_layer = _get_or_create_world_layer_for_z(layer.z_index)

		# Copy cells
		for cell in layer.get_used_cells():
			var source_id = layer.get_cell_source_id(cell)
			if source_id == -1:
				continue

			var atlas_coords = layer.get_cell_atlas_coords(cell)
			var alternative_tile = layer.get_cell_alternative_tile(cell)

			var target_cell = place_cell + (cell - anchor_cell)

			target_layer.set_cell(target_cell, source_id, atlas_coords, alternative_tile)

		# Force immediate refresh of the target layer
		target_layer.update_internals()

	building_instance.queue_free()
	placed_centers.append(place_cell)

	# Emit signal with global position of tile center
	building_created.emit(
		building,
		tile_map_ground.map_to_local(place_cell)
	)

## Computes a common anchor cell for all given layers
func _compute_anchor_cell(layers: Array[TileMapLayer]) -> Vector2i:
	var min_x = 0
	var min_y = 0

	for layer in layers:
		var rect = layer.get_used_rect()

		min_x = min(min_x, rect.position.x)
		min_y = min(min_y, rect.position.y)

	return Vector2i(min_x, min_y)

# Gets or creates a TileMapLayer for the given z_index
func _get_or_create_world_layer_for_z(index: int) -> TileMapLayer:
	# Check cache first
	if world_layer_by_z_index.has(index):
		return world_layer_by_z_index[index]

	# Search existing layers
	var parent_node = tile_map_ground.get_parent()
	for layer in parent_node.get_children():
		if layer.z_index == index:
			world_layer_by_z_index[index] = layer
			return layer

	# Create it
	var new_layer = TileMapLayer.new()
	new_layer.name = "TileMapLayer_z_%d" % index
	new_layer.z_index = index
	new_layer.z_as_relative = tile_map_ground.z_as_relative
	new_layer.tile_set = tile_map_ground.tile_set

	# Insert  by z_index
	_insert_layer_sorted_by_z(parent_node, new_layer)

	world_layer_by_z_index[index] = new_layer
	return new_layer

## Orders the new layer among existing ones by z_index
func _insert_layer_sorted_by_z(parent_node: Node, layer_to_add: TileMapLayer) -> void:
	# Add first so it becomes a child, then move to the desired position
	parent_node.add_child(layer_to_add)

	var desired_index = parent_node.get_child_count() - 1
	for i in range(parent_node.get_child_count()):
		var sibling = parent_node.get_child(i)
		if sibling == layer_to_add:
			continue
		if sibling.z_index > layer_to_add.z_index:
			desired_index = i
			break

	parent_node.move_child(layer_to_add, desired_index)

## Checks if any already placed center is too close to the candidate
func can_place_center(candidate: Vector2i) -> bool:
	for center in placed_centers:
		if center.distance_to(candidate) < MIN_DIST_CELLS:
			return false
		# Safezone near the castle (origin)
		if candidate.distance_to(Vector2i.ZERO) < SAFEZONE_DIST_CELLS:
			return false
	return true
