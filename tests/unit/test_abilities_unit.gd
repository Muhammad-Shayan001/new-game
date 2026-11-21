extends TestCase
## Prompt 08: Memory Vision, Echo Detection, Reality Shift, Time Echo and the puzzle
## framework, tested piece by piece (the scenes are played through in test_prototypes).

func before_each() -> void:
	super.before_each()
	SettingsManager.path = "user://test_settings.cfg"
	SettingsManager.reset_to_defaults()
	SettingsManager.set_value("accessibility", "reduce_motion", true)   # instant visual changes

func after_each() -> void:
	SettingsManager.reset_to_defaults()
	DataRegistry.reload()
	# Free test nodes immediately so groups are clean for the next test.
	for group in ["player", "camera_rig", "memory_traces", "memory_sight_reveal", "shiftables"]:
		for n in get_tree().get_nodes_in_group(group):
			if is_instance_valid(n):
				n.free()

## Steps ability timers like real frames.
func _advance(seconds: float) -> void:
	for i in int(seconds / 0.1) + 1:
		AbilityManager._process(0.1)

# --- Memory Vision -------------------------------------------------------------------------
func _hidden_writing() -> Revealable:
	var r := Revealable.new()
	var use := Interactable.new()
	use.name = "Examine"
	use.give_clue = "CLUE_TEST_WRITING"
	use.interactable_id = "INT_TEST_WRITING"
	r.add_child(use)
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	r.add_child(mesh)
	r.interactable_path = NodePath("Examine")
	add_child(r)
	return r

func test_hidden_object_visibility_and_interaction() -> void:
	var r := _hidden_writing()
	var use := r.get_node("Examine") as Interactable
	assert_false(r.visible, "hidden without Memory Sight")
	assert_false(use.can_interact(), "cannot examine what you cannot see")
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	assert_true(AbilityManager.activate("ABIL_MEMORY_SIGHT"))
	assert_true(r.visible and r.revealed)
	assert_true(use.can_interact())
	use.interact()
	assert_true(GameState.has_clue("CLUE_TEST_WRITING"), "clue discovery")
	_advance(8.5)
	assert_false(r.visible, "hides again when the ability ends")
	assert_false(use.can_interact())
	r.queue_free()

func test_found_writing_can_stay_visible() -> void:
	var r := _hidden_writing()
	r.stay_visible_once_found = true
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	AbilityManager.activate("ABIL_MEMORY_SIGHT")
	_advance(8.5)
	assert_true(r.visible, "discovered writing remains")
	assert_false((r.get_node("Examine") as Interactable).can_interact(), "but is only usable while revealed")
	r.queue_free()

func test_memory_trace_records_an_optional_discovery() -> void:
	var trace := MemoryTrace.new()
	trace.trace_id = "TRC_TEST_NOTE"
	var use := Interactable.new()
	use.name = "Examine"
	use.give_clue = "CLUE_TEST_NOTE"
	trace.add_child(use)
	trace.interactable_path = NodePath("Examine")
	add_child(trace)
	var found := watch(EventBus.trace_discovered)
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	AbilityManager.activate("ABIL_MEMORY_SIGHT")
	use.interact()
	assert_eq(found.size(), 1)
	assert_true(trace.is_discovered())
	assert_true("TRC_TEST_NOTE" in GameState.discovered_traces)
	trace.queue_free()

func test_ability_feedback_hud_and_rules() -> void:
	var hud := AbilityHud.new()
	add_child(hud)
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	assert_true(hud.slot_text("ABIL_MEMORY_SIGHT").contains("Ready"))
	assert_eq(hud.tint_alpha(), 0.0)
	AbilityManager.activate("ABIL_MEMORY_SIGHT")
	assert_true(hud.tint_alpha() > 0.05, "screen tint while active")
	assert_true(hud.slot_text("ABIL_MEMORY_SIGHT").contains("Active"))
	_advance(8.5)
	assert_eq(hud.tint_alpha(), 0.0)
	assert_true(hud.slot_text("ABIL_MEMORY_SIGHT").contains("Recharging"), "cooldown rule shown")
	hud.queue_free()

