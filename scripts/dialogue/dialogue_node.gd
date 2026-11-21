class_name DialogueNode
extends Resource
## One line of dialogue, optionally followed by up to 3 choices.

## Local id, unique inside its dialogue (snake_case).
@export var id: String = ""
## CharacterDef id (ALX, MAY, ARV...). Empty = narration / system voice.
@export var speaker_id: String = ""
@export var text_key: String = ""
## Following node when there are no (visible) choices. "" ends the dialogue.
@export var next_id: String = ""
## If not met the node is skipped and the dialogue continues at next_id.
@export var conditions: ConditionSet
@export var choices: Array[DialogueChoice] = []
@export var set_flags: Array[String] = []
@export var relationship_changes: Dictionary = {}
## AudioCueDef id of the spoken line (optional).
@export var voice_cue: String = ""
## Character information revealed (InfoDef ids).
@export var reveals_info: Array[String] = []
## Story states set (id -> value), for non-boolean values such as {"destroyed_index_node": 1}.
@export var set_states: Dictionary = {}
