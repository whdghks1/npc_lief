## Tracks the player's employment and runs a shift when told to.
##
## Deliberately has no idea *how* a shift gets triggered — a workplace
## (scripts/systems/jobs/workplace_trigger.gd) calls start_shift() when the
## player interacts with it. For the prototype, working advances simulation
## time directly rather than running a minigame (per the Phase 3 spec).
class_name PlayerJob
extends Node

enum ShiftState { NOT_WORKED_TODAY, ON_SHIFT, COMPLETED_TODAY }

signal shift_started
signal shift_completed(salary_paid: float, was_late: bool)

@export var job: JobDefinition

var shift_state: ShiftState = ShiftState.NOT_WORKED_TODAY


func _ready() -> void:
	TimeSystem.day_changed.connect(_on_day_changed)


func start_shift(wallet: Wallet) -> void:
	if job == null or shift_state == ShiftState.COMPLETED_TODAY:
		return

	shift_state = ShiftState.ON_SHIFT
	shift_started.emit()

	var current_total := TimeSystem.total_minutes()
	var late_minutes := maxi(current_total - job.start_total_minutes(), 0)
	var was_late := late_minutes > job.late_threshold_minutes

	var end_total := job.end_total_minutes()
	var minutes_to_advance := (end_total - current_total) if current_total < end_total else 30
	TimeSystem.advance_time(minutes_to_advance)

	var salary_paid: float = job.salary
	if was_late:
		salary_paid = maxf(salary_paid - job.late_penalty, 0.0)
	wallet.add_money(salary_paid)

	shift_state = ShiftState.COMPLETED_TODAY
	shift_completed.emit(salary_paid, was_late)


func _on_day_changed(_day: int) -> void:
	shift_state = ShiftState.NOT_WORKED_TODAY
