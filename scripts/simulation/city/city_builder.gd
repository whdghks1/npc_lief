## Procedurally lays out the Phase 2 "smallest possible believable city":
## a 4x4 grid of blocks connected by roads, with one building per block.
##
## Generated at runtime (rather than hand-placed in the scene) so the whole
## layout stays driven by a small data table (SPECIAL_BUILDINGS below)
## instead of dozens of duplicated nodes. All geometry is placeholder
## low-poly boxes per AGENTS.md ("use placeholders when assets are
## unavailable") — swap in real building assets without touching the grid
## logic.
##
## Per the Phase 3 architecture requirement, this script only constructs
## the city and exposes locations (spawn point, workplace, sleep spot, food
## stands, generic building fronts) — it does not contain job/economy/
## hunger/citizen *logic*. That behavior lives in
## scripts/systems/jobs/workplace_trigger.gd,
## scripts/systems/time/sleep_trigger.gd,
## scripts/systems/economy/food_item_trigger.gd, and
## scripts/ai/citizen/citizen.gd; this builder just attaches/spawns those
## components at the right places and wires their config.
##
## Phase 5 adds one more spawned actor: the Hero (scripts/ai/hero/hero_ai.gd).
## CityBuilder places it and exposes generic wander/drive points, same as it
## does for citizens — it has no idea what the Hero does with them.
##
## Phase 6 adds a small police patrol (scripts/ai/police/police_ai.gd),
## based near the Police Station. Same rule: CityBuilder only places them —
## PoliceAI and PoliceDispatcher own all response/pursuit/search behavior,
## and react to Hero purely through WorldEvents, never through CityBuilder
## or HeroAI directly.
class_name CityBuilder
extends Node3D

enum BuildingType { GENERIC, APARTMENT, CONVENIENCE_STORE, HOSPITAL, POLICE_STATION }

const GRID_SIZE := 4
const BLOCK_SIZE := 16.0
const ROAD_WIDTH := 8.0
## Sidewalks are perfectly level with the road (0 height difference) rather
## than raised on a curb. An earlier version used a raised curb purely for
## visual distinction; it turned out CharacterBody3D movement (citizens
## *and* the player) doesn't reliably climb even a small step when
## approaching it dead-on, and it also produced a Recast navmesh
## voxelization glitch at the coincident sidewalk/building-base height that
## made some destinations permanently unreachable. Not worth the visual
## touch — sidewalks stay identifiable by color (see _build_sidewalk()).
const SIDEWALK_HEIGHT := 0.0
const SIDEWALK_VISUAL_THICKNESS := 0.03
## Gap between block edge and building footprint — this is the only walkway
## around each building, so it needs to stay wide relative to the navmesh
## agent radius below or Recast can't find a path through it at all
## (see the long comment on NAV_AGENT_RADIUS).
const SIDEWALK_MARGIN := 3.0

const CITY_SIZE := GRID_SIZE * BLOCK_SIZE + (GRID_SIZE + 1) * ROAD_WIDTH
const GROUND_MARGIN := 10.0

## How far solid geometry's COLLISION shape (not its visual mesh) extends
## below its visible base. Without this, a building's bottom face sits
## exactly coincident with the sidewalk's top face — a razor-thin touching
## boundary that Recast's navmesh voxelizer can misread as a stray walkable
## sliver a couple of cells above the real surface, which then makes
## agents unable to ever register "arrived" near that building (confirmed
## while debugging Phase 4: citizens would close to within ~1cm of a
## target horizontally and then stall forever, chasing a phantom elevated
## path point). Extending solid shapes underground removes the coincident
## boundary entirely; it's invisible since only the mesh is rendered.
const UNDERGROUND_EXTENSION := 2.0

const JOB_DATA_PATH := "res://data/jobs/convenience_store_worker.tres"
const WORKPLACE_TRIGGER_SCRIPT := "res://scripts/systems/jobs/workplace_trigger.gd"
const SLEEP_TRIGGER_SCRIPT := "res://scripts/systems/time/sleep_trigger.gd"
const FOOD_ITEM_TRIGGER_SCRIPT := "res://scripts/systems/economy/food_item_trigger.gd"
const HOSPITAL_TRIGGER_SCRIPT := "res://scripts/systems/health/hospital_trigger.gd"

