## Minimal placeholder traffic: a solid body that loops through a fixed list
## of waypoints at constant speed. There is no AI or decision-making here —
## Phase 2 only calls for "simple traffic" so the city doesn't feel dead.
## Real traffic behavior (reacting to events, other vehicles, etc.) is a
## later-phase concern (docs/ROADMAP.md Phase 4 "Living City" onward).
##
## AnimatableBody3D (rather than StaticBody3D/RigidBody3D) is the correct
## Godot node for a scripted-moving solid object: it stays solid to
## CharacterBody3D collision without the overhead of full rigid-body physics.
class_name SimpleVehicle
extends AnimatableBody3D

@export var waypoints: PackedVector3Array = PackedVector3Array()
@export var speed: float = 6.0
## Offsets which waypoint this vehicle starts heading toward, so multiple
## vehicles sharing the same loop don't all bunch up together.
@export var start_index: int = 0

var _target_index: int = 0


func _ready() -> void:
	if not waypoints.is_empty():
		_target_index = start_index % waypoints.size()
		global_position = waypoints[_target_index]


func _physics_process(delta: float) -> void:
	if waypoints.is_empty():
		return
	var target: Vector3 = waypoints[_target_index]
	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.5:
		_target_index = (_target_index + 1) % waypoints.size()
		return
	var dir := to_target.normalized()
	global_position += dir * speed * delta
	rotation.y = atan2(dir.x, dir.z)
