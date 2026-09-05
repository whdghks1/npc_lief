## Third-person player controller.
##
## The physics body itself never rotates — only the visual "Model" child
## turns to face the movement direction. This keeps the camera pivot free to
## orbit independently without fighting the body's rotation, and keeps the
## capsule collider's orientation irrelevant (it's symmetric anyway).
class_name Player
extends CharacterBody3D

const SPEED := 4.0
const JUMP_VELOCITY := 4.5
const MODEL_TURN_SPEED := 10.0
const MOUSE_SENSITIVITY := 0.003
const MIN_PITCH := deg_to_rad(-80.0)
const MAX_PITCH := deg_to_rad(10.0)

@onready var _model: Node3D = %Model
@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _spring_arm: SpringArm3D = %SpringArm3D
@onready var _interactor: Interactor = %Interactor

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_pivot.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		_spring_arm.rotation.x = clampf(
			_spring_arm.rotation.x - event.relative.y * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH
		)
	elif event.is_action_pressed("pause"):
		_toggle_mouse_capture()
	elif event.is_action_pressed("interact"):
		_interactor.try_interact(self)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var raw_dir: Vector3 = _camera_pivot.transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	raw_dir.y = 0.0
	var move_dir := raw_dir.normalized() if raw_dir.length() > 0.0001 else Vector3.ZERO

	velocity.x = move_dir.x * SPEED
	velocity.z = move_dir.z * SPEED

	if move_dir.length() > 0.01:
		var target_angle := atan2(move_dir.x, move_dir.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_angle, MODEL_TURN_SPEED * delta)

	move_and_slide()


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