const VEHICLE_SCENE_PATH := "res://scenes/vehicles/simple_vehicle.tscn"
const VEHICLE_COUNT := 4

const CITIZEN_SCENE_PATH := "res://scenes/citizens/citizen.tscn"
const WORKER_SCHEDULE_PATH := "res://data/citizens/schedule_worker.tres"
const SHOPPER_SCHEDULE_PATH := "res://data/citizens/schedule_shopper.tres"
const CITIZEN_COUNT := 16

const HERO_SCENE_PATH := "res://scenes/hero/hero.tscn"

const POLICE_SCENE_PATH := "res://scenes/police/police_unit.tscn"
const POLICE_COUNT := 2

## Navmesh bake tuning. Cell size is coarse (0.5m) since this is all flat,
## axis-aligned placeholder geometry — plenty precise for pedestrian paths
## and much faster to bake than the default (0.25m) at this city's scale.
## agent_radius is intentionally a bit SMALLER than citizens' actual
## collision radius (0.35, see scenes/citizens/citizen.tscn), not larger.
## The walkway around each building (SIDEWALK_MARGIN) is narrow, and Recast
## needs 2x agent_radius of clear width to place a path through a corridor
## at all — a radius sized to "match" the citizen exactly (or add a safety
## buffer, which seemed like the safer choice at first) leaves too little
## room at corners and produces genuinely unreachable pinch points, not
## just tight ones. A smaller nav radius plus physical collision (which
## just slides citizens off a wall instead of blocking them) turned out to
## be far more reliable in practice than a "generous" nav radius.
## cell_size/cell_height match the default navigation map's (0.25) so the
## baked mesh doesn't mismatch it (Godot warns otherwise).
const NAV_AGENT_RADIUS := 0.25 ## exact multiple of NAV_CELL_SIZE (no ceiling warning)
const NAV_AGENT_HEIGHT := 1.75 ## exact multiple of NAV_CELL_HEIGHT (no ceiling warning)
const NAV_AGENT_MAX_CLIMB := 0.25
const NAV_CELL_SIZE := 0.25
const NAV_CELL_HEIGHT := 0.25

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

var _nav_region: NavigationRegion3D

var _home_spawn_point: Vector3 = Vector3.ZERO
var _work_point: Vector3 = Vector3.ZERO
var _police_station_point: Vector3 = Vector3.ZERO
var _food_points: Array[Vector3] = []
## Sidewalk-front points of the generic filler buildings. Citizens use these
## as stand-in "residences" — the city only has one real apartment (the
## player's), so this keeps pedestrians spread out without a housing system.
var _generic_points: Array[Vector3] = []


func _ready() -> void:
	add_to_group("city") # lets Hero/Citizen find this builder for locations

	_nav_region = _make_navigation_region()
	add_child(_nav_region)

	_build_ground()
	for row in GRID_SIZE:
		for col in GRID_SIZE:
			_build_block(row, col)

	# Synchronous bake: this is a one-time startup cost, and citizens need a
	# finished navmesh to path on as soon as they spawn.
	_nav_region.bake_navigation_mesh(false)

	_spawn_traffic()
	_spawn_citizens()
	_spawn_hero()
	_spawn_police()
	_player.global_position = _home_spawn_point
	print(
		"NPC LIFE — city generated (%dx%d blocks), %d citizens, %d police, player spawned at home: %s"
		% [
			GRID_SIZE, GRID_SIZE,
			get_tree().get_nodes_in_group("citizens").size(),
			get_tree().get_nodes_in_group("police").size(),
			_home_spawn_point,
		]
	)


## Every generic filler building's front point, plus home/work/food — used
## by Citizen (residences) and Hero (wander targets) alike. CityBuilder only
## exposes these; it has no opinion about who walks where or why.
func get_wander_points() -> Array[Vector3]:
	var points := _generic_points.duplicate()
	points.append(_home_spawn_point)
	points.append(_work_point)
	points.append_array(_food_points)
	return points


