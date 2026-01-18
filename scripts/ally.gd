extends AnimatedSprite2D

var attack_power: int = 1
var defense_power: int = 1

func setup(attack_level: int, defense_level: int) -> void:
  attack_power = 1 + attack_level
  defense_power = 1 + defense_level