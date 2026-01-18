extends Node2D

signal wave_created(
	building_type: GameData.BuildingType,
	wave_start_position: Vector2,
	number_of_enemies: int,
)

var waves_data: Array = []

func building_created(building_type: GameData.BuildingType, place_position: Vector2) -> void:
	if building_type == GameData.BuildingType.PLAYER_CASTLE:
		return  # No waves from player castle

	var wave_info = {
		"building_type": building_type,
		"position": place_position,
		"enemies_to_spawn": 2 + int(GameData.current_day / 10),
		"rounds_since_last_spawn": 0,
	}
	waves_data.append(wave_info)

func check_waves() -> void:
	for wave in waves_data:
		var building_data = GameData.building_data.get(wave.building_type)
		var waves_apart_spawn = building_data.get("waves_apart_spawn")
		wave.rounds_since_last_spawn += 1
		if wave.rounds_since_last_spawn >= waves_apart_spawn:
			wave.rounds_since_last_spawn = 0
			wave_created.emit(
				wave.building_type,
				wave.position,
				wave.enemies_to_spawn,
			)
