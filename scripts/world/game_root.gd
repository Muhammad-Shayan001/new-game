extends Node3D
## Persistent gameplay root: World container (locations swap here), Player, HUD and overlays.
## Registers itself with SceneManager; owns mouse capture on desktop.

@onready var world: Node3D = $World
@onready var player: PlayerController = $Player

func _ready() -> void:
	SceneManager.register_game_root(world, player)
	GameState.track_playtime = true
	EventBus.input_device_changed.connect(_update_mouse_mode)
	_update_mouse_mode(InputRouter.last_device)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _update_mouse_mode(kind: String) -> void:
	# Desktop: capture the mouse for look. Touch/gamepad leave it alone.
	var desktop := not (OS.has_feature("android") or OS.has_feature("ios"))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if (desktop and kind == "kbm" and not DisplayServer.get_name() == "headless") else Input.mouse_mode

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.action_release("sprint")
		InputRouter.set_virtual_move(Vector2.ZERO)
