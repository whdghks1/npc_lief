## Minimal always-available debug overlay.
##
## Phase 0 only needs an FPS/build readout that proves the debug tooling
## pipeline works. Later phases will extend this (or add sibling panels)
## with simulation debug controls per docs/ARCHITECTURE.md and AGENTS.md
## ("Development Tools"): time control, Hero spawning, chaos level, etc.
class_name DebugOverlay
extends CanvasLayer

@onready var _info_label: Label = %InfoLabel


func _ready() -> void:
	# Debug overlay should not pause with the rest of the simulation once a
	# pause system exists.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if not visible:
		return
	var fps := Engine.get_frames_per_second()
	_info_label.text = "NPC LIFE — DEBUG\nFPS: %d\n[F3] toggle debug overlay" % fps


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay_toggle"):
		visible = not visible
		get_viewport().set_input_as_handled()
