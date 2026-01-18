extends Node2D

func structure_created(structure_type: GameData.BuildingType, place_position: Vector2) -> void:
	var structure_data = GameData.building_data.get(structure_type)
	var enemy_type = structure_data.get("enemy_type")

	if enemy_type != null:
		var enemy_scene: PackedScene = enemy_type if enemy_type is PackedScene else load(enemy_type)

		for i in range(3):
			var enemy = enemy_scene.instantiate() as Node2D
			add_child(enemy)

			# spawn somewhere in range initially
			enemy.global_position = place_position + Vector2(
				randi_range(-64, 64),
				randi_range(-64, 64)
			)
