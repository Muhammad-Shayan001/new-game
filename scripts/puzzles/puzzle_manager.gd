extends Node
## Starts puzzles, checks answers, hands out 3 tiers of hints, saves the solved state.
## Scenes only call submit() / mark_solved() with a puzzle id; they hold no puzzle data.

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

## Forgets in-progress entries (new game, tests). Solved states live in GameState.
func reset_runtime() -> void:
	_runtimes.clear()

func is_solved(puzzle_id: String) -> bool:
	return GameState.puzzles.get(puzzle_id, {}).get("solved", false)

func start(puzzle_id: String) -> bool:
	var def := DataRegistry.get_puzzle(puzzle_id)
	if def == null:
		GameLog.error("Puzzle", "unknown puzzle '%s'" % puzzle_id)
		return false
	if is_solved(puzzle_id):
		return false
	var runtime := _make_runtime(def)
	if runtime != null:
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
	var result: PuzzleRuntime.Result = _runtimes[puzzle_id].submit(value)
	match result:
		PuzzleRuntime.Result.SOLVED:
			mark_solved(puzzle_id)
		PuzzleRuntime.Result.FAILED:
			EventBus.puzzle_attempt_failed.emit(puzzle_id)   # gentle feedback only
	return result

## Used by puzzles with their own scene logic (light, sound, reality, time) and by submit().
func mark_solved(puzzle_id: String) -> bool:
	var def := DataRegistry.get_puzzle(puzzle_id)
	if def == null or is_solved(puzzle_id):
		return false
	var entry: Dictionary = GameState.puzzles.get(puzzle_id, {"hints": 0})
	entry["solved"] = true
	GameState.puzzles[puzzle_id] = entry
	_runtimes.erase(puzzle_id)
	for f in def.set_flags: GameState.set_flag(f, true)
	for c in def.reward_clues: InventoryManager.add_clue(c)
	for i in def.reward_items: InventoryManager.add_item(i)
	for fr in def.reward_fragments: MemoryManager.collect(fr)
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

func reset(puzzle_id: String) -> void:
	if _runtimes.has(puzzle_id):
		_runtimes[puzzle_id].reset()
