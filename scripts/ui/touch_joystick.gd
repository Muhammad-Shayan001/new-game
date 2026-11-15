class_name TouchJoystick
extends Control
## Virtual movement stick. Feeds InputService; never talks to the player directly.

@export var radius: float = 90.0

var _touch_index := -1
var _origin := Vector2.ZERO
var _thumb := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(radius * 2.4, radius * 2.4)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and get_global_rect().has_point(event.position):
			_touch_index = event.index
			_origin = event.position
			InputService.claim_touch(event.index)
		elif not event.pressed and event.index == _touch_index:
			InputService.release_touch(_touch_index)
			_touch_index = -1
			_thumb = Vector2.ZERO
			InputService.set_virtual_move(Vector2.ZERO)
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_thumb = ((event.position - _origin) / radius).limit_length(1.0)
		InputService.set_virtual_move(_thumb)
		queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, radius, Color(1, 1, 1, 0.12))
	draw_arc(center, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 2.0)
	draw_circle(center + _thumb * radius, radius * 0.4, Color(1, 1, 1, 0.45))

func _exit_tree() -> void:
	if _touch_index != -1:
		InputService.release_touch(_touch_index)
		InputService.set_virtual_move(Vector2.ZERO)
