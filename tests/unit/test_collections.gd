extends TestCase
## Inventory, clues, fragments, puzzles and abilities.

func test_stackable_and_single_items() -> void:
	assert_true(InventoryManager.add_item("ITEM_ARCHIVE_CARD"))
	assert_false(InventoryManager.add_item("ITEM_ARCHIVE_CARD"), "non-stackable: only one")
	assert_true(InventoryManager.add_item("ITEM_LUGGAGE_TAG", 2))
	assert_true(InventoryManager.add_item("ITEM_LUGGAGE_TAG", 5), "adds up to the stack limit")
	assert_eq(InventoryManager.count_of("ITEM_LUGGAGE_TAG"), 3)
	assert_false(InventoryManager.add_item("ITEM_LUGGAGE_TAG"))
	assert_true(InventoryManager.remove_item("ITEM_LUGGAGE_TAG", 2))
	assert_eq(InventoryManager.count_of("ITEM_LUGGAGE_TAG"), 1)
	assert_false(InventoryManager.remove_item("ITEM_LUGGAGE_TAG", 5))
	assert_false(InventoryManager.add_item("ITEM_UNKNOWN"))

func test_clues_and_deductions() -> void:
	var d := DeductionDef.new()
	d.id = "DED_TEST_PAIR"
	d.clue_a = "CLUE_TEST_A"
	d.clue_b = "CLUE_TEST_B"
	d.set_flags.assign(["door_code_known"])
	DataRegistry.register_runtime(d)
	assert_true(InventoryManager.add_clue("CLUE_TEST_A"))
	assert_false(InventoryManager.add_clue("CLUE_TEST_A"), "no duplicates")
	assert_false(InventoryManager.add_clue("bad id"))
	assert_eq(InventoryManager.link_clues("CLUE_TEST_A", "CLUE_TEST_B"), "", "second clue not owned yet")
	InventoryManager.add_clue("CLUE_TEST_B")
	assert_eq(InventoryManager.link_clues("CLUE_TEST_B", "CLUE_TEST_A"), "DED_TEST_PAIR", "order does not matter")
	assert_true(GameState.get_flag("door_code_known"))
	assert_eq(GameState.deductions.size(), 1)
	InventoryManager.add_clue("CLUE_OTHER")
	var toasts := watch(EventBus.toast_requested)
	assert_eq(InventoryManager.link_clues("CLUE_TEST_A", "CLUE_OTHER"), "")
	assert_eq(toasts[0][0], "TOAST_CLUES_DONT_FIT", "wrong links are gentle")
	DataRegistry.reload()

func test_fragments_and_deep_counter() -> void:
	assert_true(MemoryManager.collect("CH1_F01"))
	assert_false(MemoryManager.collect("CH1_F01"), "only once")
	assert_false(MemoryManager.collect("CH9_F99"))
	assert_eq(MemoryManager.collected_count(FragmentDef.Kind.CORE), 1)
	assert_eq(MemoryManager.total_count(FragmentDef.Kind.DEEP), 3, "3 Deep Fragments in the game")
	MemoryManager.collect("CH2_F05")
	MemoryManager.collect("CH4_F05")
	assert_eq(GameState.get_flag("deep_fragments"), 2)
	assert_eq(MemoryManager.collected_count(FragmentDef.Kind.DEEP), 2)

func test_pattern_puzzle_hints_and_rewards() -> void:
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")   # the clock puzzle requires it
	var failed := watch(EventBus.puzzle_attempt_failed)
	assert_eq(PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "4"), PuzzleRuntime.Result.PROGRESS)
	assert_eq(PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "7"), PuzzleRuntime.Result.FAILED, "wrong symbol resets")
	assert_eq(failed.size(), 1)
	assert_eq(PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "4"), PuzzleRuntime.Result.PROGRESS)
	PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "1")
	assert_false(PuzzleManager.is_solved("PZL_CH1_CLOCK_4_17"))
	assert_eq(PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "7"), PuzzleRuntime.Result.SOLVED)
	assert_true(PuzzleManager.is_solved("PZL_CH1_CLOCK_4_17"))
	assert_true(GameState.get_flag("ch1_clock_solved"))
	assert_true(GameState.has_memory("CH1_F05"), "reward fragment")
	assert_eq(PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "4"), PuzzleRuntime.Result.SOLVED, "stays solved")

