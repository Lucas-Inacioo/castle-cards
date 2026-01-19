class_name Settings

extends Node

const SAVE_PATH := "user://settings.cfg"
const SECTION := "audio"
const KEY_MASTER := "master_volume_linear"

# 0.0 .. 1.0
var master_volume_linear: float = 1.0


func _ready() -> void:
	load_settings()
	apply_audio()


func set_master_volume_linear(value: float) -> void:
	master_volume_linear = clampf(value, 0.0, 1.0)
	apply_audio()
	save_settings()


func apply_audio() -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx < 0:
		push_warning("Audio bus 'Master' not found.")
		return

	# Avoid -INF when volume is 0
	if master_volume_linear <= 0.0005:
		AudioServer.set_bus_mute(bus_idx, true)
		AudioServer.set_bus_volume_db(bus_idx, -80.0)
		return

	AudioServer.set_bus_mute(bus_idx, false)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume_linear))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_MASTER, master_volume_linear)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Failed to save settings: %s" % err)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		master_volume_linear = float(cfg.get_value(SECTION, KEY_MASTER, 1.0))
	else:
		master_volume_linear = 1.0
