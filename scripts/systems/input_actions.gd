class_name InputActions
extends RefCounted
## Single table of every gameplay input action and its default bindings (keyboard, gamepad).
## Touch input maps onto the same actions via TouchButton, so gameplay code is device agnostic.

const ACTIONS: Dictionary = {
	"move_left": {"keys": [KEY_A, KEY_LEFT], "axis": [[JOY_AXIS_LEFT_X, -1.0]]},
	"move_right": {"keys": [KEY_D, KEY_RIGHT], "axis": [[JOY_AXIS_LEFT_X, 1.0]]},
	"move_forward": {"keys": [KEY_W, KEY_UP], "axis": [[JOY_AXIS_LEFT_Y, -1.0]]},
	"move_back": {"keys": [KEY_S, KEY_DOWN], "axis": [[JOY_AXIS_LEFT_Y, 1.0]]},
	"look_left": {"axis": [[JOY_AXIS_RIGHT_X, -1.0]]},
	"look_right": {"axis": [[JOY_AXIS_RIGHT_X, 1.0]]},
	"look_up": {"axis": [[JOY_AXIS_RIGHT_Y, -1.0]]},
	"look_down": {"axis": [[JOY_AXIS_RIGHT_Y, 1.0]]},
	"interact": {"keys": [KEY_E, KEY_F], "buttons": [JOY_BUTTON_A]},
	"sprint": {"keys": [KEY_SHIFT], "buttons": [JOY_BUTTON_LEFT_STICK]},
	"walk_toggle": {"keys": [KEY_CTRL]},
	"ability_1": {"keys": [KEY_1], "buttons": [JOY_BUTTON_X]},
	"ability_2": {"keys": [KEY_2], "buttons": [JOY_BUTTON_Y]},
	"ability_3": {"keys": [KEY_3], "buttons": [JOY_BUTTON_B]},
	"ability_4": {"keys": [KEY_4], "buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	"context_ability": {"keys": [KEY_Q], "buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	"pause": {"keys": [KEY_ESCAPE], "buttons": [JOY_BUTTON_START]},
	"journal": {"keys": [KEY_TAB, KEY_J], "buttons": [JOY_BUTTON_BACK]},
}

const STICK_DEADZONE := 0.2

static func register() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, STICK_DEADZONE)
		var cfg: Dictionary = ACTIONS[action]
		for k: int in cfg.get("keys", []):
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			InputMap.action_add_event(action, ev)
		for b: int in cfg.get("buttons", []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = b as JoyButton
			InputMap.action_add_event(action, jb)
		for a: Array in cfg.get("axis", []):
			var jm := InputEventJoypadMotion.new()
			jm.axis = a[0] as JoyAxis
			jm.axis_value = a[1]
			InputMap.action_add_event(action, jm)
