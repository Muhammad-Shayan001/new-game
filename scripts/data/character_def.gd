class_name CharacterDef
extends GameDef
## A speaking character. IDs are the 3-letter codes from CHARACTER_BIBLE.md (ALX, MAY, ARV...).

@export var name_key: String = ""
@export var accent_color: Color = Color.WHITE
## Optional NPC scene (CharacterBody3D) for placing this character in locations.
@export_file("*.tscn") var scene_path: String = ""
@export var default_dialogue: String = ""

func kind() -> String:
	return "character"
