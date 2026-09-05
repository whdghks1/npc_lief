## A simple purchasable food item placed in the world (e.g. outside the
## convenience store). Config is inline export vars rather than a Resource —
## revisit if food variety grows beyond a couple of items (Phase 3 only
## calls for one or two). CityBuilder places these; this component only
## knows how to sell itself to whoever interacts.
extends StaticBody3D

@export var food_name: String = "Snack"
@export var cost: float = 3.0
@export var hunger_restore: float = 15.0

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)


func _on_interacted(by: Node) -> void:
	var wallet: Wallet = by.get_node_or_null("Wallet")
	var hunger: Hunger = by.get_node_or_null("Hunger")
	if wallet == null or hunger == null:
		return
	if not wallet.spend(cost):
		print("Not enough money to buy ", food_name)
		return
	hunger.restore(hunger_restore)
	print("Bought and ate %s (+%.0f hunger, -$%.0f)" % [food_name, hunger_restore, cost])
