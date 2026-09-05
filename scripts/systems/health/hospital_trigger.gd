## Marks a physics body as a place the player can get treated. CityBuilder
## attaches this to the Hospital building (plus a child Interactable).
##
## Prototype rule for insufficient funds (docs/ROADMAP.md Phase 7 asks for
## one to be chosen and documented): the hospital treats you anyway. Being
## broke AND dying is future-phase material — for this prototype, healthcare
## is never a reason a recoverable player stays dying.
extends StaticBody3D

const TREATMENT_COST := 15.0

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)


func _on_interacted(by: Node) -> void:
	var health: Health = by.get_node_or_null("Health")
	if health == null or health.current_health >= health.max_health:
		print("Nothing to treat — already at full health.")
		return

	var wallet: Wallet = by.get_node_or_null("Wallet")
	if wallet != null and wallet.spend(TREATMENT_COST):
		print("Treated at the hospital. -$%d" % int(TREATMENT_COST))
	else:
		print("Treated at the hospital (couldn't afford it — treated anyway).")

	health.heal(health.max_health)
