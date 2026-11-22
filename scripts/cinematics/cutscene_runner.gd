class_name CutsceneRunner
extends Node

## Cutscene & Flashback Director
## Listens to EventBus.cutscene_requested and manages cinematic sequence lifecycles.
## Locks input, blocks autosaves, hides gameplay HUD, and restores state upon completion.

signal cutscene_started(scene_path: String)
signal cutscene_completed(scene_path: String)

var _current_cutscene: Node = null
var _hud: CanvasLayer = null

func _ready() -> void:
	EventBus.cutscene_requested.connect(play_cutscene)

func set_hud_reference(hud: CanvasLayer) -> void:
	_hud = hud

func is_playing() -> bool:
	return _current_cutscene != null

func play_cutscene(scene_path: String) -> void:
	if is_playing():
		GameLog.warn("CutsceneRunner", "Cannot start cutscene '%s': already playing" % scene_path)
		return

	if not ResourceLoader.exists(scene_path):
		GameLog.error("CutsceneRunner", "Cutscene scene not found: %s" % scene_path)
		return

	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return

	_current_cutscene = packed.instantiate()
	InputService.push_lock("cutscene")
	GameState.autosave_blocks += 1

	if _hud != null:
		_hud.visible = false

	add_child(_current_cutscene)
	cutscene_started.emit(scene_path)

	# If the cutscene defines a finished signal, wait for it
	if _current_cutscene.has_signal("finished"):
		_current_cutscene.connect("finished", func(): _on_cutscene_finished(scene_path))
	elif _current_cutscene.has_signal("completed"):
		_current_cutscene.connect("completed", func(): _on_cutscene_finished(scene_path))

func _on_cutscene_finished(scene_path: String) -> void:
	if _current_cutscene != null:
		_current_cutscene.queue_free()
		_current_cutscene = null

	if _hud != null:
		_hud.visible = true

	GameState.autosave_blocks -= 1
	InputService.pop_lock("cutscene")
	cutscene_completed.emit(scene_path)
