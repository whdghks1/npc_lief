## Marks a physics body as a workplace: CityBuilder attaches this script to
## a building (plus a child Interactable) and assigns `job`. This component
## only knows how to start a shift for whoever interacts with it — it has no
## idea about city layout, grid position, or how it got placed.
extends StaticBody3D

@export var job: JobDefinition

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)


func _on_interacted(by: Node) -> void:
	var job_component: PlayerJob = by.get_node_or_null("Job")
	var wallet: Wallet = by.get_node_or_null("Wallet")
	if job_component == null or wallet == null:
		return
	if job_component.job == null:
		job_component.job = job
	job_component.start_shift(wallet)
