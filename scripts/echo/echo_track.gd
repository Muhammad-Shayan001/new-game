class_name EchoTrack
extends Resource
## One character or object that plays back in an echo (shown as a translucent figure).

## CharacterDef id (ALX, ARC...) or a prop name for objects.
@export var actor_id: String = ""
@export var label_key: String = ""
@export var color: Color = Color(0.7, 0.85, 1.0, 0.55)
## Time-ordered samples; the figure moves between them smoothly.
@export var keys: Array[EchoKey] = []
@export var is_prop: bool = false
