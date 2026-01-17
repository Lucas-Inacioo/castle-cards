extends Node2D

const MIN_DIST_CELLS := 32
const PLAYER_CASTLE_SCENE = preload("res://scenes/player_castle.tscn")
const ENEMY_BASE_VARIANT_1_SCENE= preload("res://scenes/enemy_1.tscn")

#region Children Nodes
@export var card_container: HBoxContainer
@export var slots_container: HBoxContainer
@export var tileMapGround: TileMapLayer
#endregion

# Used as cache for already existent layers
var worldLayerByZIndex: Dictionary = {}

# To avoid placing structures on the same spot
var placed_centers: Array[Vector2i] = []

func _ready() -> void:
	get_window().content_scale_factor = 0.1

	# Register the ground layer as the layer for its z_index
	worldLayerByZIndex[tileMapGround.z_index] = tileMapGround

	# Spawn player castle at origin
	stamp_structure_scene(PLAYER_CASTLE_SCENE, Vector2i(0, 0))

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
		stamp_structure_scene(ENEMY_BASE_VARIANT_1_SCENE, candidate)

	# Optional: if no valid spot was found
	print("Failed to place enemy base (no valid location found)")

func stamp_structure_scene(
	structureScene: PackedScene,
	placeCell: Vector2i,
	tileMapNodePath: NodePath = ^"Tilemap",
	overwriteExisting: bool = true
) -> void:
	var structureInstance := structureScene.instantiate() as Node
	var sourceTileMap := structureInstance.get_node_or_null(tileMapNodePath)
	if sourceTileMap == null:
		push_error("stamp_structure_scene: structure has no node at path %s" % [tileMapNodePath])
		structureInstance.queue_free()
		return

	# Collect all TileMapLayers from the structure's TileMap node
	var sourceLayers: Array[TileMapLayer] = []
	for child in sourceTileMap.get_children():
		if child is TileMapLayer:
			sourceLayers.append(child)

	if sourceLayers.is_empty():
		push_warning("stamp_structure_scene: no TileMapLayer children found under %s" % [tileMapNodePath])
		structureInstance.queue_free()
		return

	# Compute one common anchor for ALL layers so they align together.
	# This uses the minimum used_rect.position across layers (top-left in map coords).
	var anchorCell := _compute_anchor_cell(sourceLayers)

	for sourceLayer in sourceLayers:
		var targetLayer := _get_or_create_world_layer_for_z(sourceLayer.z_index)

		# Copy cells
		for cell in sourceLayer.get_used_cells():
			var sourceId := sourceLayer.get_cell_source_id(cell)
			if sourceId == -1:
				continue

			var atlasCoords := sourceLayer.get_cell_atlas_coords(cell)
			var alternativeTile := sourceLayer.get_cell_alternative_tile(cell)

			var targetCell := placeCell + (cell - anchorCell)

			if not overwriteExisting and targetLayer.get_cell_source_id(targetCell) != -1:
				continue

			targetLayer.set_cell(targetCell, sourceId, atlasCoords, alternativeTile)

		# Force immediate refresh if you need it this frame
		targetLayer.update_internals()

	structureInstance.queue_free()

	placed_centers.append(placeCell)

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
	if worldLayerByZIndex.has(zIndex):
		return worldLayerByZIndex[zIndex] as TileMapLayer

	# Maybe exists in the scene tree but not cached yet?
	var parentNode := tileMapGround.get_parent()
	for child in parentNode.get_children():
		if child is TileMapLayer and (child as TileMapLayer).z_index == zIndex:
			worldLayerByZIndex[zIndex] = child
			return child as TileMapLayer

	# Create it
	var newLayer := TileMapLayer.new()
	newLayer.name = "TileMapLayer_z_%d" % zIndex
	newLayer.z_index = zIndex
	newLayer.z_as_relative = tileMapGround.z_as_relative
	newLayer.tile_set = tileMapGround.tile_set

	# Insert in a nice order by z_index (optional, but keeps tree tidy)
	_insert_layer_sorted_by_z(parentNode, newLayer)

	worldLayerByZIndex[zIndex] = newLayer
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
