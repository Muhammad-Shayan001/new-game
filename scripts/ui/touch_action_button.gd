class_name TouchActionButton
extends Control
## Multi-touch-safe on-screen button that presses an InputActions action.

@export var action: StringName = InputActions.INTERACT
@export var label: String = ""
@export var radius: float = 52.0

var _touch_index := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and get_global_rect().has_point(event.position):
			_touch_index = event.index
			InputService.claim_touch(event.index)
			Input.action_press(action)
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			_release()

func _release() -> void:
	InputService.release_touch(_touch_index)
	_touch_index = -1
	Input.action_release(action)
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var pressed := _touch_index != -1
	draw_circle(center, radius, Color(1, 1, 1, 0.35 if pressed else 0.15))
	draw_arc(center, radius, 0.0, TAU, 40, Color(1, 1, 1, 0.6), 2.0)
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
	draw_string(font, center + Vector2(-text_size.x / 2.0, 6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)

func _exit_tree() -> void:
	if _touch_index != -1:
		_release()
