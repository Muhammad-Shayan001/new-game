extends "res://tests/test_case.gd"
## Player controller: walk / run / sprint, acceleration, deceleration, camera-relative movement,
## turning, collision, input locks and animation blending. Runs in the dev test arena.

var root: Node

func _arena() -> void:
	root = await start_game_at("LOC_DEV_TEST_ARENA")
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 12.0)))
	await physics(10)

func test_settles_on_floor() -> void:
	await _arena()
	ok(player().is_on_floor(), "standing on the floor")
	near(player().global_position.y, 0.0, 0.2, "feet at floor level")
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(0, 6.0, 12.0)))
	await physics(90)
	ok(player().is_on_floor(), "falls and lands")
	await end_game(root)

func test_run_acceleration_and_deceleration() -> void:
	await _arena()
	var p := player()
	var z0 := p.global_position.z
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(3)
	var early := p.horizontal_speed()
	ok(early > 0.5 and early < p.run_speed - 0.3, "accelerates gradually (%.2f m/s after 3 frames)" % early)
	await physics(60)
	near(p.horizontal_speed(), p.run_speed, 0.25, "reaches run speed")
	ok(p.global_position.z < z0 - 2.5, "moved forward (-Z) with the default camera")
	eq(p.state, "run", "state is run")
	InputRouter.set_virtual_move(Vector2.ZERO)
	await physics(1)
	ok(p.horizontal_speed() > 0.5, "does not stop instantly")
	await physics(40)
	near(p.horizontal_speed(), 0.0, 0.05, "decelerates to a stop")
	eq(p.state, "idle", "state returns to idle")
	await end_game(root)

func test_walk_is_slower_than_run_and_scales_with_stick() -> void:
	await _arena()
	var p := player()
	InputRouter.set_virtual_move(Vector2(0, -0.4))
	await physics(40)
	var walk := p.horizontal_speed()
	ok(walk < p.walk_speed + 0.1 and walk > 0.9, "gentle stick = walking (%.2f)" % walk)
	eq(p.state, "walk", "walk state")
	InputRouter.set_virtual_move(Vector2(0, -0.2))
	await physics(40)
	ok(p.horizontal_speed() < walk, "smaller deflection = slower")
	await end_game(root)

func test_sprint() -> void:
	await _arena()
	var p := player()
	InputRouter.set_virtual_move(Vector2(0, -1))
	Input.action_press("sprint")
	await physics(60)
	near(p.horizontal_speed(), p.sprint_speed, 0.35, "sprint speed")
	eq(p.state, "sprint", "sprint state")
	Input.action_release("sprint")
	await physics(60)
	near(p.horizontal_speed(), p.run_speed, 0.3, "back to run when released")
	await end_game(root)

func test_sprint_toggle_setting_path() -> void:
	await _arena()
	var p := player()
	p.sprint_toggled = true
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(60)
	eq(p.state, "sprint", "latched sprint works without holding")
	await end_game(root)

func test_sprint_needs_movement() -> void:
	await _arena()
	Input.action_press("sprint")
	await physics(20)
	eq(player().state, "idle", "sprint alone does not move")
	Input.action_release("sprint")
	await end_game(root)

func test_movement_is_camera_relative() -> void:
	await _arena()
	var p := player()
	var r := rig()
	r.yaw = PI / 2.0
	r._yaw_goal = PI / 2.0
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(40)
	ok(p.velocity.x < -3.0, "forward with camera turned 90 degrees moves along -X (vx=%.2f)" % p.velocity.x)
	near(p.velocity.z, 0.0, 0.8, "no sideways drift")
	await end_game(root)

func test_character_turns_toward_motion() -> void:
	await _arena()
	var p := player()
	rig().yaw = PI / 2.0
	rig()._yaw_goal = PI / 2.0
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(8)
	var early := absf(angle_difference(p.visual.rotation.y, PI / 2.0))
	await physics(50)
	var late := absf(angle_difference(p.visual.rotation.y, PI / 2.0))
	ok(late < early, "turn is smoothed, not instant")
	ok(late < 0.2, "ends facing the direction of travel (error %.2f rad)" % late)
	await end_game(root)

func test_collision_with_boundary_wall() -> void:
	await _arena()
	var p := player()
	p.teleport(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 26.0)))
	InputRouter.set_virtual_move(Vector2(0, 1))      # toward +Z, camera yaw 0 => backwards
	await physics(150)
	ok(p.global_position.z < 27.5, "stopped by the south wall (z=%.2f)" % p.global_position.z)
	await end_game(root)

