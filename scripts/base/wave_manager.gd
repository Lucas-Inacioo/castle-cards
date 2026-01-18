extends Node2D

#region Children Nodes
@export var enemy_base_markers: Node2D
#endregion

var bases = {}

var scheduled_fights = []

var ally_wave_id = 0
var enemy_wave_id = 0

func _ready() -> void:
	# Initialize enemy base positions using marker ID
	for base in enemy_base_markers.get_children():
		var base_data = GameData.bases_data.get(int(base.name))
		bases[base.name] = {
			"position": base.global_position,
			"enemy_type": base.get("enemy_type"),
			"rounds_between_attacks": base_data.get("rounds_between_attacks"),
			"shield": base_data.get("base_shield"),
			"attack": base_data.get("base_attack")
		}
		base.base_ui_element.setup(base_data)

func schedule_fight(base_id: int) -> void:
	scheduled_fights.append(base_id)

func fight_waves() -> void:
	var castle_id = 0
	for base_id in scheduled_fights:
		var base_position = bases.get(str(base_id))
		var castle_position = bases.get(str(castle_id))
		if base_position and castle_position:
			var enemy_type = bases[ str(base_id) ].enemy_type

			var ally := _spawn_ally(castle_position.position)
			var enemy := _spawn_enemy(base_position.position, enemy_type)

			ally.set_attributes(GameData.UnitType.SOLDIER)
			enemy.set_attributes(enemy_type)

			ally.move_towards(enemy)
			enemy.move_towards(ally)

	scheduled_fights.clear()

func _spawn_ally(pos: Vector2) -> Node2D:
	var scene = load("res://scenes/units/soldier.tscn")
	var inst = scene.instantiate()
	inst.global_position = pos
	get_parent().add_child(inst)
	return inst

func _spawn_enemy(pos: Vector2, enemy_type: GameData.UnitType) -> Node2D:
	var scene = GameData.units_data.get(enemy_type).get("scene")
	var inst = scene.instantiate()
	inst.global_position = pos
	get_parent().add_child(inst)
	return inst
