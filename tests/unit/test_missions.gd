extends TestCase
## Mission state machine driven only by EventBus events.

func _start_game() -> void:
	GameState.set_flag("ch1_started")
	MissionManager.refresh()

func _visit(location_id: String) -> void:
	EventBus.scene_transition_finished.emit(location_id)

func test_first_mission_unlocks_and_starts() -> void:
	assert_eq(MissionManager.state_of("CH1_M01"), MissionDef.State.LOCKED)
	_start_game()
	assert_eq(MissionManager.state_of("CH1_M01"), MissionDef.State.ACTIVE)
	assert_eq(MissionManager.state_of("CH1_M02"), MissionDef.State.LOCKED, "waits for M01")
	assert_eq(MissionManager.state_of("CH2_M01"), MissionDef.State.LOCKED, "chapter 2 is locked")
	assert_eq(MissionManager.tracked_mission(), "CH1_M01")

func test_objectives_progress_and_completion_rewards() -> void:
	_start_game()
	var completed := watch(EventBus.mission_completed)
	_visit("LOC_UM_CONCOURSE")
	assert_eq(MissionManager.get_progress("CH1_M01", "reach_um_concourse"), 1)
	assert_eq(MissionManager.state_of("CH1_M01"), MissionDef.State.ACTIVE)
	_visit("LOC_EC_METRO_ENTRANCE")
	assert_eq(MissionManager.state_of("CH1_M01"), MissionDef.State.COMPLETE)
	assert_eq(completed.size(), 1)
	assert_true(GameState.get_flag("ch1_exit_reached"), "complete_flags applied")
	assert_true(GameState.has_memory("CH1_F01"), "fragment reward granted")
	assert_eq(MissionManager.state_of("CH1_M02"), MissionDef.State.ACTIVE, "next mission starts")

func test_objective_already_true_when_mission_starts() -> void:
	GameState.enter_location("LOC_UM_ECHO_STATION")
	var m := MissionDef.new()
	m.id = "CH1_M97"
	m.title_key = "UI_RESUME"
	var o := ObjectiveDef.new()
	o.id = "be_here"
	o.text_key = "UI_RESUME"
	o.target = "LOC_UM_ECHO_STATION"
	m.objectives.assign([o])
	DataRegistry.register_runtime(m)
	_start_game()
	assert_eq(MissionManager.state_of("CH1_M97"), MissionDef.State.COMPLETE)
	DataRegistry.reload()

func test_counted_item_objective_and_optional_mission() -> void:
	_start_game()
	assert_eq(MissionManager.state_of("CH1_S01"), MissionDef.State.ACTIVE)
	InventoryManager.add_item("ITEM_LUGGAGE_TAG")
	InventoryManager.add_item("ITEM_LUGGAGE_TAG")
	assert_eq(MissionManager.get_progress("CH1_S01", "find_luggage_tags"), 2)
	assert_eq(MissionManager.state_of("CH1_S01"), MissionDef.State.ACTIVE)
	InventoryManager.add_item("ITEM_LUGGAGE_TAG")
	assert_eq(MissionManager.state_of("CH1_S01"), MissionDef.State.COMPLETE)

func test_chapter_advances_when_all_main_missions_complete() -> void:
	_start_game()
	for chapter_mission in ["CH1_M01", "CH1_M02", "CH1_M03"]:
		var def := DataRegistry.get_mission(chapter_mission)
		for loc in def.locations:
			_visit(loc)
		if chapter_mission == "CH1_M03":
			assert_true(DialogueManager.start("DLG_CH1_M03_CATALOGUE"))
			for i in 12:
				DialogueManager.advance()
	assert_eq(MissionManager.state_of("CH1_M03"), MissionDef.State.COMPLETE)
	assert_true(GameState.has_item("ITEM_ARCHIVE_CARD"), "item reward")
	assert_eq(GameState.chapter, 2, "chapter 2 starts after all chapter 1 main missions")
	assert_eq(MissionManager.state_of("CH2_M01"), MissionDef.State.ACTIVE)

func test_mission_state_survives_save_and_load() -> void:
	_start_game()
	_visit("LOC_UM_CONCOURSE")
	SaveManager.save_game(1)
	GameState.reset()
	SaveManager.load_game(1)
	assert_eq(MissionManager.state_of("CH1_M01"), MissionDef.State.ACTIVE)
	assert_eq(MissionManager.get_progress("CH1_M01", "reach_um_concourse"), 1)
	_visit("LOC_EC_METRO_ENTRANCE")
	assert_eq(MissionManager.state_of("CH1_M01"), MissionDef.State.COMPLETE)

func test_completed_mission_ignores_further_events() -> void:
	_start_game()
	_visit("LOC_UM_CONCOURSE")
	_visit("LOC_EC_METRO_ENTRANCE")
	var completed := watch(EventBus.mission_completed)
	_visit("LOC_EC_METRO_ENTRANCE")
	_visit("LOC_UM_CONCOURSE")
	assert_eq(completed.size(), 0)

func test_unknown_and_unavailable_missions_are_refused() -> void:
	assert_false(MissionManager.start_mission("CH1_M01"), "locked mission cannot start")
	assert_false(MissionManager.start_mission("CH9_M99"))
	assert_false(MissionManager.complete_mission("CH1_M01"))
