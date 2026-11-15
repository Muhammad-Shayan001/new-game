class_name PuzzleDef
extends GameDef
## Data for one puzzle. Built-in logic exists for PATTERN and ORDERING; every other
## type is driven by its own scene which calls PuzzleManager.mark_solved(id).

enum Type { PATTERN, LIGHT_MIRROR, SOUND_ECHO, MEMORY_RECON, REALITY_SWAP, TIME_ECHO, ORDERING }

const HINT_TIERS := 3

@export var puzzle_type: Type = Type.PATTERN
@export var title_key: String = ""
@export var location_id: String = ""
## Exactly 3 translation keys, from gentle nudge to near-answer.
@export var hint_keys: Array[String] = []
## PATTERN: symbols in order. ORDERING: item ids in the right order.
@export var solution: Array[String] = []
@export var set_flags: Array[String] = []
@export var reward_clues: Array[String] = []
@export var reward_items: Array[String] = []
@export var reward_fragments: Array[String] = []

func kind() -> String:
	return "puzzle"

func validate() -> Array[String]:
	var errors := super.validate()
	if hint_keys.size() != HINT_TIERS:
		errors.append("%s: exactly %d hint keys required" % [id, HINT_TIERS])
	if (puzzle_type == Type.PATTERN or puzzle_type == Type.ORDERING) and solution.is_empty():
		errors.append("%s: pattern/ordering puzzles need a solution" % id)
	if location_id != "" and not IdRules.is_valid("location", location_id):
		errors.append("%s: bad location_id '%s'" % [id, location_id])
	return errors
