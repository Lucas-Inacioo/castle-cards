extends Node

signal castle_health_changed(current: int, max_value: int)
signal available_units_changed(units: int)

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

@export var max_castle_health: int:
	get:
		return _max_castle_health
	set(value):
		_max_castle_health = max(1, value)

		if _current_castle_health > _max_castle_health:
			_current_castle_health = _max_castle_health

		castle_health_changed.emit(_current_castle_health, _max_castle_health)

@export var current_castle_health: int:
	get:
		return _current_castle_health
	set(value):
		var clamped := clampi(value, 0, _max_castle_health)
		if _current_castle_health == clamped:
			return

		_current_castle_health = clamped
		castle_health_changed.emit(_current_castle_health, _max_castle_health)

@export var available_units: int:
	get:
		return _available_units
	set(value):
		var clamped = max(0, value)
		if _available_units == clamped:
			return

		_available_units = clamped
		available_units_changed.emit(_available_units)

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

var planned_defense_base_ids: Array[int] = []
var planned_attack_base_ids: Array[int] = []

var _max_castle_health: int = 15
var _current_castle_health: int = 15
var _available_units: int = 1