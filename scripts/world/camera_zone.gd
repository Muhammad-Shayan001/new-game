class_name CameraZone
extends Area3D
## Volume that switches the camera preset while the player is inside (indoor rooms, corridors).
## preset: "indoor" | "tunnel" | "outdoor" (see CameraRig.PRESETS).

@export var preset: String = "indoor"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4          # detects the player layer
	monitoring = true
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _rig(body: Node) -> CameraRig:
	if body is PlayerController:
		return (body as PlayerController).camera_rig as CameraRig
	return null

func _on_enter(body: Node) -> void:
	var rig := _rig(body)
	if rig:
		rig.push_preset(str(get_instance_id()), preset)

func _on_exit(body: Node) -> void:
	var rig := _rig(body)
	if rig:
		rig.pop_preset(str(get_instance_id()))
