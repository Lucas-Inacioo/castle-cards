extends HBoxContainer

func upgrade_card_completed(card_type: GameData.CardType) -> void:
  for card in get_children():
    if card.card_type == card_type:
      card.update_card_display()
      break