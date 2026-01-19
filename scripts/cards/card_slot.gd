extends TextureRect

signal defense_card_dropped()
signal attack_card_dropped()

const EMPTY_RESOURCE_REGION = Rect2(Vector2(251, 73), Vector2(23, 34))
const EMPTY_UPGRADE_REGION = Rect2(Vector2(251, 109), Vector2(23, 34))

@export var slot_type: GameData.SlotType

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data.has("card_type") || not data.has("texture"):
		return false

	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var card_type: GameData.CardType = data["card_type"]
	var dropped_tex: Texture2D = data["texture"]

	# Put dropped texture in THIS slot
	texture = dropped_tex.duplicate(true)

	# Helper: find sibling slot by slot_type and clear it using its own clear_slot()
	var clear_sibling_slot := func(target_slot_type: GameData.SlotType) -> void:
		var parent := get_parent()
		if parent == null:
			return

		for child in parent.get_children():
			if child == self:
				continue
			if child.get("slot_type") == target_slot_type:
				# Use the slot's own clearing logic (restores EMPTY_*_REGION)
				if child.has_method("clear_slot"):
					child.clear_slot()
				return

	match slot_type:
		GameData.SlotType.RESOURCE:
			# If this card is already in upgrade, clear upgrade slot properly
			if GameData.current_upgrade_card == card_type:
				clear_sibling_slot.call(GameData.SlotType.UPGRADE)

			# Clean up planned selections
			GameData.planned_defense_base_ids = []
			GameData.planned_attack_base_ids = []
			GameData.current_resource_card = card_type

			if card_type == GameData.CardType.DEFENSE:
				defense_card_dropped.emit()
			elif card_type == GameData.CardType.ATTACK:
				attack_card_dropped.emit()

		GameData.SlotType.UPGRADE:
			# If this card is already in resource, clear resource slot properly
			if GameData.current_resource_card == card_type:
				clear_sibling_slot.call(GameData.SlotType.RESOURCE)

			GameData.current_upgrade_card = card_type

func clear_slot() -> void:
	match slot_type:
		GameData.SlotType.RESOURCE:
			GameData.current_resource_card = GameData.CardType.NONE
			texture.region = EMPTY_RESOURCE_REGION
		GameData.SlotType.UPGRADE:
			GameData.current_upgrade_card = GameData.CardType.NONE
			texture.region = EMPTY_UPGRADE_REGION
