class_name NpcActor
extends CharacterBody3D
## Generic talking character. Add a character = CharacterDef + DialogueDef (data) and an
## instance of scenes/characters/npc_base.tscn with character_id set. No new code.

@export var character_id: String = ""
## Overrides CharacterDef.default_dialogue for this instance (optional).
@export var dialogue_id: String = ""

@onready var _interactable: Interactable = $Interactable

func _ready() -> void:
	var def := DataRegistry.get_character(character_id)
	if def == null:
		GameLog.warn("NpcActor", "%s: unknown character '%s'" % [name, character_id])
	var dlg := dialogue_id if dialogue_id != "" else (def.default_dialogue if def != null else "")
	_interactable.start_dialogue = dlg
	_interactable.interact_priority = Interactable.Priority.STORY
	_interactable.prompt_key = "PROMPT_TALK"
	if _interactable.interactable_id == "":
		_interactable.interactable_id = "INT_NPC_" + character_id
	add_to_group("npcs")
