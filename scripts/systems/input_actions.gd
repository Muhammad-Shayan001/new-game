class_name InputActions
extends RefCounted
## The ONLY place action names are spelled. Gameplay code uses these constants
## (through InputService) and never checks keys, mouse or touch directly.

const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_FORWARD := &"move_forward"
const MOVE_BACK := &"move_back"
const LOOK_LEFT := &"look_left"
const LOOK_RIGHT := &"look_right"
const LOOK_UP := &"look_up"
const LOOK_DOWN := &"look_down"
const INTERACT := &"interact"
const MEMORY_PULSE := &"memory_pulse"
const ABILITY_1 := &"ability_1"
const ABILITY_2 := &"ability_2"
const ABILITY_3 := &"ability_3"
const ABILITY_4 := &"ability_4"
const PAUSE := &"pause"
const JOURNAL := &"journal"

const ALL: Array[StringName] = [
	MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK, LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN,
	INTERACT, MEMORY_PULSE, ABILITY_1, ABILITY_2, ABILITY_3, ABILITY_4, PAUSE, JOURNAL,
]

static func ability_action(slot: int) -> StringName:
	return StringName("ability_%d" % slot)

static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

static func _button(index: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = index
	return e

static func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e

## Default bindings: keyboard + gamepad. Touch uses TouchActionButton / TouchJoystick,
## which feed the same actions. Mouse look is handled by InputService.
static func default_bindings() -> Dictionary:
	return {
		MOVE_LEFT: [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0)],
		MOVE_RIGHT: [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0)],
		MOVE_FORWARD: [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)],
		MOVE_BACK: [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0)],
		LOOK_LEFT: [_key(KEY_LEFT), _axis(JOY_AXIS_RIGHT_X, -1.0)],
		LOOK_RIGHT: [_key(KEY_RIGHT), _axis(JOY_AXIS_RIGHT_X, 1.0)],
		LOOK_UP: [_key(KEY_UP), _axis(JOY_AXIS_RIGHT_Y, -1.0)],
		LOOK_DOWN: [_key(KEY_DOWN), _axis(JOY_AXIS_RIGHT_Y, 1.0)],
		INTERACT: [_key(KEY_E), _button(JOY_BUTTON_A)],
		MEMORY_PULSE: [_key(KEY_F), _button(JOY_BUTTON_B)],
		ABILITY_1: [_key(KEY_1), _button(JOY_BUTTON_X)],
		ABILITY_2: [_key(KEY_2), _button(JOY_BUTTON_Y)],
		ABILITY_3: [_key(KEY_3), _button(JOY_BUTTON_RIGHT_SHOULDER)],
		ABILITY_4: [_key(KEY_4), _button(JOY_BUTTON_LEFT_SHOULDER)],
		PAUSE: [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)],
		JOURNAL: [_key(KEY_J), _key(KEY_TAB), _button(JOY_BUTTON_BACK)],
	}

## Adds every missing action with its default events (keeps user remaps intact).
static func register_defaults() -> void:
	var bindings := default_bindings()
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
			for event in bindings[action]:
				InputMap.action_add_event(action, event)
