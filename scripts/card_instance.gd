extends TextureRect

@export var card_type: GameData.CardType

@onready var pendent_rounds_2_tex: TextureRect = $PendentRounds2
@onready var pendent_rounds_1_tex: TextureRect = $PendentRounds1

func _get_drag_data(_at_position: Vector2) -> Variant:
	var card_status = GameData.cards_status.get(card_type)
	var is_upgrading = card_status.get("is_upgrading")

	# Prevent dragging if the card is upgrading
	if is_upgrading:
		return

	var drag_preview = TextureRect.new()
	drag_preview.texture = texture
	drag_preview.size = Vector2(46, 68)

	# Create Control to center the preview
	var control_node = Control.new()
	control_node.add_child(drag_preview)
	drag_preview.position = -drag_preview.size / 2

	set_drag_preview(control_node)

	var return_data = {
		"card_type": card_type,
		"texture": texture,
	}

	return return_data

func update_card_display() -> void:
	var card_status = GameData.cards_status.get(card_type)
	var upgrade_level = card_status.get("upgrade_level")

	# Update cards texture region based on upgrade level
	const ATLAS_CELL_WIDTH = 25
	texture.region.position = Vector2(
		ATLAS_CELL_WIDTH * upgrade_level + 1,
		texture.region.position.y,
	)

	# Update pendent rounds display
	if card_status.is_upgrading:
		var rounds_left = card_status.rounds_until_upgrade_complete
		pendent_rounds_2_tex.visible = rounds_left >= 2
		pendent_rounds_1_tex.visible = rounds_left >= 1
	else:
		pendent_rounds_2_tex.visible = false
		pendent_rounds_1_tex.visible = false
