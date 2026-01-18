extends VBoxContainer

func wave_created(
  building_type: GameData.BuildingType,
	wave_start_position: Vector2,
	number_of_enemies: int
) -> void:
  var wave_ui_element_scene = load("res://scenes/wave_ui_element.tscn")
  var wave_ui_element = wave_ui_element_scene.instantiate()
  wave_ui_element.setup(building_type, wave_start_position, number_of_enemies)
  add_child(wave_ui_element)
  waves.append(wave_ui_element)