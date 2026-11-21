class_name EchoGhost
extends Node3D
## A translucent figure used by Time Echo: replays of past events and the ghost copies
## the player records. Detectable ghosts carry an Area3D (layer 4) that pressure plates see.

var _path: Array = []        # [{"t": float, "pos": Vector3, "yaw": float}] in world space
var _time := 0.0
var _playing := false
var label_text := ""

func setup(color: Color, detectable: bool, label: String = "") -> void:
	label_text = label
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	mesh.mesh = capsule
	mesh.position.y = 0.85
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = material
	add_child(mesh)
	if label != "":
		var text := Label3D.new()
		text.text = label
		text.position.y = 2.1
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		text.font_size = 32
		add_child(text)
	if detectable:
		add_to_group("echo_ghost")
		var area := Area3D.new()
		area.collision_layer = 8
		area.collision_mask = 0
		area.add_to_group("echo_ghost_area")
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.45
		shape.shape = sphere
		shape.position.y = 0.4
		area.add_child(shape)
		add_child(area)

## Starts walking a recorded path. After the last sample the ghost stays where it ended.
func play_path(path: Array) -> void:
	_path = path
	_time = 0.0
	_playing = not path.is_empty()
	if _playing:
		global_position = path[0]["pos"]

func advance(delta: float) -> void:
	if not _playing:
		return
	_time += delta
	var last: Dictionary = _path[_path.size() - 1]
	if _time >= last["t"]:
		global_position = last["pos"]
		rotation.y = last["yaw"]
		_playing = false
		return
	for i in range(_path.size() - 1):
		var a: Dictionary = _path[i]
		var b: Dictionary = _path[i + 1]
		if _time >= a["t"] and _time <= b["t"]:
			var f := inverse_lerp(a["t"], b["t"], _time)
			global_position = (a["pos"] as Vector3).lerp(b["pos"], f)
			rotation.y = lerp_angle(a["yaw"], b["yaw"], f)
			return

func is_playing() -> bool:
	return _playing

func _physics_process(delta: float) -> void:
	advance(delta)
