extends TextureRect

@export var card_type: GameData.CardType

func _get_drag_data(_at_position: Vector2) -> Variant:
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
