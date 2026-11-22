class_name GameRoot
extends Node
## Composition root. Owns the persistent player, camera and UI, and hosts location
## scenes. Systems are autoloads; this script only wires them together.
## Nothing here is specific to one level, mission or character.

@export var show_main_menu_on_boot: bool = true

@onready var _world: Node3D = $World
@onready var _player: Player = $Player
@onready var _camera: CameraRig = $CameraRig
@onready var _main_menu: MainMenu = $HUD/MainMenu if has_node("HUD/MainMenu") else null
@onready var _cutscene_runner: CutsceneRunner = $CutsceneLayer/CutsceneRunner if has_node("CutsceneLayer/CutsceneRunner") else null
@onready var _hud: CanvasLayer = $HUD

var _paused := false

func _ready() -> void:
	SceneRouter.register_host(_world)
	EventBus.location_ready.connect(_on_location_ready)
	EventBus.pause_requested.connect(_on_pause_requested)
	EventBus.scene_transition_failed.connect(func(_l, reason): EventBus.toast_requested.emit("TOAST_TRANSITION_FAILED", "warning"))

	if _cutscene_runner != null and _hud != null:
		_cutscene_runner.set_hud_reference(_hud)

	var is_headless: bool = DisplayServer.get_name().to_lower().contains("headless")
	if show_main_menu_on_boot and _main_menu != null and not is_headless:
		_main_menu.start_game_requested.connect(start_new_game)
		_main_menu.continue_game_requested.connect(continue_game)
		InputService.push_lock("main_menu")
		_main_menu.show_menu()
	else:
		if _main_menu != null:
			_main_menu.visible = false
		if SaveManager.load_game(SaveManager.AUTO_SLOT):
			GameLog.info("GameRoot", "continued from autosave")
		else:
			start_new_game()
			return
		MissionManager.refresh()
		SceneRouter.change_location(GameState.current_location, GameState.last_spawn_id)

func continue_game() -> void:
	InputService.pop_lock("main_menu")
	if SaveManager.load_game(SaveManager.AUTO_SLOT):
		GameLog.info("GameRoot", "continued from autosave")
	else:
		start_new_game()
		return
	MissionManager.refresh()
	SceneRouter.change_location(GameState.current_location, GameState.last_spawn_id)

func start_new_game() -> void:
	InputService.pop_lock("main_menu")
	GameState.reset()
	AbilityManager.reset_runtime()
	PuzzleManager.reset_runtime()
	GameState.set_flag("ch1_started", true)
	MissionManager.refresh()
	SceneRouter.change_location(GameState.current_location, "default")

	var is_headless: bool = DisplayServer.get_name().to_lower().contains("headless")
	if not is_headless and ResourceLoader.exists("res://scenes/cinematics/opening_sequence.tscn"):
		EventBus.cutscene_requested.emit("res://scenes/cinematics/opening_sequence.tscn")

func _on_location_ready(_location_id: String, root: Node) -> void:
	var spawn := (root as LocationRoot).get_spawn_transform(GameState.last_spawn_id) if root is LocationRoot else Transform3D.IDENTITY
	_player.place_at(spawn)
	_camera.snap_to(_player)

func _physics_process(delta: float) -> void:
	_camera.follow(_player, delta)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(InputActions.PAUSE) and not DialogueManager.is_active():
		EventBus.pause_requested.emit(not _paused)

func _on_pause_requested(paused: bool) -> void:
	_paused = paused
	get_tree().paused = paused
	if paused:
		InputService.push_lock("pause")
	else:
		InputService.pop_lock("pause")
