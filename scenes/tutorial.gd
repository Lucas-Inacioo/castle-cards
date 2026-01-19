extends Control

@export var previous_button: Button
@export var next_button: Button
@export var start_game_button: Button

@export var tutorial_1: TextureRect
@export var tutorial_2: TextureRect
@export var tutorial_3: TextureRect
@export var tutorial_4: TextureRect
@export var tutorial_5: TextureRect
@export var tutorial_6: TextureRect
@export var tutorial_7: TextureRect
@export var tutorial_8: TextureRect

var current_step: int = 1

func _ready() -> void:
  previous_button.pressed.connect(_on_previous_button_pressed)
  next_button.pressed.connect(_on_next_button_pressed)
  start_game_button.pressed.connect(_on_start_game_button_pressed)

func _on_previous_button_pressed() -> void:
  if current_step > 1:
    current_step -= 1
    _update_tutorial_step()

func _on_next_button_pressed() -> void:
  current_step += 1
  _update_tutorial_step()

func _update_tutorial_step() -> void:
  tutorial_1.visible = current_step == 1
  tutorial_2.visible = current_step == 2
  tutorial_3.visible = current_step == 3
  tutorial_4.visible = current_step == 4
  tutorial_5.visible = current_step == 5
  tutorial_6.visible = current_step == 6
  tutorial_7.visible = current_step == 7
  tutorial_8.visible = current_step == 8

  previous_button.visible = current_step != 1
  next_button.visible = current_step != 8
  start_game_button.visible = current_step == 8

func _on_start_game_button_pressed() -> void:
  get_tree().change_scene_to_file("res://scenes/main.tscn")