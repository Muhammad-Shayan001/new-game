class_name ObjectiveDef
extends Resource
## One step of a mission. Completed by gameplay events (see MissionManager).

enum Kind { REACH_LOCATION, FLAG, FRAGMENT, ITEM, CLUE, INTERACT, PUZZLE, DIALOGUE }

## Local id, unique inside its mission (snake_case).
@export var id: String = ""
@export var text_key: String = ""
@export var objective_kind: Kind = Kind.REACH_LOCATION
## What to match: location id, flag name, fragment id, item id, clue id,
## interactable id, puzzle id or dialogue id (depends on objective_kind).
@export var target: String = ""
@export var count: int = 1
## Optional objectives never block mission completion.
@export var optional: bool = false

func target_id_kind() -> String:
	match objective_kind:
		Kind.REACH_LOCATION: return "location"
		Kind.FLAG: return "flag"
		Kind.FRAGMENT: return "fragment"
		Kind.ITEM: return "item"
		Kind.CLUE: return "clue"
		Kind.INTERACT: return "interactable"
		Kind.PUZZLE: return "puzzle"
		Kind.DIALOGUE: return "dialogue"
	return ""
