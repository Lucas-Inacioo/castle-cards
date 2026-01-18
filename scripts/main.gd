extends Node2D

const MIN_DIST_CELLS := 32

#region Children Nodes
@export var card_container: HBoxContainer
@export var slots_container: HBoxContainer
@export var tile_map_ground: TileMapLayer
#endregion

# Used as cache for already existent layers
var world_layer_by_z_index: Dictionary = {}

# To avoid placing structures on the same spot
var placed_centers: Array[Vector2i] = []

func _ready() -> void:
	get_window().content_scale_factor = 0.1

	# Register the ground layer as the layer for its z_index
	world_layer_by_z_index[tile_map_ground.z_index] = tile_map_ground

	# Spawn player castle at origin
	stamp_structure_scene(GameData.BuildingType.PLAYER_CASTLE, Vector2i(0, 0))

	# Initial enemy bases
	for i in range(20):
		spawn_enemy_base_random()

func _end_day_button_pressed() -> void:
	GameData.current_day += 1

	_check_cards_upgrade()
	_set_cards_for_new_day()

	card_container.start_new_day()
	slots_container.start_new_day()

func _check_cards_upgrade() -> void:
	for card_type in GameData.CardType.values():
		if card_type == GameData.CardType.NONE:
			continue

		var card_status = GameData.cards_status[card_type]
		if card_status.is_upgrading:
			card_status.rounds_until_upgrade_complete -= 1
			if card_status.rounds_until_upgrade_complete <= 0:
				card_status.is_upgrading = false
				card_status.upgrade_level += 1
				GameData.cards_status[card_type] = card_status

func _set_cards_for_new_day() -> void:
	var current_updating_card = GameData.current_upgrade_card
	var current_resource_card = GameData.current_resource_card

	GameData.cards_status[current_updating_card].is_upgrading = true
	GameData.cards_status[current_updating_card].rounds_until_upgrade_complete = 2

func spawn_enemy_base_random() -> void:
	var max_attempts := 2000

	for i in range(max_attempts):
		var candidate := Vector2i(
			randi_range(-50, 50),
			randi_range(-50, 50)
		)

		if not can_place_center(candidate):
			continue

		# Valid location → place structure
		var random_variant := randi() % 2
		if random_variant == 0:
			stamp_structure_scene(GameData.BuildingType.ENEMY_BASE_VARIANT_1, candidate)
		else:
			stamp_structure_scene(GameData.BuildingType.ENEMY_BASE_VARIANT_2, candidate)

	# Optional: if no valid spot was found
	print("Failed to place enemy base (no valid location found)")

