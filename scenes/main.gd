extends Node2D

@export var wave_manager: Node2D

func _ready() -> void:
  wave_manager.schedule_fight(1)
  wave_manager.schedule_fight(2)

  wave_manager.fight_waves()
