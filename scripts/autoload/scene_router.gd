extends Node
## Safe location transitions: fade out -> threaded load -> swap -> fade in.
## - Only one transition at a time (extra requests are refused, never queued blindly).
## - A failed load leaves the current location untouched and fades back in.
## - Input is locked and autosave is blocked while a transition runs.
## Unbuilt locations load the placeholder scene, so any LocationDef is reachable.

enum State { IDLE, FADING_OUT, LOADING, SWAPPING, FADING_IN }

const FADE_TIME := 0.35
const LOAD_TIMEOUT := 20.0
const FADE_SCENE := preload("res://scenes/ui/fade_overlay.tscn")

var state: State = State.IDLE
var current_root: Node = null
var current_location_id: String = ""
var fade_time: float = FADE_TIME   # tests set 0

var _host: Node = null
var _fade: FadeOverlay = null

func _ready() -> void:
	_fade = FADE_SCENE.instantiate()
	add_child(_fade)

## GameRoot (or a test) registers the node that will hold loaded location scenes.
func register_host(host: Node) -> void:
	_host = host

func is_busy() -> bool:
	return state != State.IDLE

## Returns true when the new location is loaded and visible.
func change_location(location_id: String, spawn_id: String = "") -> bool:
	if is_busy():
		GameLog.warn("SceneRouter", "transition to '%s' refused: busy" % location_id)
		return false
	var def := DataRegistry.get_location(location_id)
	if def == null:
		return _fail(location_id, "unknown location")
	if _host == null or not is_instance_valid(_host):
		return _fail(location_id, "no world host registered")
	if spawn_id == "":
		spawn_id = def.default_spawn
	var path := def.resolve_scene_path()
	var duration := 0.0 if _reduce_motion() else fade_time

	state = State.FADING_OUT
	InputService.push_lock("transition")
	GameState.autosave_blocks += 1
	EventBus.scene_transition_started.emit(current_location_id, location_id)
	await _fade.fade_to(1.0, duration)

	state = State.LOADING
	var packed: PackedScene = await _load_threaded(path)
	if packed == null:
		await _fade.fade_to(0.0, duration)
		_finish_transition()
		return _fail(location_id, "could not load scene '%s'" % path)

	state = State.SWAPPING
	if current_root != null and is_instance_valid(current_root):
		_host.remove_child(current_root)
		current_root.queue_free()
	var root := packed.instantiate()
	_host.add_child(root)
	current_root = root
	current_location_id = location_id
	GameState.enter_location(location_id, spawn_id)
	if root is LocationRoot:
		(root as LocationRoot).setup(location_id, spawn_id)
	EventBus.location_ready.emit(location_id, root)
	if def.ambience_cue != "":
		AudioManager.play_cue(def.ambience_cue)

	state = State.FADING_IN
	await _fade.fade_to(0.0, duration)
	_finish_transition()
	EventBus.scene_transition_finished.emit(location_id)
	EventBus.autosave_requested.emit("room_transition")
	return true

func _finish_transition() -> void:
	state = State.IDLE
	InputService.pop_lock("transition")
	GameState.autosave_blocks = maxi(0, GameState.autosave_blocks - 1)

func _fail(location_id: String, reason: String) -> bool:
	GameLog.error("SceneRouter", "%s -> %s" % [location_id, reason])
	EventBus.scene_transition_failed.emit(location_id, reason)
	return false

func _reduce_motion() -> bool:
	return bool(SettingsManager.get_value("accessibility", "reduce_motion"))

## Threaded load with a timeout; returns null on failure.
func _load_threaded(path: String) -> PackedScene:
	if ResourceLoader.load_threaded_request(path) != OK:
		return null
	var waited := 0.0
	while true:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			return ResourceLoader.load_threaded_get(path) as PackedScene
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			return null
		waited += get_process_delta_time()
		if waited > LOAD_TIMEOUT:
			return null
		await get_tree().process_frame
	return null
