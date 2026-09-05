## Autonomous "Hero" — an AI character that behaves like someone playing an
## open-world action game, independent of the player (docs/GAME_DESIGN.md
## "Hero System", AGENTS.md "Hero Rule"). It never queries the player's
## position or treats the player specially; it picks goals based on the
## city (wander points, nearby vehicles) the same way it would if the
## player didn't exist.
##
## Simple deterministic state machine — no behavior trees/GOAP/ML, per
## AGENTS.md. State transitions are plain timers and distance checks.
##
## CityBuilder only instantiates and places this scene (see the
## architecture note in city_builder.gd) — all Hero behavior lives here.
##
## Hero only ever emits WorldEvents; it does not know citizens or police
## exist (docs/ROADMAP.md Phase 6: Hero → WorldEvents → citizens/police
## react independently). See CitizenDangerReactor and PoliceDispatcher.
class_name HeroAI
extends CharacterBody3D

enum State {
	WANDER, SELECT_VEHICLE, APPROACH_VEHICLE, STEAL_VEHICLE,
	DRIVE, COMMIT_CRIME, ESCAPE, HIDE, COOLDOWN,
}

const WALK_SPEED := 2.4
const DRIVE_SPEED := 10.0
const ARRIVE_DISTANCE := 1.5
const VEHICLE_ARRIVE_DISTANCE := 2.5
## The radius broadcast with danger_created — how far the danger reaches is
## each listener's own business (CitizenDangerReactor uses it to decide
## which citizens flee); Hero itself doesn't know or care who reacts.
const DANGER_RADIUS := 15.0

const WANDER_MIN_TIME := 10.0
const WANDER_MAX_TIME := 20.0
const DRIVE_MIN_TIME := 8.0
const DRIVE_MAX_TIME := 16.0
const ESCAPE_TIME := 10.0
const HIDE_TIME := 6.0
## Guarantees a calm period after every incident even without a full Event
## Director (Phase 8) — "quiet periods are necessary" (docs/GAME_DESIGN.md)
## applies to a single Hero's own pacing too, not just city-wide chaos.
const COOLDOWN_TIME := 15.0
const CRIME_DURATION := 2.0
const RECKLESS_RETARGET_INTERVAL := 3.0

## Stuck recovery, same rationale/values as Citizen (see its class doc) —
## this Hero walks the same navmesh citizens do.
const STUCK_CHECK_INTERVAL := 0.5
const STUCK_PROGRESS_THRESHOLD := 0.2
const STUCK_TIME_LIMIT := 1.5

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _collision: CollisionShape3D = $CollisionShape3D

var current_state: State = State.WANDER
var current_target_vehicle: Node = null ## SimpleVehicle, while relevant
var is_driving: bool = false

var _city: Node ## CityBuilder, found via group "city"
var _home_parent: Node
var _state_timer: float = 0.0
var _state_duration: float = 0.0
var _retarget_timer: float = 0.0
var _wander_target: Vector3 = Vector3.ZERO

var _stuck_check_elapsed: float = 0.0
var _stuck_time: float = 0.0
var _last_stuck_pos: Vector3 = Vector3.ZERO
var _direct_approach: bool = false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	add_to_group("hero")
	_home_parent = get_parent()
	_city = get_tree().get_first_node_in_group("city")
	_enter_wander()


func state_name() -> String:
	return State.keys()[current_state]


## Debug-only: skip straight to an incident instead of waiting out the
## normal wander/select/approach timing — for verifying the crime/citizen-
## reaction chain quickly. Does not alter normal autonomous pacing; nothing
## calls this except the debug overlay hotkey.
func debug_force_crime() -> void:
	if not is_driving:
		var nearest := _find_nearest_available_vehicle()
		if nearest == null:
			return
		current_target_vehicle = nearest
		global_position = nearest.global_position # debug-only: skip the walk over
		_change_state(State.STEAL_VEHICLE)
		# _change_state(DRIVE) above only arms the retarget timer — the
		# actual drive_to() call normally happens on the next physics frame
		# (_process_drive). Do it now too, or the vehicle sits at speed 0
		# when we immediately jump to COMMIT_CRIME below.
		_pick_reckless_target()
	_change_state(State.COMMIT_CRIME)


