extends Node2D

@export var wave_manager: Node2D
@export var end_day_button: TextureButton
@export var card_container: Node
@export var resource_slots_container: TextureRect
@export var upgrade_slots_container: TextureRect
@export var win_label: Label

var defense_planning_active = false
var selected_defense_base_ids: Array[int] = []

var defense_overlay: PanelContainer
var defense_info_label: Label
var defense_confirm_button: Button
var defense_cancel_button: Button

var attack_planning_active = false
var selected_attack_base_ids: Array[int] = []

var attack_overlay: PanelContainer
var attack_info_label: Label
var attack_confirm_button: Button
var attack_cancel_button: Button

@onready var new_day_audio: AudioStreamPlayer2D = $NewDayAudio
@onready var confirm_audio: AudioStreamPlayer2D = $ConfirmAudio
@onready var cancel_audio: AudioStreamPlayer2D = $CancelAudio
@onready var select_base_audio: AudioStreamPlayer2D = $SelectBaseAudio

func _ready() -> void:
	end_day_button.pressed.connect(_on_end_day_button_pressed)

	(resource_slots_container as TextureRect).defense_card_dropped.connect(_on_defense_card_dropped)
	(wave_manager as Node).base_clicked.connect(_on_wave_manager_base_clicked)
	(resource_slots_container as TextureRect).attack_card_dropped.connect(_on_attack_card_dropped)

	_build_attack_overlay()
	_build_defense_overlay()

	GameData.base_destroyed.connect(_on_base_destroyed)
	_update_victory_ui()

func _on_end_day_button_pressed() -> void:
	if GameData.current_resource_card == GameData.CardType.NONE:
		return  # cannot end day without selecting cards
	if GameData.current_upgrade_card == GameData.CardType.NONE:
		return  # cannot end day without selecting cards
	new_day_audio.play()

	_upgrade_cards()
	_set_cards_for_new_day()

	_apply_planned_defense()
	_apply_planned_attack()

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
				if card_type == GameData.CardType.DEFENSE:
					GameData.bases_data[0]["base_shield"] += 1  # Increase shield on upgrade
				elif card_type == GameData.CardType.ATTACK:
					GameData.bases_data[0]["base_attack"] += 1  # Increase attack
				wave_manager.update_display_castle()

func _set_cards_for_new_day() -> void:
	var current_upgrading_card = GameData.current_upgrade_card
	var current_resource_card = GameData.current_resource_card

	# Start upgrading the selected card
	GameData.cards_status[current_upgrading_card].is_upgrading = true
	GameData.cards_status[current_upgrading_card].rounds_until_upgrade_complete = 2

	# Apply the effects of the selected resource card
	match current_resource_card:
		GameData.CardType.HEALTH:
			var current_health_level = GameData.cards_status[GameData.CardType.HEALTH].upgrade_level
			GameData.current_castle_health = min(
				GameData.current_castle_health + 1 * (1 + current_health_level),
				GameData.max_castle_health,
			)

		GameData.CardType.PEOPLE:
			var people_level = int(GameData.cards_status[GameData.CardType.PEOPLE].upgrade_level)
			var units_gained = 1 + people_level
			GameData.available_units += units_gained

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

	wave_manager.enable_base_selection(true)

func _update_defense_overlay_text() -> void:
	defense_info_label.text = "Select up to %d bases to delay attacks (%d selected)" % [
		GameData.available_units,
		selected_defense_base_ids.size()
	]

func _on_defense_confirm_pressed() -> void:
	if selected_defense_base_ids.is_empty():
		_on_defense_cancel_pressed()
		return

	GameData.planned_defense_base_ids = selected_defense_base_ids.duplicate()

	wave_manager.enable_base_selection(false)

	# clear selection visuals (but keep the plan in GameData)
	for base_id in selected_defense_base_ids:
		wave_manager.set_base_selected(base_id, false)
	selected_defense_base_ids.clear()

	defense_planning_active = false
	end_day_button.disabled = false
	defense_overlay.visible = false

	confirm_audio.play()

func _on_defense_cancel_pressed() -> void:
	wave_manager.enable_base_selection(false)  # <-- important

	# clear selection visuals
	for base_id in selected_defense_base_ids:
		wave_manager.set_base_selected(base_id, false)
	selected_defense_base_ids.clear()

	GameData.planned_defense_base_ids.clear()
	defense_planning_active = false

	(resource_slots_container as TextureRect).clear_slot()

	end_day_button.disabled = false
	defense_overlay.visible = false

	cancel_audio.play()

