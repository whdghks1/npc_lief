## A reusable pedestrian NPC: a simple state machine driven by a data-driven
## daily schedule (CitizenSchedule) and Godot's navigation system.
##
## CityBuilder only assigns this instance its home/work/food points and a
## shared schedule archetype — all the behavior lives here, not in
## CityBuilder (see the architecture note in city_builder.gd).
##
## Performance: schedule/state decisions are only evaluated once per
## simulated minute (on TimeSystem.minute_passed), not every frame. Only
## movement itself runs in _physics_process, and only while actually walking.
class_name Citizen
extends CharacterBody3D

enum State { IDLE, WALK_TO_DESTINATION, WORK, EAT, RETURN_HOME, FLEE }

const WALK_SPEED := 2.2
const FLEE_SPEED := 4.5
const ARRIVE_DISTANCE := 1.0

## Stuck recovery: if a citizen makes no meaningful progress toward its nav
## target for this long, it switches to walking straight at the target in a
## direct line instead of via the navmesh. This has been observed near a
## few destinations where Recast's baked path reports "not yet arrived" a
## handful of centimeters short, forever (a voxelization quirk right at a
## building edge, not a real obstacle) — "reach destinations reliably"
## (docs/ROADMAP.md Phase 4) matters more for a placeholder prototype than
## perfect pathing fidelity, and a short direct final approach is visually
## indistinguishable from normal walking in this simple, boxy city.
const STUCK_CHECK_INTERVAL := 0.5
const STUCK_PROGRESS_THRESHOLD := 0.2
const STUCK_TIME_LIMIT := 1.5

@export var schedule: CitizenSchedule
@export var home_position: Vector3
@export var work_position: Vector3
@export var food_position: Vector3

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D

var current_state: State = State.IDLE

var _next_entry_index: int = 0
var _active_target: Vector3 = Vector3.ZERO
var _active_arrival_state: State = State.IDLE
var _pre_flee_state: State = State.IDLE
var _flee_from_position: Vector3 = Vector3.ZERO

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

var _stuck_check_elapsed: float = 0.0
var _stuck_time: float = 0.0
var _last_stuck_check_pos: Vector3 = Vector3.ZERO
var _direct_approach: bool = false


func _ready() -> void:
	add_to_group("citizens")
	global_position = home_position
	_nav_agent.target_desired_distance = ARRIVE_DISTANCE
	_randomize_color()
	TimeSystem.day_changed.connect(_on_day_changed)
	TimeSystem.minute_passed.connect(_on_minute_passed)


func current_destination() -> Vector3:
	return _active_target


func state_name() -> String:
	return State.keys()[current_state]


## --- Future-event reaction API (Phase 5+; nothing calls these yet) ---

func react_to_danger(danger_position: Vector3) -> void:
	flee_from(danger_position)


func flee_from(danger_position: Vector3) -> void:
	if current_state == State.FLEE:
		return
	_pre_flee_state = current_state
	_flee_from_position = danger_position
	current_state = State.FLEE


func resume_schedule() -> void:
	if current_state != State.FLEE:
		return
	current_state = _pre_flee_state
	_direct_approach = false
	if current_state == State.WALK_TO_DESTINATION:
		_nav_agent.target_position = _active_target
	elif current_state == State.RETURN_HOME:
		_nav_agent.target_position = home_position

## --- End reaction API ---


func _on_day_changed(_day: int) -> void:
	_next_entry_index = 0


func _on_minute_passed(_hour: int, _minute: int) -> void:
	if current_state == State.FLEE or schedule == null:
		return
	var now := TimeSystem.total_minutes()
	while (
		_next_entry_index < schedule.entries.size()
		and int(schedule.entries[_next_entry_index]["minute_of_day"]) <= now
	):
		_trigger_action(schedule.entries[_next_entry_index]["action"])
		_next_entry_index += 1


func _trigger_action(action: String) -> void:
	match action:
		"go_work":
			_walk_to(work_position, State.WORK)
		"go_food":
			_walk_to(food_position, State.EAT)
		"go_home":
			_active_target = home_position
			_active_arrival_state = State.IDLE
			current_state = State.RETURN_HOME
			_nav_agent.target_position = home_position
			_reset_stuck_tracking()
		"eat_here":
			current_state = State.EAT


func _walk_to(target: Vector3, arrival_state: State) -> void:
	_active_target = target
	_active_arrival_state = arrival_state
	current_state = State.WALK_TO_DESTINATION
	_nav_agent.target_position = target
	_reset_stuck_tracking()


func _reset_stuck_tracking() -> void:
	_reset_stuck_timer()
	_direct_approach = false


func _reset_stuck_timer() -> void:
	_stuck_check_elapsed = 0.0
	_stuck_time = 0.0
	_last_stuck_check_pos = global_position


func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	# Ambient world movement speeds up along with a sped-up clock (debug
	# hotkey [2]), so fast-forwarding actually looks fast-forwarded instead
	# of just spinning the clock while everyone keeps walking at normal
	# real-time pace. See TimeSystem.speed_multiplier().
	var speed_scale := TimeSystem.speed_multiplier()

	match current_state:
		State.WALK_TO_DESTINATION, State.RETURN_HOME:
			if _direct_approach:
				# Short final approach in a straight line, bypassing the
				# navmesh (see the constants above for why). If even THIS
				# gets physically blocked (the direct line clips something),
				# guarantee arrival anyway rather than leave the citizen
				# permanently stuck.
				if global_position.distance_to(_active_target) <= ARRIVE_DISTANCE:
					velocity.x = 0.0
					velocity.z = 0.0
					current_state = _active_arrival_state
				else:
					_move_toward(_active_target, WALK_SPEED * speed_scale)
					if _check_stuck(delta):
						global_position = _active_target
						current_state = _active_arrival_state
			elif _nav_agent.is_navigation_finished():
				velocity.x = 0.0
				velocity.z = 0.0
				current_state = _active_arrival_state
			else:
				_move_toward(_nav_agent.get_next_path_position(), WALK_SPEED * speed_scale)
				if _check_stuck(delta):
					_direct_approach = true
					_reset_stuck_timer()
		State.FLEE:
			_move_away_from(_flee_from_position, FLEE_SPEED * speed_scale)
		_:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()


func _move_toward(target: Vector3, speed: float) -> void:
	var dir := target - global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		rotation.y = atan2(dir.x, dir.z)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _move_away_from(danger_position: Vector3, speed: float) -> void:
	var dir := global_position - danger_position
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	rotation.y = atan2(dir.x, dir.z)


func _check_stuck(delta: float) -> bool:
	_stuck_check_elapsed += delta
	if _stuck_check_elapsed < STUCK_CHECK_INTERVAL:
		return false
	_stuck_check_elapsed = 0.0
	if global_position.distance_to(_last_stuck_check_pos) < STUCK_PROGRESS_THRESHOLD:
		_stuck_time += STUCK_CHECK_INTERVAL
	else:
		_stuck_time = 0.0
	_last_stuck_check_pos = global_position
	return _stuck_time >= STUCK_TIME_LIMIT


func _randomize_color() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.from_hsv(randf(), 0.45, 0.85)
	_mesh.material_override = material
