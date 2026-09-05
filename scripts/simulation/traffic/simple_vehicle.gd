## Minimal placeholder traffic: a solid body that loops through a fixed list
## of waypoints at constant speed. There is no AI or decision-making here —
## Phase 2 only calls for "simple traffic" so the city doesn't feel dead.
##
## Phase 5 adds the ability for a Hero (or later, anyone) to "drive" it:
## setting `driver` switches it from its normal fixed loop to going wherever
## drive_to() last pointed it, at whatever speed was given — the vehicle
## itself has no idea who's driving or why, it just follows orders once it
## has a driver. This keeps HeroAI's reckless-driving decisions entirely in
## HeroAI; this script only knows "loop" and "go here at this speed."
## drive_to() routes via CityBuilder.route_between() rather than a straight
## line, so it turns at intersections instead of cutting through buildings.
##
## AnimatableBody3D (rather than StaticBody3D/RigidBody3D) is the correct
## Godot node for a scripted-moving solid object: it stays solid to
## CharacterBody3D collision without the overhead of full rigid-body physics.
##
## Its `sync_to_physics` is set to false in the scene: that flag is for
## bodies moved via AnimationPlayer (it makes the physics server read the
## transform back from the rendering side). Since this script drives the
## transform directly instead, sync_to_physics=true fights the manual
## assignment below and the body never visibly moves.
class_name SimpleVehicle
extends AnimatableBody3D

@export var waypoints: PackedVector3Array = PackedVector3Array()
@export var speed: float = 6.0
## Offsets which waypoint this vehicle starts heading toward, so multiple
## vehicles sharing the same loop don't all bunch up together.
@export var start_index: int = 0

## Non-null while a Hero (or similar) has taken control. Normal traffic
## looping pauses while this is set.
var driver: Node = null

var _target_index: int = 0
var _manual_waypoints: PackedVector3Array = PackedVector3Array()
var _manual_wp_index: int = 0
var _manual_speed: float = 0.0
var _city: Node ## CityBuilder, found via group "city"
## True while someone is approaching this vehicle on foot to steal it. A
## vehicle several times faster than a walking pedestrian would otherwise be
## impossible to catch on its own loop — "vehicle stops or becomes
## available" is the documented Phase 5 simplification for exactly this
## (docs/ROADMAP.md), so it just waits in place instead.
var _frozen: bool = false


func _ready() -> void:
	add_to_group("vehicles")
	_city = get_tree().get_first_node_in_group("city")
	if not waypoints.is_empty():
		_target_index = start_index % waypoints.size()
		global_position = waypoints[_target_index]


func is_available() -> bool:
	return driver == null


func freeze() -> void:
	_frozen = true


func unfreeze() -> void:
	_frozen = false


## Called by whoever has `driver` set on this vehicle to steer it. Routes
## via CityBuilder rather than a straight line so reckless driving turns at
## intersections instead of cutting diagonally through a building block.
func drive_to(target: Vector3, at_speed: float) -> void:
	if _city != null:
		_manual_waypoints = _city.route_between(global_position, target)
	else:
		_manual_waypoints = PackedVector3Array([target])
	_manual_wp_index = 0
	_manual_speed = at_speed


## Abandons the vehicle where it sits — it does not resume its old traffic
## loop (an abandoned stolen car staying put is the expected outcome here).
func stop_driving() -> void:
	driver = null
	_manual_speed = 0.0
	_manual_waypoints = PackedVector3Array()


func _physics_process(delta: float) -> void:
	if driver != null:
		_drive_manually(delta)
	else:
		_follow_loop(delta)


func _drive_manually(delta: float) -> void:
	if _manual_waypoints.is_empty() or _manual_speed <= 0.0:
		return
	var target: Vector3 = _manual_waypoints[_manual_wp_index]
	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.5:
		if _manual_wp_index < _manual_waypoints.size() - 1:
			_manual_wp_index += 1
		return
	var dir := to_target.normalized()
	global_position += dir * _manual_speed * TimeSystem.speed_multiplier() * delta
	rotation.y = atan2(dir.x, dir.z)


func _follow_loop(delta: float) -> void:
	if _frozen or waypoints.is_empty():
		return
	var target: Vector3 = waypoints[_target_index]
	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.5:
		_target_index = (_target_index + 1) % waypoints.size()
		return
	var dir := to_target.normalized()
	# Scales with the simulation clock (see TimeSystem.speed_multiplier())
	# so fast-forwarding time actually looks fast-forwarded.
	global_position += dir * speed * TimeSystem.speed_multiplier() * delta
	rotation.y = atan2(dir.x, dir.z)
