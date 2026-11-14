extends Node
## Central game state: story flags, clues, memories, chapter progress.
## Single source of truth for save/load. No online dependency.

signal flag_changed(flag: String, value: Variant)
signal memory_unlocked(memory_id: String)

var chapter: int = 1
var flags: Dictionary = {}
var clues: Array[String] = []
var memories: Array[String] = []
var current_location: String = LocationIDs.UM_ECHO_STATION
var visited_locations: Array[String] = []

func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)

func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)

func add_clue(clue_id: String) -> void:
	if clue_id not in clues:
		clues.append(clue_id)

func unlock_memory(memory_id: String) -> void:
	if memory_id not in memories:
		memories.append(memory_id)
		memory_unlocked.emit(memory_id)

func enter_location(loc_id: String) -> void:
	current_location = loc_id
	if loc_id not in visited_locations:
		visited_locations.append(loc_id)

func to_dict() -> Dictionary:
	return {"chapter": chapter, "flags": flags, "clues": clues, "memories": memories,
		"current_location": current_location, "visited_locations": visited_locations}

func from_dict(d: Dictionary) -> void:
	chapter = d.get("chapter", 1)
	flags = d.get("flags", {})
	clues.assign(d.get("clues", []))
	memories.assign(d.get("memories", []))
	current_location = d.get("current_location", LocationIDs.UM_ECHO_STATION)
	visited_locations.assign(d.get("visited_locations", []))
