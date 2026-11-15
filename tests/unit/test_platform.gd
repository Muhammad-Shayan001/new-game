extends TestCase
## Settings, input abstraction, networking.

func before_each() -> void:
	super.before_each()
	SettingsManager.path = "user://test_settings.cfg"
	DirAccess.remove_absolute(SettingsManager.path)
	SettingsManager.load_settings()

func after_each() -> void:
	NetworkManager.leave()
	SettingsManager.reset_to_defaults()
	DirAccess.remove_absolute(SettingsManager.path)

# --- settings ----------------------------------------------------------------
func test_settings_defaults_and_clamping() -> void:
	assert_eq(SettingsManager.get_value("video", "fov"), 65.0)
	SettingsManager.set_value("video", "fov", 500.0)
	assert_eq(SettingsManager.get_value("video", "fov"), 80.0, "clamped to the allowed range")
	SettingsManager.set_value("video", "quality", "ultra")
	assert_eq(SettingsManager.get_value("video", "quality"), "medium", "invalid choice -> default")
	SettingsManager.set_value("audio", "master", "loud")
	assert_eq(SettingsManager.get_value("audio", "master"), 1.0, "wrong type -> default")

func test_settings_unknown_key_is_an_error_not_a_crash() -> void:
	assert_eq(SettingsManager.get_value("nope", "nothing"), null)
	SettingsManager.set_value("video", "nothing", 1)
	assert_true(GameLog.error_count >= 2)

func test_settings_save_load_and_events() -> void:
	var changed := watch(EventBus.settings_changed)
	SettingsManager.set_value("controls", "look_sensitivity", 1.75)
	SettingsManager.set_value("accessibility", "subtitle_size", 1.3)
	assert_eq(changed.size(), 2)
	assert_true(SettingsManager.save_settings())
	SettingsManager.reset_to_defaults()
	assert_eq(SettingsManager.get_value("controls", "look_sensitivity"), 1.0)
	SettingsManager.load_settings()
	assert_eq(SettingsManager.get_value("controls", "look_sensitivity"), 1.75)
	assert_eq(SettingsManager.get_value("accessibility", "subtitle_size"), 1.3)

func test_hand_edited_settings_file_cannot_break_the_game() -> void:
	var f := FileAccess.open(SettingsManager.path, FileAccess.WRITE)
	f.store_string("[video]\nfov=9999.0\nquality=\"banana\"\n[audio]\nmaster=-4.0\n")
	f.close()
	SettingsManager.load_settings()
	assert_eq(SettingsManager.get_value("video", "fov"), 80.0)
	assert_eq(SettingsManager.get_value("video", "quality"), "medium")
	assert_eq(SettingsManager.get_value("audio", "master"), 0.0)

func test_settings_are_applied_to_the_engine() -> void:
	SettingsManager.set_value("video", "fps_cap", 30)
	assert_eq(Engine.max_fps, 30)
	SettingsManager.set_value("video", "fps_cap", 60)
	SettingsManager.set_value("audio", "music", 0.0)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	SettingsManager.set_value("audio", "music", 0.5)
	assert_false(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))

# --- input -------------------------------------------------------------------
func test_every_action_is_registered_with_events() -> void:
	for action in InputActions.ALL:
		assert_true(InputMap.has_action(action), "missing action %s" % action)
		assert_true(InputMap.action_get_events(action).size() >= 2, "%s needs keyboard and gamepad" % action)
	assert_eq(InputActions.ability_action(3), &"ability_3")

func test_input_locks_are_counted_by_reason() -> void:
	var changes := watch(EventBus.input_lock_changed)
	InputService.push_lock("dialogue")
	InputService.push_lock("transition")
	assert_true(InputService.is_locked())
	InputService.pop_lock("dialogue")
	assert_true(InputService.is_locked(), "still locked by the transition")
	InputService.pop_lock("transition")
	assert_false(InputService.is_locked())
	assert_eq(changes.size(), 2, "only the first lock and the last unlock are announced")

func test_virtual_stick_and_locking() -> void:
	InputService.set_virtual_move(Vector2(0.5, -1.0))
	assert_true(InputService.get_move_vector().length() <= 1.0)
	assert_true(InputService.get_move_vector().x > 0.0)
	InputService.push_lock("test")
	assert_eq(InputService.get_move_vector(), Vector2.ZERO)
	InputService.pop_lock("test")
	InputService.set_virtual_move(Vector2.ZERO)

func test_device_detection() -> void:
	var changes := watch(EventBus.input_device_changed)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	InputService._input(touch)
	assert_eq(InputService.device, "touch")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_E
	InputService._input(key)
	assert_eq(InputService.device, "keyboard_mouse")
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	InputService._input(pad)
	assert_eq(InputService.device, "gamepad")
	assert_eq(changes.size(), 3)
	InputService.release_touch(0)

func test_touch_drag_on_the_right_side_becomes_camera_look() -> void:
	var size := get_viewport().get_visible_rect().size
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.pressed = true
	press.position = Vector2(size.x * 0.8, size.y * 0.5)
	InputService._input(press)
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.relative = Vector2(25, -10)
	InputService._input(drag)
	var look := InputService.consume_look_delta()
	assert_true(look.x > 0.0 and look.y < 0.0)
	assert_eq(InputService.consume_look_delta(), Vector2.ZERO, "consumed")
	# A finger that belongs to the joystick never rotates the camera.
	InputService.claim_touch(8)
	var press2 := InputEventScreenTouch.new()
	press2.index = 8
	press2.pressed = true
	press2.position = Vector2(size.x * 0.9, size.y * 0.5)
	InputService._input(press2)
	var drag2 := InputEventScreenDrag.new()
	drag2.index = 8
	drag2.relative = Vector2(50, 0)
	InputService._input(drag2)
	assert_eq(InputService.consume_look_delta(), Vector2.ZERO)
	InputService.release_touch(8)
	var up := InputEventScreenTouch.new()
	up.index = 7
	up.pressed = false
	InputService._input(up)

# --- networking ----------------------------------------------------------------
func test_offline_is_always_authority() -> void:
	assert_false(NetworkManager.is_online())
	assert_true(NetworkManager.is_authority(), "offline play behaves like the host")

func test_host_and_leave() -> void:
	var states := watch(EventBus.network_state_changed)
	assert_eq(NetworkManager.host(47781), OK)
	assert_eq(NetworkManager.state, NetworkManager.State.HOSTING)
	assert_true(NetworkManager.is_authority())
	assert_eq(NetworkManager.host(47782), ERR_ALREADY_IN_USE)
	assert_eq(NetworkManager.join("127.0.0.1", 47781), ERR_ALREADY_IN_USE)
	NetworkManager.leave()
	assert_eq(NetworkManager.state, NetworkManager.State.OFFLINE)
	assert_eq(states.size(), 2)

func test_invalid_network_arguments() -> void:
	assert_eq(NetworkManager.host(80), ERR_INVALID_PARAMETER)
	assert_eq(NetworkManager.join("", 7777), ERR_INVALID_PARAMETER)
	assert_eq(NetworkManager.join("127.0.0.1", 70000), ERR_INVALID_PARAMETER)
	assert_false(NetworkManager.is_online())
