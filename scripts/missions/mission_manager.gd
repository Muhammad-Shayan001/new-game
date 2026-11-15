extends Node
## Runs the mission state machine: LOCKED -> AVAILABLE -> ACTIVE -> COMPLETE.
## Objectives complete from gameplay events (EventBus + GameState signals); this
## node never needs to know about scenes, NPCs or puzzles.

const S := MissionDef.State

var _refreshing := false
var _refresh_again := false

func _ready() -> void:
	GameState.flag_changed.connect(_on_flag_changed)
	EventBus.scene_transition_finished.connect(func(loc): _progress(ObjectiveDef.Kind.REACH_LOCATION, loc))
	EventBus.interaction_completed.connect(func(id): _progress(ObjectiveDef.Kind.INTERACT, id))
	EventBus.fragment_collected.connect(func(id): _progress(ObjectiveDef.Kind.FRAGMENT, id))
	EventBus.item_added.connect(func(id, n): _progress(ObjectiveDef.Kind.ITEM, id, n))
	EventBus.clue_added.connect(func(id): _progress(ObjectiveDef.Kind.CLUE, id))
	EventBus.puzzle_solved.connect(func(id): _progress(ObjectiveDef.Kind.PUZZLE, id))
	EventBus.dialogue_finished.connect(func(id): _progress(ObjectiveDef.Kind.DIALOGUE, id))
	EventBus.chapter_changed.connect(func(_c): refresh())
	EventBus.load_finished.connect(func(_slot, ok): if ok: refresh())

func state_of(mission_id: String) -> int:
	return GameState.get_mission_state(mission_id)

func get_progress(mission_id: String, objective_id: String) -> int:
	return GameState.mission_progress.get(mission_id, {}).get(objective_id, 0)

func active_missions() -> Array[String]:
	var out: Array[String] = []
	for id in GameState.mission_states:
		if GameState.mission_states[id] == S.ACTIVE:
			out.append(id)
	return out

## The mission shown in the HUD tracker: first active MAIN mission, else any active one.
func tracked_mission() -> String:
	var fallback := ""
	for id in active_missions():
		var def := DataRegistry.get_mission(id)
		if def != null and def.mission_type == MissionDef.Type.MAIN:
			return id
		fallback = id if fallback == "" else fallback
	return fallback

## Re-evaluates LOCKED -> AVAILABLE (and auto-start). Safe to call at any time.
func refresh() -> void:
	if _refreshing:
		_refresh_again = true
		return
	_refreshing = true
	var guard := 0
	while true:
		_refresh_again = false
		for def in DataRegistry.all("mission"):
			if state_of(def.id) == S.LOCKED and _is_unlocked(def):
				_set_state(def.id, S.AVAILABLE)
				if def.auto_start:
					start_mission(def.id)
		guard += 1
		if not _refresh_again or guard > 32:
			break
	_refreshing = false

func _is_unlocked(def: MissionDef) -> bool:
	return GameState.chapter >= def.chapter and ConditionSet.check(def.unlock)

func start_mission(mission_id: String) -> bool:
	var def := DataRegistry.get_mission(mission_id)
	if def == null:
		GameLog.error("Mission", "unknown mission '%s'" % mission_id)
		return false
	if state_of(mission_id) != S.AVAILABLE:
		return false
	_set_state(mission_id, S.ACTIVE)
	GameState.mission_progress[mission_id] = {}
	for f in def.start_flags:
		GameState.set_flag(f, true)
	_count_existing_progress(def)
	_check_complete(mission_id)
	return true

## Objectives that are already true when the mission starts (standing in the
## target location, already owning the item, flag already set...).
func _count_existing_progress(def: MissionDef) -> void:
	for o in def.objectives:
		var met := false
		match o.objective_kind:
			ObjectiveDef.Kind.REACH_LOCATION: met = GameState.current_location == o.target
			ObjectiveDef.Kind.FLAG: met = bool(GameState.get_flag(o.target, false))
			ObjectiveDef.Kind.FRAGMENT: met = GameState.has_memory(o.target)
			ObjectiveDef.Kind.CLUE: met = GameState.has_clue(o.target)
			ObjectiveDef.Kind.ITEM: met = GameState.has_item(o.target)
			ObjectiveDef.Kind.PUZZLE: met = PuzzleManager.is_solved(o.target)
			ObjectiveDef.Kind.DIALOGUE: met = bool(GameState.get_flag("dlg_done_" + o.target.to_lower(), false))
		if met:
			_set_progress(def.id, o, o.count)

func _on_flag_changed(flag: String, value: Variant) -> void:
	if value:
		_progress(ObjectiveDef.Kind.FLAG, flag)
	refresh()

func _progress(kind: ObjectiveDef.Kind, target: String, amount: int = 1) -> void:
	for mission_id in active_missions():
		var def := DataRegistry.get_mission(mission_id)
		if def == null:
			continue
		var changed := false
		for o in def.objectives:
			if o.objective_kind == kind and o.target == target and get_progress(mission_id, o.id) < o.count:
				_set_progress(mission_id, o, get_progress(mission_id, o.id) + amount)
				changed = true
		if changed:
			_check_complete(mission_id)

func _set_progress(mission_id: String, o: ObjectiveDef, value: int) -> void:
	var prog: Dictionary = GameState.mission_progress.get_or_add(mission_id, {})
	prog[o.id] = mini(value, o.count)
	EventBus.mission_objective_progress.emit(mission_id, o.id, prog[o.id], o.count)

func _check_complete(mission_id: String) -> void:
	if state_of(mission_id) != S.ACTIVE:
		return
	var def := DataRegistry.get_mission(mission_id)
	for o in def.objectives:
		if not o.optional and get_progress(mission_id, o.id) < o.count:
			return
	complete_mission(mission_id)

## Completes an ACTIVE mission: flags, rewards, closing dialogue, chapter check, autosave.
func complete_mission(mission_id: String) -> bool:
	var def := DataRegistry.get_mission(mission_id)
	if def == null or state_of(mission_id) != S.ACTIVE:
		return false
	_set_state(mission_id, S.COMPLETE)
	for f in def.complete_flags: GameState.set_flag(f, true)
	for a in def.reward_abilities: AbilityManager.unlock(a)
	for i in def.reward_items: InventoryManager.add_item(i)
	for c in def.reward_clues: InventoryManager.add_clue(c)
	for fr in def.reward_fragments: MemoryManager.collect(fr)
	EventBus.mission_completed.emit(mission_id)
	EventBus.autosave_requested.emit("mission_complete")
	if def.completion_dialogue != "":
		DialogueManager.start(def.completion_dialogue)
	_check_chapter_end(def.chapter)
	refresh()
	return true

## A chapter ends when every MAIN mission of that chapter is complete.
func _check_chapter_end(chapter: int) -> void:
	if GameState.chapter != chapter:
		return
	var has_next := false
	for def in DataRegistry.all("mission"):
		if def.chapter == chapter + 1:
			has_next = true
		if def.chapter == chapter and def.mission_type == MissionDef.Type.MAIN \
				and state_of(def.id) != S.COMPLETE:
			return
	if has_next:
		GameState.set_chapter(chapter + 1)

func _set_state(mission_id: String, state: int) -> void:
	GameState.mission_states[mission_id] = state
	EventBus.mission_state_changed.emit(mission_id, state)
