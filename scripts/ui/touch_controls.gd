class_name TouchControls
extends Control
## On-screen controls (stick + action buttons). Shown on touch devices, hidden when the
## player switches to keyboard/mouse or a gamepad (unless "always show" is on).

const BUTTONS := [
	[InputActions.INTERACT, "E", Vector2(-150, -170), 56.0],
	[InputActions.ABILITY_1, "1", Vector2(-260, -110), 40.0],
	[InputActions.ABILITY_2, "2", Vector2(-230, -230), 40.0],
	[InputActions.ABILITY_3, "3", Vector2(-110, -290), 40.0],
	[InputActions.MEMORY_PULSE, "P", Vector2(-60, -90), 36.0],
]

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stick := TouchJoystick.new()
	stick.position = Vector2(60, 0)
	stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stick.position = Vector2(70, -280)
	add_child(stick)
	for spec in BUTTONS:
		var b := TouchActionButton.new()
		b.action = spec[0]
		b.label = spec[1]
		b.radius = spec[3]
		b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		b.position = spec[2] - Vector2(b.radius, b.radius) + Vector2(0, 0)
		add_child(b)
	EventBus.input_device_changed.connect(func(_d): _refresh())
	EventBus.settings_changed.connect(func(s, _k, _v): if s == "controls": _refresh())
	_refresh()

func _refresh() -> void:
	visible = InputService.device == "touch" or bool(SettingsManager.get_value("controls", "always_show_touch"))
	modulate.a = float(SettingsManager.get_value("controls", "touch_opacity"))
