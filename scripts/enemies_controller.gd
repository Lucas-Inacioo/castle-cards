extends Node2D

func building_created(building_type: GameData.BuildingType, place_position: Vector2) -> void:
	if building_type == GameData.BuildingType.PLAYER_CASTLE:
		return  # No enemies spawn from player castle

	var building_data = GameData.building_data.get(building_type)

	var building_scene = building_data.get("scene")
	var building_instance: Node2D = load(building_scene).instantiate()

	# marker in building space (since instance is at 0,0 and not really placed)
	var enemy_spawner = building_instance.get_node("EnemySpawner")
	var marker_pos_in_building_space: Vector2 = enemy_spawner.global_position

	# compute anchor cell (top-left used cell) like your stamping code
	var tilemap_root: Node = building_instance.get_node("Tilemap")
	var layers: Array[TileMapLayer] = []
	for child in tilemap_root.get_children():
		if child is TileMapLayer:
			layers.append(child)

	var anchor_cell = Vector2i.ZERO
	for layer in layers:
		var rect = layer.get_used_rect()
		anchor_cell.x = min(anchor_cell.x, rect.position.x)
		anchor_cell.y = min(anchor_cell.y, rect.position.y)

	var ref_layer: TileMapLayer = layers[0]
	var anchor_pos_in_building_space: Vector2 = ref_layer.to_global(
		ref_layer.map_to_local(anchor_cell)
	)

	# now convert your placed position (anchor) into building origin
	var building_origin_world: Vector2 = place_position - anchor_pos_in_building_space

	# final correct spawn position
	var spawn_world: Vector2 = building_origin_world + marker_pos_in_building_space
	var enemy_type = building_data.get("enemy_type")
	if enemy_type != null:
		var enemy_scene = load(enemy_type)

		for i in range(3):
			var enemy = enemy_scene.instantiate()
			enemy.setup(spawn_world, false)
			add_child(enemy)

func wave_created(
	building_type: GameData.BuildingType,
	wave_start_position: Vector2,
	number_of_enemies: int,
) -> void:
	var building_data = GameData.building_data.get(building_type)

	var vector_to_castle = (Vector2.ZERO - wave_start_position).normalized()
	var spawn_offset_distance = 50.0
	var spawn_position = wave_start_position + vector_to_castle * spawn_offset_distance

	var wave_defense_value = building_data.get("defense") * number_of_enemies
	var wave_attack_value = building_data.get("attack") * number_of_enemies

	# Root node representing the wave in WORLD space
	var wave_root = Node2D.new()
	wave_root.global_position = spawn_position
	add_child(wave_root)

	# Indicator ABOVE the wave (LOCAL space under wave_root)
	var rounds_until_castle = 5
	var waves_ui = load("res://scenes/wave_ui.tscn").instantiate()
	waves_ui.setup(rounds_until_castle, wave_defense_value, wave_attack_value)
	waves_ui.position = Vector2(0, -75)
	waves_ui.z_index = 1000
	wave_root.add_child(waves_ui)

	# Optional: container just to organize the scene tree
	var enemies_container = Node2D.new()
	enemies_container.position = Vector2.ZERO
	wave_root.add_child(enemies_container)

	# Spawn enemies (GLOBAL positions because enemy.setup uses global_position)
	var enemy_type = building_data.get("enemy_type")
	if enemy_type == null:
		return

	var enemy_scene = load(enemy_type)

	for i in range(number_of_enemies):
		var random_offset = Vector2(randi_range(-6, 6), randi_range(-6, 6))
		var enemy: AnimatedSprite2D = enemy_scene.instantiate()
		enemies_container.add_child(enemy)

		# IMPORTANT: pass GLOBAL
		enemy.setup(spawn_position + random_offset, true)
