extends Node

enum CardType {
	NONE,
	ATTACK,
	DEFENSE,
	HEALTH,
	PEOPLE
}

enum SlotType {
	RESOURCE,
	UPGRADE,
}

enum BuildingType {
	PLAYER_CASTLE,
	ENEMY_BASE_VARIANT_1,
	ENEMY_BASE_VARIANT_2,
}

var card_data = {
	CardType.ATTACK: {
		"name": "Attack",
		"description": "Increases your new unit's attack power.",
		"texture_path": "res://assets/cards/attack_card.png",
	},
	CardType.DEFENSE: {
		"name": "Defense",
		"description": "Enhances your new unit's defenses.",
		"texture_path": "res://assets/cards/defense_card.png",
	},
	CardType.HEALTH: {
		"name": "Health",
		"description": "Boosts your castle's health.",
		"texture_path": "res://assets/cards/health_card.png",
	},
	CardType.PEOPLE: {
		"name": "People",
		"description": "Creates a new unit with current defense and attack.",
		"texture_path": "res://assets/cards/people_card.png",
	},
}

var cards_status = {
	CardType.ATTACK: {
		upgrade_level = 0,
		is_upgrading = false,
		rounds_until_upgrade_complete = 0,
	},
	CardType.DEFENSE: {
		upgrade_level = 0,
		is_upgrading = false,
		rounds_until_upgrade_complete = 0,
	},
	CardType.HEALTH: {
		upgrade_level = 0,
		is_upgrading = false,
		rounds_until_upgrade_complete = 0,
	},
	CardType.PEOPLE: {
		upgrade_level = 0,
		is_upgrading = false,
		rounds_until_upgrade_complete = 0,
	},
}

var building_data = {
	BuildingType.PLAYER_CASTLE: {
		"max_health": 100,
		"enemy_type": null,
		"scene": "res://scenes/player_castle.tscn",
	},
	BuildingType.ENEMY_BASE_VARIANT_1: {
		"max_health": 50,
		"enemy_type": "res://scenes/enemy_orc.tscn",
		"scene": "res://scenes/enemy_1.tscn",
		"waves_apart_spawn": 1,
	},
	BuildingType.ENEMY_BASE_VARIANT_2: {
		"max_health": 75,
		"enemy_type": "res://scenes/enemy_skeleton.tscn",
		"scene": "res://scenes/enemy_2.tscn",
		"waves_apart_spawn": 6,
	},
}

var current_resource_card: GameData.CardType = GameData.CardType.NONE
var current_upgrade_card: GameData.CardType = GameData.CardType.NONE
var current_day: int = 1