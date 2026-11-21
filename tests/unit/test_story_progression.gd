extends TestCase
## Prompt 09: story states, objectives, mission failure and recovery, progression.

func before_each() -> void:
	super.before_each()
	MissionFixtures.register_all()
	GameState.set_chapter(6)

func after_each() -> void:
	DataRegistry.reload()

func _visit(location_id: String) -> void:
	EventBus.scene_transition_finished.emit(location_id)

# --- story state registry ----------------------------------------------------------
func test_registry_knows_canon_states() -> void:
	for id in ["alex_found_first_memory", "archivist_met", "maya_trust", "metro_unlocked", "architect_revelation_seen",
			"spared_forgotten", "told_maya_truth", "trusted_archivist", "destroyed_index_node", "kept_wren_memory", "deep_fragments"]:
		assert_true(StoryState.is_known(id), id)
	assert_eq(StoryState.resolve("maya_trust_level"), "maya_trust", "alias from the prompt resolves")
	assert_true(StoryState.is_known("dlg_done_dlg_anything"), "engine flags are reserved")
	assert_false(StoryState.is_known("made_up_flag"))

func test_states_are_validated_and_clamped() -> void:
	assert_true(StoryState.set_value("archivist_met", true))
	assert_eq(StoryState.get_value("archivist_met"), true)
	assert_true(StoryState.set_value("destroyed_index_node", 9))
	assert_eq(StoryState.get_value("destroyed_index_node"), 3, "clamped to the maximum")
	assert_false(StoryState.set_value("not_registered", true))
	assert_true(GameLog.error_count > 0)

func test_relationship_states_share_storage_with_dialogue() -> void:
	StoryState.set_value("maya_trust_level", 2)
	assert_eq(GameState.get_relationship("maya_trust"), 2)
	StoryState.add_value("maya_trust", 5)
	assert_eq(StoryState.get_value("maya_trust"), 3)
	var seen := watch(EventBus.story_state_changed)
	StoryState.add_value("maya_trust", -1)
	assert_eq(seen[0][0], "maya_trust")
	assert_eq(seen[0][1], 2)

func test_conditions_can_read_story_states() -> void:
	var c := ConditionSet.new()
	c.states_min = {"maya_trust": 1}
	c.states_max = {"destroyed_index_node": 0}
	assert_false(c.is_met())
	StoryState.set_value("maya_trust", 1)
	assert_true(c.is_met())
	StoryState.set_value("destroyed_index_node", 1)
	assert_false(c.is_met())

func test_unregistered_flag_in_content_is_reported() -> void:
	var m := MissionDef.new()
	m.id = "CH6_S99"
	m.title_key = "UI_PAUSED"
	m.complete_flags.assign(["totally_unregistered_flag"])
	var o := ObjectiveDef.new()
	o.id = "x"
	o.target = "LOC_UM_CONCOURSE"
	o.text_key = "UI_PAUSED"
	m.objectives.assign([o])
	DataRegistry.register_runtime(m)
	var text := "\n".join(DataRegistry.validate_all())
	assert_true(text.contains("totally_unregistered_flag' is not a registered story state"), text)

# --- mission chain: start, update, complete, save, unlock next ----------------------------
func test_mission_chain_start_update_complete_save_unlock() -> void:
	MissionManager.refresh()
	assert_eq(MissionManager.state_of("CH6_S90"), MissionDef.State.ACTIVE)
	assert_eq(MissionManager.state_of("CH6_S91"), MissionDef.State.LOCKED)
	_visit("LOC_UM_CONCOURSE")                                   # update
	assert_eq(ObjectiveManager.progress_of("CH6_S90", "go"), 1)
	assert_eq(MissionManager.state_of("CH6_S90"), MissionDef.State.ACTIVE)
	assert_true(SaveManager.save_game(1))                        # save progress mid-mission
	GameState.reset()
	GameState.set_chapter(6)
	assert_true(SaveManager.load_game(1))
	assert_eq(MissionManager.state_of("CH6_S90"), MissionDef.State.ACTIVE, "state restored")
	assert_eq(ObjectiveManager.progress_of("CH6_S90", "go"), 1, "progress restored")
	GameState.set_flag("t90_done")                               # complete
	assert_eq(MissionManager.state_of("CH6_S90"), MissionDef.State.COMPLETE)
	assert_eq(MissionManager.state_of("CH6_S91"), MissionDef.State.ACTIVE, "next mission unlocked and started")
	GameState.set_flag("t91_done")
	assert_eq(MissionManager.state_of("CH6_S91"), MissionDef.State.COMPLETE)

