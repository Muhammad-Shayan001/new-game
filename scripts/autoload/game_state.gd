extends Node
## Single source of truth for everything that is saved: story flags, clues,
## memories, missions, inventory, abilities, puzzles, relationships.
## Other systems own the RULES; this node only owns the DATA and the save schema.
## Schema: docs/DATA_SCHEMA.md. Allowed flag value types: bool, int, String.

signal flag_changed(flag: String, value: Variant)
signal memory_unlocked(memory_id: String)

const RELATIONSHIP_MIN := -3
const RELATIONSHIP_MAX := 3

var chapter: int = 1
var flags: Dictionary = {}
var clues: Array[String] = []
var memories: Array[String] = []
var current_location: String = LocationIDs.UM_ECHO_STATION
var visited_locations: Array[String] = []
var last_spawn_id: String = "default"
var mission_states: Dictionary = {}     # mission_id -> MissionDef.State (int)
var mission_progress: Dictionary = {}   # mission_id -> {objective_id: int}
var inventory: Dictionary = {}          # item_id -> count
var abilities: Array[String] = []       # unlocked ability ids
var puzzles: Dictionary = {}            # puzzle_id -> {"solved": bool, "hints": int}
var relationships: Dictionary = {}      # e.g. {"maya_trust": 1}
var choices: Array[String] = []         # decision log (Journal "Choices" tab)
var deductions: Array[String] = []
var shift_states: Dictionary = {}        # zone_id -> current state (persistent zones only)
var discovered_traces: Array[String] = []
var info: Array[String] = []             # revealed character-information ids
var echoes_seen: Array[String] = []
var mission_checkpoints: Dictionary = {} # mission_id -> {"location", "spawn", "objectives_done"}
var playtime_seconds: float = 0.0

## While > 0 autosave is refused (pursuits, cutscenes). Not saved.
var autosave_blocks: int = 0

func _process(delta: float) -> void:
	playtime_seconds += delta

func reset() -> void:
	from_dict({})

# --- flags -----------------------------------------------------------------
func set_flag(flag: String, value: Variant = true) -> void:
	if flags.get(flag) == value:
		return
	if OS.is_debug_build() and not StoryState.is_known(flag):
		GameLog.warn("GameState", "flag '%s' is not registered as a story state" % flag)
	flags[flag] = value
	flag_changed.emit(flag, value)

func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)

# --- chapter ---------------------------------------------------------------
func set_chapter(value: int) -> void:
	if value == chapter:
		return
	chapter = value
	EventBus.chapter_changed.emit(chapter)

# --- collections -----------------------------------------------------------
func add_clue(clue_id: String) -> bool:
	if clue_id in clues:
		return false
	clues.append(clue_id)
	return true

func has_clue(clue_id: String) -> bool:
	return clue_id in clues

func unlock_memory(memory_id: String) -> bool:
	if memory_id in memories:
		return false
	memories.append(memory_id)
	memory_unlocked.emit(memory_id)
	return true

func has_memory(memory_id: String) -> bool:
	return memory_id in memories

func has_item(item_id: String) -> bool:
	return inventory.get(item_id, 0) > 0

func has_ability(ability_id: String) -> bool:
	return ability_id in abilities

# --- missions --------------------------------------------------------------
func get_mission_state(mission_id: String) -> int:
	return mission_states.get(mission_id, MissionDef.State.LOCKED)

func is_mission_complete(mission_id: String) -> bool:
	return get_mission_state(mission_id) == MissionDef.State.COMPLETE

# --- relationships ---------------------------------------------------------
func get_relationship(key: String) -> int:
	return relationships.get(key, 0)

func add_relationship(key: String, delta: int) -> void:
	relationships[key] = clampi(get_relationship(key) + delta, RELATIONSHIP_MIN, RELATIONSHIP_MAX)

# --- locations -------------------------------------------------------------
func enter_location(loc_id: String, spawn_id: String = "default") -> void:
	current_location = loc_id
	last_spawn_id = spawn_id
	if loc_id not in visited_locations:
		visited_locations.append(loc_id)

# --- save schema -----------------------------------------------------------
func to_dict() -> Dictionary:
	return {
		"chapter": chapter, "flags": flags.duplicate(true), "clues": clues.duplicate(),
		"memories": memories.duplicate(), "current_location": current_location,
		"visited_locations": visited_locations.duplicate(), "last_spawn_id": last_spawn_id,
		"mission_states": mission_states.duplicate(true),
		"mission_progress": mission_progress.duplicate(true),
		"inventory": inventory.duplicate(), "abilities": abilities.duplicate(),
		"puzzles": puzzles.duplicate(true), "relationships": relationships.duplicate(),
		"choices": choices.duplicate(), "deductions": deductions.duplicate(),
		"shift_states": shift_states.duplicate(), "discovered_traces": discovered_traces.duplicate(),
		"info": info.duplicate(), "echoes_seen": echoes_seen.duplicate(),
		"mission_checkpoints": mission_checkpoints.duplicate(true),
		"playtime_seconds": playtime_seconds,
	}

## Loads a state dictionary. Missing keys fall back to defaults, so old saves
## stay loadable. JSON turns every number into a float, so numbers are normalised.
func from_dict(d: Dictionary) -> void:
	chapter = int(d.get("chapter", 1))
	flags = _normalize_numbers(d.get("flags", {}))
	clues.assign(d.get("clues", []))
	memories.assign(d.get("memories", []))
	current_location = str(d.get("current_location", LocationIDs.UM_ECHO_STATION))
	visited_locations.assign(d.get("visited_locations", []))
	last_spawn_id = str(d.get("last_spawn_id", "default"))
	mission_states = _normalize_numbers(d.get("mission_states", {}))
	mission_progress = _normalize_numbers(d.get("mission_progress", {}))
	inventory = _normalize_numbers(d.get("inventory", {}))
	abilities.assign(d.get("abilities", []))
	puzzles = _normalize_numbers(d.get("puzzles", {}))
	relationships = _normalize_numbers(d.get("relationships", {}))
	choices.assign(d.get("choices", []))
	deductions.assign(d.get("deductions", []))
	shift_states = d.get("shift_states", {}).duplicate()
	discovered_traces.assign(d.get("discovered_traces", []))
	info.assign(d.get("info", []))
	echoes_seen.assign(d.get("echoes_seen", []))
	mission_checkpoints = _normalize_numbers(d.get("mission_checkpoints", {}))
	playtime_seconds = float(d.get("playtime_seconds", 0.0))

## Recursively turns whole-number floats back into ints.
func _normalize_numbers(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for k in value:
			out[k] = _normalize_numbers(value[k])
		return out
	if value is Array:
		var arr := []
		for v in value:
			arr.append(_normalize_numbers(v))
		return arr
	if value is float and is_equal_approx(value, roundf(value)):
		return int(roundf(value))
	return value
