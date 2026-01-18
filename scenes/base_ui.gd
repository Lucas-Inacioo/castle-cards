extends Control

@export var clock_container: Control
@export var clock_element: TextureRect
@export var shield_element: TextureRect
@export var attack_element: TextureRect

func setup(base_data: Dictionary) -> void:
	var rounds_between_attacks = base_data.get("rounds_between_attacks")
	var shield = base_data.get("shield", 0)
	var attack = base_data.get("attack", 0)

	if rounds_between_attacks != null:
		clock_element.setup(rounds_between_attacks)
	else:
		clock_container.hide()
		shield_element.setup(shield)
		attack_element.setup(attack)
