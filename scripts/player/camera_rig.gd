class_name CameraRig
extends Node3D
## Third-person orbit camera: yaw on this node, pitch on $Pitch, SpringArm for wall
## collision. Auto-recentres behind the player while moving. Cinematic framing zones
## call push_override()/pop_override() for a smooth blend (default 0.6 s).

@export var follow_offset := Vector3(0, 1.5, 0)
@export var follow_speed: float = 12.0
@export var stick_speed: float = 2.5          # radians/second at full deflection
@export var recentre_delay: float = 1.5
@export var recentre_speed: float = 1.5
@export var min_pitch: float = -1.1
@export var max_pitch: float = 0.4

@onready var _pitch: Node3D = $Pitch
@onready var _arm: SpringArm3D = $Pitch/Arm
@onready var _camera: Camera3D = $Pitch/Arm/Camera3D

var _since_look := 99.0
var _override: Node3D = null
var _blend := 0.0
var _blend_time := 0.6

func _ready() -> void:
	add_to_group("camera_rig")
	_camera.fov = float(SettingsManager.get_value("video", "fov"))
	EventBus.settings_changed.connect(_on_setting_changed)

func _on_setting_changed(section: String, key: String, value: Variant) -> void:
	if section == "video" and key == "fov":
		_camera.fov = float(value)

func snap_to(target: Node3D) -> void:
	global_position = target.global_position + follow_offset
	rotation.y = target.rotation.y

func follow(target: Node3D, delta: float) -> void:
	global_position = global_position.lerp(target.global_position + follow_offset, 1.0 - exp(-follow_speed * delta))
	var sensitivity := float(SettingsManager.get_value("controls", "look_sensitivity"))
	var invert := -1.0 if bool(SettingsManager.get_value("controls", "invert_y")) else 1.0
	var look := InputService.consume_look_delta() * sensitivity
	var stick := InputService.get_look_axis() * stick_speed * sensitivity * delta
	var total := look + stick
	if total.length() > 0.0001:
		_since_look = 0.0
		rotation.y -= total.x
		_pitch.rotation.x = clampf(_pitch.rotation.x - total.y * invert, min_pitch, max_pitch)
	else:
		_since_look += delta
		if _since_look > recentre_delay and InputService.get_move_vector().length() > 0.1 \
				and not bool(SettingsManager.get_value("accessibility", "reduce_motion")):
			rotation.y = lerp_angle(rotation.y, target.rotation.y, recentre_speed * delta)

func push_override(target: Node3D, blend_time: float = 0.6) -> void:
	_override = target
	_blend_time = maxf(blend_time, 0.01)
	_camera.top_level = true

func pop_override(blend_time: float = 0.6) -> void:
	_override = null
	_blend_time = maxf(blend_time, 0.01)

func is_overridden() -> bool:
	return _override != null or _blend > 0.0

func _process(delta: float) -> void:
	if not _camera.top_level:
		return
	_blend = clampf(_blend + (1.0 if _override != null else -1.0) * delta / _blend_time, 0.0, 1.0)
	var rest := _arm.global_transform.translated_local(Vector3(0, 0, _arm.get_hit_length()))
	var t := smoothstep(0.0, 1.0, _blend)
	if _override != null and is_instance_valid(_override):
		_camera.global_transform = rest.interpolate_with(_override.global_transform, t)
	else:
		_camera.global_transform = rest
	if _override == null and _blend <= 0.0:
		_camera.top_level = false
		_camera.transform = Transform3D.IDENTITY
