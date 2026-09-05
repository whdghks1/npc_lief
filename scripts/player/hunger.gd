## Basic need: hunger drains over simulation time and is restored by eating.
## Mirrors scripts/player/health.gd's shape. No hazard reduces health from
## starving yet — that's out of scope until later chaos/survival phases.
class_name Hunger
extends Node

signal hunger_changed(current: float, max_hunger: float)

@export var max_hunger: float = 100.0
@export var decay_per_minute: float = 0.05

var current_hunger: float = max_hunger


func _ready() -> void:
	current_hunger = max_hunger
	hunger_changed.emit(current_hunger, max_hunger)
	TimeSystem.minute_passed.connect(_on_minute_passed)


func decrease(amount: float) -> void:
	if amount <= 0.0:
		return
	current_hunger = maxf(current_hunger - amount, 0.0)
	hunger_changed.emit(current_hunger, max_hunger)


func restore(amount: float) -> void:
	if amount <= 0.0:
		return
	current_hunger = minf(current_hunger + amount, max_hunger)
	hunger_changed.emit(current_hunger, max_hunger)


func restore_full() -> void:
	current_hunger = max_hunger
	hunger_changed.emit(current_hunger, max_hunger)


func _on_minute_passed(_hour: int, _minute: int) -> void:
	decrease(decay_per_minute)
