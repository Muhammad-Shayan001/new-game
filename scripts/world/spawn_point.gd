class_name SpawnPoint
extends Marker3D
## Where the player appears. Every location scene needs one with spawn_id "default".

@export var spawn_id: String = "default"

func _ready() -> void:
	add_to_group("spawn_points")