func test_hint_tiers_cap_at_three() -> void:
	var k1 := PuzzleManager.request_hint("PZL_CH1_CLOCK_4_17")
	var k2 := PuzzleManager.request_hint("PZL_CH1_CLOCK_4_17")
	var k3 := PuzzleManager.request_hint("PZL_CH1_CLOCK_4_17")
	var k4 := PuzzleManager.request_hint("PZL_CH1_CLOCK_4_17")
	assert_eq(k1, "PZL_CH1_CLOCK_4_17_HINT_1")
	assert_eq(k2, "PZL_CH1_CLOCK_4_17_HINT_2")
	assert_eq(k3, "PZL_CH1_CLOCK_4_17_HINT_3")
	assert_eq(k4, k3)
	assert_eq(GameState.puzzles["PZL_CH1_CLOCK_4_17"]["hints"], 3)

func test_puzzle_mission_objective_completes() -> void:
	GameState.set_flag("ch1_started")
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	MissionManager.refresh()
	assert_eq(MissionManager.state_of("CH1_S02"), MissionDef.State.ACTIVE)
	EventBus.scene_transition_finished.emit("LOC_EC_HID_CLOCK_ROOM")
	PuzzleManager.mark_solved("PZL_CH1_CLOCK_DEDUCTION")
	for s in ["4", "1", "7"]:
		PuzzleManager.submit("PZL_CH1_CLOCK_4_17", s)
	assert_eq(MissionManager.state_of("CH1_S02"), MissionDef.State.COMPLETE, "the optional trace does not block completion")

func test_ordering_puzzle_and_scene_driven_puzzle() -> void:
	var p := PuzzleDef.new()
	p.id = "PZL_TEST_ORDER"
	p.puzzle_type = PuzzleDef.Type.ORDERING
	p.solution.assign(["ITEM_LUGGAGE_TAG", "ITEM_ARCHIVE_CARD"])
	p.hint_keys.assign(["UI_RESUME", "UI_QUIT", "UI_PAUSED"])
	DataRegistry.register_runtime(p)
	assert_eq(PuzzleManager.submit("PZL_TEST_ORDER", ["ITEM_ARCHIVE_CARD", "ITEM_LUGGAGE_TAG"]), PuzzleRuntime.Result.FAILED)
	assert_eq(PuzzleManager.submit("PZL_TEST_ORDER", ["ITEM_LUGGAGE_TAG", "ITEM_ARCHIVE_CARD"]), PuzzleRuntime.Result.SOLVED)
	var q := PuzzleDef.new()
	q.id = "PZL_TEST_LIGHT"
	q.puzzle_type = PuzzleDef.Type.LIGHT_MIRROR
	q.hint_keys.assign(["UI_RESUME", "UI_QUIT", "UI_PAUSED"])
	q.set_flags.assign(["mirrors_aligned"])
	DataRegistry.register_runtime(q)
	assert_true(PuzzleManager.mark_solved("PZL_TEST_LIGHT"), "scene-driven puzzles report success")
	assert_true(GameState.get_flag("mirrors_aligned"))
	DataRegistry.reload()

## Steps the ability timers like real frames (0.1 s each).
func _advance(seconds: float) -> void:
	for i in int(seconds / 0.1) + 1:
		AbilityManager._process(0.1)

func test_memory_sight_timing_and_cooldown() -> void:
	var holder := Node.new()
	holder.add_to_group("memory_sight_reveal")
	holder.set_script(load("res://tests/unit/reveal_probe.gd"))
	add_child(holder)
	assert_false(AbilityManager.activate("ABIL_MEMORY_SIGHT"), "locked until unlocked")
	assert_true(AbilityManager.unlock("ABIL_MEMORY_SIGHT"))
	assert_false(AbilityManager.unlock("ABIL_MEMORY_SIGHT"), "only once")
	assert_true(AbilityManager.activate("ABIL_MEMORY_SIGHT"))
	assert_true(holder.revealed)
	assert_false(AbilityManager.activate("ABIL_MEMORY_SIGHT"), "already active")
	_advance(8.1)
	assert_false(holder.revealed, "effect ends after 8 s")
	assert_false(AbilityManager.is_active("ABIL_MEMORY_SIGHT"))
	assert_true(AbilityManager.cooldown_left("ABIL_MEMORY_SIGHT") > 5.0)
	assert_false(AbilityManager.activate("ABIL_MEMORY_SIGHT"), "cooling down")
	_advance(6.2)
	assert_true(AbilityManager.activate("ABIL_MEMORY_SIGHT"))
	holder.queue_free()

func test_unimplemented_ability_refuses_activation() -> void:
	AbilityManager.unlock("ABIL_REALITY_SHIFT")
	assert_false(AbilityManager.activate("ABIL_REALITY_SHIFT"))
	assert_false(AbilityManager.is_active("ABIL_REALITY_SHIFT"))

func test_abilities_blocked_while_input_locked() -> void:
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	InputService.push_lock("test")
	assert_false(AbilityManager.activate("ABIL_MEMORY_SIGHT"))
	InputService.pop_lock("test")
