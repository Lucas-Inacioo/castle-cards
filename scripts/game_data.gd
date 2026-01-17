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

var current_resource_card: GameData.CardType = GameData.CardType.NONE
var current_upgrade_card: GameData.CardType = GameData.CardType.NONE