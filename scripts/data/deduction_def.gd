class_name DeductionDef
extends GameDef
## Linking two clues in the Journal produces a Deduction (door code, dialogue option...).

@export var clue_a: String = ""
@export var clue_b: String = ""
@export var title_key: String = ""
@export var set_flags: Array[String] = []
@export var result_clue: String = ""

func kind() -> String:
	return "deduction"

func validate() -> Array[String]:
	var errors := super.validate()
	for c in [clue_a, clue_b]:
		if not IdRules.is_valid("clue", c):
			errors.append("%s: '%s' is not a clue id" % [id, c])
	return errors
