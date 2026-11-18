extends "res://tests/test_case.gd"
## COMPLETION GATE for Prompt 04: a developer can add a character, item, puzzle, dialogue,
## interaction, location and mission using DATA ONLY (no GDScript edits), and the existing systems
## (graybox generation, interactions, missions, dialogue, puzzles, saves, localization) pick it up.

var added: Array = []

func _add(kind: String, d: Dictionary) -> void:
	var errs := DataRegistry.register_def(kind, d)
	eq(errs.size(), 0, "%s %s accepted: %s" % [kind, d.get("id", "?"), "; ".join(errs)])
	added.append([kind, d["id"]])

func _cleanup() -> void:
	for e in added:
		DataRegistry.unregister_def(e[0], e[1])
	added = []

func test_new_content_without_code() -> void:
	# 1. New character, item and puzzle
	_add("characters", {"id": "NEW_GUARD", "name_key": "char.NEW_GUARD"})
	_add("items", {"id": "ITEM_NEW_KEY", "name_key": "item.NEW", "kind": "key"})
	_add("puzzles", {"id": "PZL_NEW_CODE", "type": "code", "solution": [4, 1, 7],
		"on_solved": [{"do": "add_item", "id": "ITEM_NEW_KEY"}]})
	# 2. Dialogue using the new character, with a branch on an item the puzzle grants
	_add("dialogue", {"id": "DLG_NEW_GUARD", "start": "a", "nodes": {
		"a": {"speaker": "NEW_GUARD", "text_key": "ui.paused", "next": "b"},
		"b": {"branch": [{"if": {"has_item": "ITEM_NEW_KEY"}, "next": "open"}, {"next": "shut"}]},
		"open": {"speaker": "NEW_GUARD", "text_key": "ui.resume", "effects": [{"do": "set_flag", "flag": "guard_let_me_in"}]},
		"shut": {"speaker": "NEW_GUARD", "text_key": "ui.close"}}})
	# 3. Interactions placed in the new location (an NPC and a computer)
	_add("interactions", {"id": "INT_NEW_GUARD", "type": "npc", "location": "LOC_NEW_HUB", "dialogue_id": "DLG_NEW_GUARD", "position": [2, 0, 0]})
	_add("interactions", {"id": "INT_NEW_PANEL", "type": "computer", "location": "LOC_NEW_HUB", "puzzle_id": "PZL_NEW_CODE", "position": [-2, 0, 0]})
	# 4. New location connected to an existing one, and a mission that spans both
	_add("locations", {"id": "LOC_NEW_HUB", "name_key": "loc.LOC_UM_ECHO_STATION", "region": "UM", "chapter": 1, "type": "interior",
		"connections": [{"to": "LOC_UM_ECHO_STATION", "route": "main", "gate_chapter": 1}]})
	_add("missions", {"id": "NEW_M01", "name_key": "mission.CH1_M01", "chapter": 1, "type": "Secondary", "location": "LOC_NEW_HUB",
		"unlock_requires": {}, "auto_start": true, "priority": 0,
		"objectives": [
			{"id": "go", "text_key": "obj.reach", "args_keys": {"place": "loc.LOC_UM_ECHO_STATION"}, "complete_when": {"event": "location_entered", "arg": "LOC_NEW_HUB"}},
			{"id": "code", "text_key": "obj.test_puzzle", "complete_when": {"event": "puzzle_solved", "arg": "PZL_NEW_CODE"}},
			{"id": "talk", "text_key": "obj.talk_maya", "complete_when": {"event": "dialogue_finished", "arg": "DLG_NEW_GUARD"}}],
		"on_complete": [{"do": "set_flag", "flag": "new_mission_done"}]})
	MissionManager.reset_data()
	MissionManager.refresh()
	eq(MissionManager.get_state("NEW_M01"), "ACTIVE", "new mission is picked up by the mission system")

	# 5. Enter the new location: graybox is generated from data; interactions and portal appear.
	var root := await start_game_at("LOC_NEW_HUB")
	eq(SceneManager.current_location_id, "LOC_NEW_HUB", "new location loads with no scene file")
	ok(MissionManager.objectives_done("NEW_M01").has("go"), "entering the location advanced the mission")
	ok(find_interactable("INT_NEW_GUARD") != null and find_interactable("INT_NEW_PANEL") != null, "interactions spawned from data")
	var portal_found := false
	for c in SceneManager.current_location_node.get_children():
		if c is LocationPortal and c.target_location == "LOC_UM_ECHO_STATION":
			portal_found = true
	ok(portal_found, "portal to the existing location generated")

	# 6. Play it: solve the puzzle, then talk; the dialogue branches on the new item.
	ok(not PuzzleManager.submit("PZL_NEW_CODE", [4, 1, 8]), "wrong code rejected")
	ok(PuzzleManager.submit("PZL_NEW_CODE", [4, 1, 7]), "right code accepted (code puzzle type)")
	ok(InventoryManager.has_item("ITEM_NEW_KEY"), "puzzle reward applied from data")
	var panel_it := find_interactable("INT_NEW_GUARD")
	await place_near(panel_it)
	await press("interact")
	var guard := 0
	while DialogueManager.is_active() and guard < 10:
		DialogueManager.advance()
		guard += 1
	ok(GameState.get_flag("guard_let_me_in"), "dialogue branched on the item")
	eq(MissionManager.get_state("NEW_M01"), "COMPLETE", "new mission completes through the same event system")
	ok(GameState.get_flag("new_mission_done"), "mission reward effect ran")

	# 7. Saves include everything automatically.
	SaveManager.save_game(2)
	SaveManager.reset_all()
	SaveManager.load_game(2)
	ok(PuzzleManager.is_solved("PZL_NEW_CODE") and InventoryManager.has_item("ITEM_NEW_KEY"), "new content persists in saves with no save-code changes")
	SaveManager.delete_slot(2)
	await end_game(root)
	_cleanup()

func test_invalid_definitions_are_rejected_with_clear_errors() -> void:
	var errs := DataRegistry.register_def("missions", {"id": "BAD"})
	ok(errs.size() >= 4, "missing fields are listed: %s" % str(errs))
	errs = DataRegistry.register_def("items", {"id": "X", "name_key": 5, "kind": "clue"})
	ok(errs.size() == 1 and errs[0].contains("name_key"), "wrong type is named: %s" % str(errs))
	errs = DataRegistry.register_def("items", {"id": "ITEM_TUNING_FORK", "name_key": "k", "kind": "clue"})
	ok(errs.size() == 1 and errs[0].contains("duplicate"), "duplicate ids rejected")
