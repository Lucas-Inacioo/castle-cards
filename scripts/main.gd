extends Node2D

#region Children Nodes
@export var card_container: HBoxContainer
#endregion

func _ready() -> void: 	get_window().content_scale_factor = 0.1

func _end_day_button_pressed() -> void:
	GameData.current_day += 1

	_check_cards_upgrade()

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
				card_container.upgrade_card_completed(card_type)

