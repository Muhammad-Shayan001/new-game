class_name Player
extends CharacterBody3D
## Alex Morgan: third-person controller. Reads InputService only, so keyboard, gamepad
## and touch behave identically. Walk below 60% stick deflection, run above it.

@export var walk_speed: float = 2.2
@export var run_speed: float = 4.5
@export var turn_speed: float = 10.0
@export var kill_height: float = -30.0

const GRAVITY := 9.8
const RUN_THRESHOLD := 0.6

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1

func _physics_process(delta: float) -> void:
	var input := InputService.get_move_vector()
	var rig := get_tree().get_first_node_in_group("camera_rig") as Node3D
	var basis_ref: Basis = rig.global_transform.basis if rig else global_transform.basis
	var dir := basis_ref * Vector3(input.x, 0.0, input.y)
	dir.y = 0.0
	dir = dir.normalized() * input.length()
	var speed := run_speed if input.length() >= RUN_THRESHOLD else walk_speed
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	if dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), turn_speed * delta)
	move_and_slide()
	if global_position.y < kill_height:
		respawn()

## Out-of-bounds recovery: back to the spawn point of the current location.
func respawn() -> void:
	var root := SceneRouter.current_root as LocationRoot
	if root != null:
		place_at(root.get_spawn_transform(GameState.last_spawn_id))
	else:
		place_at(Transform3D.IDENTITY.translated(Vector3(0, 2, 0)))

func place_at(xform: Transform3D) -> void:
	global_transform = Transform3D(Basis.from_euler(Vector3(0, xform.basis.get_euler().y, 0)), xform.origin)
	velocity = Vector3.ZERO
