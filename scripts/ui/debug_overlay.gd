## Development debug overlay: FPS readout plus hotkeys for the simulation
## debug tools AGENTS.md asks for (time control, money, hunger, citizen
## state, Hero state). Hotkeys are plain physical-key checks rather than
## InputMap actions since they're dev-only and shouldn't consume slots in
## the player's remappable controls. Only active while the overlay is
## visible, and only consumes the specific keys it handles, so it never
## steals input from gameplay — and none of these affect normal simulation
## behavior unless actually pressed.
class_name DebugOverlay
extends CanvasLayer

const FAST_TIME_SCALE := 40.0
const MONEY_STEP := 20.0
const HUNGER_STEP := 20.0
const MAX_CITIZEN_ROWS := 5

@onready var _info_label: Label = %InfoLabel

var _player: Node3D
var _wallet: Wallet
var _hunger: Hunger
var _show_citizen_details := false
var _nav_debug_enabled := false


func _ready() -> void:
	# Debug overlay should not pause with the rest of the simulation once a
	# pause system exists.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_tree().get_first_node_in_group("player")
	if _player != null:
		_wallet = _player.get_node_or_null("Wallet")
		_hunger = _player.get_node_or_null("Hunger")


func _process(_delta: float) -> void:
	if not visible:
		return
	var fps := Engine.get_frames_per_second()
	var citizens := get_tree().get_nodes_in_group("citizens")
	var text := (
		"NPC LIFE — DEBUG (FPS %d)\n" % fps
		+ "[F3] hide | [1] +1h | [2] time x%.0f\n" % TimeSystem.time_scale
		+ "[3]/[4] $+/-%d | [5]/[6] hunger -/full | [7] next day\n" % int(MONEY_STEP)
		+ "[8] citizen info | [9] nav debug (%s) | citizens: %d\n" % [
			"on" if _nav_debug_enabled else "off", citizens.size()
		]
		+ "[0] force Hero incident | [H] teleport to Hero\n"
		+ _hero_status_text()
	)
	if _show_citizen_details:
		text += "\n" + _citizen_details_text(citizens)
	_info_label.text = text


func _hero_status_text() -> String:
	var hero: HeroAI = get_tree().get_first_node_in_group("hero")
	if hero == null:
		return "Hero: (not spawned)"
	var vehicle_note := ""
	if hero.is_driving and hero.current_target_vehicle != null:
		vehicle_note = " (%s)" % hero.current_target_vehicle.name
	return "Hero: %s | driving: %s%s" % [
		hero.state_name(), "yes" if hero.is_driving else "no", vehicle_note
	]


func _citizen_details_text(citizens: Array[Node]) -> String:
	if _player != null:
		citizens.sort_custom(
			func(a: Node3D, b: Node3D) -> bool:
				return (
					a.global_position.distance_squared_to(_player.global_position)
					< b.global_position.distance_squared_to(_player.global_position)
				)
		)
	var lines: Array[String] = []
	for i in mini(MAX_CITIZEN_ROWS, citizens.size()):
		var citizen: Citizen = citizens[i]
		lines.append("  %s: %s -> %s" % [
			citizen.name, citizen.state_name(), citizen.current_destination()
		])
	return "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay_toggle"):
		visible = not visible
		get_viewport().set_input_as_handled()
		return

	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var handled := true
	match event.physical_keycode:
		KEY_1:
			TimeSystem.advance_time(60)
		KEY_2:
			var is_fast := TimeSystem.time_scale > TimeSystem.BASE_TIME_SCALE
			TimeSystem.time_scale = TimeSystem.BASE_TIME_SCALE if is_fast else FAST_TIME_SCALE
		KEY_3:
			if _wallet != null:
				_wallet.add_money(MONEY_STEP)
		KEY_4:
			if _wallet != null:
				_wallet.spend(MONEY_STEP)
		KEY_5:
			if _hunger != null:
				_hunger.decrease(HUNGER_STEP)
		KEY_6:
			if _hunger != null:
				_hunger.restore_full()
		KEY_7:
			TimeSystem.advance_to_next_day()
		KEY_8:
			_show_citizen_details = not _show_citizen_details
		KEY_9:
			_nav_debug_enabled = not _nav_debug_enabled
			# Best-effort: older/newer engine builds expose this differently
			# (or not at all in a release export template), so this never
			# hard-fails the debug overlay if it's unavailable.
			if NavigationServer3D.has_method("set_debug_enabled"):
				NavigationServer3D.call("set_debug_enabled", _nav_debug_enabled)
		KEY_0:
			var hero: HeroAI = get_tree().get_first_node_in_group("hero")
			if hero != null:
				hero.debug_force_crime()
		KEY_H:
			var hero_to_find: HeroAI = get_tree().get_first_node_in_group("hero")
			if hero_to_find != null and _player != null:
				_player.global_position = hero_to_find.global_position + Vector3(2.0, 0.0, 0.0)
		_:
			handled = false

	if handled:
		get_viewport().set_input_as_handled()
