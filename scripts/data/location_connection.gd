class_name LocationConnection
extends Resource
## One walkable/transition route from a LocationDef to another location.

@export var to_location: String = ""
@export_enum("main", "optional", "hidden", "transition") var route_type: String = "main"
## Route is usable once GameState.chapter >= gate_chapter.
@export var gate_chapter: int = 1
## Spawn point id inside the destination scene.
@export var spawn_id: String = "default"
@export var note: String = ""
