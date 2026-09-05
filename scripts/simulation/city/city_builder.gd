## Procedurally lays out the Phase 2 "smallest possible believable city":
## a 4x4 grid of blocks connected by roads, with one building per block.
##
## Generated at runtime (rather than hand-placed in the scene) so the whole
## layout stays driven by a small data table (SPECIAL_BUILDINGS below)
## instead of dozens of duplicated nodes. All geometry is placeholder
## low-poly boxes per AGENTS.md ("use placeholders when assets are
## unavailable") — swap in real building assets without touching the grid
## logic.
class_name CityBuilder
extends Node3D

enum BuildingType { GENERIC, APARTMENT, CONVENIENCE_STORE, HOSPITAL, POLICE_STATION }

const GRID_SIZE := 4
const BLOCK_SIZE := 16.0
const ROAD_WIDTH := 8.0
const SIDEWALK_HEIGHT := 0.15
const SIDEWALK_MARGIN := 2.0 ## gap between block edge and building footprint

const CITY_SIZE := GRID_SIZE * BLOCK_SIZE + (GRID_SIZE + 1) * ROAD_WIDTH
const GROUND_MARGIN := 10.0

## Which grid cells hold the buildings the player actually needs to find.
## Everything else is filled with generic filler buildings for skyline variety.
const SPECIAL_BUILDINGS := {
	"0,0": BuildingType.APARTMENT,
	"3,3": BuildingType.CONVENIENCE_STORE,
	"0,3": BuildingType.HOSPITAL,
	"3,0": BuildingType.POLICE_STATION,
}

const BUILDING_INFO := {
	BuildingType.APARTMENT: {"label": "Home", "color": Color(0.55, 0.42, 0.32), "height": 6.0},
	BuildingType.CONVENIENCE_STORE: {
		"label": "Convenience Store", "color": Color(0.85, 0.75, 0.2), "height": 4.0
	},
	BuildingType.HOSPITAL: {"label": "Hospital", "color": Color(0.9, 0.92, 0.95), "height": 8.0},
	BuildingType.POLICE_STATION: {
		"label": "Police Station", "color": Color(0.22, 0.32, 0.7), "height": 7.0
	},
}

const GENERIC_HEIGHTS := [3.0, 5.0, 4.0, 6.0, 3.5, 4.5]
const GENERIC_COLORS := [
	Color(0.6, 0.6, 0.65), Color(0.65, 0.55, 0.5), Color(0.55, 0.6, 0.6), Color(0.6, 0.55, 0.62)
]

@onready var _player: Player = %Player

var _home_spawn_point: Vector3 = Vector3.ZERO


func _ready() -> void:
	_build_ground()
	for row in GRID_SIZE:
		for col in GRID_SIZE:
			_build_block(row, col)
	_spawn_traffic()
	_player.global_position = _home_spawn_point
	print("NPC LIFE — city generated (%dx%d blocks), player spawned at home: %s" % [
		GRID_SIZE, GRID_SIZE, _home_spawn_point
	])


func _cell_origin(row: int, col: int) -> Vector2:
	var x := ROAD_WIDTH + row * (BLOCK_SIZE + ROAD_WIDTH)
	var z := ROAD_WIDTH + col * (BLOCK_SIZE + ROAD_WIDTH)
	return Vector2(x, z)


func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Roads"
	add_child(ground)

	var size := CITY_SIZE + GROUND_MARGIN * 2.0
	var center := CITY_SIZE / 2.0

	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.material = _make_material(Color(0.32, 0.32, 0.34))
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(center, 0.0, center)
	ground.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size, 0.1, size)
	collision.shape = shape
	collision.position = Vector3(center, -0.05, center)
	ground.add_child(collision)


func _build_block(row: int, col: int) -> void:
	var key := "%d,%d" % [row, col]
	var type: BuildingType = SPECIAL_BUILDINGS.get(key, BuildingType.GENERIC)
	var origin := _cell_origin(row, col)
	var center := origin + Vector2(BLOCK_SIZE, BLOCK_SIZE) / 2.0

	_build_sidewalk(center)

	var height: float
	var color: Color
	var label: String
	if type == BuildingType.GENERIC:
		var idx := row * GRID_SIZE + col
		height = GENERIC_HEIGHTS[idx % GENERIC_HEIGHTS.size()]
		color = GENERIC_COLORS[idx % GENERIC_COLORS.size()]
		label = ""
	else:
		var info: Dictionary = BUILDING_INFO[type]
		height = info["height"]
		color = info["color"]
		label = info["label"]

	_build_building(center, height, color, label)

	if type == BuildingType.APARTMENT:
		# Stand just outside the building's front face (south side), facing it.
		var building_half := (BLOCK_SIZE - SIDEWALK_MARGIN * 2.0) / 2.0
		_home_spawn_point = Vector3(center.x, SIDEWALK_HEIGHT, center.y - building_half - 1.0)


func _build_sidewalk(center: Vector2) -> void:
	var body := StaticBody3D.new()
	body.name = "Sidewalk"
	body.position = Vector3(center.x, SIDEWALK_HEIGHT / 2.0, center.y)
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(BLOCK_SIZE, SIDEWALK_HEIGHT, BLOCK_SIZE)
	box.material = _make_material(Color(0.68, 0.68, 0.66))
	mesh_instance.mesh = box
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	body.add_child(collision)


func _build_building(center: Vector2, height: float, color: Color, label: String) -> void:
	var footprint := BLOCK_SIZE - SIDEWALK_MARGIN * 2.0

	var body := StaticBody3D.new()
	body.name = "Building"
	body.position = Vector3(center.x, SIDEWALK_HEIGHT + height / 2.0, center.y)
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(footprint, height, footprint)
	box.material = _make_material(color)
	mesh_instance.mesh = box
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	body.add_child(collision)

	if not label.is_empty():
		var label3d := Label3D.new()
		label3d.text = label
		label3d.position = Vector3(0.0, height / 2.0 + 1.0, 0.0)
		label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label3d.font_size = 48
		label3d.outline_size = 8
		body.add_child(label3d)


func _spawn_traffic() -> void:
	var half_lane := ROAD_WIDTH / 2.0
	var near := half_lane
	var far := CITY_SIZE - half_lane
	var loop_waypoints := PackedVector3Array([
		Vector3(near, 0.0, near),
		Vector3(far, 0.0, near),
		Vector3(far, 0.0, far),
		Vector3(near, 0.0, far),
	])

	var vehicle_scene: PackedScene = load("res://scenes/vehicles/simple_vehicle.tscn")
	for i in 2:
		var vehicle: SimpleVehicle = vehicle_scene.instantiate()
		vehicle.waypoints = loop_waypoints
		vehicle.start_index = i * 2
		add_child(vehicle)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
