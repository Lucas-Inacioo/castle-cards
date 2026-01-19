extends Node

signal castle_health_changed(current: int, max_value: int)
signal available_units_changed(units: int)

signal base_health_changed(base_id: int, current: int, max_value: int)
signal base_destroyed(base_id: int)

enum UnitType {
  SOLDIER,
  ORC,
  ORC2,
  SKELETON,
  SKELETON2,
  ATTACK_PLACEHOLDER,
  VAMPIRE,
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

const DEFAULT_MAX_CASTLE_HEALTH := 15
const DEFAULT_CURRENT_CASTLE_HEALTH := 15
const DEFAULT_AVAILABLE_UNITS := 1

const DEFAULT_CARDS_STATUS := {
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

const DEFAULT_BASES_DATA := {
	0: {
		"base_attack": 1,
		"base_shield": 1,
		"maximum_health": DEFAULT_MAX_CASTLE_HEALTH,
		"current_health": DEFAULT_CURRENT_CASTLE_HEALTH,
		"destroyed": false,
	},
	1: {
		"rounds_between_attacks": 4,
		"base_attack": 2,
		"base_shield": 1,
		"maximum_health": 8,
		"current_health": 8,
		"destroyed": false,
	},
	2: {
		"rounds_between_attacks": 2,
		"base_attack": 1,
		"base_shield": 1,
		"maximum_health": 15,
		"current_health": 15,
		"destroyed": false,
	},
	3: {
		"rounds_between_attacks": 7,
		"base_attack": 3,
		"base_shield": 7,
		"maximum_health": 20,
		"current_health": 20,
		"destroyed": false,
	},
	4: {
		"rounds_between_attacks": 10,
		"base_attack": 10,
		"base_shield": 1,
		"maximum_health": 50,
		"current_health": 50,
		"destroyed": false,
	},
  5: {
    "rounds_between_attacks": 5,
    "base_attack": 2,
    "base_shield": 12,
    "maximum_health": 35,
    "current_health": 35,
  },
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
		var clamped = clampi(value, 0, _max_castle_health)
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

var cards_status = DEFAULT_CARDS_STATUS.duplicate(true)

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
  GameData.UnitType.ORC2: {
    "hp": 1,
    "damage": 10,
    "scene": load("res://scenes/units/orc.tscn"),
  },
  GameData.UnitType.SKELETON: {
    "hp": 1,
    "damage": 1,
    "scene": load("res://scenes/units/skeleton.tscn"),
  },
  GameData.UnitType.SKELETON2: {
    "hp": 12,
    "damage": 2,
    "scene": load("res://scenes/units/skeleton.tscn"),
  },
  GameData.UnitType.VAMPIRE: {
    "hp": 3,
    "damage": 7,
    "scene": load("res://scenes/units/vampire.tscn"),
  },
  GameData.UnitType.ATTACK_PLACEHOLDER: {
    "hp": 1,
    "damage": 1000,
  },
}

var bases_data = DEFAULT_BASES_DATA.duplicate(true)

var current_resource_card: GameData.CardType = GameData.CardType.NONE
var current_upgrade_card: GameData.CardType = GameData.CardType.NONE

var planned_defense_base_ids: Array[int] = []
var planned_attack_base_ids: Array[int] = []

var _max_castle_health: int = DEFAULT_MAX_CASTLE_HEALTH
var _current_castle_health: int = DEFAULT_CURRENT_CASTLE_HEALTH
var _available_units: int = DEFAULT_AVAILABLE_UNITS

func reset_game() -> void:
	# Reset global run state so "Play Again" (or starting a new game) is deterministic.
	cards_status = DEFAULT_CARDS_STATUS.duplicate(true)
	bases_data = DEFAULT_BASES_DATA.duplicate(true)

	planned_defense_base_ids.clear()
	planned_attack_base_ids.clear()
	current_resource_card = CardType.NONE
	current_upgrade_card = CardType.NONE

	max_castle_health = DEFAULT_MAX_CASTLE_HEALTH
	current_castle_health = DEFAULT_CURRENT_CASTLE_HEALTH
	available_units = DEFAULT_AVAILABLE_UNITS

	ensure_base_health_initialized()

	# Push a refresh for any live UI elements that are already listening.
	for base_id in bases_data.keys():
		base_health_changed.emit(base_id, get_base_current_health(base_id), get_base_max_health(base_id))

func _ready() -> void:
	ensure_base_health_initialized()

func ensure_base_health_initialized() -> void:
	for base_id in bases_data.keys():
		var base_info: Dictionary = bases_data[base_id]
		if !base_info.has("maximum_health"):
			base_info["maximum_health"] = 1
		if !base_info.has("current_health"):
			base_info["current_health"] = int(base_info["maximum_health"])
		if !base_info.has("destroyed"):
			base_info["destroyed"] = false
		bases_data[base_id] = base_info

func is_base_destroyed(base_id: int) -> bool:
	var base_info: Dictionary = bases_data.get(base_id, {})
	return bool(base_info.get("destroyed", false))

func get_base_max_health(base_id: int) -> int:
	var base_info: Dictionary = bases_data.get(base_id, {})
	return max(1, int(base_info.get("maximum_health", 1)))

func get_base_current_health(base_id: int) -> int:
	var base_info: Dictionary = bases_data.get(base_id, {})
	if base_info.is_empty():
		return 0
	if base_info.has("current_health"):
		return int(base_info["current_health"])
	return int(base_info.get("maximum_health", 0))

func set_base_current_health(base_id: int, new_value: int) -> void:
	var base_info: Dictionary = bases_data.get(base_id, {})
	if base_info.is_empty():
		return
	var max_health = get_base_max_health(base_id)
	var clamped = clampi(new_value, 0, max_health)

	base_info["current_health"] = clamped
	bases_data[base_id] = base_info
	base_health_changed.emit(base_id, clamped, max_health)

	if clamped <= 0 and !is_base_destroyed(base_id):
		destroy_base(base_id)

func apply_damage_to_base(base_id: int, raw_damage: int) -> void:
	if raw_damage <= 0:
		return
	if is_base_destroyed(base_id):
		return
	var current_health = get_base_current_health(base_id)
	set_base_current_health(base_id, current_health - raw_damage)

func destroy_base(base_id: int) -> void:
	var base_info: Dictionary = bases_data.get(base_id, {})
	if base_info.is_empty():
		return
	if bool(base_info.get("destroyed", false)):
		return

	base_info["destroyed"] = true
	base_info["current_health"] = 0
	bases_data[base_id] = base_info
	base_destroyed.emit(base_id)

func all_bases_destroyed() -> bool:
	# Works if you store "destroyed" and/or current_health.
	for base_id in bases_data.keys():
		var info: Dictionary = bases_data[base_id]

		var destroyed := bool(info.get("destroyed", false))
		var current_hp := int(info.get("current_health", int(info.get("maximum_health", 1))))

		if !destroyed and current_hp > 0:
			return false

	return true