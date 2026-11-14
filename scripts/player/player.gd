extends CharacterBody3D
## Alex Morgan — third-person controller (touch joystick or WASD).

@export var speed: float = 4.5
@export var joystick_path: NodePath
@export var camera_pivot_path: NodePath

const GRAVITY := 9.8
@onready var _joystick: Control = get_node_or_null(joystick_path)
@onready var _pivot: Node3D = get_node_or_null(camera_pivot_path)

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if _joystick and _joystick.output != Vector2.ZERO:
		input = _joystick.output
	var b: Basis = _pivot.global_transform.basis if _pivot else global_transform.basis
	var dir := b * Vector3(input.x, 0, input.y)
	dir.y = 0
	dir = dir.normalized() * input.length()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	if dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 10.0 * delta)
	move_and_slide()
