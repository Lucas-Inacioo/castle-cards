extends Node2D

#region Children Nodes
@export var card_container: HBoxContainer
@export var slots_container: HBoxContainer
#endregion

func _ready() -> void: 	get_window().content_scale_factor = 0.1

func _end_day_button_pressed() -> void:
	GameData.current_day += 1

	_check_cards_upgrade()
	_set_cards_for_new_day()

	card_container.start_new_day()
	slots_container.start_new_day()

func _check_cards_upgrade() -> void:
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
	var current_updating_card = GameData.current_upgrade_card
	var current_resource_card = GameData.current_resource_card

	GameData.cards_status[current_updating_card].is_upgrading = true
	GameData.cards_status[current_updating_card].rounds_until_upgrade_complete = 2
