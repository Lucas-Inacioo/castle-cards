extends Node2D

func ally_created() -> void:
  var current_attack_level = GameData.cards_status[GameData.CardType.ATTACK].upgrade_level
  var current_defense_level = GameData.cards_status[GameData.CardType.DEFENSE].upgrade_level

  var ally_scene = load("res://scenes/castle_people.tscn")

  var ally = ally_scene.instantiate()
  ally.setup(current_attack_level, current_defense_level)
  add_child(ally)