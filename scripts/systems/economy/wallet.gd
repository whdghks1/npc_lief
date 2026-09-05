## Player money. Deliberately not folded into PlayerController — anything
## that needs to pay or charge the player (Job, food, later rent/shops) talks
## to this component instead of touching player state directly.
class_name Wallet
extends Node

signal money_changed(amount: float)

@export var starting_money: float = 20.0

var money: float = 0.0


func _ready() -> void:
	money = starting_money
	money_changed.emit(money)


func add_money(amount: float) -> void:
	if amount <= 0.0:
		return
	money += amount
	money_changed.emit(money)


func can_afford(amount: float) -> bool:
	return amount <= money


## Returns false (and charges nothing) if the player can't afford it.
func spend(amount: float) -> bool:
	if amount <= 0.0 or not can_afford(amount):
		return false
	money -= amount
	money_changed.emit(money)
	return true