func test_accessibility_scales_ability_duration() -> void:
	SettingsManager.set_value("accessibility", "ability_duration_scale", 2.0)
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	AbilityManager.activate("ABIL_MEMORY_SIGHT")
	assert_true(AbilityManager.active_left("ABIL_MEMORY_SIGHT") > 15.0)

# --- Echo Detection --------------------------------------------------------------------------------
func _stage() -> Node3D:
	var player := Node3D.new()
	player.add_to_group("player")
	add_child(player)
	player.global_position = Vector3.ZERO
	var rig := Node3D.new()
	rig.add_to_group("camera_rig")
	add_child(rig)
	return player

func _trace(id: String, pos: Vector3) -> MemoryTrace:
	var t := MemoryTrace.new()
	t.trace_id = id
	add_child(t)
	t.global_position = pos
	return t

func test_pulse_points_to_the_nearest_undiscovered_trace() -> void:
	_stage()
	var near := _trace("TRC_TEST_NEAR", Vector3(10, 0, 0))
	var far := _trace("TRC_TEST_FAR", Vector3(30, 0, 0))
	var detected := watch(EventBus.echo_detected)
	var result := EchoDetection.pulse()
	assert_true(result["found"])
	assert_eq(result["trace_id"], "TRC_TEST_NEAR")
	assert_eq(result["band"], "close")
	assert_true(absf(result["bearing"] - PI / 2.0) < 0.05, "a trace on the right has a bearing of +90 degrees")
	assert_eq(detected.size(), 1)
	assert_false(EchoDetection.pulse()["found"], "cooldown")
	ProgressionManager.discover_trace("TRC_TEST_NEAR")
	EchoDetection._cooldown = 0.0
	var second := EchoDetection.pulse()
	assert_eq(second["trace_id"], "TRC_TEST_FAR", "discovered traces are skipped")
	assert_eq(second["band"], "far")
	near.queue_free()
	far.queue_free()

func test_pulse_with_nothing_in_range() -> void:
	_stage()
	var lost := _trace("TRC_TEST_LOST", Vector3(0, 0, 100))
	var nothing := watch(EventBus.echo_nothing_found)
	assert_false(EchoDetection.pulse()["found"])
	assert_eq(nothing.size(), 1)
	lost.queue_free()

func test_echo_detection_feedback_text_is_readable_without_sound() -> void:
	SettingsManager.set_value("accessibility", "echo_audio_cues", false)
	var hud := AbilityHud.new()
	add_child(hud)
	_stage()
	var t := _trace("TRC_TEST_TEXT", Vector3(-5, 0, 0))
	EchoDetection.pulse()
	assert_true(hud.pulse_text().contains("Very close") and hud.pulse_text().contains("left"), hud.pulse_text())
	assert_eq(AbilityHud._direction_key(0.0), "UI_ECHO_AHEAD")
	assert_eq(AbilityHud._direction_key(PI), "UI_ECHO_BEHIND")
	assert_eq(AbilityHud._direction_key(PI / 2.0), "UI_ECHO_RIGHT")
	hud.queue_free()
	t.queue_free()

# --- Reality Shift ------------------------------------------------------------------------------------
const ZONE := "SHF_CH3_ANCHOR_BRIDGE"

func _quick_zone(id: String) -> ShiftZoneDef:
	var z := ShiftZoneDef.new()
	z.id = id
	z.title_key = "UI_PAUSED"
	z.states.assign(["calm", "storm"])
	z.default_state = "calm"
	z.transition_time = 0.0
	DataRegistry.register_runtime(z)
	return z

func test_shift_states_validate_persist_and_notify() -> void:
	assert_eq(ShiftManager.get_state(ZONE), "echo_city", "default state")
	var changes := watch(EventBus.shift_state_changed)
	assert_true(ShiftManager.set_state(ZONE, "other_side"))
	assert_eq(GameState.shift_states[ZONE], "other_side", "persistent zones are saved")
	assert_eq(changes[0][1], "other_side")
	ShiftManager.busy = false
	assert_false(ShiftManager.set_state(ZONE, "other_side"), "no change, no event")
	assert_false(ShiftManager.set_state(ZONE, "made_up"))
	assert_false(ShiftManager.set_state("SHF_UNKNOWN", "x"))
	SaveManager.save_game(1)
	GameState.reset()
	SaveManager.load_game(1)
	assert_eq(ShiftManager.get_state(ZONE), "other_side", "state survives save and load")

