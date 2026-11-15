class_name AudioCueDef
extends GameDef
## A named sound. Gameplay asks for cue IDs, never for audio files.

enum Category { MUSIC, SFX, AMBIENCE, VOICE }

@export var category: Category = Category.SFX
@export var stream: AudioStream
@export var volume_db: float = 0.0
@export var pitch_min: float = 1.0
@export var pitch_max: float = 1.0
@export var loop: bool = false

func kind() -> String:
	return "audio"
