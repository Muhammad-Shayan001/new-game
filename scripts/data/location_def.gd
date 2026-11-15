class_name LocationDef
extends GameDef
## A place in the world. One LocationDef <-> one scene (or the placeholder scene).

enum BuildStatus { PLANNED, GRAYBOX, BUILT }

const PLACEHOLDER_SCENE := "res://scenes/world/placeholder_location.tscn"

@export var name_key: String = ""
@export var region_id: String = ""
@export var location_type: String = ""
@export var first_chapter: int = 1
@export var safe_point: bool = false
@export var hidden: bool = false
@export var status: BuildStatus = BuildStatus.PLANNED
@export_file("*.tscn") var scene_path: String = ""
@export var default_spawn: String = "default"
## AudioCueDef id played while the player is here (optional).
@export var ambience_cue: String = ""
@export var connections: Array[LocationConnection] = []

func kind() -> String:
	return "location"

## Scene SceneRouter should load. Unbuilt locations use the placeholder scene.
func resolve_scene_path() -> String:
	if status != BuildStatus.PLANNED and scene_path != "" and ResourceLoader.exists(scene_path):
		return scene_path
	return PLACEHOLDER_SCENE

func validate() -> Array[String]:
	var errors := super.validate()
	if status != BuildStatus.PLANNED and not ResourceLoader.exists(scene_path):
		errors.append("%s: status is built/graybox but scene '%s' does not exist" % [id, scene_path])
	if not IdRules.is_valid("spawn", default_spawn):
		errors.append("%s: bad default_spawn '%s'" % [id, default_spawn])
	for c in connections:
		if not IdRules.is_valid("location", c.to_location):
			errors.append("%s: connection target '%s' is not a location id" % [id, c.to_location])
	return errors