func test_only_one_zone_away_from_default() -> void:
	_quick_zone("SHF_TEST_ONE")
	_quick_zone("SHF_TEST_TWO")
	ShiftManager.set_state("SHF_TEST_ONE", "storm")
	ShiftManager.busy = false
	ShiftManager.set_state("SHF_TEST_TWO", "storm")
	assert_eq(ShiftManager.get_state("SHF_TEST_TWO"), "storm")
	assert_eq(ShiftManager.get_state("SHF_TEST_ONE"), "calm", "the first zone returned to normal")

func test_shiftable_objects_follow_the_zone_and_the_save() -> void:
	var obj := ShiftableObject.new()
	obj.zone_id = ZONE
	obj.visible_in_states.assign(["other_side"])
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	body.add_child(shape)
	obj.add_child(body)
	add_child(obj)
	assert_false(obj.visible, "alternate route absent in the default state")
	ShiftManager.set_state(ZONE, "other_side")
	await get_tree().process_frame
	assert_true(obj.visible and obj.solid)
	assert_false(shape.disabled, "the route can be walked")
	obj.queue_free()
	var later := ShiftableObject.new()                        # created after the shift, like a scene load
	later.zone_id = ZONE
	later.visible_in_states.assign(["other_side"])
	add_child(later)
	assert_true(later.visible, "new objects match the saved state")
	later.queue_free()

func test_conditions_can_require_a_shift_state() -> void:
	var c := ConditionSet.new()
	c.shift_states = {ZONE: "other_side"}
	assert_false(c.is_met())
	ShiftManager.set_state(ZONE, "other_side")
	assert_true(c.is_met())

func test_reality_shift_ability_needs_an_anchor() -> void:
	AbilityManager.unlock("ABIL_REALITY_SHIFT")
	var toasts := watch(EventBus.toast_requested)
	assert_false(AbilityManager.activate("ABIL_REALITY_SHIFT"))
	assert_eq(toasts[0][0], "TOAST_NO_ANCHOR")
	var anchor := ShiftAnchor.new()
	anchor.zone_id = ZONE
	add_child(anchor)
	ShiftManager.set_anchor(anchor)
	assert_true(AbilityManager.activate("ABIL_REALITY_SHIFT"))
	assert_eq(ShiftManager.get_state(ZONE), "other_side")
	_advance(1.2)
	ShiftManager.busy = false
	assert_true(AbilityManager.activate("ABIL_REALITY_SHIFT"), "an anchor without a target cycles the states")
	assert_eq(ShiftManager.get_state(ZONE), "echo_city")
	anchor.queue_free()

func test_one_way_anchor_sets_a_fixed_state() -> void:
	AbilityManager.unlock("ABIL_REALITY_SHIFT")
	var anchor := ShiftAnchor.new()
	anchor.zone_id = ZONE
	anchor.target_state = "echo_city"
	add_child(anchor)
	ShiftManager.set_anchor(anchor)
	assert_false(AbilityManager.activate("ABIL_REALITY_SHIFT"), "already in that state: nothing happens")
	anchor.queue_free()

