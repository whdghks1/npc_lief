## Development debug overlay: FPS readout plus hotkeys for the simulation
## debug tools AGENTS.md asks for (time control, money, hunger). Hotkeys are
## plain physical-key checks rather than InputMap actions since they're
## dev-only and shouldn't consume slots in the player's remappable controls.
## Only active while the overlay is visible, and only consumes the specific
## keys it handles, so it never steals input from gameplay.
class_name DebugOverlay
extends CanvasLayer

const FAST_TIME_SCALE := 40.0
const NORMAL_TIME_SCALE := 2.0
const MONEY_STEP := 20.0
const HUNGER_STEP := 20.0

@onready var _info_label: Label = %InfoLabel

var _wallet: Wallet
var _hunger: Hunger


func _ready() -> void:
	# Debug overlay should not pause with the rest of the simulation once a
	# pause system exists.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		_wallet = player.get_node_or_null("Wallet")
		_hunger = player.get_node_or_null("Hunger")


func _process(_delta: float) -> void:
	if not visible:
		return
	var fps := Engine.get_frames_per_second()
	_info_label.text = (
		"NPC LIFE — DEBUG (FPS %d)\n" % fps
		+ "[F3] hide | [1] +1h | [2] time x%.0f\n" % TimeSystem.time_scale
		+ "[3]/[4] $+/-%d | [5]/[6] hunger -/full | [7] next day" % int(MONEY_STEP)
	)


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
			var is_fast := TimeSystem.time_scale > NORMAL_TIME_SCALE
			TimeSystem.time_scale = NORMAL_TIME_SCALE if is_fast else FAST_TIME_SCALE
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
		_:
			handled = false

	if handled:
		get_viewport().set_input_as_handled()
