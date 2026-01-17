extends TextureButton

func _physics_process(_delta: float) -> void:
	if (GameData.current_resource_card == GameData.CardType.NONE or
		GameData.current_upgrade_card == GameData.CardType.NONE):
		disabled = true
	else:
		disabled = false
