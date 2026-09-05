## Data for one job (docs/ARCHITECTURE.md "Data Driven Design" — jobs are
## resources, not hardcoded player logic). Saved instances live in data/jobs/.
class_name JobDefinition
extends Resource

@export var job_name: String = ""
@export var workplace_name: String = ""
@export var start_hour: int = 9
@export var start_minute: int = 0
@export var end_hour: int = 17
@export var end_minute: int = 0
@export var salary: float = 40.0
## Grace period after start time before a shift counts as late.
@export var late_threshold_minutes: int = 10
@export var late_penalty: float = 10.0


func start_total_minutes() -> int:
	return start_hour * 60 + start_minute


func end_total_minutes() -> int:
	return end_hour * 60 + end_minute


func get_schedule_string() -> String:
	return "%02d:%02d–%02d:%02d" % [start_hour, start_minute, end_hour, end_minute]
