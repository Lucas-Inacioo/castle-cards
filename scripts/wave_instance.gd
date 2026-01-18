extends Node2D

signal enemy_count_changed(new_count: int)
signal cleared

var building_type: int
var wave_start_position: Vector2
var rounds_until_castle: int
var wave_attack_value: int
var wave_defense_value: int

var enemies: Array[Node] = []

func setup(
  new_building_type: int,
  new_wave_start_position: Vector2,
  new_rounds_until_castle: int,
  new_wave_attack_value: int,
  new_wave_defense_value: int
) -> void:
  building_type = new_building_type
  wave_start_position = new_wave_start_position
  rounds_until_castle = new_rounds_until_castle
  wave_attack_value = new_wave_attack_value
  wave_defense_value = new_wave_defense_value

func add_enemy(enemy: Node) -> void:
  enemies.append(enemy)

  # Enemy must emit "died" (we add that in step 2)
  enemy.died.connect(_on_enemy_died.bind(enemy))

  enemy_count_changed.emit(enemies.size())

func _on_enemy_died(enemy: Node) -> void:
  enemies.erase(enemy)
  enemy_count_changed.emit(enemies.size())

  if enemies.is_empty():
    cleared.emit()
    queue_free()