# --- Time Echo: playback --------------------------------------------------------------------------------
func test_echo_playback_captions_clues_and_cleanup() -> void:
	var captions := watch(EventBus.echo_caption)
	var finished := watch(EventBus.echo_finished)
	assert_true(TimeEchoManager.play_echo("ECH_CH3_TAPE_LOADING"))
	assert_true(TimeEchoManager.is_busy())
	assert_true(InputService.is_locked(), "the player watches, input is locked")
	assert_false(TimeEchoManager.play_echo("ECH_CH3_TAPE_LOADING"), "one echo at a time")
	TimeEchoManager.advance(4.0)
	assert_eq(captions.size(), 2, "captions for sounds are shown as they happen")
	assert_false(GameState.has_clue("CLUE_TAPE_ORDER"))
	TimeEchoManager.advance(4.6)
	assert_true(GameState.has_clue("CLUE_TAPE_ORDER"), "clue moment")
	assert_true("INFO_ARC_TAPE_LOADER" in GameState.info)
	TimeEchoManager.advance(1.0)
	assert_false(TimeEchoManager.is_busy())
	assert_false(InputService.is_locked())
	assert_eq(GameState.autosave_blocks, 0)
	assert_eq(finished.size(), 1)
	assert_true("ECH_CH3_TAPE_LOADING" in GameState.echoes_seen)
	assert_true(TimeEchoManager.play_echo("ECH_CH3_TAPE_LOADING"), "replayable echoes can be watched again")
	TimeEchoManager.skip()
	assert_false(TimeEchoManager.is_busy(), "skipping jumps to the end")

func test_echo_conditions_and_single_view() -> void:
	var e := TimeEchoDef.new()
	e.id = "ECH_TEST_ONCE"
	e.duration = 2.0
	e.replayable = false
	e.conditions = ConditionSet.new()
	e.conditions.clues_all.assign(["CLUE_TEST_KEY"])
	var track := EchoTrack.new()
	track.actor_id = "ARC"
	e.tracks.assign([track])
	DataRegistry.register_runtime(e)
	assert_false(TimeEchoManager.play_echo("ECH_TEST_ONCE"), "needs a clue found earlier")
	InventoryManager.add_clue("CLUE_TEST_KEY")
	assert_true(TimeEchoManager.play_echo("ECH_TEST_ONCE"))
	TimeEchoManager.advance(3.0)
	assert_false(TimeEchoManager.play_echo("ECH_TEST_ONCE"), "non-replayable")
	assert_false(TimeEchoManager.play_echo("ECH_UNKNOWN"))

func test_echo_data_is_validated() -> void:
	var e := TimeEchoDef.new()
	e.id = "ECH_TEST_BAD"
	e.duration = 5.0
	var track := EchoTrack.new()
	var late := EchoKey.new()
	late.time = 9.0
	track.keys.assign([late])
	e.tracks.assign([track])
	assert_true("\n".join(e.validate()).contains("time-ordered"))

# --- Time Echo: recording a ghost -------------------------------------------------------------------------
func test_recording_creates_a_ghost_that_replays_and_stays() -> void:
	var player := _stage()
	var site := EchoSite.new()
	site.allow_recording = true
	add_child(site)
	TimeEchoManager.set_site(site)
	AbilityManager.unlock("ABIL_TIME_ECHO")
	var rec := watch(EventBus.echo_recording_changed)
	assert_true(TimeEchoManager.can_use())
	assert_true(AbilityManager.activate("ABIL_TIME_ECHO"), "first use starts recording")
	assert_true(TimeEchoManager.recording)
	for i in 20:
		player.global_position = Vector3(i * 0.3, 0, 0)
		TimeEchoManager.advance(0.1)
	_advance(0.6)
	assert_true(AbilityManager.activate("ABIL_TIME_ECHO"), "second use stops it")
	assert_false(TimeEchoManager.recording)
	assert_eq(rec.size(), 2)
	assert_eq(TimeEchoManager.player_echoes.size(), 1)
	var ghost := TimeEchoManager.player_echoes[0]
	assert_true(ghost.is_playing())
	ghost.advance(60.0)
	assert_false(ghost.is_playing())
	assert_true(ghost.global_position.x > 5.0, "the ghost stays where the recording ended")
	site.queue_free()

