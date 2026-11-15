extends Node
## Input abstraction. Keyboard, mouse, gamepad and touch all end up as the same
## InputActions, so no gameplay code is platform-specific.
##  - movement/looking: get_move_vector() / consume_look_delta() / get_look_axis()
##  - buttons: use Input.is_action_* with InputActions constants
##  - locking: push_lock(reason) / pop_lock(reason) while dialogue, menus, cutscenes run.

const LOOK_PIXELS_TO_RADIANS := 0.004

var device: String = "keyboard_mouse"

var _virtual_move := Vector2.ZERO        # written by TouchJoystick
var _look_pixels := Vector2.ZERO         # accumulated mouse-drag / touch-drag
var _claimed_touches: Dictionary = {}    # touch index -> true (joystick / buttons)
var _look_touches: Dictionary = {}       # touch index -> true (look-drag)
var _locks: Dictionary = {}              # reason -> true

func _init() -> void:
	InputActions.register_defaults()
	device = "touch" if OS.has_feature("mobile") else "keyboard_mouse"

# --- locking ---------------------------------------------------------------
func push_lock(reason: String) -> void:
	var was_locked := is_locked()
	_locks[reason] = true
	if not was_locked:
		_virtual_move = Vector2.ZERO
		EventBus.input_lock_changed.emit(true)

func pop_lock(reason: String) -> void:
	if _locks.erase(reason) and not is_locked():
		EventBus.input_lock_changed.emit(false)

func is_locked() -> bool:
	return not _locks.is_empty()

func clear_locks() -> void:
	_locks.clear()
	EventBus.input_lock_changed.emit(false)

# --- movement and look -----------------------------------------------------
## Movement for the player: zero while locked, virtual stick overrides actions.
func get_move_vector() -> Vector2:
	if is_locked():
		return Vector2.ZERO
	if _virtual_move != Vector2.ZERO:
		return _virtual_move.limit_length(1.0)
	return Input.get_vector(InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT,
		InputActions.MOVE_FORWARD, InputActions.MOVE_BACK)

func get_look_axis() -> Vector2:
	if is_locked():
		return Vector2.ZERO
	return Input.get_vector(InputActions.LOOK_LEFT, InputActions.LOOK_RIGHT,
		InputActions.LOOK_UP, InputActions.LOOK_DOWN)

## Pointer look since the last call, in radians (yaw = x, pitch = y).
func consume_look_delta() -> Vector2:
	var out := _look_pixels * LOOK_PIXELS_TO_RADIANS
	_look_pixels = Vector2.ZERO
	return Vector2.ZERO if is_locked() else out

func set_virtual_move(value: Vector2) -> void:
	_virtual_move = value

# --- touch ownership -------------------------------------------------------
func claim_touch(index: int) -> void:
	_claimed_touches[index] = true

func release_touch(index: int) -> void:
	_claimed_touches.erase(index)

# --- device detection and pointer look --------------------------------------
func _set_device(value: String) -> void:
	if device != value:
		device = value
		EventBus.input_device_changed.emit(value)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		_set_device("keyboard_mouse")
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		_set_device("gamepad")
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_device("touch")

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_look_pixels += event.relative
	elif event is InputEventScreenTouch:
		if event.pressed:
			var right_half: bool = event.position.x > get_viewport().get_visible_rect().size.x * 0.4
			if right_half and not _claimed_touches.has(event.index):
				_look_touches[event.index] = true
		else:
			_look_touches.erase(event.index)
	elif event is InputEventScreenDrag and _look_touches.has(event.index) \
			and not _claimed_touches.has(event.index):
		_look_pixels += event.relative
