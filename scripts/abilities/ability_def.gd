class_name AbilityDef
extends GameDef
## A supernatural ability. Limits are timer/cooldown only (no energy grinding).

@export var name_key: String = ""
@export var description_key: String = ""
@export var unlock_chapter: int = 1
## 1..4 -> input actions ability_1..ability_4.
@export_range(1, 4) var input_slot: int = 1
@export var duration: float = 0.0
@export var cooldown: float = 0.0
## AudioCueDef id played on activation (optional).
@export var activation_cue: String = ""
## Short player-facing hint shown by the HUD ("Hold near an anchor").
@export var hint_key: String = ""
## Script extending AbilityBehavior that implements the effect.
@export var behavior: Script

func kind() -> String:
	return "ability"

func validate() -> Array[String]:
	var errors := super.validate()
	if behavior == null:
		errors.append("%s: behavior script is missing" % id)
	if duration < 0.0 or cooldown < 0.0:
		errors.append("%s: duration/cooldown cannot be negative" % id)
	return errors