# --- failure and checkpoint recovery ---------------------------------------------------------
func test_failure_is_soft_and_recoverable_from_checkpoint() -> void:
	MissionManager.refresh()
	GameState.enter_location("LOC_UM_CONCOURSE", "default")
	_visit("LOC_UM_CONCOURSE")                                   # objective a done -> checkpoint
	assert_eq(MissionManager.checkpoint_of("CH6_S92")["location"], "LOC_UM_CONCOURSE")
	var failed := watch(EventBus.mission_failed)
	GameState.set_flag("t92_broken")
	assert_eq(MissionManager.state_of("CH6_S92"), MissionDef.State.FAILED)
	assert_eq(failed.size(), 1)
	assert_eq(failed[0][1], "t92_broken")
	_visit("LOC_EC_MAIN_STREET")
	assert_eq(ObjectiveManager.progress_of("CH6_S92", "b"), 0, "failed missions stop counting")
	assert_true(MissionManager.recover_mission("CH6_S92"))
	assert_eq(MissionManager.state_of("CH6_S92"), MissionDef.State.ACTIVE)
	assert_false(GameState.get_flag("t92_broken"), "fail flag cleared so the retry can work")
	assert_eq(ObjectiveManager.progress_of("CH6_S92", "a"), 1, "objectives before the checkpoint stay done")
	assert_eq(ObjectiveManager.progress_of("CH6_S92", "b"), 0)
	_visit("LOC_EC_MAIN_STREET")
	_visit("LOC_EC_PARK")
	assert_eq(MissionManager.state_of("CH6_S92"), MissionDef.State.COMPLETE)

func test_failed_mission_state_survives_save() -> void:
	MissionManager.refresh()
	GameState.set_flag("t92_broken")
	SaveManager.save_game(2)
	GameState.reset()
	SaveManager.load_game(2)
	assert_eq(MissionManager.state_of("CH6_S92"), MissionDef.State.FAILED)

func test_checkpoint_falls_back_to_the_respawn_point() -> void:
	MissionManager.refresh()
	assert_eq(MissionManager.checkpoint_of("CH6_S92")["location"], "LOC_UM_ECHO_STATION")

# --- conditional and alternative-route objectives -------------------------------------------------
func test_alternative_routes_and_conditional_objectives() -> void:
	MissionManager.refresh()
	var def := DataRegistry.get_mission("CH6_S93")
	assert_eq(ObjectiveManager.visible_objectives(def).size(), 2, "conditional objective hidden at first")
	assert_false(ObjectiveManager.required_done(def))
	GameState.set_flag("t93_hard_route")                         # finishes the "hard" route
	assert_eq(ObjectiveManager.visible_objectives(def).size(), 3, "the condition is met, the objective appears")
	assert_eq(MissionManager.state_of("CH6_S93"), MissionDef.State.ACTIVE, "now the bonus objective is required")
	GameState.set_flag("t93_done")
	assert_eq(MissionManager.state_of("CH6_S93"), MissionDef.State.COMPLETE)

func test_either_route_completes_the_group() -> void:
	MissionManager.refresh()
	InventoryManager.add_item("ITEM_ARCHIVE_CARD")               # the easy route
	assert_eq(MissionManager.state_of("CH6_S93"), MissionDef.State.COMPLETE)

