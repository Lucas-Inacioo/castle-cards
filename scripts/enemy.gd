extends AnimatedSprite2D

@export var walk_timer: Timer
@export var speed: float = 120.0

var anchor_global_position: Vector2
var target_global_position: Vector2

func setup(anchor_pos: Vector2) -> void:
	global_position = anchor_pos
	anchor_global_position = anchor_pos

	_pick_new_target()

func _ready() -> void:
	walk_timer.timeout.connect(_pick_new_target)
	walk_timer.start()
	play("Idle")

func _process(delta: float) -> void:
	global_position = global_position.move_toward(target_global_position, speed * delta)

	if global_position.distance_to(target_global_position) < 2.0:
		play("Idle")
	else:
		play("Walk")

func _pick_new_target() -> void:
	# Always pick relative to anchor, so it NEVER drifts out of range
	var ox := randi_range(-32, 32)
	var oy := randi_range(-32, 32)

	target_global_position = anchor_global_position + Vector2(
		ox,
		oy,
	)

	# Make timer a random value between 2 and 4 seconds
	walk_timer.wait_time = randf_range(2.0, 4.0)

	# Flip sprite based on direction
	if target_global_position.x < global_position.x:
		flip_h = true
	else:
		flip_h = false
