class_name ItemDef
extends GameDef
## An inventory item (keys, documents, tokens). Clues are plain CLUE_ ids, not items.

@export var name_key: String = ""
@export var description_key: String = ""
@export var stackable: bool = false
@export var max_stack: int = 1
@export var icon: Texture2D

func kind() -> String:
	return "item"

func validate() -> Array[String]:
	var errors := super.validate()
	if max_stack < 1:
		errors.append("%s: max_stack must be >= 1" % id)
	if not stackable and max_stack != 1:
		errors.append("%s: non-stackable items must have max_stack 1" % id)
	return errors
