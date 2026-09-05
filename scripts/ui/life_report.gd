## The death screen (docs/ROADMAP.md Phase 7 "Life Report"). Purely a
## display + one button — GameManager owns the actual life-ending/starting
## logic and just tells this what to show.
class_name LifeReport
extends CanvasLayer

signal new_life_requested

@onready var _days_label: Label = %DaysLabel
@onready var _job_label: Label = %JobLabel
@onready var _money_label: Label = %MoneyLabel
@onready var _cause_label: Label = %CauseLabel
@onready var _button: Button = %NewLifeButton


func _ready() -> void:
	# Must keep working while the game is paused underneath it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button.pressed.connect(func() -> void: new_life_requested.emit())


func set_stats(days_survived: int, job_name: String, money: float, cause: String) -> void:
	_days_label.text = "Days Survived: %d" % days_survived
	_job_label.text = "Job: %s" % job_name
	_money_label.text = "Money: $%d" % int(money)
	_cause_label.text = "Cause of Death:\n%s" % (cause if not cause.is_empty() else "Unknown")
