class_name ConditionSet
extends Resource
## Reusable "is this allowed?" rule used by missions, dialogue, interactables, routes.
## Every list is AND-ed together except flags_any. An empty set is always met.

@export var min_chapter: int = 0
@export var flags_all: Array[String] = []
@export var flags_any: Array[String] = []
@export var flags_none: Array[String] = []
@export var missions_complete: Array[String] = []
@export var items_all: Array[String] = []
@export var clues_all: Array[String] = []
@export var fragments_all: Array[String] = []
@export var abilities_all: Array[String] = []

func is_met() -> bool:
	if min_chapter > 0 and GameState.chapter < min_chapter:
		return false
	for f in flags_all:
		if not GameState.get_flag(f, false):
			return false
	if not flags_any.is_empty():
		var any_set := false
		for f in flags_any:
			if GameState.get_flag(f, false):
				any_set = true
				break
		if not any_set:
			return false
	for f in flags_none:
		if GameState.get_flag(f, false):
			return false
	for m in missions_complete:
		if not GameState.is_mission_complete(m):
			return false
	for i in items_all:
		if not GameState.has_item(i):
			return false
	for c in clues_all:
		if not GameState.has_clue(c):
			return false
	for fr in fragments_all:
		if not GameState.has_memory(fr):
			return false
	for a in abilities_all:
		if not GameState.has_ability(a):
			return false
	return true

## Null-safe helper: a missing ConditionSet means "no restriction".
static func check(conditions: ConditionSet) -> bool:
	return conditions == null or conditions.is_met()

## IDs this set refers to, grouped by IdRules kind (used by DataRegistry.validate_all).
func referenced_ids() -> Dictionary:
	return {
		"mission": missions_complete, "item": items_all, "clue": clues_all,
		"fragment": fragments_all, "ability": abilities_all,
	}
