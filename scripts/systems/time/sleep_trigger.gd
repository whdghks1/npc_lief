## Marks a physics body as a place the player can sleep. CityBuilder attaches
## this to the Home building (plus a child Interactable). Ends the current
## day: restores hunger and advances the clock to the next morning.
extends StaticBody3D

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)


func _on_interacted(by: Node) -> void:
	TimeSystem.advance_to_next_day()
	var hunger: Hunger = by.get_node_or_null("Hunger")
	if hunger != null:
		hunger.restore_full()
	print("Slept. %s %s" % [TimeSystem.get_day_label(), TimeSystem.get_time_string()])