# --- rewards, story states, character info ----------------------------------------------------------
func test_completion_applies_states_rewards_and_info() -> void:
	MissionManager.refresh()
	_visit("LOC_UM_CONCOURSE")
	assert_eq(MissionManager.state_of("CH6_S94"), MissionDef.State.COMPLETE)
	assert_true(StoryState.get_value("t94_rewarded"))
	assert_eq(StoryState.get_value("t94_level"), 3)
	assert_true(GameState.has_item("ITEM_ARCHIVE_CARD"))
	assert_true(GameState.has_clue("CLUE_T94_REWARD"))
	assert_true("INFO_ARV_KEEPS_RECORDS" in GameState.info)

# --- progression -----------------------------------------------------------------------------------------
func test_progression_snapshot_tracks_everything() -> void:
	GameState.reset()
	MemoryManager.collect("CH1_F01")
	MemoryManager.collect("CH2_F05")
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	ProgressionManager.reveal_info("INFO_ARV_KEEPS_RECORDS")
	ProgressionManager.discover_trace("TRC_CH1_CLOCKMAKER_NOTE")
	GameState.enter_location("LOC_UM_ECHO_STATION")
	GameState.choices.append("asked_maya_if_real")
	var snap := ProgressionManager.snapshot()
	assert_eq(snap["memories"]["total"], 2)
	assert_eq(snap["memories"]["core"], 1)
	assert_eq(snap["memories"]["deep"], 1)
	assert_eq(snap["abilities"], ["ABIL_MEMORY_SIGHT"])
	assert_eq(snap["info"]["ARV"], ["INFO_ARV_KEEPS_RECORDS"])
	assert_eq(snap["traces_found"], 1)
	assert_eq(snap["locations"]["discovered"], 1)
	assert_eq(snap["choices"], ["asked_maya_if_real"])
	assert_true(snap["optional_discoveries"] >= 2)
	assert_eq(StoryState.get_value("fragments_total"), 2, "kept in sync")
	assert_eq(StoryState.get_value("deep_fragments"), 1)
	assert_true(snap["completion_percent"] > 0.0)

func test_info_and_traces_are_one_time() -> void:
	assert_true(ProgressionManager.reveal_info("INFO_ARV_KEEPS_RECORDS"))
	assert_false(ProgressionManager.reveal_info("INFO_ARV_KEEPS_RECORDS"))
	assert_false(ProgressionManager.reveal_info("INFO_NOT_REAL"))
	assert_true(ProgressionManager.discover_trace("TRC_TEST_ONE"))
	assert_false(ProgressionManager.discover_trace("TRC_TEST_ONE"))
	assert_false(ProgressionManager.discover_trace("bad id"))

func test_ending_resolution_follows_the_ending_design() -> void:
	assert_eq(ProgressionManager.resolve_ending(), "ESCAPE", "default")
	StoryState.set_value("kept_wren_memory", true)
	assert_eq(ProgressionManager.resolve_ending(), "SAVE")
	StoryState.set_value("destroyed_index_node", 2)
	StoryState.set_value("told_maya_truth", true)
	assert_eq(ProgressionManager.resolve_ending(), "RELEASE")
	StoryState.set_value("destroyed_index_node", 1)
	StoryState.set_value("deep_fragments", 3)
	StoryState.set_value("archivist_trust", 2)
	StoryState.set_value("maya_trust", 2)
	StoryState.set_value("spared_forgotten", true)
	StoryState.set_value("lullaby_puzzle_solved", true)
	assert_eq(ProgressionManager.resolve_ending(), "SECRET")

func test_real_chapter_one_is_playable_to_the_end() -> void:
	GameState.reset()
	GameState.set_flag("ch1_started")
	MissionManager.refresh()
	for id in ["CH1_M01", "CH1_M02", "CH1_M03"]:
		for loc in DataRegistry.get_mission(id).locations:
			_visit(loc)
		if id == "CH1_M03":
			DialogueManager.start("DLG_CH1_M03_CATALOGUE")
			for i in 12:
				DialogueManager.advance()
	assert_true(GameState.has_ability("ABIL_MEMORY_SIGHT"), "granted by CH1_M02")
	assert_true(StoryState.get_value("alex_found_first_memory"))
	assert_true(StoryState.get_value("forgotten_quarter_unlocked"))
	assert_eq(GameState.chapter, 2)
