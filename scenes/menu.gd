extends Control

const TUTORIAL_SCENE_PATH = "res://scenes/tutorial.tscn"
const SETTINGS_SCENE_PATH = "res://scenes/settings.tscn"

@export var start_game_button: Button
@export var settings_button: Button

func _ready() -> void:
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)

func _on_start_game_button_pressed() -> void:
	GameData.reset_game()
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)
