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

## Builds a door (Interactable) for every route that is open at the current chapter.
## Hidden routes appear once the player owns Memory Sight. Used by the placeholder scene and
## by every graybox scene so the world graph is always walkable.
## Layout: a ring of `ring_radius`, or a row starting at `row_origin` when `use_row` is true.
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
