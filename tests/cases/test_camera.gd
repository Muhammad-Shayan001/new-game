extends "res://tests/test_case.gd"
## Camera rig: follow, orbit + sensitivity, pitch limits, collision/obstruction, presets, cinematic.

var root: Node

func _arena() -> void:
	root = await start_game_at("LOC_DEV_TEST_ARENA")
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 12.0)))
	await physics(30)

func test_follows_the_player_smoothly() -> void:
	await _arena()
	var r := rig()
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(20)
	var lag := r.global_position.distance_to(player().global_position + Vector3(0, 1.55, 0))
	ok(lag > 0.02, "camera target trails slightly (smoothing), lag %.2f" % lag)
	InputRouter.set_virtual_move(Vector2.ZERO)
	await physics(120)
	near(r.global_position.distance_to(player().global_position + Vector3(0, 1.55, 0)), 0.0, 0.1, "settles on the player")
	await end_game(root)

func test_orbit_look_and_pitch_clamp() -> void:
	await _arena()
	var r := rig()
	var y0 := r._yaw_goal
	InputRouter.add_virtual_look(Vector2(200, 0))
	await physics(30)
	ok(r._yaw_goal < y0, "dragging right turns the camera right")
	ok(absf(angle_difference(r.yaw, r._yaw_goal)) < 0.05, "smoothed yaw catches up")
	InputRouter.add_virtual_look(Vector2(0, 5000))       # absurd downward drag
	await physics(30)
	ok(r.pitch >= r._pitch_min - 0.01, "pitch clamped at the floor limit")
	InputRouter.add_virtual_look(Vector2(0, -50000))
	await physics(30)
	ok(r.pitch <= r._pitch_max + 0.01, "pitch clamped at the ceiling limit")
	await end_game(root)

func test_sensitivity_setting_scales_rotation() -> void:
	await _arena()
	var r := rig()
	r._yaw_goal = 0.0
	Settings.set_value("camera_sensitivity", 1.0, false)
	InputRouter.add_virtual_look(Vector2(100, 0))
	await physics(2)
	var low := absf(r._yaw_goal)
	r._yaw_goal = 0.0
	Settings.set_value("camera_sensitivity", 2.0, false)
	InputRouter.add_virtual_look(Vector2(100, 0))
	await physics(2)
	var high := absf(r._yaw_goal)
	near(high / low, 2.0, 0.15, "double sensitivity = double rotation")
	await end_game(root)

func test_invert_y() -> void:
	await _arena()
	var r := rig()
	r._pitch_goal = deg_to_rad(-20)
	InputRouter.add_virtual_look(Vector2(0, 40))
	await physics(2)
	var normal := r._pitch_goal
	r._pitch_goal = deg_to_rad(-20)
	Settings.set_value("invert_y", true, false)
	InputRouter.add_virtual_look(Vector2(0, 40))
	await physics(2)
	ok(r._pitch_goal > deg_to_rad(-20) and normal < deg_to_rad(-20), "inverted pitch goes the other way")
	await end_game(root)

func test_look_ignored_while_locked() -> void:
	await _arena()
	var r := rig()
	var y0 := r._yaw_goal
	InputRouter.push_lock("dialogue")
	InputRouter.add_virtual_look(Vector2(300, 0))
	await physics(10)
	near(r._yaw_goal, y0, 0.001, "camera does not orbit during dialogue")
	await end_game(root)

func test_collision_pulls_camera_in_front_of_obstacle() -> void:
	await _arena()
	var r := rig()
	near(r.current_distance, 4.6, 0.2, "normal distance in the open")
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 6, 0.5)
	cs.shape = box
	wall.add_child(cs)
	SceneManager.current_location_node.add_child(wall)
	wall.global_position = player().global_position + Vector3(0, 1.5, 2.0)      # behind the player (camera is at +Z)
	await physics(10)
	ok(r.current_distance < 2.3, "camera moved in front of the wall (%.2f)" % r.current_distance)
	ok(r.camera.global_position.z < wall.global_position.z, "camera is on the player's side of the wall")
	wall.queue_free()
	await physics(5)
	var just_after := r.current_distance
	await physics(150)
	ok(r.current_distance > just_after + 1.0, "eases back out (no pop): %.2f -> %.2f" % [just_after, r.current_distance])
	near(r.current_distance, 4.6, 0.3, "fully restored")
	await end_game(root)

