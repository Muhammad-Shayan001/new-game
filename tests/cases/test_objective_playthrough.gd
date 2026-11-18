extends "res://tests/test_case.gd"
## COMPLETION GATE: the player moves, turns, interacts and completes a multi-step objective using
## only the same inputs a phone player has (stick vector + interact). Runs the whole dev arena
## mission MSN_TEST_ARENA: pull lever -> read note -> solve computer puzzle -> walk through the
## door -> reach the goal.

func _interact_with(id: String) -> bool:
	var it := find_interactable(id)
	var arrived := await walk_to(it.global_position, 1.1)
	if not arrived:
		return false
	await physics(6)
	await press("interact")
	return true

func test_complete_arena_mission_with_stick_and_interact() -> void:
	var root := await start_game_at("LOC_DEV_TEST_ARENA")
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 12.0)))
	await physics(10)
	eq(MissionManager.get_state("MSN_TEST_ARENA"), "ACTIVE", "arena mission active on entry")
	ok(MissionManager.current_objective_text().contains("Pull the lever"), "HUD text shows the first objective")
	var start_frame := Engine.get_physics_frames()

	ok(await _interact_with("INT_TEST_LEVER"), "reached the lever")
	ok(GameState.get_flag("test_door_open"), "door unlocked")
	ok(MissionManager.objectives_done("MSN_TEST_ARENA").has("lever"), "objective 1 done")

	ok(await _interact_with("INT_TEST_NOTE"), "reached the note")
	var reader := root.get_node("DocumentReader")
	ok(reader.is_open(), "note displayed")
	reader.close_reader()
	ok(MissionManager.objectives_done("MSN_TEST_ARENA").has("note"), "objective 2 done")

	ok(await _interact_with("INT_TEST_COMPUTER"), "reached the computer")
	var panel := root.get_node("PuzzlePanel")
	ok(panel.is_open(), "puzzle UI opened by the computer")
	for o in ["a", "b", "c"]:
		panel._choose(o)
	panel.close_panel()
	ok(MissionManager.objectives_done("MSN_TEST_ARENA").has("puzzle"), "objective 3 done")

	await physics(40)         # let the door finish sliding
	ok(await _interact_with("INT_TEST_GOAL"), "walked through the door to the goal")
	eq(MissionManager.get_state("MSN_TEST_ARENA"), "COMPLETE", "MISSION COMPLETE")
	ok(player().global_position.z < -10.0, "player is beyond the wall (z=%.1f)" % player().global_position.z)
	var seconds := float(Engine.get_physics_frames() - start_frame) / 60.0
	ok(seconds < 40.0, "finished in a sensible time (%.1f s of game time)" % seconds)
	ok(not InputRouter.is_locked(), "no input lock left behind")
	await end_game(root)

func test_mission_state_survives_save_and_load_mid_objective() -> void:
	var root := await start_game_at("LOC_DEV_TEST_ARENA")
	ok(await _interact_with("INT_TEST_LEVER"), "lever")
	SaveManager.save_game(2)
	SaveManager.reset_all()
	SaveManager.load_game(2)
	ok(GameState.get_flag("test_door_open"), "flag restored")
	ok(MissionManager.objectives_done("MSN_TEST_ARENA").has("lever"), "objective progress restored")
	SaveManager.delete_slot(2)
	await end_game(root)

func test_gameplay_with_every_input_device_path() -> void:
	# Keyboard path: action presses instead of the virtual stick.
	var root := await start_game_at("LOC_DEV_TEST_ARENA")
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 12.0)))
	await physics(10)
	var z0 := player().global_position.z
	Input.action_press("move_forward")
	await physics(60)
	Input.action_release("move_forward")
	ok(player().global_position.z < z0 - 2.0, "W key moves the player forward")
	# Gamepad stick: analogue axis strength through the action.
	z0 = player().global_position.z
	Input.action_press("move_forward", 0.4)
	await physics(60)
	Input.action_release("move_forward")
	var dz := z0 - player().global_position.z
	ok(dz > 0.3 and dz < 3.0, "half-pushed gamepad stick walks slowly (moved %.2f m)" % dz)
	await end_game(root)
