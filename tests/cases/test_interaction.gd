extends "res://tests/test_case.gd"
## Interaction system: prompts, facing cone, requirements, every interaction type, hold, one-shot.

var root: Node
var prompts: Array = []
var toasts: Array = []
var docs: Array = []
var puzzles: Array = []
var interacted: Array = []

func _arena() -> void:
	root = await start_game_at("LOC_DEV_TEST_ARENA")
	prompts = []
	toasts = []
	docs = []
	puzzles = []
	interacted = []
	EventBus.interaction_prompt_changed.connect(func(t): prompts.append(t))
	EventBus.toast_requested.connect(func(t): toasts.append(t))
	EventBus.document_requested.connect(func(a, b): docs.append([a, b]))
	EventBus.puzzle_requested.connect(func(id): puzzles.append(id))
	EventBus.interacted.connect(func(id): interacted.append(id))

func test_all_dev_interactions_spawn_from_data() -> void:
	await _arena()
	for id in ["INT_TEST_LEVER", "INT_TEST_NOTE", "INT_TEST_NPC", "INT_TEST_PHONE", "INT_TEST_COMPUTER",
			"INT_TEST_MEMORY", "INT_TEST_HOLD", "INT_TEST_GOAL"]:
		ok(find_interactable(id) != null, "%s placed from its JSON definition" % id)
	await end_game(root)

func test_prompt_appears_and_clears() -> void:
	await _arena()
	var lever := find_interactable("INT_TEST_LEVER")
	await place_near(lever)
	ok(prompts.has("Pull the lever"), "prompt published for the lever: %s" % str(prompts))
	ok(lever.focused, "target highlighted")
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 20)))
	await physics(6)
	eq(prompts.back(), "", "prompt cleared when out of range")
	await end_game(root)

func test_lever_opens_door_via_flag() -> void:
	await _arena()
	var lever := find_interactable("INT_TEST_LEVER")
	var door := SceneManager.current_location_node.get_node("Door") as Mechanism
	ok(not door.is_open, "door starts closed")
	await place_near(lever)
	await press("interact")
	ok(GameState.get_flag("test_door_open"), "lever effect set the flag")
	ok(interacted.has("INT_TEST_LEVER"), "interacted signal carries the same ID as the mission objective")
	ok(door.is_open, "mechanism reacted to the flag")
	await physics(60)
	ok(door.position.y < 0.0, "door slid out of the way")
	await end_game(root)

func test_door_blocks_until_opened() -> void:
	await _arena()
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, -7.5)))
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(80)
	ok(player().global_position.z > -9.4, "closed door blocks the gap (z=%.2f)" % player().global_position.z)
	GameState.set_flag("test_door_open", true)
	await physics(80)
	ok(player().global_position.z < -10.5, "player walks through once open (z=%.2f)" % player().global_position.z)
	await end_game(root)

func test_facing_cone_and_assist_setting() -> void:
	await _arena()
	var lever := find_interactable("INT_TEST_LEVER")
	await place_near(lever, PI)                 # facing away (south)
	eq(player().get_node("Interactor").target, null, "no target when facing away")
	await press("interact")
	ok(not GameState.get_flag("test_door_open"), "interact does nothing when facing away")
	Settings.set_value("interaction_assist", true, false)
	await physics(4)
	ok(player().get_node("Interactor").target == lever, "assist setting widens the cone")
	await end_game(root)

func test_requirement_blocks_with_feedback_then_allows() -> void:
	await _arena()
	var pc := find_interactable("INT_TEST_COMPUTER")
	await place_near(pc)
	await press("interact")
	eq(puzzles.size(), 0, "computer locked before reading the note")
	ok(toasts.has("Read the note first."), "player is told why: %s" % str(toasts))
	GameState.set_flag("read:INT_TEST_NOTE", true)
	await press("interact")
	ok(puzzles.has("PZL_TEST_SEQUENCE"), "puzzle requested once requirement is met")
	await end_game(root)

func test_note_opens_document_and_sets_read_flag() -> void:
	await _arena()
	var note := find_interactable("INT_TEST_NOTE")
	await place_near(note)
	await press("interact")
	eq(docs.size(), 1, "document requested")
	ok(GameState.get_flag("read:INT_TEST_NOTE"), "read flag set")
	var reader := root.get_node("DocumentReader")
	ok(reader.is_open(), "reader UI open")
	ok(InputRouter.is_locked(), "gameplay input locked while reading")
	reader.close_reader()
	ok(not InputRouter.is_locked(), "unlocked on close")
	await end_game(root)

