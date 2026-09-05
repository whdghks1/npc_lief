## Basic player-facing HUD: health readout + contextual interact prompt.
##
## Finds the player via the "player" group instead of a direct scene
## reference, so this scene and the player scene stay decoupled — either can
## be swapped without editing the other.
class_name HUD
extends CanvasLayer

@onready var _health_label: Label = %HealthLabel
@onready var _interact_prompt: Label = %InteractPrompt


func _ready() -> void:
	_interact_prompt.visible = false
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("HUD: no node in group 'player' found to bind to.")
		return
	var health: Health = player.get_node("Health")
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)

	var interactor: Interactor = player.get_node("Interactor")
	interactor.target_changed.connect(_on_target_changed)


func _on_health_changed(current: float, max_health: float) -> void:
	_health_label.text = "HP: %d / %d" % [int(current), int(max_health)]


func _on_target_changed(interactable: Interactable) -> void:
	_interact_prompt.visible = interactable != null
	if interactable != null:
		_interact_prompt.text = "[E] %s" % interactable.prompt
