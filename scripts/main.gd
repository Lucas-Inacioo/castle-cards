extends Node2D

#region Children Nodes
@export var card_container: HBoxContainer
@export var resource_slot: TextureRect
@export var slots_container: HBoxContainer
@export var world_tile_controller: Node2D
@export var enemies_controller: Node2D
@export var waves_controller: Node2D
@export var current_waves_list: VBoxContainer
#endregion

func _ready() -> void:
	get_window().content_scale_factor = 0.1

	resource_slot.defense_card_dropped.connect(open_defense_ui)
	#resource_slot.attack_card_dropped.connect(open_attack_ui)

	world_tile_controller.building_created.connect(enemies_controller.building_created)
	world_tile_controller.building_created.connect(waves_controller.building_created)

	waves_controller.wave_created.connect(enemies_controller.wave_created)

	waves_controller.wave_created.connect(current_waves_list.wave_created)

func _end_day_button_pressed() -> void:
	GameData.current_day += 1

	_check_cards_upgrade()
	_set_cards_for_new_day()
	waves_controller.check_waves()

	card_container.start_new_day()
	slots_container.start_new_day()

func _check_cards_upgrade() -> void:
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
	var current_updating_card = GameData.current_upgrade_card
	var current_resource_card = GameData.current_resource_card

	GameData.cards_status[current_updating_card].is_upgrading = true
	GameData.cards_status[current_updating_card].rounds_until_upgrade_complete = 2

	match current_resource_card:
		GameData.CardType.HEALTH:
			# Heal castle
			var current_health_level = GameData.cards_status[GameData.CardType.HEALTH].upgrade_level
			GameData.current_castle_health = max(
				GameData.current_castle_health + 5 * (1 + current_health_level),
				GameData.max_castle_health,
			)
		GameData.CardType.PEOPLE:
			# Spawn a new unit near the castle
			GameData.number_of_people_units += 1

func open_defense_ui() -> void:
	waves_controller.defend_waves()
