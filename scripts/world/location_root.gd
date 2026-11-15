class_name LocationRoot
extends Node3D
## Root script of every location scene. Owns spawn points and nothing else:
## story logic lives in data (missions, dialogue), not in location scripts.
## Scene ownership rule: a location scene owns its geometry, lights, SpawnPoints,
## Interactables and NPC instances. The player, camera and UI are never part of it.

var location_id: String = ""
var spawn_id: String = "default"

func setup(id: String, spawn: String) -> void:
	location_id = id
	spawn_id = spawn

## Transform for a spawn id; falls back to "default", then to the origin.
func get_spawn_transform(wanted: String = "") -> Transform3D:
	var fallback: SpawnPoint = null
	for node in find_children("*", "SpawnPoint", true, false):
		var sp := node as SpawnPoint
		if sp.spawn_id == (wanted if wanted != "" else spawn_id):
			return sp.global_transform
		if sp.spawn_id == "default":
			fallback = sp
	if fallback != null:
		GameLog.warn("LocationRoot", "%s: spawn '%s' missing, using default" % [location_id, wanted])
		return fallback.global_transform
	GameLog.error("LocationRoot", "%s has no SpawnPoint" % location_id)
	return Transform3D.IDENTITY