func test_ghost_limit_and_upgrade() -> void:
	var player := _stage()
	for round in 2:
		assert_true(TimeEchoManager.start_recording())
		for i in 5:
			player.global_position = Vector3(round * 10 + i, 0, 0)
			TimeEchoManager.advance(0.1)
		assert_true(TimeEchoManager.stop_recording())
	assert_eq(TimeEchoManager.player_echoes.size(), 1, "one ghost until the Chapter 5 upgrade")
	GameState.set_flag("time_echo_upgraded")
	for round in 2:
		TimeEchoManager.start_recording()
		for i in 5:
			TimeEchoManager.advance(0.1)
		TimeEchoManager.stop_recording()
	assert_eq(TimeEchoManager.player_echoes.size(), 2, "the upgrade allows two")

func test_recording_stops_by_itself_after_ten_seconds() -> void:
	_stage()
	TimeEchoManager.start_recording()
	for i in 22:
		TimeEchoManager.advance(0.5)
	assert_false(TimeEchoManager.recording)
	assert_eq(TimeEchoManager.player_echoes.size(), 1)
	assert_false(TimeEchoManager.start_recording() and TimeEchoManager.start_recording(), "no double start")
	TimeEchoManager.stop_recording()

func test_leaving_the_location_clears_ghosts() -> void:
	_stage()
	TimeEchoManager.start_recording()
	TimeEchoManager.advance(0.5)
	TimeEchoManager.stop_recording()
	assert_eq(TimeEchoManager.player_echoes.size(), 1)
	EventBus.scene_transition_started.emit("LOC_A", "LOC_B")
	assert_eq(TimeEchoManager.player_echoes.size(), 0)

# --- puzzle framework ---------------------------------------------------------------------------------------------
func test_required_abilities_gate_a_puzzle() -> void:
	var toasts := watch(EventBus.toast_requested)
	assert_false(PuzzleManager.can_attempt("PZL_CH1_CLOCK_4_17"))
	assert_eq(PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "4"), PuzzleRuntime.Result.FAILED)
	assert_eq(toasts[0][0], "TOAST_NEED_ABILITY")
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	assert_eq(PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "4"), PuzzleRuntime.Result.PROGRESS)

func test_puzzle_progress_is_saved_when_the_definition_says_so() -> void:
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "4")
	PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "1")
	SaveManager.save_game(1)
	GameState.reset()
	PuzzleManager.reset_runtime()
	SaveManager.load_game(1)
	assert_eq(PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "7"), PuzzleRuntime.Result.SOLVED, "only the last symbol was needed")

func test_wrong_symbol_resets_and_feedback_is_gentle() -> void:
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	var toasts := watch(EventBus.toast_requested)
	PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "4")
	assert_eq(PuzzleManager.submit("PZL_CH1_CLOCK_4_17", "9"), PuzzleRuntime.Result.FAILED)
	assert_eq(toasts[toasts.size() - 1][0], "TOAST_PUZZLE_TRY_AGAIN")
	assert_eq(GameState.puzzles["PZL_CH1_CLOCK_4_17"]["progress"]["entered"].size(), 0, "reset on fail")

func test_manual_reset_and_leave_reset() -> void:
	var p := PuzzleDef.new()
	p.id = "PZL_TEST_LEAVE"
	p.location_id = "LOC_UM_ECHO_STATION"
	p.solution.assign(["a", "b"])
	p.hint_keys.assign(["UI_RESUME", "UI_QUIT", "UI_PAUSED"])
	p.title_key = "UI_PAUSED"
	p.accessibility_notes = "n/a"
	p.reset_policy = PuzzleDef.ResetPolicy.ON_LEAVE
	p.save_policy = PuzzleDef.SavePolicy.PROGRESS
	DataRegistry.register_runtime(p)
	var resets := watch(EventBus.puzzle_reset)
	PuzzleManager.submit("PZL_TEST_LEAVE", "a")
	EventBus.scene_transition_started.emit("LOC_UM_ECHO_STATION", "LOC_UM_CONCOURSE")
	assert_eq(resets.size(), 1, "leaving the location resets an unsolved puzzle")
	assert_eq(PuzzleManager.submit("PZL_TEST_LEAVE", "b"), PuzzleRuntime.Result.FAILED, "the entry started over")
	PuzzleManager.reset("PZL_TEST_LEAVE")
	assert_eq(resets.size(), 2)

