extends Node3D
## Replays a recorded path, then holds at the final point (can stand on pressure plates).
var path: Array[Vector3] = []
var _i: int = 0

func _physics_process(_delta: float) -> void:
	if path.is_empty():
		return
	global_position = path[mini(_i, path.size() - 1)]
	_i += 1
