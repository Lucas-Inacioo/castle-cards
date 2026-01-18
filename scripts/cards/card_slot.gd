extends TextureRect

signal defense_card_dropped()
signal attack_card_dropped()

const EMPTY_RESOURCE_REGION = Rect2(Vector2(251, 73), Vector2(23, 34))
const EMPTY_UPGRADE_REGION = Rect2(Vector2(251, 109), Vector2(23, 34))

@export var slot_type: GameData.SlotType

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data.has("card_type") || not data.has("texture"):
		return false

	var card_type: GameData.CardType = data["card_type"]
	match slot_type:
		GameData.SlotType.RESOURCE:
			if GameData.current_upgrade_card == card_type:
				return false
		GameData.SlotType.UPGRADE:
			if GameData.current_resource_card == card_type:
				return false

	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var card_type: GameData.CardType = data["card_type"]

	var dropped_tex: Texture2D = data["texture"]
	texture = dropped_tex.duplicate(true)

	match slot_type:
		GameData.SlotType.RESOURCE:
			GameData.current_resource_card = card_type
			if card_type == GameData.CardType.DEFENSE:
				defense_card_dropped.emit()
			if card_type == GameData.CardType.ATTACK:
				attack_card_dropped.emit()
		GameData.SlotType.UPGRADE:
			GameData.current_upgrade_card = card_type

func clear_slot() -> void:
	match slot_type:
		GameData.SlotType.RESOURCE:
			GameData.current_resource_card = GameData.CardType.NONE
			texture.region = EMPTY_RESOURCE_REGION
		GameData.SlotType.UPGRADE:
			GameData.current_upgrade_card = GameData.CardType.NONE
			texture.region = EMPTY_UPGRADE_REGION
