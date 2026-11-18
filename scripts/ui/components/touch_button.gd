class_name TouchButton
extends Control
## Round on-screen button bound to an input action (interact, sprint, context_ability, pause, ...).
## Presses go through Input.action_press so gameplay reads the same action as keyboard/gamepad.
## Hit target is at least MIN_SIZE px (about 48dp on a 1280x720 canvas).

signal pressed_changed(pressed: bool)

const MIN_SIZE := 104.0

@export var action: String = ""
@export var caption: String = ""
@export var toggle_mode: bool = false         ## tap to latch (sprint toggle accessibility)

var held: bool = false
var latched: bool = false
var highlighted: bool = false : set = _set_highlight
var _index: int = -2

func _ready() -> void:
	custom_minimum_size = Vector2(MIN_SIZE, MIN_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

func _set_highlight(v: bool) -> void:
	highlighted = v
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _index == -2:
			_index = t.index
			_set_pressed(true)
		elif not t.pressed and t.index == _index:
			_index = -2
			_set_pressed(false)
	elif event is InputEventMouseButton and not DisplayServer.is_touchscreen_available():
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			_set_pressed(m.pressed)

func _set_pressed(down: bool) -> void:
	if toggle_mode:
		if down:
			latched = not latched
			_apply(latched)
	else:
		_apply(down)
	held = down
	queue_redraw()
	pressed_changed.emit(down)

func _apply(down: bool) -> void:
	if action == "":
		return
	if down:
		InputRouter.latch(action)
		Input.action_press(action)
	else:
		Input.action_release(action)

func _exit_tree() -> void:
	if action != "" and (held or latched):
		Input.action_release(action)

func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	var on := held or latched
	var fill := Color(1, 1, 1, 0.38 if on else 0.18)
	if highlighted:
		fill = Color(1.0, 0.85, 0.3, 0.45)
	draw_circle(c, r, fill)
	draw_arc(c, r, 0, TAU, 40, Color(1, 1, 1, 0.65 if highlighted or on else 0.4), 3.0)
	if caption != "":
		var font := ThemeDB.fallback_font
		var fs := 22
		var w := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, c + Vector2(-w.x / 2.0, fs * 0.35), caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 1, 1, 0.95))
