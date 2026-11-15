extends TestCase
## Integration: the real game scene boots, spawns the player, and interaction works
## through the physics engine.

var root_scene: Node

func after_each() -> void:
	get_tree().paused = false
	Input.action_release("interact")
	if root_scene != null:
		root_scene.queue_free()
		root_scene = null
		await get_tree().process_frame

func _wait_until(condition: Callable, max_frames: int = 180) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await get_tree().physics_frame
	return false

func _boot() -> GameRoot:
	SceneRouter.state = SceneRouter.State.IDLE
	SceneRouter.current_root = null
	SceneRouter.current_location_id = ""
	var scene: GameRoot = load("res://scenes/game_root.tscn").instantiate()
	root_scene = scene
	add_child(scene)
	await _wait_until(func(): return SceneRouter.current_location_id != "" and not SceneRouter.is_busy())
	return scene

func test_new_game_boots_into_echo_station() -> void:
	var game := await _boot()
	assert_eq(SceneRouter.current_location_id, "LOC_UM_ECHO_STATION")
	assert_true(GameState.get_flag("ch1_started"))
	assert_eq(MissionManager.tracked_mission(), "CH1_M01")
	var player := game.get_node("Player") as Player
	assert_true(player.global_position.distance_to(Vector3(0, 0.5, 0)) < 0.1, "player at the spawn point")
	assert_true(get_tree().get_first_node_in_group("camera_rig") != null)
	assert_true(FileAccess.file_exists(SaveManager.slot_path(0)), "room transition autosaved")

func test_player_walks_with_virtual_stick_and_stops_when_locked() -> void:
	var game := await _boot()
	var player := game.get_node("Player") as Player
	await get_tree().physics_frame
	var start := player.global_position
	InputService.set_virtual_move(Vector2(0, -1))
	for i in 30:
		await get_tree().physics_frame
	var moved := player.global_position.distance_to(start)
	assert_true(moved > 1.0, "moved %s m in half a second at run speed" % moved)
	InputService.push_lock("test")
	var locked_at := player.global_position
	for i in 10:
		await get_tree().physics_frame
	assert_true(player.global_position.distance_to(locked_at) < 0.2, "locked input stops the player")
	InputService.pop_lock("test")
	InputService.set_virtual_move(Vector2.ZERO)

func test_interaction_through_physics() -> void:
	var game := await _boot()
	var player := game.get_node("Player") as Player
	player.place_at(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, -1.6)))   # faces -Z, clock is at z = -3
	var sensor := player.get_node("InteractionSensor") as InteractionSensor
	var found := await _wait_until(func(): return sensor.current_target() != null)
	assert_true(found, "sensor sees the station clock")
	assert_eq(sensor.current_target().interactable_id, "INT_UM_ECHO_STATION_CLOCK")
	Input.action_press("interact")
	var got_clue := await _wait_until(func(): return GameState.has_clue("CLUE_STATION_CLOCK"))
	Input.action_release("interact")
	assert_true(got_clue, "pressing interact examines the clock")

func test_walk_through_a_door_to_the_next_location() -> void:
	var game := await _boot()
	var player := game.get_node("Player") as Player
	player.place_at(Transform3D(Basis.from_euler(Vector3(0, -PI / 2.0, 0)), Vector3(6.4, 0.1, 0)))   # facing +X
	var sensor := player.get_node("InteractionSensor") as InteractionSensor
	await _wait_until(func(): return sensor.current_target() != null)
	assert_eq(sensor.current_target().interactable_id, "INT_UM_ECHO_STATION_STAIRS")
	Input.action_press("interact")
	var arrived := await _wait_until(func(): return SceneRouter.current_location_id == "LOC_UM_CONCOURSE", 240)
	Input.action_release("interact")
	assert_true(arrived)
	assert_eq(MissionManager.get_progress("CH1_M01", "reach_um_concourse"), 1)

func test_pause_locks_input_and_resumes() -> void:
	await _boot()
	EventBus.pause_requested.emit(true)
	assert_true(get_tree().paused)
	assert_true(InputService.is_locked())
	EventBus.pause_requested.emit(false)
	assert_false(get_tree().paused)
	assert_false(InputService.is_locked())

func test_out_of_bounds_respawn() -> void:
	var game := await _boot()
	var player := game.get_node("Player") as Player
	player.global_position = Vector3(0, -100, 0)
	await _wait_until(func(): return player.global_position.y > -1.0, 10)
	assert_true(player.global_position.distance_to(Vector3(0, 0.5, 0)) < 0.5)

func test_camera_cinematic_override_blends_and_returns() -> void:
	var game := await _boot()
	var rig := game.get_node("CameraRig") as CameraRig
	var marker := Node3D.new()
	add_child(marker)
	marker.global_position = Vector3(10, 5, 10)
	var cam := rig.get_node("Pitch/Arm/Camera3D") as Camera3D
	rig.push_override(marker, 0.2)
	await get_tree().create_timer(0.5).timeout     # real time: the blend is time based
	assert_true(cam.global_position.distance_to(marker.global_position) < 0.1, "reached the framing")
	rig.pop_override(0.2)
	await get_tree().create_timer(0.5).timeout
	assert_false(rig.is_overridden())
	assert_false(cam.top_level)
	marker.queue_free()

func test_continue_loads_autosave() -> void:
	GameState.set_chapter(1)
	GameState.set_flag("ch1_started")
	GameState.enter_location("LOC_UM_CONCOURSE", "default")
	GameState.set_flag("from_autosave")
	SaveManager.save_game(0)
	GameState.reset()
	await _boot()
	assert_true(GameState.get_flag("from_autosave"))
	assert_eq(SceneRouter.current_location_id, "LOC_UM_CONCOURSE", "resumes where the player left off")
