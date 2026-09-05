## Lightweight "what should an ordinary citizen do right now" hint for the
## HUD. This is NOT a quest framework — just a small rule-based status line
## derived from time/job/hunger state, per docs/ROADMAP.md Phase 3 ("Daily
## Objective Feedback"). Sibling of Job/Hunger under the Player node.
class_name ObjectiveTracker
extends Node

signal objective_changed(text: String)

const HUNGRY_THRESHOLD := 50.0
const BEDTIME_HOUR := 22

@onready var _job: PlayerJob = $"../Job"
@onready var _hunger: Hunger = $"../Hunger"

var current_text: String = ""


func _ready() -> void:
	TimeSystem.minute_passed.connect(_on_minute_passed)
	_refresh()


func _on_minute_passed(_hour: int, _minute: int) -> void:
	_refresh()


func _refresh() -> void:
	var text := _compute_text()
	if text != current_text:
		current_text = text
		objective_changed.emit(current_text)


func _compute_text() -> String:
	if _job.shift_state == PlayerJob.ShiftState.NOT_WORKED_TODAY:
		if _job.job != null:
			return "Go to work — shift starts at %02d:%02d" % [
				_job.job.start_hour, _job.job.start_minute
			]
		return "Find somewhere to work."
	if _job.shift_state == PlayerJob.ShiftState.ON_SHIFT:
		return "Working..."
	if _hunger.current_hunger < HUNGRY_THRESHOLD:
		return "Buy something to eat."
	if TimeSystem.hour >= BEDTIME_HOUR or TimeSystem.hour < TimeSystem.WAKE_HOUR:
		return "Return home and sleep."
	return "Enjoy the rest of your day."
