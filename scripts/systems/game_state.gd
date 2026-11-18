extends Node
## Core progression state: chapter, story flags, relationships, decisions, location tracking.
## Content collections live in their own managers (inventory, memory, missions, puzzles, abilities).
## Persistence: implements the SaveManager provider interface (save_data/load_data/reset_data).

const SAVE_KEY := "game_state"
const REL_MIN := -3
const REL_MAX := 3

var chapter: int = 1
var flags: Dictionary = {}
var relationships: Dictionary = {}
var decisions: Array = []            # [{id, text_key, chapter}]
var current_location: String = ""
var visited_locations: Array = []
var playtime_seconds: float = 0.0
var track_playtime: bool = false

func _ready() -> void:
	SaveManager.register_provider(SAVE_KEY, self)

func _process(delta: float) -> void:
	if track_playtime:
		playtime_seconds += delta

# --- flags ---
func set_flag(flag: String, value: Variant = true) -> void:
	if flags.get(flag, null) == value:
		return
	flags[flag] = value
	EventBus.flag_changed.emit(flag, value)

func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)

# --- chapter ---
func set_chapter(value: int) -> void:
	if value == chapter:
		return
	chapter = value
	EventBus.chapter_changed.emit(chapter)

# --- relationships ---
func adjust_relationship(key: String, delta: int) -> void:
	var v := clampi(get_relationship(key) + delta, REL_MIN, REL_MAX)
	relationships[key] = v
	EventBus.relationship_changed.emit(key, v)

func get_relationship(key: String) -> int:
	return int(relationships.get(key, 0))

# --- decisions ---
func log_decision(id: String, text_key: String) -> void:
	for d in decisions:
		if d["id"] == id:
			return
	decisions.append({"id": id, "text_key": text_key, "chapter": chapter})

# --- locations ---
func enter_location(loc_id: String) -> void:
	current_location = loc_id
	if loc_id not in visited_locations:
		visited_locations.append(loc_id)

func has_visited(loc_id: String) -> bool:
	return loc_id in visited_locations

# --- SaveManager provider interface ---
func save_data() -> Dictionary:
	return {"chapter": chapter, "flags": flags.duplicate(true), "relationships": relationships.duplicate(),
		"decisions": decisions.duplicate(true), "current_location": current_location,
		"visited_locations": visited_locations.duplicate(), "playtime_seconds": playtime_seconds}

func load_data(d: Dictionary) -> void:
	chapter = int(d.get("chapter", 1))
	flags = d.get("flags", {}).duplicate(true)
	relationships = {}
	for k: String in d.get("relationships", {}):
		relationships[k] = int(d["relationships"][k])
	decisions = d.get("decisions", []).duplicate(true)
	current_location = str(d.get("current_location", ""))
	visited_locations = d.get("visited_locations", []).duplicate()
	playtime_seconds = float(d.get("playtime_seconds", 0.0))

func reset_data() -> void:
	chapter = 1
	flags = {}
	relationships = {}
	decisions = []
	current_location = ""
	visited_locations = []
	playtime_seconds = 0.0
