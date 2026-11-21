extends Node
## Mission state machine: LOCKED -> AVAILABLE -> ACTIVE -> COMPLETE (or FAILED -> recovered).
## Objective counting lives in ObjectiveManager; story variables in StoryState.
## Failure is soft: a failed mission restarts from its last checkpoint, nothing is lost.

const S := MissionDef.State

var _refreshing := false
var _refresh_again := false

func _ready() -> void:
	GameState.flag_changed.connect(func(_f, _v): recheck())
	EventBus.mission_objectives_changed.connect(_check_complete)
	EventBus.chapter_changed.connect(func(_c): refresh())
	EventBus.load_finished.connect(func(_slot, ok): if ok: refresh())

func state_of(mission_id: String) -> int:
	return GameState.get_mission_state(mission_id)

func get_progress(mission_id: String, objective_id: String) -> int:
	return ObjectiveManager.progress_of(mission_id, objective_id)

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

## Re-evaluates LOCKED -> AVAILABLE (and auto-start), then failure and completion.
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
	recheck()

## Failure and completion checks for every ACTIVE mission (flags and conditions changed).
func recheck() -> void:
	for id in active_missions():
		if state_of(id) == S.ACTIVE and not _check_fail(id):
			_check_complete(id)

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
	for f in def.start_flags:
		GameState.set_flag(f, true)
	ObjectiveManager.begin(def)
	if not _check_fail(mission_id):
		_check_complete(mission_id)
	return true

func _check_fail(mission_id: String) -> bool:
	if state_of(mission_id) != S.ACTIVE:
		return false
	var def := DataRegistry.get_mission(mission_id)
	for f in def.fail_flags:
		if GameState.get_flag(f, false):
			fail_mission(mission_id, f)
			return true
	return false

func _check_complete(mission_id: String) -> void:
	if state_of(mission_id) != S.ACTIVE:
		return
	var def := DataRegistry.get_mission(mission_id)
	if def != null and ObjectiveManager.required_done(def):
		complete_mission(mission_id)

## Completes an ACTIVE mission: flags, story states, rewards, closing dialogue, chapter check.
func complete_mission(mission_id: String) -> bool:
	var def := DataRegistry.get_mission(mission_id)
	if def == null or state_of(mission_id) != S.ACTIVE:
		return false
	_set_state(mission_id, S.COMPLETE)
	GameState.mission_checkpoints.erase(mission_id)
	for f in def.complete_flags: GameState.set_flag(f, true)
	for s in def.complete_states: StoryState.set_value(str(s), def.complete_states[s])
	for a in def.reward_abilities: AbilityManager.unlock(a)
	for i in def.reward_items: InventoryManager.add_item(i)
	for c in def.reward_clues: InventoryManager.add_clue(c)
	for i in def.reward_info: ProgressionManager.reveal_info(i)
	for fr in def.reward_fragments: MemoryManager.collect(fr)
	EventBus.mission_completed.emit(mission_id)
	EventBus.autosave_requested.emit("mission_complete")
	if def.completion_dialogue != "":
		DialogueManager.start(def.completion_dialogue)
	_check_chapter_end(def.chapter)
	refresh()
	return true

## Soft failure. Progress is kept for recovery; the player is told gently and can retry.
func fail_mission(mission_id: String, reason: String = "") -> bool:
	var def := DataRegistry.get_mission(mission_id)
	if def == null or state_of(mission_id) != S.ACTIVE:
		return false
	_set_state(mission_id, S.FAILED)
	EventBus.mission_failed.emit(mission_id, reason)
	EventBus.toast_requested.emit("TOAST_MISSION_FAILED", "warning")
	if def.fail_dialogue != "":
		DialogueManager.start(def.fail_dialogue)
	return true

## Where "recover" takes the player: last checkpoint, else the mission's respawn point.
func checkpoint_of(mission_id: String) -> Dictionary:
	var saved: Dictionary = GameState.mission_checkpoints.get(mission_id, {})
	if not saved.is_empty():
		return saved
	var def := DataRegistry.get_mission(mission_id)
	if def != null and def.respawn_location != "":
		return {"location": def.respawn_location, "spawn": def.respawn_spawn}
	return {}

## Restarts a FAILED (or stuck ACTIVE) mission from its checkpoint. Fail flags are cleared.
func recover_mission(mission_id: String) -> bool:
	var def := DataRegistry.get_mission(mission_id)
	if def == null or state_of(mission_id) not in [S.FAILED, S.ACTIVE]:
		return false
	var checkpoint := checkpoint_of(mission_id)
	for f in def.fail_flags:
		GameState.set_flag(f, false)
	_set_state(mission_id, S.ACTIVE)
	var kept_checkpoint := checkpoint.duplicate()
	var progress_backup: Dictionary = GameState.mission_progress.get(mission_id, {}).duplicate()
	ObjectiveManager.reset(def)
	# Objectives completed before the checkpoint stay completed.
	var done_before := int(kept_checkpoint.get("objectives_done", 0))
	if done_before > 0:
		var restored := 0
		for o in def.objectives:
			if restored >= done_before:
				break
			if progress_backup.get(o.id, 0) >= o.count:
				GameState.mission_progress[mission_id][o.id] = o.count
				restored += 1
	if not kept_checkpoint.is_empty():
		GameState.mission_checkpoints[mission_id] = kept_checkpoint
		if kept_checkpoint.get("location", "") != "" and SceneRouter.current_location_id != "":
			SceneRouter.change_location(kept_checkpoint["location"], kept_checkpoint.get("spawn", ""))
	EventBus.mission_state_changed.emit(mission_id, S.ACTIVE)
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
