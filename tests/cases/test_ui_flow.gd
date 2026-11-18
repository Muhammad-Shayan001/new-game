extends "res://tests/test_case.gd"
## Title screen, new game / continue, pause menu, HUD wiring.

func test_title_screen_builds() -> void:
	var title: Control = load("res://scenes/ui/title_screen.tscn").instantiate()
	tree.root.add_child(title)
	await frames(2)
	var labels: Array = []
	for b in title.find_children("*", "Button", true, false):
		labels.append(b.text)
	ok(labels.has("New Game") and labels.has("Continue"), "has New Game / Continue: %s" % str(labels))
	title.queue_free()
	await frames(2)

func test_new_game_flow_reaches_gameplay() -> void:
	SaveManager.delete_slot(0)
	tree.change_scene_to_file("res://scenes/ui/title_screen.tscn")
	await frames(3)
	Settings.set_value("reduced_motion", true, false)
	await SceneManager.start_new_game()
	await frames(3)
	ok(SceneManager.player != null, "game root registered")
	eq(SceneManager.current_location_id, "LOC_UM_ECHO_STATION", "starts at Echo Station")
	eq(GameState.chapter, 1, "chapter 1")
	ok(MissionManager.current_objective_text() != "", "objective visible")
	ok(AbilityManager.is_unlocked("ABL_MEMORY_SIGHT"), "Memory Sight unlocked from the first mission")
	await SceneManager.return_to_title()
	await frames(3)
	ok(SceneManager.player == null, "game root unregistered on return to title")
	ok(not InputRouter.is_locked(), "no lingering locks")

func test_continue_restores_exact_state() -> void:
	Settings.set_value("reduced_motion", true, false)
	await SceneManager.start_new_game()
	await frames(2)
	await SceneManager.go_to_location("LOC_EC_MAIN_STREET")
	GameState.set_flag("marker", true)
	SaveManager.save_game(1)
	await SceneManager.return_to_title()
	await frames(2)
	SaveManager.reset_all()
	var okay: bool = await SceneManager.continue_game(1)
	await frames(2)
	ok(okay, "continue succeeds")
	eq(SceneManager.current_location_id, "LOC_EC_MAIN_STREET", "back in the saved location")
	ok(GameState.get_flag("marker"), "flags restored")
	SaveManager.delete_slot(1)
	await SceneManager.return_to_title()
	await frames(2)

func test_continue_with_empty_slot_fails_cleanly() -> void:
	SaveManager.delete_slot(3)
	var r: bool = await SceneManager.continue_game(3)
	ok(not r, "no save, no crash")

func test_pause_menu_pauses_and_blocks_input() -> void:
	var root := await start_game_at("LOC_DEV_TEST_ARENA")
	var pm := root.get_node("PauseMenu")
	pm.toggle()
	ok(tree.paused and InputRouter.is_locked(), "paused + input locked")
	pm.toggle()
	ok(not tree.paused and not InputRouter.is_locked(), "resumed")
	await end_game(root)

func test_pause_menu_does_not_open_during_dialogue() -> void:
	var root := await start_game_at("LOC_DEV_TEST_ARENA")
	DialogueManager.start("DLG_TEST_PHONE")
	root.get_node("PauseMenu").toggle()
	ok(not tree.paused, "dialogue wins over pause")
	DialogueManager.abort()
	await end_game(root)

func test_dialogue_box_shows_lines_and_choices() -> void:
	var root := await start_game_at("LOC_DEV_TEST_ARENA")
	Settings.set_value("reduced_motion", true, false)
	var box := root.get_node("DialogueBox")
	DialogueManager.start("DLG_TEST_NPC")
	await frames(2)
	ok(box._panel.visible, "dialogue panel visible")
	ok(box._text.text.contains("test arena"), "line text shown: " + box._text.text)
	DialogueManager.advance()
	await frames(2)
	eq(box._choices.get_child_count(), 2, "two visible choice buttons")
	box._choices.get_child(0).pressed.emit()
	await frames(2)
	DialogueManager.advance()
	await frames(2)
	ok(not box._panel.visible, "panel hidden when finished")
	await end_game(root)

func test_toast_shows_message() -> void:
	var root := await start_game_at("LOC_DEV_TEST_ARENA")
	EventBus.toast_requested.emit("Hello toast")
	await frames(2)
	eq(root.get_node("HUD").toast_label.text, "Hello toast", "toast text")
	ok(root.get_node("HUD").toast_label.modulate.a > 0.9, "toast visible")
	await end_game(root)
