class_name TouchLookPad
extends Control
## Camera drag area. One finger dragging here rotates the camera. Sits BELOW the buttons in the
## HUD tree so buttons always win the touch. Mouse drag works when touch UI is forced on (PC testing).

var _index: int = -2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _index == -2:
			_index = t.index
		elif not t.pressed and t.index == _index:
			_index = -2
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _index:
			InputRouter.add_virtual_look(d.relative)
	elif event is InputEventMouseButton and not DisplayServer.is_touchscreen_available():
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			_index = -1 if m.pressed else -2
	elif event is InputEventMouseMotion and _index == -1:
		InputRouter.add_virtual_look((event as InputEventMouseMotion).relative)
