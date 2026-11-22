class_name Player
extends CharacterBody3D

## Alex Morgan: Advanced Third-Person Kinetic Controller
## High-aesthetic, responsive locomotion designed for mobile touch, gamepad, and KBM.
## Features acceleration smoothing, footstep audio dispatch, kinetic sprint, and respawn safety.

@export_group("Locomotion Tuning")
@export var walk_speed: float = 2.4
@export var run_speed: float = 4.8
@export var sprint_speed: float = 7.2
@export var acceleration: float = 14.0
@export var deceleration: float = 18.0
@export var turn_speed: float = 12.0
@export var kill_height: float = -30.0

@export_group("Kinetic Juice")
@export var footstep_walk_interval: float = 0.55
@export var footstep_run_interval: float = 0.38
@export var footstep_sprint_interval: float = 0.28

const GRAVITY: float = 9.8
const RUN_THRESHOLD: float = 0.60
const SPRINT_THRESHOLD: float = 0.95

var current_target_speed: float = 0.0
var _footstep_timer: float = 0.0
var _is_sprinting: bool = false

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1

func _physics_process(delta: float) -> void:
	var input: Vector2 = InputService.get_move_vector()
	var rig: Node3D = get_tree().get_first_node_in_group("camera_rig") as Node3D
	var basis_ref: Basis = rig.global_transform.basis if rig != null else global_transform.basis
	
	# Compute camera-relative direction vector
	var move_dir: Vector3 = basis_ref * Vector3(input.x, 0.0, input.y)
	move_dir.y = 0.0
	var input_len: float = input.length()
	if input_len > 0.001:
		move_dir = move_dir.normalized()

	# Determine kinetic speed state
	_is_sprinting = (input_len >= SPRINT_THRESHOLD and Input.is_key_pressed(KEY_SHIFT)) or (input_len >= 0.99)
	if input_len < 0.1:
		current_target_speed = 0.0
	elif _is_sprinting and input_len > RUN_THRESHOLD:
		current_target_speed = sprint_speed
	elif input_len >= RUN_THRESHOLD:
		current_target_speed = run_speed
	else:
		current_target_speed = walk_speed

	# Smooth horizontal velocity acceleration / deceleration
	var target_vel: Vector3 = move_dir * current_target_speed
	var accel_rate: float = acceleration if input_len > 0.1 else deceleration
	velocity.x = move_toward(velocity.x, target_vel.x, accel_rate * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, accel_rate * delta)

	# Gravity
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	# Smooth character rotation facing movement direction
	if move_dir.length_squared() > 0.01:
		var target_angle: float = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)

	move_and_slide()

	# Process kinetic footstep foley ticks
	_process_footsteps(delta)

	# Out-of-bounds safety recovery
	if global_position.y < kill_height:
		respawn()

func _process_footsteps(delta: float) -> void:
	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or horiz_speed < 0.5:
		_footstep_timer = 0.0
		return

	_footstep_timer += delta
	var current_interval: float = footstep_walk_interval
	if horiz_speed > run_speed:
		current_interval = footstep_sprint_interval
	elif horiz_speed > walk_speed:
		current_interval = footstep_run_interval

	if _footstep_timer >= current_interval:
		_footstep_timer = 0.0
		# Dispatch audio cue for footstep (handled safely by AudioManager)
		AudioManager.play_cue("sfx_foley_footstep_wet", randf_range(0.95, 1.05))

## Out-of-bounds recovery: returns to spawn point of the active scene
func respawn() -> void:
	var root: LocationRoot = SceneRouter.current_root as LocationRoot
	if root != null:
		place_at(root.get_spawn_transform(GameState.last_spawn_id))
	else:
		place_at(Transform3D.IDENTITY.translated(Vector3(0, 2, 0)))

func place_at(xform: Transform3D) -> void:
	global_transform = Transform3D(Basis.from_euler(Vector3(0, xform.basis.get_euler().y, 0)), xform.origin)
	velocity = Vector3.ZERO
