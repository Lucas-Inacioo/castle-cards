extends Camera2D

const MIN_ZOOM = 0.1
const MAX_ZOOM = 2.9

# Better feel than a big additive step:
const ZOOM_FACTOR = 1.12         # wheel up/down multiplies/divides zoom
const ZOOM_SMOOTH = 14.0         # higher = snappier smoothing
const PAN_SPEED = 1.0

# Your world bounds (center of camera must stay inside these, adjusted by viewport)
@export var world_left = -3000
@export var world_right = 3000.0
@export var world_top = -1400.0
@export var world_bottom = 2000.0

var target_zoom = 1.0

func _ready() -> void:
	target_zoom = zoom.x
	_clamp_to_bounds()

func _unhandled_input(event: InputEvent) -> void:
	# Zoom with wheel
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom *= ZOOM_FACTOR
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom /= ZOOM_FACTOR

		target_zoom = clampf(target_zoom, MIN_ZOOM, MAX_ZOOM)

	# Pan with RMB drag
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		global_position -= event.relative / zoom.x * PAN_SPEED
		_clamp_to_bounds()

func _process(delta: float) -> void:
	# Smooth zoom toward target
	var desired = Vector2(target_zoom, target_zoom)
	var alpha = 1.0 - exp(-ZOOM_SMOOTH * delta) # framerate-independent smoothing
	zoom = zoom.lerp(desired, alpha)

	_clamp_to_bounds()

func _clamp_to_bounds() -> void:
	var viewport_size = get_viewport_rect().size
	var half_view = viewport_size * 0.5 / zoom  # world units visible from center

	var min_x = world_left + half_view.x
	var max_x = world_right - half_view.x
	var min_y = world_top + half_view.y
	var max_y = world_bottom - half_view.y

	# If you're zoomed out so far that the view is larger than the world,
	# lock camera to center (otherwise min>max and clamp breaks).
	if min_x > max_x:
		global_position.x = (world_left + world_right) * 0.5
	else:
		global_position.x = clamp(global_position.x, min_x, max_x)

	if min_y > max_y:
		global_position.y = (world_top + world_bottom) * 0.5
	else:
		global_position.y = clamp(global_position.y, min_y, max_y)
