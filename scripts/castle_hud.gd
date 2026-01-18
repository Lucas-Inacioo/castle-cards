extends Control

## Updates the top-left HUD digits (castle health + available units) reactively.

@export var _health_digit_1: TextureRect
@export var _health_digit_2: TextureRect

@export var _people_digit_1: TextureRect
@export var _people_digit_2: TextureRect

func _ready() -> void:
	# Initial paint
	_update_health(GameData.current_castle_health, GameData.max_castle_health)
	_update_people(GameData.available_units)

	# Reactive updates
	GameData.castle_health_changed.connect(_update_health)
	GameData.available_units_changed.connect(_update_people)

func _update_health(current_health: int, _max_health: int) -> void:
	_set_two_digits(current_health, _health_digit_1, _health_digit_2)

func _update_people(units: int) -> void:
	_set_two_digits(units, _people_digit_1, _people_digit_2)

func _set_two_digits(value: int, digit_1: TextureRect, digit_2: TextureRect) -> void:
	# HUD only has 2 digits; clamp to a sensible range.
	var clamped := clampi(value, 0, 99)
	var tens := int(clamped / 10)
	var ones := clamped % 10

	# Uses the same digit TextureRect script as the base UI elements (base_ui_element.gd)
	digit_1.setup(tens)
	digit_2.setup(ones)

	# Hide leading zero for prettier display.
	digit_1.visible = clamped >= 10
