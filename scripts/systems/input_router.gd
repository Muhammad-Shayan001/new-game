extends Node
## Input abstraction layer. Gameplay NEVER reads devices directly; it asks the router.
## Sources merged: keyboard, mouse, gamepad, and on-screen touch controls.
## Touch widgets feed in through set_virtual_move / add_virtual_look and Input.action_press,
## so there is no platform-specific branch in player or camera code.

const MOUSE_SENS := 0.0025          # radians per pixel
const TOUCH_LOOK_SENS := 0.0045
const STICK_LOOK_SPEED := 2.6       # radians per second at full deflection

var virtual_move: Vector2 = Vector2.ZERO
var last_device: String = "kbm"      # kbm | gamepad | touch
var _look_accum: Vector2 = Vector2.ZERO
var _locks: Dictionary = {}          # lock source -> true
var _latched: Dictionary = {}        # action -> tick (ms) of an unconsumed press
const LATCH_MS := 150                # a tap shorter than one physics tick is still delivered

func _ready() -> void:
	InputActions.register()
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- locks (dialogue, pause, cinematics, menus) ---
func push_lock(source: String) -> void:
	_locks[source] = true

func pop_lock(source: String) -> void:
	_locks.erase(source)

func is_locked() -> bool:
	return not _locks.is_empty()

func clear_locks() -> void:
	_locks.clear()

# --- movement ---
## Raw movement vector (x = right, y = back) with magnitude 0..1. Zero while locked.
func get_move() -> Vector2:
	if is_locked():
		return Vector2.ZERO
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back", InputActions.STICK_DEADZONE)
	if virtual_move.length() > v.length():
		v = virtual_move
	return v.limit_length(1.0)

func set_virtual_move(v: Vector2) -> void:
	virtual_move = v.limit_length(1.0)
	if v != Vector2.ZERO:
		_set_device("touch")

# --- camera look ---
func add_virtual_look(pixels: Vector2) -> void:
	_look_accum += pixels * TOUCH_LOOK_SENS
	_set_device("touch")

## Look delta in radians for this frame, already scaled by device. Settings scaling is applied by the camera.
func consume_look(delta: float) -> Vector2:
	var out := _look_accum
	_look_accum = Vector2.ZERO
	if is_locked():
		return Vector2.ZERO
	out += Input.get_vector("look_left", "look_right", "look_up", "look_down") * STICK_LOOK_SPEED * delta
	return out

# --- buttons ---
func is_pressed(action: String) -> bool:
	return not is_locked() and Input.is_action_pressed(action)

## True once per press. Uses a short latch so quick taps (press + release between two physics
## ticks, common on slow phones) are never lost, and stale presses expire instead of firing later.
func just_pressed(action: String) -> bool:
	var latched_at: int = int(_latched.get(action, -1000000))
	var fresh := Time.get_ticks_msec() - latched_at <= LATCH_MS
	_latched.erase(action)
	if is_locked():
		return false
	return fresh or Input.is_action_just_pressed(action)

## Called by touch widgets (and the device router) when an action goes down.
func latch(action: String) -> void:
	_latched[action] = Time.get_ticks_msec()

# --- device tracking ---
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed() and not event.is_echo():
			for action: String in InputActions.ACTIONS:
				if event.is_action(action):
					latch(action)
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_look_accum += (event as InputEventMouseMotion).relative * MOUSE_SENS
			_set_device("kbm")
	elif event is InputEventKey or event is InputEventMouseButton:
		_set_device("kbm")
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_set_device("gamepad")
	elif event is InputEventScreenTouch:
		_set_device("touch")

func _set_device(kind: String) -> void:
	if last_device != kind:
		last_device = kind
		EventBus.input_device_changed.emit(kind)

func touch_ui_enabled() -> bool:
	match str(Settings.value("touch_controls")):
		"on": return true
		"off": return false
	return DisplayServer.is_touchscreen_available() or OS.has_feature("android") or OS.has_feature("ios")
