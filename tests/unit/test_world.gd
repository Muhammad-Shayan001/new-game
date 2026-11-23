extends TestCase
## Scene transitions, location scenes, interaction, NPCs.

var host: Node3D

func before_each() -> void:
	super.before_each()
	host = Node3D.new()
	add_child(host)
	SceneRouter.fade_time = 0.0
	SceneRouter.state = SceneRouter.State.IDLE
	SceneRouter.current_root = null
	SceneRouter.current_location_id = ""
	SceneRouter.register_host(host)

func after_each() -> void:
	SceneRouter.current_root = null
	host.queue_free()

func test_transition_loads_graybox_scene() -> void:
	var finished := watch(EventBus.scene_transition_finished)
	var ready := watch(EventBus.location_ready)
	var ok: bool = await SceneRouter.change_location("LOC_UM_ECHO_STATION")
	assert_true(ok)
	assert_true(SceneRouter.current_root is LocationRoot)
	assert_eq(SceneRouter.current_location_id, "LOC_UM_ECHO_STATION")
	assert_eq(GameState.current_location, "LOC_UM_ECHO_STATION")
	assert_eq(finished.size(), 1)
	assert_eq(ready.size(), 1)
	assert_false(InputService.is_locked(), "input unlocked after transition")
	assert_eq(GameState.autosave_blocks, 0)
	assert_eq(SceneRouter.state, SceneRouter.State.IDLE)

func test_unbuilt_location_uses_placeholder_with_doors() -> void:
	GameState.set_chapter(2)
	var ok: bool = await SceneRouter.change_location("LOC_EC_MAIN_STREET")
	assert_true(ok)
	var root := SceneRouter.current_root
	var def := DataRegistry.get_location("LOC_EC_MAIN_STREET")
	assert_true(ResourceLoader.exists(root.scene_file_path), "main street scene resource exists")
	var doors := root.get_children().filter(func(n): return n is Interactable)
	var expected := def.connections.filter(func(c): return c.gate_chapter <= 2 and c.route_type != "hidden").size()
	assert_eq(doors.size(), expected)
	assert_true(expected >= 1, "main street has at least one route")

func test_chapter_gates_hide_doors() -> void:
	await SceneRouter.change_location("LOC_EC_MAIN_STREET")   # chapter 1
	var chapter1_doors := SceneRouter.current_root.get_children().filter(func(n): return n is Interactable).size()
	GameState.set_chapter(2)
	await SceneRouter.change_location("LOC_EC_PARK")
	await SceneRouter.change_location("LOC_EC_MAIN_STREET")
	var chapter2_doors := SceneRouter.current_root.get_children().filter(func(n): return n is Interactable).size()
	assert_true(chapter2_doors > chapter1_doors, "alley opens in chapter 2")

func test_unknown_location_fails_safely() -> void:
	await SceneRouter.change_location("LOC_UM_ECHO_STATION")
	var failed := watch(EventBus.scene_transition_failed)
	var ok: bool = await SceneRouter.change_location("LOC_ZZ_NOWHERE")
	assert_false(ok)
	assert_eq(failed.size(), 1)
	assert_eq(SceneRouter.current_location_id, "LOC_UM_ECHO_STATION", "stays where it was")
	assert_true(is_instance_valid(SceneRouter.current_root))

func test_busy_router_refuses_second_request() -> void:
	SceneRouter.state = SceneRouter.State.LOADING   # a transition is "in progress"
	var refused: bool = await SceneRouter.change_location("LOC_UM_CONCOURSE")
	assert_false(refused)
	assert_true(SceneRouter.is_busy())
	assert_eq(SceneRouter.current_location_id, "", "nothing was loaded")
	SceneRouter.state = SceneRouter.State.IDLE
	var ok: bool = await SceneRouter.change_location("LOC_UM_CONCOURSE")
	assert_true(ok)

