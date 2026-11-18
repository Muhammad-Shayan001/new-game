class_name Mechanism
extends StaticBody3D
## Environmental mechanism (door, gate, bridge) driven purely by a story flag. When the flag is
## true the body "opens": collision is disabled and it slides by open_offset. Pair it with an
## Interactable (lever, switch, key door) that sets the flag; no scripting per door is needed.

@export var watch_flag: String = ""
@export var open_offset: Vector3 = Vector3(0, -3.2, 0)
@export var open_time: float = 0.6

var is_open: bool = false
var _closed_pos: Vector3

func _ready() -> void:
	collision_layer = 1
	_closed_pos = position
	EventBus.flag_changed.connect(_on_flag)
	_apply(bool(GameState.get_flag(watch_flag)), true)

func _on_flag(flag: String, value: Variant) -> void:
	if flag == watch_flag:
		_apply(bool(value), false)

func _apply(open: bool, instant: bool) -> void:
	is_open = open
	for c in get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).set_deferred("disabled", open)
	var goal := _closed_pos + (open_offset if open else Vector3.ZERO)
	if instant or bool(Settings.value("reduced_motion")) or not is_inside_tree():
		position = goal
	else:
		create_tween().tween_property(self, "position", goal, open_time)
