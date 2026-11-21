extends Node
## Starts puzzles, checks answers, hands out 3 tiers of hints, applies feedback and rewards,
## saves state. Scenes only call submit() / mark_solved() with a puzzle id.

## Built-in puzzle logic per type. To add one: write a PuzzleRuntime subclass and add a case.
## Types without a case use their own scene logic and call mark_solved().
func _make_runtime(def: PuzzleDef) -> PuzzleRuntime:
	match def.puzzle_type:
		PuzzleDef.Type.PATTERN:
			return PatternRuntime.new(def)
		PuzzleDef.Type.ORDERING, PuzzleDef.Type.MEMORY_RECON:
			return OrderingRuntime.new(def)
	return null

var _runtimes: Dictionary = {}   # puzzle_id -> PuzzleRuntime

func _ready() -> void:
	EventBus.scene_transition_started.connect(_on_leaving_location)

## Forgets in-progress entries (new game, tests). Solved states live in GameState.
func reset_runtime() -> void:
	_runtimes.clear()

func is_solved(puzzle_id: String) -> bool:
	return GameState.puzzles.get(puzzle_id, {}).get("solved", false)

## True when the player owns every required ability. Missing ones are reported gently.
func can_attempt(puzzle_id: String, notify: bool = false) -> bool:
	var def := DataRegistry.get_puzzle(puzzle_id)
	if def == null:
		return false
	for a in def.required_abilities:
		if not GameState.has_ability(a):
			if notify:
				EventBus.toast_requested.emit("TOAST_NEED_ABILITY", "info")
			return false
	return true

func start(puzzle_id: String) -> bool:
	var def := DataRegistry.get_puzzle(puzzle_id)
	if def == null:
		GameLog.error("Puzzle", "unknown puzzle '%s'" % puzzle_id)
		return false
	if is_solved(puzzle_id) or not can_attempt(puzzle_id, true):
		return false
	var runtime := _make_runtime(def)
	if runtime != null:
		if def.save_policy == PuzzleDef.SavePolicy.PROGRESS:
			runtime.import_state(GameState.puzzles.get(puzzle_id, {}).get("progress", {}))
		_runtimes[puzzle_id] = runtime
	EventBus.puzzle_started.emit(puzzle_id)
	return true

## Pattern: submit(id, "symbol"). Ordering: submit(id, ["a", "b", "c"]).
func submit(puzzle_id: String, value: Variant) -> PuzzleRuntime.Result:
	if is_solved(puzzle_id):
		return PuzzleRuntime.Result.SOLVED
	if not _runtimes.has(puzzle_id) and not start(puzzle_id):
		return PuzzleRuntime.Result.FAILED
	if not _runtimes.has(puzzle_id):
		GameLog.warn("Puzzle", "'%s' has no built-in logic; use mark_solved()" % puzzle_id)
		return PuzzleRuntime.Result.FAILED
	var def := DataRegistry.get_puzzle(puzzle_id)
	var result: PuzzleRuntime.Result = _runtimes[puzzle_id].submit(value)
	match result:
		PuzzleRuntime.Result.SOLVED:
			mark_solved(puzzle_id)
		PuzzleRuntime.Result.FAILED:
			_feedback(def, false)
			EventBus.puzzle_attempt_failed.emit(puzzle_id)   # gentle feedback only, no penalty
			if def.reset_policy == PuzzleDef.ResetPolicy.ON_FAIL:
				_runtimes[puzzle_id].reset()
			_save_progress(def)
		PuzzleRuntime.Result.PROGRESS:
			_save_progress(def)
	return result

func _save_progress(def: PuzzleDef) -> void:
	if def.save_policy != PuzzleDef.SavePolicy.PROGRESS or not _runtimes.has(def.id):
		return
	var entry: Dictionary = GameState.puzzles.get(def.id, {"hints": 0})
	entry["progress"] = _runtimes[def.id].export_state()
	GameState.puzzles[def.id] = entry

func _feedback(def: PuzzleDef, success: bool) -> void:
	var key := def.success_key if success else def.failure_key
	if key == "":
		key = "TOAST_PUZZLE_SOLVED" if success else "TOAST_PUZZLE_TRY_AGAIN"
	EventBus.toast_requested.emit(key, "reward" if success else "info")
	if def.feedback_cue != "" and success:
		AudioManager.play_cue(def.feedback_cue)

## Used by puzzles with their own scene logic and by submit().
func mark_solved(puzzle_id: String) -> bool:
	var def := DataRegistry.get_puzzle(puzzle_id)
	if def == null or is_solved(puzzle_id):
		return false
	if not can_attempt(puzzle_id, true):
		return false
	var entry: Dictionary = GameState.puzzles.get(puzzle_id, {"hints": 0})
	entry["solved"] = true
	entry.erase("progress")
	GameState.puzzles[puzzle_id] = entry
	_runtimes.erase(puzzle_id)
	for f in def.set_flags: GameState.set_flag(f, true)
	for c in def.reward_clues: InventoryManager.add_clue(c)
	for i in def.reward_items: InventoryManager.add_item(i)
	for fr in def.reward_fragments: MemoryManager.collect(fr)
	_feedback(def, true)
	EventBus.puzzle_solved.emit(puzzle_id)
	return true

## Next hint tier (1..3) as a translation key; stays on tier 3 afterwards.
func request_hint(puzzle_id: String) -> String:
	var def := DataRegistry.get_puzzle(puzzle_id)
	if def == null:
		return ""
	var entry: Dictionary = GameState.puzzles.get(puzzle_id, {"hints": 0, "solved": false})
	var tier := mini(int(entry.get("hints", 0)) + 1, PuzzleDef.HINT_TIERS)
	entry["hints"] = tier
	GameState.puzzles[puzzle_id] = entry
	var key := def.hint_keys[tier - 1]
	EventBus.puzzle_hint_given.emit(puzzle_id, tier, key)
	return key

## Accessibility: with the setting on, a puzzle whose last hint was shown can be skipped.
func skip_puzzle(puzzle_id: String) -> bool:
	if not bool(SettingsManager.get_value("accessibility", "puzzle_skip")):
		return false
	if int(GameState.puzzles.get(puzzle_id, {}).get("hints", 0)) < PuzzleDef.HINT_TIERS:
		return false
	return mark_solved(puzzle_id)

## Clears the entered progress of an unsolved puzzle.
func reset(puzzle_id: String) -> void:
	if _runtimes.has(puzzle_id):
		_runtimes[puzzle_id].reset()
	if GameState.puzzles.has(puzzle_id) and not is_solved(puzzle_id):
		GameState.puzzles[puzzle_id].erase("progress")
	EventBus.puzzle_reset.emit(puzzle_id)

func _on_leaving_location(from_location: String, _to: String) -> void:
	for def in DataRegistry.all("puzzle"):
		if def.reset_policy == PuzzleDef.ResetPolicy.ON_LEAVE and def.location_id == from_location \
				and not is_solved(def.id):
			reset(def.id)
