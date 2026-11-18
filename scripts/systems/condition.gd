class_name Condition
extends RefCounted
## Evaluates data-driven conditions (used by missions, dialogue, interactables, portals, endings).
## A condition is a Dictionary; all keys must pass (AND). An empty or null condition passes.
## Keys: all, any, not, flag, flag_equals, chapter_gte, rel_gte, rel_lte, mission, has_item,
##       has_fragment, deep_fragments_gte, visited, ability, puzzle_solved.

static func check(cond: Variant) -> bool:
	if cond == null:
		return true
	if cond is Dictionary:
		for key: String in cond:
			if not _check_key(key, cond[key]):
				return false
		return true
	if cond is Array:
		for c in cond:
			if not check(c):
				return false
		return true
	Log.warn("Condition", "Unsupported condition type: %s" % str(cond))
	return false

static func _check_key(key: String, v: Variant) -> bool:
	match key:
		"all":
			for c in v:
				if not check(c):
					return false
			return true
		"any":
			for c in v:
				if check(c):
					return true
			return false
		"not":
			return not check(v)
		"flag":
			return bool(GameState.get_flag(str(v)))
		"flag_equals":
			return GameState.get_flag(str(v[0]), null) == v[1]
		"chapter_gte":
			return GameState.chapter >= int(v)
		"rel_gte":
			return GameState.get_relationship(str(v[0])) >= int(v[1])
		"rel_lte":
			return GameState.get_relationship(str(v[0])) <= int(v[1])
		"mission":
			return MissionManager.get_state(str(v[0])) == str(v[1])
		"has_item":
			return InventoryManager.has_item(str(v))
		"has_fragment":
			return MemoryManager.has_fragment(str(v))
		"deep_fragments_gte":
			return MemoryManager.deep_count() >= int(v)
		"visited":
			return GameState.has_visited(str(v))
		"ability":
			return AbilityManager.is_unlocked(str(v))
		"puzzle_solved":
			return PuzzleManager.is_solved(str(v))
	Log.warn("Condition", "Unknown condition key '%s'" % key)
	return false