## Every road-centerline coordinate along one axis, e.g. [4, 28, 52, 76, 100]
## for the current GRID_SIZE/BLOCK_SIZE/ROAD_WIDTH — the grid is symmetric,
## so this is the same set of values for both x and z.
func _road_axis_values() -> Array[float]:
	var values: Array[float] = []
	for k in GRID_SIZE + 1:
		values.append(ROAD_WIDTH / 2.0 + k * (BLOCK_SIZE + ROAD_WIDTH))
	return values


func _nearest_axis_distance(value: float, axis_values: Array[float]) -> float:
	var best := INF
	for v in axis_values:
		best = minf(best, absf(value - v))
	return best


## A random road intersection anywhere in the grid, for reckless driving
## that deliberately doesn't follow the normal traffic loop but still needs
## to stay on actual roads.
func get_random_road_point() -> Vector3:
	var xs := _road_axis_values()
	var zs := _road_axis_values()
	return Vector3(xs[randi() % xs.size()], 0.0, zs[randi() % zs.size()])


## A handful of the road intersections closest to a given point — for
## patrol/search behavior that should stay local without leaving the road
## grid (picking only the single nearest one would look robotic/static).
func get_nearby_road_points(from: Vector3, count: int = 4) -> Array[Vector3]:
	var xs := _road_axis_values()
	var zs := _road_axis_values()
	var candidates: Array[Vector3] = []
	for x in xs:
		for z in zs:
			candidates.append(Vector3(x, 0.0, z))
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool: return from.distance_to(a) < from.distance_to(b))
	return candidates.slice(0, mini(count, candidates.size()))


## A short (2-point) route between two positions that only ever moves along
## grid-aligned axes, rather than a straight diagonal that can cut through
## a building block. Not real pathfinding — just enough for reckless
## driving/pursuit/patrol to stay on the roads (docs/ROADMAP.md: "simple
## vehicle/path logic", "do not build realistic police-driving physics").
## Assumes `from` is already reasonably road-aligned on at least one axis,
## which holds as long as everything upstream only ever drives between
## points this function (or get_random_road_point/get_nearby_road_points)
## produced.
func route_between(from: Vector3, to: Vector3) -> PackedVector3Array:
	var axis_values := _road_axis_values()
	var x_aligned := _nearest_axis_distance(from.x, axis_values)
	var z_aligned := _nearest_axis_distance(from.z, axis_values)
	var corner: Vector3
	if x_aligned <= z_aligned:
		# Closer to a vertical road strip: travel along it to the target's
		# row first, then across to the target.
		corner = Vector3(from.x, 0.0, to.z)
	else:
		corner = Vector3(to.x, 0.0, from.z)
	return PackedVector3Array([corner, to])


func _make_navigation_region() -> NavigationRegion3D:
	var region := NavigationRegion3D.new()
	region.name = "Navigation"
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = NAV_AGENT_RADIUS
	nav_mesh.agent_height = NAV_AGENT_HEIGHT
	nav_mesh.agent_max_climb = NAV_AGENT_MAX_CLIMB
	nav_mesh.cell_size = NAV_CELL_SIZE
	nav_mesh.cell_height = NAV_CELL_HEIGHT
	# Bake from collision shapes rather than visual meshes: this scene is
	# built at runtime, and parsing RenderingServer mesh data back from the
	# GPU at runtime (the default) is expensive; our collision shapes are
	# already identical boxes, so this is free precision-wise.
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	region.navigation_mesh = nav_mesh
	return region


func _cell_origin(row: int, col: int) -> Vector2:
	var x := ROAD_WIDTH + row * (BLOCK_SIZE + ROAD_WIDTH)
	var z := ROAD_WIDTH + col * (BLOCK_SIZE + ROAD_WIDTH)
	return Vector2(x, z)


func _footprint_half() -> float:
	return (BLOCK_SIZE - SIDEWALK_MARGIN * 2.0) / 2.0


