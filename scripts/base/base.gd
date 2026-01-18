extends Marker2D

signal clicked(base_id: int)

@export var enemy_type: GameData.UnitType
@export var base_ui_element: Control

var highlight_overlay: ColorRect

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

	highlight_overlay = ColorRect.new()
	highlight_overlay.name = "HighlightOverlay"
	highlight_overlay.anchor_left = 0
	highlight_overlay.anchor_top = 0
	highlight_overlay.anchor_right = 1
	highlight_overlay.anchor_bottom = 1
	highlight_overlay.offset_left = 0
	highlight_overlay.offset_top = 0
	highlight_overlay.offset_right = 0
	highlight_overlay.offset_bottom = 0

	highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_overlay.visible = false

	# soft red tint for selectable state
	highlight_overlay.color = Color(1, 0.3, 0.3, 0.18)

	base_ui_element.add_child(highlight_overlay)
	base_ui_element.move_child(highlight_overlay, base_ui_element.get_child_count() - 1) # on top

func set_selectable(enabled: bool) -> void:
	_is_selectable = enabled
	_click_area.input_pickable = enabled
	_click_area.monitoring = enabled
	_update_visual()

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_visual()

func _update_visual() -> void:
	if highlight_overlay == null:
		return

	if _is_selected:
		highlight_overlay.visible = true
		highlight_overlay.color = Color(1, 0.2, 0.2, 0.35) # stronger
	elif _is_selectable:
		highlight_overlay.visible = true
		highlight_overlay.color = Color(1, 0.3, 0.3, 0.18) # lighter
	else:
		highlight_overlay.visible = false

func _on_click_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if !_is_selectable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(_base_id)