func _physics_process(delta: float) -> void:
	match current_state:
		State.WANDER:
			_apply_gravity(delta)
			_process_wander(delta)
			move_and_slide()
		State.SELECT_VEHICLE:
			_process_select_vehicle()
		State.APPROACH_VEHICLE:
			_apply_gravity(delta)
			_process_approach_vehicle(delta)
			move_and_slide()
		State.DRIVE:
			_process_drive(delta)
		State.COMMIT_CRIME:
			_process_commit_crime(delta)
		State.ESCAPE:
			_process_escape(delta)
		State.HIDE:
			_apply_gravity(delta)
			move_and_slide()
			_process_hide(delta)
		State.COOLDOWN:
			_apply_gravity(delta)
			_process_wander_step()
			_process_cooldown(delta)
			move_and_slide()
		State.STEAL_VEHICLE:
			pass # instantaneous, handled by _enter_steal_vehicle()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta


func _change_state(new_state: State) -> void:
	current_state = new_state
	_state_timer = 0.0
	match new_state:
		State.WANDER:
			_enter_wander()
		State.APPROACH_VEHICLE:
			_reset_stuck_tracking()
			if current_target_vehicle != null:
				current_target_vehicle.freeze()
		State.STEAL_VEHICLE:
			_enter_steal_vehicle()
		State.DRIVE:
			_enter_drive()
		State.COMMIT_CRIME:
			_enter_commit_crime()
		State.ESCAPE:
			_enter_escape()
		State.HIDE:
			_enter_hide()
		State.COOLDOWN:
			_pick_wander_target()


## --- WANDER: walk the city on foot with no particular purpose ---

func _enter_wander() -> void:
	_state_duration = randf_range(WANDER_MIN_TIME, WANDER_MAX_TIME)
	_pick_wander_target()


func _process_wander(delta: float) -> void:
	_state_timer += delta
	_process_wander_step()
	if _state_timer >= _state_duration:
		_change_state(State.SELECT_VEHICLE)


