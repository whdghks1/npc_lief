## Autonomous police patrol car. Reacts to world events via
## PoliceDispatcher — never talks to HeroAI directly (docs/ROADMAP.md
## Phase 6: "Police should react primarily through WorldEvents").
##
## Simple deterministic state machine, no behavior trees/GOAP/ML, per
## AGENTS.md. Movement routes via CityBuilder.route_between() rather than a
## straight line to whatever target it's given (like SimpleVehicle) — no
## realistic police-driving physics, no line-of-sight simulation. "Locating"
## the target is just a distance check.
##
## CityBuilder only instantiates and places this scene — all police
## behavior lives here.
class_name PoliceAI
extends AnimatableBody3D

enum State { PATROL, RESPOND, PURSUE, SEARCH, RETURN_TO_PATROL }

const PATROL_SPEED := 3.0
const RESPOND_SPEED := 9.0
## A little faster than Hero's reckless-driving speed (see HeroAI.DRIVE_SPEED)
## so a pursuit is a real threat — Hero still escapes via unpredictable
## retargeting and eventually ditching the car, not by simply outrunning police.
const PURSUE_SPEED := 11.0
const SEARCH_SPEED := 5.0
const RETURN_SPEED := 4.0

const ARRIVE_DISTANCE := 3.0
## How close police need to get to "reasonably locate" the incident vehicle.
const DETECTION_RADIUS := 20.0
## Beyond this distance, pursuit no longer counts as "following" — police
## loses track and starts searching instead of chasing forever.
const LOSE_DISTANCE := 45.0
const SEARCH_DURATION := 12.0
## How many nearby road intersections to pick a patrol/search target from.
const NEARBY_ROAD_POINT_COUNT := 4
## Re-route (see _drive_toward()) once the target has moved this far since
## the last computed route — matters for PURSUE, whose target moves every
## frame; re-routing on every tiny drift would be wasteful and jittery.
const REROUTE_THRESHOLD := 2.0

var current_state: State = State.PATROL
var home_position: Vector3 = Vector3.ZERO ## near the Police Station

var _target_vehicle: Node = null
var _incident_position: Vector3 = Vector3.ZERO
var _last_known_position: Vector3 = Vector3.ZERO
var _current_target: Vector3 = Vector3.ZERO
var _state_timer: float = 0.0

var _city: Node ## CityBuilder, found via group "city"
var _route_waypoints: PackedVector3Array = PackedVector3Array()
var _route_index: int = 0
var _routed_target: Vector3 = Vector3.INF ## sentinel: "no route computed yet"


func _ready() -> void:
	add_to_group("police")
	_city = get_tree().get_first_node_in_group("city")
	global_position = home_position
	_pick_patrol_target()


func state_name() -> String:
	return State.keys()[current_state]


func current_target() -> Vector3:
	return _current_target


func is_available() -> bool:
	return current_state == State.PATROL


## The AI's intended driving speed right now (unscaled by TimeSystem's debug
## fast-forward — see SimpleVehicle.current_speed() for why). Used by
## VehicleImpact to decide whether a touch is a hit or just a bump: normal
## patrol/return speeds stay below the threshold, response/pursuit don't.
func current_speed() -> float:
	match current_state:
		State.PATROL:
			return PATROL_SPEED
		State.RESPOND:
			return RESPOND_SPEED
		State.PURSUE:
			return PURSUE_SPEED
		State.SEARCH:
			return SEARCH_SPEED
		State.RETURN_TO_PATROL:
			return RETURN_SPEED
	return 0.0


## The vehicle this unit is actively pursuing, or null. Used by
## VehicleImpact to phrase "hit during a police pursuit" without reaching
## into this class's internals.
func pursuit_target() -> Node:
	return _target_vehicle if current_state == State.PURSUE else null


## Called by PoliceDispatcher. `vehicle` may be null (e.g. a collision report
## with no known getaway vehicle) — response still drives to the position.
func dispatch_to(position: Vector3, vehicle: Node) -> void:
	if current_state != State.PATROL:
		return
	_incident_position = position
	_target_vehicle = vehicle
	_change_state(State.RESPOND)


## Debug-only: skip straight to pursuit/response for testing, bypassing
## normal dispatch. Nothing else calls this.
func debug_force_response(position: Vector3, vehicle: Node) -> void:
	_incident_position = position
	_target_vehicle = vehicle
	_change_state(State.RESPOND)


func _physics_process(delta: float) -> void:
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.RESPOND:
			_process_respond(delta)
		State.PURSUE:
			_process_pursue(delta)
		State.SEARCH:
			_process_search(delta)
		State.RETURN_TO_PATROL:
			_process_return(delta)


