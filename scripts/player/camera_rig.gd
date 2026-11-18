class_name CameraRig
extends Node3D
## Third-person camera. Responsibilities: follow (frame-rate independent smoothing), orbit with
## sensitivity settings, collision (SpringArm3D) with fast-in/slow-out obstruction correction,
## environment presets (indoor/outdoor via CameraZone or location type), and cinematic control.
## Put as a child of the player scene; it detaches itself (top_level) so it can smooth independently.

signal cinematic_started
signal cinematic_finished

const PRESETS := {
	"outdoor": {"distance": 4.6, "height": 1.55, "fov": 65.0, "pitch_min": -65.0, "pitch_max": 25.0},
	"indoor": {"distance": 2.7, "height": 1.5, "fov": 72.0, "pitch_min": -55.0, "pitch_max": 15.0},
	"tunnel": {"distance": 3.1, "height": 1.5, "fov": 70.0, "pitch_min": -55.0, "pitch_max": 18.0},
}
const LOCATION_TYPE_PRESET := {"interior": "indoor", "tunnel": "tunnel"}

@export_group("Feel")
@export var follow_speed: float = 10.0          ## position smoothing (1/s)
@export var rotation_smoothing: float = 16.0    ## orbit smoothing (1/s); input is eased, never snapped
@export var preset_blend_speed: float = 4.0
@export var auto_recenter: bool = true
@export var recenter_delay: float = 1.6
@export var recenter_speed: float = 1.1
@export var distance_out_speed: float = 3.0     ## how fast the camera relaxes back after an obstruction
@export var hide_player_below: float = 0.7      ## hide the body when the camera is inside it

var target: Node3D
var arm: SpringArm3D
var camera: Camera3D

var yaw: float = 0.0
var pitch: float = deg_to_rad(-15.0)
var _yaw_goal: float = 0.0
var _pitch_goal: float = deg_to_rad(-15.0)
var _distance: float = 4.6
var _height: float = 1.55
var _fov: float = 65.0
var _pitch_min: float = deg_to_rad(-65.0)
var _pitch_max: float = deg_to_rad(25.0)
var _presets: Array = []                          # stack of [id, preset dict]
var _base_preset: String = "outdoor"
var _look_idle: float = 0.0
var _cinematic: bool = false
var _cine_tween: Tween
var _trauma: float = 0.0
var current_distance: float = 4.6                 ## actual (post-collision) camera distance

func _ready() -> void:
	top_level = true
	arm = get_node_or_null("SpringArm3D") as SpringArm3D
	camera = get_node_or_null("SpringArm3D/Camera3D") as Camera3D
	if arm == null or camera == null:
		Log.error("Camera", "CameraRig needs SpringArm3D/Camera3D children")
		set_process(false)
		return
	arm.collision_mask = 1
	arm.margin = 0.25
	arm.shape = _arm_shape()
	camera.current = true
	_apply_preset_instant(_effective_preset())

func _arm_shape() -> SphereShape3D:
	var s := SphereShape3D.new()
	s.radius = 0.22
	return s

func set_follow_target(t: Node3D) -> void:
	target = t
	if arm and t is CollisionObject3D:
		arm.add_excluded_object((t as CollisionObject3D).get_rid())
	snap_to_target()

func snap_to_target() -> void:
	if target:
		global_position = target.global_position + Vector3(0, _height, 0)
		yaw = _yaw_goal
		pitch = _pitch_goal
		_update_transform()

func get_yaw() -> float:
	return yaw

func get_forward_flat() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))

# ------------------------------------------------------------------ presets
func set_location_type(location_type: String) -> void:
	_base_preset = LOCATION_TYPE_PRESET.get(location_type, "outdoor")

func push_preset(id: String, preset_name: String) -> void:
	for e in _presets:
		if e[0] == id:
			e[1] = preset_name
			return
	_presets.append([id, preset_name])

func pop_preset(id: String) -> void:
	for i in range(_presets.size() - 1, -1, -1):
		if _presets[i][0] == id:
			_presets.remove_at(i)

func _effective_preset() -> Dictionary:
	var name_ := _base_preset if _presets.is_empty() else str(_presets.back()[1])
	return PRESETS.get(name_, PRESETS["outdoor"])

func _apply_preset_instant(p: Dictionary) -> void:
	_distance = p["distance"]
	current_distance = _distance
	_height = p["height"]
	_fov = p["fov"]
	_pitch_min = deg_to_rad(p["pitch_min"])
	_pitch_max = deg_to_rad(p["pitch_max"])
	if camera:
		camera.fov = _fov
	if arm:
		arm.spring_length = _distance

# ------------------------------------------------------------------ frame
func _process(delta: float) -> void:
	if target == null:
		return
	if _cinematic:
		return
	_blend_preset(delta)
	_read_look(delta)
	_follow(delta)
	_update_transform()
	_resolve_obstruction(delta)
	_apply_shake(delta)

