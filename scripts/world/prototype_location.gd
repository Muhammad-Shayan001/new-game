class_name PrototypeLocation
extends LocationRoot
## Root of the graybox puzzle scenes (built by tools/scene_builder.gd). Adds route doors in a
## row so the player can always leave toward the neighbouring locations.

@export var door_row_origin: Vector3 = Vector3(-4, 1, 8)
@export var door_row_spacing: float = 3.0

func setup(id: String, spawn: String) -> void:
	super.setup(id, spawn)
	build_route_doors(0.0, true, door_row_origin, door_row_spacing)
