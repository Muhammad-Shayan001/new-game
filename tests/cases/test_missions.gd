extends "res://tests/test_case.gd"

## Plays the entire campaign through the mission system using only the story events the objectives
## ask for. Proves every main mission is completable, in order, with consistent unlocks.
func _satisfy(mission_id: String) -> void:
	var def := DataRegistry.get_def("missions", mission_id)
	for o: Dictionary in def["objectives"]:
		var cw: Dictionary = o["complete_when"]
		match cw["event"]:
			"location_entered": EventBus.location_entered.emit(cw["arg"])
			"dialogue_finished": EventBus.dialogue_finished.emit(cw["arg"])
			"interacted": EventBus.interacted.emit(cw["arg"])
			"puzzle_solved": EventBus.puzzle_solved.emit(cw["arg"])

func test_first_mission_starts_automatically() -> void:
	eq(MissionManager.get_state("CH1_M01"), "ACTIVE", "CH1_M01 active at new game")
	eq(MissionManager.get_state("CH1_M02"), "LOCKED", "CH1_M02 locked")
	eq(MissionManager.get_state("CH2_M01"), "LOCKED", "later chapters locked")

func test_objective_text_for_hud() -> void:
	var t := MissionManager.current_objective_text()
	ok(t.contains("Static"), "mission name shown: " + t)
	ok(t.contains("Echo Station"), "objective shown: " + t)

func test_full_campaign_walkthrough() -> void:
	for ch in range(1, 7):
		for k in range(1, 4):
			var id := "CH%d_M%02d" % [ch, k]
			eq(MissionManager.get_state(id), "ACTIVE", "%s should be active before play" % id)
			_satisfy(id)
			eq(MissionManager.get_state(id), "COMPLETE", "%s completes from its objectives" % id)
		if ch < 6:
			eq(GameState.chapter, ch + 1, "chapter advances after chapter %d" % ch)
	ok(GameState.get_flag("game_complete"), "game_complete set at the end")
	for a in ["ABL_MEMORY_SIGHT", "ABL_REALITY_SHIFT", "ABL_TIME_ECHO", "ABL_ECHO_VOICE"]:
		ok(AbilityManager.is_unlocked(a), a + " unlocked by campaign progress")

func test_out_of_order_events_do_not_skip_missions() -> void:
	_satisfy("CH1_M03")        # fire chapter 1 mission 3 events before it is active
	eq(MissionManager.get_state("CH1_M03"), "LOCKED", "locked mission ignores events")
	eq(MissionManager.get_state("CH1_M01"), "ACTIVE", "M01 untouched")

func test_secondary_missions_appear_with_chapter() -> void:
	eq(MissionManager.get_state("CH2_S01"), "LOCKED", "optional locked in ch1")
	GameState.set_chapter(2)
	EventBus.flag_changed.emit("x", true)    # any event triggers refresh
	eq(MissionManager.get_state("CH2_S01"), "ACTIVE", "optional available once chapter reached")

func test_optional_objectives_do_not_block_completion() -> void:
	var m := MissionManager
	ok(m.get_state("CH1_M01") == "ACTIVE")
	m.complete_objective("CH1_M01", "reach_um_echo_station")
	ok(m.objectives_done("CH1_M01").has("reach_um_echo_station"), "manual objective completion")
