extends Node2D

@export var wave_manager: Node2D
@export var end_day_button: TextureButton
@export var card_container: Node
@export var resource_slots_container: TextureRect
@export var upgrade_slots_container: TextureRect

var defense_planning_active = false
var selected_defense_base_ids: Array[int] = []

var defense_overlay: PanelContainer
var defense_info_label: Label
var defense_confirm_button: Button
var defense_cancel_button: Button

func _ready() -> void:
	end_day_button.pressed.connect(_on_end_day_button_pressed)

	(resource_slots_container as TextureRect).defense_card_dropped.connect(_on_defense_card_dropped)
	(wave_manager as Node).base_clicked.connect(_on_wave_manager_base_clicked)

	_build_defense_overlay()

func _on_end_day_button_pressed() -> void:
	_upgrade_cards()
	_set_cards_for_new_day()

	_apply_planned_defense()

	wave_manager.check_waves()
	wave_manager.fight_waves()

	# Notify UI elements about new day
	card_container.start_new_day()
	resource_slots_container.clear_slot()
	upgrade_slots_container.clear_slot()

func _upgrade_cards() -> void:
	for card_type in GameData.CardType.values():
		if card_type == GameData.CardType.NONE:
			continue

		var card_status = GameData.cards_status[card_type]
		if card_status.is_upgrading:
			card_status.rounds_until_upgrade_complete -= 1
			if card_status.rounds_until_upgrade_complete <= 0:
				card_status.is_upgrading = false
				card_status.upgrade_level += 1
				GameData.cards_status[card_type] = card_status

func _set_cards_for_new_day() -> void:
	var current_upgrading_card = GameData.current_upgrade_card
	var current_resource_card = GameData.current_resource_card

	# Start upgrading the selected card
	GameData.cards_status[current_upgrading_card].is_upgrading = true
	GameData.cards_status[current_upgrading_card].rounds_until_upgrade_complete = 2

	# Apply the effects of the selected resource card
	match current_resource_card:
		GameData.CardType.HEALTH:
			# Heal castle
			var current_health_level = GameData.cards_status[GameData.CardType.HEALTH].upgrade_level
			GameData.current_castle_health = max(
				GameData.current_castle_health + 5 * (1 + current_health_level),
				GameData.max_castle_health,
			)
		GameData.CardType.PEOPLE:
			pass

func _build_defense_overlay() -> void:
	var ui_root: Control = $UI/Control

	defense_overlay = PanelContainer.new()
	defense_overlay.visible = false
	defense_overlay.anchor_left = 0.5
	defense_overlay.anchor_right = 0.5
	defense_overlay.anchor_top = 1.0
	defense_overlay.anchor_bottom = 1.0
	defense_overlay.offset_left = -160
	defense_overlay.offset_right = 160
	defense_overlay.offset_top = -120
	defense_overlay.offset_bottom = -20

	var vbox = VBoxContainer.new()
	defense_overlay.add_child(vbox)

	defense_info_label = Label.new()
	vbox.add_child(defense_info_label)

	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)

	defense_confirm_button = Button.new()
	defense_confirm_button.text = "Confirm"
	defense_confirm_button.disabled = true
	defense_confirm_button.pressed.connect(_on_defense_confirm_pressed)
	hbox.add_child(defense_confirm_button)

	defense_cancel_button = Button.new()
	defense_cancel_button.text = "Cancel"
	defense_cancel_button.pressed.connect(_on_defense_cancel_pressed)
	hbox.add_child(defense_cancel_button)

	ui_root.add_child(defense_overlay)

func _on_defense_card_dropped() -> void:
	# Only allow if you have units available
	if GameData.available_units <= 0:
		(resource_slots_container as TextureRect).clear_slot()
		return

	defense_planning_active = true
	selected_defense_base_ids.clear()

	end_day_button.disabled = true
	defense_overlay.visible = true

	_update_defense_overlay_text()

	wave_manager.enable_defense_selection(true)

func _on_wave_manager_base_clicked(base_id: int) -> void:
	if !defense_planning_active:
		return
	if base_id == 0:
		return

	if selected_defense_base_ids.has(base_id):
		selected_defense_base_ids.erase(base_id)
		wave_manager.set_base_selected(base_id, false)
	else:
		if selected_defense_base_ids.size() >= GameData.available_units:
			return
		selected_defense_base_ids.append(base_id)
		wave_manager.set_base_selected(base_id, true)

	defense_confirm_button.disabled = selected_defense_base_ids.is_empty()
	_update_defense_overlay_text()

func _update_defense_overlay_text() -> void:
	defense_info_label.text = "Select up to %d bases (%d selected)" % [
		GameData.available_units,
		selected_defense_base_ids.size()
	]

func _on_defense_confirm_pressed() -> void:
	if selected_defense_base_ids.is_empty():
		_on_defense_cancel_pressed()
		return

	GameData.planned_defense_base_ids = selected_defense_base_ids.duplicate()

	wave_manager.enable_defense_selection(false)  # <-- important

	defense_planning_active = false
	end_day_button.disabled = false
	defense_overlay.visible = false

func _on_defense_cancel_pressed() -> void:
	wave_manager.enable_defense_selection(false)  # <-- important

	# clear selection visuals
	for base_id in selected_defense_base_ids:
		wave_manager.set_base_selected(base_id, false)
	selected_defense_base_ids.clear()

	GameData.planned_defense_base_ids.clear()
	defense_planning_active = false

	(resource_slots_container as TextureRect).clear_slot()

	end_day_button.disabled = false
	defense_overlay.visible = false

func _apply_planned_defense() -> void:
	if GameData.planned_defense_base_ids.is_empty():
		return

	for base_id in GameData.planned_defense_base_ids:
		wave_manager.reset_base_timer(base_id)
		wave_manager.schedule_fight(base_id)

	GameData.planned_defense_base_ids.clear()

	# Optional: clear highlights now that it’s committed
	wave_manager.clear_all_base_selections()