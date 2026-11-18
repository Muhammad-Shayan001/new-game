class_name TouchJoystick
extends Control
## Floating virtual joystick (appears where the thumb lands inside this Control's rect).
## Writes to InputRouter.virtual_move. Also reacts to the mouse when touch UI is forced on, so it
## can be tested on a PC. Multi-touch safe: tracks the touch index that started the drag.

@export var radius: float = 90.0
@export var dead_zone: float = 0.12

var output: Vector2 = Vector2.ZERO
var _index: int = -2                  # -2 none, -1 mouse, >=0 touch index
var _origin: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _index == -2:
			_begin(t.index, t.position)
		elif not t.pressed and t.index == _index:
			_end()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _index:
			_update(d.position)
	elif event is InputEventMouseButton and not DisplayServer.is_touchscreen_available():
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed and _index == -2:
				_begin(-1, m.position)
			elif not m.pressed and _index == -1:
				_end()
	elif event is InputEventMouseMotion and _index == -1:
		_update((event as InputEventMouseMotion).position)

func _begin(index: int, pos: Vector2) -> void:
	_index = index
	_origin = pos
	_knob = pos
	_emit(Vector2.ZERO)

func _update(pos: Vector2) -> void:
	_knob = pos
	var v := (pos - _origin) / radius
	var mag := v.length()
	if mag < dead_zone:
		_emit(Vector2.ZERO)
		return
	# rescale so the output ramps from 0 at the dead zone to 1 at full deflection
	var scaled := (mag - dead_zone) / (1.0 - dead_zone)
	_emit(v.normalized() * clampf(scaled, 0.0, 1.0))

func _end() -> void:
	_index = -2
	_emit(Vector2.ZERO)

func _emit(v: Vector2) -> void:
	output = v
	InputRouter.set_virtual_move(v)
	queue_redraw()

func is_active() -> bool:
	return _index != -2

func _draw() -> void:
	if _index == -2:
		return
	var o := _origin - global_position
	draw_arc(o, radius, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	var k := o + (_knob - _origin).limit_length(radius)
	draw_circle(k, radius * 0.38, Color(1, 1, 1, 0.45))

func _exit_tree() -> void:
	if output != Vector2.ZERO:
		InputRouter.set_virtual_move(Vector2.ZERO)
