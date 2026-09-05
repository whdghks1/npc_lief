## Basic player-facing HUD: stats, clock, daily objective, interact prompt,
## and a brief danger warning.
##
## Finds the player via the "player" group instead of a direct scene
## reference, so this scene and the player scene stay decoupled — either can
## be swapped without editing the other. Purely a display — all the rules
## live in the systems it listens to (TimeSystem, Health, Hunger, Wallet,
## PlayerJob via ObjectiveTracker, WorldEvents for danger).
class_name HUD
extends CanvasLayer

## How close a danger_created event needs to be to the player to warrant a
## warning — "enough feedback to understand danger is nearby" without
## turning into a minimap-style radar (docs/ROADMAP.md Phase 7).
const DANGER_WARNING_RADIUS := 40.0
const DANGER_WARNING_DURATION := 4.0

@onready var _stats_label: Label = %StatsLabel
@onready var _time_label: Label = %TimeLabel
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _interact_prompt: Label = %InteractPrompt
@onready var _danger_label: Label = %DangerLabel

var _health_current := 0.0
var _health_max := 0.0
var _hunger_current := 0.0
var _hunger_max := 0.0
var _money := 0.0
var _player: Node3D
var _danger_warning_remaining := 0.0


func _ready() -> void:
	_interact_prompt.visible = false
	_danger_label.visible = false
	_update_time_label()
	TimeSystem.minute_passed.connect(_on_minute_passed)
	TimeSystem.day_changed.connect(_on_day_changed)
	WorldEvents.danger_created.connect(_on_danger_created)

	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_warning("HUD: no node in group 'player' found to bind to.")
		return

	var health: Health = _player.get_node("Health")
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)

	var hunger: Hunger = _player.get_node("Hunger")
	hunger.hunger_changed.connect(_on_hunger_changed)
	_on_hunger_changed(hunger.current_hunger, hunger.max_hunger)

	var wallet: Wallet = _player.get_node("Wallet")
	wallet.money_changed.connect(_on_money_changed)
	_on_money_changed(wallet.money)

	var interactor: Interactor = _player.get_node("Interactor")
	interactor.target_changed.connect(_on_target_changed)

	var objective: ObjectiveTracker = _player.get_node("ObjectiveTracker")
	objective.objective_changed.connect(_on_objective_changed)
	_on_objective_changed(objective.current_text)


func _process(delta: float) -> void:
	if _danger_warning_remaining <= 0.0:
		return
	_danger_warning_remaining -= delta
	if _danger_warning_remaining <= 0.0:
		_danger_label.visible = false


func _on_health_changed(current: float, max_health: float) -> void:
	_health_current = current
	_health_max = max_health
	_refresh_stats()


func _on_hunger_changed(current: float, max_hunger: float) -> void:
	_hunger_current = current
	_hunger_max = max_hunger
	_refresh_stats()


func _on_money_changed(amount: float) -> void:
	_money = amount
	_refresh_stats()


func _refresh_stats() -> void:
	_stats_label.text = "HP: %d/%d\nHunger: %d/%d\n$%d" % [
		int(_health_current), int(_health_max),
		int(_hunger_current), int(_hunger_max),
		int(_money),
	]


func _on_minute_passed(_hour: int, _minute: int) -> void:
	_update_time_label()


func _on_day_changed(_day: int) -> void:
	_update_time_label()


func _update_time_label() -> void:
	_time_label.text = "%s\n%s" % [TimeSystem.get_day_label(), TimeSystem.get_time_string()]


func _on_objective_changed(text: String) -> void:
	_objective_label.text = text


func _on_target_changed(interactable: Interactable) -> void:
	_interact_prompt.visible = interactable != null
	if interactable != null:
		_interact_prompt.text = "[E] %s" % interactable.prompt


func _on_danger_created(position: Vector3, _radius: float) -> void:
	if _player == null or _player.global_position.distance_to(position) > DANGER_WARNING_RADIUS:
		return
	_danger_label.visible = true
	_danger_warning_remaining = DANGER_WARNING_DURATION
