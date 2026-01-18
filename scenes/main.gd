extends Node2D

@export var wave_manager: Node2D
@export var end_day_button: TextureButton
@export var card_container: Node
@export var resource_slots_container: TextureRect
@export var upgrade_slots_container: TextureRect

func _ready() -> void:
	end_day_button.pressed.connect(_on_end_day_button_pressed)

func _on_end_day_button_pressed() -> void:
	_upgrade_cards()
	_set_cards_for_new_day()

	wave_manager.check_waves()
	wave_manager.fight_waves()

	# Notify UI elements about new day
	card_container.start_new_day()
	resource_slots_container.clear_slot()
	upgrade_slots_container.clear_slot()

func _upgrade_cards() -> void:
	for card_type in GameData.CardType.values():
		if card_type == GameData.CardType.NONE:
			continue

		var card_status = GameData.cards_status[card_type]
		if card_status.is_upgrading:
			card_status.rounds_until_upgrade_complete -= 1
			if card_status.rounds_until_upgrade_complete <= 0:
				card_status.is_upgrading = false
				card_status.upgrade_level += 1
				GameData.cards_status[card_type] = card_status

func _set_cards_for_new_day() -> void:
	var current_upgrading_card = GameData.current_upgrade_card
	var current_resource_card = GameData.current_resource_card

	# Start upgrading the selected card
	GameData.cards_status[current_upgrading_card].is_upgrading = true
	GameData.cards_status[current_upgrading_card].rounds_until_upgrade_complete = 2

	# Apply the effects of the selected resource card
	match current_resource_card:
		GameData.CardType.HEALTH:
			# Heal castle
			var current_health_level = GameData.cards_status[GameData.CardType.HEALTH].upgrade_level
			GameData.current_castle_health = max(
				GameData.current_castle_health + 5 * (1 + current_health_level),
				GameData.max_castle_health,
			)
		GameData.CardType.PEOPLE:
			pass
