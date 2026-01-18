extends AnimatedSprite2D

signal died

@export var walk_timer: Timer
@export var speed: float = 120.0
@export var max_health: int = 3

var current_health: int
var anchor_global_position: Vector2
var target_global_position: Vector2
var is_from_wave: bool = false

func setup(anchor_pos: Vector2, new_is_from_wave: bool) -> void:
  global_position = anchor_pos
  anchor_global_position = anchor_pos
  is_from_wave = new_is_from_wave
  current_health = max_health

  _pick_new_target()

func take_damage(amount: int) -> void:
  current_health -= amount
  if current_health <= 0:
    die()

func die() -> void:
  died.emit()
  queue_free()

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
  if is_from_wave:
    target_global_position = anchor_global_position
    return

  var ox := randi_range(-32, 32)
  var oy := randi_range(-32, 32)
  target_global_position = anchor_global_position + Vector2(ox, oy)
  walk_timer.wait_time = randf_range(2.0, 4.0)
  flip_h = target_global_position.x < global_position.x
