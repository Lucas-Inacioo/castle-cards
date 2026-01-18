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
		bases[base.name] = base.global_position

func schedule_fight(base_id: int) -> void:
	scheduled_fights.append(base_id)

func fight_waves() -> void:
	for base_id in scheduled_fights:
		var base_position = bases.get(str(base_id))
		var castle_position = bases.get("0")
		if base_position and castle_position:
			var ally := _spawn_ally(castle_position)
			var enemy := _spawn_enemy(base_position)

			ally.set_attributes("soldier")
			enemy.set_attributes("orc")

			ally.move_towards(enemy)
			enemy.move_towards(ally)

	scheduled_fights.clear()

func _spawn_ally(pos: Vector2) -> Node2D:
	var scene = load("res://scenes/units/soldier.tscn")
	var inst = scene.instantiate()
	inst.global_position = pos
	get_parent().add_child(inst)
	return inst

func _spawn_enemy(pos: Vector2) -> Node2D:
	var scene = load("res://scenes/units/orc.tscn")
	var inst = scene.instantiate()
	inst.global_position = pos
	get_parent().add_child(inst)
	return inst
