class_name GameRoot
extends Node
## Composition root. Owns the persistent player, camera and UI, and hosts location
## scenes. Systems are autoloads; this script only wires them together.
## Nothing here is specific to one level, mission or character.

@onready var _world: Node3D = $World
@onready var _player: Player = $Player
@onready var _camera: CameraRig = $CameraRig

var _paused := false

func _ready() -> void:
	SceneRouter.register_host(_world)
	EventBus.location_ready.connect(_on_location_ready)
	EventBus.pause_requested.connect(_on_pause_requested)
	EventBus.scene_transition_failed.connect(func(_l, reason): EventBus.toast_requested.emit("TOAST_TRANSITION_FAILED", "warning"))
	if SaveManager.load_game(SaveManager.AUTO_SLOT):
		GameLog.info("GameRoot", "continued from autosave")
	else:
		start_new_game()
		return
	MissionManager.refresh()
	SceneRouter.change_location(GameState.current_location, GameState.last_spawn_id)

func start_new_game() -> void:
	GameState.reset()
	AbilityManager.reset_runtime()
	PuzzleManager.reset_runtime()
	GameState.set_flag("ch1_started", true)
	MissionManager.refresh()
	SceneRouter.change_location(GameState.current_location, "default")

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
