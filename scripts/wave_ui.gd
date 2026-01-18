extends Control

#region Children Nodes
@export var rounds_indicator: TextureRect
@export var defense_indicator: TextureRect
@export var attack_indicator: TextureRect
#endregion

func setup(rounds_until_castle: int, defense_value: int, attack_value: int) -> void:
  rounds_indicator.setup(rounds_until_castle)
  defense_indicator.setup(defense_value)
  attack_indicator.setup(attack_value)
