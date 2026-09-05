## Detects when a vehicle is moving fast enough to actually hurt someone it
## touches — the player or a citizen — rather than just being solid scenery.
##
## Attach as a child of any vehicle body that exposes `current_speed()`
## (SimpleVehicle, PoliceAI). Kept separate from those scripts' own driving
## logic so both share identical, simply-readable impact rules instead of
## duplicating them (docs/ROADMAP.md Phase 7: "Keep damage rules simple and
## readable").
##
## The speed threshold is what keeps ordinary traffic from being a constant
## threat: normal patrol/loop speeds sit below it, reckless driving and
## police response/pursuit sit above it.
extends Node

const SPEED_THRESHOLD := 7.0
const HIT_RADIUS := 1.5
const PLAYER_DAMAGE := 35.0
## Radius nearby citizens flee from after a real hit — reuses the same
## danger-reaction pipeline a Hero crime uses (CitizenDangerReactor).
const HIT_DANGER_RADIUS := 12.0
## Avoids re-hitting every single physics frame while still overlapping.
const HIT_COOLDOWN := 2.0

@onready var _body: Node3D = get_parent()

var _cooldown_remaining: float = 0.0


func _physics_process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
		return
	if _body.current_speed() < SPEED_THRESHOLD:
		return
	if _try_hit_player():
		return
	_try_hit_citizen()


func _try_hit_player() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or _body.global_position.distance_to(player.global_position) > HIT_RADIUS:
		return false

	var health: Health = player.get_node_or_null("Health")
	if health == null:
		return false

	var pos: Vector3 = _body.global_position
	health.take_damage(PLAYER_DAMAGE, _describe_cause())
	WorldEvents.player_injured.emit(pos)
	WorldEvents.vehicle_collision.emit(pos)
	WorldEvents.danger_created.emit(pos, HIT_DANGER_RADIUS)
	_cooldown_remaining = HIT_COOLDOWN
	return true


func _try_hit_citizen() -> void:
	for citizen in get_tree().get_nodes_in_group("citizens"):
		if _body.global_position.distance_to(citizen.global_position) > HIT_RADIUS:
			continue
		var pos: Vector3 = _body.global_position
		# No injury/recovery simulation — a severe hit just removes the
		# citizen from the simulation (docs/ROADMAP.md: "do not build
		# complex injury simulation", "avoid gore").
		citizen.queue_free()
		WorldEvents.civilian_injured.emit(pos)
		WorldEvents.vehicle_collision.emit(pos)
		WorldEvents.danger_created.emit(pos, HIT_DANGER_RADIUS)
		_cooldown_remaining = HIT_COOLDOWN
		return


func _describe_cause() -> String:
	if _body is PoliceAI:
		return "Hit by a police vehicle during a high-speed response"
	for unit in get_tree().get_nodes_in_group("police"):
		if unit.pursuit_target() == _body:
			return "Hit by a stolen vehicle during a police pursuit"
	if _body.has_method("is_available") and not _body.is_available():
		return "Hit by a stolen vehicle"
	return "Hit by a vehicle"
