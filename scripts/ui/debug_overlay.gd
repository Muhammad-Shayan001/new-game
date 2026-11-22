class_name DebugOverlay
extends Label
## Temporary diagnostic HUD. Add to game_root.tscn on a CanvasLayer (layer 99).
## REMOVE before release build.

@export var enabled: bool = true

var _player: Node3D = null
var _camera: Node3D = null
var _tick: float = 0.0

func _ready() -> void:
	if not enabled or not OS.is_debug_build():
		queue_free()
		return
	add_to_group("debug_ui")
	z_index = 99
	modulate = Color(0.1, 1.0, 0.5, 0.9)
	add_theme_font_size_override("font_size", 14)
	position = Vector2(8, 8)
	autowrap_mode = TextServer.AUTOWRAP_OFF

func _process(delta: float) -> void:
	if not enabled:
		return
	_tick += delta
	if _tick < 0.1:   # update at 10 Hz to avoid string alloc every frame
		return
	_tick = 0.0

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _camera == null:
		_camera = get_tree().get_first_node_in_group("camera_rig")

	var ppos: String
	if _player != null:
		var p := _player.global_position
		ppos = "%.1f, %.1f, %.1f" % [p.x, p.y, p.z]
	else:
		ppos = "—"

	var cpos: String
	if _camera != null:
		var c := _camera.global_position
		cpos = "%.1f, %.1f, %.1f" % [c.x, c.y, c.z]
	else:
		cpos = "—"

	var fps: String = "%.0f" % Engine.get_frames_per_second()
	var loc: String = GameState.current_location if Engine.has_singleton("GameState") else "?"

	text = "[DBG] FPS: %s | Location: %s\nPlayer: %s | Cam: %s" % [fps, loc, ppos, cpos]