func test_skip_puzzle_accessibility_option() -> void:
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	assert_false(PuzzleManager.skip_puzzle("PZL_CH1_CLOCK_DEDUCTION"), "off by default")
	SettingsManager.set_value("accessibility", "puzzle_skip", true)
	assert_false(PuzzleManager.skip_puzzle("PZL_CH1_CLOCK_DEDUCTION"), "only after the last hint")
	for i in 3:
		PuzzleManager.request_hint("PZL_CH1_CLOCK_DEDUCTION")
	assert_true(PuzzleManager.skip_puzzle("PZL_CH1_CLOCK_DEDUCTION"))
	assert_true(GameState.get_flag("ch1_clock_dial_unlocked"), "the puzzle's rewards still apply")

func test_every_puzzle_definition_is_complete() -> void:
	for id in ["PZL_CH1_CLOCK_DEDUCTION", "PZL_CH1_CLOCK_4_17", "PZL_CH3_ANCHOR_BRIDGE", "PZL_CH3_TAPE_ORDER", "PZL_CH3_ECHO_PLATES"]:
		var p := DataRegistry.get_puzzle(id)
		assert_true(p != null, id)
		assert_eq(p.validate().size(), 0, id)
		assert_eq(p.hint_keys.size(), 3, id)
		assert_false(p.required_abilities.is_empty(), "%s declares its abilities" % id)
		assert_false(p.accessibility_notes.is_empty(), id)
		assert_false(p.design_notes.is_empty(), id)
		assert_true(DataRegistry.get_location(p.location_id).status != LocationDef.BuildStatus.PLANNED, "%s has a playable scene" % id)
	var bad := PuzzleDef.new()
	bad.id = "PZL_TEST_BAD"
	bad.hint_keys.assign(["a"])
	var text := "\n".join(bad.validate())
	assert_true(text.contains("accessibility_notes"), text)

func test_puzzle_variety() -> void:
	var types := {}
	for id in ["PZL_CH1_CLOCK_DEDUCTION", "PZL_CH1_CLOCK_4_17", "PZL_CH3_ANCHOR_BRIDGE", "PZL_CH3_TAPE_ORDER", "PZL_CH3_ECHO_PLATES"]:
		types[DataRegistry.get_puzzle(id).puzzle_type] = true
	assert_eq(types.size(), 5, "five different puzzle types, no repeated solution pattern")

func test_condition_gate_opens_with_conditions() -> void:
	var gate := ConditionGate.new()
	gate.conditions = ConditionSet.new()
	gate.conditions.flags_all.assign(["gate_flag"])
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	body.add_child(shape)
	gate.add_child(body)
	add_child(gate)
	assert_false(gate.is_open)
	assert_true(gate.visible)
	GameState.set_flag("gate_flag")
	assert_true(gate.is_open)
	assert_false(gate.visible)
	await get_tree().process_frame
	assert_true(shape.disabled, "an open gate has no collision")
	gate.queue_free()

func test_clue_board_links_only_matching_clues() -> void:
	AbilityManager.unlock("ABIL_MEMORY_SIGHT")
	var board := ClueBoard.new()
	board.deduction_id = "DED_STUCK_AT_417"
	board.puzzle_id = "PZL_CH1_CLOCK_DEDUCTION"
	add_child(board)
	var toasts := watch(EventBus.toast_requested)
	board.interact()
	assert_eq(toasts[0][0], "TOAST_CLUES_DONT_FIT", "nothing owned yet")
	assert_false(PuzzleManager.is_solved("PZL_CH1_CLOCK_DEDUCTION"))
	InventoryManager.add_clue("CLUE_STATION_CLOCK")
	board.interact()
	assert_false(PuzzleManager.is_solved("PZL_CH1_CLOCK_DEDUCTION"), "one clue is not enough")
	InventoryManager.add_clue("CLUE_CLOCK_WALL_WRITING")
	board.interact()
	assert_true(PuzzleManager.is_solved("PZL_CH1_CLOCK_DEDUCTION"))
	assert_true("DED_STUCK_AT_417" in GameState.deductions)
	board.queue_free()