func test_npc_and_phone_start_dialogue() -> void:
	await _arena()
	var npc := find_interactable("INT_TEST_NPC")
	await place_near(npc)
	await press("interact")
	ok(DialogueManager.is_active() and DialogueManager.active_id == "DLG_TEST_NPC", "NPC starts its dialogue")
	DialogueManager.abort()
	var phone := find_interactable("INT_TEST_PHONE")
	await place_near(phone)
	await press("interact")
	eq(DialogueManager.active_id, "DLG_TEST_PHONE", "phone starts its dialogue")
	DialogueManager.abort()
	await end_game(root)

func test_memory_object_collects_fragment() -> void:
	await _arena()
	var m := find_interactable("INT_TEST_MEMORY")
	await place_near(m)
	await press("interact")
	ok(MemoryManager.has_fragment("CH1_F01"), "memory object granted the fragment")
	await end_game(root)

func test_hold_interaction_needs_full_hold() -> void:
	await _arena()
	var h := find_interactable("INT_TEST_HOLD")
	await place_near(h)
	var progress := [0.0]
	EventBus.interaction_hold_progress.connect(func(r): progress[0] = r)
	Input.action_press("interact")
	await physics(30)
	ok(not GameState.get_flag("test_hold_done"), "half a second is not enough")
	ok(progress[0] > 0.3 and progress[0] < 1.0, "progress reported (%.2f)" % progress[0])
	Input.action_release("interact")
	await physics(4)
	near(progress[0], 0.0, 0.01, "releasing resets progress")
	Input.action_press("interact")
	await physics(90)
	Input.action_release("interact")
	ok(GameState.get_flag("test_hold_done"), "holding long enough triggers it")
	await end_game(root)

func test_input_lock_blocks_interaction() -> void:
	await _arena()
	var lever := find_interactable("INT_TEST_LEVER")
	await place_near(lever)
	InputRouter.push_lock("pause")
	await press("interact")
	ok(not GameState.get_flag("test_door_open"), "cannot interact while locked")
	await end_game(root)

func test_nearest_target_wins() -> void:
	await _arena()
	var lever := find_interactable("INT_TEST_LEVER")
	var other := Interactable.new()
	other.configure({"id": "INT_TEST_NEAR", "type": "generic"})
	SceneManager.current_location_node.add_child(other)
	other.global_position = lever.global_position + Vector3(1.0, 0, 0.9)
	await place_near(lever)
	ok(player().get_node("Interactor").target == lever, "closest in front is chosen")
	await end_game(root)

func test_one_shot_pickup_persists_as_consumed() -> void:
	root = await start_game_at("LOC_EC_ALEX_APT")
	var stub := find_interactable("INT_EC_STUB")
	ok(stub != null, "stub spawned from data")
	await place_near(stub)
	await press("interact")
	ok(InventoryManager.has_item("ITEM_TICKET_STUB_WM"), "item added")
	ok(GameState.get_flag("consumed:INT_EC_STUB"), "consumed flag stored (saved with the game)")
	ok(not stub.monitorable, "pickup disabled")
	await SceneManager.go_to_location("LOC_EC_APT_BLDG")
	await SceneManager.go_to_location("LOC_EC_ALEX_APT")
	var again := find_interactable("INT_EC_STUB")
	ok(not again.is_available(), "does not respawn after re-entering")
	await end_game(root)

func test_puzzle_object_runs_full_chain_with_ui() -> void:
	root = await start_game_at("LOC_EC_ALEX_APT")
	var wardrobe := find_interactable("INT_EC_WARDROBE")
	await place_near(wardrobe)
	await press("interact")
	var panel := root.get_node("PuzzlePanel")
	ok(panel.is_open(), "puzzle UI opened")
	for o in ["house", "lake", "wave"]:
		panel._choose(o)
	ok(not PuzzleManager.is_solved("PZL_EC_01"), "wrong order rejected")
	for o in ["wave", "house", "lake"]:
		panel._choose(o)
	ok(PuzzleManager.is_solved("PZL_EC_01"), "right order solves it")
	ok(InventoryManager.has_item("ITEM_CHILD_DRAWING"), "reward from data")
	panel.close_panel()
	ok(not InputRouter.is_locked(), "input restored")
	await end_game(root)

func test_unavailable_interactable_is_ignored_by_visibility_rule() -> void:
	root = await start_game_at("LOC_EC_ARCHIVE_TOWER")
	var arch := find_interactable("INT_EC_ARCHIVIST")
	ok(arch != null, "archivist spawned")
	ok(not arch.is_available(), "hidden until CH1_M03 is active (visible_if)")
	await end_game(root)
