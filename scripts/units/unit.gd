class_name Unit

extends CharacterBody2D

signal died(unit: Node)

@export var move_speed: float = 80.0
@export var attack_range: float = 32.0
@export var hp: int = 3
@export var damage: int = 1
@export var animation: AnimatedSprite2D
@export var return_range: float = 4.0

var spawn_position: Vector2
var returning = false

var opponent = null
var in_combat = false
var dead = false
var _combat_loop_running = false

func set_attributes(unit_type: GameData.UnitType) -> void:
	var attrs = GameData.units_data.get(unit_type)
	hp = attrs.get("hp", hp)
	damage = attrs.get("damage", damage)

func move_towards(opponent_node) -> void:
	spawn_position = global_position
	opponent = opponent_node
	in_combat = false
	dead = false
	_combat_loop_running = false
	velocity = Vector2.ZERO
	if opponent.global_position.x < global_position.x:
		animation.flip_h = true
	else:
		animation.flip_h = false
	_play("Walk")

func _physics_process(_delta: float) -> void:
	if dead:
		return

	# Once combat starts, distance never changes again
	if in_combat:
		return

	if returning:
		var to_home = spawn_position - global_position
		if to_home.length() <= return_range:
			returning = false
			velocity = Vector2.ZERO
			move_and_slide()
			_play("Idle")
			return

		velocity = to_home.normalized() * move_speed
		move_and_slide()
		_play("Walk")
		return

	if opponent == null and not returning:
		queue_free()
		return

	var dist = global_position.distance_to(opponent.global_position)
	if dist <= attack_range:
		_lock_combat()
		return

	# move in straight line
	velocity = (opponent.global_position - global_position).normalized() * move_speed
	move_and_slide()
	_play("Walk")

func _lock_combat() -> void:
	if in_combat or dead:
		return

	in_combat = true
	velocity = Vector2.ZERO
	move_and_slide()

	if opponent == null or !is_instance_valid(opponent):
		return

	# Lock opponent too
	if !opponent.in_combat:
		opponent._lock_combat_from(self)

	# IMPORTANT: start loop on the driver (smaller instance_id)
	if get_instance_id() < opponent.get_instance_id():
		_start_combat_loop()
	else:
		opponent._start_combat_loop()

func _lock_combat_from(other) -> void:
	# Just lock, don't start loops here
	opponent = other
	in_combat = true
	velocity = Vector2.ZERO
	move_and_slide()

func _start_combat_loop() -> void:
	if _combat_loop_running or dead:
		return
	if opponent == null or !is_instance_valid(opponent) or opponent.dead:
		return
	_combat_loop_running = true
	_combat_loop()  # async; runs until first await

func _combat_loop() -> void:
	while true:
		if dead:
			break
		if opponent == null or !is_instance_valid(opponent) or opponent.dead:
			break

		# Turn: both attack at the same time
		_play("Attack")
		opponent._play("Attack")

		# Wait until BOTH finished Attack (no missing-signal issues)
		await _wait_both_attack_finished()

		# Opponent might have died/freed during await (rare, but guard anyway)
		if opponent == null or !is_instance_valid(opponent) or opponent.dead:
			break

		# Simultaneous damage (both can die)
		var opp = opponent
		var my_next_hp = hp - opp.damage
		var opp_next_hp = opp.hp - damage

		hp = my_next_hp
		opp.hp = opp_next_hp

		var opp_dies = opp.hp <= 0
		var self_dies = hp <= 0

		# Important: defeat opponent first so we don't lose the reference if we die
		if opp_dies:
			opp.defeat()
		if self_dies:
			defeat()

		if opp_dies or self_dies:
			break

	# combat ended for the driver
	_combat_loop_running = false
	if !dead:
		opponent = null
		in_combat = false
		returning = true
		_play("Walk")

func _wait_both_attack_finished() -> void:
	while true:
		var self_attacking = animation.is_playing() and animation.animation == "Attack"

		var opp_attacking = false
		if opponent.animation != null:
			opp_attacking = opponent.animation.is_playing() and opponent.animation.animation == "Attack"

		if !self_attacking and !opp_attacking:
			return

		await get_tree().process_frame

func defeat() -> void:
	if dead:
		return
	dead = true
	died.emit(self)
	in_combat = true
	opponent = null
	velocity = Vector2.ZERO
	move_and_slide()

	_play("Die")
	await animation.animation_finished
	queue_free()

func _play(animation_name: String) -> void:
	animation.play(animation_name)
