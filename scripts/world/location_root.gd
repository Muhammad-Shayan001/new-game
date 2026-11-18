class_name LocationRoot
extends Node3D
## Base class for every location scene (hand-built or generated). SceneManager sets location_id,
## adds the node, then calls setup_location(def). Spawn points are Marker3D nodes in group "spawn"
## named "default" or "from_<LOC_ID>".

var location_id: String = ""
var def: Dictionary = {}

func setup_location(location_def: Dictionary) -> void:
	def = location_def

func get_spawn_transform(spawn_id: String) -> Transform3D:
	var fallback := Transform3D.IDENTITY
	for n in get_children():
		if n is Marker3D and n.is_in_group("spawn"):
			if spawn_id != "" and n.name == spawn_id:
				return n.global_transform
			if n.name == "default":
				fallback = n.global_transform
	return fallback