func _change_state(new_state: State) -> void:
	current_state = new_state
	_state_timer = 0.0
	if new_state == State.SEARCH:
		_pick_search_target()


## --- PATROL: stay near the station ---

func _process_patrol(delta: float) -> void:
	_drive_toward(_current_target, PATROL_SPEED, delta)
	if global_position.distance_to(_current_target) <= ARRIVE_DISTANCE:
		_pick_patrol_target()


func _pick_patrol_target() -> void:
	_current_target = _pick_nearby_road_point(home_position)


## --- RESPOND: drive to the reported incident position ---

func _process_respond(delta: float) -> void:
	_current_target = _incident_position
	_drive_toward(_current_target, RESPOND_SPEED, delta)

	if _vehicle_within_detection_range():
		_last_known_position = _target_vehicle.global_position
		_change_state(State.PURSUE)
		return

	if global_position.distance_to(_incident_position) <= ARRIVE_DISTANCE:
		_last_known_position = _incident_position
		_change_state(State.SEARCH)


func _vehicle_within_detection_range() -> bool:
	return (
		_target_vehicle != null
		and is_instance_valid(_target_vehicle)
		and not _target_vehicle.is_available() # still being driven — abandoned counts as lost
		and global_position.distance_to(_target_vehicle.global_position) <= DETECTION_RADIUS
	)


## --- PURSUE: chase the (moving) target vehicle ---

func _process_pursue(delta: float) -> void:
	if _target_vehicle == null or not is_instance_valid(_target_vehicle):
		_change_state(State.SEARCH)
		return
	if _target_vehicle.is_available():
		# Abandoned — Hero fled on foot. Search from where it was left.
		_last_known_position = _target_vehicle.global_position
		_change_state(State.SEARCH)
		return

	_current_target = _target_vehicle.global_position
	_drive_toward(_current_target, PURSUE_SPEED, delta)
	_last_known_position = _current_target

	if global_position.distance_to(_current_target) > LOSE_DISTANCE:
		_change_state(State.SEARCH)


## --- SEARCH: look around the last known position for a while, then give up ---

func _process_search(delta: float) -> void:
	_state_timer += delta

	if _vehicle_within_detection_range():
		_last_known_position = _target_vehicle.global_position
		_change_state(State.PURSUE)
		return

	_drive_toward(_current_target, SEARCH_SPEED, delta)
	if global_position.distance_to(_current_target) <= ARRIVE_DISTANCE:
		_pick_search_target()

	if _state_timer >= SEARCH_DURATION:
		_change_state(State.RETURN_TO_PATROL)


func _pick_search_target() -> void:
	_current_target = _pick_nearby_road_point(_last_known_position)


## --- RETURN_TO_PATROL: head back to the station, then resume patrol ---

func _process_return(delta: float) -> void:
	_current_target = home_position
	_drive_toward(_current_target, RETURN_SPEED, delta)
	if global_position.distance_to(home_position) <= ARRIVE_DISTANCE:
		_target_vehicle = null
		_change_state(State.PATROL)


## --- Shared helpers ---

func _pick_nearby_road_point(near: Vector3) -> Vector3:
	if _city != null:
		var options: Array[Vector3] = _city.get_nearby_road_points(near, NEARBY_ROAD_POINT_COUNT)
		if not options.is_empty():
			return options[randi() % options.size()]
	return near


## Routes via CityBuilder rather than driving straight at the target, so
## patrol/response/pursuit/search all turn at intersections instead of
## cutting through a building block. Only recomputes the route when the
## target has moved meaningfully (REROUTE_THRESHOLD) since last time — matters
## for PURSUE, whose target moves every frame; re-routing every frame would
## be wasteful and produce jittery, constantly-corner-cutting movement.
func _drive_toward(target: Vector3, speed: float, delta: float) -> void:
	if _city != null and target.distance_to(_routed_target) > REROUTE_THRESHOLD:
		_route_waypoints = _city.route_between(global_position, target)
		_route_index = 0
		_routed_target = target

	var waypoints := _route_waypoints if not _route_waypoints.is_empty() else PackedVector3Array([target])
	var next_point: Vector3 = waypoints[mini(_route_index, waypoints.size() - 1)]

	var dir := next_point - global_position
	dir.y = 0.0
	if dir.length() <= 0.5:
		if _route_index < waypoints.size() - 1:
			_route_index += 1
		return
	dir = dir.normalized()
	# Scales with the simulation clock, same as SimpleVehicle/Citizen/Hero —
	# see TimeSystem.speed_multiplier().
	global_position += dir * speed * TimeSystem.speed_multiplier() * delta
	rotation.y = atan2(dir.x, dir.z)
