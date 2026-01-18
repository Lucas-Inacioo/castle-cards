extends Node2D

func building_created(building_type: GameData.BuildingType, place_position: Vector2) -> void:
	if building_type == GameData.BuildingType.PLAYER_CASTLE:
		return  # No enemies spawn from player castle

	var building_data = GameData.building_data.get(building_type)

	var building_scene = building_data.get("scene")
	var building_instance: Node2D = load(building_scene).instantiate()

	# marker in building space (since instance is at 0,0 and not really placed)
	var marker_pos_in_building_space: Vector2 = building_instance.get_node("EnemySpawner").global_position

	# compute anchor cell (top-left used cell) like your stamping code
	var tilemap_root: Node = building_instance.get_node("Tilemap")
	var layers: Array[TileMapLayer] = []
	for child in tilemap_root.get_children():
		if child is TileMapLayer:
			layers.append(child)

	var anchor_cell := Vector2i.ZERO
	for layer in layers:
		var rect := layer.get_used_rect()
		anchor_cell.x = min(anchor_cell.x, rect.position.x)
		anchor_cell.y = min(anchor_cell.y, rect.position.y)

	var ref_layer: TileMapLayer = layers[0]
	var anchor_pos_in_building_space: Vector2 = ref_layer.to_global(ref_layer.map_to_local(anchor_cell))

	# now convert your placed position (anchor) into building origin
	var building_origin_world: Vector2 = place_position - anchor_pos_in_building_space

	# final correct spawn position
	var spawn_world: Vector2 = building_origin_world + marker_pos_in_building_space
	var enemy_type = building_data.get("enemy_type")
	if enemy_type != null:
		var enemy_scene = load(enemy_type)

		for i in range(3):
			var enemy = enemy_scene.instantiate()
			enemy.setup(spawn_world)
			add_child(enemy)
