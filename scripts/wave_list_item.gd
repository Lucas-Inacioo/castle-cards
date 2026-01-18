extends Button

var wave

@export var wave_ui: Control
@export var enemies_label: Label

func bind_to_wave(new_wave) -> void:
  wave = new_wave

  _refresh()

  wave.enemy_count_changed.connect(_on_enemy_count_changed)
  wave.cleared.connect(_on_wave_cleared)

func _refresh() -> void:
  wave_ui.setup(wave.rounds_until_castle, wave.wave_defense_value, wave.wave_attack_value)
  enemies_label.text = str(wave.enemies.size())

func _on_enemy_count_changed(new_count: int) -> void:
  enemies_label.text = str(new_count)

func _on_wave_cleared() -> void:
  queue_free()
