extends Marker2D

signal clicked(base_id: int)

@export var enemy_type: GameData.UnitType
@export var base_ui_element: Control

var _base_id: int
var _is_selectable = false
var _is_selected = false
var _default_modulate = Color(1, 1, 1)

var _click_area: Area2D
var _click_shape: CollisionShape2D

func _ready() -> void:
	_base_id = int(name)

	if base_ui_element != null:
		_default_modulate = base_ui_element.modulate

	_click_area = Area2D.new()
	_click_area.input_pickable = false
	_click_area.monitoring = false
	add_child(_click_area)

	_click_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 28.0
	_click_shape.shape = circle
	_click_area.add_child(_click_shape)

	_click_area.input_event.connect(_on_click_area_input_event)

func set_selectable(enabled: bool) -> void:
	_is_selectable = enabled
	_click_area.input_pickable = enabled
	_click_area.monitoring = enabled
	_update_visual()

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_visual()

func _update_visual() -> void:
	if base_ui_element == null:
		return

	if _is_selected:
		base_ui_element.modulate = Color(0.7, 1.0, 0.7) # selected
	elif _is_selectable:
		base_ui_element.modulate = Color(1.0, 1.0, 0.7) # selectable
	else:
		base_ui_element.modulate = _default_modulate

func _on_click_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if !_is_selectable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(_base_id)