func stamp_structure_scene(
	structure: GameData.BuildingType,
	place_cell: Vector2i,
	tile_map_node_path: NodePath = ^"Tilemap",
	overwrite_existing: bool = true
) -> void:
	var structure_data = GameData.building_data.get(structure)
	var structure_scene = load(structure_data.get("scene"))

	var structure_instance := structure_scene.instantiate() as Node
	var source_tile_map := structure_instance.get_node_or_null(tile_map_node_path)
	if source_tile_map == null:
		push_error("stamp_structure_scene: structure has no node at path %s" % [tile_map_node_path])
		structure_instance.queue_free()
		return

	# Collect all TileMapLayers from the structure's TileMap node
	var source_layers: Array[TileMapLayer] = []
	for child in source_tile_map.get_children():
		if child is TileMapLayer:
			source_layers.append(child)

	if source_layers.is_empty():
		structure_instance.queue_free()
		return

	# Compute one common anchor for ALL layers so they align together.
	# This uses the minimum used_rect.position across layers (top-left in map coords).
	var anchor_cell := _compute_anchor_cell(source_layers)

	for source_layer in source_layers:
		var target_layer := _get_or_create_world_layer_for_z(source_layer.z_index)

		# Copy cells
		for cell in source_layer.get_used_cells():
			var source_id := source_layer.get_cell_source_id(cell)
			if source_id == -1:
				continue

			var atlas_coords := source_layer.get_cell_atlas_coords(cell)
			var alternative_tile := source_layer.get_cell_alternative_tile(cell)

			var target_cell := place_cell + (cell - anchor_cell)

			if not overwrite_existing and target_layer.get_cell_source_id(target_cell) != -1:
				continue

			target_layer.set_cell(target_cell, source_id, atlas_coords, alternative_tile)

		# Force immediate refresh if you need it this frame
		target_layer.update_internals()

	structure_instance.queue_free()

	placed_centers.append(place_cell)

	var enemy_type = structure_data.get("enemy_type")
	if enemy_type != null:
		var target_layer := _get_or_create_world_layer_for_z(-1)
		var enemy_scene: PackedScene = enemy_type if enemy_type is PackedScene else load(enemy_type)

		var tile_size := Vector2(target_layer.tile_set.tile_size)
		var anchor_global = target_layer.to_global(
			target_layer.map_to_local(place_cell) + tile_size * 0.5
		)

		for i in range(3):
			var enemy := enemy_scene.instantiate() as Node2D
			add_child(enemy)

			if enemy.has_method("setup"):
				enemy.setup(anchor_global, tile_size, 3) # 3 tiles radius

			# spawn somewhere in range initially
			enemy.global_position = anchor_global + Vector2(
				randi_range(-3, 3) * tile_size.x,
				randi_range(-3, 3) * tile_size.y
			)

func _compute_anchor_cell(layers: Array[TileMapLayer]) -> Vector2i:
	var hasAny := false
	var minX := 0
	var minY := 0

	for layer in layers:
		var rect := layer.get_used_rect()
		# If a layer has no tiles, used_rect size is zero
		if rect.size == Vector2i.ZERO:
			continue

		if not hasAny:
			minX = rect.position.x
			minY = rect.position.y
			hasAny = true
		else:
			minX = min(minX, rect.position.x)
			minY = min(minY, rect.position.y)

	# Fallback: if all layers are empty, just anchor at (0,0)
	return Vector2i(minX, minY) if hasAny else Vector2i.ZERO

func _get_or_create_world_layer_for_z(zIndex: int) -> TileMapLayer:
	# Cached already?
	if world_layer_by_z_index.has(zIndex):
		return world_layer_by_z_index[zIndex] as TileMapLayer

	# Maybe exists in the scene tree but not cached yet?
	var parentNode := tile_map_ground.get_parent()
	for child in parentNode.get_children():
		if child is TileMapLayer and (child as TileMapLayer).z_index == zIndex:
			world_layer_by_z_index[zIndex] = child
			return child as TileMapLayer

	# Create it
	var newLayer := TileMapLayer.new()
	newLayer.name = "TileMapLayer_z_%d" % zIndex
	newLayer.z_index = zIndex
	newLayer.z_as_relative = tile_map_ground.z_as_relative
	newLayer.tile_set = tile_map_ground.tile_set

	# Insert in a nice order by z_index (optional, but keeps tree tidy)
	_insert_layer_sorted_by_z(parentNode, newLayer)

	world_layer_by_z_index[zIndex] = newLayer
	return newLayer

func _insert_layer_sorted_by_z(parentNode: Node, layerToAdd: TileMapLayer) -> void:
	# Add first so it becomes a child, then move to the desired position
	parentNode.add_child(layerToAdd)

	var desiredIndex := parentNode.get_child_count() - 1
	for i in range(parentNode.get_child_count()):
		var sibling := parentNode.get_child(i)
		if sibling == layerToAdd:
			continue
		if sibling is TileMapLayer and (sibling as TileMapLayer).z_index > layerToAdd.z_index:
			desiredIndex = i
			break

	parentNode.move_child(layerToAdd, desiredIndex)

func can_place_center(candidate: Vector2i) -> bool:
	for c in placed_centers:
		if c.distance_to(candidate) < MIN_DIST_CELLS:
			return false
	return true
