extends Node
## Story-state manager. The one place that knows which story variables exist, their
## type, range, and aliases. Writes are validated and clamped; unknown ids are refused.
## Storage stays in GameState (flags or relationships), so saves need no special handling.

## Flags the engine creates itself (per dialogue / interactable). Not story states.
const RESERVED_PREFIXES := ["dlg_done_", "int_done_"]

var _aliases: Dictionary = {}   # alias -> canonical id

func _ready() -> void:
	rebuild_aliases()

func rebuild_aliases() -> void:
	_aliases.clear()
	for def in DataRegistry.all("story_state"):
		for a in def.aliases:
			_aliases[a] = def.id

func is_reserved(id: String) -> bool:
	for p in RESERVED_PREFIXES:
		if id.begins_with(p):
			return true
	return false

func resolve(id: String) -> String:
	return _aliases.get(id, id)

func is_known(id: String) -> bool:
	return is_reserved(id) or DataRegistry.has_def("story_state", resolve(id))

func get_def(id: String) -> StoryStateDef:
	return DataRegistry.get_def("story_state", resolve(id)) as StoryStateDef

## Current value: bool for BOOL states, int for INT states.
func get_value(id: String) -> Variant:
	var def := get_def(id)
	if def == null:
		return GameState.get_flag(id, false)
	var raw: Variant
	if def.relationship_key != "":
		raw = GameState.get_relationship(def.relationship_key)
	else:
		raw = GameState.get_flag(def.id, def.default_value)
	if def.value_type == StoryStateDef.ValueType.BOOL:
		return bool(raw)
	return int(raw)

## Numeric view used by conditions: true = 1, false = 0.
func get_number(id: String) -> int:
	return int(get_value(id))

func set_value(id: String, value: Variant) -> bool:
	var def := get_def(id)
	if def == null:
		GameLog.error("StoryState", "unknown story state '%s'" % id)
		return false
	var clean: int
	if def.value_type == StoryStateDef.ValueType.BOOL:
		clean = 1 if bool(value) else 0
	else:
		clean = clampi(int(value), def.min_value, def.max_value)
	if def.relationship_key != "":
		GameState.relationships[def.relationship_key] = clean
	elif def.value_type == StoryStateDef.ValueType.BOOL:
		GameState.set_flag(def.id, clean == 1)
	else:
		GameState.set_flag(def.id, clean)
	EventBus.story_state_changed.emit(def.id, get_value(def.id))
	return true

func add_value(id: String, delta: int) -> bool:
	return set_value(id, get_number(id) + delta)

func all_ids() -> Array:
	return DataRegistry.ids("story_state")
