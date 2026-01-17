extends TextureRect

@export var slot_type: GameData.SlotType

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data.has("card_type") || not data.has("texture"):
		return false

	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var card_type: GameData.CardType = data["card_type"]
	texture = data["texture"]

	match slot_type:
		GameData.SlotType.RESOURCE:
			GameData.current_resource_card = card_type as GameData.CardType
		GameData.SlotType.UPGRADE:
			GameData.current_upgrade_card = card_type as GameData.CardType