func _apply_planned_defense() -> void:
	if GameData.planned_defense_base_ids.is_empty():
		return

	var units_spent = GameData.planned_defense_base_ids.size()
	GameData.available_units = max(1, GameData.available_units - units_spent)

	for base_id in GameData.planned_defense_base_ids:
		# Only delay if the player wins the defense battle:
		wave_manager.start_defense_for_base(base_id)

	GameData.planned_defense_base_ids.clear()
	wave_manager.clear_all_base_selections()

func _build_attack_overlay() -> void:
	var ui_root: Control = $UI/Control

	attack_overlay = PanelContainer.new()
	attack_overlay.visible = false
	attack_overlay.anchor_left = 0.5
	attack_overlay.anchor_right = 0.5
	attack_overlay.anchor_top = 1.0
	attack_overlay.anchor_bottom = 1.0
	attack_overlay.offset_left = -160
	attack_overlay.offset_right = 160
	attack_overlay.offset_top = -120
	attack_overlay.offset_bottom = -20

	var vbox = VBoxContainer.new()
	attack_overlay.add_child(vbox)

	attack_info_label = Label.new()
	vbox.add_child(attack_info_label)

	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)

	attack_confirm_button = Button.new()
	attack_confirm_button.text = "Confirm"
	attack_confirm_button.disabled = true
	attack_confirm_button.pressed.connect(_on_attack_confirm_pressed)
	hbox.add_child(attack_confirm_button)

	attack_cancel_button = Button.new()
	attack_cancel_button.text = "Cancel"
	attack_cancel_button.pressed.connect(_on_attack_cancel_pressed)
	hbox.add_child(attack_cancel_button)

	ui_root.add_child(attack_overlay)

func _on_attack_card_dropped() -> void:
	if GameData.available_units <= 0:
		(resource_slots_container as TextureRect).clear_slot()
		return

	# Cancel any active defense planning (without clearing the just-dropped card)
	if defense_planning_active:
		for base_id in selected_defense_base_ids:
			wave_manager.set_base_selected(base_id, false)
		selected_defense_base_ids.clear()
		GameData.planned_defense_base_ids.clear()
		defense_planning_active = false
		defense_confirm_button.disabled = true
		defense_overlay.visible = false

	attack_planning_active = true
	selected_attack_base_ids.clear()

	end_day_button.disabled = true
	attack_overlay.visible = true

	_update_attack_overlay_text()
	wave_manager.enable_base_selection(true)

func _update_attack_overlay_text() -> void:
	attack_info_label.text = "Select up to %d bases to attack (%d selected)" % [
		GameData.available_units,
		selected_attack_base_ids.size()
	]

func _on_attack_confirm_pressed() -> void:
	if selected_attack_base_ids.is_empty():
		_on_attack_cancel_pressed()
		return

	GameData.planned_attack_base_ids = selected_attack_base_ids.duplicate()

	wave_manager.enable_base_selection(false)
	for base_id in selected_attack_base_ids:
		wave_manager.set_base_selected(base_id, false)
	selected_attack_base_ids.clear()

	attack_planning_active = false
	end_day_button.disabled = false
	attack_overlay.visible = false

	confirm_audio.play()

func _on_attack_cancel_pressed() -> void:
	wave_manager.enable_base_selection(false)

	for base_id in selected_attack_base_ids:
		wave_manager.set_base_selected(base_id, false)
	selected_attack_base_ids.clear()

	GameData.planned_attack_base_ids.clear()
	attack_planning_active = false

	(resource_slots_container as TextureRect).clear_slot()

	end_day_button.disabled = false
	attack_overlay.visible = false

	cancel_audio.play()

func _apply_planned_attack() -> void:
	if GameData.planned_attack_base_ids.is_empty():
		return

	var units_spent = GameData.planned_attack_base_ids.size()
	GameData.available_units = max(1, GameData.available_units - units_spent)

	for base_id in GameData.planned_attack_base_ids:
		wave_manager.schedule_attack(base_id)

	GameData.planned_attack_base_ids.clear()
	wave_manager.clear_all_base_selections()

func _on_wave_manager_base_clicked(base_id: int) -> void:
	if base_id == 0:
		return

	if defense_planning_active:
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

	if attack_planning_active:
		if selected_attack_base_ids.has(base_id):
			selected_attack_base_ids.erase(base_id)
			wave_manager.set_base_selected(base_id, false)
		else:
			if selected_attack_base_ids.size() >= GameData.available_units:
				return
			selected_attack_base_ids.append(base_id)
			wave_manager.set_base_selected(base_id, true)

		attack_confirm_button.disabled = selected_attack_base_ids.is_empty()
		_update_attack_overlay_text()
		return
	
	select_base_audio.play()

func _on_base_destroyed(_base_id: int) -> void:
	_update_victory_ui()

func _update_victory_ui() -> void:
	var won := GameData.all_bases_destroyed()
	win_label.visible = won

	if won:
		# Stop the game flow
		end_day_button.disabled = true
