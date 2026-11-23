class_name LocationRoot
extends Node3D
## Root script of every location scene. Owns spawn points and nothing else:
## story logic lives in data (missions, dialogue), not in location scripts.
## Scene ownership rule: a location scene owns its geometry, lights, SpawnPoints,
## Interactables and NPC instances. The player, camera and UI are never part of it.

@export var location_id: String = ""
@export var spawn_id: String = "default"

func setup(id: String, spawn: String) -> void:
	if id != "":
		location_id = id
	if spawn != "":
		spawn_id = spawn

## Transform for a spawn id; falls back to "default", then to the origin.
func get_spawn_transform(wanted: String = "") -> Transform3D:
	var requested := wanted if wanted != "" else spawn_id

	if requested == "" or requested == "default":
		var direct_spawn := find_child("Spawn", true, false)
		if direct_spawn is Marker3D:
			return (direct_spawn as Marker3D).global_transform
		var default_spawn := find_child("default", true, false)
		if default_spawn is Marker3D:
			return (default_spawn as Marker3D).global_transform

	var fallback: Marker3D = null
	for node in find_children("*", "*", true, false):
		if not node is Marker3D:
			continue
		var marker := node as Marker3D
		var id := ""
		if "spawn_id" in marker:
			id = str(marker.get("spawn_id"))
		elif marker.name == "Spawn":
			id = "default"
		else:
			id = str(marker.name)
		if id == requested:
			return marker.global_transform
		if id == "default":
			fallback = marker

	var direct_default := find_child("Spawn", true, false)
	if direct_default is Marker3D:
		fallback = direct_default as Marker3D
	var named_default := find_child("default", true, false)
	if fallback == null and named_default is Marker3D:
		fallback = named_default as Marker3D
	if fallback != null:
		GameLog.warn("LocationRoot", "%s: spawn '%s' missing, using default" % [location_id, wanted])
		return fallback.global_transform
	GameLog.error("LocationRoot", "%s has no SpawnPoint" % location_id)
	return Transform3D.IDENTITY

## Builds a door (Interactable) for every route that is open at the current chapter.
## Hidden routes appear once the player owns Memory Sight. Used by the placeholder scene and
## by graybox scenes so the world graph is always walkable.
func build_route_doors(ring_radius: float = 9.0, use_row: bool = false,
		row_origin: Vector3 = Vector3.ZERO, row_spacing: float = 3.0) -> void:
	var def := DataRegistry.get_location(location_id)
	if def == null:
		return
	var open: Array[LocationConnection] = []
	for c in def.connections:
		var hidden_ok := c.route_type != "hidden" or GameState.has_ability("ABIL_MEMORY_SIGHT")
		if c.gate_chapter <= GameState.chapter and hidden_ok:
			open.append(c)
	for i in open.size():
		var c := open[i]
		var door := Interactable.new()
		door.name = "Door%d" % i
		door.interactable_id = "INT_DOOR_%s_%d" % [def.id.trim_prefix("LOC_"), i]
		door.prompt_key = "PROMPT_ENTER"
		door.interact_priority = Interactable.Priority.STORY
		door.travel_to_location = c.to_location
		door.travel_spawn = c.spawn_id
		if use_row:
			door.position = row_origin + Vector3(i * row_spacing, 0.0, 0.0)
		else:
			var angle := TAU * float(i) / maxf(open.size(), 1.0)
			door.position = Vector3(cos(angle), 0.0, sin(angle)) * ring_radius + Vector3(0, 1.0, 0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.4, 2.0, 2.4)
		shape.shape = box
		door.add_child(shape)
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.6, 2.0, 0.3)
		mesh.mesh = bm
		door.add_child(mesh)
		var target := DataRegistry.get_location(c.to_location)
		var text := Label3D.new()
		text.text = "%s\n[%s]" % [Localization.t(target.name_key) if target != null else c.to_location, c.route_type]
		text.position = Vector3(0, 1.5, 0)
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		text.font_size = 36
		door.add_child(text)
		add_child(door)
