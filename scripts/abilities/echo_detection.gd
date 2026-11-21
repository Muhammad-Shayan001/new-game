extends Node
## Echo Detection ("Memory Pulse"): hold the pulse button to find the nearest undiscovered
## memory trace. Feedback is visual (direction and distance words), audio (a ping whose
## pitch rises as you get closer) and haptic. Each channel can be switched off in settings.
## Needs Memory Sight to be unlocked (the pulse is part of that ability family).

const HOLD_TIME := 0.4
const COOLDOWN := 3.0
const RANGE := 40.0
const VERY_CLOSE := 6.0
const CLOSE := 18.0

var _held := 0.0
var _cooldown := 0.0

func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if InputService.is_locked() or not GameState.has_ability("ABIL_MEMORY_SIGHT"):
		_held = 0.0
		return
	if Input.is_action_pressed(InputActions.MEMORY_PULSE):
		_held += delta
		if _held >= HOLD_TIME and _cooldown <= 0.0:
			_held = -INF          # one pulse per press
			pulse()
	else:
		_held = 0.0

func reset_runtime() -> void:
	_cooldown = 0.0
	_held = 0.0

func cooldown_left() -> float:
	return _cooldown

## Fires a pulse. Returns {"found": bool, "trace_id", "distance", "bearing", "band"}.
## bearing is in radians relative to where the camera looks: 0 = ahead, +PI/2 = right.
func pulse() -> Dictionary:
	if _cooldown > 0.0:
		return {"found": false}
	_cooldown = COOLDOWN
	EventBus.echo_pulse_fired.emit()
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var origin := player.global_position if player != null else Vector3.ZERO
	var trace := nearest_trace(origin)
	if trace == null:
		EventBus.echo_nothing_found.emit()
		_haptic(20)
		return {"found": false}
	var distance := _flat_distance(origin, trace.global_position)
	var bearing := _bearing(origin, trace.global_position)
	var band := "very_close" if distance <= VERY_CLOSE else ("close" if distance <= CLOSE else "far")
	EventBus.echo_detected.emit(trace.trace_id, distance, bearing)
	if bool(SettingsManager.get_value("accessibility", "echo_audio_cues")):
		AudioManager.play_cue("AUD_ECHO_PING", lerpf(1.6, 0.8, clampf(distance / RANGE, 0.0, 1.0)))
	_haptic(60 if band != "far" else 30)
	return {"found": true, "trace_id": trace.trace_id, "distance": distance, "bearing": bearing, "band": band}

func nearest_trace(origin: Vector3) -> MemoryTrace:
	var best: MemoryTrace = null
	var best_distance := RANGE
	for node in get_tree().get_nodes_in_group("memory_traces"):
		var trace := node as MemoryTrace
		if trace == null or trace.is_discovered():
			continue
		var d := _flat_distance(origin, trace.global_position)
		if d <= best_distance:
			best = trace
			best_distance = d
	return best

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _bearing(origin: Vector3, target: Vector3) -> float:
	var rig := get_tree().get_first_node_in_group("camera_rig") as Node3D
	var forward := -rig.global_transform.basis.z if rig != null else Vector3(0, 0, -1)
	forward.y = 0.0
	var dir := target - origin
	dir.y = 0.0
	if forward.length() < 0.001 or dir.length() < 0.001:
		return 0.0
	return -forward.normalized().signed_angle_to(dir.normalized(), Vector3.UP)

func _haptic(ms: int) -> void:
	if bool(SettingsManager.get_value("accessibility", "echo_haptics")) and InputService.device == "touch":
		Input.vibrate_handheld(ms)
