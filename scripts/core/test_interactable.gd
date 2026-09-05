## Phase 1 verification prop — demonstrates the Interactable component works
## end to end (detection, prompt, triggering). Not part of the game's actual
## content; later phases replace ad-hoc props like this with real world
## objects (jobs, food, doors, etc.).
extends StaticBody3D

@onready var _interactable: Interactable = $Interactable
@onready var _mesh: MeshInstance3D = $MeshInstance3D

var _lit := false


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)


func _on_interacted(_by: Node) -> void:
	_lit = not _lit
	var material := _mesh.get_surface_override_material(0) as StandardMaterial3D
	if material == null:
		material = _mesh.mesh.surface_get_material(0).duplicate()
		_mesh.set_surface_override_material(0, material)
	material.albedo_color = Color(0.9, 0.9, 0.2) if _lit else Color(0.2, 0.8, 0.85)
	print("Interacted with test prop. Lit: ", _lit)
