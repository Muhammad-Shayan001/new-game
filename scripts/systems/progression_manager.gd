extends Node
## Player progression: memories, abilities, discovered locations, character information,
## story choices, optional discoveries. Read-only views plus a few "discover" actions.
## Also resolves the ending from the story states (docs/ENDING_DESIGN.md).

func _ready() -> void:
	EventBus.fragment_collected.connect(_on_fragment)
	for sig in [EventBus.mission_completed, EventBus.ability_unlocked, EventBus.info_revealed,
			EventBus.trace_discovered, EventBus.scene_transition_finished, EventBus.puzzle_solved]:
		sig.connect(func(_a = null): EventBus.progression_changed.emit())

func _on_fragment(_id: String) -> void:
	StoryState.set_value("fragments_total", GameState.memories.size())
	EventBus.progression_changed.emit()

# --- character information ---------------------------------------------------
func reveal_info(info_id: String) -> bool:
	if DataRegistry.get_info(info_id) == null:
		GameLog.error("Progression", "unknown info '%s'" % info_id)
		return false
	if info_id in GameState.info:
		return false
	GameState.info.append(info_id)
	EventBus.info_revealed.emit(info_id)
	EventBus.toast_requested.emit("TOAST_INFO_LEARNED", "info")
	return true

func info_for(character_id: String) -> Array[String]:
	var out: Array[String] = []
	for id in GameState.info:
		var def := DataRegistry.get_info(id)
		if def != null and def.character_id == character_id:
			out.append(id)
	return out

# --- optional discoveries -------------------------------------------------------
func discover_trace(trace_id: String) -> bool:
	if not IdRules.is_valid("trace", trace_id):
		GameLog.error("Progression", "bad trace id '%s'" % trace_id)
		return false
	if trace_id in GameState.discovered_traces:
		return false
	GameState.discovered_traces.append(trace_id)
	EventBus.trace_discovered.emit(trace_id)
	EventBus.toast_requested.emit("TOAST_TRACE_FOUND", "reward")
	return true

func discovered_locations() -> Array[String]:
	return GameState.visited_locations.duplicate()

# --- overview ---------------------------------------------------------------------
func snapshot() -> Dictionary:
	var hidden_total := 0
	var hidden_found := 0
	for l in DataRegistry.all("location"):
		if l.hidden:
			hidden_total += 1
			if l.id in GameState.visited_locations:
				hidden_found += 1
	var main_total := 0
	var main_done := 0
	var opt_total := 0
	var opt_done := 0
	for m in DataRegistry.all("mission"):
		var done := GameState.is_mission_complete(m.id)
		if m.mission_type == MissionDef.Type.MAIN:
			main_total += 1
			main_done += 1 if done else 0
		else:
			opt_total += 1
			opt_done += 1 if done else 0
	var info_by_character := {}
	for c in DataRegistry.ids("character"):
		var facts := info_for(c)
		if not facts.is_empty():
			info_by_character[c] = facts
	var optional_discoveries := opt_done + hidden_found + GameState.discovered_traces.size() \
		+ MemoryManager.collected_count(FragmentDef.Kind.HIDDEN) + MemoryManager.collected_count(FragmentDef.Kind.DEEP)
	return {
		"chapter": GameState.chapter,
		"memories": {
			"core": MemoryManager.collected_count(FragmentDef.Kind.CORE),
			"hidden": MemoryManager.collected_count(FragmentDef.Kind.HIDDEN),
			"deep": MemoryManager.collected_count(FragmentDef.Kind.DEEP),
			"total": GameState.memories.size(), "of": DataRegistry.all("fragment").size(),
		},
		"abilities": GameState.abilities.duplicate(),
		"locations": {"discovered": GameState.visited_locations.size(), "of": DataRegistry.all("location").size(),
			"hidden_found": hidden_found, "hidden_total": hidden_total},
		"missions": {"main_done": main_done, "main_total": main_total, "optional_done": opt_done, "optional_total": opt_total},
		"info": info_by_character,
		"choices": GameState.choices.duplicate(),
		"traces_found": GameState.discovered_traces.size(),
		"optional_discoveries": optional_discoveries,
		"completion_percent": completion_percent(),
	}

## Simple overall completion: memories 50%, missions 30%, locations 20%.
func completion_percent() -> float:
	var fragments := float(GameState.memories.size()) / maxf(DataRegistry.all("fragment").size(), 1)
	var missions_done := 0
	for m in DataRegistry.all("mission"):
		if GameState.is_mission_complete(m.id):
			missions_done += 1
	var missions := float(missions_done) / maxf(DataRegistry.all("mission").size(), 1)
	var locations := float(GameState.visited_locations.size()) / maxf(DataRegistry.all("location").size(), 1)
	return snappedf((fragments * 0.5 + missions * 0.3 + locations * 0.2) * 100.0, 0.1)

## Ending by docs/ENDING_DESIGN.md. Order: Secret, Release, Save, Escape (default).
func resolve_ending() -> String:
	var maya := StoryState.get_number("maya_trust")
	var archivist := StoryState.get_number("archivist_trust")
	var mercy := StoryState.get_number("forgotten_mercy")
	var nodes := StoryState.get_number("destroyed_index_node")
	if StoryState.get_number("deep_fragments") == 3 and archivist >= 2 and maya >= 2 \
			and StoryState.get_number("spared_forgotten") == 1 and nodes == 1 \
			and StoryState.get_number("lullaby_puzzle_solved") == 1:
		return "SECRET"
	if nodes >= 2 and StoryState.get_number("told_maya_truth") == 1:
		return "RELEASE"
	if nodes == 0 and archivist >= 0 and StoryState.get_number("kept_wren_memory") == 1:
		return "SAVE"
	return "ESCAPE"
