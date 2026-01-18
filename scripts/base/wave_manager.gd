extends Node2D

signal base_clicked(base_id: int)

#region Children Nodes
@export var enemy_base_markers: Node2D
#endregion

var bases = {}

var scheduled_fights = []
var scheduled_attacks = []
var ally_wave_id = 0
var enemy_wave_id = 0
var _defense_selection_enabled = false

var _base_selection_enabled := false

func _ready() -> void:
	# Initialize enemy base positions using marker ID
	for base in enemy_base_markers.get_children():
		var base_data = GameData.bases_data.get(int(base.name))
		bases[base.name] = {
			"position": base.global_position,
			"enemy_type": base.get("enemy_type"),
			"rounds_between_attacks": base_data.get("rounds_between_attacks"),
			"rounds_since_last_attack": 0,
			"base_shield": base_data.get("base_shield"),
			"base_attack": base_data.get("base_attack")
		}
		base.base_ui_element.setup(base_data)

func check_waves() -> void:
	for base_id in bases.keys():
		if base_id == "0":
			continue  # Skip castle base
		var base_info = bases[base_id]
		base_info.rounds_since_last_attack += 1
		var rounds_between_attacks = base_info.rounds_between_attacks
		if base_info.rounds_since_last_attack >= rounds_between_attacks:
			attack_castle(int(base_id))
			base_info.rounds_since_last_attack = 0
		bases[base_id] = base_info

	for base in enemy_base_markers.get_children():
		if base.name == "0":
			continue  # Skip castle base
		var base_info = bases[base.name]
		var remaining_rounds = base_info.rounds_between_attacks - base_info.rounds_since_last_attack
		base.base_ui_element.setup({
			"rounds_between_attacks": remaining_rounds,
			"base_shield": base_info.get("base_shield"),
			"base_attack": base_info.get("base_attack"),
		})

func schedule_fight(base_id: int) -> void:
	scheduled_fights.append(base_id)

func schedule_attack(base_id: int) -> void:
	scheduled_attacks.append(base_id)

func fight_waves() -> void:
	var castle_id = 0
	for base_id in scheduled_fights:
		var base_position = bases.get(str(base_id))
		var castle_position = bases.get(str(castle_id))
		if base_position and castle_position:
			var enemy_type = bases[ str(base_id) ].enemy_type

			var ally = _spawn_ally(castle_position.position)
			var enemy = _spawn_enemy(base_position.position, enemy_type)

			ally.set_attributes(GameData.UnitType.SOLDIER)
			enemy.set_attributes(enemy_type)

			ally.move_towards(enemy)
			enemy.move_towards(ally)

	for base_id in scheduled_attacks:
		attack_base(int(base_id))

	scheduled_fights.clear()
	scheduled_attacks.clear()

func attack_castle(base_id: int) -> void:
	var base_position = bases.get(str(base_id))
	var castle_position = bases.get("0")
	if base_position and castle_position:
		var enemy_type = bases[ str(base_id) ].enemy_type

		var ally = _spawn_ally(castle_position.position)
		var enemy = _spawn_enemy(base_position.position, enemy_type)

		ally.set_attributes(GameData.UnitType.ATTACK_PLACEHOLDER)
		enemy.set_attributes(enemy_type)

		# Make the ally not move so it stays inside the castle
		ally.move_speed = 0.0
		ally.move_towards(enemy)
		enemy.move_towards(ally)

		# Apply damage to castle directly
		var enemy_data = GameData.units_data.get(enemy_type)
		var enemy_damage = enemy_data.get("damage", 1)
		GameData.current_castle_health -= enemy_damage
		print("Castle attacked! Current health: ", GameData.current_castle_health)

func attack_base(base_id: int) -> void:
	var base_info = bases.get(str(base_id))
	var castle_info = bases.get("0")
	if base_info == null or castle_info == null:
		return

	var enemy_type = base_info.enemy_type

	var ally = _spawn_ally(castle_info.position)
	var enemy = _spawn_enemy(base_info.position, enemy_type)

	ally.set_attributes(GameData.UnitType.SOLDIER)
	enemy.set_attributes(enemy_type)

	# Make the enemy not move (stationary defender)
	enemy.move_speed = 0.0

	ally.move_towards(enemy)
	enemy.move_towards(ally)

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

func set_base_selected(base_id: int, selected: bool) -> void:
	var base_node = enemy_base_markers.get_node_or_null(str(base_id))
	if base_node == null:
		return
	base_node.set_selected(selected)

func clear_all_base_selections() -> void:
	for base in enemy_base_markers.get_children():
		if base.name == "0":
			continue
		base.set_selected(false)
		base.set_selectable(false)

func _on_base_clicked(base_id: int) -> void:
	base_clicked.emit(base_id)

func reset_base_timer(base_id: int) -> void:
	var base_key = str(base_id)
	var base_info = bases.get(base_key, null)
	if base_info == null:
		return

	# So that check_waves() increments it to 0 on the same day
	base_info.rounds_since_last_attack = -1
	bases[base_key] = base_info

func enable_base_selection(enabled: bool) -> void:
	if _base_selection_enabled == enabled:
		return
	_base_selection_enabled = enabled

	for base in enemy_base_markers.get_children():
		# Never allow selecting the castle
		if base.name == "0":
			continue

		# If you track destroyed bases, don't allow selecting them
		var base_info = bases.get(base.name, null)
		if base_info != null and base_info.get("destroyed", false):
			base.set_selectable(false)
			base.set_selected(false)
			continue

		base.set_selectable(enabled)

		# Connect/disconnect the click relay
		if enabled:
			if !base.clicked.is_connected(_on_base_clicked):
				base.clicked.connect(_on_base_clicked)
		else:
			if base.clicked.is_connected(_on_base_clicked):
				base.clicked.disconnect(_on_base_clicked)
