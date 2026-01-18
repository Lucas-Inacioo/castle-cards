extends AnimatedSprite2D

@export var walk_timer: Timer
@export var speed: float = 120.0

var anchor_global_position: Vector2
var tile_size: Vector2 = Vector2(32, 32)
var max_range_tiles: int = 3

var target_global_position: Vector2

func setup(anchor_pos: Vector2, tile_size_px: Vector2, max_tiles: int) -> void:
	anchor_global_position = anchor_pos
	tile_size = tile_size_px
	max_range_tiles = max_tiles

	_pick_new_target()

func _ready() -> void:
	if walk_timer:
		walk_timer.timeout.connect(_pick_new_target)
		walk_timer.start()
	play("Idle")

func _process(delta: float) -> void:
	# Safety in case setup wasn't called yet
	if anchor_global_position == Vector2.ZERO:
		return

	global_position = global_position.move_toward(target_global_position, speed * delta)

	if global_position.distance_to(target_global_position) < 2.0:
		play("Idle")
	else:
		play("Walk")

func _pick_new_target() -> void:
	# Always pick relative to anchor, so it NEVER drifts out of range
	var ox := randi_range(-max_range_tiles, max_range_tiles)
	var oy := randi_range(-max_range_tiles, max_range_tiles)

	target_global_position = anchor_global_position + Vector2(
		ox * tile_size.x,
		oy * tile_size.y
	)

	# Make timer a random value between 2 and 4 seconds
	walk_timer.wait_time = randf_range(2.0, 4.0)
	walk_timer.start()

	# Flip sprite based on direction
	if target_global_position.x < global_position.x:
		flip_h = true
	else:
		flip_h = false
