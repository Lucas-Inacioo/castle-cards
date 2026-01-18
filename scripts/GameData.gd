extends Node

enum UnitType {
  SOLDIER,
  ORC,
  SKELETON,
  ATTACK_PLACEHOLDER
}

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

var units_data = {
  GameData.UnitType.SOLDIER: {
    "hp": 3,
    "damage": 1,
  },
  GameData.UnitType.ORC: {
    "hp": 2,
    "damage": 1,
    "scene": load("res://scenes/units/orc.tscn"),
  },
  GameData.UnitType.SKELETON: {
    "hp": 1,
    "damage": 1,
    "scene": load("res://scenes/units/skeleton.tscn"),
  },
  GameData.UnitType.ATTACK_PLACEHOLDER: {
    "hp": 1,
    "damage": 1000,
  },
}

var bases_data = {
  0: {
    "base_attack": 1,
    "base_shield": 50,
  },
  1: {
    "rounds_between_attacks": 4,
    "base_attack": 2,
    "base_shield": 4,
  },
  2: {
    "rounds_between_attacks": 2,
    "base_attack": 5,
    "base_shield": 3,
  },
}

var current_resource_card: GameData.CardType = GameData.CardType.NONE
var current_upgrade_card: GameData.CardType = GameData.CardType.NONE

var current_castle_health: int = 100
var max_castle_health: int = 100

var available_units: int = 1 
var planned_defense_base_ids: Array[int] = []