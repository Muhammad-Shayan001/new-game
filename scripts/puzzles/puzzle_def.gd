class_name PuzzleDef
extends GameDef
## One puzzle, fully described (see docs/PUZZLE_FRAMEWORK.md). Every puzzle defines:
## id, required abilities, initial state, interaction rules, solution, feedback,
## completion condition, reset behavior, save behavior, accessibility considerations.

enum Type { PATTERN, LIGHT_MIRROR, SOUND_ECHO, MEMORY_RECON, REALITY_SWAP, TIME_ECHO, ORDERING, LOGIC, OBSERVATION }
## What counts as "done".
enum Completion { SOLUTION_MATCH, SCENE_EVENT, DEDUCTION }
## When unsolved progress is cleared.
enum ResetPolicy { MANUAL, ON_FAIL, ON_LEAVE }
## What is written to the save file.
enum SavePolicy { SOLVED_ONLY, PROGRESS }

const HINT_TIERS := 3

@export var puzzle_type: Type = Type.PATTERN
@export var title_key: String = ""
@export var location_id: String = ""
## Abilities the player must own to attempt the puzzle.
@export var required_abilities: Array[String] = []
## Documented starting configuration (keys are free-form: "digits_shown", "zone_state"...).
@export var initial_state: Dictionary = {}
## Exactly 3 translation keys, from gentle nudge to near-answer.
@export var hint_keys: Array[String] = []
## PATTERN: symbols in order. ORDERING / MEMORY_RECON: the correct arrangement.
@export var solution: Array[String] = []
@export var completion: Completion = Completion.SOLUTION_MATCH
@export var reset_policy: ResetPolicy = ResetPolicy.ON_FAIL
@export var save_policy: SavePolicy = SavePolicy.SOLVED_ONLY
## Feedback: toast keys (empty = defaults) and an optional AudioCueDef id.
@export var success_key: String = ""
@export var failure_key: String = ""
@export var feedback_cue: String = ""
@export var set_flags: Array[String] = []
@export var reward_clues: Array[String] = []
@export var reward_items: Array[String] = []
@export var reward_fragments: Array[String] = []
## Co-op: needs this many players at once. In solo play the design note says how a
## Time Echo replaces the missing player.
@export var cooperative: bool = false
@export var min_players: int = 1
@export_multiline var accessibility_notes: String = ""
@export_multiline var design_notes: String = ""

func kind() -> String:
	return "puzzle"

func validate() -> Array[String]:
	var errors := super.validate()
	if hint_keys.size() != HINT_TIERS:
		errors.append("%s: exactly %d hint keys required" % [id, HINT_TIERS])
	if (puzzle_type == Type.PATTERN or puzzle_type == Type.ORDERING or puzzle_type == Type.MEMORY_RECON) and solution.is_empty():
		errors.append("%s: pattern/ordering/reconstruction puzzles need a solution" % id)
	if location_id != "" and not IdRules.is_valid("location", location_id):
		errors.append("%s: bad location_id '%s'" % [id, location_id])
	if accessibility_notes.strip_edges() == "":
		errors.append("%s: accessibility_notes are required" % id)
	if cooperative and min_players < 2:
		errors.append("%s: cooperative puzzles need min_players >= 2" % id)
	for a in required_abilities:
		if not IdRules.is_valid("ability", a):
			errors.append("%s: bad required ability '%s'" % [id, a])
	return errors
