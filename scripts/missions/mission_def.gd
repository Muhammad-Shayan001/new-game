class_name MissionDef
extends GameDef
## Data-driven mission (follows docs/MISSION_DESIGN_TEMPLATE.md).
## States: LOCKED -> AVAILABLE -> ACTIVE -> COMPLETE. No hard fail: see respawn fields.

enum Type { MAIN, OPTIONAL }
enum State { LOCKED, AVAILABLE, ACTIVE, COMPLETE, FAILED }

@export var mission_type: Type = Type.MAIN
@export_range(1, 6) var chapter: int = 1
@export var title_key: String = ""
@export var summary_key: String = ""
## Locations (LocationDef ids) this mission takes place in, in story order.
@export var locations: Array[String] = []
## Extra rules for LOCKED -> AVAILABLE (chapter >= `chapter` is always required).
@export var unlock: ConditionSet
## Start automatically when it becomes AVAILABLE.
@export var auto_start: bool = true
@export var start_flags: Array[String] = []
@export var objectives: Array[ObjectiveDef] = []
@export var complete_flags: Array[String] = []
@export var reward_fragments: Array[String] = []
@export var reward_items: Array[String] = []
@export var reward_clues: Array[String] = []
@export var reward_abilities: Array[String] = []
@export var reward_info: Array[String] = []
## Story states set on completion, e.g. {"alex_found_first_memory": true, "maya_trust": 1}.
@export var complete_states: Dictionary = {}
## Soft failure: if any of these flags becomes true while ACTIVE the mission FAILS.
## A failed mission can be recovered from its last checkpoint (never a hard fail).
@export var fail_flags: Array[String] = []
@export var fail_dialogue: String = ""
@export var completion_dialogue: String = ""
## Checkpoint used by the out-of-bounds / reset rule (never a hard fail).
@export var respawn_location: String = ""
@export var respawn_spawn: String = "default"
@export var estimated_minutes: int = 10
## false = generated skeleton (tools/content_tool.gd generate-world). Set true once a
## designer has edited it; generators never overwrite existing files either way.
@export var authored: bool = false

func kind() -> String:
	return "mission"

func validate() -> Array[String]:
	var errors := super.validate()
	if objectives.is_empty():
		errors.append("%s: a mission needs at least one objective" % id)
	var seen := {}
	var required := 0
	for o in objectives:
		if not IdRules.is_valid("node", o.id):
			errors.append("%s: objective id '%s' must be snake_case" % [id, o.id])
		if seen.has(o.id):
			errors.append("%s: duplicate objective id '%s'" % [id, o.id])
		seen[o.id] = true
		if o.count < 1:
			errors.append("%s/%s: count must be >= 1" % [id, o.id])
		var k := o.target_id_kind()
		if k == "" or not IdRules.is_valid(k, o.target):
			errors.append("%s/%s: target '%s' is not a valid %s id" % [id, o.id, o.target, k])
		if not o.optional:
			required += 1
	if required == 0:
		errors.append("%s: at least one non-optional objective is required" % id)
	for l in locations:
		if not IdRules.is_valid("location", l):
			errors.append("%s: '%s' is not a location id" % [id, l])
	for f in start_flags + complete_flags + fail_flags:
		if not IdRules.is_valid("flag", f):
			errors.append("%s: flag '%s' must be snake_case" % [id, f])
	return errors