func test_collision_with_pillar() -> void:
	await _arena()
	var p := player()
	p.teleport(Transform3D(Basis.IDENTITY, Vector3(-3.0, 0.1, -3.5)))     # pillar at (-3, 1.5, -6)
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(120)
	ok(p.global_position.z > -5.25 and p.global_position.z < -4.8, "stops at the pillar face (pillar face -5.4 + radius 0.3) (z=%.2f)" % p.global_position.z)
	await end_game(root)

func test_slides_along_walls_instead_of_sticking() -> void:
	await _arena()
	var p := player()
	p.teleport(Transform3D(Basis.IDENTITY, Vector3(-27.0, 0.1, 0.0)))
	InputRouter.set_virtual_move(Vector2(-1, -1).normalized())     # into the west wall at an angle
	await physics(60)
	ok(p.global_position.z < -2.0, "keeps sliding along the wall (z=%.2f)" % p.global_position.z)
	await end_game(root)

func test_input_lock_stops_player() -> void:
	await _arena()
	var p := player()
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(30)
	InputRouter.push_lock("dialogue")
	await physics(40)
	near(p.horizontal_speed(), 0.0, 0.05, "locked = stopped")
	InputRouter.pop_lock("dialogue")
	await physics(30)
	ok(p.horizontal_speed() > 2.0, "moves again when unlocked")
	await end_game(root)

func test_target_speed_function() -> void:
	await _arena()
	var p := player()
	eq(p._target_speed(0.0, false), 0.0, "no input")
	eq(p._target_speed(1.0, true), p.sprint_speed, "sprint")
	eq(p._target_speed(1.0, false), p.run_speed, "full stick")
	ok(p._target_speed(0.3, false) < p.walk_speed, "light stick below walk")
	ok(p._target_speed(0.8, false) > p.walk_speed and p._target_speed(0.8, false) < p.run_speed, "between")
	await end_game(root)

# ------------------------------------------------------------------ animation
func test_animation_tree_blends_with_speed() -> void:
	await _arena()
	var a := player().get_node("Animator") as PlayerAnimator
	ok(a.anim_tree.active, "AnimationTree active")
	for clip in ["idle", "walk", "run", "sprint", "interact"]:
		ok(a.anim_player.has_animation(clip), "clip '%s' exists" % clip)
	await physics(30)
	near(a.blend_position, 0.0, 0.1, "idle blend at rest")
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(80)
	near(a.blend_position, 2.0, 0.35, "run blend while running")
	Input.action_press("sprint")
	await physics(60)
	ok(a.blend_position > 2.6, "sprint blend (%.2f)" % a.blend_position)
	Input.action_release("sprint")
	InputRouter.set_virtual_move(Vector2.ZERO)
	await physics(90)
	near(a.blend_position, 0.0, 0.15, "back to idle")
	await end_game(root)

func test_blend_mapping_is_monotonic() -> void:
	await _arena()
	var p := player()
	var a := p.get_node("Animator") as PlayerAnimator
	var last := -1.0
	for s in [0.0, 0.5, p.walk_speed, 3.0, p.run_speed, 5.0, p.sprint_speed]:
		var b := a.blend_for_speed(s, p)
		ok(b >= last, "blend never decreases (speed %.1f -> %.2f)" % [s, b])
		last = b
	near(a.blend_for_speed(p.walk_speed, p), 1.0, 0.01, "walk = 1")
	near(a.blend_for_speed(p.run_speed, p), 2.0, 0.01, "run = 2")
	near(a.blend_for_speed(p.sprint_speed, p), 3.0, 0.01, "sprint = 3")
	await end_game(root)

func test_footsteps_fire_while_moving() -> void:
	await _arena()
	var a := player().get_node("Animator") as PlayerAnimator
	var steps := [0]
	a.footstep.connect(func(_s): steps[0] += 1)
	await physics(30)
	eq(steps[0], 0, "no footsteps when idle")
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(90)
	ok(steps[0] >= 3, "footsteps while running (%d)" % steps[0])
	await end_game(root)

func test_reduced_motion_snaps_animation() -> void:
	await _arena()
	Settings.set_value("reduced_motion", true, false)
	var a := player().get_node("Animator") as PlayerAnimator
	InputRouter.set_virtual_move(Vector2(0, -1))
	await physics(70)
	ok(a.blend_position > 1.5, "blend still correct with reduced motion")
	await end_game(root)
