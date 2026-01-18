extends HBoxContainer

func start_new_day() -> void:
	for card in get_children():
		if card.card_type == GameData.CardType.NONE:
			continue
		card.update_card_display()