func _blend_preset(delta: float) -> void:
	var p := _effective_preset()
	var k := 1.0 - exp(-preset_blend_speed * delta)
	_distance = lerpf(_distance, p["distance"], k)
	_height = lerpf(_height, p["height"], k)
	_fov = lerpf(_fov, p["fov"], k)
	_pitch_min = lerpf(_pitch_min, deg_to_rad(p["pitch_min"]), k)
	_pitch_max = lerpf(_pitch_max, deg_to_rad(p["pitch_max"]), k)
	camera.fov = _fov
	arm.spring_length = _distance

func _read_look(delta: float) -> void:
	var look := InputRouter.consume_look(delta)
	var sens := float(Settings.value("camera_sensitivity"))
	var inv := -1.0 if bool(Settings.value("invert_y")) else 1.0
	if look.length_squared() > 0.0000001:
		_look_idle = 0.0
		_yaw_goal -= look.x * sens
		_pitch_goal = clampf(_pitch_goal - look.y * sens * inv, _pitch_min, _pitch_max)
	else:
		_look_idle += delta
		_recenter(delta)
	_pitch_goal = clampf(_pitch_goal, _pitch_min, _pitch_max)
	var k := 1.0 if bool(Settings.value("reduced_motion")) else 1.0 - exp(-rotation_smoothing * delta)
	yaw = lerp_angle(yaw, _yaw_goal, k)
	pitch = lerpf(pitch, _pitch_goal, k)

## Gently swings the camera behind the player while moving and not looking around.
func _recenter(delta: float) -> void:
	if not auto_recenter or _look_idle < recenter_delay or not target is PlayerController:
		return
	var p := target as PlayerController
	if p.horizontal_speed() < 1.0:
		return
	var v := p.facing_direction()
	var desired := atan2(-v.x, -v.z)
	_yaw_goal = lerp_angle(_yaw_goal, desired, 1.0 - exp(-recenter_speed * delta))

func _follow(delta: float) -> void:
	var goal := target.global_position + Vector3(0, _height, 0)
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))

func _update_transform() -> void:
	global_transform = Transform3D(Basis.from_euler(Vector3(pitch, yaw, 0.0)), global_position)

## SpringArm snaps the camera in front of obstacles instantly; relaxing back outward is eased so the
## view never pops. Also hides the body mesh if the camera ends up inside the character.
func _resolve_obstruction(delta: float) -> void:
	var hit := arm.get_hit_length()
	if hit < current_distance:
		current_distance = hit
	else:
		current_distance = minf(hit, current_distance + distance_out_speed * delta * maxf(1.0, current_distance))
	camera.position = Vector3(0, 0, current_distance - arm.spring_length)
	if target and target.has_node("Visual"):
		target.get_node("Visual").visible = current_distance > hide_player_below

func add_trauma(amount: float) -> void:
	if not bool(Settings.value("reduced_motion")):
		_trauma = clampf(_trauma + amount, 0.0, 1.0)

func _apply_shake(delta: float) -> void:
	if _trauma <= 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		return
	_trauma = maxf(0.0, _trauma - delta * 1.5)
	var s := _trauma * _trauma
	camera.h_offset = randf_range(-1.0, 1.0) * 0.15 * s
	camera.v_offset = randf_range(-1.0, 1.0) * 0.15 * s

# ------------------------------------------------------------------ cinematic control
## Takes over the camera: blends to the given world transform, locks player input.
## The camera is detached from the SpringArm3D for the duration, because the arm rewrites the
## transform of its children every physics frame and would fight the shot.
func begin_cinematic(world_transform: Transform3D, fov: float = 60.0, blend_time: float = 0.8) -> void:
	if _cinematic:
		return
	_cinematic = true
	InputRouter.push_lock("cinematic")
	camera.reparent(self, true)
	if _cine_tween:
		_cine_tween.kill()
	_cine_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var t := 0.0 if bool(Settings.value("reduced_motion")) else blend_time
	_cine_tween.tween_property(camera, "global_transform", world_transform, t)
	_cine_tween.tween_property(camera, "fov", fov, t)
	cinematic_started.emit()

## Moves a cinematic camera to another shot (call between begin and end).
func cinematic_cut(world_transform: Transform3D, fov: float = 60.0) -> void:
	if _cinematic:
		if _cine_tween:
			_cine_tween.kill()
		camera.global_transform = world_transform
		camera.fov = fov

func end_cinematic(blend_time: float = 0.8) -> void:
	if not _cinematic:
		return
	if _cine_tween:
		_cine_tween.kill()
	_update_transform()
	var rest_local := Transform3D(Basis.IDENTITY, Vector3(0, 0, current_distance - arm.spring_length))
	var goal_xform := global_transform * arm.transform * rest_local
	_cine_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var t := 0.0 if bool(Settings.value("reduced_motion")) else blend_time
	_cine_tween.tween_property(camera, "global_transform", goal_xform, t)
	_cine_tween.tween_property(camera, "fov", _fov, t)
	await _cine_tween.finished
	camera.reparent(arm, false)
	camera.transform = rest_local
	_cinematic = false
	InputRouter.pop_lock("cinematic")
	cinematic_finished.emit()

func is_cinematic() -> bool:
	return _cinematic
