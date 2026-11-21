class_name StoryStateDef
extends GameDef
## One registered story-state id (a flag, counter or relationship value).
## Every flag used by missions, dialogue, puzzles and conditions must be registered here,
## so story variables stay consistent (docs/STORY_STATE_REGISTRY.md).

enum ValueType { BOOL, INT }

@export var value_type: ValueType = ValueType.BOOL
@export var min_value: int = 0
@export var max_value: int = 1
@export var default_value: int = 0
## If set, the value is stored in GameState.relationships[relationship_key] instead of a flag.
@export var relationship_key: String = ""
## Other names that resolve to this state (e.g. maya_trust_level -> maya_trust).
@export var aliases: Array[String] = []
@export var chapter: int = 1
@export var ending_relevant: bool = false
@export_multiline var description: String = ""

func kind() -> String:
	return "story_state"

func validate() -> Array[String]:
	var errors := super.validate()
	if value_type == ValueType.INT and min_value > max_value:
		errors.append("%s: min_value is greater than max_value" % id)
	if description == "":
		errors.append("%s: description is required (say who sets it and when)" % id)
	for a in aliases:
		if not IdRules.is_valid("story_state", a):
			errors.append("%s: alias '%s' must be snake_case" % [id, a])
	return errors
