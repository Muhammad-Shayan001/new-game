extends Control
## Virtual joystick. Outputs a normalized Vector2 in `output`.

@export var radius: float = 90.0
var output := Vector2.ZERO
var _touch_index := -1
var _origin := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and get_global_rect().has_point(event.position):
			_touch_index = event.index
			_origin = event.position
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			output = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _touch_index:
		output = ((event.position - _origin) / radius).limit_length(1.0)
