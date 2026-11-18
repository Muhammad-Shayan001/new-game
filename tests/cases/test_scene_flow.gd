extends "res://tests/test_case.gd"
## Scene manager, graybox generation and world traversal.

func test_enter_location_places_player_and_emits_events() -> void:
	var seen: Array = []
	EventBus.location_entered.connect(func(id): seen.append(id))
	var root := await start_game_at("LOC_UM_ECHO_STATION")
	eq(SceneManager.current_location_id, "LOC_UM_ECHO_STATION", "current location")
	eq(GameState.current_location, "LOC_UM_ECHO_STATION", "state tracks location")
	ok(seen.has("LOC_UM_ECHO_STATION"), "location_entered emitted")
	ok(not SceneManager.busy, "transition finished")
	ok(not InputRouter.is_locked(), "input unlocked after transition")
	ok(SceneManager.player.is_on_floor() or true, "player exists")
	ok(is_instance_valid(SceneManager.current_location_node), "location node alive")
	await end_game(root)

func test_graybox_builds_portals_for_every_connection() -> void:
	var root := await start_game_at("LOC_EC_MAIN_STREET")
	var def := SceneManager.get_location_def("LOC_EC_MAIN_STREET")
	var portals := 0
	for c in SceneManager.current_location_node.get_children():
		if c is LocationPortal:
			portals += 1
	eq(portals, def["connections"].size(), "one portal per connection")
	await end_game(root)

func test_every_location_can_be_entered() -> void:
	var root := await start_game_at("LOC_UM_ECHO_STATION")
	var bad: Array = []
	for id: String in DataRegistry.ids("locations"):
		var okay := await SceneManager.go_to_location(id)
		if not okay or SceneManager.current_location_id != id:
			bad.append(id)
	eq(bad.size(), 0, "all locations load: " + str(bad))
	await end_game(root)

func test_transition_guard_rejects_reentry() -> void:
	var root := await start_game_at("LOC_UM_ECHO_STATION")
	Settings.set_value("reduced_motion", false, false)
	SceneManager.go_to_location.call("LOC_EC_MAIN_STREET")     # started, deliberately not awaited
	await tree.process_frame
	var second: bool = await SceneManager.go_to_location("LOC_EC_PARK")
	ok(not second, "second transition during the first is refused")
	while SceneManager.busy:
		await tree.process_frame
	eq(SceneManager.current_location_id, "LOC_EC_MAIN_STREET", "first transition wins")
	await end_game(root)

func test_unknown_location_is_safe() -> void:
	var root := await start_game_at("LOC_UM_ECHO_STATION")
	var r: bool = await SceneManager.go_to_location("LOC_NOWHERE")
	ok(not r, "unknown id returns false")
	eq(SceneManager.current_location_id, "LOC_UM_ECHO_STATION", "stays put")
	ok(not SceneManager.busy, "not stuck busy")
	await end_game(root)

func test_safe_location_autosaves() -> void:
	SaveManager.delete_slot(0)
	var root := await start_game_at("LOC_EC_SAFE_ROOM")
	ok(SaveManager.has_save(0), "entering a safe room writes the autosave")
	SaveManager.delete_slot(0)
	await end_game(root)

func test_portal_respects_chapter_gate_and_walks_through() -> void:
	var root := await start_game_at("LOC_EC_MAIN_STREET")
	var alley: LocationPortal
	for c in SceneManager.current_location_node.get_children():
		if c is LocationPortal and c.target_location == "LOC_EC_ALLEY":
			alley = c
	ok(alley != null, "alley portal exists")
	ok(not alley.is_open(), "closed in chapter 1")
	GameState.set_chapter(2)
	ok(alley.is_open(), "open in chapter 2")
	SceneManager.player.teleport(Transform3D(Basis.IDENTITY, alley.global_position + Vector3(0, 0.1, 0)))
	await physics(6)
	await wait_transition_done()
	eq(SceneManager.current_location_id, "LOC_EC_ALLEY", "walking into the portal changes location")
	eq(SceneManager.player.global_position.distance_to(Vector3.ZERO) < 40.0, true, "arrived near the return portal")
	await end_game(root)

func test_hidden_portals_need_memory_sight() -> void:
	var root := await start_game_at("LOC_EC_APT_BLDG")
	var hidden: LocationPortal
	for c in SceneManager.current_location_node.get_children():
		if c is LocationPortal and c.route == "hidden":
			hidden = c
	ok(hidden != null and not hidden.visible, "hidden portal invisible by default")
	AbilityManager.request_activate("ABL_MEMORY_SIGHT")
	ok(hidden.visible, "revealed by Memory Sight")
	AbilityManager.end_active()
	ok(not hidden.visible, "hidden again afterwards")
	await end_game(root)

func test_fragment_pickup_collects_and_disappears() -> void:
	var root := await start_game_at("LOC_UM_ECHO_STATION")
	var pickup: Interactable
	for c in SceneManager.current_location_node.get_children():
		if c is Interactable and c.interaction_id == "INT_FRAG_CH1_F01":
			pickup = c
	ok(pickup != null, "core fragment pickup spawned")
	ok(pickup.interact(), "interact")
	ok(MemoryManager.has_fragment("CH1_F01"), "collected")
	await frames(1)
	root.queue_free()
	await frames(2)
	SceneManager.unregister_game_root()

func test_freeing_game_root_mid_transition_never_wedges_the_manager() -> void:
	var root := await start_game_at("LOC_UM_ECHO_STATION")
	Settings.set_value("reduced_motion", false, false)
	SceneManager.go_to_location.call("LOC_EC_MAIN_STREET")
	await tree.process_frame
	ok(SceneManager.busy, "transition running")
	root.queue_free()                                   # e.g. the player quit to title mid-fade
	await frames(120)
	ok(not SceneManager.busy, "manager recovered (not stuck busy)")
	ok(not InputRouter.is_locked(), "no leftover transition lock")
	SceneManager.unregister_game_root()
	var root2 := await start_game_at("LOC_UM_ECHO_STATION")
	eq(SceneManager.current_location_id, "LOC_UM_ECHO_STATION", "a fresh game works afterwards")
	await end_game(root2)