func _process_cooldown(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= COOLDOWN_TIME:
		_change_state(State.WANDER)


func _process_wander_step() -> void:
	if _walk_toward(_wander_target, WALK_SPEED, ARRIVE_DISTANCE):
		_pick_wander_target()


func _pick_wander_target() -> void:
	if _city != null:
		var points: Array[Vector3] = _city.get_wander_points()
		if not points.is_empty():
			_wander_target = points[randi() % points.size()]
	_reset_stuck_tracking()


## --- SELECT_VEHICLE: instantly pick the nearest available vehicle ---

func _process_select_vehicle() -> void:
	var nearest := _find_nearest_available_vehicle()
	if nearest != null:
		current_target_vehicle = nearest
		_change_state(State.APPROACH_VEHICLE)
	else:
		_change_state(State.WANDER) # nothing to steal right now


func _find_nearest_available_vehicle() -> Node:
	var nearest: Node = null
	var nearest_dist := INF
	for v in get_tree().get_nodes_in_group("vehicles"):
		if not v.is_available():
			continue
		var d: float = global_position.distance_to(v.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = v
	return nearest


## --- APPROACH_VEHICLE: walk toward the (possibly moving) target vehicle ---

func _process_approach_vehicle(delta: float) -> void:
	if not _vehicle_still_available():
		_change_state(State.WANDER)
		return
	_state_timer += delta
	if _walk_toward(current_target_vehicle.global_position, WALK_SPEED, VEHICLE_ARRIVE_DISTANCE):
		_change_state(State.STEAL_VEHICLE)


func _vehicle_still_available() -> bool:
	return (
		current_target_vehicle != null
		and is_instance_valid(current_target_vehicle)
		and current_target_vehicle.is_available()
	)


## --- STEAL_VEHICLE: instant — take control, disappear into the vehicle ---

func _enter_steal_vehicle() -> void:
	if not _vehicle_still_available():
		_change_state(State.WANDER)
		return
	current_target_vehicle.driver = self
	is_driving = true
	visible = false
	_collision.disabled = true
	reparent(current_target_vehicle)
	WorldEvents.vehicle_stolen.emit(current_target_vehicle, current_target_vehicle.global_position)
	WorldEvents.hero_activity_started.emit(self)
	_change_state(State.DRIVE)


## --- DRIVE: reckless driving, no fixed route ---

func _enter_drive() -> void:
	_state_timer = 0.0
	_retarget_timer = RECKLESS_RETARGET_INTERVAL # force an immediate retarget
	_state_duration = randf_range(DRIVE_MIN_TIME, DRIVE_MAX_TIME)


func _process_drive(delta: float) -> void:
	if not is_driving:
		return
	_state_timer += delta
	_retarget_timer += delta
	if _retarget_timer >= RECKLESS_RETARGET_INTERVAL:
		_retarget_timer = 0.0
		_pick_reckless_target()
	if _state_timer >= _state_duration:
		_change_state(State.COMMIT_CRIME)


func _pick_reckless_target() -> void:
	if current_target_vehicle != null and _city != null:
		current_target_vehicle.drive_to(_city.get_random_road_point(), DRIVE_SPEED)


## --- COMMIT_CRIME: a discrete incident — this is what citizens react to ---

## Only emits — it's up to whoever's listening (CitizenDangerReactor,
## PoliceDispatcher, later News) to decide what to do about it. Hero has no
## idea citizens or police exist.
func _enter_commit_crime() -> void:
	var pos := global_position
	WorldEvents.dangerous_driving_started.emit(pos)
	WorldEvents.collision_occurred.emit(pos)
	WorldEvents.danger_created.emit(pos, DANGER_RADIUS)


func _process_commit_crime(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= CRIME_DURATION:
		_change_state(State.ESCAPE)


## --- ESCAPE: keep driving recklessly, away from the scene ---

func _enter_escape() -> void:
	_retarget_timer = RECKLESS_RETARGET_INTERVAL
	_pick_reckless_target()


func _process_escape(delta: float) -> void:
	if not is_driving:
		return
	_state_timer += delta
	_retarget_timer += delta
	if _retarget_timer >= RECKLESS_RETARGET_INTERVAL:
		_retarget_timer = 0.0
		_pick_reckless_target()
	if _state_timer >= ESCAPE_TIME:
		_change_state(State.HIDE)


## --- HIDE: abandon the vehicle, lay low on foot ---

func _enter_hide() -> void:
	if current_target_vehicle != null and is_instance_valid(current_target_vehicle):
		current_target_vehicle.stop_driving()
	is_driving = false
	var drop_position := global_position
	reparent(_home_parent)
	global_position = drop_position
	visible = true
	_collision.disabled = false
	current_target_vehicle = null


func _process_hide(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= HIDE_TIME:
		_change_state(State.COOLDOWN)


## --- Shared on-foot movement helper (WANDER / APPROACH_VEHICLE / COOLDOWN) ---
## Mirrors scripts/ai/citizen/citizen.gd's movement — same navmesh, same
## occasional edge-case pathing quirks, same fix. See its class doc.

func _walk_toward(target: Vector3, speed: float, arrive_distance: float) -> bool:
	if global_position.distance_to(target) <= arrive_distance:
		velocity.x = 0.0
		velocity.z = 0.0
		return true

	# Scales with the simulation clock, same as Citizen and SimpleVehicle —
	# see TimeSystem.speed_multiplier().
	var scaled_speed := speed * TimeSystem.speed_multiplier()
	if _direct_approach:
		_move_toward(target, scaled_speed)
	else:
		_nav_agent.target_position = target
		if _nav_agent.is_navigation_finished():
			velocity.x = 0.0
			velocity.z = 0.0
			return true
		_move_toward(_nav_agent.get_next_path_position(), scaled_speed)
		if _check_stuck():
			_direct_approach = true
			_reset_stuck_timer()
	return false


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


func _reset_stuck_tracking() -> void:
	_reset_stuck_timer()
	_direct_approach = false


func _reset_stuck_timer() -> void:
	_stuck_check_elapsed = 0.0
	_stuck_time = 0.0
	_last_stuck_pos = global_position


func _check_stuck() -> bool:
	_stuck_check_elapsed += get_physics_process_delta_time()
	if _stuck_check_elapsed < STUCK_CHECK_INTERVAL:
		return false
	_stuck_check_elapsed = 0.0
	if global_position.distance_to(_last_stuck_pos) < STUCK_PROGRESS_THRESHOLD:
		_stuck_time += STUCK_CHECK_INTERVAL
	else:
		_stuck_time = 0.0
	_last_stuck_pos = global_position
	return _stuck_time >= STUCK_TIME_LIMIT
