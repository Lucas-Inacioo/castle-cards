extends Control

@export var back_scene: String = "res://scenes/menu.tscn"
@export var volume_slider: HSlider
@export var volume_value_label: Label
@export var back_button: Button

func _ready() -> void:
	# Load current value into UI
	volume_slider.value = SettingsSingleton.master_volume_linear
	_update_volume_label(SettingsSingleton.master_volume_linear)

	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)


func _on_volume_changed(value: float) -> void:
	SettingsSingleton.set_master_volume_linear(value)
	_update_volume_label(value)


func _update_volume_label(value: float) -> void:
	var percent := int(round(value * 100.0))
	volume_value_label.text = "%d%%" % percent


func _on_back_pressed() -> void:
	if back_scene != "":
		get_tree().change_scene_to_file(back_scene)
	else:
		# If you're using this as an overlay, you can just hide it:
		queue_free()