func _build_ground() -> void:
	var size := CITY_SIZE + GROUND_MARGIN * 2.0
	var center := CITY_SIZE / 2.0

	var ground := StaticBody3D.new()
	ground.name = "Roads"

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

	# Navmesh source geometry — see the class doc for why buildings and
	# ground/sidewalks are all included (Recast naturally excludes vertical
	# building walls and isolates unreachable rooftops on its own).
	_nav_region.add_child(ground)


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

	_build_building(center, height, color, label, type)

	# A point just outside the building's front face (south side).
	var front_point := Vector3(center.x, SIDEWALK_HEIGHT, center.y - _footprint_half() - 1.0)
	match type:
		BuildingType.APARTMENT:
			_home_spawn_point = front_point
		BuildingType.CONVENIENCE_STORE:
			_work_point = front_point
			_spawn_food_stands(center)
		BuildingType.POLICE_STATION:
			_police_station_point = front_point
		BuildingType.GENERIC:
			_generic_points.append(front_point)


func _build_sidewalk(center: Vector2) -> void:
	var body := StaticBody3D.new()
	body.name = "Sidewalk"
	# Sits just under the walkable surface (SIDEWALK_HEIGHT) so its TOP is
	# exactly flush with the road — a color cue, not a step. No collision
	# shape: it's purely visual (buried), the Roads ground plane is what's
	# actually walked on and baked into the navmesh here.
	body.position = Vector3(center.x, SIDEWALK_HEIGHT - SIDEWALK_VISUAL_THICKNESS / 2.0, center.y)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(BLOCK_SIZE, SIDEWALK_VISUAL_THICKNESS, BLOCK_SIZE)
	box.material = _make_material(Color(0.68, 0.68, 0.66))
	mesh_instance.mesh = box
	body.add_child(mesh_instance)

	add_child(body)


func _build_building(
	center: Vector2, height: float, color: Color, label: String, type: BuildingType
) -> void:
	var footprint := BLOCK_SIZE - SIDEWALK_MARGIN * 2.0

	var body := StaticBody3D.new()
	body.name = "Building"
	body.position = Vector3(center.x, SIDEWALK_HEIGHT + height / 2.0, center.y)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(footprint, height, footprint)
	box.material = _make_material(color)
	mesh_instance.mesh = box
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(box.size.x, box.size.y + UNDERGROUND_EXTENSION, box.size.z)
	collision.position = Vector3(0.0, -UNDERGROUND_EXTENSION / 2.0, 0.0)
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

	# Attach gameplay entry points for the buildings that need them. This
	# only wires components together — the behavior lives in their scripts.
	match type:
		BuildingType.CONVENIENCE_STORE:
			_make_workplace(body)
		BuildingType.APARTMENT:
			_make_sleep_spot(body)
		BuildingType.HOSPITAL:
			_make_hospital(body)

	# Script and children must be fully set up before the body joins the
	# tree, so its _ready() (if any) sees a complete node. Buildings are
	# navmesh source geometry (see _build_ground()), so they're parented
	# under the NavigationRegion3D rather than directly under the city.
	_nav_region.add_child(body)


func _make_workplace(body: StaticBody3D) -> void:
	body.collision_layer = 5 # world (1) + interactable (4)
	body.set_script(load(WORKPLACE_TRIGGER_SCRIPT))
	# set() rather than a direct property access: the static type checker
	# only knows `body` as StaticBody3D and can't see the script's `job`
	# export that was just attached above.
	body.set("job", load(JOB_DATA_PATH))

	var interactable := Interactable.new()
	interactable.name = "Interactable"
	interactable.prompt = "Start shift"
	body.add_child(interactable)


func _make_sleep_spot(body: StaticBody3D) -> void:
	body.collision_layer = 5 # world (1) + interactable (4)
	body.set_script(load(SLEEP_TRIGGER_SCRIPT))

	var interactable := Interactable.new()
	interactable.name = "Interactable"
	interactable.prompt = "Sleep"
	body.add_child(interactable)


func _make_hospital(body: StaticBody3D) -> void:
	body.collision_layer = 5 # world (1) + interactable (4)
	body.set_script(load(HOSPITAL_TRIGGER_SCRIPT))

	var interactable := Interactable.new()
	interactable.name = "Interactable"
	# Cost is hardcoded here for the prompt text — keep in sync with
	# HospitalTrigger.TREATMENT_COST.
	interactable.prompt = "Get treated ($15)"
	body.add_child(interactable)


