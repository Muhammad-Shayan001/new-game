class_name PlayerController
extends CharacterBody3D
## Third-person player. Reads ONLY InputRouter (no device code), moves relative to the camera,
## and exposes movement state for the animator. No jumping: the level design (see
## LEVEL_DESIGN_DOCUMENT.md) has no jump traversal, only marked climbs handled by interactions.

signal movement_state_changed(state: String)

@export_group("Speeds (m/s)")
@export var walk_speed: float = 1.9
@export var run_speed: float = 3.9
@export var sprint_speed: float = 6.0
@export_group("Handling")
@export var acceleration: float = 20.0       ## m/s^2 while input is held
@export var deceleration: float = 26.0       ## m/s^2 when input is released
@export var air_control: float = 0.35
@export var turn_speed: float = 11.0         ## visual yaw smoothing (higher = snappier)
@export var run_threshold: float = 0.6       ## stick magnitude above which the player runs
@export var gravity: float = 22.0
@export var camera_path: NodePath = ^"CameraRig"
@export var visual_path: NodePath = ^"Visual"

var state: String = "idle"                   # idle | walk | run | sprint
var sprint_toggled: bool = false
var camera_rig: Node3D
var visual: Node3D
var _was_locked: bool = false

func _ready() -> void:
	add_to_group("player")
	collision_layer = 4          # layer 3: player
	collision_mask = 1           # layer 1: world
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(50.0)
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	camera_rig = get_node_or_null(camera_path)
	visual = get_node_or_null(visual_path)
	if camera_rig and camera_rig.has_method("set_follow_target"):
		camera_rig.set_follow_target(self)

func _physics_process(delta: float) -> void:
	var input := InputRouter.get_move()
	var yaw := _camera_yaw()
	var wish := Basis(Vector3.UP, yaw) * Vector3(input.x, 0.0, input.y)
	var mag := input.length()
	var want_sprint := _sprint_requested() and mag > 0.5
	var target_speed := _target_speed(mag, want_sprint)
	var target_vel := wish.normalized() * target_speed if mag > 0.01 else Vector3.ZERO

	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	var rate := acceleration if target_vel.length() > horiz.length() - 0.01 and mag > 0.01 else deceleration
	if not is_on_floor():
		rate *= air_control
	horiz = horiz.move_toward(target_vel, rate * delta)
	velocity.x = horiz.x
	velocity.z = horiz.z
	velocity.y = -2.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()

	_update_facing(horiz, delta)
	_update_state(horiz.length(), want_sprint)

## Pure function so it can be unit tested: stick magnitude (0..1) -> target speed in m/s.
func _target_speed(magnitude: float, sprinting: bool) -> float:
	if magnitude <= 0.01:
		return 0.0
	if sprinting:
		return sprint_speed
	if magnitude < run_threshold:
		return walk_speed * clampf(magnitude / run_threshold, 0.35, 1.0)
	if magnitude >= 0.95:
		return run_speed
	return lerpf(walk_speed, run_speed, (magnitude - run_threshold) / (0.95 - run_threshold))

func _sprint_requested() -> bool:
	if InputRouter.is_locked():
		return false
	return Input.is_action_pressed("sprint") or sprint_toggled

func _camera_yaw() -> float:
	if camera_rig and camera_rig.has_method("get_yaw"):
		return camera_rig.get_yaw()
	return 0.0

func _update_facing(horiz: Vector3, delta: float) -> void:
	if visual == null or horiz.length() < 0.15:
		return
	var target_yaw := atan2(-horiz.x, -horiz.z)
	var k := 1.0 - exp(-turn_speed * delta)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, k)

func _update_state(speed: float, sprinting: bool) -> void:
	var s := "idle"
	if speed > 0.1:
		if sprinting and speed > run_speed * 0.9:
			s = "sprint"
		elif speed > (walk_speed + run_speed) * 0.5:
			s = "run"
		else:
			s = "walk"
	if s != state:
		state = s
		movement_state_changed.emit(s)

func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()

## Direction the character faces (flat, normalized). Used by the interactor.
func facing_direction() -> Vector3:
	if visual == null:
		return -global_transform.basis.z
	return -visual.global_transform.basis.z

func teleport(xform: Transform3D) -> void:
	global_transform = xform
	velocity = Vector3.ZERO
	if camera_rig and camera_rig.has_method("snap_to_target"):
		camera_rig.snap_to_target()
