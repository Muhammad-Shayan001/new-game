class_name ShiftZoneDef
extends GameDef
## A Reality Shift zone: a marked area that can switch between named states.
## Objects (ShiftableObject) declare which states they appear in.

@export var title_key: String = ""
@export var location_id: String = ""
@export var states: Array[String] = ["echo_city", "other_side"]
@export var default_state: String = "echo_city"
## Persistent zones keep their state in the save file.
@export var persistent: bool = true
## Only one zone can be away from its default state at a time ("1 area at a time").
@export var exclusive: bool = true
@export var transition_time: float = 0.5

func kind() -> String:
	return "shift_zone"

func next_state(current: String) -> String:
	var i := states.find(current)
	return states[(i + 1) % states.size()]

func validate() -> Array[String]:
	var errors := super.validate()
	if states.size() < 2:
		errors.append("%s: a shift zone needs at least 2 states" % id)
	if default_state not in states:
		errors.append("%s: default_state '%s' is not one of the states" % [id, default_state])
	for s in states:
		if not IdRules.is_valid("node", s):
			errors.append("%s: state '%s' must be snake_case" % [id, s])
	if location_id != "" and not IdRules.is_valid("location", location_id):
		errors.append("%s: bad location_id" % id)
	return errors
