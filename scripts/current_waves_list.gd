extends VBoxContainer

signal wave_selected(wave)

var wave_rows_by_id: Dictionary = {}

func wave_spawned(wave) -> void:
  var row_scene = load("res://scenes/wave_list_item.tscn")
  var row = row_scene.instantiate()

  row.bind_to_wave(wave)
  row.pressed.connect(func(): wave_selected.emit(wave))

  add_child(row)
  wave_rows_by_id[wave.get_instance_id()] = row

  # Extra safety: if wave gets freed some other way
  wave.cleared.connect(func():
    wave_rows_by_id.erase(wave.get_instance_id())
  )
