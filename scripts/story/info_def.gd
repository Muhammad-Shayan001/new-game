class_name InfoDef
extends GameDef
## A fact the player learns about a character (shown in the Journal character pages).

@export var character_id: String = ""
@export var text_key: String = ""
@export var chapter: int = 1

func kind() -> String:
	return "info"

func validate() -> Array[String]:
	var errors := super.validate()
	if not IdRules.is_valid("character", character_id):
		errors.append("%s: bad character_id '%s'" % [id, character_id])
	return errors