func test_broken_scene_keeps_current_location() -> void:
	await SceneRouter.change_location("LOC_UM_ECHO_STATION")
	var path := "user://broken_location.tscn"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("[gd_scene format=3]\n[node name=")
	f.close()
	var def := LocationDef.new()
	def.id = "LOC_ZZ_BROKEN"
	def.status = LocationDef.BuildStatus.BUILT
	def.scene_path = path
	DataRegistry.register_runtime(def)
	var failed := watch(EventBus.scene_transition_failed)
	var ok: bool = await SceneRouter.change_location("LOC_ZZ_BROKEN")
	assert_false(ok)
	assert_eq(failed.size(), 1)
	assert_eq(SceneRouter.current_location_id, "LOC_UM_ECHO_STATION")
	assert_false(InputService.is_locked())
	assert_eq(GameState.autosave_blocks, 0)
	assert_eq(SceneRouter.state, SceneRouter.State.IDLE)
	DataRegistry.reload()

func test_spawn_points() -> void:
	await SceneRouter.change_location("LOC_UM_ECHO_STATION")
	var root := SceneRouter.current_root as LocationRoot
	assert_eq(root.get_spawn_transform("default").origin, Vector3(0, 0.5, 0))
	var fallback := root.get_spawn_transform("does_not_exist")
	assert_eq(fallback.origin, Vector3(0, 0.5, 0), "falls back to default")
	assert_true(GameLog.warning_count > 0)

func test_interactable_effects_and_once() -> void:
	var i := Interactable.new()
	add_child(i)
	i.interactable_id = "INT_TEST_THING"
	i.give_clue = "CLUE_TEST_THING"
	i.set_flags.assign(["thing_examined"])
	i.once = true
	var seen := watch(EventBus.interaction_completed)
	i.interact()
	assert_true(GameState.has_clue("CLUE_TEST_THING"))
	assert_true(GameState.get_flag("thing_examined"))
	assert_eq(seen[0][0], "INT_TEST_THING")
	assert_false(i.can_interact(), "once: consumed")
	i.interact()
	assert_eq(seen.size(), 1)
	i.queue_free()

func test_interactable_conditions_block_use() -> void:
	var i := Interactable.new()
	add_child(i)
	i.give_item = "ITEM_ARCHIVE_CARD"
	i.conditions = ConditionSet.new()
	i.conditions.flags_all.assign(["unlocked"])
	i.interact()
	assert_false(GameState.has_item("ITEM_ARCHIVE_CARD"))
	GameState.set_flag("unlocked")
	i.interact()
	assert_true(GameState.has_item("ITEM_ARCHIVE_CARD"))
	i.queue_free()

func test_interactable_door_travels() -> void:
	await SceneRouter.change_location("LOC_UM_ECHO_STATION")
	var stairs := SceneRouter.current_root.get_node("StairsToConcourse") as Interactable
	stairs.interact()
	for i in 10:
		await get_tree().process_frame
	assert_eq(SceneRouter.current_location_id, "LOC_UM_CONCOURSE")

func test_sensor_prefers_priority_then_distance_and_cone() -> void:
	var sensor := InteractionSensor.new()
	add_child(sensor)
	sensor.global_position = Vector3.ZERO
	var near_ambient := _make_interactable(Vector3(0, 0, -1.0), Interactable.Priority.AMBIENT)
	var far_story := _make_interactable(Vector3(0, 0, -1.8), Interactable.Priority.STORY)
	var behind := _make_interactable(Vector3(0, 0, 1.0), Interactable.Priority.STORY)
	for c in [near_ambient, far_story, behind]:
		sensor._candidates.append(c)
	assert_eq(sensor._pick_best(), far_story, "story beats nearer ambient; object behind the player is outside the cone")
	far_story.enabled = false
	assert_eq(sensor._pick_best(), near_ambient)
	sensor.queue_free()
	for c in [near_ambient, far_story, behind]:
		c.queue_free()

func _make_interactable(pos: Vector3, prio: Interactable.Priority) -> Interactable:
	var i := Interactable.new()
	add_child(i)
	i.global_position = pos
	i.interact_priority = prio
	return i

func test_npc_actor_uses_character_data() -> void:
	var npc: NpcActor = load("res://scenes/characters/npc_base.tscn").instantiate()
	npc.character_id = "ARV"
	npc.dialogue_id = "DLG_CH1_M03_CATALOGUE"
	add_child(npc)
	var interactable := npc.get_node("Interactable") as Interactable
	assert_eq(interactable.start_dialogue, "DLG_CH1_M03_CATALOGUE")
	assert_eq(interactable.interactable_id, "INT_NPC_ARV")
	interactable.interact()
	assert_true(DialogueManager.is_active())
	DialogueManager.cancel()
	npc.queue_free()
