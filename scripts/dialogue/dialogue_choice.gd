class_name DialogueChoice
extends Resource
## One player reply. Shown only if `conditions` are met (e.g. "Remember" prompts).

@export var text_key: String = ""
## Node to go to after this choice. "" ends the dialogue.
@export var next_id: String = ""
@export var conditions: ConditionSet
@export var set_flags: Array[String] = []
## Relationship changes, e.g. {"maya_trust": 1}. Values are clamped to -3..+3.
@export var relationship_changes: Dictionary = {}
## Optional decision-log entry shown in the Journal "Choices" tab.
@export var log_choice: String = ""
