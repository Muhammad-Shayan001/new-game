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
@export var info_all: Array[String] = []
@export var traces_all: Array[String] = []
@export var echoes_seen_all: Array[String] = []
@export var locations_visited: Array[String] = []
## Reality Shift: zone id -> required state, e.g. {"SHF_CH3_ANCHOR_BRIDGE": "other_side"}.
@export var shift_states: Dictionary = {}
## Story states (see StoryState): id -> minimum / maximum value. Bool states count as 0 or 1.
@export var states_min: Dictionary = {}
@export var states_max: Dictionary = {}

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
	for i in info_all:
		if i not in GameState.info:
			return false
	for t in traces_all:
		if t not in GameState.discovered_traces:
			return false
	for e in echoes_seen_all:
		if e not in GameState.echoes_seen:
			return false
	for l in locations_visited:
		if l not in GameState.visited_locations:
			return false
	for zone in shift_states:
		if ShiftManager.get_state(zone) != shift_states[zone]:
			return false
	for s in states_min:
		if StoryState.get_number(s) < int(states_min[s]):
			return false
	for s in states_max:
		if StoryState.get_number(s) > int(states_max[s]):
			return false
	return true

## Null-safe helper: a missing ConditionSet means "no restriction".
static func check(conditions: ConditionSet) -> bool:
	return conditions == null or conditions.is_met()

## IDs this set refers to, grouped by IdRules kind (used by DataRegistry.validate_all).
func referenced_ids() -> Dictionary:
	return {
		"mission": missions_complete, "item": items_all, "clue": clues_all,
		"fragment": fragments_all, "ability": abilities_all, "info": info_all,
		"trace": traces_all, "echo": echoes_seen_all, "location": locations_visited,
		"shift_zone": shift_states.keys(), "story_state": states_min.keys() + states_max.keys(),
	}

## Every flag name this set reads (used to check them against the story-state registry).
func referenced_flags() -> Array:
	return flags_all + flags_any + flags_none
