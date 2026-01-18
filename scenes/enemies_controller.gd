extends Node2D

func structure_created(structure_type: GameData.BuildingType, place_position: Vector2) -> void:
	if structure_type == GameData.BuildingType.PLAYER_CASTLE:
		return  # No enemies spawn from player castle

	var structure_data = GameData.building_data.get(structure_type)

	var structure_scene = structure_data.get("scene")
	var structure_instance = load(structure_scene).instantiate()
	var enemy_spawner_position = structure_instance.get_node("EnemySpawner").global_position
	print(place_position)
	print(enemy_spawner_position)
	print("Spawning enemies at: ", place_position + enemy_spawner_position)

	var enemy_type = structure_data.get("enemy_type")
	if enemy_type != null:
		var enemy_scene = load(enemy_type)

		for i in range(3):
			var enemy = enemy_scene.instantiate()
			enemy.setup(place_position + enemy_spawner_position)
			add_child(enemy)
