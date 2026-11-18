extends Node
## Safe scene/location transitions. Locations are data (resources/locations/*.json); the scene is
## loaded with threaded loading and swapped inside the persistent GameRoot, so the player, HUD and
## autoload state survive every transition. Re-entrant calls are rejected instead of queued.

const GAME_ROOT := "res://scenes/game_root.tscn"
const TITLE := "res://scenes/ui/title_screen.tscn"
const GRAYBOX := "res://scenes/world/graybox_location.tscn"
const START_LOCATION := "LOC_UM_ECHO_STATION"
const FADE_TIME := 0.28

var world_root: Node3D
var player: PlayerController
var current_location_id: String = ""
var current_location_node: Node3D
var busy: bool = false
var _fade: ColorRect
var _fade_layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade)

func register_game_root(world: Node3D, player_node: PlayerController) -> void:
	world_root = world
	player = player_node

func unregister_game_root() -> void:
	world_root = null
	player = null
	current_location_node = null
	current_location_id = ""

# ------------------------------------------------------------------ fading
func _fade_to(alpha: float) -> void:
	var t := 0.0 if bool(Settings.value("reduced_motion")) else FADE_TIME
	if t <= 0.0:
		_fade.modulate.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, t)
	await tween.finished

# ------------------------------------------------------------------ screens
## Changes to a non-world scene (title screen, credits). Fades out, swaps, fades in.
func change_screen(path: String, fade_in: bool = true) -> bool:
	if busy:
		return false
	if not ResourceLoader.exists(path):
		Log.error("Scene", "Missing scene %s" % path)
		return false
	busy = true
	await _fade_to(1.0)
	unregister_game_root()
	InputRouter.clear_locks()
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		Log.error("Scene", "change_scene failed: %s" % error_string(err))
		await _fade_to(0.0)
		busy = false
		return false
	await get_tree().process_frame
	await get_tree().process_frame
	if fade_in:
		await _fade_to(0.0)
	busy = false
	return true

func start_new_game(start_location: String = START_LOCATION) -> void:
	SaveManager.reset_all()
	MissionManager.refresh()
	GameState.track_playtime = true
	if await change_screen(GAME_ROOT, false):
		await go_to_location(start_location)

func continue_game(slot: int) -> bool:
	if not SaveManager.load_game(slot):
		return false
	GameState.track_playtime = true
	var loc := GameState.current_location if GameState.current_location != "" else START_LOCATION
	if await change_screen(GAME_ROOT, false):
		await go_to_location(loc)
		return true
	return false

func return_to_title() -> void:
	GameState.track_playtime = false
	await change_screen(TITLE)

# ------------------------------------------------------------------ locations
func get_location_def(id: String) -> Dictionary:
	return DataRegistry.get_def("locations", id)

## Coroutine: await it if you need to know when the transition is complete.
func go_to_location(loc_id: String, spawn: String = "") -> bool:
	if busy:
		Log.warn("Scene", "Transition to %s ignored: another transition is running" % loc_id)
		return false
	var def := get_location_def(loc_id)
	if def.is_empty():
		Log.error("Scene", "Unknown location '%s'" % loc_id)
		return false
	if world_root == null or player == null:
		Log.error("Scene", "No GameRoot registered; cannot enter %s" % loc_id)
		return false
	busy = true
	EventBus.scene_transition_started.emit(loc_id)
	InputRouter.push_lock("transition")
	await _fade_to(1.0)

	if current_location_node != null and is_instance_valid(current_location_node):
		EventBus.location_exited.emit(current_location_id)
		if current_location_node.get_parent() == world_root:
			world_root.remove_child(current_location_node)
		current_location_node.queue_free()
	current_location_node = null

	var scene := await _load_location_scene(def)
	if scene == null or not _root_alive():
		await _abort_transition()
		return false
	var inst := scene.instantiate()
	if "location_id" in inst:
		inst.location_id = loc_id
	world_root.add_child(inst)
	if inst.has_method("setup_location"):
		inst.setup_location(def)
	current_location_node = inst
	current_location_id = loc_id

	var xform := Transform3D.IDENTITY
	if inst.has_method("get_spawn_transform"):
		xform = inst.get_spawn_transform(spawn)
	if not _root_alive():
		await _abort_transition()
		return false
	player.teleport(xform)
	if player.camera_rig and player.camera_rig.has_method("set_location_type"):
		player.camera_rig.set_location_type(str(def.get("type", "exterior")))

	GameState.enter_location(loc_id)
	if def.get("safe", false):
		SaveManager.autosave()
	InputRouter.pop_lock("transition")
	EventBus.location_entered.emit(loc_id)
	await _fade_to(0.0)
	busy = false
	EventBus.scene_transition_finished.emit(loc_id)
	return true

## The GameRoot can be freed mid-transition (quit to title, scene change). Never leave the manager stuck.
func _root_alive() -> bool:
	return is_instance_valid(world_root) and is_instance_valid(player) and world_root.is_inside_tree()

func _abort_transition() -> void:
	Log.warn("Scene", "Transition aborted: game root went away")
	current_location_node = null
	InputRouter.pop_lock("transition")
	busy = false
	await _fade_to(0.0)

func _load_location_scene(def: Dictionary) -> PackedScene:
	var path: String = str(def.get("scene", ""))
	if path == "" or not ResourceLoader.exists(path):
		if path != "":
			Log.warn("Scene", "Scene %s missing; using graybox" % path)
		path = GRAYBOX
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		Log.error("Scene", "Cannot request %s: %s" % [path, error_string(err)])
		return null
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
		Log.error("Scene", "Failed to load %s" % path)
		return null
	return ResourceLoader.load_threaded_get(path) as PackedScene