func test_camera_inside_body_hides_player_mesh() -> void:
	await _arena()
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 6, 0.2)
	cs.shape = box
	wall.add_child(cs)
	SceneManager.current_location_node.add_child(wall)
	wall.global_position = player().global_position + Vector3(0, 1.5, 0.75)
	await physics(10)
	ok(not player().visual.visible, "body hidden when the camera is jammed against the player")
	wall.queue_free()
	await physics(150)
	ok(player().visual.visible, "body visible again")
	await end_game(root)

func test_indoor_zone_changes_preset() -> void:
	await _arena()
	var r := rig()
	near(r.camera.fov, 65.0, 1.0, "outdoor fov")
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(-18, 0.1, 12)))
	await physics(150)
	near(r.camera.fov, 72.0, 1.0, "indoor fov")
	near(r.arm.spring_length, 2.7, 0.2, "indoor distance")
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 12)))
	await physics(150)
	near(r.camera.fov, 65.0, 1.0, "back to outdoor fov")
	near(r.arm.spring_length, 4.6, 0.2, "back to outdoor distance")
	await end_game(root)

func test_interior_location_type_uses_indoor_preset() -> void:
	root = await start_game_at("LOC_EC_APT_BLDG")        # type: interior
	await physics(150)
	near(rig().camera.fov, 72.0, 1.0, "interior locations use the indoor camera")
	await end_game(root)

func test_cinematic_takeover_and_release() -> void:
	await _arena()
	var r := rig()
	Settings.set_value("reduced_motion", false, false)
	var shot := Transform3D(Basis.IDENTITY, Vector3(5, 8, -5))
	r.begin_cinematic(shot, 40.0, 0.3)
	ok(r.is_cinematic(), "cinematic active")
	ok(InputRouter.is_locked(), "player input locked during cinematic")
	await physics(40)
	near(r.camera.global_position.distance_to(shot.origin), 0.0, 0.2, "camera reached the shot")
	near(r.camera.fov, 40.0, 0.5, "fov applied")
	r.cinematic_cut(Transform3D(Basis.IDENTITY, Vector3(-5, 3, 5)), 55.0)
	near(r.camera.global_position.x, -5.0, 0.01, "hard cut works")
	await r.end_cinematic(0.3)
	ok(not r.is_cinematic(), "cinematic over")
	ok(not InputRouter.is_locked(), "input released")
	ok(r.camera.get_parent() == r.arm, "camera reattached to the spring arm")
	await physics(30)
	near(r.camera.fov, 65.0, 1.5, "fov restored")
	await end_game(root)

func test_trauma_shake_respects_reduced_motion() -> void:
	await _arena()
	var r := rig()
	Settings.set_value("reduced_motion", true, false)
	r.add_trauma(1.0)
	ok(r._trauma == 0.0, "no shake when reduced motion is on")
	Settings.set_value("reduced_motion", false, false)
	r.add_trauma(0.8)
	ok(r._trauma > 0.0, "shake accumulates normally")
	await end_game(root)

func test_auto_recenter_swings_behind_moving_player() -> void:
	await _arena()
	var r := rig()
	r._yaw_goal = 0.0
	r.yaw = 0.0
	InputRouter.set_virtual_move(Vector2(1, 0))             # strafing right: travel direction is -90 degrees from the camera
	await physics(240)
	ok(absf(angle_difference(r._yaw_goal, 0.0)) > 0.4, "camera swings toward the travel direction (yaw %.2f)" % r._yaw_goal)
	await end_game(root)

func test_no_recenter_when_looking_or_still() -> void:
	await _arena()
	var r := rig()
	r._yaw_goal = 0.0
	await physics(200)
	near(r._yaw_goal, 0.0, 0.001, "stationary player: camera does not drift")
	await end_game(root)
