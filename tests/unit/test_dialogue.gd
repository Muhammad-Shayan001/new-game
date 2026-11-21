extends TestCase

func test_linear_dialogue_runs_to_the_end() -> void:
	var lines := watch(EventBus.dialogue_line_shown)
	var finished := watch(EventBus.dialogue_finished)
	assert_true(DialogueManager.start("DLG_CH1_M03_CATALOGUE"))
	assert_true(DialogueManager.is_active())
	assert_true(InputService.is_locked(), "gameplay input locked during dialogue")
	assert_eq(lines.size(), 1)
	assert_eq(lines[0][0], "ARV")
	assert_eq(lines[0][1], "DLG_CH1_M03_CATALOGUE_ARV_001")
	for i in 9:
		DialogueManager.advance()
	assert_eq(lines.size(), 10)
	DialogueManager.advance()
	assert_false(DialogueManager.is_active())
	assert_false(InputService.is_locked(), "lock released")
	assert_eq(finished.size(), 1)
	assert_true(GameState.get_flag("archive_card_received"), "node set_flags applied")
	assert_true(GameState.get_flag("archivist_met"))
	assert_true("INFO_ARV_KEEPS_RECORDS" in GameState.info, "dialogue reveals character information")

func test_non_repeatable_dialogue_plays_once() -> void:
	DialogueManager.start("DLG_CH1_M03_CATALOGUE")
	for i in 11:
		DialogueManager.advance()
	assert_false(DialogueManager.start("DLG_CH1_M03_CATALOGUE"))

func test_choices_apply_effects_and_log() -> void:
	var choices := watch(EventBus.dialogue_choices_presented)
	DialogueManager.start("DLG_CH2_M02_CAFE")
	for i in 4:
		DialogueManager.advance()
	assert_eq(choices.size(), 1)
	assert_eq(choices[0][0].size(), 2)
	DialogueManager.advance()   # ignored while choices are shown
	assert_true(DialogueManager.is_active())
	DialogueManager.choose(0)
	assert_eq(GameState.get_relationship("maya_trust"), 1)
	DialogueManager.advance()
	assert_false(DialogueManager.is_active())

func test_second_choice_logs_decision() -> void:
	DialogueManager.start("DLG_CH2_M02_CAFE")
	for i in 4:
		DialogueManager.advance()
	DialogueManager.choose(1)
	assert_true("asked_maya_if_real" in GameState.choices)
	assert_eq(GameState.get_relationship("maya_trust"), 0)

func test_choice_conditions_hide_options() -> void:
	var d := DialogueDef.new()
	d.id = "DLG_TEST_CONDITIONS"
	d.start_id = "a"
	var n := DialogueNode.new()
	n.id = "a"
	n.text_key = "UI_RESUME"
	var open := DialogueChoice.new()
	open.text_key = "UI_QUIT"
	var remember := DialogueChoice.new()
	remember.text_key = "UI_PAUSED"
	remember.conditions = ConditionSet.new()
	remember.conditions.fragments_all.assign(["CH3_F02"])
	n.choices.assign([open, remember])
	d.nodes.assign([n])
	DataRegistry.register_runtime(d)
	var choices := watch(EventBus.dialogue_choices_presented)
	DialogueManager.start("DLG_TEST_CONDITIONS")
	assert_eq(choices[0][0].size(), 1, "'Remember' option hidden without the memory")
	DialogueManager.cancel()
	GameState.unlock_memory("CH3_F02")
	DialogueManager.start("DLG_TEST_CONDITIONS")
	assert_eq(choices[1][0].size(), 2, "shown once the memory is owned")
	DialogueManager.cancel()
	DataRegistry.reload()

func test_unmet_node_is_skipped() -> void:
	var d := DialogueDef.new()
	d.id = "DLG_TEST_SKIP"
	d.start_id = "a"
	var a := DialogueNode.new()
	a.id = "a"
	a.text_key = "UI_RESUME"
	a.next_id = "b"
	a.conditions = ConditionSet.new()
	a.conditions.flags_all.assign(["never_set"])
	var b := DialogueNode.new()
	b.id = "b"
	b.text_key = "UI_QUIT"
	d.nodes.assign([a, b])
	DataRegistry.register_runtime(d)
	var lines := watch(EventBus.dialogue_line_shown)
	DialogueManager.start("DLG_TEST_SKIP")
	assert_eq(lines[0][1], "UI_QUIT")
	DialogueManager.cancel()
	DataRegistry.reload()

func test_only_one_dialogue_at_a_time_and_unknown_ids() -> void:
	assert_true(DialogueManager.start("DLG_CH2_M02_CAFE"))
	assert_false(DialogueManager.start("DLG_CH1_M03_CATALOGUE"))
	DialogueManager.cancel()
	assert_false(DialogueManager.start("DLG_DOES_NOT_EXIST"))
	assert_false(InputService.is_locked())