func _spawn_food_stands(store_center: Vector2) -> void:
	var offset := _footprint_half() + 1.0
	_food_points.append(_spawn_food_stand(
		Vector3(store_center.x - offset, SIDEWALK_HEIGHT, store_center.y - 2.0),
		"Snack", 3.0, 15.0, Color(0.9, 0.55, 0.15)
	))
	_food_points.append(_spawn_food_stand(
		Vector3(store_center.x - offset, SIDEWALK_HEIGHT, store_center.y + 2.0),
		"Meal", 8.0, 40.0, Color(0.35, 0.7, 0.3)
	))


func _spawn_food_stand(
	pos: Vector3, food_name: String, cost: float, hunger_restore: float, color: Color
) -> Vector3:
	var body := StaticBody3D.new()
	body.name = "Food_%s" % food_name
	body.position = pos
	body.collision_layer = 5 # world (1) + interactable (4)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	box.material = _make_material(color)
	mesh_instance.position = Vector3(0.0, 0.3, 0.0)
	mesh_instance.mesh = box
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.position = mesh_instance.position
	collision.shape = shape
	body.add_child(collision)

	body.set_script(load(FOOD_ITEM_TRIGGER_SCRIPT))
	# set() rather than direct property access — see _make_workplace().
	body.set("food_name", food_name)
	body.set("cost", cost)
	body.set("hunger_restore", hunger_restore)

	var interactable := Interactable.new()
	interactable.name = "Interactable"
	interactable.prompt = "Buy %s ($%d)" % [food_name, int(cost)]
	body.add_child(interactable)

	add_child(body)
	return pos


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

	var vehicle_scene: PackedScene = load(VEHICLE_SCENE_PATH)
	for i in VEHICLE_COUNT:
		var vehicle: SimpleVehicle = vehicle_scene.instantiate()
		vehicle.waypoints = loop_waypoints
		vehicle.start_index = i
		add_child(vehicle)


## Spawns placeholder pedestrians and assigns each a schedule archetype and
## the location points it needs. Citizens have no individual homes/jobs of
## their own — a few reusable archetypes plus the generic building fronts as
## stand-in residences are enough for a believable, lightweight crowd.
func _spawn_citizens() -> void:
	if _generic_points.is_empty():
		return

	var worker_schedule: CitizenSchedule = load(WORKER_SCHEDULE_PATH)
	var shopper_schedule: CitizenSchedule = load(SHOPPER_SCHEDULE_PATH)
	var citizen_scene: PackedScene = load(CITIZEN_SCENE_PATH)

	for i in CITIZEN_COUNT:
		var citizen: Citizen = citizen_scene.instantiate()
		citizen.home_position = _generic_points[i % _generic_points.size()]
		citizen.food_position = _food_points[i % _food_points.size()]
		if i % 2 == 0:
			citizen.schedule = worker_schedule
			citizen.work_position = _work_point
		else:
			citizen.schedule = shopper_schedule
		add_child(citizen)


## Spawns the one Hero. Just placement — HeroAI decides everything about
## what it does from here (see the architecture note at the top of this
## file, and scripts/ai/hero/hero_ai.gd).
func _spawn_hero() -> void:
	var points := get_wander_points()
	if points.is_empty():
		return
	var hero_scene: PackedScene = load(HERO_SCENE_PATH)
	var hero: HeroAI = hero_scene.instantiate()
	hero.position = points[randi() % points.size()]
	add_child(hero)


## Spawns a small number of police units based near the Police Station.
## Placement only — PoliceAI/PoliceDispatcher own all response/pursuit/
## search behavior (see the architecture note at the top of this file).
func _spawn_police() -> void:
	if _police_station_point == Vector3.ZERO:
		return
	var police_scene: PackedScene = load(POLICE_SCENE_PATH)
	for i in POLICE_COUNT:
		var unit: PoliceAI = police_scene.instantiate()
		unit.home_position = _police_station_point + Vector3(i * 3.0, 0.0, 0.0)
		add_child(unit)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
