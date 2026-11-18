extends "res://tests/test_case.gd"
## Android input path: floating joystick, camera pad, buttons, left-handed layout, multi-touch.
## Events are injected exactly as Godot delivers screen events to Controls.

var root: Node
var hud: CanvasLayer

func _setup() -> void:
	Settings.set_value("touch_controls", "on", false)
	root = await start_game_at("LOC_DEV_TEST_ARENA")
	hud = root.get_node("HUD")
	player().teleport(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 12.0)))
	await physics(20)

func _touch(ctrl: Control, index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	ctrl._gui_input(e)

func _drag(ctrl: Control, index: int, pos: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	e.relative = rel
	ctrl._gui_input(e)

func test_hud_builds_all_touch_controls() -> void:
	await _setup()
	ok(hud.joystick != null and hud.look_pad != null, "joystick and camera pad")
	ok(hud.interact_button != null and hud.sprint_button != null and hud.ability_button != null and hud.pause_button != null, "buttons")
	ok(hud._controls.visible, "touch controls visible when touch UI is on")
	for b in [hud.interact_button, hud.sprint_button, hud.ability_button]:
		ok(b.size.x >= 96 and b.size.y >= 96, "%s hit target >= 96px (%s)" % [b.name, str(b.size)])
	ok(hud.pause_button.size.x >= 70, "pause button size")
	await end_game(root)

func test_floating_joystick_drives_player() -> void:
	await _setup()
	var js: TouchJoystick = hud.joystick
	_touch(js, 0, Vector2(200, 500), true)
	_drag(js, 0, Vector2(200, 400), Vector2(0, -100))           # thumb up = forward
	near(js.output.y, -1.0, 0.01, "full deflection forward")
	var z0 := player().global_position.z
	await physics(60)
	ok(player().global_position.z < z0 - 2.0, "player ran forward from joystick input")
	_touch(js, 0, Vector2(200, 400), false)
	eq(js.output, Vector2.ZERO, "release zeroes output")
	await physics(40)
	near(player().horizontal_speed(), 0.0, 0.05, "player stops")
	await end_game(root)

func test_joystick_dead_zone_and_proportional_output() -> void:
	await _setup()
	var js: TouchJoystick = hud.joystick
	_touch(js, 0, Vector2(200, 500), true)
	_drag(js, 0, Vector2(200 + 5, 500), Vector2(5, 0))
	eq(js.output, Vector2.ZERO, "tiny thumb jitter ignored (dead zone)")
	_drag(js, 0, Vector2(200 + 45, 500), Vector2(40, 0))
	ok(js.output.x > 0.2 and js.output.x < 0.8, "half deflection is proportional (%.2f)" % js.output.x)
	_drag(js, 0, Vector2(200 + 500, 500), Vector2(455, 0))
	near(js.output.length(), 1.0, 0.001, "output capped at 1")
	_touch(js, 0, Vector2(700, 500), false)
	await end_game(root)

func test_joystick_ignores_second_finger() -> void:
	await _setup()
	var js: TouchJoystick = hud.joystick
	_touch(js, 0, Vector2(200, 500), true)
	_touch(js, 1, Vector2(300, 500), true)
	_drag(js, 1, Vector2(300, 400), Vector2(0, -100))
	eq(js.output, Vector2.ZERO, "second finger does not steer")
	_touch(js, 1, Vector2(300, 400), false)
	ok(js.is_active(), "releasing the second finger keeps the joystick active")
	_touch(js, 0, Vector2(200, 500), false)
	await end_game(root)

func test_camera_pad_rotates_camera() -> void:
	await _setup()
	var pad: TouchLookPad = hud.look_pad
	var y0 := rig()._yaw_goal
	_touch(pad, 0, Vector2(900, 300), true)
	_drag(pad, 0, Vector2(960, 300), Vector2(60, 0))
	await physics(3)
	ok(rig()._yaw_goal < y0 - 0.1, "dragging right rotates the camera (%.3f -> %.3f)" % [y0, rig()._yaw_goal])
	_touch(pad, 0, Vector2(960, 300), false)
	await end_game(root)

func test_move_and_look_simultaneously_multitouch() -> void:
	await _setup()
	var js: TouchJoystick = hud.joystick
	var pad: TouchLookPad = hud.look_pad
	var y0 := rig()._yaw_goal
	_touch(js, 0, Vector2(200, 500), true)
	_drag(js, 0, Vector2(200, 420), Vector2(0, -80))
	_touch(pad, 1, Vector2(900, 300), true)
	for i in 10:
		_drag(pad, 1, Vector2(900 + i * 8, 300), Vector2(8, 0))
		await physics(1)
	ok(js.output.y < -0.5, "still moving while looking")
	ok(rig()._yaw_goal < y0 - 0.1, "camera rotated while moving")
	_touch(js, 0, Vector2(200, 420), false)
	_touch(pad, 1, Vector2(980, 300), false)
	await end_game(root)

func test_interact_button_triggers_interaction() -> void:
	await _setup()
	var lever := find_interactable("INT_TEST_LEVER")
	await place_near(lever)
	ok(hud.interact_button.highlighted, "button highlights when something is interactable")
	_touch(hud.interact_button, 0, Vector2(1000, 600), true)
	await physics(2)
	_touch(hud.interact_button, 0, Vector2(1000, 600), false)
	await physics(2)
	ok(GameState.get_flag("test_door_open"), "tapping the on-screen button used the lever")
	await end_game(root)

func test_sprint_button_hold_and_toggle() -> void:
	await _setup()
	var b: TouchButton = hud.sprint_button
	_touch(b, 0, Vector2(1000, 600), true)
	ok(Input.is_action_pressed("sprint"), "hold: pressed")
	_touch(b, 0, Vector2(1000, 600), false)
	ok(not Input.is_action_pressed("sprint"), "hold: released")
	b.toggle_mode = true
	_touch(b, 0, Vector2(1000, 600), true)
	_touch(b, 0, Vector2(1000, 600), false)
	ok(Input.is_action_pressed("sprint"), "toggle: stays latched after lifting finger")
	_touch(b, 0, Vector2(1000, 600), true)
	_touch(b, 0, Vector2(1000, 600), false)
	ok(not Input.is_action_pressed("sprint"), "toggle: second tap releases")
	await end_game(root)

func test_pause_button_requests_pause() -> void:
	await _setup()
	var got := [0]
	EventBus.pause_requested.connect(func(): got[0] += 1)
	_touch(hud.pause_button, 0, Vector2(1200, 60), true)
	_touch(hud.pause_button, 0, Vector2(1200, 60), false)
	eq(got[0], 1, "pause requested once")
	ok(tree.paused, "pause menu paused the game")
	root.get_node("PauseMenu").toggle()
	ok(not tree.paused, "second toggle resumes")
	await end_game(root)

func test_context_ability_button_activates_ability() -> void:
	await _setup()
	ok(AbilityManager.is_unlocked("ABL_MEMORY_SIGHT"), "memory sight unlocked by CH1_M01")
	hud._refresh_ability()
	ok(hud.ability_button.visible, "ability button visible once an ability is unlocked")
	_touch(hud.ability_button, 0, Vector2(1100, 400), true)
	await physics(3)
	_touch(hud.ability_button, 0, Vector2(1100, 400), false)
	eq(AbilityManager.active_id, "ABL_MEMORY_SIGHT", "button activated the contextual ability")
	AbilityManager.end_active()
	await end_game(root)

func test_left_handed_layout_mirrors() -> void:
	await _setup()
	var right_x: float = hud.look_pad.position.x
	var move_x: float = hud.joystick.position.x
	ok(right_x > move_x, "default: move on the left, look on the right")
	Settings.set_value("left_handed", true, false)
	await frames(2)
	ok(hud.look_pad.position.x < hud.joystick.position.x, "left-handed: move on the right, look on the left")
	ok(hud.interact_button.position.x < 640, "interact button moves to the left side")
	await end_game(root)

func test_touch_ui_hidden_on_desktop_default() -> void:
	Settings.set_value("touch_controls", "off", false)
	root = await start_game_at("LOC_DEV_TEST_ARENA")
	await frames(2)
	ok(not root.get_node("HUD")._controls.visible, "controls hidden when touch UI is off")
	await end_game(root)

func test_layout_fits_common_phone_aspect_ratios() -> void:
	await _setup()
	for sz in [Vector2(1280, 720), Vector2(1280, 590), Vector2(960, 720), Vector2(1560, 720)]:
		for lefty in [false, true]:
			Settings.set_value("left_handed", lefty, false)
			hud._layout(sz)
			for b in [hud.interact_button, hud.sprint_button, hud.ability_button, hud.pause_button]:
				var r := Rect2(b.position, b.size)
				ok(Rect2(Vector2.ZERO, sz).encloses(r), "%s fits at %s (left-handed=%s): %s" % [b.name, str(sz), str(lefty), str(r)])
			var overlap := Rect2(hud.interact_button.position, hud.interact_button.size).intersects(Rect2(hud.sprint_button.position, hud.sprint_button.size))
			ok(not overlap, "interact and sprint buttons do not overlap at %s" % str(sz))
	await end_game(root)
